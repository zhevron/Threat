require "Apollo"
require "GameLib"

local Threat = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("Threat")
local Mini = Threat:NewModule("Mini")

Mini.bInPreview = false

--[[ Initial functions ]]--

function Mini:OnInitialize()
	self.oXml = XmlDoc.CreateFromFile("Forms/Mini.xml")

	if self.oXml == nil then
		Apollo.AddAddonErrorText(Threat, "Could not load the Threat mini window!")
		return
	end

	self.oXml:RegisterCallback("OnDocumentReady", self)
end

function Mini:OnDocumentReady()
	self.wndMain = Apollo.LoadForm(self.oXml, "ThreatMini", nil, self)
	self.wndOutput = self.wndMain:FindChild("Output")

	self.wndOutput:Show(Threat.tOptions.profile.tMini.bAlwaysShow)

	self:UpdatePosition()
	self:UpdateLockStatus()
end

function Mini:OnEnable()
end

function Mini:OnDisable()
end

--[[ Update and Clear ]]--

function Mini:Update(nPlayerValue, nTopThreatFirst, nTopThreatSecond, nTopThreatTank, bIsPlayerTank)
	if self.wndMain == nil or self.bInPreview then return end

	local nPercent

	if not bIsPlayerTank and Threat.tOptions.profile.tMini.bDifferenceToTank and nTopThreatTank ~= 0 then
		nPercent = nPlayerValue / nTopThreatTank
	else
		nPercent = nPlayerValue / nTopThreatFirst

		if nPercent == 1 and nTopThreatSecond ~= 0 then
			nPercent = nPlayerValue / nTopThreatSecond
		end
	end

	self:UpdateText(nPercent)
end

function Mini:Clear()
	if self.wndMain == nil or self.bInPreview then return end

	if Threat.tOptions.profile.tMini.bAlwaysShow then
		self:UpdateText(0)
	else
		self.wndOutput:Show(false)
	end
end

function Mini:UpdateText(nPercent)
	self.wndOutput:Show(true)

	local tColors = Threat.tOptions.profile.tMini.tColors

	local Text = string.format("%d%s", nPercent * 100,"%")
	local Color

	if nPercent < Threat.tOptions.profile.tMini.tSwitch.nMid then
		--Low
		Color = ApolloColor.new(tColors.tLow.nR / 255, tColors.tLow.nG / 255, tColors.tLow.nB / 255, 255)
		if nPercent <= 0 then Text = "N/A" end
	elseif nPercent < Threat.tOptions.profile.tMini.tSwitch.nHigh then
		--Mid
		Color = ApolloColor.new(tColors.tMid.nR / 255, tColors.tMid.nG / 255, tColors.tMid.nB / 255, 255)
	elseif nPercent < 1 then
		--High
		Color = ApolloColor.new(tColors.tHigh.nR / 255, tColors.tHigh.nG / 255, tColors.tHigh.nB / 255, 255)
	else
		--Over
		Color = ApolloColor.new(tColors.tOver.nR / 255, tColors.tOver.nG / 255, tColors.tOver.nB / 255, 255)
		if nPercent > 9.9 then Text = "High" end
	end

	self.wndOutput:SetText(Text)
	self.wndOutput:SetTextColor(Color)
end

--[[ Window events ]]--

function Mini:OnMouseEnter(wndHandler, wndControl)
	if wndControl ~= self.wndMain then return end

	if not Threat.tOptions.profile.bLocked then
		self.wndMain:FindChild("Background"):Show(true)
	end
end

function Mini:OnMouseExit(wndHandler, wndControl)
	if wndControl ~= self.wndMain then return end

	if Threat:GetModule("Settings").nCurrentTab == 0 then
		self.wndMain:FindChild("Background"):Show(false)
	end
end

function Mini:OnMouseButtonUp(wndHandler, wndControl, eMouseButton)
	if eMouseButton == GameLib.CodeEnumInputMouse.Right then
		if not Threat.tOptions.profile.bLocked or Threat:GetModule("Settings").wndMain:IsShown() then
			Threat:GetModule("Settings"):Open(4)
		end
	end
end

function Mini:OnWindowMove()
	local nLeft, nTop = self.wndMain:GetAnchorOffsets()
	Threat.tOptions.profile.tMini.tPosition.nX = nLeft
	Threat.tOptions.profile.tMini.tPosition.nY = nTop
end

function Mini:OnWindowSizeChanged()
	local nLeft, nTop, nRight, nBottom = self.wndMain:GetAnchorOffsets()
	Threat.tOptions.profile.tMini.tSize.nWidth = nRight - nLeft
	Threat.tOptions.profile.tMini.tSize.nHeight = nBottom - nTop
end

--[[ Window updaters ]]--

function Mini:UpdatePosition()
	if self.wndMain == nil then return end

	local nLeft = Threat.tOptions.profile.tMini.tPosition.nX
	local nTop = Threat.tOptions.profile.tMini.tPosition.nY
	local nWidth = Threat.tOptions.profile.tMini.tSize.nWidth
	local nHeight = Threat.tOptions.profile.tMini.tSize.nHeight

	self.wndMain:SetAnchorOffsets(nLeft, nTop, nLeft + nWidth, nTop + nHeight)
end

function Mini:UpdateLockStatus()
	if self.wndMain == nil then return end

	self.wndMain:SetStyle("Moveable", not Threat.tOptions.profile.bLocked)
	self.wndMain:SetStyle("Sizable", not Threat.tOptions.profile.bLocked)
	self.wndMain:SetStyle("IgnoreMouse", Threat.tOptions.profile.bLocked)
end

function Mini:Preview(nProfile)
	local nPercent = 0

	if nProfile == 1 then
		nPercent = Threat.tOptions.profile.tMini.tSwitch.nMid / 2
	elseif nProfile == 2 then
		nPercent = Threat.tOptions.profile.tMini.tSwitch.nMid
	elseif nProfile == 3 then
		nPercent = Threat.tOptions.profile.tMini.tSwitch.nHigh
	elseif nProfile == 4 then
		nPercent = 1.2
	end

	self:UpdateText(nPercent)
end

function Mini:PreviewByColorName(strColor)
	if strColor == "tLow" then
		self:Preview(1)
	elseif strColor == "tMid" then
		self:Preview(2)
	elseif strColor == "tHigh" then
		self:Preview(3)
	elseif strColor == "tOver" then
		self:Preview(4)
	end
end
