
pac = pac or {}

pac.Parts = pac.Parts or {}
pac.Errors = {}
pac.resource = include("pac3/libraries/resource.lua")

CreateConVar("has_pac3", "1", {FCVAR_NOTIFY})
CreateConVar("pac_allow_blood_color", "1", {FCVAR_NOTIFY}, "Allow to use custom blood color")
CreateConVar('pac_allow_mdl', '1', CLIENT and {FCVAR_REPLICATED} or {FCVAR_ARCHIVE, FCVAR_REPLICATED}, 'Allow to use custom MDLs')
CreateConVar('pac_allow_mdl_entity', '1', CLIENT and {FCVAR_REPLICATED} or {FCVAR_ARCHIVE, FCVAR_REPLICATED}, 'Allow to use custom MDLs as Entity')

include("util.lua")

include("pac3/core/shared/init.lua")

include("effects.lua")
include("event.lua")
include("net_messages.lua")
include("test_suite_backdoor.lua")
include("in_skybox.lua")

hook.Run("pac_Initialized")
