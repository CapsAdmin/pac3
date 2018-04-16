pace = pace or {}
pace.net = include("pac3/libraries/netx.lua")

-- for the default models
resource.AddWorkshop("104691717")

pace.Parts = pace.Parts or {}
pace.Errors = {}

util.AddNetworkString('pac_submit_acknowledged')
util.AddNetworkString('pac_update_playerfilter')

include("util.lua")
include("wear.lua")
include("bans.lua")
include("spawnmenu.lua")

do
	util.AddNetworkString("pac_in_editor")

	net.Receive("pac_in_editor", function(_, ply)
		ply:SetNW2Bool("pac_in_editor", net.ReadBit() == 1)
	end)
end


CreateConVar("has_pac3_editor", "1", {FCVAR_NOTIFY})

resource.AddSingleFile("materials/icon64/pac3.png")