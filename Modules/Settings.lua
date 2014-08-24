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
  local GeminiLocale = Apollo.GetPackage("Gemini:Locale-1.0").tPackage
  local L = GeminiLocale:GetLocale("Threat", true)
  self.wndMain = Apollo.LoadForm(self.oXml, "Settings", nil, self)
  GeminiLocale:TranslateWindow(L, self.wndMain)
  self.wndMain:Show(false)
  self:ApplyCurrent()
end

function Settings:OnBtnEnable(wndHandler, wndControl)
  Threat.tOptions.tCharacter.bEnabled = wndControl:IsChecked()
  if wndControl:IsChecked() then
    Threat:GetModule("Main"):Enable()
  else
    Threat:GetModule("Main"):Disable()
  end
end

function Settings:OnBtnLock(wndHandler, wndControl)
  Threat.tOptions.tCharacter.bLock = wndControl:IsChecked()
  Threat:GetModule("Main"):UpdateLockStatus()
end

function Settings:OnBtnClassColors(wndHandler, wndControl)
  Threat.tOptions.tCharacter.bUseClassColors = wndControl:IsChecked()
end

function Settings:OnBtnRoleColors(wndHandler, wndControl)
  Threat.tOptions.tCharacter.bUseRoleColors = wndControl:IsChecked()
end

function Settings:OnBtnShowSolo(wndHandler, wndControl)
  Threat.tOptions.tCharacter.bShowSolo = wndControl:IsChecked()
end

function Settings:OnBtnShowDifferences(wndHandler, wndControl)
  Threat.tOptions.tCharacter.bShowDifferences = wndControl:IsChecked()
end

function Settings:OnBtnReset(wndHandler, wndControl)
  Threat.tOptions = Threat:GetModule("Utility"):TableCopyRecursive(Threat.tDefaults)
  Threat:GetModule("Main"):UpdatePosition()
  self:ApplyCurrent()
end

function Settings:OnBtnTest(wndHandler, wndControl)
  Threat:GetModule("Main"):ShowTestBars()
end

function Settings:OnBtnChoose(wndHandler, wndControl)
  local GeminiColor = Apollo.GetPackage("GeminiColor").tPackage
  local tColor = Threat.tOptions.tCharacter.tColors[wndControl:GetParent():GetData()]
  if tColor ~= nil then
    local sColor = GeminiColor:RGBAPercToHex(
      tColor.nR / 255,
      tColor.nG / 255,
      tColor.nB / 255,
      tColor.nA / 255
    )
    GeminiColor:ShowColorPicker(self, "OnColorPicker", true, sColor, wndControl:GetParent())
  end
end

function Settings:OnColorPicker(sColor, wndControl)
  local GeminiColor = Apollo.GetPackage("GeminiColor").tPackage
  local nR, nG, nB, nA = GeminiColor:HexToRGBAPerc(sColor)
  Threat.tOptions.tCharacter.tColors[wndControl:GetData()] = {
    nR = nR * 255,
    nG = nG * 255,
    nB = nB * 255,
    nA = nA * 255
  }
  wndControl:FindChild("ColorBackground"):SetBGColor(ApolloColor.new(nR, nG, nB, nA))
end

function Settings:Open()
  self.wndMain:Show(true)
  Threat:GetModule("Main").wndMain:FindChild("Background"):Show(true)
end

function Settings:Close()
  self.wndMain:Show(false)
  Threat:GetModule("Main").wndMain:FindChild("Background"):Show(false)
end

function Settings:ApplyCurrent()
  self.wndMain:FindChild("BtnEnable"):SetCheck(Threat.tOptions.tCharacter.bEnabled)
  self.wndMain:FindChild("BtnLock"):SetCheck(Threat.tOptions.tCharacter.bLock)
  self.wndMain:FindChild("BtnClassColors"):SetCheck(Threat.tOptions.tCharacter.bUseClassColors)
  self.wndMain:FindChild("BtnRoleColors"):SetCheck(Threat.tOptions.tCharacter.bUseRoleColors)
  self.wndMain:FindChild("BtnShowSolo"):SetCheck(Threat.tOptions.tCharacter.bShowSolo)
  self.wndMain:FindChild("BtnShowDifferences"):SetCheck(Threat.tOptions.tCharacter.bShowDifferences)
  self:CreateColors()
