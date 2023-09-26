--lua_openscript pac3/extra/shared/net_combat.lua
if SERVER then
	include("pac3/editor/server/combat_bans.lua")
	include("pac3/editor/server/bans.lua")
end


pac.global_combat_whitelist = pac.global_combat_whitelist or {}

local hitscan_allow = CreateConVar('pac_sv_hitscan', 1, CLIENT and {FCVAR_REPLICATED} or {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}, 'Allow hitscan parts serverside')
local hitscan_max_bullets = CreateConVar('pac_sv_hitscan_max_bullets', '200', CLIENT and {FCVAR_REPLICATED} or {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}, 'hitscan part maximum number of bullets')
local hitscan_max_damage = CreateConVar('pac_sv_hitscan_max_damage', '20000', CLIENT and {FCVAR_REPLICATED} or {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}, 'hitscan part maximum damage')
local hitscan_spreadout_dmg = CreateConVar('pac_sv_hitscan_divide_max_damage_by_max_bullets', 0, CLIENT and {FCVAR_REPLICATED} or {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}, 'Whether or not force hitscans to divide their damage among the number of bullets fired')

local damagezone_allow = CreateConVar('pac_sv_damage_zone', 1, CLIENT and {FCVAR_REPLICATED} or {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}, 'Allow damage zone parts serverside')
local damagezone_max_damage = CreateConVar('pac_sv_damage_zone_max_damage', '20000', CLIENT and {FCVAR_REPLICATED} or {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}, 'damage zone maximum damage')
local damagezone_max_length = CreateConVar('pac_sv_damage_zone_max_length', '20000', CLIENT and {FCVAR_REPLICATED} or {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}, 'damage zone maximum length')
local damagezone_max_radius = CreateConVar('pac_sv_damage_zone_max_radius', '10000', CLIENT and {FCVAR_REPLICATED} or {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}, 'damage zone maximum radius')
local damagezone_allow_dissolve = CreateConVar('pac_sv_damage_zone_allow_dissolve', '1', CLIENT and {FCVAR_REPLICATED} or {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}, 'Whether to enable entity dissolvers and removing NPCs\' weapons on death for damagezone')

local lock_allow = CreateConVar('pac_sv_lock', 1, CLIENT and {FCVAR_REPLICATED} or {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}, 'Allow lock parts serverside')
local lock_allow_grab = CreateConVar('pac_sv_lock_grab', 1, CLIENT and {FCVAR_REPLICATED} or {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}, 'Allow lock part grabs serverside')
local lock_allow_teleport = CreateConVar('pac_sv_lock_teleport', 1, CLIENT and {FCVAR_REPLICATED} or {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}, 'Allow lock part teleports serverside')
local lock_max_radius = CreateConVar('pac_sv_lock_max_grab_radius', '200', CLIENT and {FCVAR_REPLICATED} or {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}, 'lock part maximum grab radius')
local lock_allow_grab_ply = CreateConVar('pac_sv_lock_allow_grab_ply', 1, CLIENT and {FCVAR_REPLICATED} or {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}, 'allow grabbing players with lock part')
local lock_allow_grab_npc = CreateConVar('pac_sv_lock_allow_grab_npc', 1, CLIENT and {FCVAR_REPLICATED} or {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}, 'allow grabbing NPCs with lock part')
local lock_allow_grab_ent = CreateConVar('pac_sv_lock_allow_grab_ent', 1, CLIENT and {FCVAR_REPLICATED} or {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}, 'allow grabbing other entities with lock part')

local force_allow = CreateConVar('pac_sv_force', 1, CLIENT and {FCVAR_REPLICATED} or {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}, 'Allow force parts serverside')
local force_max_length = CreateConVar('pac_sv_force_max_length', '10000', CLIENT and {FCVAR_REPLICATED} or {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}, 'force part maximum length')
local force_max_radius = CreateConVar('pac_sv_force_max_radius', '10000', CLIENT and {FCVAR_REPLICATED} or {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}, 'force part maximum radius')
local force_max_amount = CreateConVar('pac_sv_force_max_amount', '10000', CLIENT and {FCVAR_REPLICATED} or {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}, 'force part maximum amount of force')

local healthmod_allow = CreateConVar('pac_sv_health_modifier', 1, CLIENT and {FCVAR_REPLICATED} or {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}, 'Allow health modifier parts serverside')
local healthmod_allowed_extra_bars = CreateConVar('pac_sv_health_modifier_extra_bars', 1, CLIENT and {FCVAR_NOTIFY, FCVAR_REPLICATED} or {FCVAR_ARCHIVE, FCVAR_REPLICATED}, 'Allow extra health bars')
local healthmod_allow_change_maxhp = CreateConVar('pac_sv_health_modifier_allow_maxhp', 1, CLIENT and {FCVAR_NOTIFY, FCVAR_REPLICATED} or {FCVAR_ARCHIVE, FCVAR_REPLICATED}, 'Allow players to change their maximum health and armor.')
local healthmod_minimum_dmgscaling = CreateConVar('pac_sv_health_modifier_min_damagescaling', -1, CLIENT and {FCVAR_REPLICATED} or {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}, 'Minimum health modifier amount. Negative values can heal.')

