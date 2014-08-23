require "Apollo"
require "ApolloColor"
require "GameLib"

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
  self:ApplyCurrent()
  self:CreateColors()
end

function Settings:OnBtnLock(oHandler, wndControl)
  Threat.tOptions.tCharacter.bLock = wndControl:IsChecked()
end

function Settings:OnBtnClassColors(oHandler, wndControl)
  Threat.tOptions.tCharacter.bUseClassColors = wndControl:IsChecked()
end

function Settings:OnBtnReset(oHandler, wndControl)
  Threat:GetModule("Utility"):TableCopyRecursive(Threat.tDefaults, Threat.tOptions)
  self:ApplyCurrent()
end

function Settings:OnBtnChoose(oHandler, wndControl)
  local GeminiColor = Apollo.GetPackage("GeminiColor").tPackage
  local sColor = Threat.tOptions.tCharacter.tColors[wndControl:GetParent():GetData()]
  if sColor ~= nil then
    GeminiColor:ShowColorPicker(self, "OnColorPicker", true, sColor, wndControl:GetParent())
  end
end

function Settings:OnColorPicker(sColor, wndControl)
  Threat.tOptions.tCharacter.tColors[wndControl:GetData()] = sColor
  wndControl:FindChild("ColorBackground"):SetBGColor(ApolloColor.new(sColor))
end

function Settings:Open()
  self.wndMain:Show(true)
end

function Settings:Close()
  self.wndMain:Show(false)
end

function Settings:ApplyCurrent()
  self.wndMain:FindChild("BtnLock"):SetCheck(Threat.tOptions.tCharacter.bLock)
  self.wndMain:FindChild("BtnClassColors"):SetCheck(Threat.tOptions.tCharacter.bUseClassColors)
end

function Settings:CreateColors()
  local wndList = self.wndMain:FindChild("LstColor")

  local wndColor = Apollo.LoadForm(self.oXml, "Color", wndList, self)
  wndColor:SetData("sSelf")
  wndColor:FindChild("Name"):SetText("Self")
  wndColor:FindChild("ColorBackground"):SetBGColor(ApolloColor.new(Threat.tOptions.tCharacter.tColors.sSelf))

  wndColor = Apollo.LoadForm(self.oXml, "Color", wndList, self)
  wndColor:SetData("sOthers")
  wndColor:FindChild("Name"):SetText("Others")
  wndColor:FindChild("ColorBackground"):SetBGColor(ApolloColor.new(Threat.tOptions.tCharacter.tColors.sOthers))

  for eClass, sColor in pairs(Threat.tOptions.tCharacter.tColors) do
    if type(eClass) == "number" then
      wndColor = Apollo.LoadForm(self.oXml, "Color", wndList, self)
      wndColor:SetData(eClass)
      wndColor:FindChild("Name"):SetText(GameLib.GetClassName(eClass))
      wndColor:FindChild("ColorBackground"):SetBGColor(ApolloColor.new(sColor))
    end
  end

  wndList:ArrangeChildrenVert()
end