end

function Settings:CreateColors()
  local L = Apollo.GetPackage("Gemini:Locale-1.0").tPackage:GetLocale("Threat", true)
  local wndList = self.wndMain:FindChild("LstColor")
  wndList:DestroyChildren()

  local wndColor = Apollo.LoadForm(self.oXml, "Color", wndList, self)
  local tColor = Threat.tOptions.tCharacter.tColors.tSelf
  wndColor:SetData("tSelf")
  wndColor:FindChild("Name"):SetText(L["self"])
  wndColor:FindChild("ColorBackground"):SetBGColor(ApolloColor.new(
    tColor.nR / 255,
    tColor.nG / 255,
    tColor.nB / 255,
    tColor.nA / 255
  ))

  wndColor = Apollo.LoadForm(self.oXml, "Color", wndList, self)
  tColor = Threat.tOptions.tCharacter.tColors.tOthers
  wndColor:SetData("tOthers")
  wndColor:FindChild("Name"):SetText(L["others"])
  wndColor:FindChild("ColorBackground"):SetBGColor(ApolloColor.new(
    tColor.nR / 255,
    tColor.nG / 255,
    tColor.nB / 255,
    tColor.nA / 255
  ))

  Apollo.LoadForm(self.oXml, "Divider", wndList, self)

  wndColor = Apollo.LoadForm(self.oXml, "Color", wndList, self)
  tColor = Threat.tOptions.tCharacter.tColors.tTank
  wndColor:SetData("tTank")
  wndColor:FindChild("Name"):SetText(Apollo.GetString("Matching_Role_Tank"))
  wndColor:FindChild("ColorBackground"):SetBGColor(ApolloColor.new(
    tColor.nR / 255,
    tColor.nG / 255,
    tColor.nB / 255,
    tColor.nA / 255
  ))

  wndColor = Apollo.LoadForm(self.oXml, "Color", wndList, self)
  tColor = Threat.tOptions.tCharacter.tColors.tHealer
  wndColor:SetData("tHealer")
  wndColor:FindChild("Name"):SetText(Apollo.GetString("Matching_Role_Healer"))
  wndColor:FindChild("ColorBackground"):SetBGColor(ApolloColor.new(
    tColor.nR / 255,
    tColor.nG / 255,
    tColor.nB / 255,
    tColor.nA / 255
  ))

  wndColor = Apollo.LoadForm(self.oXml, "Color", wndList, self)
  tColor = Threat.tOptions.tCharacter.tColors.tDamage
  wndColor:SetData("tDamage")
  wndColor:FindChild("Name"):SetText(Apollo.GetString("Matching_Role_Dps"))
  wndColor:FindChild("ColorBackground"):SetBGColor(ApolloColor.new(
    tColor.nR / 255,
    tColor.nG / 255,
    tColor.nB / 255,
    tColor.nA / 255
  ))

  Apollo.LoadForm(self.oXml, "Divider", wndList, self)

  for eClass, tColor in pairs(Threat.tOptions.tCharacter.tColors) do
    if type(eClass) == "number" then
      wndColor = Apollo.LoadForm(self.oXml, "Color", wndList, self)
      wndColor:SetData(eClass)
      wndColor:FindChild("Name"):SetText(GameLib.GetClassName(eClass))
      wndColor:FindChild("ColorBackground"):SetBGColor(ApolloColor.new(
        tColor.nR / 255,
        tColor.nG / 255,
        tColor.nB / 255,
        tColor.nA / 255
      ))
    end
  end

  wndList:ArrangeChildrenVert()
end
