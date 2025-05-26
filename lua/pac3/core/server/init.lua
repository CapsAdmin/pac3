
pac = pac or {}

pac.Parts = pac.Parts or {}
pac.Errors = {}
pac.resource = include("pac3/libraries/resource.lua")

CreateConVar("has_pac3", "1", {FCVAR_NOTIFY})
CreateConVar("pac_allow_blood_color", "1", {FCVAR_NOTIFY}, "Allow to use custom blood color")
CreateConVar("pac_allow_mdl", "1", CLIENT and {FCVAR_REPLICATED} or {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Allow to use custom MDLs")
CreateConVar("pac_allow_mdl_entity", "1", CLIENT and {FCVAR_REPLICATED} or {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Allow to use custom MDLs as Entity")

local default = "0"
if game.SinglePlayer() then default = "1" end
CreateConVar("pac_sv_nearest_life", default, {FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_NOTIFY}, "Enables nearest_life aimparts and bones, abusable for aimbot-type setups (which would already be possible with CS lua)")
CreateConVar("pac_sv_nearest_life_allow_sampling_from_parts", "1", {FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_NOTIFY}, "Restricts nearest_life aimparts and bones search to the player itself to prevent sampling from arbitrary positions\n0=sampling can only start from the player itself")
CreateConVar("pac_sv_nearest_life_allow_bones", default, {FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_NOTIFY}, "Restricts nearest_life bones, preventing placement on external entities' position")
CreateConVar("pac_sv_nearest_life_allow_targeting_players", "1", {FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_NOTIFY}, "Restricts nearest_life aimparts and bones to forbid targeting players\n0=no target players")
CreateConVar("pac_sv_nearest_life_max_distance", "5000", {FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_NOTIFY}, "Restricts the radius for nearest_life aimparts and bones")

include("util.lua")

include("pac3/core/shared/init.lua")

include("effects.lua")
include("event.lua")
include("net_messages.lua")
include("test_suite_backdoor.lua")
include("in_skybox.lua")

pac.CallHook("Initialized")
