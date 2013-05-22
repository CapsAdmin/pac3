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

timer.Create("pac_to_git_notify", 30, 0, function()
	print("!!!!PAC3 has moved to GitHub!!!!")
	print("the new address is:")
	print("https://github.com/CapsAdmin/pac3")
	
	print("to keep using svn change the svn address to:")
	print("https://github.com/CapsAdmin/pac3.git/trunk")
end)