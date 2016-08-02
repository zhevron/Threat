require "Apollo"
require "ApolloTimer"
require "GameLib"
require "GroupLib"

local Threat = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("Threat")
local Notify = Threat:NewModule("Notify")

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

	self.wndMain:Show(false)
end

function Notify:OnEnable()
end

function Notify:OnDisable()
end

--[[ Runtime functions ]]--

----------------------------------------------------------------------------------


--[[
	!!!
	Stuff need to be put here
	!!!
]]


function Main:SetNotifyVisual(nProfile, nPercent)
	self.wndNotifier:Show(true)

	if nProfile == 1 then
		self.wndNotifier:SetTextColor(ApolloColor.new(1, 1, 1, Threat.tOptions.profile.nShowNotifySoftText))
		self.wndNotifier:SetBGColor(ApolloColor.new(1, 1, 1, Threat.tOptions.profile.nShowNotifySoftBG))
		self.wndNotifier:SetSprite("BK3:UI_BK3_Holo_Framing_3")
		self.wndNotifier:SetText(string.format("Close to highest threat: %d%s", nPercent * 100,"%"))
	else
		self.wndNotifier:SetTextColor(ApolloColor.new(1, 1, 1, Threat.tOptions.profile.nShowNotifyHardText))
		self.wndNotifier:SetBGColor(ApolloColor.new(1, 1, 1, Threat.tOptions.profile.nShowNotifyHardBG))
		self.wndNotifier:SetSprite("BK3:UI_BK3_Holo_Framing_3_Alert")

		if nProfile == 2 then
			self.wndNotifier:SetText(string.format("Close to highest threat: %d%s", nPercent * 100,"%"))
		else
			self.wndNotifier:SetText("You have the highest threat!")
		end
	end
end

-- Window events

function Main:OnMouseEnterNotify()
	if not Threat.tOptions.profile.bLock then
		self.wndNotify:FindChild("Background"):Show(true)
	end
end

function Main:OnMouseExitNotify()
	if (not Threat:GetModule("Settings").wndMain:IsShown() and Threat:GetModule("Settings").wndNotifySettings == nil) or Threat:GetModule("Settings").bPreview then
		self.wndNotify:FindChild("Background"):Show(false)
	end
end

function Main:OnMouseButtonUpNotify(wndHandler, wndControl, eMouseButton)
	if eMouseButton == GameLib.CodeEnumInputMouse.Right then
		if not Threat.tOptions.profile.bLock then
			Threat:GetModule("Settings"):OpenNotifySettings()
		end
	end
end

function Main:OnWindowMoveNotify()
	local nLeft, nTop = self.wndNotify:GetAnchorOffsets()
	Threat.tOptions.profile.tNotifyPosition.nX = nLeft + 252
	Threat.tOptions.profile.tNotifyPosition.nY = nTop
end

--extra

function Main:UpdateNotifyPosition()
	local nLeft = Threat.tOptions.profile.tNotifyPosition.nX
	local nTop = Threat.tOptions.profile.tNotifyPosition.nY
	local nWidth = 252
	local nHeight = 104
	self.wndNotify:SetAnchorOffsets(nLeft - nWidth, nTop, nLeft + nWidth, nTop + nHeight)
end