require "Apollo"
require "GameLib"

local Threat = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:NewAddon("Threat", true)

Threat.tVersion = {
  nMajor = 0,
  nMinor = 0,
  nBuild = 1
}

Threat.tDefaults = {
  tAccount = {
  },
  tCharacter = {
    bEnabled = true,
    bShowSolo = false,
    bShowDifferences = false,
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
      tTank = { nR = 154, nG = 25, nB = 230, nA = 255 },
      tHealer = { nR = 87, nG = 156, nB = 12, nA = 255 },
      tDamage = { nR = 235, nG = 27, nB = 27, nA = 255 },
      [GameLib.CodeEnumClass.Warrior] = { nR = 235, nG = 27, nB = 27, nA = 255 },
      [GameLib.CodeEnumClass.Engineer] = { nR = 225, nG = 140, nB = 32, nA = 255 },
      [GameLib.CodeEnumClass.Esper] = { nR = 13, nG = 143, nB = 211, nA = 255 },
      [GameLib.CodeEnumClass.Medic] = { nR = 233, nG = 192, nB = 36, nA = 255 },
      [GameLib.CodeEnumClass.Spellslinger] = { nR = 87, nG = 156, nB = 12, nA = 255 },
      [GameLib.CodeEnumClass.Stalker] = { nR = 154, nG = 25, nB = 230, nA = 255 }
    }
  }
}

Threat.tOptions = {
  tAccount = {},
  tCharacter = {}
}

function Threat:OnInitialize()
  local Utility = self:GetModule("Utility")
  self.tOptions.tCharacter = Utility:TableCopyRecursive(self.tDefaults.tCharacter)
  self.tOptions.tAccount = Utility:TableCopyRecursive(self.tDefaults.tAccount)
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
  self.tOptions.tCharacter.bEnabled = not Main:IsEnabled()
  if Main:IsEnabled() then
    Main:Disable()
  else
    Main:Enable()
  end
end

function Threat:OnSave(eType)
  local Utility = self:GetModule("Utility")
  if eType == GameLib.CodeEnumAddonSaveLevel.Character then
    return Utility:TableCopyRecursive(self.tOptions.tCharacter)
  elseif eType == GameLib.CodeEnumAddonSaveLevel.Account then
    return Utility:TableCopyRecursive(self.tOptions.tAccount)
  end
  return nil
end

function Threat:OnRestore(eType, tOptions)
  local Utility = self:GetModule("Utility")
  if eType == GameLib.CodeEnumAddonSaveLevel.Character then
    self.tOptions.tCharacter = Utility:TableCopyRecursive(tOptions, self.tOptions.tCharacter)
  elseif eType == GameLib.CodeEnumAddonSaveLevel.Account then
    self.tOptions.tAccount = Utility:TableCopyRecursive(tOptions, self.tOptions.tAccount)
  end
end
