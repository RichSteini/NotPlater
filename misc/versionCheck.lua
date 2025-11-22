if not NotPlater then
	return
end

local VersionCheck = NotPlater:NewModule("VersionCheck", "AceEvent-3.0", "AceTimer-3.0")
local AceComm = LibStub("AceComm-3.0")
local L = NotPlaterLocals

local COMM_PREFIX = "NotPlaterVC"
local BROADCAST_DELAY = 2
local UPDATE_LINK = "https://github.com/RichSteini/NotPlater"
local LINK_COLOR = "|cff5daeff"
local IS_WRATH_CLIENT = NotPlater.isWrathClient

local UnitName = UnitName
local GetNumPartyMembers = GetNumPartyMembers
local GetNumRaidMembers = GetNumRaidMembers
local max = math.max

local function ShortName(name)
	if not name or name == "" then
		return nil
	end
	local dash = name:find("-")
	if dash then
		return name:sub(1, dash - 1)
	end
	return name
end

local function BuildRevisionParts(revision)
	if type(revision) ~= "string" then
		return nil
	end
	local trimmed = revision:match("%S") and revision:gsub("^%D+", "") or nil
	if not trimmed or trimmed == "" then
		return nil
	end
	local parts = {}
	for value in trimmed:gmatch("%d+") do
		local number = tonumber(value)
		if number then
			parts[#parts + 1] = number
		end
	end
	if #parts == 0 then
		return nil
	end
	return parts
end

local function BuildUpdateHyperlink()
	if IS_WRATH_CLIENT then
		return ("|Hurl:%s|h%s%s|r|h"):format(UPDATE_LINK, LINK_COLOR, UPDATE_LINK)
	end
	return UPDATE_LINK
end

local function IsRevisionNewer(left, right)
	if type(left) ~= "string" or left == "" then
		return false
	end
	local leftParts = BuildRevisionParts(left)
	if not leftParts then
		return false
	end
	local rightParts = BuildRevisionParts(right)
	if not rightParts then
		return true
	end
	local maxIndex = max(#leftParts, #rightParts)
	for index = 1, maxIndex do
		local leftValue = leftParts[index] or 0
		local rightValue = rightParts[index] or 0
		if leftValue > rightValue then
			return true
		elseif leftValue < rightValue then
			return false
		end
	end
	return false
end

function VersionCheck:OnInitialize()
	self.highestRemoteRevision = nil
	self.pendingBroadcast = nil

	AceComm:RegisterComm(COMM_PREFIX, function(_, message, _, sender)
		self:OnCommReceived(message, sender)
	end)
end

function VersionCheck:OnEnable()
	self:RegisterEvent("PARTY_MEMBERS_CHANGED", "HandleGroupChange")
	self:RegisterEvent("RAID_ROSTER_UPDATE", "HandleGroupChange")
	self:HandleGroupChange()
end

function VersionCheck:OnDisable()
	self:CancelPendingBroadcast()
end

function VersionCheck:HandleGroupChange()
	self:CancelPendingBroadcast()
	if self:GetGroupChannel() then
		self.pendingBroadcast = self:ScheduleTimer("BroadcastVersion", BROADCAST_DELAY)
	end
end

function VersionCheck:GetGroupChannel()
	if GetNumRaidMembers() and GetNumRaidMembers() > 0 then
		return "RAID"
	end
	if GetNumPartyMembers() and GetNumPartyMembers() > 0 then
		return "PARTY"
	end
	return nil
end

function VersionCheck:BroadcastVersion()
	self.pendingBroadcast = nil
	local channel = self:GetGroupChannel()
	if not channel then
		return
	end
	local revision = NotPlater.revision or ""
	if revision == "" then
		revision = "0"
	end
	AceComm:SendCommMessage(COMM_PREFIX, "V:" .. revision, channel)
end

function VersionCheck:CancelPendingBroadcast()
	if self.pendingBroadcast then
		self:CancelTimer(self.pendingBroadcast)
		self.pendingBroadcast = nil
	end
end

function VersionCheck:OnCommReceived(message, sender)
	if not message or not sender then
		return
	end
	local playerName = UnitName("player")
	if ShortName(sender) == ShortName(playerName) then
		return
	end
	local remoteRevision = message:match("^V:(.+)$")
	if not remoteRevision then
		return
	end
	local localRevision = NotPlater.revision
	if not IsRevisionNewer(remoteRevision, localRevision) then
		return
	end
	if self.highestRemoteRevision and not IsRevisionNewer(remoteRevision, self.highestRemoteRevision) then
		return
	end
	self.highestRemoteRevision = remoteRevision

	local hyperlink = BuildUpdateHyperlink()
	local template = L and L["NewVersionNotice"] or "A newer version of NotPlater (%s) is available. Get it from: %s"
	local notice = template:format(remoteRevision, hyperlink)
	NotPlater:Print(notice)
end
