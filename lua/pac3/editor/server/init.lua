pace = pace or {}

pace.Parts = pace.Parts or {}
pace.Errors = {}

util.AddNetworkString('pac_submit_acknowledged')

include("util.lua")

include("wear.lua")
include("bans.lua")
include("contraption.lua")
include("spawnmenu.lua")
include("global_bans.lua")
include("net_messages.lua")

CreateConVar("has_pac3_editor", "1", {FCVAR_NOTIFY})

resource.AddSingleFile("materials/icon64/pac3.png")