local master_init_featureblocker = CreateConVar('pac_sv_block_combat_features_on_next_restart', 0, CLIENT and {FCVAR_REPLICATED} or {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}, 'Whether to stop initializing the net receivers for the networking of PAC3 combat parts those selectively disabled. This requires a restart!\n0=initialize all the receivers\n1=disable those whose corresponding part cvar is disabled\n2=block all combat features\nAfter updating the sv cvars, you can still reinitialize the net receivers with pac_sv_combat_reinitialize_missing_receivers, but you cannot turn them off after they are turned on')
cvars.AddChangeCallback('pac_sv_block_combat_features_on_next_restart', function() print("Remember that pac_sv_block_combat_features_on_next_restart is applied on server startup! Only do it if you know what you're doing. You'll need to restart the server.") end)

local enforce_netrate = CreateConVar("pac_sv_combat_enforce_netrate", 0, CLIENT and {FCVAR_REPLICATED} or {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}, 'whether to enforce a limit on how often any pac combat net messages can be sent. 0 to disable, otherwise a number in mililiseconds')
local enforce_netrate_buffer = CreateConVar("pac_sv_combat_enforce_netrate_buffersize", 5000, CLIENT and {FCVAR_REPLICATED} or {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}, 'the budgeted allowance to limit how often pac combat net messages can be sent. 0 to disable, otherwise a number in bit size')
local raw_ent_limit = CreateConVar("pac_sv_entity_limit_per_combat_operation", 500, CLIENT and {FCVAR_REPLICATED} or {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Hard limit to drop any force or damage zone if more than this amount of entities is selected")
local per_ply_limit = CreateConVar("pac_sv_entity_limit_per_player_per_combat_operation", 40, CLIENT and {FCVAR_REPLICATED} or {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Limit per player to drop any force or damage zone if this amount multiplied by each client is more than the hard limit")
local player_fraction = CreateConVar("pac_sv_player_limit_as_fraction_to_drop_damage_zone", 1, CLIENT and {FCVAR_REPLICATED} or {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "The fraction (0.0-1.0) of players that will stop damage zone net messages if a damage zone order covers more than this fraction of the server's population, when there are more than 12 players covered")

local global_combat_whitelisting = CreateConVar('pac_sv_combat_whitelisting', 0, CLIENT and {FCVAR_REPLICATED} or {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}, 'How the server should decide which players are allowed to use the main PAC3 combat parts (lock, damagezone, force).\n0:Everyone is allowed unless the parts are disabled serverwide\n1:No one is allowed until they get verified as trustworthy\tpac_sv_whitelist_combat <playername>\n\tpac_sv_blacklist_combat <playername>')
local global_combat_prop_protection = CreateConVar('pac_sv_prop_protection', 0, CLIENT and {FCVAR_REPLICATED} or {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}, 'Whether players\' owned (created) entities (physics props and gmod contraption entities) will be considered in the consent calculations, protecting them. Without this cvar, only the player is protected.')

local damageable_point_ent_classes = {
	["predicted_viewmodel"] = false,
	["prop_physics"] = true,
	["weapon_striderbuster"] = true,
	["item_item_crate"] = true,
	["func_breakable_surf"] = true,
	["func_breakable"] = true,
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
	["physics_cannister"] = true
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
}



local grab_consents = {}
local damage_zone_consents = {}
local force_consents = {}
local hitscan_consents = {}
local calcview_consents = {}
local active_force_ids = {}
local active_grabbed_ents = {}

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

do	--define a basic class for the bullet emitters
	local ENT = {}
	ENT.Type = "anim"
	ENT.ClassName = "pac_bullet_emitter"
	ENT.Spawnable = false 
	scripted_ents.Register(ENT, "pac_bullet_emitter")
end

if SERVER then

	--hack fix to stop GetOwner returning [NULL Entity]
	hook.Add("PlayerSpawnedProp", "HackReAssignOwner", function(ply, model, ent) ent.m_PlayerCreator = ply end)
	hook.Add("PlayerSpawnedNPC", "HackReAssignOwner", function(ply, ent) ent.m_PlayerCreator = ply end)
	hook.Add("PlayerSpawnedRagdoll", "HackReAssignOwner", function(ply, model, ent) ent.m_PlayerCreator = ply end)
	hook.Add("PlayerSpawnedSENT", "HackReAssignOwner", function(ply, ent) ent.m_PlayerCreator = ply end)
	hook.Add("PlayerSpawnedSWEP", "HackReAssignOwner", function(ply, ent) ent.m_PlayerCreator = ply end)
	hook.Add("PlayerSpawnedVehicle", "HackReAssignOwner", function(ply, ent) ent.m_PlayerCreator = ply end)
	hook.Add("PlayerSpawnedEffect", "HackReAssignOwner", function(ply, model, ent) ent.m_PlayerCreator = ply end)
	
	local function IsPossibleContraptionEntity(ent)
		if not IsValid(ent) then return false end
		local b = (string.find(ent:GetClass(), "phys") ~= nil
		or string.find(ent:GetClass(), "anchor") ~= nil
		or string.find(ent:GetClass(), "rope") ~= nil
		or string.find(ent:GetClass(), "gmod") ~= nil)
		--print("entity", ent, "contraption?", b)
		return b
	end

	local function IsPropProtected(ent, ply)
		
		local reason = ""
		local pac_sv_prop_protection = global_combat_prop_protection:GetBool()

		local prop_protected = ent:GetCreator():IsPlayer() and ent:GetCreator() ~= ply

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
	local function TooManyEnts(count)
		local playercount = player.GetCount()
		local hard_limit = raw_ent_limit:GetInt()
		local per_ply = per_ply_limit:GetInt()
		print(count .. " compared against hard limit " .. hard_limit .. " and " .. playercount .. " players*" .. per_ply .. " limit (" .. count*playercount .. " | " .. playercount*per_ply .. ")")
		if count > hard_limit then
			MsgC(Color(255,0,0), "TOO MANY ENTS. Beyond hard limit.\n")
			return true
		end
		if not game.SinglePlayer() then
			if count > per_ply_limit:GetInt() * playercount then
				MsgC(Color(255,0,0), "TOO MANY ENTS. Beyond per-player sending limit.\n")
				return true
			end
			if count * playercount > math.min(hard_limit, per_ply*playercount) then
				MsgC(Color(255,0,0), "TOO MANY ENTS. Beyond hard limit or player limit\n")
				return true
			end
		end
		return false
	end

	--consent check
	local function PlayerAllowsCalcView(ply)
		return grab_consents[ply] and calcview_consents[ply] --oops it's redundant but I prefer it this way
	end

	local function ApplyLockState(ent, bool) --Change the movement states and reset some other angle-related things
		--the grab imposes MOVETYPE_NONE and no collisions
		--reverting the state requires to reset the eyeang roll in case it was modified
		if ent:IsPlayer() then
			if bool then
				active_grabbed_ents[ent] = true
				ent:SetMoveType(MOVETYPE_NONE)
				ent:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
			else
				active_grabbed_ents[ent] = nil
				ent:SetMoveType(MOVETYPE_WALK)
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
				ent:SetMoveType(MOVETYPE_NONE)
				ent:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
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
		ply.pac_damage_scalings[part_uid] = {scale = scale, id = id, uid = part_uid}
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

	local function UpdateHealthBars(ply, num, barsize, layer, absorbfactor, part_uid, follow)
		local existing_uidlayer = true
		local healthvalue = 0
		if not ply.pac_healthbars then
			existing_uidlayer = false
			ply.pac_healthbars = {}
		end
		if not ply.pac_healthbars[layer] then
			existing_uidlayer = false
			ply.pac_healthbars[layer] = {}
		end
		if not ply.pac_healthbars[layer][part_uid] then
			existing_uidlayer = false
			ply.pac_healthbars[layer][part_uid] = num*barsize
			healthvalue = num*barsize
		end

		if (not existing_uidlayer) or follow then
			healthvalue = num*barsize
		end

		ply.pac_healtbar_uid_absorbfactor = ply.pac_healtbar_uid_absorbfactor or {}
		ply.pac_healtbar_uid_absorbfactor[part_uid] = absorbfactor

		if num == 0 then --remove
			ply.pac_healthbars[layer] = nil
			ply.pac_healtbar_uid_absorbfactor[part_uid] = nil
		elseif num > 0 then --add if follow or created
			ply.pac_healthbars[layer][part_uid] = healthvalue
			ply.pac_healtbar_uid_absorbfactor[part_uid] = absorbfactor
		end
		for checklayer,tbl in pairs(ply.pac_healthbars) do
			for uid,value in pairs(tbl) do
				if layer ~= checklayer and part_uid == uid then
					ply.pac_healthbars[checklayer][uid] = nil
				end
			end
		end

	end

	local function CalculateHealthBarUIDCombinedHP(ply, uid)
		
	end

	local function CalculateHealthBarLayerCombinedHP(ply, layer)
		
	end
	
	local function GatherExtraHPBars(ply)
		if not ply.pac_healthbars then return 0,nil end
		local built_tbl = {}
		local total_hp_value = 0
		
		for layer,tbl in pairs(ply.pac_healthbars) do
			built_tbl[layer] = {}
			local layer_total = 0
			for uid,value in pairs(tbl) do
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

						local absorbfactor = ply.pac_healtbar_uid_absorbfactor[uid]
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

						local remainder = math.max(0,remaining_dmg - ply.pac_healthbars[layer][uid])

						local breakthrough_dmg = math.min(remaining_dmg, value)
						
						if remaining_dmg > value then --break through one of the uid clusters
							surviving_layer = layer - 1
							ply.pac_healthbars[layer][uid] = 0
						else
							ply.pac_healthbars[layer][uid] = math.max(0, value - remaining_dmg)
						end

						local absorbfactor = ply.pac_healtbar_uid_absorbfactor[uid]
						side_effect_dmg = side_effect_dmg + breakthrough_dmg * absorbfactor
						
						remaining_dmg = math.max(0,remaining_dmg - value)
					end
					
				end
			end
		end
		
		return remaining_dmg,surviving_layer,side_effect_dmg
	end

	local function SendUpdateHealthBars(target)
		if not target:IsPlayer() or not target.pac_healthbars then return end
		net.Start("pac_update_healthbars")
		net.WriteEntity(target)
		net.WriteTable(target.pac_healthbars)
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
			local remaining_dmg,surviving_layer,side_effect_dmg = GetHPBarDamage(target, dmginfo:GetDamage())


			if dmginfo:GetInflictor():GetClass() == "pac_bullet_emitter" and hitscan_consents[target] == false then
				dmginfo:SetDamage(0)
			else
				local total_hp_value,built_tbl = GatherExtraHPBars(target)
				if surviving_layer == nil or total_hp_value == 0 or not built_tbl then --no shields = use the dmginfo base damage scaled with the cumulative mult

					if cumulative_mult < 0 then
						target:SetHealth(math.floor(math.Clamp(target:Health() + math.abs(dmginfo:GetDamage()),0,target:GetMaxHealth())))
						return true
					else
						dmginfo:SetDamage(remaining_dmg)
						if target.pac_healthbars then SendUpdateHealthBars(target) end
					end

				else --shields = use the calculated cumulative side effect damage from each uid's related absorbfactor

					if side_effect_dmg < 0 then
						target:SetHealth(math.floor(math.Clamp(target:Health() + math.abs(side_effect_dmg),0,target:GetMaxHealth())))
						return true
					else
						dmginfo:SetDamage(side_effect_dmg + remaining_dmg)
						SendUpdateHealthBars(target)
					end
					
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
		local ent_count = 0
		local ply_count = 0
		local ply_prog_count = 0
		for i,v in pairs(ents_hits) do
			if not (v:IsPlayer() or v:IsNPC() or string.find(v:GetClass(), "npc_")) and not tbl.PointEntities then ents_hits[i] = nil end
			if pre_excluded_ent_classes[v:GetClass()] or v:IsWeapon() or (v:IsNPC() and not tbl.NPC) or ((v ~= ply and v:IsPlayer() and not tbl.Players) and not (tbl.AffectSelf and v == ply)) then ents_hits[i] = nil
			else
				ent_count = ent_count + 1
				--print(v, "counted")
				if v:IsPlayer() then ply_count = ply_count + 1 end
			end
		end

		--dangerous conditions: absurd amounts of entities, damaging a large percentage of the server's players beyond a certain point
		if TooManyEnts(ent_count) or ((ply_count) > 12 and (ply_count > player_fraction:GetFloat() * player.GetCount())) then
			print("early exit")
			return false,false,nil,{},{}
		end

		local pac_sv_damage_zone_allow_dissolve = GetConVar("pac_sv_damage_zone_allow_dissolve"):GetBool()
		local pac_sv_prop_protection = global_combat_prop_protection:GetBool()
		
		local inflictor = dmg_info:GetInflictor()
		local attacker = dmg_info:GetAttacker()

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
			local dissolvable = true
			local prop_protected, reason = IsPropProtected(ent, attacker)
			local prop_protected_final = prop_protected and ent:GetCreator():IsPlayer() and damage_zone_consents[ent:GetCreator()] == false
			
			if ent:IsPlayer() then
				if not kill then dissolvable = false
				elseif damage_zone_consents[ent] == false then dissolvable = false end
			elseif inflictor == ent then
				dissolvable = false --do we allow that?
			end
			if ent:IsWeapon() and IsValid(ent:GetCreator()) then
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
			
			if ent:Health() == 0 then return false end --immediately exclude entities with 0 health
			local canhit = false --whether the policies allow the hit
			local prop_protected_consent = ent:GetCreator() ~= inflictor and ent ~= inflictor and ent:GetCreator():IsPlayer() and damage_zone_consents[ent:GetCreator()] == false-- and ent:GetCreator() ~= inflictor
			local contraption = IsPossibleContraptionEntity(ent)
			local bot_exception = true
			if ent:IsPlayer() then
				if ent:IsBot() then bot_exception = true end
			end
			--first pass: entity class blacklist
			if IsEntity(ent) and ((damageable_point_ent_classes[ent:GetClass()] ~= false) or ((damageable_point_ent_classes[ent:GetClass()] == nil) or (damageable_point_ent_classes[ent:GetClass()] == true))) then
				--second pass: the damagezone's settings
					--1.player hurt self if asked
				if (tbl.AffectSelf) and ent == inflictor then
					canhit = true
					--2.main target types : players, NPC, point entities
				elseif	((ent:IsPlayer() and tbl.Players) or (tbl.NPC and (ent:IsNPC() or string.find(ent:GetClass(), "npc") or ent.IsVJBaseSNPC or ent.IsDRGEntity)) or tbl.PointEntities)
						and --one of the base classes
						(damageable_point_ent_classes[ent:GetClass()] ~= false) --non-blacklisted class
						and --enforce prop protection
						(bot_exception or (ent:GetCreator() == inflictor or ent == inflictor or (ent:GetCreator() ~= inflictor and pac_sv_prop_protection and damage_zone_consents[ent:GetCreator()] == true) or not pac_sv_prop_protection))
						then
					canhit = true
					if ent:IsPlayer() and tbl.Players then
						--rules for players:
							--self can always hurt itself if asked to
						if (ent == inflictor and tbl.AffectSelf) then canhit = true
							--self shouldn't hurt itself if asked not to
						elseif (ent == inflictor and not tbl.AffectSelf) then canhit = false
							--other players need to consent, bots don't care about it
						elseif damage_zone_consents[ent] == true or ent:IsBot() then canhit = true
							--other players that didn't consent are excluded
						else canhit = false end

					elseif (tbl.NPC and damageable_point_ent_classes[ent:GetClass()] ~= false) or (tbl.PointEntities and (damageable_point_ent_classes[ent:GetClass()] == true)) then
						canhit = true
					end
					
					--apply prop protection
					if IsPropProtected(ent, inflictor) or prop_protected_consent then
						canhit = false
					end
					
				end
				
			end

			return canhit
		end

		local function IsLiving(ent) --players and NPCs
			return ent:IsPlayer() or (ent:IsNPC() or string.find(ent:GetClass(), "npc") or ent.IsVJBaseSNPC or ent.IsDRGEntity)
		end

		--final action to apply the DamageInfo
		local function DoDamage(ent)
			--we'll need to find out whether the damage will crack open a player's extra bars
			local de_facto_dmg = GetPredictedHPBarDamage(ent, tbl.Damage)

			local distance = (ent:GetPos()):Distance(pos)

			local fraction = math.pow(math.Clamp(1 - distance / math.Clamp(math.max(tbl.Radius, tbl.Length),1,50000),0,1),tbl.DamageFalloffPower)

			if tbl.DamageFalloff then
				dmg_info:SetDamage(fraction * tbl.Damage)
			end

			successful_hit_ents[ent] = true
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
			
			if tbl.DamageType == "heal" then
				
				ent:SetHealth(math.min(ent:Health() + tbl.Damage, math.max(ent:Health(), ent:GetMaxHealth())))
			elseif tbl.DamageType == "armor" then
				ent:SetArmor(math.min(ent:Armor() + tbl.Damage, math.max(ent:Armor(), ent:GetMaxArmor())))
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
				if kill then successful_kill_ents[ent] = true end
				
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
				
				--leave at a critical health
				if tbl.DoNotKill then
					local dmg_info2 = DamageInfo()
					
					dmg_info2:SetDamagePosition(ent:NearestPoint(pos))
					dmg_info2:SetReportedPosition(pos)
					dmg_info2:SetDamage( math.min(ent:Health() - tbl.CriticalHealth, tbl.Damage))
					dmg_info2:IsBulletDamage(tbl.Bullet)
					dmg_info2:SetDamageForce(Vector(0,0,0))
					
					dmg_info2:SetAttacker(attacker)
					
					dmg_info2:SetInflictor(inflictor)

					ent:TakeDamageInfo(dmg_info2)
					max_dmg = math.max(max_dmg, dmg_info2:GetDamage())
				
				--finally we reached the normal damage event!
				else
					if string.find(tbl.DamageType, "dissolve") and IsDissolvable(ent) and pac_sv_damage_zone_allow_dissolve then
						dissolve(ent, dmg_info:GetInflictor(), damage_types[tbl.DamageType])
					end
					dmg_info:SetDamagePosition(ent:NearestPoint(pos))
					dmg_info:SetReportedPosition(pos)
					ent:TakeDamageInfo(dmg_info)
					max_dmg = math.max(max_dmg, dmg_info:GetDamage())
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
					DoDamage(ent)
				end
			end
			if not hit and (oldhp > 0 and canhit) then hit = true end
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
		["ToolgunTracer"] = 10,
		["LaserTracer"] = 11
	}

	--second stage of force: apply
	local function ProcessForcesList(ents_hits, tbl, pos, ang, ply)
		local ent_count = 0
		for i,v in pairs(ents_hits) do
			if pre_excluded_ent_classes[v:GetClass()] or (v:IsNPC() and not tbl.NPC) or (v:IsPlayer() and not tbl.Players) then ents_hits[i] = nil
			else ent_count = ent_count + 1 end
		end

		if TooManyEnts(ent_count) then return end
		for _,ent in pairs(ents_hits) do

			local phys_ent
			if (ent ~= tbl.RootPartOwner or (tbl.AffectSelf and ent == tbl.RootPartOwner))
					and (
						ent:IsPlayer()
						or (string.find(ent:GetClass(), "npc") ~= nil)
						or ent:IsNPC()
						or physics_point_ent_classes[ent:GetClass()]
						or string.find(ent:GetClass(),"item_")
						or string.find(ent:GetClass(),"ammo_")
						or (ent:IsWeapon() and not IsValid(ent:GetOwner()))
					) then
				
				local is_phys = true
				if ent:GetPhysicsObject() ~= nil then
					phys_ent = ent:GetPhysicsObject()
					if (string.find(ent:GetClass(), "npc") ~= nil) then
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
				local distance = (ent_center - pos):Length()

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

				if is_phys and tbl.AccountMass then
					if not (string.find(ent:GetClass(), "npc") ~= nil) then
						addvel = addvel * (1 / math.max(phys_ent:GetMass(),0.1))
					else
						addvel = addvel
					end
					add_angvel = add_angvel * (1 / math.max(phys_ent:GetMass(),0.1))
				end

				if tbl.Falloff then
					dist_multiplier = math.Clamp(1 - distance / math.max(tbl.Radius, tbl.Length),0,1)
				end
				
				addvel = addvel * dist_multiplier
				add_angvel = add_angvel * dist_multiplier
				
				local unconsenting_owner = ent:GetCreator() ~= ply and force_consents[ent:GetCreator()] == false
				
				if (ent:IsPlayer() and tbl.Players) or (ent == ply and tbl.AffectSelf) then
					if (ent ~= ply and force_consents[ent] ~= false) or (ent == ply and tbl.AffectSelf) then
						phys_ent:SetVelocity(addvel)
						ent:SetVelocity(addvel)
					end

				elseif (physics_point_ent_classes[ent:GetClass()] or string.find(ent:GetClass(),"item_") or string.find(ent:GetClass(),"ammo_") or ent:IsWeapon()) and tbl.PhysicsProps then
					if not IsPropProtected(ent, ply) and not (global_combat_prop_protection:GetBool() and unconsenting_owner) then
						if IsValid(phys_ent) then
							ent:PhysWake()
							if islocaltorque then
								phys_ent:AddAngleVelocity(add_angvel)
							else
								add_angvel = phys_ent:WorldToLocalVector( add_angvel )
								phys_ent:ApplyTorqueCenter(add_angvel)
							end
							ent:SetPos(ent:GetPos() + Vector(0,0,0.0001)) --dumb workaround to fight against the ground friction reversing the forces
							phys_ent:SetVelocity(oldvel + addvel)
						end
					end
				elseif (ent:IsNPC() or string.find(ent:GetClass(), "npc") ~= nil) and tbl.NPC then
					if not IsPropProtected(ent, ply) and not global_combat_prop_protection:GetBool() and not unconsenting_owner then
						if phys_ent:GetVelocity():Length() > 500 then
							local vec = oldvel + addvel
							local clamp_vec = vec:GetNormalized()*500
							ent:SetVelocity(Vector(0.7 * clamp_vec.x,0.7 * clamp_vec.y,clamp_vec.z)*math.Clamp(1.5*(pos - ent_center):Length()/tbl.Radius,0,1)) --more jank, this one is to prevent some of the weird sliding of npcs by lowering the force as we get closer
							
						else ent:SetVelocity(oldvel + addvel) end
					end
				else
					if not IsPropProtected(ent, ply) and not global_combat_prop_protection:GetBool() and not unconsenting_owner then
						phys_ent:SetVelocity(oldvel + addvel)
					end
				end
				hook.Run("PhysicsUpdate", ent)
				hook.Run("PhysicsUpdate", phys_ent)
			end
			
		end
	end
	--first stage of force: look for targets and determine force amount if continuous
	local function ImpulseForce(tbl, pos, ang, ply)
		if tbl.Continuous then
			tbl.BaseForce = tbl.BaseForce * FrameTime() * 3.3333 --weird value to equalize how 600 cancels out gravity
			tbl.AddedVectorForce = tbl.AddedVectorForce * FrameTime() * 3.3333
			tbl.Torque = tbl.Torque * FrameTime() * 3.3333
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
	end


	--consent message from clients
	net.Receive("pac_signal_player_combat_consent", function(len,ply)
		local grab = net.ReadBool() -- GetConVar("pac_client_grab_consent"):GetBool()
		local damagezone = net.ReadBool() -- GetConVar("pac_client_damage_zone_consent"):GetBool()
		local calcview = net.ReadBool() -- GetConVar("pac_client_lock_camera_consent"):GetBool()
		local force = net.ReadBool() -- GetConVar("pac_client_force_consent"):GetBool()
		local hitscan = net.ReadBool() -- GetConVar("pac_client_hitscan_consent"):GetBool()
		grab_consents[ply] = grab
		damage_zone_consents[ply] = damagezone
		calcview_consents[ply] = calcview
		force_consents[ply] = force
		hitscan_consents[ply] = hitscan
	end)

	--lock break order from client
	net.Receive("pac_signal_stop_lock", function(len,ply)
		ApplyLockState(ply, false)
		MsgC(Color(0,255,255), "Requesting lock break!\n")
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
		for _,v in pairs(string.Explode(";",argStr)) do
			damageable_point_ent_classes[v] = true
			print("added " .. v .. " to the entities you can damage")
		end
		PrintTable(damageable_point_ent_classes)
	end)

	concommand.Add("pac_damage_zone_blacklist_entity_class", function(ply, cmd, args, argStr)
		for _,v in pairs(string.Explode(";",argStr)) do
			damageable_point_ent_classes[v] = false
			print("removed " .. v .. " from the entities you can damage")
		end
		PrintTable(damageable_point_ent_classes)
	end)

	local nextchecklock = CurTime()
	hook.Add("Tick", "pac_checklocks", function()
		if nextchecklock > CurTime() then return else nextchecklock = CurTime() + 0.14 end
		--go through every entity and check if they're still active, if beyond 0.5 seconds we nil out. this is the closest to a regular check
		for ent,bool in pairs(active_grabbed_ents) do
			if ent.grabbed_by or bool then
				if ent.grabbed_by_time + 0.5 < CurTime() then --restore the movetype
					local grabber = ent.grabbed_by
					ent.grabbed_by_uid = nil
					ent.grabbed_by = nil
					grabber.grabbed_ents[ent] = false
					ApplyLockState(ent, false)
					active_grabbed_ents[ent] = nil
				end
			end
		end
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

	function DeclareForceReceivers()
		util.AddNetworkString("pac_request_force")
		--the force part impulse request net message
		net.Receive("pac_request_force", function(len,ply)
			--server allow
			if not force_allow:GetBool() then return end
			if not PlayerIsCombatAllowed(ply) then return end

			local tbl = {}
			local pos = net.ReadVector()
			local ang = net.ReadAngle()
			tbl.Locus_pos = net.ReadVector()
			local on = net.ReadBool()

			tbl.UniqueID = net.ReadString()
			tbl.RootPartOwner = net.ReadEntity()

			tbl.HitboxMode = table.KeyFromValue(force_hitbox_ids, net.ReadUInt(4))
			tbl.BaseForceAngleMode = table.KeyFromValue(base_force_mode_ids, net.ReadUInt(3))
			tbl.VectorForceAngleMode = table.KeyFromValue(vect_force_mode_ids, net.ReadUInt(2))
			tbl.TorqueMode = table.KeyFromValue(ang_torque_mode_ids, net.ReadUInt(2))

			tbl.Length = net.ReadInt(16)
			tbl.Radius = net.ReadInt(16)

			tbl.BaseForce = net.ReadInt(18)
			tbl.AddedVectorForce = net.ReadVector()
			tbl.Torque = net.ReadVector()

			tbl.Continuous = net.ReadBool()
			tbl.AccountMass = net.ReadBool()
			tbl.Falloff = net.ReadBool()
			tbl.AffectSelf = net.ReadBool()
			tbl.Players = net.ReadBool()
			tbl.PhysicsProps = net.ReadBool()
			tbl.NPC = net.ReadBool()

			--server limits
			tbl.Radius = math.Clamp(tbl.Radius,-force_max_radius:GetInt(),force_max_radius:GetInt())
			tbl.Length = math.Clamp(tbl.Length,-force_max_length:GetInt(),force_max_length:GetInt())
			tbl.BaseForce = math.Clamp(tbl.BaseForce,-force_max_amount:GetInt(),force_max_amount:GetInt())


			if on then
				if tbl.Continuous then
					hook.Add("Tick", "pac_force_hold"..tbl.UniqueID, function()
						ImpulseForce(tbl, pos, ang, ply)

					end)
					
					active_force_ids[tbl.UniqueID] = CurTime()
				else
					ImpulseForce(tbl, pos, ang, ply)
					active_force_ids[tbl.UniqueID] = nil
				end
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
	end

	function DeclareDamageZoneReceivers()
		util.AddNetworkString("pac_request_zone_damage")
		util.AddNetworkString("pac_hit_results")
		net.Receive("pac_request_zone_damage", function(len,ply)
			--server allow
			if not damagezone_allow:GetBool() then return end
			if not PlayerIsCombatAllowed(ply) then return end

			local pos = net.ReadVector()
			local ang = net.ReadAngle()
			local tbl = {}

			tbl.Damage = net.ReadUInt(28)
			tbl.Length = net.ReadInt(16)
			tbl.Radius = net.ReadInt(16)

			tbl.AffectSelf = net.ReadBool()
			tbl.NPC = net.ReadBool()
			tbl.Players = net.ReadBool()
			tbl.PointEntities = net.ReadBool()

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
			tbl.CriticalHealth = net.ReadUInt(16)
			tbl.RemoveNPCWeaponsOnKill = net.ReadBool()

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

			dmg_info:SetDamageType(damage_types[tbl.DamageType])

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
			net.WriteBool(hit)
			net.WriteBool(kill)
			net.WriteFloat(highest_dmg)
			net.WriteTable(successful_hit_ents)
			net.WriteTable(successful_kill_ents)
			net.Broadcast()
		end)
	end

	function DeclareLockReceivers()
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
			local targ_ent = net.ReadEntity()
			local auth_ent = net.ReadEntity()
			local override_viewposition = net.ReadBool()
			local alt_pos = net.ReadVector()
			local alt_ang = net.ReadAngle()
			local ask_drawviewer = net.ReadBool()

			local prop_protected, reason = IsPropProtected(targ_ent, ply)
			
			local unconsenting_owner = targ_ent:GetCreator() ~= ply and (grab_consents[targ_ent:GetCreator()] == false or (targ_ent:IsPlayer() and grab_consents[targ_ent] == false))
			local calcview_unconsenting = targ_ent:GetCreator() ~= ply and (calcview_consents[targ_ent:GetCreator()] == false or (targ_ent:IsPlayer() and calcview_consents[targ_ent] == false))

			if unconsenting_owner or (global_combat_prop_protection:GetBool() and prop_protected) then return end

			local targ_ent_owner = targ_ent:GetCreator() or targ_ent
			local auth_ent_owner = ply

			auth_ent_owner.grabbed_ents = auth_ent_owner.grabbed_ents or {}

			local consent_break_condition = false

			if grab_consents[targ_ent_owner] == false then --if the target player is non-consenting
				if targ_ent_owner == auth_ent_owner then consent_break_condition = false  --player can still grab his owned entities
				elseif targ_ent:IsPlayer() then --if not the same player, we cannot grab
					consent_break_condition = true
					breakup_condition = breakup_condition .. "cannot grab another player if they don't consent to grabs, "
				elseif global_combat_prop_protection:GetBool() and targ_ent:GetCreator() ~= ply then
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
				if (auth_ent_owner ~= targ_ent and auth_ent_owner.grabbed_ents[targ_ent] == true) then
					did_grab = false
					need_breakup = true
					breakup_condition = breakup_condition .. "mutual grab prevention, "
				end
			end

			if did_grab then
				

				if targ_ent:IsPlayer() and targ_ent:InVehicle() then --yank player out of vehicle
					print("Kicking " .. targ_ent:Nick() .. " out of vehicle to be grabbed!")
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
								else print("skipping") end
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
				
				ApplyLockState(targ_ent, true)
				if targ_ent:GetClass() == "prop_ragdoll" then targ_ent:GetPhysicsObject():SetPos(pos) end

				--@@note lock assignation! IMPORTANT
				if is_first_time then --successful, first
					auth_ent_owner.grabbed_ents[targ_ent] = true
					targ_ent.grabbed_by = auth_ent_owner
					targ_ent.grabbed_by_uid = lockpart_UID
					print(auth_ent, "grabbed", targ_ent, "owner grabber is", auth_ent_owner)
				end
				targ_ent.grabbed_by_time = CurTime()
			else
				auth_ent_owner.grabbed_ents[targ_ent] = nil
				targ_ent.grabbed_by_uid = nil
				targ_ent.grabbed_by = nil
			end

			if need_breakup then
				print("stop this now! reason: " .. breakup_condition)
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

			targ_ent:SetAngles(ang)
			ApplyLockState(targ_ent, false)
			
		end)
	end

	function DeclareHitscanReceivers()
		util.AddNetworkString("pac_hitscan")
		net.Receive("pac_hitscan", function(len,ply)

			if not hitscan_allow:GetBool() then return end
			if not PlayerIsCombatAllowed(ply) then return end

			local bulletinfo = {}
			local affect_self = net.ReadBool()
			bulletinfo.Src = net.ReadVector()
			local dir = net.ReadAngle()
			bulletinfo.Dir = dir:Forward()
			
			bulletinfo.dmgtype_str = table.KeyFromValue(damage_ids, net.ReadUInt(7))
			bulletinfo.dmgtype = damage_types[bulletinfo.dmgtype_str]
			bulletinfo.Spread = net.ReadVector()
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
	
			bulletinfo.Callback = function(atk, trc, dmg)
				dmg:SetDamageType(bulletinfo.dmgtype)
				if trc.Hit and IsValid(trc.Entity) then
					local distance = (trc.HitPos):Distance(trc.StartPos)
					local fraction = math.Clamp(1 - (1-bulletinfo.DamageFalloffFraction)*(distance / bulletinfo.DamageFalloffDistance),bulletinfo.DamageFalloffFraction,1)
					local ent = trc.Entity

					if bulletinfo.dmgtype_str == "heal" then
						dmg:SetDamageType(0)
						ent:SetHealth(math.min(ent:Health() + fraction * dmg:GetDamage(), math.max(ent:Health(), ent:GetMaxHealth())))
						dmg:SetDamage(0)
						return
					elseif bulletinfo.dmgtype_str == "armor" then
						dmg:SetDamageType(0)
						ent:SetArmor(math.min(ent:Armor() + fraction * dmg:GetDamage(), math.max(ent:Armor(), ent:GetMaxArmor())))
						dmg:SetDamage(0)
						return
					end
					if bulletinfo.DamageFalloff and trc.Hit and IsValid(trc.Entity) then
						if not bulletinfo.dmgtype_str == "heal" and not bulletinfo.dmgtype_str == "armor" then
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
	
	function DeclareHealthModifierReceivers()
		util.AddNetworkString("pac_request_healthmod")
		util.AddNetworkString("pac_update_healthbars")
		net.Receive("pac_request_healthmod", function(len,ply)
			if not healthmod_allow:GetBool() then return end
			local part_uid = net.ReadString()
			local mod_id = net.ReadString()
			local action = net.ReadString()
			
			if action == "MaxHealth" then
				if not healthmod_allow:GetBool() then return end
				local num = net.ReadUInt(32)
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
				
				UpdateHealthBars(ply, num, barsize, layer, absorbfactor, part_uid, follow)
	
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

	concommand.Add("pac_sv_combat_reinitialize_missing_receivers", function()
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
	end)

	net.Receive("pac_request_blocked_parts", function(len, ply)
		net.Start("pac_inform_blocked_parts")
		net.WriteTable(FINAL_BLOCKED_COMBAT_FEATURES)
		net.Send(ply)
	end)
end

if CLIENT then
	CreateConVar("pac_client_grab_consent", "0", {FCVAR_ARCHIVE and FCVAR_USERINFO}, "Whether you want to consent to being grabbed by other players in PAC3 with the lock part")
	CreateConVar("pac_client_lock_camera_consent", "0", {FCVAR_ARCHIVE and FCVAR_USERINFO}, "Whether you want to consent to having lock parts override your view")
	CreateConVar("pac_client_damage_zone_consent", "0", {FCVAR_ARCHIVE and FCVAR_USERINFO}, "Whether you want to consent to receiving damage by other players in PAC3 with the damage zone part")
	CreateConVar("pac_client_force_consent", "0", {FCVAR_ARCHIVE and FCVAR_USERINFO}, "Whether you want to consent to pac3 physics forces")
	CreateConVar("pac_client_hitscan_consent", "0", {FCVAR_ARCHIVE and FCVAR_USERINFO}, "Whether you want to consent to receiving damage by other players in PAC3 with the hitscan part.")
	
	local function SendConsents()
		net.Start("pac_signal_player_combat_consent")
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
	concommand.Add("pac_inform_about_blocked_parts", RequestBlockedParts)

	net.Receive("pac_inform_blocked_parts", function()
		pac.Blocked_Combat_Parts = net.ReadTable()
		print("Are these pac combat parts blocked?")

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

	local consent_cvars = {"pac_client_grab_consent", "pac_client_lock_camera_consent", "pac_client_damage_zone_consent", "pac_client_force_consent", "pac_client_hitscan_consent"}
	for _,cmd in ipairs(consent_cvars) do
		cvars.AddChangeCallback(cmd, SendConsents)
	end

	CreateConVar("pac_break_lock_verbosity", "3", FCVAR_ARCHIVE, "How much info you want for the PAC3 lock notifications\n3:full information\n2:grabbing player + basic reminder of the lock break command\n1:grabbing player\n0:suppress the notifications")
	

	concommand.Add( "pac_stop_lock", function()
		net.Start("pac_signal_stop_lock")
		net.SendToServer()
	end, "asks the server to breakup any lockpart hold on your player")

	concommand.Add( "pac_break_lock", function()
		net.Start("pac_signal_stop_lock")
		net.SendToServer()
	end, "asks the server to breakup any lockpart hold on your player")
	
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
end

