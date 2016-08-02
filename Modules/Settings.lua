require "Apollo"
require "ApolloColor"
require "GameLib"

local Threat = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("Threat")
local Settings = Threat:NewModule("Settings")

Settings.wndNotifySettings = nil
Settings.wndProfiles = nil
Settings.SelectedProfile = nil

Settings.bPreview = false

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
	self.wndMain:FindChild("Version"):SetText(Threat:GetVersionString())
	GeminiLocale:TranslateWindow(L, self.wndMain)
	self.wndMain:Show(false)
end

function Settings:OnBtnEnable(wndHandler, wndControl)
	Threat.tOptions.profile.bEnabled = wndControl:IsChecked()
	if wndControl:IsChecked() then
		Threat:GetModule("Main"):Enable()
	else
		Threat:GetModule("Main"):Disable()
	end
end

function Settings:OnBtnLock(wndHandler, wndControl)
	Threat.tOptions.profile.bLock = wndControl:IsChecked()
	Threat:GetModule("Main"):UpdateLockStatus()
end

--  Color Select

function Settings:OnBtnSimpleColors(wndHandler, wndControl)
	if wndControl:IsChecked() then
		Threat.tOptions.profile.bUseClassColors = false
		Threat.tOptions.profile.bUseRoleColors = false
	end
end

function Settings:OnBtnClassColors(wndHandler, wndControl)
	Threat.tOptions.profile.bUseClassColors = wndControl:IsChecked()
	if wndControl:IsChecked() then
		Threat.tOptions.profile.bUseRoleColors = false
	end
end

function Settings:OnBtnRoleColors(wndHandler, wndControl)
	Threat.tOptions.profile.bUseRoleColors = wndControl:IsChecked()
	if wndControl:IsChecked() then
		Threat.tOptions.profile.bUseClassColors = false
	end
end

--  Show Options

function Settings:OnBtnShowSolo(wndHandler, wndControl)
	Threat.tOptions.profile.bShowSolo = wndControl:IsChecked()
end

function Settings:OnBtnShowDifferences(wndHandler, wndControl)
	Threat.tOptions.profile.bShowDifferences = wndControl:IsChecked()
end

function Settings:OnBtnShowTPS(wndHandler, wndControl)
	Threat.tOptions.profile.bShowThreatPerSec = wndControl:IsChecked()
end

--  Other Options

function Settings:OnBtnAlwaysUseSelf(wndHandler, wndControl)
	Threat.tOptions.profile.bUseSelfColor = wndControl:IsChecked()
end

function Settings:OnBtnShowSelfWarning(wndHandler, wndControl)
	Threat.tOptions.profile.bShowSelfWarning = wndControl:IsChecked()
end

function Settings:OnBtnRightToLeftBars(wndHandler, wndControl)
	Threat.tOptions.profile.bRightToLeftBars = wndControl:IsChecked()
end

--Slider

function Settings:OnSliderUpdateRate(wndHandler, wndControl, fNewValue, fOldValue)
	local nValue = math.floor(fNewValue * 10 + 0.5) * 0.1

	if Threat.tOptions.profile.nUpdateRate == nValue then return end

	local wndCurrSlider = self.wndMain:FindChild("SettingUpdateRate")
	wndCurrSlider:FindChild("SliderOutput"):SetText(string.format("%.1f", nValue))
	Threat.tOptions.profile.nUpdateRate = nValue

	Threat:GetModule("Main"):SetUpdateTimerRate()
end

--  Buttons

--Notify Buttons

function Settings:OpenNotifySettings()
	if self.wndNotifySettings ~= nil then return end

	self.wndNotifySettings = Apollo.LoadForm(self.oXml, "NotificationSettings", nil, self)
	self:ApplyCurrentNotify()

	Threat:GetModule("Main").wndNotify:FindChild("Background"):Show(true)
end

function Settings:OnBtnShowNotifySettings(wndHandler, wndControl)
	self:OpenNotifySettings()
end

function Settings:ApplyCurrentNotify()
	if self.wndNotifySettings == nil then return end

	self.wndNotifySettings:FindChild("BtnEnableNotify"):SetCheck(Threat.tOptions.profile.bShowNotify)
	self.wndNotifySettings:FindChild("BtnOnlyInRaidNotify"):SetCheck(Threat.tOptions.profile.bNotifyOnlyInRaid)

	self:SetSlider("SettingShowPercent", Threat.tOptions.profile.nShowNotifySoft * 100)
	self:SetSlider("SettingShowPercentBGAlpha", Threat.tOptions.profile.nShowNotifySoftBG * 100)
	self:SetSlider("SettingShowPercentTextAlpha", Threat.tOptions.profile.nShowNotifySoftText * 100)

	self:SetSlider("SettingShowHighPercent", Threat.tOptions.profile.nShowNotifyHard * 100)
	self:SetSlider("SettingShowHighPercentBGAlpha", Threat.tOptions.profile.nShowNotifyHardBG * 100)
	self:SetSlider("SettingShowHighPercentTextAlpha", Threat.tOptions.profile.nShowNotifyHardText * 100)
