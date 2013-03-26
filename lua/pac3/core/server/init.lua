pac = pac or {}

pac.Parts = pac.Parts or {}
pac.Errors = {}

include("pac3/core/shared/init.lua")

include("util.lua")
include("bans.lua")
include("effects.lua")
include("wear.lua")
include("event.lua")
include("contraption.lua")
include("spawnmenu.lua")

-- should this be here?

concommand.Add("pac_in_editor", function(ply, _, args)
	ply:SetNWBool("in pac3 editor", tonumber(args[1]) == 1)
end)

CreateConVar("has_pac3", "1", {FCVAR_NOTIFY})