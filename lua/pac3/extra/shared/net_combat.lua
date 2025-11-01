--lua_openscript pac3/extra/shared/net_combat.lua
if SERVER then
	include("pac3/editor/server/combat_bans.lua")
	include("pac3/editor/server/bans.lua")
end

local master_default = "0"

if string.find(engine.ActiveGamemode(), "sandbox") and game.SinglePlayer() then
	master_default = "1"
end

pac.global_combat_whitelist = pac.global_combat_whitelist or {}

local hitscan_allow = CreateConVar("pac_sv_hitscan", master_default, CLIENT and {FCVAR_REPLICATED} or {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Allow hitscan parts serverside")
local hitscan_max_bullets = CreateConVar("pac_sv_hitscan_max_bullets", "200", CLIENT and {FCVAR_REPLICATED} or {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "hitscan part maximum number of bullets")
local hitscan_max_damage = CreateConVar("pac_sv_hitscan_max_damage", "20000", CLIENT and {FCVAR_REPLICATED} or {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "hitscan part maximum damage")
local hitscan_spreadout_dmg = CreateConVar("pac_sv_hitscan_divide_max_damage_by_max_bullets", 0, CLIENT and {FCVAR_REPLICATED} or {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Whether or not force hitscans to divide their damage among the number of bullets fired")

local damagezone_allow = CreateConVar("pac_sv_damage_zone", master_default, CLIENT and {FCVAR_REPLICATED} or {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Allow damage zone parts serverside")
local damagezone_max_damage = CreateConVar("pac_sv_damage_zone_max_damage", "20000", CLIENT and {FCVAR_REPLICATED} or {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "damage zone maximum damage")
local damagezone_max_length = CreateConVar("pac_sv_damage_zone_max_length", "20000", CLIENT and {FCVAR_REPLICATED} or {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "damage zone maximum length")
local damagezone_max_radius = CreateConVar("pac_sv_damage_zone_max_radius", "10000", CLIENT and {FCVAR_REPLICATED} or {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "damage zone maximum radius")
local damagezone_allow_dissolve = CreateConVar("pac_sv_damage_zone_allow_dissolve", "1", CLIENT and {FCVAR_REPLICATED} or {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Whether to enable entity dissolvers and removing NPCs\" weapons on death for damagezone")
local damagezone_allow_damageovertime = CreateConVar("pac_sv_damage_zone_allow_damage_over_time", "1", CLIENT and {FCVAR_REPLICATED} or {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Allow damage over time for damagezone")
local damagezone_max_damageovertime_total_time = CreateConVar("pac_sv_damage_zone_max_damage_over_time_total_time", "1", CLIENT and {FCVAR_REPLICATED} or {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "maximum time that a DoT instance is allowed to last in total.\nIf your tick time multiplied by the count is beyond that, it will compress the ticks, but if your total time is more than 200% of the limit, it will reject the attack")
local damagezone_allow_ragdoll_networking_for_hitpart = CreateConVar("pac_sv_damage_zone_allow_ragdoll_hitparts", "0", CLIENT and {FCVAR_REPLICATED} or {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Whether to send information about corpses to all clients when a player's damage zone needs it for attaching hitparts")

local lock_allow = CreateConVar("pac_sv_lock", master_default, CLIENT and {FCVAR_REPLICATED} or {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Allow lock parts serverside")
local lock_allow_grab = CreateConVar("pac_sv_lock_grab", 1, CLIENT and {FCVAR_REPLICATED} or {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Allow lock part grabs serverside")
local lock_allow_teleport = CreateConVar("pac_sv_lock_teleport", 1, CLIENT and {FCVAR_REPLICATED} or {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Allow lock part teleports serverside")
local lock_allow_aim = CreateConVar("pac_sv_lock_aim", 1, CLIENT and {FCVAR_REPLICATED} or {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Allow lock part aim serverside")
local lock_max_radius = CreateConVar("pac_sv_lock_max_grab_radius", "200", CLIENT and {FCVAR_REPLICATED} or {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "lock part maximum grab radius")
local lock_allow_grab_ply = CreateConVar("pac_sv_lock_allow_grab_ply", 1, CLIENT and {FCVAR_REPLICATED} or {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "allow grabbing players with lock part")
local lock_allow_grab_npc = CreateConVar("pac_sv_lock_allow_grab_npc", 1, CLIENT and {FCVAR_REPLICATED} or {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "allow grabbing NPCs with lock part")
local lock_allow_grab_ent = CreateConVar("pac_sv_lock_allow_grab_ent", 1, CLIENT and {FCVAR_REPLICATED} or {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "allow grabbing other entities with lock part")

local force_allow = CreateConVar("pac_sv_force", master_default, CLIENT and {FCVAR_REPLICATED} or {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Allow force parts serverside")
local force_max_length = CreateConVar("pac_sv_force_max_length", "10000", CLIENT and {FCVAR_REPLICATED} or {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "force part maximum length")
local force_max_radius = CreateConVar("pac_sv_force_max_radius", "10000", CLIENT and {FCVAR_REPLICATED} or {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "force part maximum radius")
local force_max_amount = CreateConVar("pac_sv_force_max_amount", "10000", CLIENT and {FCVAR_REPLICATED} or {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "force part maximum amount of force")

local healthmod_allow = CreateConVar("pac_sv_health_modifier", master_default, CLIENT and {FCVAR_REPLICATED} or {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Allow health modifier parts serverside")
local healthmod_allowed_extra_bars = CreateConVar("pac_sv_health_modifier_extra_bars", 1, CLIENT and {FCVAR_NOTIFY, FCVAR_REPLICATED} or {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Allow extra health bars")
local healthmod_allow_change_maxhp = CreateConVar("pac_sv_health_modifier_allow_maxhp", 1, CLIENT and {FCVAR_NOTIFY, FCVAR_REPLICATED} or {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Allow players to change their maximum health and armor.")
local healthmod_minimum_dmgscaling = CreateConVar("pac_sv_health_modifier_min_damagescaling", -1, CLIENT and {FCVAR_REPLICATED} or {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Minimum health modifier amount. Negative values can heal.")
local healthmod_allowed_counted_hits = CreateConVar("pac_sv_health_modifier_allow_counted_hits", 1, CLIENT and {FCVAR_NOTIFY, FCVAR_REPLICATED} or {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Allow extra health bars counted hits mode (one hit = 1 HP)")
local healthmod_max_value = CreateConVar("pac_sv_health_modifier_max_hp_armor", 1000000, CLIENT and {FCVAR_NOTIFY, FCVAR_REPLICATED} or {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "health modifier maximum value for health and armor")
local healthmod_max_extra_bars_value = CreateConVar("pac_sv_health_modifier_max_extra_bars_value", 1000000, CLIENT and {FCVAR_NOTIFY, FCVAR_REPLICATED} or {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "health modifier maximum value for extra health bars (bars x amount)")

local master_init_featureblocker = CreateConVar("pac_sv_block_combat_features_on_next_restart", 1, CLIENT and {FCVAR_REPLICATED} or {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Whether to stop initializing the net receivers for the networking of PAC3 combat parts those selectively disabled. This requires a restart!\n0=initialize all the receivers\n1=disable those whose corresponding part cvar is disabled\n2=block all combat features\nAfter updating the sv cvars, you can still reinitialize the net receivers with pac_sv_combat_reinitialize_missing_receivers, but you cannot turn them off after they are turned on")
cvars.AddChangeCallback("pac_sv_block_combat_features_on_next_restart", function() print("Remember that pac_sv_block_combat_features_on_next_restart is applied on server startup! Only do it if you know what you're doing. You'll need to restart the server.") end)

local debugging = CreateConVar("pac_sv_combat_debugging", 1, CLIENT and {FCVAR_REPLICATED} or {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Whether to get log prints for combat activity. If a player targets too many entities or sends messages too often, it will say it in the server console.")
local enforce_netrate = CreateConVar("pac_sv_combat_enforce_netrate", 0, CLIENT and {FCVAR_REPLICATED} or {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "whether to enforce a limit on how often any pac combat net messages can be sent. 0 to disable, otherwise a number in mililiseconds.\nSee the related cvar pac_sv_combat_enforce_netrate_buffersize. That second convar is governed by this one, if the netrate enforcement is 0, the allowance doesn\"t matter")
local netrate_allowance = CreateConVar("pac_sv_combat_enforce_netrate_buffersize", 60, CLIENT and {FCVAR_REPLICATED} or {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "the budgeted allowance to limit how many pac combat net messages can be sent in bursts. 0 to disable, otherwise a number of net messages of allowance.")
local netrate_enforcement_sv_monitoring = CreateConVar("pac_sv_combat_enforce_netrate_monitor_serverside", 0, {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Whether or not to let clients enforce their net message rates.\nSet this to 1 to get serverside prints telling you whenever someone is going over their allowance, but it'll still take the network bandwidth.\nSet this to 0 to let clients enforce their net rate and save some bandwidth but the server won't know who's spamming net messages.")
local raw_ent_limit = CreateConVar("pac_sv_entity_limit_per_combat_operation", 500, CLIENT and {FCVAR_REPLICATED} or {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Hard limit to drop any force or damage zone if more than this amount of entities is selected")
local per_ply_limit = CreateConVar("pac_sv_entity_limit_per_player_per_combat_operation", 40, CLIENT and {FCVAR_REPLICATED} or {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Limit per player to drop any force or damage zone if this amount multiplied by each client is more than the hard limit")
local player_fraction = CreateConVar("pac_sv_player_limit_as_fraction_to_drop_damage_zone", 1, CLIENT and {FCVAR_REPLICATED} or {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "The fraction (0.0-1.0) of players that will stop damage zone net messages if a damage zone order covers more than this fraction of the server's population, when there are more than 12 players covered")
local enforce_distance = CreateConVar("pac_sv_combat_distance_enforced", 0, CLIENT and {FCVAR_REPLICATED} or {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Whether to enforce a limit on how far a pac combat action can originate.\nIf set to a distance, it will prevent actions that are too far from the acting player.\n0 to disable.")
local ENFORCE_DISTANCE_SQR = math.pow(enforce_distance:GetInt(),2)
cvars.AddChangeCallback("pac_sv_combat_distance_enforced", function() ENFORCE_DISTANCE_SQR = math.pow(enforce_distance:GetInt(),2) end)


local global_combat_whitelisting = CreateConVar("pac_sv_combat_whitelisting", 0, CLIENT and {FCVAR_REPLICATED} or {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "How the server should decide which players are allowed to use the main PAC3 combat parts (lock, damagezone, force...).\n0:Everyone is allowed unless the parts are disabled serverwide\n1:No one is allowed until they get verified as trustworthy\tpac_sv_whitelist_combat <playername>\n\tpac_sv_blacklist_combat <playername>")
local global_combat_prop_protection = CreateConVar("pac_sv_prop_protection", 0, CLIENT and {FCVAR_REPLICATED} or {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Whether players owned (created) entities (physics props and gmod contraption entities) will be considered in the consent calculations, protecting them. Without this cvar, only the player is protected.")

do	--define a basic class for the bullet emitters
	local ENT = {}
	ENT.Type = "anim"
	ENT.ClassName = "pac_bullet_emitter"
	ENT.Spawnable = false
	scripted_ents.Register(ENT, "pac_bullet_emitter")
end

if SERVER then
	local damageable_point_ent_classes = {
		["predicted_viewmodel"] = false,
		["prop_physics"] = true,
		["weapon_striderbuster"] = true,
		["item_item_crate"] = true,
		["npc_satchel"] = true,
		["func_breakable_surf"] = true,
		["func_breakable"] = true,
		["func_physbox"] = true,
		["physics_cannister"] = true
	}

	local physics_point_ent_classes = {
		["prop_physics"] = true,
		["prop_physics_multiplayer"] = true,
		["prop_ragdoll"] = true,
		["weapon_striderbuster"] = true,
		["item_item_crate"] = true,
		["func_breakable_surf"] = true,
		["func_breakable"] = true,
		["physics_cannister"] = true,
		["pac_projectile"] = true,
	}

	local contraption_classes = {
		["prop_physics"] = true,
	}

	local pre_excluded_ent_classes = {
		["info_player_start"] = true,
		["aoc_spawnpoint"] = true,
		["info_player_teamspawn"] = true,
		["env_tonemap_controller"] = true,
		["env_fog_controller"] = true,
		["env_skypaint"] = true,
		["shadow_control"] = true,
		["env_sun"] = true,
		["predicted_viewmodel"] = true,
		["physgun_beam"] = true,
		["ambient_generic"] = true,
		["trigger_once"] = true,
		["trigger_multiple"] = true,
		["trigger_hurt"] = true,
		["info_ladder_dismount"] = true,
		["info_particle_system"] = true,
		["env_sprite"] = true,
		["env_fire"] = true,
		["env_soundscape"] = true,
		["env_smokestack"] = true,
		["light"] = true,
		["move_rope"] = true,
		["keyframe_rope"] = true,
		["env_soundscape_proxy"] = true,
		["gmod_hands"] = true,
		["env_lightglow"] = true,
		["point_spotlight"] = true,
		["spotlight_end"] = true,
		["beam"] = true,
		["info_target"] = true,
		["func_lod"] = true,

	}


	local grab_consents = {}
	local damage_zone_consents = {}
	local force_consents = {}
	local hitscan_consents = {}
	local calcview_consents = {}
	local active_force_ids = {}
	local active_grabbed_ents = {}
	local active_dots = {}


	local friendly_NPC_preferences = {}
	--we compare player's preference with the disposition's overall "friendliness". if relationship is more friendly than the preference, do not affect
	local disposition_friendliness_level = {
		[0] = 0,	--D_ER Error
		[1] = 0,	--D_HT Hate
		[2] = 1,	--D_FR Frightened / Fear
		[3] = 2,	--D_LI Like
		[4] = 1,	--D_NU Neutral
	}

	local function Is_NPC(ent)
		return ent:IsNPC() or ent:IsNextBot() or ent.IsDrGEntity or ent.IsVJBaseSNPC
	end

	local function NPCDispositionAllowsIt(ply, ent)

		if not Is_NPC(ent) or not ent.Disposition then return true end

		if not friendly_NPC_preferences[ply] then return true end

		local player_friendliness = friendly_NPC_preferences[ply]
		local relationship_friendliness = disposition_friendliness_level[ent:Disposition(ply)]

		if player_friendliness == 0 then --me agressive
			return true --hurt anyone
		elseif player_friendliness == 1 then --me not fully agressive
			return relationship_friendliness <= 1 --hurt who is neutral or hostile
		elseif player_friendliness == 2 then --me mostly friendly
			return relationship_friendliness == 0 --hurt who is hostile
		end

		return true
	end

	local function NPCDispositionIsFilteredOut(ply, ent, friendly, neutral, hostile)
		if not Is_NPC(ent) or not ent.Disposition then return false end
		local relationship_friendliness = disposition_friendliness_level[ent:Disposition(ply)]

		if relationship_friendliness == 0 then --it hostile
			return not hostile
		elseif relationship_friendliness == 1 then --it neutral
			return not neutral
		elseif relationship_friendliness == 2 then --it friendly
			return not friendly
		end
	end

	local damage_types = {
		generic = 0, --generic damage
		crush = 1, --caused by physics interaction
		bullet = 2, --bullet damage
		slash = 4, --sharp objects, such as manhacks or other npcs attacks
		burn = 8, --damage from fire
		vehicle = 16, --hit by a vehicle
		fall = 32, --fall damage
		blast = 64, --explosion damage
		club = 128, --crowbar damage
		shock = 256, --electrical damage, shows smoke at the damage position
		sonic = 512, --sonic damage,used by the gargantua and houndeye npcs
		energybeam = 1024, --laser
		nevergib = 4096, --don't create gibs
		alwaysgib = 8192, --always create gibs
		drown = 16384, --drown damage
		paralyze = 32768, --same as dmg_poison
		nervegas = 65536, --neurotoxin damage
		poison = 131072, --poison damage
		acid = 1048576, --
		airboat = 33554432, --airboat gun damage
		blast_surface = 134217728, --this won't hurt the player underwater
		buckshot = 536870912, --the pellets fired from a shotgun
		direct = 268435456, --
		dissolve = 67108864, --forces the entity to dissolve on death
		drownrecover = 524288, --damage applied to the player to restore health after drowning
		physgun = 8388608, --damage done by the gravity gun
		plasma = 16777216, --
		prevent_physics_force = 2048, --
		radiation = 262144, --radiation
		removenoragdoll = 4194304, --don't create a ragdoll on death
		slowburn = 2097152, --

		fire = -1, -- ent:Ignite(5)

		-- env_entity_dissolver
		dissolve_energy = 0,
		dissolve_heavy_electrical = 1,
		dissolve_light_electrical = 2,
		dissolve_core_effect = 3,

		heal = -1,
		armor = -1,
	}
	local special_damagetypes = {
		fire = true, -- ent:Ignite(5)
		-- env_entity_dissolver
		dissolve_energy = 0,
		dissolve_heavy_electrical = 1,
		dissolve_light_electrical = 2,
		dissolve_core_effect = 3,

		heal = true,
		armor = true,
	}

	local when_to_print_messages = {}
	local can_print = {}
	local function CountDebugMessage(ply)
		if CurTime() < when_to_print_messages[ply] then
			can_print[ply] = false
		else
			can_print[ply] = true
		end
		when_to_print_messages[ply] = CurTime() + 1
	end
	local function CountNetMessage(ply)
		if can_print[ply] == nil then can_print[ply] = true end
		when_to_print_messages[ply] = when_to_print_messages[ply] or 0

		local stime = SysTime()
		local ms_basis = enforce_netrate:GetInt()/1000
		local base_allowance = netrate_allowance:GetInt()

		ply.pac_netmessage_allowance = ply.pac_netmessage_allowance or base_allowance
		ply.pac_netmessage_allowance_time = ply.pac_netmessage_allowance_time or 0 --initialize fields

		local timedelta = stime - ply.pac_netmessage_allowance_time --in seconds
		ply.pac_netmessage_allowance_time = stime
		local regen_rate = math.Clamp(ms_basis,0.01,10) / 20 --delay (converted from milliseconds) -> frequency (1/seconds)
		local regens = timedelta / regen_rate
		--print(timedelta .. " s, " .. 1/regen_rate .. "/s, " .. regens .. " regens")
		if base_allowance == 0 then --limiting only by time, with no reserves
			return timedelta > ms_basis
		elseif ms_basis == 0 then --allowance with 0 time means ??? I guess automatic pass
			return true
		else
			if timedelta > ms_basis then --good, count up
				--print("good time: +"..regens .. "->" .. math.Clamp(ply.pac_netmessage_allowance + math.min(regens,base_allowance), -1, base_allowance))
				ply.pac_netmessage_allowance = math.Clamp(ply.pac_netmessage_allowance + math.min(regens,base_allowance), -1, base_allowance)
			else --earlier than base delay, so count down the allowance
				--print("bad time: -1")
				ply.pac_netmessage_allowance = ply.pac_netmessage_allowance - 1
			end
			ply.pac_netmessage_allowance = math.Clamp(ply.pac_netmessage_allowance,-1,base_allowance)
			ply.pac_netmessage_allowance_time = stime
			return ply.pac_netmessage_allowance ~= -1
		end

	end

	local function SetNoCPPIFallbackOwner(ent, ply)
		ent.pac_prop_protection_owner = ply
	end

	local function Try_CPPIGetOwner(ent)
		if ent.CPPIGetOwner then --a prop protection using CPPI probably exists so we use it
			return ent:CPPIGetOwner()
		end
		return ent.pac_prop_protection_owner or nil --otherwise we'll use the field we set or
	end

	--hack fix to stop GetOwner returning [NULL Entity]
	--uses CPPI interface from prop protectors if present
	hook.Add("PlayerSpawnedProp", "HackReAssignOwner", function(ply, model, ent)
		SetNoCPPIFallbackOwner(ent, ply)
	end)
	hook.Add("PlayerSpawnedNPC", "PAC_HackReAssignOwner", function(ply, ent)
		SetNoCPPIFallbackOwner(ent, ply)
	end)
	hook.Add("PlayerSpawnedRagdoll", "PAC_HackReAssignOwner", function(ply, model, ent)
		SetNoCPPIFallbackOwner(ent, ply)
	end)
	hook.Add("PlayerSpawnedSENT", "PAC_HackReAssignOwner", function(ply, ent)
		SetNoCPPIFallbackOwner(ent, ply)
	end)
	hook.Add("PlayerSpawnedSWEP", "PAC_HackReAssignOwner", function(ply, ent)
		SetNoCPPIFallbackOwner(ent, ply)
	end)
	hook.Add("PlayerSpawnedVehicle", "PAC_HackReAssignOwner", function(ply, ent)
		SetNoCPPIFallbackOwner(ent, ply)
	end)
	hook.Add("PlayerSpawnedEffect", "PAC_HackReAssignOwner", function(ply, model, ent)
		SetNoCPPIFallbackOwner(ent, ply)
	end)

	local function IsPossibleContraptionEntity(ent)
		if not IsValid(ent) then return false end
		local b = (string.find(ent:GetClass(), "phys") ~= nil
		or string.find(ent:GetClass(), "gmod") ~= nil
		or ent:IsConstraint())
		return b
	end

	local function IsPropProtected(ent, ply)
		local owner = Try_CPPIGetOwner(ent)

		local prop_protected
		if IsValid(owner) then --created entities should be fine
			prop_protected = owner:IsPlayer() and owner ~= ply
		else --players and world props could nil out
			prop_protected = false
		end

		local reason = ""
		local pac_sv_prop_protection = global_combat_prop_protection:GetBool()

		local contraption = IsPossibleContraptionEntity(ent) and ent:IsConstrained()

		if prop_protected and contraption then
			reason = "it's a contraption owned by another player"
			return true, reason
		end
		--apply prop protection
		if pac_sv_prop_protection and prop_protected then
			reason = "we enforce generic prop protection in the server"
			return true, reason
		end
		return false, "it's fine"
	end

	--whitelisting/blacklisting check
	local function PlayerIsCombatAllowed(ply)
		if pace.IsBanned(ply) then return false end
		if ulx and (ply.frozen or ply.jail) then return false end
		if pac.global_combat_whitelist[string.lower(ply:SteamID())] then
			if pac.global_combat_whitelist[string.lower(ply:SteamID())].permission == "Allowed" then return true end
			if pac.global_combat_whitelist[string.lower(ply:SteamID())].permission == "Banned" then return false end
		end

		if global_combat_whitelisting:GetBool() then --if server uses the high-trust whitelisting mode
			if pac.global_combat_whitelist[string.lower(ply:SteamID())] then
				if pac.global_combat_whitelist[string.lower(ply:SteamID())].permission ~= "Allowed" then return false end --if player is not in whitelist, stop!
			end
		else --if server uses the default, blacklisting mode
			if pac.global_combat_whitelist[string.lower(ply:SteamID())] then
				if pac.global_combat_whitelist[string.lower(ply:SteamID())].permission == "Banned" then return false end --if player is in blacklist, stop!
			end
		end

		return true
	end

	--stopping condition to stop force or damage operation if too many entities, because net impact is proportional to players
	local function TooManyEnts(count, ply)
		local playercount = player.GetCount()
		local hard_limit = raw_ent_limit:GetInt()
		local per_ply = per_ply_limit:GetInt()
		--print(count .. " compared against hard limit " .. hard_limit .. " and " .. playercount .. " players*" .. per_ply .. " limit (" .. count*playercount .. " | " .. playercount*per_ply .. ")")
		if count > hard_limit then
			if debugging:GetBool() and can_print[ply] then
				MsgC(Color(255,255,0), "[PAC3] : ") MsgC(Color(0,255,255), tostring(ply)) MsgC(Color(200,200,200), " TOO MANY ENTS (" .. count .. "). Beyond hard limit (".. hard_limit ..")\n")
			end
			return true
		end
		--if not game.SinglePlayer() then
			if count > per_ply_limit:GetInt() * playercount then
				if debugging:GetBool() and can_print[ply] then
					MsgC(Color(255,255,0), "[PAC3] : ") MsgC(Color(0,255,255), tostring(ply)) MsgC(Color(200,200,200), " TOO MANY ENTS (" .. count .. "). Beyond per-player sending limit (".. per_ply_limit:GetInt() .." per player)\n")
				end
				return true
			end
			if count * playercount > math.min(hard_limit, per_ply*playercount) then
				if debugging:GetBool() and can_print[ply] then
					MsgC(Color(255,255,0), "[PAC3] : ") MsgC(Color(0,255,255), tostring(ply)) MsgC(Color(200,200,200), " TOO MANY ENTS (" .. count .. "). Beyond hard limit or player limit (" .. math.min(hard_limit, per_ply*playercount) .. ")\n")
				end
				return true
			end
		--end
		return false
	end

	--consent check
	local function PlayerAllowsCalcView(ply)
		return grab_consents[ply] and calcview_consents[ply] --oops it's redundant but I prefer it this way
	end

	local function ApplyLockState(ent, bool, nocollide) --Change the movement states and reset some other angle-related things
		if ulx and (ent.frozen or ent.jail) then return end
		--the grab imposes MOVETYPE_NONE and no collisions
		--reverting the state requires to reset the eyeang roll in case it was modified
		if ent:IsPlayer() then
			if bool then --apply lock
				active_grabbed_ents[ent] = true
				if nocollide then
					ent:SetMoveType(MOVETYPE_NONE)
					ent:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
				else
					ent:SetMoveType(MOVETYPE_WALK)
					ent:SetCollisionGroup(COLLISION_GROUP_NONE)
				end
			else --revert
				active_grabbed_ents[ent] = nil
				if ent.default_movetype_reserved then
					ent:SetMoveType(ent.default_movetype)
					ent.default_movetype_reserved = nil
				end
				ent:SetCollisionGroup(COLLISION_GROUP_NONE)
				local eyeang = ent:EyeAngles()
				eyeang.r = 0
				ent:SetEyeAngles(eyeang)
				ent:SetPos(ent:GetPos() + Vector(0,0,10))
				net.Start("pac_lock_imposecalcview")
					net.WriteBool(false)
					net.WriteVector(Vector(0,0,0))
					net.WriteAngle(Angle(0,0,0))
					net.Send(ent)
					ent.has_calcview = false
			end

		elseif ent:IsNPC() then
			if bool then
				active_grabbed_ents[ent] = true
				if nocollide then
					ent:SetMoveType(MOVETYPE_NONE)
					ent:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
				else
					ent:SetMoveType(MOVETYPE_STEP)
					ent:SetCollisionGroup(COLLISION_GROUP_NONE)
				end
			else
				active_grabbed_ents[ent] = nil
				ent:SetMoveType(MOVETYPE_STEP)
				ent:SetCollisionGroup(COLLISION_GROUP_NONE)
				ent_ang = ent:GetAngles()
				ent_ang.r = 0
				ent:SetAngles(ent_ang)
			end
		end

		if bool == nil then
			for i,ply in pairs(player.GetAll()) do
				if ply.grabbed_ents[ent] then
					ply.grabbed_ents[ent] = nil
					print(ent , "no longer grabbed by", ply)
				end
			end
		elseif bool == false then
			ent.lock_state_applied = false
		end

		ent:PhysWake()
		ent:SetGravity(1)

	end

	local function maximized_ray_mins_maxs(startpos,endpos,padding)
		local maxsx,maxsy,maxsz
		local highest_sq_distance = 0
		for xsign = -1, 1, 2 do
			for ysign = -1, 1, 2 do
				for zsign = -1, 1, 2 do
					local distance_tried = (startpos + Vector(padding*xsign,padding*ysign,padding*zsign)):DistToSqr(endpos - Vector(padding*xsign,padding*ysign,padding*zsign))
					if distance_tried > highest_sq_distance then
						highest_sq_distance = distance_tried
						maxsx,maxsy,maxsz = xsign,ysign,zsign
					end
				end
			end
		end
		return Vector(padding*maxsx,padding*maxsy,padding*maxsz),Vector(padding*-maxsx,padding*-maxsy,padding*-maxsz)
	end

	local function AddDamageScale(ply, id,scale, part_uid)
		ply.pac_damage_scalings = ply.pac_damage_scalings or {}
		if id == "" then --no mod id = part uid mode, don't overwrite another part
			ply.pac_damage_scalings[part_uid] = {scale = scale, id = id, uid = part_uid}
		else --mod id = try to remove competing parts whose multipliers have the same mod id
			for existing_uid,tbl in pairs(ply.pac_damage_scalings) do
				if tbl.id == id then
					ply.pac_damage_scalings[existing_uid] = nil
				end
			end
			ply.pac_damage_scalings[part_uid] = {scale = scale, id = id, uid = part_uid}
		end
	end

	local function FixMaxHealths(ply)
		local biggest_health = 0
		local biggest_armor = 0
		local found_armor = false
		local found_health = false

		if ply.pac_healthmods then
			for uid,tbl in pairs(ply.pac_healthmods) do
				if tbl.maxhealth then biggest_health = math.max(biggest_health,tbl.maxhealth) found_health = true end
				if tbl.maxarmor then biggest_armor = math.max(biggest_armor,tbl.maxarmor) found_armor = true end
			end
		end

		if found_health then
			ply:SetMaxHealth(biggest_health)
		else
			ply:SetMaxHealth(100)
			ply:SetHealth(math.min(ply:Health(),100))
		end
		ply.pac_maxhealth = ply:GetMaxHealth()
		if found_armor then
			ply:SetMaxArmor(biggest_armor)
		else
			ply:SetMaxArmor(100)
			ply:SetArmor(math.min(ply:Armor(),100))
		end
		ply.pac_maxhealth = ply:GetMaxArmor()
	end

	hook.Add("PlayerSpawn", "PAC_AutoMaxHealth_On_Respawn", function(ply)
		FixMaxHealths(ply)
	end)

	local function GatherDamageScales(ent)
		if not ent then return 0 end
		if not ent:IsPlayer() then return 1 end
		if not ent.pac_damage_scalings then return 1 end
		local cumulative_dmg_scale = 1
		for uid, tbl in pairs(ent.pac_damage_scalings) do
			cumulative_dmg_scale = cumulative_dmg_scale * tbl.scale
		end
		return math.max(cumulative_dmg_scale,healthmod_minimum_dmgscaling:GetFloat())
	end

	--healthbars work with a 2 levels-deep table
		--for each player, an index table (priority) to decide which layer is damaged first
		--for each layer, one table for each part uid
		--for each uid, we have the current uid bar cluster's health value
		--instead of keeping track of every bar, it will update the status with a remainder calculation

		--ply.pac_healthbars
		--ply.pac_healthbars[layer]
		--ply.pac_healthbars[layer][part_uid] = healthvalue

	local function UpdateHealthBars(ply, num, barsize, layer, absorbfactor, part_uid, follow, counted_hits, no_overflow)
		local existing_uidlayer = true
		local healthvalue = 0
		if ply.pac_healthbars == nil then
			existing_uidlayer = false
			ply.pac_healthbars = {}
		end
		if ply.pac_healthbars[layer] == nil then
			existing_uidlayer = false
			ply.pac_healthbars[layer] = {}
		end
		if ply.pac_healthbars[layer][part_uid] == nil then
			existing_uidlayer = false
			ply.pac_healthbars[layer][part_uid] = num*barsize
			healthvalue = num*barsize
		end

		if (not existing_uidlayer) or follow then
			healthvalue = num*barsize
		end

		ply.pac_healtbar_uid_absorbfactor = ply.pac_healtbar_uid_absorbfactor or {}
		ply.pac_healtbar_uid_absorbfactor[part_uid] = absorbfactor

		ply.pac_healtbar_uid_info = ply.pac_healtbar_uid_info or {}
		ply.pac_healtbar_uid_info[part_uid] = {
			absorb_factor = absorbfactor,
			counted_hits = counted_hits,
			no_overflow = no_overflow
		}

		if num == 0 then --remove
			ply.pac_healthbars[layer] = nil
			ply.pac_healtbar_uid_info[part_uid].absorbfactor = nil
		elseif num > 0 then --add if follow or created
			if follow or not existing_uidlayer then
				ply.pac_healthbars[layer][part_uid] = healthvalue
				ply.pac_healtbar_uid_info[part_uid].absorbfactor = absorbfactor
			end
		end
		for checklayer,tbl in pairs(ply.pac_healthbars) do
			local layertotal = 0
			for uid,value in pairs(tbl) do
				layertotal = layertotal + value
				if layer ~= checklayer and part_uid == uid then
					ply.pac_healthbars[checklayer][uid] = nil
					if table.IsEmpty(ply.pac_healthbars[checklayer]) then ply.pac_healthbars[checklayer] = nil end
				end
			end
			if layertotal == 0 then ply.pac_healthbars[checklayer] = nil end
		end
	end

	local function UpdateHealthBarsFromCMD(ply, action, num, part_uid)
		if ply.pac_healthbars == nil then return end

		local target_tbl
		for checklayer,tbl in pairs(ply.pac_healthbars) do
			if tbl[part_uid] ~= nil then
				target_tbl = tbl
			end
		end

		if target_tbl == nil then return end

		--actions: set, add, subtract, replenish, remove
		if action == "set" then
			target_tbl[part_uid] = num
		elseif action == "add" then
			target_tbl[part_uid] = math.max(target_tbl[part_uid] + num,0)
		elseif action == "subtract" then
			target_tbl[part_uid] = math.max(target_tbl[part_uid] - num,0)
		elseif action == "remove" then
			target_tbl[part_uid] = nil
		end
	end

	local function GatherExtraHPBars(ply, filter)
		if ply.pac_healthbars == nil then return 0,nil end

		local built_tbl = {}
		local total_hp_value = 0

		for layer,tbl in pairs(ply.pac_healthbars) do
			built_tbl[layer] = {}
			local layer_total = 0
			for uid,value in pairs(tbl) do
				if uid == filter then continue end
				built_tbl[layer][uid] = value
				total_hp_value = total_hp_value + value
				layer_total = layer_total + value
			end
		end
		return total_hp_value,built_tbl

	end

	--simulate on a healthbar layers copy
	local function GetPredictedHPBarDamage(ply, dmg)
		local BARS_COPY = {}
		if ply.pac_healthbars then
			BARS_COPY = table.Copy(ply.pac_healthbars)
		else --this can happen with non-player ents
			return dmg,nil,nil
		end

		local remaining_dmg = dmg or 0
		local surviving_layer = 15
		local total_hp_value,built_tbl = GatherExtraHPBars(ply)
		local side_effect_dmg = 0

		if not built_tbl or total_hp_value == 0 then --no shields
			return dmg,nil,nil
		end

		for layer=15,0,-1 do --go progressively inward in the layers
			if BARS_COPY[layer] then
				surviving_layer = layer
				for uid,value in pairs(BARS_COPY[layer]) do --check the healthbars by uid

					if value > 0 then --skip 0 HP healthbars

						local remainder = math.max(0,remaining_dmg - BARS_COPY[layer][uid])

						local breakthrough_dmg = math.min(remaining_dmg, value)

						if remaining_dmg > value then --break through one of the uid clusters
							surviving_layer = layer - 1
							BARS_COPY[layer][uid] = 0
						else
							BARS_COPY[layer][uid] = math.max(0, value - remaining_dmg)
						end

						local absorbfactor = ply.pac_healtbar_uid_info[uid].absorbfactor
						side_effect_dmg = side_effect_dmg + breakthrough_dmg * absorbfactor

						remaining_dmg = math.max(0,remaining_dmg - value)
					end

				end
			end
		end
		return remaining_dmg,surviving_layer,side_effect_dmg
	end

	--do the calculation and reduce the player's underlying values
	local function GetHPBarDamage(ply, dmg)
		local remaining_dmg = dmg or 0
		local surviving_layer = 15
		local total_hp_value,built_tbl = GatherExtraHPBars(ply)
		local side_effect_dmg = 0

		if not built_tbl or total_hp_value == 0 then --no shields
			return dmg,nil,nil
		end

		for layer=15,0,-1 do --go progressively inward in the layers
			if ply.pac_healthbars[layer] then
				surviving_layer = layer
				for uid,value in pairs(ply.pac_healthbars[layer]) do --check the healthbars by uid

					if value > 0 then --skip 0 HP healthbars
						local counted_hits_mode = ply.pac_healtbar_uid_info[uid].counted_hits

						local absorbfactor = ply.pac_healtbar_uid_info[uid].absorbfactor
						local breakthrough_dmg

						if counted_hits_mode then
							ply.pac_healthbars[layer][uid] = ply.pac_healthbars[layer][uid] - 1
							breakthrough_dmg = remaining_dmg
							remaining_dmg = 0
						else
							--local remainder = math.max(0,remaining_dmg - ply.pac_healthbars[layer][uid])

							--if the dmg is more than health value, we will have a breakthrough damage
							breakthrough_dmg = math.min(remaining_dmg, value)

							if remaining_dmg > value then --break through one of the uid clusters
								surviving_layer = layer - 1
								ply.pac_healthbars[layer][uid] = 0
							else --subtracting the health now
								ply.pac_healthbars[layer][uid] = math.max(0, value - remaining_dmg)
							end
							if ply.pac_healtbar_uid_info[uid].no_overflow then
								remaining_dmg = 0
								breakthrough_dmg = 0
							else
								remaining_dmg = math.max(0,remaining_dmg - value)
							end
						end
						side_effect_dmg = side_effect_dmg + breakthrough_dmg * absorbfactor
					end

				end
			end
		end
		return remaining_dmg,surviving_layer,side_effect_dmg
	end

	local function SendUpdateHealthBars(target)
		if not target:IsPlayer() or not target.pac_healthbars then return end
		local table_copy = {}
		local layers = 0

		for layer=0,15,1 do --ok so we're gonna compress it
			if not target.pac_healthbars[layer] then continue end
			local tbl = target.pac_healthbars[layer]
			layers = layer
			table_copy[layer] = {}
			for uid, value in pairs(tbl) do
				table_copy[layer][string.sub(uid, 1, 8)] = math.Round(value)
			end
		end
		--PrintTable(table_copy)
		net.Start("pac_update_healthbars")
		net.WriteEntity(target)
		net.WriteUInt(layers, 4)
		for i=0,layers,1 do
			--PrintTable(table_copy)
			if not table_copy[i] then
				net.WriteBool(true)--skip
				continue
			elseif not table.IsEmpty(table_copy[i]) then
				net.WriteBool(false)--data exists
			end
			net.WriteUInt(math.Clamp(table.Count(table_copy[i]),0,15), 4)
			for uid, value in pairs(table_copy[i]) do
				net.WriteString(uid) --partial UID was written before
				net.WriteUInt(value,24)
			end
		end
		net.Broadcast()
	end

	--healthbars work with a 2 levels-deep table
		--for each player, an index table (priority) to decide which layer is damaged first
		--for each layer, one table for each part uid
		--for each uid, we have the current uid bar cluster's health value
		--instead of keeping track of every bar, it will update the status with a remainder calculation

		--ply.pac_healthbars
		--ply.pac_healthbars[layer]
		--ply.pac_healthbars[layer][part_uid] = healthvalue


	--apply hitscan consents, eat into extra healthbars first and calculate final damage multipliers from pac3
	hook.Add( "EntityTakeDamage", "ApplyPACDamageModifiers", function( target, dmginfo )
		if target:IsPlayer() then
			local cumulative_mult = GatherDamageScales(target)

			dmginfo:ScaleDamage(cumulative_mult)
			local pretotal_hp_value,prebuilt_tbl = GatherExtraHPBars(target)
			local remaining_dmg,surviving_layer,side_effect_dmg = GetHPBarDamage(target, dmginfo:GetDamage())

			if IsValid(dmginfo:GetInflictor()) then
				if dmginfo:GetInflictor():GetClass() == "pac_bullet_emitter" and hitscan_consents[target] == false then --unconsenting for pac hitscans = no damage, exit now
					return true
				end
			end

			local total_hp_value,built_tbl = GatherExtraHPBars(target)
			if surviving_layer == nil or (total_hp_value == 0 and pretotal_hp_value == total_hp_value) or not built_tbl then --no shields = use the dmginfo base damage scaled with the cumulative mult

				if cumulative_mult < 0 then
					target:SetHealth(math.floor(math.Clamp(target:Health() + math.abs(dmginfo:GetDamage()),0,target:GetMaxHealth())))
					return true
				else
					dmginfo:SetDamage(remaining_dmg)
					--if target.pac_healthbars then SendUpdateHealthBars(target) end
				end

			else --shields = use the calculated cumulative side effect damage from each uid's related absorbfactor

				if side_effect_dmg < 0 then
					target:SetHealth(math.floor(math.Clamp(target:Health() + math.abs(side_effect_dmg),0,target:GetMaxHealth())))
					SendUpdateHealthBars(target)
					return true
				else
					dmginfo:SetDamage(side_effect_dmg + remaining_dmg)
					SendUpdateHealthBars(target)
				end

			end
			
		end
	end)

	gameevent.Listen("entity_killed")
	hook.Add( "entity_killed", "entity_killed_example", function( data )
		local victim_index = data.entindex_killed		// Same as Victim:EntIndex() / the entity / player victim
		local ent = Entity(victim_index)
		if ent:IsValid() then
			if active_dots[ent] then
				for timer_entid,_ in pairs(active_dots[ent]) do
					timer.Remove(timer_entid)
				end
			end
		end
	end)

	local function MergeTargetsByID(tbl1, tbl2)
		for i,v in ipairs(tbl2) do
			tbl1[v:EntIndex()] = v
		end
	end

	local function ProcessDamagesList(ents_hits, dmg_info, tbl, pos, ang, ply)
		local base_damage = tbl.Damage
		local ent_count = 0
		local ply_count = 0
		local ply_prog_count = 0
		for i,v in pairs(ents_hits) do
			if not (v:IsPlayer() or Is_NPC(v)) and not tbl.PointEntities then ents_hits[i] = nil continue end
			if v.CPPICanDamage and not v:CPPICanDamage(ply) then ents_hits[i] = nil continue end --CPPI check on the player
			if v:IsConstraint() then  ents_hits[i] = nil continue end

			if not NPCDispositionAllowsIt(ply, v) then ents_hits[i] = nil continue end
			if NPCDispositionIsFilteredOut(ply,v, tbl.FilterFriendlies, tbl.FilterNeutrals, tbl.FilterHostiles) then ents_hits[i] = nil end

			if pre_excluded_ent_classes[v:GetClass()] or v:IsWeapon() or (v:IsNPC() and not tbl.NPC) or ((v ~= ply and v:IsPlayer() and not tbl.Players) and not (tbl.AffectSelf and v == ply)) then ents_hits[i] = nil continue
			else
				ent_count = ent_count + 1
				--print(v, "counted")
				if v:IsPlayer() then ply_count = ply_count + 1 end
			end
		end


		--dangerous conditions: absurd amounts of entities, damaging a large percentage of the server's players beyond a certain point
		if TooManyEnts(ent_count, ply) or ((ply_count) > 12 and (ply_count > player_fraction:GetFloat() * player.GetCount())) then
			return false,false,nil,{},{}
		end

		local pac_sv_damage_zone_allow_dissolve = GetConVar("pac_sv_damage_zone_allow_dissolve"):GetBool()
		local pac_sv_prop_protection = global_combat_prop_protection:GetBool()

		local inflictor = dmg_info:GetInflictor() or ply
		local attacker = dmg_info:GetAttacker() or ply

		local kill = false --whether a kill was done
		local hit = false --whether a hit was done
		local max_dmg = 0 --the max damage applied to targets. it should give the same damage by default, but I'm accounting for targets that can modify their damage
		local successful_hit_ents = {}
		local successful_kill_ents = {}

		local bullet = {}
		bullet.Src = pos + ang:Forward()
		bullet.Dir = ang:Forward()*50000
		bullet.Damage = -1
		bullet.Force = 0
		bullet.Entity = dmg_info:GetAttacker()

		--the function to determine if we can dissolve, based on policy and setting factors
		local function IsDissolvable(ent)
			local owner = Try_CPPIGetOwner(ent)

			local prop_protected_final
			if IsValid(owner) then --created entities should be fine
				prop_protected_final = prop_protected and owner:IsPlayer() and damage_zone_consents[owner] == false
			else --players and world props could nil out
				prop_protected_final = false
			end
			if not pac_sv_damage_zone_allow_dissolve then return false end
			local dissolvable = true
			local prop_protected, reason = IsPropProtected(ent, attacker)

			if ent:IsPlayer() then
				if not kill then dissolvable = false
				elseif damage_zone_consents[ent] == false then dissolvable = false end
			elseif inflictor == ent then
				dissolvable = false --do we allow that?
			end
			if ent:IsWeapon() and IsValid(owner) then
				dissolvable = false
			end
			if ent:CreatedByMap() then
				dissolvable = false
				if ent:GetClass() == "prop_physics" then dissolvable = true end
			end
			if damageable_point_ent_classes[ent:GetClass()] == false then
				dissolvable = false
			end
			if prop_protected_final then
				dissolvable = false
			end
			return dissolvable
		end

		local dissolver_entity = NULL
		local function dissolve(target, attacker, typ)
			local dissolver_ent = ents.Create("env_entity_dissolver")
			dissolver_ent:Spawn()
			target:SetName(tostring({}))
			dissolver_ent:SetKeyValue("dissolvetype", tostring(typ))
			dissolver_ent:Fire("Dissolve", target:GetName())
			timer.Simple(5, function() SafeRemoveEntity(dissolver_ent) end)
			dissolver_entity = dissolver_ent
		end

		--the giga function to determine if we can damage
		local function DMGAllowed(ent)
			if ent:Health() == 0 and not (string.find(tbl.DamageType, "dissolve")) then return false end --immediately exclude entities with 0 health, except if we want to dissolve


			local canhit = false --whether the policies allow the hit
			local prop_protected_consent
			local contraption = IsPossibleContraptionEntity(ent)
			local bot_exception = false
			if ent:IsPlayer() then
				if ent:IsBot() then bot_exception = true end
			end

			local owner = Try_CPPIGetOwner(ent)
			local target_ply
			if IsValid(owner) then --created entities should be fine
				target_ply = owner
				prop_protected_consent = owner ~= inflictor and ent ~= inflictor and owner:IsPlayer() and damage_zone_consents[owner] == false
			else --players and world props could nil out
				prop_protected_consent = false
				if ent:IsPlayer() then
					target_ply = ent
				end
			end

			--first pass: entity class blacklist

			if IsEntity(ent) and ((damageable_point_ent_classes[ent:GetClass()] ~= false) or ((damageable_point_ent_classes[ent:GetClass()] == nil) or (damageable_point_ent_classes[ent:GetClass()] == true))) then
				--second pass: the damagezone's settings
					--1.player hurt self if asked
				local is_player = ent:IsPlayer()
				local is_physics = (physics_point_ent_classes[ent:GetClass()] or string.find(ent:GetClass(),"item_") or string.find(ent:GetClass(),"ammo_"))
				local is_npc = Is_NPC(ent)

				if (tbl.AffectSelf) and ent == inflictor then
					canhit = true
					--2.main target types : players, NPC, point entities
				elseif		--one of the base classes
						(damageable_point_ent_classes[ent:GetClass()] ~= false) --non-blacklisted class
						and --enforce prop protection
						(bot_exception or (owner == inflictor or ent == inflictor or (pac_sv_prop_protection and damage_zone_consents[target_ply] ~= false) or not pac_sv_prop_protection))
						then

					if is_player then
						if tbl.Players then
							canhit = true
							--rules for players:
								--self can always hurt itself if asked to
							if (ent == inflictor and not tbl.AffectSelf) then
								canhit = false --self shouldn't hurt itself if asked not to
							elseif (damage_zone_consents[ent] == true) or ent:IsBot() then
								canhit = true --other players need to consent, bots don't care about it
								--other players that didn't consent are excluded
							else
								canhit = false
							end
						end
					elseif is_npc then
						if tbl.NPC then
							canhit = true
						end
					elseif tbl.PointEntities and (damageable_point_ent_classes[ent:GetClass()] == true) then
						canhit = true
					end

					--apply prop protection
					if (IsPropProtected(ent, inflictor) and IsValid(owner) and damage_zone_consents[target_ply]) or prop_protected_consent or (ent.CPPICanDamage and not ent:CPPICanDamage(ply)) then
						canhit = false
					end

				end

			end

			return canhit
		end

		local function IsLiving(ent) --players and NPCs
			return ent:IsPlayer() or Is_NPC(ent)
		end

		--final action to apply the DamageInfo
		local function DoDamage(ent)
			--add the max hp-scaled damage calculated with this entity's max health
			tbl.Damage = base_damage + tbl.MaxHpScaling * ent:GetMaxHealth()
			dmg_info:SetDamage(tbl.Damage)
			--we'll need to find out whether the damage will crack open a player's extra bars
			local de_facto_dmg = GetPredictedHPBarDamage(ent, tbl.Damage)

			local distance = (ent:GetPos()):Distance(pos)

			local fraction = math.pow(math.Clamp(1 - distance / math.Clamp(math.max(tbl.Radius, tbl.Length),1,50000),0,1),tbl.DamageFalloffPower)

			if tbl.DamageFalloff then
				dmg_info:SetDamage(fraction * tbl.Damage)
			end

			table.insert(successful_hit_ents,ent)
			--fire bullets if asked
			local ents2 = {inflictor}
			if tbl.Bullet then
				for _,v in ipairs(ents_hits) do
					if v ~= ent then table.insert(ents2,v) end
				end

				traceresult = util.TraceLine({filter = ents2, start = pos, endpos = pos + 50000*(ent:WorldSpaceCenter() - dmg_info:GetAttacker():WorldSpaceCenter())})

				bullet.Dir = traceresult.Normal
				bullet.Src = traceresult.HitPos + traceresult.HitNormal*5
				dmg_info:GetInflictor():FireBullets(bullet)

			end

			--this may benefit from some flattening treatment, lotta pyramids over here
			if tbl.DamageType == "heal" and ent.Health then
				if ent:Health() < ent:GetMaxHealth() then
					if tbl.ReverseDoNotKill then --don't heal if health is below critical
						if ent:Health() > tbl.CriticalHealth then --default behavior
							ent:SetHealth(math.min(ent:Health() + tbl.Damage, math.max(ent:Health(), ent:GetMaxHealth())))
						end --else do nothing
					else
						if tbl.DoNotKill then --stop healing at the critical health
							if ent:Health() < tbl.CriticalHealth then
								ent:SetHealth(math.min(ent:Health() + tbl.Damage, math.min(tbl.CriticalHealth, ent:GetMaxHealth())))
							end --else do nothing, we're already above critical
						else
							ent:SetHealth(math.min(ent:Health() + tbl.Damage, math.max(ent:Health(), ent:GetMaxHealth())))
						end
					end
				end
			elseif tbl.DamageType == "armor" and ent.Armor then
				if ent:Armor() < ent:GetMaxArmor() then
					if tbl.ReverseDoNotKill then --don't heal if armor is below critical
						if ent:Armor() > tbl.CriticalHealth then --default behavior
							ent:SetArmor(math.min(ent:Armor() + tbl.Damage, math.max(ent:Armor(), ent:GetMaxArmor())))
						end --else do nothing
					else
						if tbl.DoNotKill then --stop healing at the critical health
							if ent:Armor() < tbl.CriticalHealth then
								ent:SetArmor(math.min(ent:Armor() + tbl.Damage, math.min(tbl.CriticalHealth, ent:GetMaxArmor())))
							end --else do nothing, we're already above critical
						else
							ent:SetArmor(math.min(ent:Armor() + tbl.Damage, math.max(ent:Armor(), ent:GetMaxArmor())))
						end
					end
				end
			else
				--only "living" entities can be killed, and we checked generic entities with a ghost 0 health previously

				--now, after checking the de facto damage after extra healthbars, there's a 80% absorbtion ratio of armor.
				--so, the kill condition is either:
					--if damage is 500% of health (no amount will save you, because the remainder of 80% means death)
					--if damage is more than 125% of armor, and damage is more than health+armor
				if IsLiving(ent) and ent:Health() - de_facto_dmg <= 0 then
					if ent.Armor then

						if not (de_facto_dmg > 5*ent:Health()) and not (de_facto_dmg > 1.25*ent:Armor() and de_facto_dmg > ent:Health() + ent:Armor()) then
							kill = false
						else
							kill = true
						end
					else
						kill = true
					end

				end
				if tbl.DoNotKill then
					kill = false	--durr
				end
				if kill then
					table.insert(successful_kill_ents,ent)
					ent.pac_damagezone_need_send_ragdoll = true
					ent.pac_damagezone_killer = ply
				end

				--remove weapons on kill if asked
				if kill and not ent:IsPlayer() and tbl.RemoveNPCWeaponsOnKill and pac_sv_damage_zone_allow_dissolve then
					if ent:IsNPC() then
						if #ent:GetWeapons() >= 1 then
							for _,wep in pairs(ent:GetWeapons()) do
								SafeRemoveEntity(wep)
							end
						end
					end
				end

				if tbl.ReverseDoNotKill then
					--don't damage if health is above critical
					if ent:Health() < tbl.CriticalHealth then
						if string.find(tbl.DamageType, "dissolve") and IsDissolvable(ent) then
							dissolve(ent, dmg_info:GetInflictor(), damage_types[tbl.DamageType])
						end
						dmg_info:SetDamagePosition(ent:NearestPoint(pos))
						dmg_info:SetReportedPosition(pos)
						ent:TakeDamageInfo(dmg_info)
						max_dmg = math.max(max_dmg, dmg_info:GetDamage())
					end
				else
					--leave at a critical health
					if tbl.DoNotKill then
						local dmg_info2 = DamageInfo()

						dmg_info2:SetDamagePosition(ent:NearestPoint(pos))
						dmg_info2:SetReportedPosition(pos)
						dmg_info2:SetDamage( math.min(ent:Health() - tbl.CriticalHealth, tbl.Damage))
						dmg_info2:IsBulletDamage(tbl.Bullet)
						dmg_info2:SetDamageForce(Vector(0,0,0))

						if IsValid(attacker) then dmg_info2:SetAttacker(attacker) end

						if IsValid(inflictor) then dmg_info2:SetInflictor(inflictor) end

						ent:TakeDamageInfo(dmg_info2)
						max_dmg = math.max(max_dmg, dmg_info2:GetDamage())
					--finally we reached the normal damage event!
					else
						if string.find(tbl.DamageType, "dissolve") and IsDissolvable(ent) then
							dissolve(ent, dmg_info:GetInflictor(), damage_types[tbl.DamageType])
						end
						dmg_info:SetDamagePosition(ent:NearestPoint(pos))
						dmg_info:SetReportedPosition(pos)
						ent:TakeDamageInfo(dmg_info)
						max_dmg = math.max(max_dmg, dmg_info:GetDamage())
					end
				end
			end

			if tbl.DamageType == "fire" then ent:Ignite(5) end
		end

		--the forward bullet, if applicable and no entity is found
		if ent_count == 0 then
			if tbl.Bullet then
				dmg_info:GetInflictor():FireBullets(bullet)
			end
			return hit,kill,dmg,successful_hit_ents,successful_kill_ents
		end

		--look through each entity
		for _,ent in pairs(ents_hits) do
			local canhit = DMGAllowed(ent)
			local oldhp = ent:Health()
			if canhit then
				if ent:IsPlayer() and ply_count > 5 then
					--jank fix to delay players damage in case they die all at once overflowing the reliable buffer
					timer.Simple(ply_prog_count / 32, function() DoDamage(ent) end)
					ply_prog_count = ply_prog_count + 1
				else
					if tbl.DOTMode then
						active_dots[ent] = active_dots[ent] or {}
						local counts = tbl.NoInitialDOT and tbl.DOTCount or tbl.DOTCount-1
						local timer_entid = tbl.UniqueID .. "_" .. ent:GetClass() .. "_" .. ent:EntIndex()
						if counts <= 0 then --nuh uh, timer 0 means infinite repeat
							timer.Remove(timer_entid)
							active_dots[ent][timer_entid] = nil
						else
							if timer.Exists(timer_entid) then
								timer.Adjust(tbl.UniqueID, tbl.DOTTime, counts)
								active_dots[ent][timer_entid] = tbl
							else
								timer.Create(timer_entid, tbl.DOTTime, counts, function()
									if not IsValid(ent) then timer.Remove(timer_entid) return end
									DoDamage(ent)
								end)
								active_dots[ent][timer_entid] = tbl
							end
						end
						
					end
					if not tbl.NoInitialDOT then DoDamage(ent) end
				end
			end
			if not hit and (oldhp > 0 and canhit) then hit = true end
		end
		if IsValid(ent) then
			if kill then
				timer.Remove(tbl.UniqueID .. "_" .. ent:GetClass() .. "_" .. ent:EntIndex())
			end
			return
		end

		return hit,kill,dmg,successful_hit_ents,successful_kill_ents
	end


	local hitbox_ids = {
		["Box"] = 1,
		["Cube"] = 2,
		["Sphere"] = 3,
		["Cylinder"] = 4,
		["CylinderHybrid"] = 5,
		["CylinderSpheres"] = 6,
		["Cone"] = 7,
		["ConeHybrid"] = 8,
		["ConeSpheres"] = 9,
		["Ray"] = 10
	}

	local damage_ids = {
		generic = 0, --generic damage
		crush = 1, --caused by physics interaction
		bullet = 2, --bullet damage
		slash = 3, --sharp objects, such as manhacks or other npcs attacks
		burn = 4, --damage from fire
		vehicle = 5, --hit by a vehicle
		fall = 6, --fall damage
		blast = 7, --explosion damage
		club = 8, --crowbar damage
		shock = 9, --electrical damage, shows smoke at the damage position
		sonic = 10, --sonic damage,used by the gargantua and houndeye npcs
		energybeam = 11, --laser
		nevergib = 12, --don't create gibs
		alwaysgib = 13, --always create gibs
		drown = 14, --drown damage
		paralyze = 15, --same as dmg_poison
		nervegas = 16, --neurotoxin damage
		poison = 17, --poison damage
		acid = 18, --
		airboat = 19, --airboat gun damage
		blast_surface = 20, --this won't hurt the player underwater
		buckshot = 21, --the pellets fired from a shotgun
		direct = 22, --
		dissolve = 23, --forces the entity to dissolve on death
		drownrecover = 24, --damage applied to the player to restore health after drowning
		physgun = 25, --damage done by the gravity gun
		plasma = 26, --
		prevent_physics_force = 27, --
		radiation = 28, --radiation
		removenoragdoll = 29, --don't create a ragdoll on death
		slowburn = 30, --

		fire = 31, -- ent:Ignite(5)

		-- env_entity_dissolver
		dissolve_energy = 32,
		dissolve_heavy_electrical = 33,
		dissolve_light_electrical = 34,
		dissolve_core_effect = 35,

		heal = 36,
		armor = 37,
	}

	local tracer_ids = {
		["Tracer"] = 1,
		["AR2Tracer"] = 2,
		["HelicopterTracer"] = 3,
		["AirboatGunTracer"] = 4,
		["AirboatGunHeavyTracer"] = 5,
		["GaussTracer"] = 6,
		["HunterTracer"] = 7,
		["StriderTracer"] = 8,
		["GunshipTracer"] = 9,
		["ToolTracer"] = 10,
		["LaserTracer"] = 11
	}

	--second stage of force: apply
	local function ProcessForcesList(ents_hits, tbl, pos, ang, ply)
		local ent_count = 0
		for i,v in pairs(ents_hits) do
			if v.CPPICanPickup and not v:CPPICanPickup(ply) then ents_hits[i] = nil end
			if v.CPPICanPunt and not v:CPPICanPunt(ply) then ents_hits[i] = nil end
			if v:IsConstraint() then ents_hits[i] = nil end

			if v == ply then
				if not tbl.AffectPlayerOwner then ents_hits[i] = nil end
			elseif v == tbl.RootPartOwner then
				if (not tbl.AffectSelf) and v == tbl.RootPartOwner then ents_hits[i] = nil end
			end

			if pre_excluded_ent_classes[v:GetClass()] or (Is_NPC(v) and not tbl.NPC) or (v:IsPlayer() and not tbl.Players and not (v == ply and tbl.AffectPlayerOwner)) then ents_hits[i] = nil
			end
			if ents_hits[i] ~= nil then
				ent_count = ent_count + 1
			end
		end
		if TooManyEnts(ent_count, ply) and not ((tbl.AffectSelf or tbl.AffectPlayerOwner) and not tbl.Players and not tbl.NPC and not tbl.PhysicsProps and not tbl.PointEntities) then return end
		for _,ent in pairs(ents_hits) do
			local phys_ent
			local ent_getphysobj = ent:GetPhysicsObject()
			local owner = Try_CPPIGetOwner(ent)
			local is_player = ent:IsPlayer()
			local is_physics = (physics_point_ent_classes[ent:GetClass()] or string.find(ent:GetClass(),"item_") or string.find(ent:GetClass(),"ammo_") or (ent:IsWeapon() and not IsValid(ent:GetOwner())))
			local is_npc = Is_NPC(ent)
			if (ent ~= tbl.RootPartOwner or (tbl.AffectSelf and ent == tbl.RootPartOwner) or (tbl.AffectPlayerOwner and ent == ply))
					and (
						is_player
						or is_npc
						or is_physics
						or IsValid( ent_getphysobj )
					) then
				
				local is_phys = true
				if ent_getphysobj ~= nil then
					phys_ent = ent_getphysobj
					if is_npc then
						phys_ent = ent
					end
				else
					phys_ent = ent
					is_phys = false
				end

				local oldvel

				if IsValid(phys_ent) then
					oldvel = phys_ent:GetVelocity()
				else
					oldvel = Vector(0,0,0)
				end


				local addvel = Vector(0,0,0)
				local add_angvel = Vector(0,0,0)

				local ent_center = ent:WorldSpaceCenter() or ent:GetPos()

				local dir = ent_center - pos --part
				local dir2 = ent_center - tbl.Locus_pos--locus

				local dist_multiplier = 1
				local damping_dist_mult = 1
				local up_mult = 1
				local distance = (ent_center - pos):Length()
				local height_delta = pos.z + tbl.LevitationHeight - ent_center.z

				--what it do
				--if delta is -100 (ent is lower than the desired height), that means +100 adjustment direction
				--height decides how much to knee the force until it equalizes at 0
				--clamp the delta to the ratio levitation height

				if tbl.Levitation then
					up_mult = math.Clamp(height_delta / (5 + math.abs(tbl.LevitationHeight)),-1,1)
				end

				if tbl.BaseForceAngleMode == "Radial" then --radial on self
					addvel = dir:GetNormalized() * tbl.BaseForce
				elseif tbl.BaseForceAngleMode == "Locus" then --radial on locus
					addvel = dir2:GetNormalized() * tbl.BaseForce
				elseif tbl.BaseForceAngleMode == "Local" then --forward on self
					addvel = ang:Forward() * tbl.BaseForce
				end

				if tbl.VectorForceAngleMode == "Global" then --global
					addvel = addvel + tbl.AddedVectorForce
				elseif tbl.VectorForceAngleMode == "Local" then --local on self
					addvel = addvel
					+ang:Forward()*tbl.AddedVectorForce.x
					+ang:Right()*tbl.AddedVectorForce.y
					+ang:Up()*tbl.AddedVectorForce.z

				elseif tbl.VectorForceAngleMode == "Radial" then --relative to locus or self
					ang2 = dir:Angle()
					addvel = addvel
					+ang2:Forward()*tbl.AddedVectorForce.x
					+ang2:Right()*tbl.AddedVectorForce.y
					+ang2:Up()*tbl.AddedVectorForce.z
				elseif tbl.VectorForceAngleMode == "RadialNoPitch" then --relative to locus or self
					dir.z = 0
					ang2 = dir:Angle()
					addvel = addvel
					+ang2:Forward()*tbl.AddedVectorForce.x
					+ang2:Right()*tbl.AddedVectorForce.y
					+ang2:Up()*tbl.AddedVectorForce.z
				end

				if tbl.TorqueMode == "Global" then
					add_angvel = tbl.Torque
				elseif tbl.TorqueMode == "Local" then
					add_angvel = ang:Forward()*tbl.Torque.x + ang:Right()*tbl.Torque.y + ang:Up()*tbl.Torque.z
				elseif tbl.TorqueMode == "TargetLocal" then
					add_angvel = tbl.Torque
				elseif tbl.TorqueMode == "Radial" then
					ang2 = dir:Angle()
					addvel = ang2:Forward()*tbl.Torque.x + ang2:Right()*tbl.Torque.y + ang2:Up()*tbl.Torque.z
				end

				local islocaltorque = tbl.TorqueMode == "TargetLocal"

				local mass = 1
				if IsValid(phys_ent) then
					if phys_ent.GetMass then
						phys_ent:GetMass()
					end
				end
				if is_phys and tbl.AccountMass then
					if not is_npc then
						addvel = addvel * (1 / math.max(mass,0.1))
					else
						addvel = addvel
					end
					add_angvel = add_angvel * (1 / math.max(mass,0.1))
				end

				if tbl.Falloff then
					dist_multiplier = math.Clamp(1 - distance / math.max(tbl.Radius, tbl.Length),0,1)
				end
				if tbl.ReverseFalloff then
					dist_multiplier = 1 - math.Clamp(1 - distance / math.max(tbl.Radius, tbl.Length),0,1)
				end

				if tbl.DampingFalloff then
					damping_dist_mult = math.Clamp(1 - distance / math.max(tbl.Radius, tbl.Length),0,1)
				end
				if tbl.DampingReverseFalloff then
					damping_dist_mult = 1 - math.Clamp(1 - distance / math.max(tbl.Radius, tbl.Length),0,1)
				end
				damping_dist_mult = damping_dist_mult
				local final_damping = 1 - (tbl.Damping * damping_dist_mult)

				if tbl.Levitation then
					addvel.z = addvel.z * up_mult
				end

				addvel = addvel * dist_multiplier
				add_angvel = add_angvel * dist_multiplier

				local unconsenting_owner = owner ~= ply and force_consents[owner] == false

				if is_player then
					if  tbl.Players or (ent == ply and tbl.AffectPlayerOwner) then
						if (ent ~= ply and force_consents[ent] ~= false) or (ent == ply and tbl.AffectPlayerOwner) then
							oldvel = ent:GetVelocity()
							phys_ent:SetVelocity(oldvel * (-1 + final_damping) + addvel)
							ent:SetVelocity(oldvel * (-1 + final_damping) + addvel)
						end
					end
				elseif is_physics then
					if tbl.PhysicsProps then
						if not (IsPropProtected(ent, ply) and global_combat_prop_protection:GetBool()) or not unconsenting_owner then
							if IsValid(phys_ent) then
								ent:PhysWake()
								ent:SetVelocity(final_damping * oldvel + addvel)
								if islocaltorque then
									phys_ent:SetAngleVelocity(final_damping * phys_ent:GetAngleVelocity())
									phys_ent:AddAngleVelocity(add_angvel)

								else
									phys_ent:SetAngleVelocity(final_damping * phys_ent:GetAngleVelocity())
									add_angvel = phys_ent:WorldToLocalVector( add_angvel )
									phys_ent:ApplyTorqueCenter(add_angvel)
								end
								ent:SetPos(ent:GetPos() + Vector(0,0,0.0001)) --dumb workaround to fight against the ground friction reversing the forces
								phys_ent:SetVelocity((oldvel * final_damping) + addvel)
							end
						end
					end

				elseif is_npc then
					if tbl.NPC then
						if not (IsPropProtected(ent, ply) and global_combat_prop_protection:GetBool()) or not unconsenting_owner then
							if ent.IsDrGEntity then --welcome to episode 40 of intercompatibility hackery
								phys_ent = ent.loco
								local jumpHeight = ent.loco:GetJumpHeight()
								ent.loco:SetJumpHeight(1)
								ent.loco:Jump()
								ent.loco:SetJumpHeight(jumpHeight)
							end
							if IsValid(phys_ent) and phys_ent:GetVelocity():Length() > 500 then
								local vec = oldvel + addvel
								local clamp_vec = vec:GetNormalized()*500
								ent:SetVelocity(Vector(0.7 * clamp_vec.x,0.7 * clamp_vec.y,clamp_vec.z)*math.Clamp(1.5*(pos - ent_center):Length()/tbl.Radius,0,1)) --more jank, this one is to prevent some of the weird sliding of npcs by lowering the force as we get closer
							else
								ent:SetVelocity((oldvel * final_damping) + addvel)
							end
						end
					end

				elseif tbl.PointEntities or (tbl.AffectSelf and ent == tbl.RootPartOwner) then
					if not (IsPropProtected(ent, ply) and global_combat_prop_protection:GetBool()) or not unconsenting_owner then
						phys_ent:SetVelocity(final_damping * oldvel + addvel)
					end
				end
				hook.Run("PhysicsUpdate", ent)
				hook.Run("PhysicsUpdate", phys_ent)
			end

		end
	end
	--first stage of force: look for targets and determine force amount if continuous
	local function ImpulseForce(tbl, pos, ang, ply)
		local ftime = 0.016 --approximate tick duration
		if tbl.Continuous then
			tbl.BaseForce = tbl.BaseForce1 * ftime * 3.3333 --weird value to equalize how 600 cancels out gravity
			tbl.AddedVectorForce = tbl.AddedVectorForce1 * ftime * 3.3333
			tbl.Torque = tbl.Torque1 * ftime * 3.3333
		else
			tbl.BaseForce = tbl.BaseForce1
			tbl.AddedVectorForce = tbl.AddedVectorForce1
			tbl.Torque = tbl.Torque1
		end

		if tbl.HitboxMode == "Sphere" then
			local ents_hits = ents.FindInSphere(pos, tbl.Radius)
			ProcessForcesList(ents_hits, tbl, pos, ang, ply)
		elseif tbl.HitboxMode == "Box" then
			local mins
			local maxs
			if tbl.HitboxMode == "Box" then
				mins = pos - Vector(tbl.Radius, tbl.Radius, tbl.Length)
				maxs = pos + Vector(tbl.Radius, tbl.Radius, tbl.Length)
			end

			local ents_hits = ents.FindInBox(mins, maxs)
			ProcessForcesList(ents_hits, tbl, pos, ang, ply)
		elseif tbl.HitboxMode == "Cylinder" then
			local ents_hits = {}
			if tbl.Length ~= 0 and tbl.Radius ~= 0 then
				local counter = 0
				MergeTargetsByID(ents_hits,ents.FindInSphere(pos, tbl.Radius))
				for i=0,1,1/(math.abs(tbl.Length/tbl.Radius)) do
					MergeTargetsByID(ents_hits,ents.FindInSphere(pos + ang:Forward()*tbl.Length*i, tbl.Radius))
					if counter == 200 then break end
					counter = counter + 1
				end
				MergeTargetsByID(ents_hits,ents.FindInSphere(pos + ang:Forward()*tbl.Length, tbl.Radius))
				--render.DrawWireframeSphere( self:GetWorldPosition() + self:GetWorldAngles():Forward()*(self.Length - 0.5*self.Radius), 0.5*self.Radius, 10, 10, Color( 255, 255, 255 ) )
			elseif tbl.Radius == 0 then MergeTargetsByID(ents_hits,ents.FindAlongRay(pos, pos + ang:Forward()*tbl.Length)) end
			ProcessForcesList(ents_hits, tbl, pos, ang, ply)
		elseif tbl.HitboxMode == "Cone" then
			local ents_hits = {}
			local steps
			steps = math.Clamp(4*math.ceil(tbl.Length / (tbl.Radius or 1)),1,50)
			for i = 1,0,-1/steps do
				MergeTargetsByID(ents_hits,ents.FindInSphere(pos + ang:Forward()*tbl.Length*i, i * tbl.Radius))
			end

			steps = math.Clamp(math.ceil(tbl.Length / (tbl.Radius or 1)),1,4)

			if tbl.Radius == 0 then MergeTargetsByID(ents_hits,ents.FindAlongRay(pos, pos + ang:Forward()*tbl.Length)) end
			ProcessForcesList(ents_hits, tbl, pos, ang, ply)
		elseif tbl.HitboxMode =="Ray" then
			local startpos = pos + Vector(0,0,0)
			local endpos = pos + ang:Forward()*tbl.Length
			ents_hits = ents.FindAlongRay(startpos, endpos)
			ProcessForcesList(ents_hits, tbl, pos, ang, ply)
		end
	end


	--consent message from clients
	net.Receive("pac_signal_player_combat_consent", function(len,ply)
		local friendly_NPC_preference = net.ReadUInt(2) -- GetConVar("pac_client_npc_exclusion_consent"):GetInt()
		local grab = net.ReadBool() -- GetConVar("pac_client_grab_consent"):GetBool()
		local damagezone = net.ReadBool() -- GetConVar("pac_client_damage_zone_consent"):GetBool()
		local calcview = net.ReadBool() -- GetConVar("pac_client_lock_camera_consent"):GetBool()
		local force = net.ReadBool() -- GetConVar("pac_client_force_consent"):GetBool()
		local hitscan = net.ReadBool() -- GetConVar("pac_client_hitscan_consent"):GetBool()
		friendly_NPC_preferences[ply] = friendly_NPC_preference
		grab_consents[ply] = grab
		damage_zone_consents[ply] = damagezone
		calcview_consents[ply] = calcview
		force_consents[ply] = force
		hitscan_consents[ply] = hitscan
	end)

	--lock break order from client
	net.Receive("pac_signal_stop_lock", function(len,ply)
		if not pac.RatelimitPlayer( ply, "pac_signal_stop_lock", 3, 5, {"Player ", ply, " is spamming pac_signal_stop_lock!"} ) then
			return
		end
		ApplyLockState(ply, false)
		if ply.default_movetype and ply.lock_state_applied and not (ulx and (ply.frozen or ply.jail)) then
			ply:SetMoveType(ply.default_movetype)
			targ_ent.default_movetype_reserved = nil
		end
		if debugging:GetBool() and can_print[ply] then MsgC(Color(0,255,255), "Requesting lock break!\n") end

		if ply.grabbed_by then --directly go for the grabbed_by player
			net.Start("pac_request_lock_break")
			net.WriteEntity(ply)
			net.WriteString("")
			net.Send(ply.grabbed_by)
		end
		--What if there's more? try to find it AMONG US SUS!
		for _,ent in pairs(player.GetAll()) do
			if ent.grabbed_ents and ent ~= ply.grabbed_by then --a player! time to inspect! but skip the already found grabber
				for _,grabbed in pairs(ent.grabbed_ents) do --check all her entities
					if ply == grabbed then --that's us!
						net.Start("pac_request_lock_break")
						net.WriteEntity(ply)
						net.WriteString(ply.grabbed_by_uid)
						net.Send(ent)
					end
				end
			end
		end
	end)

	concommand.Add("pac_damage_zone_whitelist_entity_class", function(ply, cmd, args, argStr)
		if IsValid(ply) then
			if not ply:IsAdmin() or not pac.RatelimitPlayer( ply, "pac_damage_zone_whitelist_entity_class", 3, 5, {"Player ", ply, " is spamming pac_damage_zone_whitelist_entity_class!"} ) then
				return
			end
		end
		for _,v in pairs(string.Explode(";",argStr)) do
			if v ~= "" then
				damageable_point_ent_classes[v] = true
				print("added " .. v .. " to the entities you can damage")
			end
		end
		PrintTable(damageable_point_ent_classes)
	end)

	concommand.Add("pac_damage_zone_blacklist_entity_class", function(ply, cmd, args, argStr)
		if IsValid(ply) then
			if not ply:IsAdmin() or not pac.RatelimitPlayer( ply, "pac_damage_zone_blacklist_entity_class", 3, 5, {"Player ", ply, " is spamming pac_damage_zone_blacklist_entity_class!"} ) then
				return
			end
		end
		for _,v in pairs(string.Explode(";",argStr)) do
			if v ~= "" then
				damageable_point_ent_classes[v] = false
				print("removed " .. v .. " from the entities you can damage")
			end
		end
		PrintTable(damageable_point_ent_classes)
	end)


	util.AddNetworkString("pac_signal_player_combat_consent")
	util.AddNetworkString("pac_request_blocked_parts")
	util.AddNetworkString("pac_inform_blocked_parts")

	local FINAL_BLOCKED_COMBAT_FEATURES = {
		hitscan = false,
		damage_zone = false,
		lock = false,
		force = false,
		health_modifier = false,
	}


	--[[function net.Incoming( len, client )

		local i = net.ReadHeader()
		local strName = util.NetworkIDToString( i )
		if strName ~= "pac_in_editor_posang" and strName ~= "DrGBasePlayerLuminosity" then
			print(strName, client, "message with " .. len .." bits")
		end

		if ( !strName ) then return end

		local func = net.Receivers[ strName:lower() ]
		if ( !func ) then return end

		--
		-- len includes the 16 bit int which told us the message name
		--
		len = len - 16

		func( len, client )

	end]]

	local force_hitbox_ids = {["Box"] = 0,["Cube"] = 1,["Sphere"] = 2,["Cylinder"] = 3,["Cone"] = 4,["Ray"] = 5}
	local base_force_mode_ids = {["Radial"] = 0, ["Locus"] = 1, ["Local"] = 2}
	local vect_force_mode_ids = {["Global"] = 0, ["Local"] = 1, ["Radial"] = 2,  ["RadialNoPitch"] = 3}
	local ang_torque_mode_ids = {["Global"] = 0, ["TargetLocal"] = 1, ["Local"] = 2, ["Radial"] = 3}
	local nextcheckforce = SysTime()

	local function DeclareForceReceivers()
		util.AddNetworkString("pac_request_force")
		--the force part impulse request net message
		net.Receive("pac_request_force", function(len,ply)
			--server allow
			if not force_allow:GetBool() then return end
			if not PlayerIsCombatAllowed(ply) then return end


			local tbl = {}
			local pos = net.ReadVector()
			if ply:GetPos():DistToSqr(pos) > ENFORCE_DISTANCE_SQR and ENFORCE_DISTANCE_SQR > 0 then return end
			local ang = net.ReadAngle()
			tbl.Locus_pos = net.ReadVector()
			local on = net.ReadBool()

			tbl.UniqueID = net.ReadString()

			if not CountNetMessage(ply) then
				if debugging:GetBool() and can_print[ply] then MsgC(Color(255,255,0), "[PAC3] Force part: ") MsgC(Color(0,255,255), tostring(ply)) MsgC(Color(200,200,200), " combat actions are too many or too fast! (spam warning)\n") end
				hook.Remove("Tick", "pac_force_hold"..tbl.UniqueID)
				active_force_ids[tbl.UniqueID] = nil
				CountDebugMessage(ply)
				return
			end

			tbl.RootPartOwner = net.ReadEntity()

			tbl.HitboxMode = table.KeyFromValue(force_hitbox_ids, net.ReadUInt(4))
			tbl.BaseForceAngleMode = table.KeyFromValue(base_force_mode_ids, net.ReadUInt(3))
			tbl.VectorForceAngleMode = table.KeyFromValue(vect_force_mode_ids, net.ReadUInt(2))
			tbl.TorqueMode = table.KeyFromValue(ang_torque_mode_ids, net.ReadUInt(2))

			tbl.Length = net.ReadInt(16)
			tbl.Radius = net.ReadInt(16)

			tbl.BaseForce1 = net.ReadInt(18)
			tbl.AddedVectorForce1 = net.ReadVector()
			tbl.Torque1 = net.ReadVector()

			tbl.Damping = net.ReadUInt(10)/1000
			tbl.LevitationHeight = net.ReadInt(14)

			tbl.Continuous = net.ReadBool()
			tbl.AccountMass = net.ReadBool()
			tbl.Falloff = net.ReadBool()
			tbl.ReverseFalloff = net.ReadBool()
			tbl.DampingFalloff = net.ReadBool()
			tbl.DampingReverseFalloff = net.ReadBool()
			tbl.Levitation = net.ReadBool()
			tbl.AffectSelf = net.ReadBool()
			tbl.AffectPlayerOwner = net.ReadBool()
			tbl.Players = net.ReadBool()
			tbl.PhysicsProps = net.ReadBool()
			tbl.PointEntities = net.ReadBool()
			tbl.NPC = net.ReadBool()

			--server limits
			tbl.Radius = math.Clamp(tbl.Radius,-force_max_radius:GetInt(),force_max_radius:GetInt())
			tbl.Length = math.Clamp(tbl.Length,-force_max_length:GetInt(),force_max_length:GetInt())
			tbl.BaseForce = math.Clamp(tbl.BaseForce1,-force_max_amount:GetInt(),force_max_amount:GetInt())
			tbl.AddedVectorForce1.x = math.Clamp(tbl.AddedVectorForce1.x,-force_max_amount:GetInt(),force_max_amount:GetInt())
			tbl.AddedVectorForce1.y = math.Clamp(tbl.AddedVectorForce1.y,-force_max_amount:GetInt(),force_max_amount:GetInt())
			tbl.AddedVectorForce1.z = math.Clamp(tbl.AddedVectorForce1.z,-force_max_amount:GetInt(),force_max_amount:GetInt())
			tbl.Torque1.x = math.Clamp(tbl.Torque1.x,-force_max_amount:GetInt(),force_max_amount:GetInt())
			tbl.Torque1.y = math.Clamp(tbl.Torque1.y,-force_max_amount:GetInt(),force_max_amount:GetInt())
			tbl.Torque1.z = math.Clamp(tbl.Torque1.z,-force_max_amount:GetInt(),force_max_amount:GetInt())

			if on then
				if tbl.Continuous then
					hook.Add("Tick", "pac_force_hold"..tbl.UniqueID, function()
						ImpulseForce(tbl, pos, ang, ply)
					end)

					active_force_ids[tbl.UniqueID] = CurTime()
				else
					active_force_ids[tbl.UniqueID] = nil
				end
				ImpulseForce(tbl, pos, ang, ply)
			else
				hook.Remove("Tick", "pac_force_hold"..tbl.UniqueID)
				active_force_ids[tbl.UniqueID] = nil
			end

			--check bad or inactive hooks
			for i,v in pairs(active_force_ids) do
				if not v then
					hook.Remove("Tick", "pac_force_hold"..i)
					--print("invalid force")
				elseif v + 0.1 < CurTime() then
					hook.Remove("Tick", "pac_force_hold"..i)
					--print("outdated force")
				end
			end

		end)

		hook.Add("Tick", "pac_check_force_hooks", function()
			if nextcheckforce > SysTime() then return else nextcheckforce = SysTime() + 0.2 end
			for i,v in pairs(active_force_ids) do
				if not v then
					hook.Remove("Tick", "pac_force_hold"..i)
					--print("removed an invalid force")
				elseif v + 0.1 < CurTime() then
					hook.Remove("Tick", "pac_force_hold"..i)
					--print("removed an outdated force")
				end
			end

		end)
	end
	
	local active_DoT = {}
	local requesting_corpses = {}

	local function DeclareDamageZoneReceivers()
		--networking for damagezone hitparts on corpses
		hook.Add("CreateEntityRagdoll", "pac_ragdoll_assign", function(ent, rag)
			if not ent.pac_damagezone_need_send_ragdoll then return end
			if not ent.pac_damagezone_killer then return end
			if not damagezone_allow:GetBool() then return end
			if not damagezone_allow_ragdoll_networking_for_hitpart:GetBool() then return end
			if not PlayerIsCombatAllowed(ent.pac_damagezone_killer) then return end
			if not requesting_corpses[ent.pac_damagezone_killer] then return end
			net.Start("pac_send_ragdoll")
			net.WriteUInt(ent:EntIndex(), 12)
			net.WriteEntity(rag)
			net.Broadcast()
		end)

		net.Receive("pac_request_ragdoll_sends", function(len, ply)
			local b = net.ReadBool()
			if not damagezone_allow:GetBool() then return end
			if not PlayerIsCombatAllowed(ply) then return end
			requesting_corpses[ply] = b
		end)

		util.AddNetworkString("pac_request_zone_damage")
		util.AddNetworkString("pac_hit_results")
		util.AddNetworkString("pac_request_ragdoll_sends")
		util.AddNetworkString("pac_send_ragdoll")
		net.Receive("pac_request_zone_damage", function(len,ply)
			--server allow
			if not damagezone_allow:GetBool() then return end
			if not PlayerIsCombatAllowed(ply) then return end

			--netrate enforce
			if not CountNetMessage(ply) then
				if debugging:GetBool() and can_print[ply] then
					MsgC(Color(255,255,0), "[PAC3] Damage zone: ") MsgC(Color(0,255,255), tostring(ply)) MsgC(Color(200,200,200), " combat actions are too many or too fast! (spam warning)\n")
					can_print[ply] = false
				end
				CountDebugMessage(ply)
				return
			end

			local pos = net.ReadVector()
			if ply:GetPos():DistToSqr(pos) > ENFORCE_DISTANCE_SQR and ENFORCE_DISTANCE_SQR > 0 then return end
			local ang = net.ReadAngle()
			local tbl = {}

			tbl.Damage = net.ReadUInt(28)
			tbl.MaxHpScaling = net.ReadUInt(10) / 1000
			tbl.Length = net.ReadInt(16)
			tbl.Radius = net.ReadInt(16)

			tbl.AffectSelf = net.ReadBool()
			tbl.NPC = net.ReadBool()
			tbl.Players = net.ReadBool()
			tbl.PointEntities = net.ReadBool()
			tbl.FilterFriendlies = net.ReadBool()
			tbl.FilterNeutrals = net.ReadBool()
			tbl.FilterHostiles = net.ReadBool()

			tbl.HitboxMode = table.KeyFromValue(hitbox_ids, net.ReadUInt(5))
			tbl.DamageType = table.KeyFromValue(damage_ids, net.ReadUInt(7))

			tbl.Detail = net.ReadInt(6)
			tbl.ExtraSteps = net.ReadInt(4)
			tbl.RadialRandomize = net.ReadInt(7) / 8
			tbl.PhaseRandomize = net.ReadInt(7) / 8
			tbl.DamageFalloff = net.ReadBool()
			tbl.DamageFalloffPower = net.ReadInt(12) / 8
			tbl.Bullet = net.ReadBool()
			tbl.DoNotKill = net.ReadBool()
			tbl.ReverseDoNotKill = net.ReadBool()
			tbl.CriticalHealth = net.ReadUInt(16)
			tbl.RemoveNPCWeaponsOnKill = net.ReadBool()

			tbl.DOTMode = net.ReadBool()
			tbl.NoInitialDOT = net.ReadBool()
			tbl.DOTCount = net.ReadUInt(7)
			tbl.DOTTime = net.ReadUInt(11) / 64
			tbl.UniqueID = net.ReadString()
			local do_ents_feedback = net.ReadBool()
			if not tbl.UniqueID then return end

			if tbl.DOTTime == 0 or (tbl.DOTCount == 0 and not tbl.NoInitialDOT) then
				tbl.DOTMode = false
			end

			local dmg_info = DamageInfo()

			--server limits
			tbl.Radius = math.Clamp(tbl.Radius,-damagezone_max_radius:GetInt(),damagezone_max_radius:GetInt())
			tbl.Length = math.Clamp(tbl.Length,-damagezone_max_length:GetInt(),damagezone_max_length:GetInt())
			tbl.Damage = math.Clamp(tbl.Damage,-damagezone_max_damage:GetInt(),damagezone_max_damage:GetInt())

			dmg_info:SetDamage(tbl.Damage)
			dmg_info:IsBulletDamage(tbl.Bullet)
			dmg_info:SetDamageForce(Vector(0,0,0))
			dmg_info:SetAttacker(ply)
			dmg_info:SetInflictor(ply)

			local ents_hits
			local kill = false
			local hit = false

			if damage_types[tbl.DamageType] then
				if special_damagetypes[tbl.DamageType] then
					dmg_info:SetDamageType(0)
				else
					dmg_info:SetDamageType(damage_types[tbl.DamageType])
				end
			else
				dmg_info:SetDamageType(0)
			end

			local ratio
			if tbl.Radius == 0 then ratio = tbl.Length
			else ratio = math.abs(tbl.Length / tbl.Radius) end

			if tbl.HitboxMode == "Sphere" then
				ents_hits = ents.FindInSphere(pos, tbl.Radius)

			elseif tbl.HitboxMode == "Box" or tbl.HitboxMode == "Cube" then
				local mins
				local maxs
				if tbl.HitboxMode == "Box" then
					mins = pos - Vector(tbl.Radius, tbl.Radius, tbl.Length)
					maxs = pos + Vector(tbl.Radius, tbl.Radius, tbl.Length)
				elseif tbl.HitboxMode == "Cube" then
					mins = pos - Vector(tbl.Radius, tbl.Radius, tbl.Radius)
					maxs = pos + Vector(tbl.Radius, tbl.Radius, tbl.Radius)
				end

				ents_hits = ents.FindInBox(mins, maxs)

			elseif tbl.HitboxMode == "Cylinder" or tbl.HitboxMode == "CylinderHybrid" then
				ents_hits = {}
				if tbl.Radius ~= 0 then
					local sides = tbl.Detail
					if tbl.Detail < 1 then sides = 1 end
					local area_factor = tbl.Radius*tbl.Radius / (400 + 100*tbl.Length/math.max(tbl.Radius,0.1)) --bigger radius means more rays needed to cast to approximate the cylinder detection
					local steps = 3 + math.ceil(4*(area_factor / ((4 + tbl.Length/4) / (20 / math.max(tbl.Detail,1)))))
					if tbl.HitboxMode == "CylinderHybrid" and tbl.Length ~= 0 then
						area_factor = 0.15*area_factor
						steps = 1 + math.ceil(4*(area_factor / ((4 + tbl.Length/4) / (20 / math.max(tbl.Detail,1)))))
					end
					steps = math.max(steps + math.abs(tbl.ExtraSteps),1)

					for ringnumber=1,0,-1/steps do --concentric circles go smaller and smaller by lowering the i multiplier
						phase = math.random()
						local ray_thickness = math.Clamp(0.5*math.log(tbl.Radius) + 0.05*tbl.Radius,0,10)*(1 - 0.7*ringnumber)
						for i=1,0,-1/sides do
							if ringnumber == 0 then i = 0 end
							x = ang:Right()*math.cos(2 * math.pi * i + phase * tbl.PhaseRandomize)*tbl.Radius*ringnumber*(1 - math.random() * (ringnumber) * tbl.RadialRandomize)
							y = ang:Up()   *math.sin(2 * math.pi * i + phase * tbl.PhaseRandomize)*tbl.Radius*ringnumber*(1 - math.random() * (ringnumber) * tbl.RadialRandomize)
							local startpos = pos + x + y
							local endpos = pos + ang:Forward()*tbl.Length + x + y
							MergeTargetsByID(ents_hits, ents.FindAlongRay(startpos, endpos, maximized_ray_mins_maxs(startpos,endpos,ray_thickness)))
						end
					end
					if tbl.HitboxMode == "CylinderHybrid" and tbl.Length ~= 0 then
						--fast sphere check on the wide end
						if tbl.Length/tbl.Radius >= 2 then
							MergeTargetsByID(ents_hits,ents.FindInSphere(pos + ang:Forward()*(tbl.Length - tbl.Radius), tbl.Radius))
							MergeTargetsByID(ents_hits,ents.FindInSphere(pos + ang:Forward()*tbl.Radius, tbl.Radius))
							if tbl.Radius ~= 0 then
								local counter = 0
								for i=math.floor(tbl.Length / tbl.Radius) - 1,1,-1 do
									MergeTargetsByID(ents_hits,ents.FindInSphere(pos + ang:Forward()*(tbl.Radius*i), tbl.Radius))
									if counter == 100 then break end
									counter = counter + 1
								end
							end
						end
					end
				elseif tbl.Radius == 0 then MergeTargetsByID(ents_hits,ents.FindAlongRay(pos, pos + ang:Forward()*tbl.Length)) end

			elseif tbl.HitboxMode == "CylinderSpheres" then
				ents_hits = {}
				if tbl.Length ~= 0 and tbl.Radius ~= 0 then
					local counter = 0
					MergeTargetsByID(ents_hits,ents.FindInSphere(pos, tbl.Radius))
					for i=0,1,1/(math.abs(tbl.Length/tbl.Radius)) do
						MergeTargetsByID(ents_hits,ents.FindInSphere(pos + ang:Forward()*tbl.Length*i, tbl.Radius))
						if counter == 200 then break end
						counter = counter + 1
					end
					MergeTargetsByID(ents_hits,ents.FindInSphere(pos + ang:Forward()*tbl.Length, tbl.Radius))
				elseif tbl.Radius == 0 then MergeTargetsByID(ents_hits,ents.FindAlongRay(pos, pos + ang:Forward()*tbl.Length)) end

			elseif tbl.HitboxMode == "Cone" or tbl.HitboxMode == "ConeHybrid" then
				ents_hits = {}
				if tbl.Radius ~= 0 then
					local sides = tbl.Detail
					if tbl.Detail < 1 then sides = 1 end
					local startpos = pos-- + Vector(0,       self.Radius,self.Radius)
					local area_factor = tbl.Radius*tbl.Radius / (400 + 100*tbl.Length/math.max(tbl.Radius,0.1)) --bigger radius means more rays needed to cast to approximate the cylinder detection
					local steps = 3 + math.ceil(4*(area_factor / ((4 + tbl.Length/4) / (20 / math.max(tbl.Detail,1)))))
					if tbl.HitboxMode == "ConeHybrid" and tbl.Length ~= 0 then
						area_factor = 0.15*area_factor
						steps = 1 + math.ceil(4*(area_factor / ((4 + tbl.Length/4) / (20 / math.max(tbl.Detail,1)))))
					end
					steps = math.max(steps + math.abs(tbl.ExtraSteps),1)
					local timestart = SysTime()
					local casts = 0
					for ringnumber=1,0,-1/steps do --concentric circles go smaller and smaller by lowering the ringnumber multiplier
						phase = math.random()
						local ray_thickness = 5 * (2 - ringnumber)

						for i=1,0,-1/sides do
							if ringnumber == 0 then i = 0 end
							x = ang:Right()*math.cos(2 * math.pi * i + phase * tbl.PhaseRandomize)*tbl.Radius*ringnumber*(1 - math.random() * (ringnumber) * tbl.RadialRandomize)
							y = ang:Up()   *math.sin(2 * math.pi * i + phase * tbl.PhaseRandomize)*tbl.Radius*ringnumber*(1 - math.random() * (ringnumber) * tbl.RadialRandomize)
							local endpos = pos + ang:Forward()*tbl.Length + x + y
							MergeTargetsByID(ents_hits,ents.FindAlongRay(startpos, endpos, maximized_ray_mins_maxs(startpos,endpos,ray_thickness)))
							casts = casts + 1
						end
					end
					if tbl.HitboxMode == "ConeHybrid" and tbl.Length ~= 0 then
						--fast sphere check on the wide end
						local radius_multiplier = math.atan(math.abs(ratio)) / (1.5 + 0.1*math.sqrt(ratio))
						if ratio > 0.5 then
							MergeTargetsByID(ents_hits,ents.FindInSphere(pos + ang:Forward()*(tbl.Length - tbl.Radius * radius_multiplier), tbl.Radius * radius_multiplier))
						end
					end
				elseif tbl.Radius == 0 then MergeTargetsByID(ents_hits,ents.FindAlongRay(pos, pos + ang:Forward()*tbl.Length)) end

			elseif tbl.HitboxMode == "ConeSpheres" then
				ents_hits = {}
				local steps
				steps = math.Clamp(4*math.ceil(tbl.Length / (tbl.Radius or 1)),1,50)
				for i = 1,0,-1/steps do
					MergeTargetsByID(ents_hits,ents.FindInSphere(pos + ang:Forward()*tbl.Length*i, i * tbl.Radius))
				end

				steps = math.Clamp(math.ceil(tbl.Length / (tbl.Radius or 1)),1,4)

				if tbl.Radius == 0 then MergeTargetsByID(ents_hits,ents.FindAlongRay(pos, pos + ang:Forward()*tbl.Length)) end

			elseif tbl.HitboxMode =="Ray" then
				local startpos = pos + Vector(0,0,0)
				local endpos = pos + ang:Forward()*tbl.Length
				ents_hits = ents.FindAlongRay(startpos, endpos)

				if tbl.Bullet then
					local bullet = {}
					bullet.Src = pos + ang:Forward()
					bullet.Dir = ang:Forward()*50000
					bullet.Damage = -1
					bullet.Force = 0
					bullet.Entity = dmg_info:GetAttacker()
					dmg_info:GetInflictor():FireBullets(bullet)
				end
			end
			hit,kill,highest_dmg,successful_hit_ents,successful_kill_ents = ProcessDamagesList(ents_hits, dmg_info, tbl, pos, ang, ply)
			highest_dmg = highest_dmg or 0
			net.Start("pac_hit_results", true)
			net.WriteString(tbl.UniqueID)
			net.WriteBool(hit)
			net.WriteBool(kill)
			net.WriteFloat(highest_dmg)
			net.WriteBool(hit and do_ents_feedback)
			if successful_hit_ents and hit and do_ents_feedback and #successful_hit_ents < 20 then
				local _,bits_before_hit = net.BytesWritten()
				net.WriteTable(successful_hit_ents, true)
				local _,bits_after_hit = net.BytesWritten()
				--print("table is length " .. bits_after_hit - bits_before_hit .. " for " .. table.Count(successful_hit_ents) .. " ents hit, or about " .. ((bits_after_hit - bits_before_hit) / table.Count(successful_hit_ents) - 16) .. " per ent")
				if kill then net.WriteTable(successful_kill_ents, true) end
				local _,bits_after_kill = net.BytesWritten()
				--print("table is length " .. bits_after_kill - bits_after_hit .. " for " .. table.Count(successful_kill_ents) .. " ents killed, or about " .. ((bits_after_kill - bits_after_hit) / table.Count(successful_kill_ents) - 16) .. " per ent")
			end
			net.Broadcast()
		end)

	end

	local nextchecklock = CurTime()
	local function DeclareLockReceivers()
		util.AddNetworkString("pac_request_position_override_on_entity_teleport")
		util.AddNetworkString("pac_request_position_override_on_entity_grab")
		util.AddNetworkString("pac_request_angle_reset_on_entity")
		util.AddNetworkString("pac_lock_imposecalcview")
		util.AddNetworkString("pac_signal_stop_lock")
		util.AddNetworkString("pac_request_lock_break")
		util.AddNetworkString("pac_mark_grabbed_ent")
		util.AddNetworkString("pac_notify_grabbed_player")
		--The lock part grab request net message
		net.Receive("pac_request_position_override_on_entity_grab", function(len, ply)
			--server allow
			if not lock_allow:GetBool() then return end
			if not lock_allow_grab:GetBool() then return end
			if not PlayerIsCombatAllowed(ply) then return end


			--netrate enforce
			if not CountNetMessage(ply) then
				if debugging:GetBool() and can_print[ply] then
					MsgC(Color(255,255,0), "[PAC3] Lock grab: ") MsgC(Color(0,255,255), tostring(ply)) MsgC(Color(200,200,200), " combat actions are too many or too fast! (spam warning)\n")
					can_print[ply] = false
				end
				CountDebugMessage(ply)
				return
			end

			local did_grab = true
			local need_breakup = false
			local breakup_condition = ""
			--monstrous net message
			local is_first_time = net.ReadBool()
			local lockpart_UID = net.ReadString()
			local pos = net.ReadVector()
			local ang = net.ReadAngle()
			local override_ang = net.ReadBool()
			local override_eyeang = net.ReadBool()
			local no_collide = net.ReadBool()
			local targ_ent = net.ReadEntity()
			local auth_ent = net.ReadEntity()
			local override_viewposition = net.ReadBool()
			local alt_pos = net.ReadVector()
			local alt_ang = net.ReadAngle()
			local ask_drawviewer = net.ReadBool()

			if targ_ent.CPPICanPhysgun and not targ_ent:CPPICanPhysgun(ply) then return end
			if ulx and (targ_ent.frozen or targ_ent.jail) then return end --we can't grab frozen/jailed players either

			if ply:GetPos():DistToSqr(pos) > ENFORCE_DISTANCE_SQR and ENFORCE_DISTANCE_SQR > 0 then
				ApplyLockState(targ_ent, false)
				if ply.grabbed_ents then
					net.Start("pac_request_lock_break")
					net.WriteEntity(targ_ent)
					net.WriteString(lockpart_UID)
					net.WriteString("too far!")
					net.Send(ply)
				end
				return
			end

			local prop_protected, reason = IsPropProtected(targ_ent, ply)

			local owner = Try_CPPIGetOwner(targ_ent) or targ_ent
			if not IsValid(owner) then return end


			local unconsenting_owner = owner ~= ply and (grab_consents[owner] == false or (targ_ent:IsPlayer() and grab_consents[targ_ent] == false))
			local calcview_unconsenting = owner ~= ply and (calcview_consents[owner] == false or (targ_ent:IsPlayer() and calcview_consents[targ_ent] == false))

			if unconsenting_owner then
				if owner:IsPlayer() then return
				elseif (global_combat_prop_protection:GetBool() and prop_protected) then return
				end
			end

			local targ_ent_owner = owner or targ_ent
			local auth_ent_owner = ply

			auth_ent_owner.grabbed_ents = auth_ent_owner.grabbed_ents or {}

			local consent_break_condition = false

			if grab_consents[targ_ent_owner] == false then --if the target player is non-consenting
				if targ_ent_owner == auth_ent_owner then consent_break_condition = false  --player can still grab his owned entities
				elseif targ_ent:IsPlayer() then --if not the same player, we cannot grab
					consent_break_condition = true
					breakup_condition = breakup_condition .. "cannot grab another player if they don't consent to grabs, "
				elseif global_combat_prop_protection:GetBool() and owner ~= ply then
					--if entity not owned by grabbing player, he cannot do it to other players' entities in the prop-protected mode
					consent_break_condition = true
					breakup_condition = breakup_condition .. "cannot grab another player's owned entities if they don't consent to grabs, "
				end
			end

			if not IsValid(targ_ent) then --invalid entity?
				did_grab = false
				return --nothing else matters, get out
			end
			if consent_break_condition then --any of the non-consenting conditions
				did_grab = false
				need_breakup = true
				breakup_condition = breakup_condition .. "non-consenting, "
			end

			--dead ent = break
			--but don't exclude about physics props
			if targ_ent:Health() == 0 and not (physics_point_ent_classes[targ_ent:GetClass()] or string.find(targ_ent:GetClass(),"item_") or string.find(targ_ent:GetClass(),"ammo_") or targ_ent:IsWeapon()) then
				did_grab = false
				need_breakup = true
				breakup_condition = breakup_condition .. "dead, "
			end

			if is_first_time then
				if targ_ent.grabbed_ents then
					if (auth_ent_owner ~= targ_ent and targ_ent.grabbed_ents[auth_ent_owner] == true) then
						did_grab = false
						need_breakup = true
						breakup_condition = breakup_condition .. "mutual grab prevention, "
					end
				end

			end

			if did_grab then


				if targ_ent:IsPlayer() and targ_ent:InVehicle() then --yank player out of vehicle
					if debugging:GetBool() and can_print[ply] then print("Kicking " .. targ_ent:Nick() .. " out of vehicle to be grabbed!") end
					targ_ent:ExitVehicle()
				end

				if override_ang then
					if not targ_ent:IsPlayer() then --non-players work with angles
						targ_ent:SetAngles(ang)
					else --players work with eyeangles
						if override_eyeang then

							if PlayerAllowsCalcView(targ_ent) and override_viewposition then
								targ_ent.nextcalcviewTick = targ_ent.nextcalcviewTick or CurTime()
								if targ_ent.nextcalcviewTick < CurTime() then
									net.Start("pac_lock_imposecalcview")
									net.WriteBool(true)
									net.WriteVector(alt_pos)
									net.WriteAngle(alt_ang)
									net.WriteBool(ask_drawviewer)
									net.Send(targ_ent)
									targ_ent.nextcalcviewTick = CurTime() + 0.1
									targ_ent.has_calcview = true
								end
								targ_ent:SetEyeAngles(alt_ang)
								targ_ent:SetAngles(alt_ang)
							else
								targ_ent:SetEyeAngles(ang)
								targ_ent:SetAngles(ang)
							end
						elseif not override_eyeang or not override_viewposition or not PlayerAllowsCalcView(targ_ent) then --break any calcviews if we can't do that
							if targ_ent.has_calcview then
								net.Start("pac_lock_imposecalcview")
								net.WriteBool(false)
								net.WriteVector(Vector(0,0,0))
								net.WriteAngle(Angle(0,0,0))
								net.Send(targ_ent)
								targ_ent.has_calcview = false
							end
						end

					end
				end

				targ_ent:SetPos(pos)

				if not targ_ent.lock_state_applied and not targ_ent.default_movetype_reserved then
					targ_ent.default_movetype = targ_ent:GetMoveType()
					targ_ent.default_movetype_reserved = true
					targ_ent.lock_state_applied = true
				end
				ApplyLockState(targ_ent, true, no_collide)
				if targ_ent.IsDrGEntity then
					targ_ent.loco:SetVelocity(Vector(0,0,0)) --counter gravity speed buildup
				end
				if targ_ent:GetClass() == "prop_ragdoll" then targ_ent:GetPhysicsObject():SetPos(pos) end

				--@@note lock assignation! IMPORTANT
				if is_first_time then --successful, first
					auth_ent_owner.grabbed_ents[targ_ent] = true
					targ_ent.grabbed_by = auth_ent_owner
					targ_ent.grabbed_by_uid = lockpart_UID
					if debugging:GetBool() and can_print[ply] then print(auth_ent, "grabbed", targ_ent, "owner grabber is", auth_ent_owner) end
				end
				targ_ent.grabbed_by_time = CurTime()
			else
				auth_ent_owner.grabbed_ents[targ_ent] = nil
				targ_ent.grabbed_by_uid = nil
				targ_ent.grabbed_by = nil
			end

			if need_breakup then
				if debugging:GetBool() and can_print[ply] then print("stop this now! reason: " .. breakup_condition) end
				net.Start("pac_request_lock_break")
				net.WriteEntity(targ_ent)
				net.WriteString(lockpart_UID)
				net.WriteString(breakup_condition)
				net.Send(auth_ent_owner)

			else
				if is_first_time and did_grab then
					net.Start("pac_mark_grabbed_ent")
					net.WriteEntity(targ_ent)
					net.WriteBool(did_grab)
					net.WriteString(lockpart_UID)
					net.Broadcast()

					if targ_ent:IsPlayer() then
						net.Start("pac_notify_grabbed_player")
						net.WriteEntity(ply)
						net.Send(targ_ent)
					end
				end
			end
		end)
		--the lockpart teleport request net message
		net.Receive("pac_request_position_override_on_entity_teleport", function(len, ply)
			--server allow
			if not lock_allow:GetBool() then return end
			if not lock_allow_teleport:GetBool() then return end
			if not PlayerIsCombatAllowed(ply) then return end

			--netrate enforce
			if not CountNetMessage(ply) then
				if debugging:GetBool() and can_print[ply] then
					MsgC(Color(255,255,0), "[PAC3] Lock teleport: ") MsgC(Color(0,255,255), tostring(ply)) MsgC(Color(200,200,200), " combat actions are too many or too fast! (spam warning)\n")
					can_print[ply] = false
				end
				CountDebugMessage(ply)
				return
			end

			local lockpart_UID = net.ReadString()
			local pos = net.ReadVector()
			local ang = net.ReadAngle()
			local override_ang = net.ReadBool()

			if IsValid(ply) then
				if override_ang then
					ply:SetEyeAngles(ang)
				end
				ply:SetPos(pos)
			end

		end)
		--the lockpart grab end request net message
		net.Receive("pac_request_angle_reset_on_entity", function(len, ply)

			if not PlayerIsCombatAllowed(ply) then return end

			local ang = net.ReadAngle()
			local delay = net.ReadFloat()
			local targ_ent = net.ReadEntity()
			local auth_ent = net.ReadEntity()
			if targ_ent.CPPICanPhysgun and not targ_ent:CPPICanPhysgun(ply) then return end
			local prop_protected, reason = IsPropProtected(targ_ent, ply)

			local owner = Try_CPPIGetOwner(targ_ent)

			local unconsenting_owner = owner ~= ply and (grab_consents[owner] == false or (targ_ent:IsPlayer() and grab_consents[targ_ent] == false))
			if unconsenting_owner then
				if owner:IsPlayer() then return
				elseif (global_combat_prop_protection:GetBool() and prop_protected) then return
				end
			end

			targ_ent:SetAngles(ang)
			ApplyLockState(targ_ent, false)

		end)


		hook.Add("Tick", "pac_checklocks", function()
			if nextchecklock > CurTime() then return else nextchecklock = CurTime() + 0.2 end
			--go through every entity and check if they're still active, if beyond 0.5 seconds we nil out. this is the closest to a regular check
			for ent,bool in pairs(active_grabbed_ents) do
				if not IsValid(ent) then
					active_grabbed_ents[ent] = nil
				elseif (ent.grabbed_by or bool) then
					ent.grabbed_by_time = ent.grabbed_by_time or 0
					if ent.grabbed_by_time + 0.5 < CurTime() then --restore the movetype
						local grabber = ent.grabbed_by
						ent.grabbed_by_uid = nil
						ent.grabbed_by = nil
						if grabber then
							grabber.grabbed_ents[ent] = false
						end

						ApplyLockState(ent, false)
						active_grabbed_ents[ent] = nil
					end
				end
			end
		end)
	end

	local function DeclareHitscanReceivers()
		util.AddNetworkString("pac_hitscan")
		net.Receive("pac_hitscan", function(len,ply)

			if not hitscan_allow:GetBool() then return end
			if not PlayerIsCombatAllowed(ply) then return end

			--netrate enforce
			if not CountNetMessage(ply) then
				if debugging:GetBool() and can_print[ply] then
					MsgC(Color(255,255,0), "[PAC3] Hitscan: ") MsgC(Color(0,255,255), tostring(ply)) MsgC(Color(200,200,200), " combat actions are too many or too fast! (spam warning)\n")
					can_print[ply] = false
				end
				CountDebugMessage(ply)
				return
			end

			local bulletinfo = {}
			local affect_self = net.ReadBool()
			bulletinfo.Src = net.ReadVector()
			local dir = net.ReadAngle()
			bulletinfo.Dir = dir:Forward()

			bulletinfo.dmgtype_str = table.KeyFromValue(damage_ids, net.ReadUInt(7))
			bulletinfo.dmgtype = damage_types[bulletinfo.dmgtype_str]
			local spreadx = net.ReadUInt(20) / 10000
			local spready = net.ReadUInt(20) / 10000
			bulletinfo.Spread = Vector(spreadx, spready, 0)
			bulletinfo.Damage = net.ReadUInt(28)
			bulletinfo.Tracer = net.ReadUInt(8)
			bulletinfo.Force = net.ReadUInt(16)

			bulletinfo.Distance = net.ReadUInt(16)
			bulletinfo.Num = net.ReadUInt(9)
			bulletinfo.TracerName = table.KeyFromValue(tracer_ids, net.ReadUInt(4))
			bulletinfo.DistributeDamage = net.ReadBool()

			bulletinfo.DamageFalloff = net.ReadBool()
			bulletinfo.DamageFalloffDistance = net.ReadUInt(16)
			bulletinfo.DamageFalloffFraction = net.ReadUInt(10) / 1000

			local part_uid = ply:Nick() .. net.ReadString()

			bulletinfo.Num = math.Clamp(bulletinfo.Num, 1, hitscan_max_bullets:GetInt())
			bulletinfo.Damage = math.Clamp(bulletinfo.Damage, 0, hitscan_max_damage:GetInt())
			bulletinfo.DamageFalloffFraction = math.Clamp(bulletinfo.DamageFalloffFraction,0,1)

			if hitscan_spreadout_dmg:GetBool() or bulletinfo.DistributeDamage then
				bulletinfo.Damage = bulletinfo.Damage / bulletinfo.Num
			end

			if not affect_self then bulletinfo.IgnoreEntity = ply end
			ply.pac_bullet_emitters = ply.pac_bullet_emitters or {}
			ply.pac_bullet_emitters[part_uid] = ply.pac_bullet_emitters[part_uid] or ents.Create("pac_bullet_emitter")

			bulletinfo.Attacker = ply
			bulletinfo.Callback = function(atk, trc, dmg)
				dmg:SetDamageType(bulletinfo.dmgtype)
				if trc.Hit and IsValid(trc.Entity) then
					if not NPCDispositionAllowsIt(ply, trc.Entity) then return {effects = false, damage = false} end
					local distance = (trc.HitPos):Distance(trc.StartPos)
					local fraction = math.Clamp(1 - (1-bulletinfo.DamageFalloffFraction)*(distance / bulletinfo.DamageFalloffDistance),bulletinfo.DamageFalloffFraction,1)
					local ent = trc.Entity

					if bulletinfo.dmgtype_str == "heal" and ent.Health then
						dmg:SetDamageType(0)

						if ent:Health() < ent:GetMaxHealth() then
							ent:SetHealth(math.min(ent:Health() + fraction * dmg:GetDamage(), math.max(ent:Health(), ent:GetMaxHealth())))
						end

						dmg:SetDamage(0)
						return
					elseif bulletinfo.dmgtype_str == "armor" and ent.Armor then
						dmg:SetDamageType(0)

						if ent:Armor() < ent:GetMaxArmor() then
							ent:SetArmor(math.min(ent:Armor() + fraction * dmg:GetDamage(), math.max(ent:Armor(), ent:GetMaxArmor())))
						end

						dmg:SetDamage(0)
						return
					end
					if bulletinfo.DamageFalloff and trc.Hit and IsValid(trc.Entity) then
						if bulletinfo.dmgtype_str ~= "heal" and bulletinfo.dmgtype_str ~= "armor" then
							dmg:SetDamage(fraction * dmg:GetDamage())
						end
					end
				end
			end

			if IsValid(ply.pac_bullet_emitters[part_uid]) then
				ply.pac_bullet_emitters[part_uid]:FireBullets(bulletinfo)
			else
				ply.pac_bullet_emitters[part_uid] = ents.Create("pac_bullet_emitter")
			end

		end)
	end

	local function DeclareHealthModifierReceivers()
		util.AddNetworkString("pac_request_healthmod")
		util.AddNetworkString("pac_update_healthbars")
		util.AddNetworkString("pac_request_extrahealthbars_action")
		net.Receive("pac_request_healthmod", function(len,ply)
			if not healthmod_allow:GetBool() then return end

			--netrate enforce
			if not CountNetMessage(ply) then
				if debugging:GetBool() and can_print[ply] then
					MsgC(Color(255,255,0), "[PAC3] Health modifier: ") MsgC(Color(0,255,255), tostring(ply)) MsgC(Color(200,200,200), " combat actions are too many or too fast! (spam warning)\n")
					can_print[ply] = false
				end
				CountDebugMessage(ply)
				return
			end

			local part_uid = net.ReadString()
			local mod_id = net.ReadString()
			local action = net.ReadString()

			if action == "MaxHealth" then
				if not healthmod_allow:GetBool() then return end
				local num = net.ReadUInt(32)
				num = math.Clamp(num,0,healthmod_max_value:GetInt())
				local follow = net.ReadBool()
				if not healthmod_allow_change_maxhp:GetBool() then return end
				if ply:Health() == ply:GetMaxHealth() and follow then
					ply:SetHealth(num)
				elseif num < ply:Health() then
					ply:SetHealth(num)
				end
				ply:SetMaxHealth(num)
				ply.pac_healthmods = ply.pac_healthmods or {}
				ply.pac_healthmods[part_uid] = ply.pac_healthmods[part_uid] or {}
				ply.pac_healthmods[part_uid].maxhealth = num

			elseif action == "MaxArmor" then
				if not healthmod_allow:GetBool() then return end
				local num = net.ReadUInt(32)
				num = math.Clamp(num,0,healthmod_max_value:GetInt())
				local follow = net.ReadBool()
				if not healthmod_allow_change_maxhp:GetBool() then return end
				if ply:Armor() == ply:GetMaxArmor() and follow then
					ply:SetArmor(num)
				elseif num < ply:Armor() then
					ply:SetArmor(num)
				end
				ply:SetMaxArmor(num)
				ply.pac_healthmods = ply.pac_healthmods or {}
				ply.pac_healthmods[part_uid] = ply.pac_healthmods[part_uid] or {}
				ply.pac_healthmods[part_uid].maxarmor = num

			elseif action == "DamageMultiplier" then
				local scale = net.ReadFloat()
				AddDamageScale(ply, mod_id, scale, part_uid)

			elseif action == "HealthBars" then
				if not healthmod_allowed_extra_bars:GetBool() then return end
				local num =	net.ReadUInt(32)
				local barsize = net.ReadUInt(32)
				local layer = net.ReadUInt(4)
				local absorbfactor = net.ReadFloat()
				local follow = net.ReadBool()
				local counted_hits = net.ReadBool()
				local no_overflow = net.ReadBool()

				if counted_hits and not healthmod_allowed_counted_hits:GetBool() then return end

				local requested_amount = num * barsize

				local current_bars_amount_without_this = GatherExtraHPBars(ply, part_uid)
				local allowed_amount_without_this = healthmod_max_extra_bars_value:GetInt() - current_bars_amount_without_this

				if requested_amount >= allowed_amount_without_this then
					requested_amount = math.Clamp(requested_amount,0,allowed_amount_without_this)

					barsize = math.floor(requested_amount / num)
					num = math.floor(requested_amount / barsize)

					UpdateHealthBars(ply, num, barsize, layer, absorbfactor, part_uid, follow, counted_hits, no_overflow)
				else
					UpdateHealthBars(ply, num, barsize, layer, absorbfactor, part_uid, follow, counted_hits, no_overflow)
				end

			elseif action == "OnRemove" then
				if ply.pac_damage_scalings then
					if ply.pac_damage_scalings[part_uid] then
						ply.pac_damage_scalings[part_uid] = nil
					end
				end
				if ply.pac_healthmods then
					ply.pac_healthmods[part_uid] = nil
				end

				FixMaxHealths(ply)
				UpdateHealthBars(ply, 0, 0, 0, 0, part_uid, follow)
			end
			SendUpdateHealthBars(ply)
		end)
		net.Receive("pac_request_extrahealthbars_action", function(len, ply)
			local part_uid = net.ReadString()
			local action = net.ReadString()
			local num = net.ReadInt(16)
			UpdateHealthBarsFromCMD(ply, action, num, part_uid)
			SendUpdateHealthBars(ply)
		end)
	end

	--[[util.AddNetworkString("pac_hitscan")
	util.AddNetworkString("pac_request_position_override_on_entity_teleport")
	util.AddNetworkString("pac_request_position_override_on_entity_grab")
	util.AddNetworkString("pac_request_angle_reset_on_entity")
	util.AddNetworkString("pac_request_zone_damage")
	util.AddNetworkString("pac_hit_results")
	util.AddNetworkString("pac_request_force")

	util.AddNetworkString("pac_signal_stop_lock")
	util.AddNetworkString("pac_request_lock_break")
	util.AddNetworkString("pac_lock_imposecalcview")
	util.AddNetworkString("pac_mark_grabbed_ent")
	util.AddNetworkString("pac_notify_grabbed_player")
	util.AddNetworkString("pac_request_healthmod")
	util.AddNetworkString("pac_update_healthbars")]]

	if master_init_featureblocker:GetInt() == 0 then
		FINAL_BLOCKED_COMBAT_FEATURES = {
			hitscan = false,
			damage_zone = false,
			lock = false,
			force = false,
			health_modifier = false,
		}


	elseif master_init_featureblocker:GetInt() == 1 then
		FINAL_BLOCKED_COMBAT_FEATURES = {
			hitscan = not hitscan_allow:GetBool(),
			damage_zone = not damagezone_allow:GetBool(),
			lock = not lock_allow:GetBool(),
			force = not force_allow:GetBool(),
			health_modifier = not healthmod_allow:GetBool(),
		}

	else -- if it's not 0 or 1, all net combat features will be removed!
		FINAL_BLOCKED_COMBAT_FEATURES = {
			hitscan = true,
			damage_zone = true,
			lock = true,
			force = true,
			health_modifier = true,
		}
	end

	if not FINAL_BLOCKED_COMBAT_FEATURES["force"] then DeclareForceReceivers() end
	if not FINAL_BLOCKED_COMBAT_FEATURES["damage_zone"] then DeclareDamageZoneReceivers() end
	if not FINAL_BLOCKED_COMBAT_FEATURES["lock"] then DeclareLockReceivers() end
	if not FINAL_BLOCKED_COMBAT_FEATURES["hitscan"] then DeclareHitscanReceivers() end
	if not FINAL_BLOCKED_COMBAT_FEATURES["health_modifier"] then DeclareHealthModifierReceivers() end

	local function ReinitializeCombatReceivers()
		for name,blocked in pairs(FINAL_BLOCKED_COMBAT_FEATURES) do
			local update = blocked and (blocked == GetConVar("pac_sv_"..name):GetBool())
			local new_bool = not (blocked or not GetConVar("pac_sv_"..name):GetBool())

			if update then
				FINAL_BLOCKED_COMBAT_FEATURES[name] = new_bool
				if name == "force" then DeclareForceReceivers() print("reinitialized " .. name)
				elseif name == "damage_zone" then DeclareDamageZoneReceivers() print("reinitialized " .. name)
				elseif name == "lock" then DeclareLockReceivers() print("reinitialized " .. name)
				elseif name == "hitscan" then DeclareHitscanReceivers() print("reinitialized " .. name)
				elseif name == "health_modifier" then DeclareHealthModifierReceivers() print("reinitialized " .. name)
				end
			end
		end
		net.Start("pac_inform_blocked_parts")
		net.WriteTable(FINAL_BLOCKED_COMBAT_FEATURES)
		net.Broadcast()
	end

	concommand.Add("pac_sv_combat_reinitialize_missing_receivers", function(ply)
		if IsValid(ply) then
			if not ply:IsAdmin() or not pac.RatelimitPlayer( ply, "pac_sv_combat_reinitialize_missing_receivers", 3, 5, {"Player ", ply, " is spamming pac_sv_combat_reinitialize_missing_receivers!"} ) then
				return
			end
			ReinitializeCombatReceivers()
		end

	end)

	util.AddNetworkString("pac_request_blocked_parts_reinitialization")
	net.Receive("pac_request_blocked_parts_reinitialization", function(len, ply)
		if IsValid(ply) then
			if not ply:IsAdmin() or not pac.RatelimitPlayer( ply, "pac_sv_combat_reinitialize_missing_receivers", 3, 5, {"Player ", ply, " is spamming pac_sv_combat_reinitialize_missing_receivers!"} ) then
				return
			end
			ReinitializeCombatReceivers()
		end
	end)

	net.Receive("pac_request_blocked_parts", function(len, ply)
		net.Start("pac_inform_blocked_parts")
		net.WriteTable(FINAL_BLOCKED_COMBAT_FEATURES)
		net.Send(ply)
	end)

end

if CLIENT then
	killicon.Add( "pac_bullet_emitter", "icon16/user_gray.png", Color(255,255,255) )

	concommand.Add("pac_sv_reinitialize_missing_combat_parts_remotely", function(ply)
		if IsValid(ply) then
			if not ply:IsAdmin() then
				return
			end
			net.Start("pac_request_blocked_parts_reinitialization")
			net.SendToServer()
		end
	end)


	CreateConVar("pac_client_npc_exclusion_consent", "0", {FCVAR_ARCHIVE}, "Whether you want to protect some npcs based on their disposition or faction. So far it only works with Dispositions.0 = ignore factions and relationships and target any NPC\n1 = protect friendlies\n2 = protect friendlies and neutrals")
	CreateConVar("pac_client_grab_consent", "0", {FCVAR_ARCHIVE}, "Whether you want to consent to being grabbed by other players in PAC3 with the lock part")
	CreateConVar("pac_client_lock_camera_consent", "0", {FCVAR_ARCHIVE}, "Whether you want to consent to having lock parts override your view")
	CreateConVar("pac_client_damage_zone_consent", "0", {FCVAR_ARCHIVE}, "Whether you want to consent to receiving damage by other players in PAC3 with the damage zone part")
	CreateConVar("pac_client_force_consent", "0", {FCVAR_ARCHIVE}, "Whether you want to consent to pac3 physics forces")
	CreateConVar("pac_client_hitscan_consent", "0", {FCVAR_ARCHIVE}, "Whether you want to consent to receiving damage by other players in PAC3 with the hitscan part.")

	function pac.CountNetMessage()
		local ply = LocalPlayer()

		local stime = SysTime()
		local ms_basis = GetConVar("pac_sv_combat_enforce_netrate"):GetInt()/1000
		local base_allowance = GetConVar("pac_sv_combat_enforce_netrate_buffersize"):GetInt()

		ply.pac_netmessage_allowance = ply.pac_netmessage_allowance or base_allowance
		ply.pac_netmessage_allowance_time = ply.pac_netmessage_allowance_time or 0 --initialize fields

		local timedelta = stime - ply.pac_netmessage_allowance_time --in seconds
		ply.pac_netmessage_allowance_time = stime
		local regen_rate = math.Clamp(ms_basis,0.01,10) / 20 --delay (converted from milliseconds) -> frequency (1/seconds)
		local regens = timedelta / regen_rate
		--print(timedelta .. " s, " .. 1/regen_rate .. "/s, " .. regens .. " regens")
		if base_allowance == 0 then --limiting only by time, with no reserves
			return timedelta > ms_basis
		elseif ms_basis == 0 then --allowance with 0 time means ??? I guess automatic pass
			return true
		else
			if timedelta > ms_basis then --good, count up
				--print("good time: +"..regens .. "->" .. math.Clamp(ply.pac_netmessage_allowance + math.min(regens,base_allowance), -1, base_allowance))
				ply.pac_netmessage_allowance = math.Clamp(ply.pac_netmessage_allowance + math.min(regens,base_allowance), -1, base_allowance)
			else --earlier than base delay, so count down the allowance
				--print("bad time: -1")
				ply.pac_netmessage_allowance = ply.pac_netmessage_allowance - 1
			end
			ply.pac_netmessage_allowance = math.Clamp(ply.pac_netmessage_allowance,-1,base_allowance)
			ply.pac_netmessage_allowance_time = stime
			return ply.pac_netmessage_allowance ~= -1
		end

	end

	local function SendConsents()
		net.Start("pac_signal_player_combat_consent")
		net.WriteUInt(GetConVar("pac_client_npc_exclusion_consent"):GetInt(),2)
		net.WriteBool(GetConVar("pac_client_grab_consent"):GetBool())
		net.WriteBool(GetConVar("pac_client_damage_zone_consent"):GetBool())
		net.WriteBool(GetConVar("pac_client_lock_camera_consent"):GetBool())
		net.WriteBool(GetConVar("pac_client_force_consent"):GetBool())
		net.WriteBool(GetConVar("pac_client_hitscan_consent"):GetBool())
		net.SendToServer()
	end


	local function RequestBlockedParts()
		net.Start("pac_request_blocked_parts")
		net.SendToServer()
	end

	concommand.Add("pac_inform_about_blocked_parts", function()
		RequestBlockedParts()
		pac.Message("Manually fetching info about pac3 combat parts...")

		timer.Simple(2, function()
			for name,b in pairs(pac.Blocked_Combat_Parts) do
				local blocked = b
				local disabled = not GetConVar("pac_sv_"..name):GetBool()

				local bool_str

				if disabled and blocked then bool_str = "disabled and blocked -> unavailable"
				elseif disabled and not blocked then bool_str = "disabled -> unavailable"
				elseif not disabled and blocked then bool_str = "blocked - > unavailable"
				elseif not disabled and not blocked then bool_str = "available"
				else bool_str = "??" end

				print(name .. " is " .. bool_str)
			end
		end)
	end)

	net.Receive("pac_inform_blocked_parts", function() --silent
		pac.Blocked_Combat_Parts = net.ReadTable()
	end)

	local consent_cvars = {"pac_client_npc_exclusion_consent", "pac_client_grab_consent", "pac_client_lock_camera_consent", "pac_client_damage_zone_consent", "pac_client_force_consent", "pac_client_hitscan_consent"}
	for _,cmd in ipairs(consent_cvars) do
		cvars.AddChangeCallback(cmd, SendConsents)
	end

	CreateConVar("pac_break_lock_verbosity", "3", FCVAR_ARCHIVE, "How much info you want for the PAC3 lock notifications\n3:full information\n2:grabbing player + basic reminder of the lock break command\n1:grabbing player\n0:suppress the notifications")


	concommand.Add( "pac_stop_lock", function()
		net.Start("pac_signal_stop_lock")
		net.SendToServer()
	end, nil, "asks the server to breakup any lockpart hold on your player")

	concommand.Add( "pac_break_lock", function()
		net.Start("pac_signal_stop_lock")
		net.SendToServer()
	end, nil, "asks the server to breakup any lockpart hold on your player")

	net.Receive("pac_lock_imposecalcview", function()
		local authority_to_calcview = net.ReadBool() and GetConVar("pac_client_lock_camera_consent"):GetBool()

		local alt_pos = net.ReadVector()
		local alt_ang = net.ReadAngle()
		local ask_drawviewer = net.ReadBool()

		if authority_to_calcview then
			LocalPlayer().last_calcview = CurTime()
			LocalPlayer().has_calcview = true
			hook.Add("CalcView", "PAC_lockpart_calcview", function(ply, pos, angles, fov)
				if LocalPlayer().last_calcview + 0.5 < CurTime() then
					hook.Remove("CalcView", "PAC_lockpart_calcview")
					LocalPlayer().has_calcview = false
					return nil

				end
				local view = {
					origin = alt_pos,
					angles = alt_ang,
					fov = fov,
					drawviewer = ask_drawviewer
				}
				return view
			end)
			hook.Add("Tick", "pac_checkcalcview", function()
				if LocalPlayer().has_calcview and LocalPlayer().last_calcview + 0.5 < CurTime() then
					hook.Remove("CalcView", "PAC_lockpart_calcview")
					LocalPlayer().has_calcview = false
					--print("killed a calcview due to expiry")
				end
				if LocalPlayer().last_calcview + 0.5 < CurTime() then
					hook.Remove("CalcView", "PAC_lockpart_calcview")
					LocalPlayer().has_calcview = false
					--print("killed a calcview again due to expiry")
				end
			end)
		else --if LocalPlayer().has_calcview then
			hook.Remove("CalcView", "PAC_lockpart_calcview")
			--print("killed a calcview due to lack of authority")
		end
	end)

	net.Receive("pac_request_player_combat_consent_update", function()
		SendConsents()
	end)

	net.Receive("pac_notify_grabbed_player", function()
		local grabber = net.ReadEntity()
		local verbosity = GetConVar("pac_break_lock_verbosity"):GetInt()
		local str
		if verbosity == 3 then
			str = "[PAC3] You've been grabbed by " .. grabber:Nick() .. "! You can break free with pac_break_lock or pac_stop_lock. You can suppress these messages with pac_break_lock_verbosity 0"
			notification.AddLegacy( str, NOTIFY_HINT, 10 )
		elseif verbosity == 2 then
			str = "[PAC3] You've been grabbed by " .. grabber:Nick() .. "! pac_break_lock to break free"
			notification.AddLegacy( str, NOTIFY_HINT, 7 )
		elseif verbosity == 1 then
			str = "[PAC3] You've been grabbed by " .. grabber:Nick() .. "!"
			notification.AddLegacy( str, NOTIFY_HINT, 7 )
		end

		pac.Message("You've been grabbed by " .. grabber:Nick() .. "!")

	end)

	hook.Add("InitPostEntity", "PAC_Send_Consents_On_Join", SendConsents)
	hook.Add("InitPostEntity", "PAC_Request_BlockedParts_On_Join", RequestBlockedParts)
	pac.Blocked_Combat_Parts = pac.Blocked_Combat_Parts or {}
end
