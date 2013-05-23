pace = pace or {}

pace.Parts = pace.Parts or {}
pace.Errors = {}

include("util.lua")
include("bans.lua")
include("event.lua")
include("effects.lua")
include("wear.lua")

CreateConVar("has_pac3_editor", "1", {FCVAR_NOTIFY})