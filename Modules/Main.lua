require "Apollo"
require "ApolloTimer"
require "GameLib"
require "GroupLib"

local Threat = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("Threat")
local Main = Threat:NewModule("Main")

Main.tThreatList = {}
Main.bCanInstantUpdate = true
Main.bUpdateAwaiting = false

Main.ModuleList = nil
Main.ModuleNotify = nil
Main.ModuleMini = nil

Main.bInPreview = false

function Main:OnInitialize()
	self.tUpdateTimer = ApolloTimer.Create(Threat.tOptions.profile.nUpdateRate, true, "OnUpdateTimer", self)
	self.tUpdateTimer:Stop()
end

function Main:SetUpdateTimerRate()
	if self.tUpdateTimer == nil then return end
	self.tUpdateTimer:Set(Threat.tOptions.profile.nUpdateRate, true, "OnUpdateTimer")
end

function Main:OnEnable()
	if not Threat.tOptions.profile.bEnabled then
		self:Disable()
		return
	end

	Apollo.RegisterEventHandler("TargetThreatListUpdated", "OnTargetThreatListUpdated", self)
	Apollo.RegisterEventHandler("TargetUnitChanged", "OnTargetUnitChanged", self)

	self:SetUpdateTimerRate()
	self.tUpdateTimer:Start()
end

function Main:OnDisable()
	Apollo.RemoveEventHandler("TargetThreatListUpdated", self)
	Apollo.RemoveEventHandler("TargetUnitChanged", self)

	self.tUpdateTimer:Stop()
end

function Main:OnTargetThreatListUpdated(...)
	self.tThreatList = {}

	-- Create the new threat list
	for nId = 1, select("#", ...), 2 do
		local oUnit = select(nId, ...)
		local nValue = select(nId + 1, ...)
		if oUnit ~= nil and nValue ~= nil and nValue > 0 then
			table.insert(self.tThreatList, {
				nId = oUnit:GetId(),
				sName = oUnit:GetName(),
				eClass = oUnit:GetClassId(),
				bPet = oUnit:GetUnitOwner() ~= nil,
				nValue = nValue
			})
		end
	end

	-- Sort the new threat list
	table.sort(self.tThreatList,
		function(oValue1, oValue2)
			return oValue1.nValue > oValue2.nValue
		end
	)

	if self.bCanInstantUpdate then
		self:UpdateUI()
	else
		self.bUpdateAwaiting = true
	end
end

function Main:OnTargetUnitChanged(unitTarget)
	self:ClearUI()
	self.bCanInstantUpdate = true
end

function Main:OnUpdateTimer()
	if self.bUpdateAwaiting then
		self:UpdateUI()
	else
		self.bCanInstantUpdate = true
	end
end

--[[ Main UI update function ]]--
function Main:UpdateUI()
	-- Set variables so we know an update happened
	self.bUpdateAwaiting = false
	self.bCanInstantUpdate = false

	-- Checks
	if self.bInPreview then return end

	if (#self.tThreatList < 1) or (not Threat.tOptions.profile.bShowSolo and #self.tThreatList < 2) then
		self.ClearUI()
		return
	end

	-- Creating variables for the UI update
	local oPlayer = GameLib.GetPlayerUnit()
	local nPlayerValue = 0

	local nTopThreatFirst = self.tThreatList[1].nValue
	local nTopThreatSecond = self.tThreatList[2].nValue or 0
	local nTopThreatTank = 0

	local bInGroup = GroupLib.InGroup()
	local bIsPlayerTank = false
	local tTanks = {}

	-- Getting tank names
	if bInGroup then
		for nIdx = 1, GroupLib.GetMemberCount() do
			local tMemberData = GroupLib.GetGroupMember(nIdx)

			if tMemberData.strCharacterName == oPlayer:GetName() then
				bIsPlayerTank = tMemberData.bTank
			end

			if tMemberData.bTank then
				table.insert(tTanks, tMemberData.strCharacterName)
			end
		end
	end

	-- Getting info from the tThreatList
	for nIndex, tEntry in ipairs(self.tThreatList) do
		if nPlayerValue == 0 and oPlayer:GetId() == tEntry.nId then
			nPlayerValue = tEntry.nValue
		end

		if nTopThreatTank == 0 then
			for _, strTankName in ipairs(tTanks) do
				if tEntry.sName == strTankName then
					nTopThreatTank = tEntry.nValue
					break
				end
			end
		end
	end

	-- Calling UI module updates
end

function Main:ClearUI()
	if self.bInPreview then return end

	-- Calling UI module clears
end
