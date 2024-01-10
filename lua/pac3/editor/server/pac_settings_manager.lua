util.AddNetworkString("pac_send_sv_cvar")
util.AddNetworkString("pac_request_sv_cvars")
util.AddNetworkString("pac_send_cvars_to_client")

--cvars used by settings.lua
local pac_server_cvars = {
	{"pac_sv_prop_protection", "Enforce generic prop protection for player-owned props and physics entities based on client consents.", "", -1, 0, 200},
	{"pac_sv_combat_whitelisting", "Restrict new pac3 combat (damage zone, lock, force, hitscan, health modifier) to only whitelisted users.", "off = Blacklist mode: Default players are allowed to use the combat features\non = Whitelist mode: Default players aren't allowed to use the combat features until set to Allowed", -1, 0, 200},
	{"pac_sv_block_combat_features_on_next_restart", "Block the combat features that aren't enabled. WARNING! Requires a restart!\nThis applies to damage zone, lock, force, hitscan and health modifier parts", "You can go to the console and set pac_sv_block_combat_features_on_next_restart to 2 to block everything.\nif you re-enable a blocked part, update with pac_sv_combat_reinitialize_missing_receivers", -1, 0, 200},
	{"pac_sv_combat_enforce_netrate_monitor_serverside", "Enable serverside monitoring prints for allowance and rate limiters", "Enable serverside monitoring prints.\n0=let clients enforce their netrate allowance before sending messages\n1=the server will receive net messages and print the outcome.", -1, 0, 200},
	{"pac_sv_combat_enforce_netrate", "Rate limiter (milliseconds)", "The milliseconds delay between net messages.\nIf this is 0, the allowance won't matter, otherwise early net messages use up the player's allowance.\nThe allowance regenerates gradually when unused, and one unit gets spent if the message is earlier than the rate limiter's delay.", 0, 0, 1000},
	{"pac_sv_combat_enforce_netrate_buffersize", "Allowance, in number of messages", "Allowance:\nIf this is 0, only the time limiter will stop pac combat messages if they're too fast.\nOtherwise, players trying to use a pac combat message earlier will deduct 1 from the player's allowance, and only stop the messages if the allowance reaches 0.", 0, 0, 400},
	{"pac_sv_entity_limit_per_combat_operation", "Hard entity limit to cutoff damage zones and force parts", "If the number of entities selected is more than this value, the whole operation gets dropped.\nThis is so that the server doesn't have to send huge amounts of entity updates to everyone.", 0, 0, 1000},
	{"pac_sv_entity_limit_per_player_per_combat_operation", "Entity limit per player to cutoff damage zones and force parts", "When in multiplayer, with the server's player count, if the number of entities selected is more than this value, the whole operation gets dropped.\nThis is so that the server doesn't have to send huge amounts of entity updates to everyone.", 0, 0, 500},
	{"pac_sv_player_limit_as_fraction_to_drop_damage_zone", "block damage zones targeting this fraction of players", "This applies when the zone covers more than 12 players. 0 is 0% of the server, 1 is 100%\nFor example, if this is at 0.5, there are 24 players and a damage zone covers 13 players, it will be blocked.", 2, 0, 1},
	{"pac_sv_combat_distance_enforced", "distance to block combat actions that are too far", "The distance is compared between the action's origin and the player's position.\n0 to ignore.", 0, 0, 64000},

	{"pac_sv_lock", "Allow lock part", "", -1, 0, 200},
	{"pac_sv_lock_teleport", "Allow lock part teleportation", "", -1, 0, 200},
	{"pac_sv_lock_grab", "Allow lock part grabbing", "", -1, 0, 200},
	{"pac_sv_lock_allow_grab_ply", "Allow grabbing players", "", -1, 0, 200},
	{"pac_sv_lock_allow_grab_npc", "Allow grabbing NPCs", "", -1, 0, 200},
	{"pac_sv_lock_allow_grab_ent", "Allow grabbing other entities", "", -1, 0, 200},
	{"pac_sv_lock_max_grab_radius", "Max lock part grab range", "", 0, 0, 5000},

	{"pac_sv_damage_zone", "Allow damage zone", "", -1, 0, 200},
	{"pac_sv_damage_zone_max_radius", "Max damage zone radius", "", 0, 0, 32767},
	{"pac_sv_damage_zone_max_length", "Max damage zone length", "", 0, 0, 32767},
	{"pac_sv_damage_zone_max_damage", "Max damage zone damage", "", 0, 0, 268435455},
	{"pac_sv_damage_zone_allow_dissolve", "Allow damage entity dissolvers", "", -1, 0, 200},

	{"pac_sv_force", "Allow force part", "", -1, 0, 200},
	{"pac_sv_force_max_radius", "Max force radius", "", 0, 0, 32767},
	{"pac_sv_force_max_length", "Max force length", "", 0, 0, 32767},
	{"pac_sv_force_max_length", "Max force amount", "", 0, 0, 10000000},

	{"pac_sv_hitscan", "allow serverside bullets", "", -1, 0, 200},
	{"pac_sv_hitscan_max_damage", "Max hitscan damage (per bullet, per multishot,\ndepending on the next setting)", "", 0, 0, 268435455},
	{"pac_sv_hitscan_divide_max_damage_by_max_bullets", "force hitscans to distribute their total damage accross bullets. if off, every bullet does full damage; if on, adding more bullets doesn't do more damage", "", -1, 0, 200},
	{"pac_sv_hitscan_max_bullets", "Maximum number of bullets for hitscan multishots", "", 0, 0, 500},

	{"pac_sv_projectiles", "allow serverside physical projectiles", "", -1, 0, 200},
	{"pac_sv_projectile_allow_custom_collision_mesh", "allow custom collision meshes for physical projectiles", "", -1, 0, 200},
	{"pac_sv_projectile_max_phys_radius", "Max projectile physical radius", "", 0, 0, 4095},
	{"pac_sv_projectile_max_damage_radius", "Max projectile damage radius", "", 0, 0, 4095},
	{"pac_sv_projectile_max_attract_radius", "Max projectile attract radius", "", 0, 0, 100000000},
	{"pac_sv_projectile_max_damage", "Max projectile damage", "", 0, 0, 100000000},
	{"pac_sv_projectile_max_speed", "Max projectile speed", "", 0, 0, 50000},
	{"pac_sv_projectile_max_mass", "Max projectile mass", "", 0, 0, 500000},

	{"pac_sv_health_modifier", "Allow health modifier part", "", -1, 0, 200},
	{"pac_sv_health_modifier_allow_maxhp", "Allow changing max health and max armor", "", -1, 0, 200},
	{"pac_sv_health_modifier_min_damagescaling", "Minimum combined damage multiplier allowed.\nNegative values lead to healing from damage.", "", 2, -10, 1},
	{"pac_sv_health_modifier_extra_bars", "Allow extra healthbars", "What are those? It's like an armor layer that takes damage before it gets applied to the entity.", -1, 0, 200},


	{"pac_modifier_blood_color", "Blood", "", -1, 0, 200},
	{"pac_allow_mdl", "MDL", "", -1, 0, 200},
	{"pac_allow_mdl_entity", "Entity MDL", "", -1, 0, 200},
	{"pac_modifier_model", "Entity model", "", -1, 0, 200},
	{"pac_modifier_size", "Entity size", "", -1, 0, 200},

	--the playermovement enabler policy cvar is a form, not a slider nor a bool
	{"pac_player_movement_allow_mass", "Allow Modify Mass", "", -1, 0, 200},
	{"pac_player_movement_min_mass", "Mimnimum mass players can set for themselves", "", 0, 0, 1000000},
	{"pac_player_movement_max_mass", "Maximum mass players can set for themselves", "", 0, 0, 1000000},
	{"pac_player_movement_physics_damage_scaling", "Allow damage scaling of physics damage based on player's mass", "", -1, 0, 200},

	{"pac_sv_draw_distance", "PAC server draw distance", "", 0, 0, 500000},
	{"pac_submit_spam", "Limit pac_submit to prevent spam", "", -1, 0, 200},
	{"pac_submit_limit", "limit of pac_submits", "", 0, 0, 100},
	{"pac_onuse_only_force", "Players need to +USE on others to reveal outfits", "", -1, 0, 200},

	{"sv_pac_webcontent_allow_no_content_length", "Players need to +USE on others to reveal outfits", "", -1, 0, 200},
	{"pac_to_contraption_allow", "Allow PAC to contraption tool", "", -1, 0, 200},
	{"pac_max_contraption_entities", "Entity limit for PAC to contraption", "", 0, 0, 200},
	{"pac_restrictions", "restrict PAC editor camera movement", "", -1, 0, 200},
}

net.Receive("pac_send_sv_cvar", function(len,ply)
	if not (game.SinglePlayer() or ply:IsAdmin()) then ply:ChatPrint( "Only admins can change pac3 server settings!" ) return end
	local cmd = net.ReadString()
	local val = net.ReadString()
	if not cmd then return end

	if GetConVar(cmd) then
		GetConVar(cmd):SetString(val)
	end

end)

net.Receive("pac_request_sv_cvars", function (len, ply)
	local cvars_tbl = {}
	for _, tbl in ipairs(pac_server_cvars) do
		local cmd = tbl[1]
		if GetConVar(cmd) then
			cvars_tbl[cmd] = GetConVar(cmd):GetString()
		end
	end
	timer.Simple(0, function()
		net.Start("pac_send_cvars_to_client")
		net.WriteTable(cvars_tbl)
		net.Send(ply)
	end)

end)
