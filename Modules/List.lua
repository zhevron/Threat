require "Apollo"
require "ApolloTimer"
require "GameLib"
require "GroupLib"

local Threat = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("Threat")
local List = Threat:NewModule("List")

function List:OnInitialize()
	self.mytimer = ApolloTimer.Create(1, true, "OnTest", self)
	self.mytimer:Start()
end

function List:OnTest()
		Print("Test - List Module")
end

function List:OnEnable()
	self.mytimer:Start()
end

function List:OnDisable()
	self.mytimer:Stop()
end

--------------------------------------------------------------

Main.nBarHeight = 10
Main.nBarSlots = 0

function Main:OnInitialize()
	self.oXml = XmlDoc.CreateFromFile("Forms/Main.xml")
	if self.oXml == nil then
		Apollo.AddAddonErrorText(Threat, "Could not load the Threat window!")
		return
	end
	self.oXml:RegisterCallback("OnDocumentReady", self)
end

function Main:OnEnable()
	if self.wndMain ~= nil then
		self.wndMain:Show(true)
	end

	if self.wndNotify ~= nil then
		self.wndNotify:Show(true)
	end

	if not Threat.tOptions.profile.bEnabled then
		self:Disable()
	end
end

function Main:OnDisable()
	if self.wndMain ~= nil then
		self.wndMain:Show(false)
	end

	if self.wndNotify ~= nil then
		self.wndNotify:Show(false)
	end
end

function Main:OnDocumentReady()
	self.wndMain = Apollo.LoadForm(self.oXml, "Threat", nil, self)

	self.wndNotify = Apollo.LoadForm(self.oXml, "Notification", nil, self)

	self.wndList = self.wndMain:FindChild("BarList")
	self.wndNotifier = self.wndNotify:FindChild("Notifier")

	self:UpdatePosition()
	self:UpdateNotifyPosition()
	self:UpdateLockStatus()

	--Get Bar Size
	local wndBarTemp = Apollo.LoadForm(self.oXml, "Bar", nil, self)
	self.nBarHeight = wndBarTemp:GetHeight()
	wndBarTemp:Destroy()

	self:SetBarSlots()
end

function Main:SetBarSlots()
	self.nBarSlots = math.floor(self.wndList:GetHeight() / self.nBarHeight)
end

function Main:CreateBars(wndList, nTListNum)
	local nListNum = #wndList:GetChildren()
	local nThreatListNum = math.min(self.nBarSlots, nTListNum)

	--Check if needs to do any work
	if nListNum ~= nThreatListNum then
		if nListNum > nThreatListNum then
			--If needs to remove some bars
			for nIdx = nListNum, nThreatListNum + 1, -1 do
				wndList:GetChildren()[nIdx]:Destroy()
			end
		else
			--If needs to create some bars
			for nIdx = nListNum + 1, nThreatListNum do
				Apollo.LoadForm(self.oXml, "Bar", wndList, self)
			end
		end
	end
end

--Window Events

function Main:OnMouseEnter()
	if not Threat.tOptions.profile.bLock then
		self.wndMain:FindChild("Background"):Show(true)
	end
end

function Main:OnMouseExit()
	if not Threat:GetModule("Settings").wndMain:IsShown() then
		self.wndMain:FindChild("Background"):Show(false)
	end
end

function Main:OnMouseButtonUp(wndHandler, wndControl, eMouseButton)
	if eMouseButton == GameLib.CodeEnumInputMouse.Right then
		if not Threat.tOptions.profile.bLock then
			Threat:GetModule("Settings"):Open()
		end
	end
end

function Main:OnWindowMove()
	local nLeft, nTop = self.wndMain:GetAnchorOffsets()
	Threat.tOptions.profile.tPosition.nX = nLeft
	Threat.tOptions.profile.tPosition.nY = nTop
end

