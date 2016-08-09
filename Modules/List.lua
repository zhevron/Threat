require "Apollo"
require "GameLib"
require "GroupLib"

local Threat = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("Threat")
local List = Threat:NewModule("List")

List.nBarSlots = 0
List.bInPreview = false

--[[ Initial functions ]]--

function List:OnInitialize()
	self.oXml = XmlDoc.CreateFromFile("Forms/List.xml")
	Apollo.LoadSprites("Textures/Threat_Textures.xml", "")

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

	self:SetBarSlots()
end

function List:SetBarSlots()
	local nOffset = Threat.tOptions.profile.tList.nBarOffset
	self.nBarSlots = math.floor((self.wndList:GetHeight() + nOffset) / (Threat.tOptions.profile.tList.nBarHeight + nOffset))
end

function List:OnEnable()
end

function List:OnDisable()
end

--[[ Update and Clear ]]--

function List:Update(tThreatList, nPlayerId, nHighest)
	if self.wndMain == nil or self.bInPreview then return end

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
	if self.wndMain == nil or self.bInPreview then return end

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
				local wndBar = Apollo.LoadForm(self.oXml, "Bar", self.wndList, self)
				self:SetBarOptions(wndBar)
			end
		end
	end
end

function List:SetBarOptions(wndBar)
	if Threat.tOptions.profile.tList.nBarStyle == 1 then
		wndBar:FindChild("Background"):SetSprite("Threat_Textures:Threat_Smooth")
	elseif Threat.tOptions.profile.tList.nBarStyle == 2 then
		wndBar:FindChild("Background"):SetSprite("Threat_Textures:Threat_Edge")
	end

	local nOffset = Threat.tOptions.profile.tList.nBarOffset
	local nL, nT, nR, nB = wndBar:GetAnchorOffsets()
	wndBar:SetAnchorOffsets(nL, nT, nR, Threat.tOptions.profile.tList.nBarHeight + nOffset)

	for _, v in ipairs(wndBar:GetChildren()) do
		local nL, nT, nR, nB = v:GetAnchorOffsets()
		v:SetAnchorOffsets(nL, nT, nR, nB - nOffset)
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

function List:OnMouseEnter(wndHandler, wndControl)
	if wndControl ~= self.wndMain then return end

	if not Threat.tOptions.profile.bLocked then
		self.wndMain:FindChild("Background"):Show(true)
	end
end

function List:OnMouseExit(wndHandler, wndControl)
	if wndControl ~= self.wndMain then return end

	if Threat:GetModule("Settings").nCurrentTab == 0 then
		self.wndMain:FindChild("Background"):Show(false)
	end
end

function List:OnMouseButtonUp(wndHandler, wndControl, eMouseButton)
	if eMouseButton == GameLib.CodeEnumInputMouse.Right then
		if not Threat.tOptions.profile.bLocked or Threat:GetModule("Settings").wndMain:IsShown() then
			Threat:GetModule("Settings"):Open(2)
		end
	end
end

function List:OnWindowMove()
	local nLeft, nTop = self.wndMain:GetAnchorOffsets()
	Threat.tOptions.profile.tList.tPosition.nX = nLeft
	Threat.tOptions.profile.tList.tPosition.nY = nTop
end

function List:OnWindowSizeChanged(wndHandler, wndControl)
	if wndControl ~= self.wndMain then return end

	local nLeft, nTop, nRight, nBottom = self.wndMain:GetAnchorOffsets()
	Threat.tOptions.profile.tList.tSize.nWidth = nRight - nLeft
	Threat.tOptions.profile.tList.tSize.nHeight = nBottom - nTop

	local nOldBarSlots = self.nBarSlots

	self:SetBarSlots()

	if self.bInPreview and nOldBarSlots ~= self.nBarSlots then
		self:Preview()
	end
end

--[[ Window updaters ]]--

function List:UpdatePosition()
	if self.wndMain == nil then return end

	local nLeft = Threat.tOptions.profile.tList.tPosition.nX
	local nTop = Threat.tOptions.profile.tList.tPosition.nY
	local nWidth = Threat.tOptions.profile.tList.tSize.nWidth
	local nHeight = Threat.tOptions.profile.tList.tSize.nHeight

	self.wndMain:SetAnchorOffsets(nLeft, nTop, nLeft + nWidth, nTop + nHeight)
