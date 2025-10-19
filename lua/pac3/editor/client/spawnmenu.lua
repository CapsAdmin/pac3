local L = pace.LanguageString

concommand.Add("pac_wear_parts", function(ply, _, _, file)
	if file then
		file = string.Trim(file)
		if file ~= "" then
			pace.LoadParts(string.Trim(string.Replace(file, "\"", "")), true)
		end
	end

	pace.WearParts()
end,
function(cmd, args)
	-- Replace \ with /
	args = string.Trim(string.Replace(args, "\\", "/"))

	-- Find path
	local path = ""
	local slashPos = string.find(args, "/[^/]*$")
	if slashPos then
		-- Set path to the directory without the file name
		path = string.sub(args, 1, slashPos)
	end

	-- Find files and directories
	local files, dirs = file.Find("pac3/" .. args .. "*", "DATA")
	if not dirs then return end

	-- Format directories
	for k, v in ipairs(dirs) do
		dirs[k] = v .. "/"
	end

	-- Format results
	for k, v in ipairs(table.Add(dirs, files)) do
		dirs[k] = cmd .. " " .. path .. v
	end

	return dirs
end)

concommand.Add("pac_clear_parts", function()
	pace.ClearParts()
end)

concommand.Add("pac_panic", function()
	pac.Panic()
end)

net.Receive("pac_spawn_part", function()
	if not pace.current_part:IsValid() then return end

	local mdl = net.ReadString()

	if pace.close_spawn_menu then
		pace.RecordUndoHistory()
		pace.Call("VariableChanged", pace.current_part, "Model", mdl)

		if g_SpawnMenu:IsVisible() then
			g_SpawnMenu:Close()
		end

		pace.close_spawn_menu = false
	elseif pace.current_part.ClassName ~= "model" then
		local name = mdl:match(".+/(.+)%.mdl")

		pace.RecordUndoHistory()
		pace.Call("CreatePart", "model2", name, mdl)
	else
		pace.RecordUndoHistory()
		pace.Call("VariableChanged", pace.current_part, "Model", mdl)
	end
end)

pace.SpawnlistBrowser = NULL

function pace.ClientOptionsMenu(self)
	if not IsValid(self) then return end

	self:Button(L"show editor", "pac_editor")
	self:CheckBox(L"enable", "pac_enable")
	self:Button(L"clear", "pac_clear_parts")
	self:Button(L"wear on server", "pac_wear_parts" )
	self:CheckBox(L"raw file sizes", "pac_browser_display_raw_file_size"):SetTooltip("fixes sorting")

	local browser = self:AddControl("pace_browser", {})

	browser.OnLoad = function(node)
		pace.LoadParts(node.FileName, true)
	end

	if #file.Find("pac3/sessions/*", "DATA") > 0 then
		browser:SetDir("sessions/")
	else
		browser:SetDir("")
	end

	browser:SetSize(400,480)

	pace.SpawnlistBrowser = browser

	self:Button(L"request outfits", "pac_request_outfits")
end

CreateClientConVar("pac_limit_sounds_draw_distance", 20000, true, false, "Overall multiplier for PAC3 sounds")
cvars.AddChangeCallback("pac_limit_sounds_draw_distance", function(_,_,val)
	if not isnumber(val) then val = 0 end
	pac.sounds_draw_dist_sqr = val * val
end)
pac.sounds_draw_dist_sqr = math.pow(GetConVar("pac_limit_sounds_draw_distance"):GetInt(), 2)

CreateClientConVar("pac_volume", 1, true, false, "Overall multiplier for PAC3 sounds",0,1)
cvars.AddChangeCallback("pac_volume", function(_,_,val)
	pac.volume = math.pow(math.Clamp(val,0,1),2) --adjust for the nonlinearity of volume
	pac.ForceUpdateSoundVolumes()
end)

pac.volume = math.pow(math.Clamp(GetConVar("pac_volume"):GetFloat(),0,1), 2)

concommand.Add("pac_stopsound", function()
	pac.StopSound()
end)

