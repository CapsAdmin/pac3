pac = pac or {}

pac.Parts = pac.Parts or {}
pac.Errors = {}

include("util.lua")
include("bans.lua")
include("effects.lua")
include("wear.lua")
include("playermodels.lua")
include("event.lua")
include("contraption.lua")
include("spawnmenu.lua")

-- should this be here?

concommand.Add("pac_in_editor", function(ply, _, args)
	ply:SetNWBool("in pac3 editor", tonumber(args[1]) == 1)
end)

local tags = GetConVarString("sv_tags")

if tags == "" then
	RunConsoleCommand("sv_tags", "PAC3")
elseif not tags:find("PAC3") then
	RunConsoleCommand("sv_tags", "PAC3," .. tags)
end