end

function List:UpdateLockStatus()
	if self.wndMain == nil then return end

	self.wndMain:SetStyle("Moveable", not Threat.tOptions.profile.bLocked)
	self.wndMain:SetStyle("Sizable", not Threat.tOptions.profile.bLocked)
	self.wndMain:SetStyle("IgnoreMouse", Threat.tOptions.profile.bLocked)
end

--[[ Preview ]]--

function List:GetPreviewEntries()
	local oPlayer = GameLib.GetPlayerUnit()
	return {
		{
			nId = 0,
			sName = GameLib.GetClassName(GameLib.CodeEnumClass.Warrior),
			eClass = GameLib.CodeEnumClass.Warrior,
			bPet = false,
			nValue = 1000000
		},
		{
			nId = oPlayer:GetId(),
			sName = oPlayer:GetName(),
			eClass = oPlayer:GetClassId(),
			bPet = false,
			nValue = 900000
		},
		{
			nId = 0,
			sName = GameLib.GetClassName(GameLib.CodeEnumClass.Engineer),
			eClass = GameLib.CodeEnumClass.Engineer,
			bPet = false,
			nValue = 800000
		},
		{
			nId = 0,
			sName = GameLib.GetClassName(GameLib.CodeEnumClass.Esper),
			eClass = GameLib.CodeEnumClass.Esper,
			bPet = false,
			nValue = 700000
		},
		{
			nId = 0,
			sName = GameLib.GetClassName(GameLib.CodeEnumClass.Medic),
			eClass = GameLib.CodeEnumClass.Medic,
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
			sName = GameLib.GetClassName(GameLib.CodeEnumClass.Spellslinger),
			eClass = GameLib.CodeEnumClass.Spellslinger,
			bPet = false,
			nValue = 400000
		},
		{
			nId = -1,
			sName = "Pet",
			eClass = nil,
			bPet = true,
			nValue = 300000
		}
	}
end

function List:Preview()
	local nPlayerId = GameLib.GetPlayerUnit():GetId()
	local tEntries = self:GetPreviewEntries()

	self:CreateBars(#tEntries)

	local nHighest = tEntries[1].nValue
	local nBars = #self.wndList:GetChildren()

	if nBars > 0 then
		for nIndex, tEntry in pairs(tEntries) do
			self:SetupBar(self.wndList:GetChildren()[nIndex], tEntry, nIndex == 1, nHighest, nPlayerId)
			self:PreviewSetRoleColor(nIndex, tEntry)
			if nBars == nIndex then break end
		end
		self.wndList:ArrangeChildrenVert()
	end
end

function List:PreviewSetRoleColor(nIndex, tEntry)
	if Threat.tOptions.profile.tList.nColorMode == 1 then
		if nIndex == 1 then
			self:PreviewSetColor(Threat.tOptions.profile.tList.tColors.tTank, nIndex)
		elseif nIndex == 7 then
			self:PreviewSetColor(Threat.tOptions.profile.tList.tColors.tHealer, nIndex)
		elseif tEntry.nId == 0 then
			self:PreviewSetColor(Threat.tOptions.profile.tList.tColors.tDamage, nIndex)
		end
	end
end

function List:PreviewSetColor(tColor, nIndex)
	local Color = ApolloColor.new((tColor.nR / 255), (tColor.nG / 255), (tColor.nB / 255), (tColor.nA / 255))
	self.wndList:GetChildren()[nIndex]:FindChild("Background"):SetBGColor(Color)
end

function List:PreviewColor()
	local nPlayerId = GameLib.GetPlayerUnit():GetId()
	local tEntries = self:GetPreviewEntries()
	local nBars = #self.wndList:GetChildren()

	if nBars > 0 then
		for nIndex, tEntry in ipairs(tEntries) do
			local wndBarBackground = self.wndList:GetChildren()[nIndex]:FindChild("Background")
			local nR, nG, nB, nA = self:GetColorForEntry(tEntry, nIndex == 1, nPlayerId)
			wndBarBackground:SetBGColor(ApolloColor.new(nR, nG, nB, nA))

			self:PreviewSetRoleColor(nIndex, tEntry)

			if nBars == nIndex then break end
		end
	end
end

function List:PreviewFullReload()
	self.wndList:DestroyChildren()
	self:SetBarSlots()
	self:Preview()
end
