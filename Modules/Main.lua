require "Apollo"
require "ApolloTimer"
require "GameLib"
require "GroupLib"

local Threat = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("Threat")
local Main = Threat:NewModule("Main")

Main.tThreatList = {}
Main.nDuration = 0
Main.nLastEvent = 0

Main.CanInstantUpdate = true
Main.UpdateAwaiting = false

function Main:OnInitialize()
	-- Create a timer to track combat status. Needed for TPS calculations.
	self.tCombatTimer = ApolloTimer.Create(1, true, "OnCombatTimer", self)
	self.tCombatTimer:Stop()

	-- Create a timer to update the UI.
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

	self.tCombatTimer:Start()
	self.tUpdateTimer:Start()
end

function Main:OnDisable()
	Apollo.RemoveEventHandler("TargetThreatListUpdated", self)
	Apollo.RemoveEventHandler("TargetUnitChanged", self)

	self.tCombatTimer:Stop()
	self.tUpdateTimer:Stop()
end

function Main:OnTargetThreatListUpdated(...)
	self.tThreatList = {}
	self.nLastEvent = os.time()

	-- Create the new threat list
	for nId = 1, select("#", ...), 2 do
		local oUnit = select(nId, ...)
		local nValue = select(nId + 1, ...)
		if oUnit ~= nil then
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

	if self.CanInstantUpdate then
		self:UpdateUI()
	else
		self.UpdateAwaiting = true
	end
end

function Main:OnTargetUnitChanged(unitTarget)
	--self.wndList:DestroyChildren()
	--self.wndNotifier:Show(false)

	--self.CanInstantUpdate = true --Not really worked the way i wanted it to
end

function Main:OnCombatTimer()
	if os.time() >= (self.nLastEvent + Threat.tOptions.profile.nCombatDelay) then
		--self.wndList:DestroyChildren()
		self.nDuration = 0

		--if Threat:GetModule("Settings").wndNotifySettings == nil then
		--	self.wndNotifier:Show(false)
		--end
	else
		self.nDuration = self.nDuration + 1
	end
end

function Main:OnUpdateTimer()
	if self.UpdateAwaiting then
		self:UpdateUI()
	else
		self.CanInstantUpdate = true
	end
end

--------------------------------
-- Work needs to be done here --
--------------------------------
function Main:UpdateUI()
	self.CanInstantUpdate = false
	self.UpdateAwaiting = false

	if self.wndMain == nil then
		return
	end

	if not Threat.tOptions.profile.bShowSolo and #self.tThreatList < 2 then
		self.wndList:DestroyChildren()
		self.wndNotifier:Show(false)
		return
	end

	--Set correct amount of bars
	self:CreateBars(self.wndList, #self.tThreatList)

	local nBars = #self.wndList:GetChildren()
	local nPlayerId = GameLib.GetPlayerUnit():GetId()
	local nPlayerIndex = -1

	--Set bar data
	if #self.tThreatList > 0 and nBars > 0 then
		local nTopThreat = self.tThreatList[1].nValue

		for tIndex, tEntry in ipairs(self.tThreatList) do
			if nBars >= tIndex then
				self:SetupBar(self.wndList:GetChildren()[tIndex], tEntry, tIndex == 1, nTopThreat, nPlayerId)
			end

			if nPlayerId == tEntry.nId then
				nPlayerIndex = tIndex
			end
		end

		self.wndList:ArrangeChildrenVert()
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
