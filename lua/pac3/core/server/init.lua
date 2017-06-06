pac = pac or {}

pac.Parts = pac.Parts or {}
pac.Errors = {}

include("pac3/core/shared/init.lua")

include("util.lua")

include("effects.lua")
include("event.lua")
include("map_outfit.lua")
include("boneanimlib.lua")
include("net_messages.lua")

CreateConVar("has_pac3", "1", {FCVAR_NOTIFY})
-- If clients are allowed to use the 'workshop' part to make other clients download and mount workshop content
CreateConVar("pac_sv_workshop_enabled", "0", {FCVAR_REPLICATED})

hook.Run("pac_Initialized")