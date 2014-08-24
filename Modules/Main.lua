require "Apollo"
require "ApolloTimer"
require "GameLib"
require "GroupLib"

local Threat = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("Threat")
local Main = Threat:NewModule("Main")

Main.tThreatList = {}
Main.nTotal = 0
Main.nDuration = 0
Main.nLastEvent = 0

function Main:OnInitialize()
  self.oXml = XmlDoc.CreateFromFile("Forms/Main.xml")
  if self.oXml == nil then
    Apollo.AddAddonErrorText(Threat, "Could not load the Threat window!")
    return
  end
  self.oXml:RegisterCallback("OnDocumentReady", self)

  -- Create a timer to track combat status. Needed for TPS calculations.
  self.tCombatTimer = ApolloTimer.Create(1, true, "OnCombatTimer", self)
  self.tCombatTimer:Stop()

  -- Create a timer to update the UI. We don't need to do that as often as every frame.
  self.tUpdateTimer = ApolloTimer.Create(0.5, true, "OnUpdateTimer", self)
  self.tUpdateTimer:Stop()
end

function Main:OnEnable()
  Apollo.RegisterEventHandler("TargetThreatListUpdated", "OnTargetThreatListUpdated", self)

  if self.wndMain ~= nil then
    self.wndMain:Show(true)
  end

  self.tCombatTimer:Start()
  self.tUpdateTimer:Start()

  if not Threat.tOptions.tCharacter.bEnabled then
    self:Disable()
  end
end

function Main:OnDisable()
  Apollo.RemoveEventHandler("TargetThreatListUpdated", self)

  if self.wndMain ~= nil then
    self.wndMain:Show(false)
  end

  self.tCombatTimer:Stop()
  self.tUpdateTimer:Stop()
end

function Main:OnDocumentReady()
  self.wndMain = Apollo.LoadForm(self.oXml, "Threat", nil, self)
  self:UpdateLockStatus()

  local nLeft = Threat.tOptions.tCharacter.tPosition.nX
  local nTop = Threat.tOptions.tCharacter.tPosition.nY
  local nWidth = Threat.tOptions.tCharacter.tSize.nWidth
  local nHeight = Threat.tOptions.tCharacter.tSize.nHeight
  self.wndMain:SetAnchorOffsets(nLeft, nTop, nLeft + nWidth, nTop + nHeight)
end

function Main:OnTargetThreatListUpdated(...)
  self.tThreatList = {}
  self.nTotal = 0
  self.nLastEvent = os.time()

  -- Create the new threat list
  for nId = 1, select("#", ...), 2 do
    local oUnit = select(nId, ...)
    local nValue = select(nId + 1, ...)
    table.insert(self.tThreatList, {
      nId = oUnit:GetId(),
      sName = oUnit:GetName(),
      eClass = oUnit:GetClassId(),
      nValue = nValue
    })
    self.nTotal = self.nTotal + nValue
  end
end

function Main:OnCombatTimer()
  if os.time() >= (self.nLastEvent + Threat.tOptions.tCharacter.nCombatDelay) then
    self.wndMain:FindChild("BarList"):DestroyChildren()
    self.nDuration = 0
  else
    self.nDuration = self.nDuration + 1
  end
end

function Main:OnUpdateTimer()
  if self.wndMain == nil then
    return
  end

  if not Threat.tOptions.tCharacter.bShowSolo and #self.tThreatList < 2 then
    return
  end

  local wndList = self.wndMain:FindChild("BarList")
  if self.nTotal >= 0 then
    wndList:DestroyChildren()
    for _, tEntry in pairs(self.tThreatList) do
      self:CreateBar(wndList, tEntry)
    end
    wndList:ArrangeChildrenVert(0, Main.SortBars)
  end
end

function Main:OnMouseEnter()
  if not Threat.tOptions.tCharacter.bLock then
    self.wndMain:FindChild("Background"):Show(true)
  end
end

function Main:OnMouseExit()
  if not Threat:GetModule("Settings").wndMain:IsShown() then
    self.wndMain:FindChild("Background"):Show(false)
  end
end

function Main:OnMouseButtonUp(wndHandler, wndControl, eMouseButton)
  if eMouseButton == GameLib.CodeEnumInputMouse.Right then
    if not Threat.tOptions.tCharacter.bLock then
      Threat:GetModule("Settings"):Open()
    end
  end
end

function Main:OnWindowMove()
  local nLeft, nTop = self.wndMain:GetAnchorOffsets()
  Threat.tOptions.tCharacter.tPosition.nX = nLeft
  Threat.tOptions.tCharacter.tPosition.nY = nTop
end

function Main:OnWindowSizeChanged()
  local nLeft, nTop, nRight, nBottom = self.wndMain:GetAnchorOffsets()
  Threat.tOptions.tCharacter.tSize.nWidth = nRight - nLeft
  Threat.tOptions.tCharacter.tSize.nHeight = nBottom - nTop
end

