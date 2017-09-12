pac = pac or {}

pac.Parts = pac.Parts or {}
pac.Errors = {}
pac.resource = include("pac3/libraries/resource.lua")

include("pac3/core/shared/init.lua")

include("util.lua")
include("effects.lua")
include("event.lua")
include("pac3/libraries/boneanimlib.lua")
include("net_messages.lua")

CreateConVar("has_pac3", "1", {FCVAR_NOTIFY})

hook.Run("pac_Initialized")