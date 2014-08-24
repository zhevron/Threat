require "Apollo"

local Threat = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("Threat")
local Utility = Threat:NewModule("Utility")

function Utility:FormatNumber(nNumber, nPrecision)
  nPrecision = nPrecision or 0
  if nNumber >= 1000000 then
    return string.format("%."..nPrecision.."fm", nNumber / 1000000)
  elseif nNumber >= 10000 then
    return string.format("%."..nPrecision.."fk", nNumber / 1000)
  else
    return tostring(nNumber)
  end
end

function Utility:TableCopyRecursive(tSource, tDestination)
  if type(tSource) ~= "table" then
    return {}
  end
  local tMetatable = getmetatable(tSource)
  local tDestination = self:TableCopyRecursive(tDestination)
  if type(tDestination) ~= "table" then
    return
  end
  for oKey, oValue in pairs(tSource) do
    if type(oValue) == "table" then
      oValue = self:TableCopyRecursive(oValue)
    end
    tDestination[oKey] = oValue
  end
  setmetatable(tDestination, tMetatable)
  return tDestination
end
