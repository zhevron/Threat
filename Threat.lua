require "Apollo"
require "GameLib"

local Threat = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:NewAddon("Threat", true)

Threat.tVersion = {
  nMajor = 1,
  nMinor = 0,
  nBuild = 4
}

local tDefaults = {
  profile = {
    bEnabled = true,
    bShowSolo = false,
    bShowDifferences = false,
    bShowThreatPerSec = true,
    bUseSelfColor = false,
    bShowSelfWarning = false,
    bRightToLeftBars = false,
    bLock = false,
    tPosition = {
      nX = 100,
      nY = 100
    },
    tSize = {
      nWidth = 350,
      nHeight = 250
    },
    nCombatDelay = 5,
    bUseClassColors = false,
    bUseRoleColors = false,
    tColors = {
      tSelf = { nR = 87, nG = 156, nB = 12, nA = 255 },
      tOthers = { nR = 13, nG = 143, nB = 211, nA = 255 },
      tPet = { nR = 47, nG = 79, nB = 79, nA = 255 },
      tSelfWarning = { nR = 235, nG = 27, nB = 27, nA = 255 },
      tTank = { nR = 154, nG = 25, nB = 230, nA = 255 },
      tHealer = { nR = 87, nG = 156, nB = 12, nA = 255 },
      tDamage = { nR = 235, nG = 27, nB = 27, nA = 255 },
      [GameLib.CodeEnumClass.Warrior] = { nR = 204, nG = 26, nB = 26, nA = 255 },
      [GameLib.CodeEnumClass.Engineer] = { nR = 204, nG = 204, nB = 0, nA = 255 },
      [GameLib.CodeEnumClass.Esper] = { nR = 26, nG = 128, nB = 179, nA = 255 },
      [GameLib.CodeEnumClass.Medic] = { nR = 51, nG = 153, nB = 26, nA = 255 },
      [GameLib.CodeEnumClass.Spellslinger] = { nR = 230, nG = 102, nB = 0, nA = 255 },
      [GameLib.CodeEnumClass.Stalker] = { nR = 128, nG = 26, nB = 204, nA = 255 }
    }
  }
}

function Threat:OnInitialize()
  self.tOptions = Apollo.GetPackage("Gemini:DB-1.0").tPackage:New(self, tDefaults)
  self.tOptions.RegisterCallback(self, "OnProfileReset", "OnProfileReset")
  Apollo.RegisterEventHandler("InterfaceMenuListHasLoaded", "OnInterfaceMenuListHasLoaded", self)
  Apollo.RegisterSlashCommand("threat", "OnSlashCommand", self)
end

function Threat:OnEnable()
end

function Threat:OnDisable()
end

function Threat:OnInterfaceMenuListHasLoaded()
end

function Threat:OnConfigure()
  self:GetModule("Settings"):Open()
end

function Threat:OnSlashCommand()
  local Main = self:GetModule("Main")
  self.tOptions.profile.bEnabled = not Main:IsEnabled()
  if Main:IsEnabled() then
    Main:Disable()
  else
    Main:Enable()
  end
end

function Threat:OnProfileReset(tOptions)
  self:GetModule("Main"):UpdatePosition()
  self:GetModule("Main"):UpdateLockStatus()
  self:GetModule("Settings"):ApplyCurrent()
end

function Threat:GetVersionString()
  return string.format("%d.%d.%d", self.tVersion.nMajor, self.tVersion.nMinor, self.tVersion.nBuild)
end