function Main:OnWindowSizeChanged()
	local nLeft, nTop, nRight, nBottom = self.wndMain:GetAnchorOffsets()
	Threat.tOptions.profile.tSize.nWidth = nRight - nLeft
	Threat.tOptions.profile.tSize.nHeight = nBottom - nTop

	self:SetBarSlots()
end

-- Setupbar +

function Main:SetupBar(wndBar, tEntry, bFirst, nHighest, nPlayerId)
	-- Perform calculations for this entry.
	local nPerSecond = tEntry.nValue / self.nDuration
	local nPercent = 1
	local sValue = Threat:GetModule("Utility"):FormatNumber(tEntry.nValue, 2)

	-- Show the difference if enabled and not the first bar
	if not bFirst then
		nPercent = tEntry.nValue / nHighest
		if Threat.tOptions.profile.bShowDifferences then
			sValue = "-"..Threat:GetModule("Utility"):FormatNumber(nHighest - tEntry.nValue, 2)
		end
	end

	-- Set the name string to the character name
	wndBar:FindChild("Name"):SetText(tEntry.sName)

	-- Print threat per second as a floating point number with a precision of 1. (Ex. 7572.2)
	if Threat.tOptions.profile.bShowThreatPerSec then
		wndBar:FindChild("ThreatPerSecond"):SetText(string.format("%.1f", nPerSecond))
	else
		wndBar:FindChild("ThreatPerSecond"):SetText("")
	end

	-- Print the total as a string with the formatted number and percentage of total. (Ex. 300k  42%)
	wndBar:FindChild("Total"):SetText(string.format("%s  %d%s", sValue, nPercent * 100, "%"))

	-- Update the progress bar with the new values and set the bar color.
	local wndBarBackground = wndBar:FindChild("Background")
	local nR, nG, nB, nA = self:GetColorForEntry(tEntry, bFirst, nPlayerId)
	local _, nTop, _, nBottom = wndBarBackground:GetAnchorPoints()
	
	if Threat.tOptions.profile.bRightToLeftBars then
		wndBarBackground:SetAnchorPoints(1 - nPercent, nTop, 1, nBottom)
	else
		wndBarBackground:SetAnchorPoints(0, nTop, nPercent, nBottom)
	end
	
	wndBarBackground:SetBGColor(ApolloColor.new(nR, nG, nB, nA))
end

function Main:GetColorForEntry(tEntry, bFirst, nPlayerId)
	local tColor = nil
	local tWhite = { nR = 255, nG = 255, nB = 255, nA = 255 }
	local bForceSelf = false

	-- Determine the color of the bar based on user settings.
	if Threat.tOptions.profile.bUseClassColors then
		-- Use class color. Defaults to white if not found.
		tColor = Threat.tOptions.profile.tColors[tEntry.eClass] or tWhite
	elseif Threat.tOptions.profile.bUseRoleColors and GroupLib.InGroup() then
		-- Use role color. Defaults to white if not found.
		for nIdx = 1, GroupLib.GetMemberCount() do
			local tMemberData = GroupLib.GetGroupMember(nIdx)
			if tMemberData.strCharacterName == tEntry.sName then
				if tMemberData.bTank then
					tColor = Threat.tOptions.profile.tColors.tTank or tWhite
				elseif tMemberData.bHealer then
					tColor = Threat.tOptions.profile.tColors.tHealer or tWhite
				else
					tColor = Threat.tOptions.profile.tColors.tDamage or tWhite
				end
			end
		end
		if tColor == nil then
			tColor = Threat.tOptions.profile.tColors.tOthers or tWhite
		end
	else
		-- Use non-class colors. Defaults to white if not found.
		bForceSelf = true
		tColor = Threat.tOptions.profile.tColors.tOthers or tWhite
	end

	
	if Threat.tOptions.profile.bUseSelfColor or bForceSelf then
		if nPlayerId == tEntry.nId then
			-- This unit is the current player.
			if Threat.tOptions.profile.bShowSelfWarning and bFirst ~= nil and bFirst then
				tColor = Threat.tOptions.profile.tColors.tSelfWarning or tWhite
			else
				tColor = Threat.tOptions.profile.tColors.tSelf or tWhite
			end
		end
	end

	if tEntry.bPet then
		tColor = Threat.tOptions.profile.tColors.tPet or tWhite
	end

	return (tColor.nR / 255), (tColor.nG / 255), (tColor.nB / 255), (tColor.nA / 255)
