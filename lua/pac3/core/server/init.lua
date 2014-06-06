pac = pac or {}

pac.Parts = pac.Parts or {}
pac.Errors = {}

include("pac3/core/shared/init.lua")

include("util.lua")

include("effects.lua")
include("event.lua")
include("map_outfit.lua")
include("boneanimlib.lua")
include("netmessages.lua")

CreateConVar("has_pac3", "1", {FCVAR_NOTIFY})

hook.Run("pac_Initialized")