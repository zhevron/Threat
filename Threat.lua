require "Apollo"
require "GameLib"

local Threat = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:NewAddon("Threat", true)

Threat.tVersion = {
	nMajor = 2,
	nMinor = 1,
	nBuild = 0
}

--[[
Description to what some of the values mean in the settings
--------------------------------------------------------------------------------------------------------
nShow: 		0 = Disabled  || 1 = Only in Group  || 2 = Only in Party  || 3 = Only in Raid  || 4 = Always
nColorMode: 0 = Simple	  || 1 = Role			|| 2 = Class
--------------------------------------------------------------------------------------------------------
]]
Threat.tDefaults = {
	profile = {
		bEnabled = true,
		bShowSolo = false,
		bLocked = false,
		nUpdateRate = 0.4,
		
		tList = {
			nShow = 4,

			bShowDifferences = false,
			bRightToLeftBars = false,

			nBarStyle = 0,
			nBarHeight = 22,
			nBarOffset = 1,

			tPosition = {
				nX = 840,
				nY = 100
			},
			tSize = {
				nWidth = 320,
				nHeight = 183
			},

			bAlwaysUseSelfColor = true,
			bUseSelfWarning = true,
			nColorMode = 0,
			tColors = {
				tSelf = { nR = 255, nG = 125, nB = 0, nA = 255 },
				tSelfWarning = { nR = 230, nG = 0, nB = 0, nA = 255 },
				tOthers = { nR = 10, nG = 140, nB = 200, nA = 255 },
				tPet = { nR = 47, nG = 79, nB = 79, nA = 255 },

				tTank = { nR = 145, nG = 25, nB = 220, nA = 255 },
				tHealer = { nR = 87, nG = 156, nB = 12, nA = 255 },
				tDamage = { nR = 10, nG = 140, nB = 200, nA = 255 },

				[GameLib.CodeEnumClass.Warrior] = { nR = 204, nG = 26, nB = 26, nA = 255 },
				[GameLib.CodeEnumClass.Engineer] = { nR = 240, nG = 220, nB = 0, nA = 255 },
				[GameLib.CodeEnumClass.Esper] = { nR = 26, nG = 128, nB = 179, nA = 255 },
				[GameLib.CodeEnumClass.Medic] = { nR = 51, nG = 153, nB = 26, nA = 255 },
				[GameLib.CodeEnumClass.Spellslinger] = { nR = 230, nG = 102, nB = 0, nA = 255 },
				[GameLib.CodeEnumClass.Stalker] = { nR = 128, nG = 26, nB = 204, nA = 255 }
			}
		},

		tNotify = {
			nShow = 3,

			tAlert = {
				tLow = {
					nPercent = 0.9,
					nAlphaBG = 0.6,
					nAlphaText = 0.8
				},
				tHigh = {
					nPercent = 0.95,
					nAlphaBG = 0.95,
					nAlphaText = 1
				}
			},

			tPosition = {
				nX = 0,
				nY = 300
			},

			tColors = {
				tLowText = { nR = 255, nG = 255, nB = 255, nA = 255 },
				tHighText = { nR = 255, nG = 255, nB = 255, nA = 255 }
			}
		},

		tMini = {
			nShow = 0,
			bAlwaysShow = false,
			bDifferenceToTank = false,

			tSwitch = {
				nMid = 0.85,
				nHigh = 0.95
			},

			tPosition = {
				nX = 840,
				nY = 450
			},
			tSize = {
				nWidth = 160,
				nHeight = 100
			},

			tColors = {
				tLow = { nR = 255, nG = 255, nB = 255, nA = 255 },
				tMid = { nR = 255, nG = 100, nB = 0, nA = 255 },
				tHigh = { nR = 255, nG = 0, nB = 0, nA = 255 },
				tOver = { nR = 255, nG = 0, nB = 255, nA = 255 }
			}
		}
	}
}

function Threat:OnInitialize()
	self.tOptions = Apollo.GetPackage("Gemini:DB-1.0").tPackage:New(self, self.tDefaults)
	self.tOptions.RegisterCallback(self, "OnProfileReset", "OnProfileReset")
	self.tOptions.RegisterCallback(self, "OnProfileCopied", "OnProfileCopied")

	Apollo.RegisterSlashCommand("threat", "OnConfigure", self)
end

function Threat:OnEnable()
end

function Threat:OnDisable()
end

function Threat:OnConfigure()
	self:GetModule("Settings"):Open(1)
end

function Threat:OnSlashCommand() --Unused
	local Main = self:GetModule("Main")
	self.tOptions.profile.bEnabled = not Main:IsEnabled()
	if Main:IsEnabled() then
		Main:Disable()
	else
		Main:Enable()
	end
end

function Threat:OnProfileReset(tOptions)
	self:ReloadSettings()
end

function Threat:OnProfileCopied(db, sourceProfile)
	self:ReloadSettings()
end

function Threat:ReloadSettings()
	self:GetModule("Main"):ReloadSettings()
	self:GetModule("Settings"):GeneralApplyCurrent()
end
