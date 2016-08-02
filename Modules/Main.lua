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
	self.tUpdateTimer = ApolloTimer.Create(0.5, true, "OnUpdateTimer", self)
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

	self:SetTimerUpdateRate()
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

function Main:UpdateUI()
	self.bUpdateAwaiting = false
	self.bCanInstantUpdate = false

	if self.bInPreview then return end

	if (#self.tThreatList < 1) or (not Threat.tOptions.profile.bShowSolo and #self.tThreatList < 2) then
		self.ClearUI()
		return
	end

	local nPlayerId = GameLib.GetPlayerUnit():GetId()
	local nPlayerIndex = -1

	local nTopThreatFirst = self.tThreatList[1].nValue
	local nTopThreatSecond = self.tThreatList[2].nValue or 0
	local nTopThreatTank = 0

	local bInGroup = GroupLib.InGroup()
	local bIsPlayerTank = false
	if bInGroup then

	end

	for tIndex, tEntry in ipairs(self.tThreatList) do
		if nPlayerId == tEntry.nId then
			nPlayerIndex = tIndex
		end
		
	end

	--Notification
	if self.wndNotify == nil then
		return
	end

	if nPlayerIndex ~= -1 and Threat.tOptions.profile.bShowNotify and GroupLib.InGroup() then
		if Threat.tOptions.profile.bNotifyOnlyInRaid and not GroupLib:InRaid() then
			self.wndNotifier:Show(false)
			return
		end

		local tEntry = self.tThreatList[nPlayerIndex]
		local nPercent = tEntry.nValue / self.tThreatList[1].nValue
		
		if nPercent >= Threat.tOptions.profile.nShowNotifySoft then
			local bIsTank = false

			for nIdx = 1, GroupLib.GetMemberCount() do
				local tMemberData = GroupLib.GetGroupMember(nIdx)
				if tMemberData.strCharacterName == tEntry.sName then
					bIsTank = tMemberData.bTank
					break
				end
			end
			
			if not bIsTank then
				if nPercent >= Threat.tOptions.profile.nShowNotifyHard then
					if nPercent == 1 then
						self:SetNotifyVisual(3, nPercent)
					else
						self:SetNotifyVisual(2, nPercent)
					end
				else
					self:SetNotifyVisual(1, nPercent)
				end
				return
			end
		end
	end

	--This won't get called if there was a notify
	self.wndNotifier:Show(false)
end

function Main:ClearUI()
	if self.bInPreview then return end

	
end