end

function Settings:SetSlider(strName, nValue)
	local wndSlider = self.wndNotifySettings:FindChild(strName)
	wndSlider:FindChild("SliderBar"):SetValue(nValue)
	wndSlider:FindChild("SliderOutput"):SetText(self:ToPercent(nValue))
end

function Settings:OnBtnNotifyEnable(wndHandler, wndControl)
	Threat.tOptions.profile.bShowNotify = wndControl:IsChecked()
end

function Settings:OnBtnNotifyOnlyRaid(wndHandler, wndControl)
	Threat.tOptions.profile.bNotifyOnlyInRaid = wndControl:IsChecked()
end

function Settings:OnBtnNotifySettingsClose(wndHandler, wndControl)
	if self.wndNotifySettings == nil then return end

	if not self.wndMain:IsShown() then
		Threat:GetModule("Main").wndNotify:FindChild("Background"):Show(false)
	else
		Threat:GetModule("Main").wndNotify:FindChild("Background"):Show(true)
	end

	self.wndNotifySettings:Destroy()
	self.wndNotifySettings = nil
	self.bPreview = false

	local wndNotifier = Threat:GetModule("Main").wndNotifier
	if wndNotifier ~= nil then
		wndNotifier:Show(false)
	end
end

function Settings:OnBtnResetNotifyPos(wndHandler, wndControl)
	local tDefaultPos = Threat.tDefaults.profile.tNotifyPosition
	Threat.tOptions.profile.tNotifyPosition = { nX = tDefaultPos.nX, nY = tDefaultPos.nY }
	Threat:GetModule("Main"):UpdateNotifyPosition()
end

function Settings:OnBtnResetNotifySettings(wndHandler, wndControl)
	Threat.tOptions.profile.bShowNotify = Threat.tDefaults.profile.bShowNotify
	Threat.tOptions.profile.bNotifyOnlyInRaid = Threat.tDefaults.profile.bNotifyOnlyInRaid

	Threat.tOptions.profile.nShowNotifySoft = Threat.tDefaults.profile.nShowNotifySoft
	Threat.tOptions.profile.nShowNotifySoftBG = Threat.tDefaults.profile.nShowNotifySoftBG
	Threat.tOptions.profile.nShowNotifySoftText = Threat.tDefaults.profile.nShowNotifySoftText
	Threat.tOptions.profile.nShowNotifyHard = Threat.tDefaults.profile.nShowNotifyHard
	Threat.tOptions.profile.nShowNotifyHardBG = Threat.tDefaults.profile.nShowNotifyHardBG
	Threat.tOptions.profile.nShowNotifyHardText = Threat.tDefaults.profile.nShowNotifyHardText

	self:ResetNotifyPreview()
	self:ApplyCurrentNotify()
end

function Settings:ResetNotifyPreview()
	self.bPreview = false
	
	local wndNotifier = Threat:GetModule("Main").wndNotifier
	if wndNotifier ~= nil then
		wndNotifier:Show(false)
	end

	local wndNotify = Threat:GetModule("Main").wndNotify
	if wndNotify ~= nil then
		wndNotify:FindChild("Background"):Show(true)
	end
end

function Settings:ShowNotifier(nProfile, nPercent)
	local Main = Threat:GetModule("Main")
	local wndNotifier = Main.wndNotifier
	if wndNotifier == nil then return end

	self.bPreview = true
	Main.wndNotify:FindChild("Background"):Show(false)
	Main:SetNotifyVisual(nProfile, nPercent)
end

--Sliders

function Settings:OnSliderShowPercent(wndHandler, wndControl, fNewValue, fOldValue)
	local wndCurrSlider = self.wndNotifySettings:FindChild("SettingShowPercent")
	wndCurrSlider:FindChild("SliderOutput"):SetText(self:ToPercent(fNewValue))
	Threat.tOptions.profile.nShowNotifySoft = fNewValue / 100

	self:ShowNotifier(1, Threat.tOptions.profile.nShowNotifySoft)
end