function pace.ClientSettingsMenu(self)
	if not IsValid(self) then return end
	self:Help(L"Performance"):SetFont("DermaDefaultBold")
		self:CheckBox(L"Enable PAC", "pac_enable")
		self:NumSlider(L"Draw distance:", "pac_draw_distance", 0, 20000, 0)
		self:NumSlider(L"Max render time: ", "pac_max_render_time", 0, 100, 0)

	self:Help(L"Sounds"):SetFont("DermaDefaultBold")
		self:NumSlider(L"Sounds volume", "pac_volume", 0, 1, 2)
		self:Button(L"Stop sounds", "pac_stopsound")

	self:Help(L"Part limiters"):SetFont("DermaDefaultBold")
		self:NumSlider(L"Sounds draw distance:", "pac_limit_sounds_draw_distance", 0, 20000, 0)
		self:NumSlider(L"2D text draw distance:", "pac_limit_text_2d_draw_distance", 0, 20000, 0)
		self:NumSlider(L"Sunbeams draw distance: ", "pac_limit_sunbeams_draw_distance", 0, 20000, 0)
		self:NumSlider(L"Shake draw distance: ", "pac_limit_shake_draw_distance", 0, 20000, 0)
		self:NumSlider(L"Shake max duration: ", "pac_limit_shake_duration", 0, 120, 0)
		self:NumSlider(L"Shake max amplitude: ", "pac_limit_shake_amplitude", 0, 1000, 0)
		self:NumSlider(L"Particles max per emission: ", "pac_limit_particles_per_emission", 0, 5000, 0)
		self:NumSlider(L"Particles max per emitter: ", "pac_limit_particles_per_emitter", 0, 10000, 0)
end

local default = "0"
if game.SinglePlayer() then default = "1" end
CreateConVar("pac_sv_nearest_life", default, {FCVAR_REPLICATED}, "Enables nearest_life aimparts and bones, abusable for aimbot-type setups (which would already be possible with CS lua)")
CreateConVar("pac_sv_nearest_life_allow_sampling_from_parts", "1", {FCVAR_REPLICATED}, "Restricts nearest_life aimparts and bones search to the player itself to prevent sampling from arbitrary positions\n0=sampling can only start from the player itself")
CreateConVar("pac_sv_nearest_life_allow_bones", default, {FCVAR_REPLICATED}, "Restricts nearest_life bones, preventing placement on external entities' position")
CreateConVar("pac_sv_nearest_life_allow_targeting_players", "1", {FCVAR_REPLICATED}, "Restricts nearest_life aimparts and bones to forbid targeting players\n0=no target players")
CreateConVar("pac_sv_nearest_life_max_distance", "5000", {FCVAR_REPLICATED}, "Restricts the radius for nearest_life aimparts and bones")
CreateConVar("pac_submit_spam", "1", {FCVAR_REPLICATED})
CreateConVar("pac_allow_blood_color", "1", {FCVAR_REPLICATED})
CreateConVar("pac_sv_prop_outfits", "1", {FCVAR_REPLICATED})

