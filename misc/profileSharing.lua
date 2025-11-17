--[[ profileSharing.lua
This file implements the profile sharing functionality for NotPlater, similar to WeakAuras.
It handles export/import of profiles as strings, chat links for sharing, and transmission over addon channels.
]]--

if not NotPlater then return end
local ProfileSharing = NotPlater:NewModule("ProfileSharing")
local L = NotPlaterLocals
local LibDeflate = LibStub("LibDeflate")
local LibSerialize = LibStub("LibSerialize")
local AceComm = LibStub("AceComm-3.0")
local dialog = LibStub("AceConfigDialog-3.0", true)
local registry = LibStub("AceConfigRegistry-3.0", true)
local configForDeflate = {level = 9}
local configForLS = {errorOnUnserializableType = false}
local addonPrefix = "NotPlater"
local tooltipLoading = false
local receivedData = false
local safeSenders = {}
local linkedProfiles = {}
local linkValidityDuration = 60 * 5
local GetNumPartyMembers = GetNumPartyMembers
local GetNumRaidMembers = GetNumRaidMembers
local UnitName = UnitName
local GetTime = GetTime

local function ShortName(name)
	if not name then
		return nil
	end
	local short = name:gsub("|c[Ff][Ff]%x%x%x%x%x%x", ""):gsub("|r", "")
	local dash = short:find("-")
	if dash then
		short = short:sub(1, dash - 1)
	end
	return short
end

local function RecordLinkedProfile(profileName)
	if profileName and profileName ~= "" then
		linkedProfiles[profileName] = GetTime()
	end
end

local function IsLinkedProfileRecent(profileName)
	if not profileName then
		return false
	end
	local timestamp = linkedProfiles[profileName]
	if not timestamp then
		return false
	end
	if (GetTime() - timestamp) > linkValidityDuration then
		linkedProfiles[profileName] = nil
		return false
	end
	return true
end

local function GetGroupChannelForTarget(target)
	local short = ShortName(target)
	if not short then
		return nil
	end
	for i = 1, GetNumRaidMembers() do
		local name = UnitName("raid" .. i)
		if name == short then
			return "RAID"
		end
	end
	for i = 1, GetNumPartyMembers() do
		local name = UnitName("party" .. i)
		if name == short then
			return "PARTY"
		end
	end
	return nil
end

local function SendProfileCommMessage(message, target, queueName, callbackFn, callbackArg)
	local channel = GetGroupChannelForTarget(target) or "WHISPER"
	local destination = target
	local payload = message
	if channel ~= "WHISPER" then
		local shortTarget = ShortName(target)
		payload = ("§§%s:%s"):format(shortTarget or target, message)
		destination = nil
	end
	AceComm:SendCommMessage(addonPrefix, payload, channel, destination, queueName, callbackFn, callbackArg)
end

local function OpenSharingOptions()
	local configModule = NotPlater:GetModule("Config", true)
	if configModule and configModule.OpenConfig then
		configModule:OpenConfig()
	end
	if dialog and dialog.SelectGroup then
		dialog:SelectGroup("NotPlater", "profile", "import")
	end
end

-- Local functions
local function TableToString(inTable, forPrint)
  local serialized = LibSerialize:SerializeEx(configForLS, inTable)
  local compressed = LibDeflate:CompressDeflate(serialized, configForDeflate)
  local encoded = "!NP:1!"
  if forPrint then
    encoded = encoded .. LibDeflate:EncodeForPrint(compressed)
  else
    encoded = encoded .. LibDeflate:EncodeForWoWAddonChannel(compressed)
  end
  return encoded
end

local function StringToTable(inString, fromPrint)
  local _, _, encodeVersion, encoded = inString:find("^(!NP:%d+!)(.+)$")
  encodeVersion = tonumber(encodeVersion:match("%d+")) or 1
  local decoded
  if fromPrint then
    decoded = LibDeflate:DecodeForPrint(encoded)
  else
    decoded = LibDeflate:DecodeForWoWAddonChannel(encoded)
  end
  if not decoded then
    return "Error decoding."
  end
  local decompressed = LibDeflate:DecompressDeflate(decoded)
  if not decompressed then
    return "Error decompressing."
  end
  local success, deserialized = LibSerialize:Deserialize(decompressed)
  if not success then
    return "Error deserializing: " .. deserialized
  end
  return deserialized
end

local function ShowTooltip(lines)
  ItemRefTooltip:ClearLines()
  if not ItemRefTooltip:IsVisible() then
    ItemRefTooltip:SetOwner(UIParent, "ANCHOR_PRESERVE")
  end
  for i, line in ipairs(lines) do
    local sides, a1, a2, a3, a4, a5, a6, a7, a8 = unpack(line)
    if sides == 1 then
      ItemRefTooltip:AddLine(a1, a2, a3, a4, a5)
    elseif sides == 2 then
      ItemRefTooltip:AddDoubleLine(a1, a2, a3, a4, a5, a6, a7, a8)
    end
  end
  ItemRefTooltip:Show()
