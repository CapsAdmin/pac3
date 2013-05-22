--include("libraries/von.lua")
--include("libraries/netstream.lua")

include("hands.lua")
include("pac_weapon.lua")
include("modifiers.lua")
include("footsteps_fix.lua")
include("projectiles.lua")

local cvar = CreateConVar("pac_restrictions", "0", FCVAR_REPLICATED)

function pac.GetRestrictionLevel()
	return cvar:GetInt()
end