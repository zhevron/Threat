require "Apollo"
require "GameLib"

local Threat = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("Threat")
local Notify = Threat:NewModule("Notify")

Notify.bActive = false

--[[ Initial functions ]]--

function Notify:OnInitialize()
	self.oXml = XmlDoc.CreateFromFile("Forms/Notify.xml")

	if self.oXml == nil then
		Apollo.AddAddonErrorText(Threat, "Could not load the Threat notification window!")
		return
	end

	self.oXml:RegisterCallback("OnDocumentReady", self)
end

function Notify:OnDocumentReady()
	self.wndMain = Apollo.LoadForm(self.oXml, "Notification", nil, self)
	self.wndNotifier = self.wndMain:FindChild("Notifier")

	self:UpdatePosition()
	self:UpdateLockStatus()
end

function Notify:OnEnable()
end

function Notify:OnDisable()
end

--[[ Update and Clear ]]--

function Notify:Update(bIsPlayerTank, nPlayerValue, nHighest)
	if self.wndMain == nil then return end

	if bIsPlayerTank or nPlayerValue == 0 or nHighest == 0 then self:Clear() return end

	local nPercent = nPlayerValue / nHighest
	
	if nPercent >= Threat.tOptions.profile.tNotify.tAlert.tLow.nPercent then
		self.bActive = true

		if nPercent >= Threat.tOptions.profile.tNotify.tAlert.tHigh.nPercent then
			if nPercent >= 1 then
				self:SetNotifyVisual(3, nPercent)
			else
				self:SetNotifyVisual(2, nPercent)
			end
		else
			self:SetNotifyVisual(1, nPercent)
		end
	else
		self:Clear()
	end
end

function Notify:Clear()
	if self.wndMain == nil then return end

	self.bActive = false
	self.wndNotifier:Show(false)
end

--[[ Notify setup functions ]]--

function Notify:SetNotifyVisual(nProfile, nPercent)
	local tAlert = Threat.tOptions.profile.tNotify.tAlert

	if nProfile == 1 then
		self.wndNotifier:SetTextColor(ApolloColor.new(1, 1, 1, tAlert.tLow.nAlphaText))
		self.wndNotifier:SetBGColor(ApolloColor.new(1, 1, 1, tAlert.tLow.nAlphaBG))
		self.wndNotifier:SetSprite("BK3:UI_BK3_Holo_Framing_3")
		self.wndNotifier:SetText(string.format("Close to highest threat: %d%s", nPercent * 100,"%"))
	else
		self.wndNotifier:SetTextColor(ApolloColor.new(1, 1, 1, tAlert.tHigh.nAlphaText))
		self.wndNotifier:SetBGColor(ApolloColor.new(1, 1, 1, tAlert.tHigh.nAlphaBG))
		self.wndNotifier:SetSprite("BK3:UI_BK3_Holo_Framing_3_Alert")

		if nProfile == 2 then
			self.wndNotifier:SetText(string.format("Close to highest threat: %d%s", nPercent * 100,"%"))
		else
			self.wndNotifier:SetText("You have the highest threat!")
		end
	end

	self.wndNotifier:Show(true)
end

--[[ Window events ]]--

function Notify:OnMouseEnter(wndHandler, wndControl)
	if wndControl ~= self.wndMain then return end

	if not Threat.tOptions.profile.bLock then
		self.wndMain:FindChild("Background"):Show(true)
	end
end

function Notify:OnMouseExit(wndHandler, wndControl)
	if wndControl ~= self.wndMain then return end

	if Threat:GetModule("Settings").nCurrentTab ~= 3 then
		self.wndMain:FindChild("Background"):Show(false)
	end
end

function Notify:OnMouseButtonUp(wndHandler, wndControl, eMouseButton)
	if eMouseButton == GameLib.CodeEnumInputMouse.Right then
		if not Threat.tOptions.profile.bLock then
			Threat:GetModule("Settings"):Open(3)
		end
	end
end

function Notify:OnWindowMove()
	local nLeft, nTop = self.wndMain:GetAnchorOffsets()
	Threat.tOptions.profile.tNotify.tPosition.nX = nLeft + 252
	Threat.tOptions.profile.tNotify.tPosition.nY = nTop
end

--[[ Window updaters ]]--

function Notify:UpdatePosition()
	if self.wndMain == nil then return end
	
	local nLeft = Threat.tOptions.profile.tNotify.tPosition.nX
	local nTop = Threat.tOptions.profile.tNotify.tPosition.nY
	local nWidth = 252
	local nHeight = 104

	self.wndMain:SetAnchorOffsets(nLeft - nWidth, nTop, nLeft + nWidth, nTop + nHeight)
end

function Notify:UpdateLockStatus()
	if self.wndMain == nil then return end

	self.wndMain:SetStyle("Moveable", not Threat.tOptions.profile.bLock)
	self.wndMain:SetStyle("IgnoreMouse", Threat.tOptions.profile.bLock)
end
