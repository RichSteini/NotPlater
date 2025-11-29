if not NotPlater then
	return
end

local WhatsNew = NotPlater:NewModule("WhatsNew")
local L = NotPlaterLocals
local AceConfigRegistry = LibStub and LibStub("AceConfigRegistry-3.0", true)
local sformat = string.format
local strtrim = strtrim
local tonumber = tonumber
local max = math.max
local tinsert = table.insert
local tconcat = table.concat
local wipe = wipe or function(tbl)
	for key in pairs(tbl) do
		tbl[key] = nil
	end
end

local COLOR_RESET = "|r"
local COLOR_HEADING_1 = "|cffffd100"
local COLOR_HEADING_2 = "|cffffff78"
local COLOR_HEADING_3 = "|cffc0e0ff"
local COLOR_BOLD = "|cfffff2b0"
local COLOR_ITALIC = "|cffb4d4ff"
local COLOR_CODE = "|cff96ffc8"
local COLOR_QUOTE = "|cff9eb2c7"

local function FormatInline(text)
	text = tostring(text or "")
	text = text:gsub("|", "||")
	text = text:gsub("%[(.-)%]%((.-)%)", "%1")
	text = text:gsub("`([^`]+)`", COLOR_CODE .. "%1" .. COLOR_RESET)
	text = text:gsub("%*%*(.-)%*%*", COLOR_BOLD .. "%1" .. COLOR_RESET)
	text = text:gsub("%_%_(.-)%_%_", COLOR_BOLD .. "%1" .. COLOR_RESET)
	text = text:gsub("%*(.-)%*", COLOR_ITALIC .. "%1" .. COLOR_RESET)
	text = text:gsub("%_(.-)%_", COLOR_ITALIC .. "%1" .. COLOR_RESET)
	return text
end

local function ExtractFirstHeading(markdown)
	if type(markdown) ~= "string" then
		return nil
	end
	for line in (markdown .. "\n"):gmatch("(.-)\r?\n") do
		local trimmed = strtrim(line or "")
		if trimmed and trimmed ~= "" then
			local heading = trimmed:match("^#+%s*(.+)")
			if heading and heading ~= "" then
				return heading
			end
		end
	end
	return nil
end