end

local function HandleProfileChatFilter(msg, event, player, l, cs, t, flag, channelId, ...)
  local selfName = ShortName(UnitName("player"))
  if flag == "GM" or flag == "DEV" or (event == "CHAT_MSG_CHANNEL" and type(channelId) == "number" and channelId > 0) then
    return
  end
  local newMsg = ""
  local remaining = msg
  local done
  repeat
    local start, finish, characterName, profileName = remaining:find("%[NotPlater: ([^%s]+) %- (.*)%]")
    if characterName and profileName then
      characterName = characterName:gsub("|c[Ff][Ff]......", ""):gsub("|r", "")
      profileName = profileName:gsub("|c[Ff][Ff]......", ""):gsub("|r", "")
      if player and ShortName(player) == selfName then
        RecordLinkedProfile(profileName)
      end
      newMsg = newMsg .. remaining:sub(1, start - 1)
      newMsg = newMsg .. "|HNotPlater:" .. characterName .. ":" .. profileName .. "|h|cFF8800FF[" .. characterName .. " |r|cFF8800FF- " .. profileName .. "]|h|r"
      remaining = remaining:sub(finish + 1)
    else
      done = true
    end
  until done
  if newMsg ~= "" then
    if event == "CHAT_MSG_WHISPER" and not (UnitInParty(player) or UnitInRaid(player)) then
      return true -- Filter strangers not in group
    end
    return false, newMsg, player, l, cs, t, flag, channelId, ...
  end
end

local function LegacyChatFilter(msg, event, _, player, l, cs, t, flag, channelId, ...)
  return HandleProfileChatFilter(msg, event, player, l, cs, t, flag, channelId, ...)
end

local function ModernChatFilter(_, event, msg, player, l, cs, t, flag, channelId, ...)
  return HandleProfileChatFilter(msg, event, player, l, cs, t, flag, channelId, ...)
end

local chatFilterFunc = NotPlater.isWrathClient and ModernChatFilter or LegacyChatFilter

ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL", chatFilterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_YELL", chatFilterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_GUILD", chatFilterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_OFFICER", chatFilterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_PARTY", chatFilterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_PARTY_LEADER", chatFilterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID", chatFilterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID_LEADER", chatFilterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_SAY", chatFilterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", chatFilterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER_INFORM", chatFilterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_BATTLEGROUND", chatFilterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_BATTLEGROUND_LEADER", chatFilterFunc)

local origSetItemRef = SetItemRef
SetItemRef = function(link, text, button, chatFrame)
  local linkType, characterName, profileName = link:match("^(%w+):([^:]+):(.+)$")
  if linkType == "NotPlater" and characterName and profileName then
    if IsShiftKeyDown() then
      local editbox = GetCurrentKeyBoardFocus()
      if editbox then
        editbox:Insert("[NotPlater: " .. characterName .. " - " .. profileName .. "]")
      end
    else
      ShowTooltip({
        {2, "NotPlater", profileName, 0.5, 0, 1, 1, 1, 1},
        {1, L["Requesting profile information from %s ..."]:format(characterName), 1, 0.82, 0},
        {1, L["Note, that cross realm transmission may not be supported in this version"], 1, 0.82, 0}
      })
      tooltipLoading = true
      receivedData = false
      ProfileSharing:RequestProfile(characterName, profileName)
      local timer = CreateFrame("Frame")
      timer:SetScript("OnUpdate", function(self, elapsed)
        self.time = (self.time or 0) + elapsed
        if self.time > 5 then
          if tooltipLoading and not receivedData then
            ShowTooltip({
              {2, "NotPlater", profileName, 0.5, 0, 1, 1, 1, 1},
              {1, L["Error not receiving profile information from %s"]:format(characterName), 1, 0, 0},
              {1, L["Note, that cross realm transmission may not be supported in this version"], 1, 0.82, 0}
            })
          end
          self:SetScript("OnUpdate", nil)
        end
      end)
    end
  else
    origSetItemRef(link, text, button, chatFrame)
  end
end

