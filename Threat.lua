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
    bLock = false,
    tPosition = {
      nX = 100,
      nY = 100
    },
    nCombatDelay = 5,
    bUseClassColors = false,
    tColors = {
      sSelf = { nR = 87, nG = 156, nB = 12, nA = 255 },
      sOthers = { nR = 13, nG = 143, nB = 211, nA = 255 },
      [GameLib.CodeEnumClass.Warrior] = { nR = 235, nG = 27, nB = 27, nA = 255 },
      [GameLib.CodeEnumClass.Engineer] = { nR = 225, nG = 140, nB = 32, nA = 255 },
      [GameLib.CodeEnumClass.Esper] = { nR = 13, nG = 143, nB = 211, nA = 255 },
      [GameLib.CodeEnumClass.Medic] = { nR = 233, nG = 192, nB = 36, nA = 255 },
      [GameLib.CodeEnumClass.Spellslinger] = { nR = 87, nG = 156, nB = 12, nA = 255 },
      [GameLib.CodeEnumClass.Stalker] = { nR = 154, nG = 25, nB = 230, nA = 255 }
    }
  }
}

Threat.tOptions = {}

function Threat:OnInitialize()
  local GeminiLogging = Apollo.GetPackage("Gemini:Logging-1.2").tPackage
  self.Log = GeminiLogging:GetLogger({
    level = GeminiLogging.INFO,
    pattern = "[%d %l %c:%n] %m",
    appender = "GeminiConsole"
  })
  Apollo.RegisterEventHandler("InterfaceMenuListHasLoaded", "OnInterfaceMenuListHasLoaded", self)
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
    for oKey, oVal in pairs(self.tDefaults.tCharacter) do
      if tOptions[oKey] == nil then
        tOptions[oKey] = oVal
      end
    end
    self.tOptions.tCharacter = Utility:TableCopyRecursive(tOptions)
  elseif eType == GameLib.CodeEnumAddonSaveLevel.Account then
    for oKey, oVal in pairs(self.tDefaults.tAccount) do
      if tOptions[oKey] == nil then
        tOptions[oKey] = oVal
      end
    end
    self.tOptions.tAccount = Utility:TableCopyRecursive(tOptions)
  end
end
