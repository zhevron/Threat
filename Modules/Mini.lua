require "Apollo"
require "GameLib"

local Threat = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("Threat")
local Mini = Threat:NewModule("Mini")

Mini.bActive = false

--[[ Initial functions ]]--

function Mini:OnInitialize()
end

function Mini:OnEnable()
end

function Mini:OnDisable()
end