function Settings:OnSliderBGAlpha(wndHandler, wndControl, fNewValue, fOldValue)
	local wndCurrSlider = self.wndNotifySettings:FindChild("SettingShowPercentBGAlpha")
	wndCurrSlider:FindChild("SliderOutput"):SetText(self:ToPercent(fNewValue))
	Threat.tOptions.profile.nShowNotifySoftBG = fNewValue / 100

	self:ShowNotifier(1, Threat.tOptions.profile.nShowNotifySoft)
end

function Settings:OnSliderTextAlpha(wndHandler, wndControl, fNewValue, fOldValue)
	local wndCurrSlider = self.wndNotifySettings:FindChild("SettingShowPercentTextAlpha")
	wndCurrSlider:FindChild("SliderOutput"):SetText(self:ToPercent(fNewValue))
	Threat.tOptions.profile.nShowNotifySoftText = fNewValue / 100

	self:ShowNotifier(1, Threat.tOptions.profile.nShowNotifySoft)
end

function Settings:OnSliderShowPercentHigh(wndHandler, wndControl, fNewValue, fOldValue)
	local wndCurrSlider = self.wndNotifySettings:FindChild("SettingShowHighPercent")
	wndCurrSlider:FindChild("SliderOutput"):SetText(self:ToPercent(fNewValue))
	Threat.tOptions.profile.nShowNotifyHard = fNewValue / 100

	self:ShowNotifier(2, Threat.tOptions.profile.nShowNotifyHard)
end

function Settings:OnSliderBGAlphaHigh(wndHandler, wndControl, fNewValue, fOldValue)
	local wndCurrSlider = self.wndNotifySettings:FindChild("SettingShowHighPercentBGAlpha")
	wndCurrSlider:FindChild("SliderOutput"):SetText(self:ToPercent(fNewValue))
	Threat.tOptions.profile.nShowNotifyHardBG = fNewValue / 100

	self:ShowNotifier(2, Threat.tOptions.profile.nShowNotifyHard)
end

function Settings:OnSliderTextAlphaHigh(wndHandler, wndControl, fNewValue, fOldValue)
	local wndCurrSlider = self.wndNotifySettings:FindChild("SettingShowHighPercentTextAlpha")
	wndCurrSlider:FindChild("SliderOutput"):SetText(self:ToPercent(fNewValue))
	Threat.tOptions.profile.nShowNotifyHardText = fNewValue / 100

	self:ShowNotifier(2, Threat.tOptions.profile.nShowNotifyHard)
end

--Notify Buttons end

function Settings:ToPercent(value)
	return string.format("%d%s", value, "%")
end

--Notify end

function Settings:OnBtnShowProfiles(wndHandler, wndControl)
	if self.wndProfiles == nil then
		local CurrentProfile = Threat.tOptions:GetCurrentProfile()

		self.wndProfiles = Apollo.LoadForm(self.oXml, "Profiles", nil, self)
		self.wndProfiles:FindChild("ProfileName"):SetText(CurrentProfile)

		local wndPList = self.wndProfiles:FindChild("LstProfile")
		local tProfiles = Threat.tOptions:GetProfiles()

		for k,v in ipairs(tProfiles) do
			if CurrentProfile ~= v then
				Apollo.LoadForm(self.oXml, "ProfileListEntry", wndPList, self):SetText(v)
			end
		end
		wndPList:ArrangeChildrenVert()
	end
end

function Settings:OnBtnTest(wndHandler, wndControl)
	Threat:GetModule("Main"):ShowTestBars()
end

function Settings:OnBtnChoose(wndHandler, wndControl)
	local GeminiColor = Apollo.GetPackage("GeminiColor").tPackage
	local tColor = Threat.tOptions.profile.tColors[wndControl:GetParent():GetData()]
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
	Threat.tOptions.profile.tColors[wndControl:GetData()] = {
		nR = nR * 255,
		nG = nG * 255,
		nB = nB * 255,
		nA = nA * 255
	}
	wndControl:FindChild("ColorBackground"):SetBGColor(ApolloColor.new(nR, nG, nB, nA))
end

function Settings:Open()
	if self.wndMain == nil then return end

	self:ApplyCurrent()
	self.wndMain:Show(true)
	Threat:GetModule("Main").wndMain:FindChild("Background"):Show(true)
	if not self.bPreview then
		Threat:GetModule("Main").wndNotify:FindChild("Background"):Show(true)
	end
end

function Settings:Close()
	if self.wndMain == nil then return end

	self.wndMain:Show(false)
	Threat:GetModule("Main").wndMain:FindChild("Background"):Show(false)

	if self.wndNotifySettings == nil then
		Threat:GetModule("Main").wndNotify:FindChild("Background"):Show(false)
	end
end

--Profiles