local function BuildRevisionParts(revision)
	if type(revision) ~= "string" then
		return nil
	end
	local trimmed = strtrim(revision)
	if trimmed == "" then
		return nil
	end
	trimmed = trimmed:gsub("^%D+", "")
	if trimmed == "" then
		return nil
	end
	local parts = {}
	for segment in trimmed:gmatch("%d+") do
		local value = tonumber(segment)
		if value then
			parts[#parts + 1] = value
		end
	end
	if #parts == 0 then
		return nil
	end
	return parts
end

local function IsRevisionNewer(currentRevision, storedRevision)
	if type(currentRevision) ~= "string" or currentRevision == "" then
		return false
	end
	local currentParts = BuildRevisionParts(currentRevision)
	if not currentParts then
		return false
	end

	local storedParts = BuildRevisionParts(storedRevision)
	if not storedParts then
		return true
	end

	local compareLength = max(#currentParts, #storedParts)
	for index = 1, compareLength do
		local currentValue = currentParts[index] or 0
		local storedValue = storedParts[index] or 0
		if currentValue > storedValue then
			return true
		elseif currentValue < storedValue then
			return false
		end
	end

	return false
end

local function MarkdownToDisplayText(markdown)
	if type(markdown) ~= "string" or not markdown:match("%S") then
		return ""
	end

	local lines = {}
	local paragraph = {}

	local function flushParagraph()
		if #paragraph > 0 then
			lines[#lines + 1] = tconcat(paragraph, " ")
			wipe(paragraph)
		end
	end

	local function addBlankLine()
		if #lines == 0 then
			return
		end
		if lines[#lines] ~= "" then
			lines[#lines + 1] = ""
		end
	end

	local function addHeading(level, text)
		flushParagraph()
		addBlankLine()
		local color = COLOR_HEADING_3
		if level == 1 then
			color = COLOR_HEADING_1
		elseif level == 2 then
			color = COLOR_HEADING_2
		end
		lines[#lines + 1] = color .. FormatInline(text) .. COLOR_RESET
		addBlankLine()
	end

	for line in (markdown .. "\n"):gmatch("(.-)\r?\n") do
		local trimmed = strtrim(line or "")
		if trimmed == "" then
			flushParagraph()
			addBlankLine()
		else
			local heading = trimmed:match("^###%s+(.+)")
			if heading then
				addHeading(3, heading)
			else
				heading = trimmed:match("^##%s+(.+)")
				if heading then
					addHeading(2, heading)
				else
					heading = trimmed:match("^#%s+(.+)")
					if heading then
						addHeading(1, heading)
					else
						local number, orderedText = trimmed:match("^(%d+)%.%s+(.+)")
						if number then
							flushParagraph()
							lines[#lines + 1] = COLOR_HEADING_2 .. number .. "." .. COLOR_RESET .. " " .. FormatInline(orderedText)
						else
							local bullet = trimmed:match("^[-*]%s+(.+)")
							if bullet then
								flushParagraph()
								lines[#lines + 1] = "- " .. FormatInline(bullet)
							else
								local quote = trimmed:match("^>%s*(.+)")
								if quote then
									flushParagraph()
									lines[#lines + 1] = COLOR_QUOTE .. FormatInline(quote) .. COLOR_RESET
								else
									tinsert(paragraph, FormatInline(trimmed))
								end
							end
						end
					end
				end
			end
		end
	end

	flushParagraph()

	local text = tconcat(lines, "\n")
	text = text:gsub("\n\n\n+", "\n\n")
	return text
end

function WhatsNew:GetRawMarkdown()
	local data = NotPlaterReleaseData
	if type(data) == "table" then
		if type(data.markdown) == "string" then
			return data.markdown
		end
	elseif type(data) == "string" then
		return data
	end
	return ""
end

function WhatsNew:GetReleaseId()
	local data = NotPlaterReleaseData
	if type(data) == "table" and data.id then
		local identifier = strtrim(tostring(data.id) or "")
		if identifier ~= "" then
			return identifier
		end
	end

	local revision = NotPlater.revision
	if type(revision) == "string" and revision ~= "" then
		return revision
	end

	local heading = ExtractFirstHeading(self:GetRawMarkdown())
	if type(heading) == "string" and heading ~= "" then
		return heading
	end

	return "notplater-release"
end

function WhatsNew:GetReleaseTitle()
	local data = NotPlaterReleaseData
	if type(data) == "table" then
		if type(data.title) == "string" and strtrim(data.title) ~= "" then
			return strtrim(data.title)
		end
		if type(data.id) == "string" and strtrim(data.id) ~= "" then
			return strtrim(data.id)
		end
	end

	local heading = ExtractFirstHeading(self:GetRawMarkdown())
	if type(heading) == "string" and heading ~= "" then
		return heading
	end

	return NotPlater.revision or ""
end

function WhatsNew:HasReleaseText()
	local markdown = self:GetRawMarkdown()
	return type(markdown) == "string" and markdown:match("%S") ~= nil
end

function WhatsNew:GetStorage()
	if not NotPlater.db then
		return nil
	end
	NotPlater.db.global = NotPlater.db.global or {}
	NotPlater.db.global.whatsNew = NotPlater.db.global.whatsNew or {}
	local storage = NotPlater.db.global.whatsNew
	if storage.lastSeenId == nil then
		storage.lastSeenId = ""
	end
	if storage.lastSeenRevision == nil then
		storage.lastSeenRevision = ""
	end
	return storage
end

function WhatsNew:IsSuppressed()
	local storage = self:GetStorage()
	return storage and storage.suppressed
end

function WhatsNew:SetSuppressed(state)
	local storage = self:GetStorage()
	if not storage then
		return
	end
	storage.suppressed = state and true or false
	if AceConfigRegistry then
		AceConfigRegistry:NotifyChange("NotPlater")
	end
end

function WhatsNew:MarkSeen()
	local storage = self:GetStorage()
	if storage then
		storage.lastSeenId = self:GetReleaseId() or storage.lastSeenId
		storage.lastSeenRevision = NotPlater and NotPlater.revision or storage.lastSeenRevision
	end
end

function WhatsNew:ShouldShow()
	if not self:HasReleaseText() then
		return false
	end
	if self:IsSuppressed() then
		return false
	end
	local storage = self:GetStorage()
	if not storage then
		return false
	end
	local releaseId = self:GetReleaseId()
	if releaseId ~= "" and storage.lastSeenId ~= releaseId then
		return true
	end

	local currentRevision = NotPlater and NotPlater.revision
	if IsRevisionNewer(currentRevision, storage.lastSeenRevision) then
		return true
	end

	return false
end

local function GetFallbackDisplayText()
	return FormatInline(L["Release notes are not available."])
end

function WhatsNew:GetDisplayText()
	local markdown = self:GetRawMarkdown()
	if type(markdown) ~= "string" or markdown == "" then
		return GetFallbackDisplayText()
	end
	if self._cachedMarkdown ~= markdown then
		self._cachedMarkdown = markdown
		local converted = MarkdownToDisplayText(markdown)
		if converted == "" then
			converted = GetFallbackDisplayText()
		end
		self._cachedDisplay = converted
	end
	return self._cachedDisplay or GetFallbackDisplayText()
end

function WhatsNew:BeginConfigSession()
	self._sessionVisible = (self._manualOverride == true) or self:ShouldShow()
	self._manualOverride = false
	if self._sessionVisible then
		self:MarkSeen()
	end
end

function WhatsNew:IsSessionVisible()
	return self._sessionVisible
end

function WhatsNew:DismissSession()
	self._sessionVisible = false
	if AceConfigRegistry then
		AceConfigRegistry:NotifyChange("NotPlater")
	end
end

function WhatsNew:GetConfigOptions()
	if self.configOptions then
		return self.configOptions
	end
	local module = self
	self.configOptions = {
		order = -100,
		type = "group",
		inline = true,
		name = L["What's New"],
		hidden = function()
			return not module:IsSessionVisible()
		end,
		args = {
			body = {
				order = 1,
				type = "description",
				fontSize = NotPlater.isWrathClient and "medium" or nil,
				name = function()
					return module:GetDisplayText()
				end,
			},
			spacer = {
				order = 2,
				type = "description",
				name = " ",
			},
			suppress = {
				order = 3,
				type = "toggle",
				width = "full",
				name = L["Don't show this again"],
				get = function()
					return module:IsSuppressed()
				end,
				set = function(_, value)
					module:SetSuppressed(value)
				end,
			},
			dismiss = {
				order = 4,
				type = "execute",
				width = "half",
				name = L["Got it!"],
				func = function()
					module:DismissSession()
				end,
			},
		},
	}
	return self.configOptions
end

function WhatsNew:RequestManualView()
	self._manualOverride = true
end