function ProfileSharing:OnInitialize()
  self.exportString = ""
  self.importString = ""
  self.importProfileName = ""
  self.switchToImportedProfile = true
  self.lastExportSummary = L["Generate an export string to populate this field."]
  self.lastImportSummary = L["No import has been processed yet."]
  AceComm:RegisterComm(addonPrefix, function(_, message, distribution, sender)
    local payload
    if distribution == "WHISPER" then
      payload = message
    elseif distribution == "PARTY" or distribution == "RAID" then
      local dest, encoded = message:match("^§§([^:]+):(.+)$")
      if not dest then
        return
      end
      local playerShort = ShortName(UnitName("player"))
      if ShortName(dest) ~= playerShort then
        return
      end
      payload = encoded
    else
      return
    end

    local received = StringToTable(payload, false)
    if type(received) == "string" then
      return
    end

    local senderKey = ShortName(sender) or sender

    if received.m == "pR" then
      local requestedProfile = received.n
      if not requestedProfile then
        return
      end
      if not safeSenders[senderKey] and not IsLinkedProfileRecent(requestedProfile) then
        return
      end
      self:TransmitProfile(sender, requestedProfile)
    elseif received.m == "p" then
      if not safeSenders[senderKey] then
        return
      end
      safeSenders[senderKey] = nil
      tooltipLoading = false
      receivedData = true
      ItemRefTooltip:Hide()
      local data = received.d
      local profName = received.n
      local serialized = LibSerialize:SerializeEx(configForLS, data)
      local compressed = LibDeflate:CompressDeflate(serialized, configForDeflate)
      local encoded = "!NP:1!" .. LibDeflate:EncodeForPrint(compressed)
      self:SetImportString(encoded)
      self:SetImportProfileName("Imported from " .. (ShortName(sender) or sender) .. " (" .. profName .. ")")
      OpenSharingOptions()
    end
  end)
end

function ProfileSharing:GenerateExportString()
  local profile = NotPlater.db.profile
  local data = CopyTable(profile)
  local serialized = LibSerialize:SerializeEx(configForLS, data)
  if not serialized then
    return nil, "Serialization failed"
  end
  local compressed = LibDeflate:CompressDeflate(serialized, configForDeflate)
  local encoded = LibDeflate:EncodeForPrint(compressed)
  self.exportString = "!NP:1!" .. encoded
  self.lastExportSummary = L["Profile exported: "] .. NotPlater.db:GetCurrentProfile()
  return self.exportString
end

function ProfileSharing:GetExportString()
  return self.exportString
end

function ProfileSharing:InsertShareLink()
  local raidMembers = GetNumRaidMembers()
  local partyMembers = GetNumPartyMembers()
  local channel
  if raidMembers and raidMembers > 0 then
    channel = "RAID"
  elseif partyMembers and partyMembers > 0 then
    channel = "PARTY"
  else
    NotPlater:Print(L["Profile sharing requires being in a party or raid."])
    return false
  end
  local profileName = NotPlater.db:GetCurrentProfile()
  local link = "[NotPlater: " .. UnitName("player") .. " - " .. profileName .. "]"
  SendChatMessage(link, channel)
  RecordLinkedProfile(profileName)
  return true
end

function ProfileSharing:SetImportString(value)
  self.importString = value
end

function ProfileSharing:GetImportString()
  return self.importString
end

function ProfileSharing:SetImportProfileName(value)
  self.importProfileName = value
end

function ProfileSharing:GetImportProfileName()
  return self.importProfileName
end

function ProfileSharing:SetSwitchToImportedProfile(value)
  self.switchToImportedProfile = value
end

function ProfileSharing:GetSwitchToImportedProfile()
  return self.switchToImportedProfile
end

function ProfileSharing:GetLastExportSummary()
  return self.lastExportSummary
end

function ProfileSharing:GetLastImportSummary()
  return self.lastImportSummary
end

function ProfileSharing:ImportFromOptions()
  local str = self.importString
  if not str:match("^!NP:1!") then
    self.lastImportSummary = L["Invalid import string"]
    return
  end
  local data = StringToTable(str, true)
  if type(data) == "string" then
    self.lastImportSummary = data
    return
  end
  local name = self.importProfileName
  if name == "" then
    name = "Imported"
  end
  local baseName = name
  local i = 2
  while NotPlater.db.profiles[name] do
    name = baseName .. " " .. i
    i = i + 1
  end
  NotPlater.db.profiles[name] = data
  self.lastImportSummary = L["Imported as "] .. name
  if self.switchToImportedProfile then
    NotPlater.db:SetProfile(name)
    NotPlater:Reload()
  end
  if registry then
    registry:NotifyChange("NotPlater")
  end
end

function ProfileSharing:RequestProfile(characterName, profileName)
  local senderKey = ShortName(characterName) or characterName
  safeSenders[senderKey] = true
  local transmit = {m = "pR", n = profileName}
  local transmitString = TableToString(transmit, false)
  SendProfileCommMessage(transmitString, characterName)
end

function ProfileSharing:TransmitProfile(characterName, requestedProfile)
  local profileName = requestedProfile or NotPlater.db:GetCurrentProfile()
  local sourceProfile = NotPlater.db.profiles[profileName]
  if not sourceProfile then
    profileName = NotPlater.db:GetCurrentProfile()
    sourceProfile = NotPlater.db.profile
  end
  local data = CopyTable(sourceProfile)
  local transmit = {m = "p", d = data, n = profileName}
  local encoded = TableToString(transmit, false)
  SendProfileCommMessage(encoded, characterName, "BULK")
end
