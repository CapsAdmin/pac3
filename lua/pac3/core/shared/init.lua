--include("libraries/von.lua")
--include("libraries/netstream.lua")

include("hands.lua")
include("pac_weapon.lua")
include("modifiers.lua")
include("footsteps_fix.lua")
include("projectiles.lua")
include("boneanimlib.lua")

local cvar = CreateConVar("pac_restrictions", "0", FCVAR_REPLICATED)

function pac.GetRestrictionLevel()
	return cvar:GetInt()
end

CreateConVar("pac_sv_draw_distance", 0, bit.bor(FCVAR_REPLICATED, FCVAR_ARCHIVE))