function Settings:OnBtnProfileSelect(wndHandler, wndControl)
	if wndControl:IsChecked() then
		self.SelectedProfile = wndControl:GetText()
	else
		self.SelectedProfile = nil
	end
end

function Settings:OnBtnCopyProfile(wndHandler, wndControl)
	if self.SelectedProfile ~= nil then
		Threat.tOptions:CopyProfile(self.SelectedProfile, true)
	end
end

function Settings:OnBtnResetProfile(wndHandler, wndControl)
	Threat.tOptions:ResetProfile()
end

function Settings:OnBtnProfilesClose(wndHandler, wndControl)
	if self.wndProfiles == nil then return end

	self.wndProfiles:Destroy()

	self.wndProfiles = nil
	self.SelectedProfile = nil
end

--Profiles end

function Settings:ApplyCurrent()
	self.wndMain:FindChild("BtnEnable"):SetCheck(Threat.tOptions.profile.bEnabled)
	self.wndMain:FindChild("BtnLock"):SetCheck(Threat.tOptions.profile.bLock)
	self.wndMain:FindChild("BtnSimpleColors"):SetCheck(not (Threat.tOptions.profile.bUseRoleColors or Threat.tOptions.profile.bUseClassColors))
	self.wndMain:FindChild("BtnClassColors"):SetCheck(Threat.tOptions.profile.bUseClassColors)
	self.wndMain:FindChild("BtnRoleColors"):SetCheck(Threat.tOptions.profile.bUseRoleColors)
	self.wndMain:FindChild("BtnShowSolo"):SetCheck(Threat.tOptions.profile.bShowSolo)
	self.wndMain:FindChild("BtnShowDifferences"):SetCheck(Threat.tOptions.profile.bShowDifferences)
	self.wndMain:FindChild("BtnShowThreatPerSec"):SetCheck(Threat.tOptions.profile.bShowThreatPerSec)
	self.wndMain:FindChild("BtnAlwaysUseSelf"):SetCheck(Threat.tOptions.profile.bUseSelfColor)
	self.wndMain:FindChild("BtnShowSelfWarning"):SetCheck(Threat.tOptions.profile.bShowSelfWarning)
	self.wndMain:FindChild("BtnRightToLeftBars"):SetCheck(Threat.tOptions.profile.bRightToLeftBars)

	local wndSlider = self.wndMain:FindChild("SettingUpdateRate")
	wndSlider:FindChild("SliderBar"):SetValue(Threat.tOptions.profile.nUpdateRate)
	wndSlider:FindChild("SliderOutput"):SetText(Threat.tOptions.profile.nUpdateRate)

	self:CreateColors()
end

function Settings:CreateColors()
	local L = Apollo.GetPackage("Gemini:Locale-1.0").tPackage:GetLocale("Threat", true)
	local wndList = self.wndMain:FindChild("LstColor")
	wndList:DestroyChildren()

	self:CreateColor(wndList, Threat.tOptions.profile.tColors.tSelf, "tSelf", L["self"])
	self:CreateColor(wndList, Threat.tOptions.profile.tColors.tSelfWarning, "tSelfWarning", L["selfWarning"])
	self:CreateColor(wndList, Threat.tOptions.profile.tColors.tOthers, "tOthers", L["others"])
	self:CreateColor(wndList, Threat.tOptions.profile.tColors.tPet, "tPet", L["pet"])

	Apollo.LoadForm(self.oXml, "Divider", wndList, self)

	self:CreateColor(wndList, Threat.tOptions.profile.tColors.tTank, "tTank", Apollo.GetString("Matching_Role_Tank"))
	self:CreateColor(wndList, Threat.tOptions.profile.tColors.tHealer, "tHealer", Apollo.GetString("Matching_Role_Healer"))
	self:CreateColor(wndList, Threat.tOptions.profile.tColors.tDamage, "tDamage", Apollo.GetString("Matching_Role_Dps"))

	Apollo.LoadForm(self.oXml, "Divider", wndList, self)

	for eClass, tColor in pairs(Threat.tOptions.profile.tColors) do
		if type(eClass) == "number" then
			self:CreateColor(wndList, tColor, eClass, GameLib.GetClassName(eClass))
		end
	end

	wndList:ArrangeChildrenVert()
end

function Settings:CreateColor(wndList, pColor, pData, pText)
	local wndColor = Apollo.LoadForm(self.oXml, "Color", wndList, self)
	local tColor = pColor
	wndColor:SetData(pData)
	wndColor:FindChild("Name"):SetText(pText)
	wndColor:FindChild("ColorBackground"):SetBGColor(ApolloColor.new(
		tColor.nR / 255,
		tColor.nG / 255,
		tColor.nB / 255,
		tColor.nA / 255
	))
end