function Main:CreateBar(wndParent, tEntry)
  local wndBar = Apollo.LoadForm(self.oXml, "Bar", wndParent, self)

  -- Perform calculations for this entry.
  local nPerSecond = tEntry.nValue / self.nDuration
  local nPercent = (tEntry.nValue / self.nTotal) * 100
  local sValue = Threat:GetModule("Utility"):FormatNumber(tEntry.nValue, 2)

  -- Set the name string to the character name
  wndBar:FindChild("Name"):SetText(tEntry.sName)

  -- Print threat per second as a floating point number with a precision of 1. (Ex. 7572.2)
  wndBar:FindChild("ThreatPerSecond"):SetText(string.format("%.1f", nPerSecond))

  -- Print the total as a string with the formatted number and percentage of total. (Ex. 300k  42%)
  wndBar:FindChild("Total"):SetText(string.format("%s  %d%s", sValue, nPercent, "%"))
  wndBar:FindChild("Total"):SetData(tEntry.nValue)

  -- Update the progress bar with the new values and set the bar color.
  local nR, nG, nB, nA = self:GetColorForEntry(tEntry)
  local nLeft, nTop, _, nBottom = wndBar:FindChild("Background"):GetAnchorPoints()
  wndBar:FindChild("Background"):SetAnchorPoints(nLeft, nTop, nPercent / 100, nBottom)
  wndBar:FindChild("Background"):SetBGColor(ApolloColor.new(nR, nG, nB, nA))
end

function Main:GetColorForEntry(tEntry)
  local tColor = nil
  local tWhite = { nR = 255, nG = 255, nB = 255, nA = 255 }

  -- Determine the color of the bar based on user settings.
  if Threat.tOptions.tCharacter.bUseClassColors then
    -- Use class color. Defaults to white if not found.
    tColor = Threat.tOptions.tCharacter.tColors[tEntry.eClass] or tWhite
  elseif Threat.tOptions.tCharacter.bUseRoleColors and GroupLib.InGroup() then
    -- Use role color. Defaults to white if not found.
    for nIdx = 1, GroupLib.GetMemberCount() do
      local tMemberData = GroupLib.GetGroupMember(nIdx)
      if tMemberData.strCharacterName == tEntry.sName then
        if tMemberData.bTank then
          tColor = Threat.tOptions.tCharacter.tColors.tTank or tWhite
        elseif tMemberData.bHealer then
          tColor = Threat.tOptions.tCharacter.tColors.tHealer or tWhite
        else
          tColors = Threat.tOptions.tCharacter.tColors.tDamage or tWhite
        end
      end
    end
  else
    -- Use non-class colors. Defaults to white if not found.
    local oPlayer = GameLib.GetPlayerUnit()
    if oPlayer ~= nil and oPlayer:GetId() == tEntry.nId then
      -- This unit is the current player.
      tColor = Threat.tOptions.tCharacter.tColors.tSelf or tWhite
    else
      -- This unit is not the player.
      tColor = Threat.tOptions.tCharacter.tColors.tOthers or tWhite
    end
  end

  return (tColor.nR / 255), (tColor.nG / 255), (tColor.nB / 255), (tColor.nA / 255)
end

function Main:UpdateLockStatus()
  self.wndMain:SetStyle("Moveable", not Threat.tOptions.tCharacter.bLock)
  self.wndMain:SetStyle("Sizable", not Threat.tOptions.tCharacter.bLock)
  self.wndMain:SetStyle("IgnoreMouse", Threat.tOptions.tCharacter.bLock)
end

function Main:ShowTestBars()
  local tEntries = {
    {
      nId = 0,
      sName = GameLib.GetClassName(GameLib.CodeEnumClass.Warrior),
      eClass = GameLib.CodeEnumClass.Warrior,
      nValue = 1000000
    },
    {
      nId = 0,
      sName = GameLib.GetClassName(GameLib.CodeEnumClass.Engineer),
      eClass = GameLib.CodeEnumClass.Engineer,
      nValue = 900000
    },
    {
      nId = 0,
      sName = GameLib.GetClassName(GameLib.CodeEnumClass.Esper),
      eClass = GameLib.CodeEnumClass.Esper,
      nValue = 800000
    },
    {
      nId = 0,
      sName = GameLib.GetClassName(GameLib.CodeEnumClass.Medic),
      eClass = GameLib.CodeEnumClass.Medic,
      nValue = 700000
    },
    {
      nId = GameLib.GetPlayerUnit():GetId(),
      sName = GameLib.GetClassName(GameLib.CodeEnumClass.Spellslinger),
      eClass = GameLib.CodeEnumClass.Spellslinger,
      nValue = 600000
    },
    {
      nId = 0,
      sName = GameLib.GetClassName(GameLib.CodeEnumClass.Stalker),
      eClass = GameLib.CodeEnumClass.Stalker,
      nValue = 500000
    }
  }

  local wndList = self.wndMain:FindChild("BarList")
  wndList:DestroyChildren()

  self.nDuration = 10
  self.nTotal = 0
  for _, tEntry in pairs(tEntries) do
    self.nTotal = self.nTotal + tEntry.nValue
    self:CreateBar(wndList, tEntry)
  end
  wndList:ArrangeChildrenVert(0, Main.SortBars)

  self.nLastEvent = os.time() + 10
end

function Main.SortBars(wndBar1, wndBar2)
  local nValue1 = wndBar1:FindChild("Total"):GetData()
  local nValue2 = wndBar2:FindChild("Total"):GetData()
  return nValue1 >= nValue2
end