function pace.AdminSettingsMenu(self)
	if not LocalPlayer():IsAdmin() then return end
	if not IsValid(self) then return end
	self:Button("Open PAC3 settings menu (Admin)", "pace_settings")
	if GetConVar("pac_sv_block_combat_features_on_next_restart"):GetInt() ~= 0 then
		self:Help(L"Remember that you have to reinitialize combat parts if you want to enable those that were blocked."):SetFont("DermaDefaultBold")
		self:Button("Reinitialize combat parts", "pac_sv_reinitialize_missing_combat_parts_remotely")
	end

	self:Help(L"PAC3 outfits: general server policy"):SetFont("DermaDefaultBold")
		self:NumSlider(L"Server Draw distance:", "pac_sv_draw_distance", 0, 20000, 0)
		self:CheckBox(L"Prevent spam with pac_submit", "pac_submit_spam")
		self:CheckBox(L"Players need to +USE on others to reveal outfits", "pac_onuse_only_force")
		self:CheckBox(L"Restrict editor camera", "pac_restrictions")
		self:CheckBox(L"Allow MDL zips", "pac_allow_mdl")
		self:CheckBox(L"Allow MDL zips for entity", "pac_allow_mdl_entity")
		self:CheckBox(L"Allow entity model modifier", "pac_modifier_model")
		self:CheckBox(L"Allow entity size modifier", "pac_modifier_size")
		self:CheckBox(L"Allow blood color modifier", "pac_allow_blood_color")
		self:NumSlider(L"Allow prop / other player outfits", "pac_sv_prop_outfits", 0, 2, 0)
		self:CheckBox(L"Allow Nearest Life", "pac_sv_nearest_life")
		self:CheckBox(L"Allow NL sampling anywhere", "pac_sv_nearest_life_allow_sampling_from_parts")
		self:CheckBox(L"Allow NL on bones", "pac_sv_nearest_life_allow_bones")
		self:CheckBox(L"Allow NL targeting players", "pac_sv_nearest_life_allow_targeting_players")
		self:NumSlider(L"Max NL distance", "pac_sv_nearest_life_max_distance", 0, 20000, 0)
	self:Help(""):SetFont("DermaDefaultBold")--spacers
	self:Help(""):SetFont("DermaDefaultBold")

	self:Help(L"PAC3 combat: general server policy"):SetFont("DermaDefaultBold")
		self:NumSlider(L"Rate limiter", "pac_sv_combat_enforce_netrate", 0, 1000, 0)
		self:NumSlider(L"Distance limiter", "pac_sv_combat_distance_enforced", 0, 64000, 0)
		self:NumSlider(L"Allowance, in number of messages", "pac_sv_combat_enforce_netrate_buffersize", 0, 400, 0)
		self:CheckBox(L"Use general prop protection based on player consents", "pac_sv_prop_protection")
		self:NumSlider(L"Entity limit per combat action", "pac_sv_entity_limit_per_combat_operation", 0, 1000, 0)
		self:NumSlider(L"Entity limit per player", "pac_sv_entity_limit_per_player_per_combat_operation", 0, 500, 0)
		self:CheckBox(L"Only specifically allowed users can do pac3 combat actions", "pac_sv_combat_whitelisting")
	self:Help(""):SetFont("DermaDefaultBold")--spacers
	self:Help(""):SetFont("DermaDefaultBold")
		
	self:Help(L"Combat parts (more detailed settings in the full editor settings menu)"):SetFont("DermaDefaultBold")
		self:Help(L"Damage Zones"):SetFont("DermaDefaultBold")
		self:CheckBox(L"Enable damage zones", "pac_sv_damage_zone")
		self:NumSlider(L"Max damage", "pac_sv_damage_zone_max_damage", 0, 268435455, 0)
		self:NumSlider(L"Max radius", "pac_sv_damage_zone_max_radius", 0, 32767, 0)
		self:NumSlider(L"Max length", "pac_sv_damage_zone_max_length", 0, 32767, 0)
		self:CheckBox(L"Enable damage zone dissolve", "pac_sv_damage_zone_allow_dissolve")
		self:CheckBox(L"Enable ragdoll hitparts", "pac_sv_damage_zone_allow_ragdoll_hitparts")
		
		self:Help(L"Hitscan"):SetFont("DermaDefaultBold")
		self:CheckBox(L"Enable hitscan part", "pac_sv_hitscan")
		self:NumSlider(L"Max damage", "pac_sv_hitscan_max_damage", 0, 268435455, 0)
		self:CheckBox(L"Force damage division among multi-shot bullets", "pac_sv_hitscan_divide_max_damage_by_max_bullets")

		self:Help(L"Lock part"):SetFont("DermaDefaultBold")
		self:CheckBox(L"Enable lock part", "pac_sv_lock")
		self:CheckBox(L"Allow grab", "pac_sv_lock_grab")
		self:CheckBox(L"Allow teleport", "pac_sv_lock_teleport")
		self:CheckBox(L"Allow aiming", "pac_sv_lock_aim")
		
		self:Help(L"Force part"):SetFont("DermaDefaultBold")
		self:CheckBox(L"Enable force part", "pac_sv_force")
		self:NumSlider(L"Max amount", "pac_sv_force_max_amount", 0, 10000000, 0)
		self:NumSlider(L"Max radius", "pac_sv_force_max_radius", 0, 32767, 0)
		self:NumSlider(L"Max length", "pac_sv_force_max_length", 0, 32767, 0)
		
		self:Help(L"Health Modifier"):SetFont("DermaDefaultBold")
		self:CheckBox(L"Enable health modifier", "pac_sv_health_modifier")
		self:CheckBox(L"Allow changing max health or armor", "pac_sv_health_modifier_allow_maxhp")
		self:NumSlider(L"Maximum modified health or armor", "pac_sv_health_modifier_max_hp_armor", 0, 100000000, 0)
		self:NumSlider(L"Minimum combined damage scaling", "pac_sv_health_modifier_min_damagescaling", -10, 1, 2)
		self:CheckBox(L"Allow extra health bars", "pac_sv_health_modifier_extra_bars")
		self:CheckBox(L"Allow counted hits mode", "pac_sv_health_modifier_allow_counted_hits")
		self:NumSlider(L"Maximum combined extra health value", "pac_sv_health_modifier_max_extra_bars_value", 0, 100000000, 0)

		self:Help(L"Projectile part"):SetFont("DermaDefaultBold")
		self:CheckBox(L"Enable physical projectiles", "pac_sv_projectiles")
		self:CheckBox(L"Enable custom collide meshes for physical projectiles", "pac_sv_projectile_allow_custom_collision_mesh")
		self:NumSlider(L"Max speed", "pac_sv_force_max_amount", 0, 5000, 0)
		self:NumSlider(L"Max physical radius", "pac_sv_projectile_max_phys_radius", 0, 4095, 0)
		self:NumSlider(L"Max damage radius", "pac_sv_projectile_max_damage_radius", 0, 4095, 0)

		self:Help(L"Player movement part"):SetFont("DermaDefaultBold")
		self:CheckBox(L"Allow playermovement", "pac_free_movement")
		self:CheckBox(L"Allow playermovement mass", "pac_player_movement_allow_mass")
		self:CheckBox(L"Allow physics damage scaling by mass", "pac_player_movement_physics_damage_scaling")
		
