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
  tDestination = tDestination or {}
  for key, val in pairs(tSource) do
    if type(key) ~= "table" then
      if type(val) ~= "table" then
        tDestination[key] = val
      else
        tDestination[key] = self:TableCopyRecursive(val, tDestination[key])
      end
    end
  end
  return tDestination
end
