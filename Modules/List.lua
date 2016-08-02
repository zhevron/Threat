require "Apollo"
require "GameLib"
require "GroupLib"

local Threat = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("Threat")
local List = Threat:NewModule("List")

List.bActive = false
List.nBarHeight = 10
List.nBarSlots = 0

--[[ Initial functions ]]--

function List:OnInitialize()
	self.oXml = XmlDoc.CreateFromFile("Forms/List.xml")

	if self.oXml == nil then
		Apollo.AddAddonErrorText(Threat, "Could not load the Threat list window!")
		return
	end

	self.oXml:RegisterCallback("OnDocumentReady", self)
end

function List:OnDocumentReady()
	self.wndMain = Apollo.LoadForm(self.oXml, "ThreatList", nil, self)
	self.wndList = self.wndMain:FindChild("BarList")

	self:UpdatePosition()
	self:UpdateLockStatus()

	self.wndMain:Show(false)

	--Get Bar Size
	local wndBarTemp = Apollo.LoadForm(self.oXml, "Bar", nil, self)
	self.nBarHeight = wndBarTemp:GetHeight()
	wndBarTemp:Destroy()

	self:SetBarSlots()
end

function List:SetBarSlots()
	self.nBarSlots = math.floor(self.wndList:GetHeight() / self.nBarHeight)
end

function List:OnEnable()
end

function List:OnDisable()
end

--[[ Update and Clear ]]--

