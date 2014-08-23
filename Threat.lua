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
    nCombatDelay = 5,
    bUseClassColors = false,
    tNonClassColors = {
      sSelf = "579c0cff",
      sOthers = "0d8fd3ff"
    },
    tClassColors = {
      [GameLib.CodeEnumClass.Warrior] = "eb1b1bff",
      [GameLib.CodeEnumClass.Engineer] = "e18c20ff",
      [GameLib.CodeEnumClass.Esper] = "0d8fd3ff",
      [GameLib.CodeEnumClass.Medic] = "e9c024ff",
      [GameLib.CodeEnumClass.Stalker] = "9a19e6ff",
      [GameLib.CodeEnumClass.Spellslinger] = "579c0cff"
    }
  }
}

Threat.tOptions = Threat.tDefaults

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
    for key, val in pairs(self.tDefaults.tCharacter) do
      if tOptions[key] == nil then
        tOptions[key] = val
      end
    end
    self.tOptions.tCharacter = Utility:TableCopyRecursive(tOptions, self.tOptions.tCharacter)
  elseif eType == GameLib.CodeEnumAddonSaveLevel.Account then
    for key, val in pairs(self.tDefaults.tAccount) do
      if tOptions[key] == nil then
        tOptions[key] = val
      end
    end
    self.tOptions.tAccount = Utility:TableCopyRecursive(tOptions, self.tOptions.tAccount)
  end
end