end

-- Extra

function Main:UpdatePosition()
	local nLeft = Threat.tOptions.profile.tPosition.nX
	local nTop = Threat.tOptions.profile.tPosition.nY
	local nWidth = Threat.tOptions.profile.tSize.nWidth
	local nHeight = Threat.tOptions.profile.tSize.nHeight
	self.wndMain:SetAnchorOffsets(nLeft, nTop, nLeft + nWidth, nTop + nHeight)
end

function Main:UpdateLockStatus()
	self.wndMain:SetStyle("Moveable", not Threat.tOptions.profile.bLock)
	self.wndMain:SetStyle("Sizable", not Threat.tOptions.profile.bLock)
	self.wndMain:SetStyle("IgnoreMouse", Threat.tOptions.profile.bLock)

	self.wndNotify:SetStyle("Moveable", not Threat.tOptions.profile.bLock)
	self.wndNotify:SetStyle("IgnoreMouse", Threat.tOptions.profile.bLock)
end

--User Test

function Main:ShowTestBars()
	local L = Apollo.GetPackage("Gemini:Locale-1.0").tPackage:GetLocale("Threat", true)
	local nPlayerId = GameLib.GetPlayerUnit():GetId()
	local tEntries = {
		{
			nId = 0,
			sName = GameLib.GetClassName(GameLib.CodeEnumClass.Warrior),
			eClass = GameLib.CodeEnumClass.Warrior,
			bPet = false,
			nValue = 1000000
		},
		{
			nId = 0,
			sName = GameLib.GetClassName(GameLib.CodeEnumClass.Engineer),
			eClass = GameLib.CodeEnumClass.Engineer,
			bPet = false,
			nValue = 900000
		},
		{
			nId = 0,
			sName = GameLib.GetClassName(GameLib.CodeEnumClass.Esper),
			eClass = GameLib.CodeEnumClass.Esper,
			bPet = false,
			nValue = 800000
		},
		{
			nId = 0,
			sName = GameLib.GetClassName(GameLib.CodeEnumClass.Medic),
			eClass = GameLib.CodeEnumClass.Medic,
			bPet = false,
			nValue = 700000
		},
		{
			nId = nPlayerId,
			sName = GameLib.GetClassName(GameLib.CodeEnumClass.Spellslinger),
			eClass = GameLib.CodeEnumClass.Spellslinger,
			bPet = false,
			nValue = 600000
		},
		{
			nId = 0,
			sName = GameLib.GetClassName(GameLib.CodeEnumClass.Stalker),
			eClass = GameLib.CodeEnumClass.Stalker,
			bPet = false,
			nValue = 500000
		},
		{
			nId = 0,
			sName = L["pet"],
			eClass = nil,
			bPet = true,
			nValue = 400000
		}
	}

	self.nDuration = 10
	self:CreateBars(self.wndList, #tEntries)

	local nTopThreat = tEntries[1].nValue
	local nBars = #self.wndList:GetChildren()

	if nBars > 0 then
		for tIndex, tEntry in pairs(tEntries) do
			self:SetupBar(self.wndList:GetChildren()[tIndex], tEntry, tIndex == 1, nTopThreat, nPlayerId)
			if nBars == tIndex then break end
		end
		self.wndList:ArrangeChildrenVert()
	end

	self.nLastEvent = os.time() + 5
end


--- Changes needed !!!!!!

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