end



local icon_cvar = CreateConVar("pac_icon", "0", {FCVAR_ARCHIVE}, "Use the new PAC4.5 icon or the old PAC icon.\n0 = use the old one\n1 = use the new one")
local icon = icon_cvar:GetBool() and "icon64/new pac icon.png" or "icon64/pac3.png"

icon = file.Exists("materials/"..icon,'GAME') and icon or "icon64/playermodel.png"

local function ResetPACIcon()
	if icon_cvar:GetBool() then icon = "icon64/new pac icon.png" else icon = "icon64/pac3.png" end
	list.Set(
		"DesktopWindows",
		"PACEditor",
		{
			title = "PAC Editor",
			icon = icon,
			width = 960,
			height = 700,
			onewindow = true,
			init = function(icn, pnl)
				pnl:Remove()
				RunConsoleCommand("pac_editor")
			end
		}
	)
	RunConsoleCommand("spawnmenu_reload")
end

cvars.AddChangeCallback("pac_icon", ResetPACIcon)

concommand.Add("pac_change_icon", function() RunConsoleCommand("pac_icon", (not icon_cvar:GetBool()) and "1" or "0") ResetPACIcon() end)


list.Set(
	"DesktopWindows",
	"PACEditor",
	{
		title = "PAC Editor",
		icon = icon,
		width = 960,
		height = 700,
		onewindow = true,
		init = function(icn, pnl)
			pnl:Remove()
			RunConsoleCommand("pac_editor")
		end
	}
)

hook.Add("PopulateToolMenu", "pac_spawnmenu", function()
	spawnmenu.AddToolMenuOption(
		"Utilities",
		"PAC",
		"PAC3",
		L"PAC3",
		"",
		"",
		pace.ClientOptionsMenu,
		{
			SwitchConVar = "pac_enable",
		}
	)
	spawnmenu.AddToolMenuOption(
		"Utilities",
		"PAC",
		"PAC3S",
		L"Settings",
		"",
		"",
		pace.ClientSettingsMenu,
		{
		}
	)
	spawnmenu.AddToolMenuOption(
		"Utilities",
		"PAC",
		"PAC3Admin",
		L"Admin",
		"",
		"",
		pace.AdminSettingsMenu,
		{
		}
	)
end)

if IsValid(g_ContextMenu) and CreateContextMenu then
	CreateContextMenu()
end