function List:Update(tThreatList, nPlayerId, nHighest)
	if self.wndMain == nil then return end

	self.bActive = true
	self.wndMain:Show(true)
	self:CreateBars(#tThreatList)

	local nBars = #self.wndList:GetChildren()

	for nIndex, tEntry in ipairs(tThreatList) do
		if nBars >= nIndex then
			self:SetupBar(self.wndList:GetChildren()[nIndex], tEntry, nIndex == 1, nHighest, nPlayerId)
		else break end
	end

	self.wndList:ArrangeChildrenVert()
end

function List:Clear()
	self.bActive = false
	self.wndMain:Show(false)
	self.wndList:DestroyChildren()
end

--[[ Bar setup functions ]]--

function List:CreateBars(nTListNum)
	local nListNum = #self.wndList:GetChildren()
	local nThreatListNum = math.min(self.nBarSlots, nTListNum)

	--Check if needs to do any work
	if nListNum ~= nThreatListNum then
		if nListNum > nThreatListNum then
			--If needs to remove some bars
			for nIdx = nListNum, nThreatListNum + 1, -1 do
				self.wndList:GetChildren()[nIdx]:Destroy()
			end
		else
			--If needs to create some bars
			for nIdx = nListNum + 1, nThreatListNum do
				Apollo.LoadForm(self.oXml, "Bar", wndList, self)
			end
		end
	end
end

function List:SetupBar(wndBar, tEntry, bFirst, nHighest, nPlayerId)
	-- Perform calculations for this entry.
	local nPercent = 1
	local sValue = self:FormatNumber(tEntry.nValue, 2)

	-- Show the difference if enabled and not the first bar
	if not bFirst then
		nPercent = tEntry.nValue / nHighest
		if Threat.tOptions.profile.tList.bShowDifferences then
			sValue = "-"..self:FormatNumber(nHighest - tEntry.nValue, 2)
		end
	end

	-- Set the name string to the character name
	wndBar:FindChild("Name"):SetText(tEntry.sName)

	-- Print the total as a string with the formatted number and percentage of total. (Ex. 300k  42%)
	wndBar:FindChild("Total"):SetText(string.format("%s  %d%s", sValue, nPercent * 100, "%"))

	-- Update the progress bar with the new values and set the bar color.
	local wndBarBackground = wndBar:FindChild("Background")
	local nR, nG, nB, nA = self:GetColorForEntry(tEntry, bFirst, nPlayerId)
	local _, nTop, _, nBottom = wndBarBackground:GetAnchorPoints()
	
	if Threat.tOptions.profile.tList.bRightToLeftBars then
		wndBarBackground:SetAnchorPoints(1 - nPercent, nTop, 1, nBottom)
	else
		wndBarBackground:SetAnchorPoints(0, nTop, nPercent, nBottom)
	end
	
	wndBarBackground:SetBGColor(ApolloColor.new(nR, nG, nB, nA))
end

function List:GetColorForEntry(tEntry, bFirst, nPlayerId)
	local tColor = nil
	local tWhite = { nR = 255, nG = 255, nB = 255, nA = 255 }
	local bForceSelfColor = false

	if tEntry.bPet then
		tColor = Threat.tOptions.profile.tList.tColors.tPet or tWhite
	else
		-- Determine the color of the bar based on user settings.
		if Threat.tOptions.profile.tList.nColorMode == 2 then
			-- Use class color. Defaults to white if not found.
			tColor = Threat.tOptions.profile.tList.tColors[tEntry.eClass] or tWhite
		elseif Threat.tOptions.profile.tList.nColorMode == 1 and GroupLib.InGroup() then
			-- Use role color. Defaults to white if not found.
			for nIdx = 1, GroupLib.GetMemberCount() do
				local tMemberData = GroupLib.GetGroupMember(nIdx)
				if tMemberData.strCharacterName == tEntry.sName then
					if tMemberData.bTank then
						tColor = Threat.tOptions.profile.tList.tColors.tTank or tWhite
					elseif tMemberData.bHealer then
						tColor = Threat.tOptions.profile.tList.tColors.tHealer or tWhite
					else
						tColor = Threat.tOptions.profile.tList.tColors.tDamage or tWhite
					end
				end
			end

			if tColor == nil then
				tColor = Threat.tOptions.profile.tList.tColors.tOthers or tWhite
			end
		else
			-- Use non-class colors. Defaults to white if not found.
			bForceSelfColor = true
			tColor = Threat.tOptions.profile.tList.tColors.tOthers or tWhite
		end

		if Threat.tOptions.profile.tList.bAlwaysUseSelfColor or bForceSelfColor then
			if nPlayerId == tEntry.nId then
				-- This unit is the current player.
				if Threat.tOptions.profile.tList.bUseSelfWarning and bFirst then
					tColor = Threat.tOptions.profile.tList.tColors.tSelfWarning or tWhite
				else
					tColor = Threat.tOptions.profile.tList.tColors.tSelf or tWhite
				end
			end
		end
	end

	return (tColor.nR / 255), (tColor.nG / 255), (tColor.nB / 255), (tColor.nA / 255)
end

function List:FormatNumber(nNumber, nPrecision)
	nPrecision = nPrecision or 0
	if nNumber >= 1000000 then
		return string.format("%."..nPrecision.."fm", nNumber / 1000000)
	elseif nNumber >= 10000 then
		return string.format("%."..nPrecision.."fk", nNumber / 1000)
	else
		return tostring(nNumber)
	end
end

--[[ Window events ]]--

function List:OnMouseEnter()
	if not Threat.tOptions.profile.bLock then
		self.wndMain:Show(true)
		self.wndMain:FindChild("Background"):Show(true)
	end
end

function List:OnMouseExit()
	if not Threat:GetModule("Settings").wndMain:IsShown() then
		if not self.bActive then self.wndMain:Show(false) end
		self.wndMain:FindChild("Background"):Show(false)
	end
end

function List:OnMouseButtonUp(wndHandler, wndControl, eMouseButton)
	if eMouseButton == GameLib.CodeEnumInputMouse.Right then
		if not Threat.tOptions.profile.bLock then
			Threat:GetModule("Settings"):Open()
		end
	end
end

function List:OnWindowMove()
	local nLeft, nTop = self.wndMain:GetAnchorOffsets()
	Threat.tOptions.profile.tList.tPosition.nX = nLeft
	Threat.tOptions.profile.tList.tPosition.nY = nTop
end

function List:OnWindowSizeChanged()
	local nLeft, nTop, nRight, nBottom = self.wndMain:GetAnchorOffsets()
	Threat.tOptions.profile.tList.tSize.nWidth = nRight - nLeft
	Threat.tOptions.profile.tList.tSize.nHeight = nBottom - nTop

	self:SetBarSlots()
end

--[[ Window updaters ]]--

function Main:UpdatePosition()
	if self.wndMain == nil then return end

	local nLeft = Threat.tOptions.profile.tList.tPosition.nX
	local nTop = Threat.tOptions.profile.tList.tPosition.nY
	local nWidth = Threat.tOptions.profile.tList.tSize.nWidth
	local nHeight = Threat.tOptions.profile.tList.tSize.nHeight

	self.wndMain:SetAnchorOffsets(nLeft, nTop, nLeft + nWidth, nTop + nHeight)
end

function Main:UpdateLockStatus()
	if self.wndMain == nil then return end

	self.wndMain:SetStyle("Moveable", not Threat.tOptions.profile.bLock)
	self.wndMain:SetStyle("Sizable", not Threat.tOptions.profile.bLock)
	self.wndMain:SetStyle("IgnoreMouse", Threat.tOptions.profile.bLock)
end

--[[ Preview ]]--

function Main:Preview()
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
			sName = "Pet",
			eClass = nil,
			bPet = true,
			nValue = 400000
		}
	}

	self:CreateBars(#tEntries)

	local nHighest = tEntries[1].nValue
	local nBars = #self.wndList:GetChildren()

	if nBars > 0 then
		for nIndex, tEntry in pairs(tEntries) do
			self:SetupBar(self.wndList:GetChildren()[nIndex], tEntry, nIndex == 1, nHighest, nPlayerId)
			if nBars == nIndex then break end
		end
		self.wndList:ArrangeChildrenVert()
	end
end
