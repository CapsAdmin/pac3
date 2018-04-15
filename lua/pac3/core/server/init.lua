
pac = pac or {}

pac.Parts = pac.Parts or {}
pac.Errors = {}
pac.resource = include("pac3/libraries/resource.lua")

include("pac3/core/shared/init.lua")

include("util.lua")
include("effects.lua")
include("event.lua")
include("net_messages.lua")

CreateConVar("has_pac3", "1", {FCVAR_NOTIFY})
CreateConVar('pac_allow_mdl', '1', {FCVAR_ARCHIVE, FCVAR_REPLICATED}, 'Allow to use custom MDLs')
CreateConVar('pac_allow_mdl_entity', '1', {FCVAR_ARCHIVE, FCVAR_REPLICATED}, 'Allow to use custom MDLs as Entity')

hook.Run("pac_Initialized")
