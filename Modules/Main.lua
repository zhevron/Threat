require "Apollo"
require "ApolloTimer"
require "GameLib"

local Threat = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("Threat")
local Main = Threat:NewModule("Main")

Main.tThreatList = {}
Main.nTotal = 0
Main.nDuration = 0

function Main:OnInitialize()
  self.oXml = XmlDoc.CreateFromFile("Forms/Main.xml")
  if self.oXml == nil then
    Apollo.AddAddonErrorText(Threat, "Could not load the Threat window!")
    return
  end
  self.oXml:RegisterCallback("OnDocumentReady", self)
  self.tCombatTimer = ApolloTimer.Create(1, true, "OnCombatTimer", self)
  self.tCombatTimer:Stop()
  self.tUpdateTimer = ApolloTimer.Create(0.5, true, "OnUpdateTimer", self)
  self.tUpdateTimer:Stop()
end

function Main:OnEnable()
  Apollo.RegisterEventHandler("TargetThreatListUpdated", "OnTargetThreatListUpdated", self)
  self.tCombatTimer:Start()
  self.tUpdateTimer:Start()
end

function Main:OnDisable()
  if self.wndMain ~= nil then
    self.wndMain:Show(false)
  end
  self.tCombatTimer:Stop()
  self.tUpdateTimer:Stop()
end

function Main:OnDocumentReady()
  self.wndMain = Apollo.LoadForm(self.oXml, "Threat", nil, self)
end

function Main:OnTargetThreatListUpdated(...)
  self.tThreatList = {}
  self.nTotal = 0
  for nId = 1, select("#", ...), 2 do
    local oUnit = select(nId, ...)
    local nValue = select(nId + 1, ...)
    table.insert(self.tThreatList, {
      sName = oUnit:GetName(),
      eClass = oUnit:GetClassId(),
      nValue = nValue
    })
    self.nTotal = self.nTotal + nValue
  end
end

function Main:OnCombatTimer()
  local oPlayer = GameLib.GetPlayerUnit()
  if oPlayer ~= nil and oPlayer:IsInCombat() then
    self.nDuration = self.nDuration + 1
  else
    self.nDuration = 0
  end
end

function Main:OnUpdateTimer()
  if self.wndMain == nil then
    return
  end
  local wndList = self.wndMain:FindChild("BarList")
  wndList:DestroyChildren()
  if self.nTotal >= 0 then
    for _, tEntry in pairs(self.tThreatList) do
      self:CreateBar(wndList, tEntry)
    end
    wndList:ArrangeChildrenVert(0, Main.SortBars)
  end
end

function Main:CreateBar(wndParent, tEntry)
  local Utility = Threat:GetModule("Utility")
  local wndBar = Apollo.LoadForm(self.oXml, "Bar", wndParent, self)
  local sValue = Utility:FormatNumber(tEntry.nValue)
  local nPerSecond = tEntry.nValue / self.nDuration
  local nPercent = (tEntry.nValue / self.nTotal) * 100
  wndBar:FindChild("Name"):SetText(tEntry.sName)
  wndBar:FindChild("ThreatPerSecond"):SetText(string.format("%.1f", nPerSecond))
  wndBar:FindChild("Total"):SetText(string.format("%s  %d%s", sValue, nPercent, "%"))
  wndBar:FindChild("Total"):SetData(tEntry.nValue)
end

function Main.SortBars(wndBar1, wndBar2)
  local nValue1 = wndBar1:FindChild("Total"):GetData()
  local nValue2 = wndBar2:FindChild("Total"):GetData()
  return nValue1 <= nValue2
end
