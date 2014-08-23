require "Apollo"

local Threat = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("Threat")
local Settings = Threat:NewModule("Settings")

function Settings:OnInitialize()
  self.oXml = XmlDoc.CreateFromFile("Forms/Settings.xml")
  if self.oXml == nil then
    Apollo.AddAddonErrorText(Threat, "Could not load the Threat window!")
    return
  end
  self.oXml:RegisterCallback("OnDocumentReady", self)
end

function Settings:OnEnable()
end

function Settings:OnDisable()
end

function Settings:OnDocumentReady()
  self.wndMain = Apollo.LoadForm(self.oXml, "Settings", nil, self)
  self.wndMain:Show(false)
end

function Settings:OnBtnLock(oHandler, wndControl)
end

function Settings:OnBtnClassColors(oHandler, wndControl)
end

function Settings:OnBtnReset(oHandler, wndControl)
end

function Settings:OnBtnChoose(oHandler, wndControl)
end

function Settings:Open()
  self.wndMain:Show(true)
end

function Settings:Close()
  self.wndMain:Show(false)
end
