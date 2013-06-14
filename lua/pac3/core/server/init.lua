pac = pac or {}

pac.Parts = pac.Parts or {}
pac.Errors = {}

include("pac3/core/shared/init.lua")

include("util.lua")

include("effects.lua")
include("event.lua")
include("map_outfit.lua")

CreateConVar("has_pac3", "1", {FCVAR_NOTIFY})