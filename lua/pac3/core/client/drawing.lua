
local pac = pac

local render_SetColorModulation = render.SetColorModulation
local render_SetBlend = render.SetBlend
local render_ModelMaterialOverride = render.ModelMaterialOverride
local render_MaterialOverride = render.MaterialOverride
local render_CullMode = render.CullMode
local render_SuppressEngineLighting = render.SuppressEngineLighting
local SysTime = SysTime
local util_TimerCycle = util.TimerCycle
local FrameNumber = FrameNumber
local RealTime = RealTime
local FrameTime = FrameTime
local GetConVar = GetConVar
local NULL = NULL
local EF_BONEMERGE = EF_BONEMERGE
local RENDERMODE_TRANSALPHA = RENDERMODE_TRANSALPHA
local pairs = pairs
local util_PixelVisible = util.PixelVisible

local cvar_distance = CreateClientConVar("pac_draw_distance", "500")
local cvar_fovoverride = CreateClientConVar("pac_override_fov", "0")
local cvar_projected_texture = CreateClientConVar("pac_render_projected_texture", "0")

local render_time = math.huge
local max_render_time_cvar = CreateClientConVar("pac_max_render_time", 0)
local max_render_time = 0

local TIME = math.huge

local entMeta = FindMetaTable('Entity')
local plyMeta = FindMetaTable('Player')
local IsValid = entMeta.IsValid
local GetTable = entMeta.GetTable
local Alive = plyMeta.Alive

pac.Errors = {}
pac.firstperson_parts = pac.firstperson_parts or {}
pac.EyePos = vector_origin
pac.drawn_entities = pac.drawn_entities or {}
pac.LocalPlayer = LocalPlayer()
pac.RealTime = 0
pac.FrameNumber = 0
pac.profile_info = {}
pac.profile = true

local class = pac.class

local function IsActuallyValid(ent)
	return IsEntity(ent) and pcall(ent.GetPos, ent)
end

local function IsActuallyPlayer(ent)
	return IsEntity(ent) and pcall(ent.UniqueID, ent)
end

local ent_parts = {}
local all_parts = {}
local uid_parts = {}

local function parts_from_uid(owner_id)
	return uid_parts[owner_id] or {}
end

local function think(part)
	if part.ThinkTime == 0 then
		if part.last_think ~= pac.FrameNumber then
			part:Think()
			part.last_think = pac.FrameNumber
		end
	elseif not part.last_think or part.last_think < pac.RealTime then
		part:Think()
		part.last_think = pac.RealTime + (part.ThinkTime or 0.1)
	end
end

function pac.GetProfilingData(ent)
	local profile_data = pac.profile_info[ent:EntIndex()]

	if profile_data then
		local out = {events = {}}
		out.times_rendered = profile_data.times_ran


		for type, data in pairs(profile_data.types) do
			out.events[type] = {
				average_ms = data.total_render_time / out.times_rendered,
			}
		end

		return out
	end
end

local function hide_parts(ent)
	if ent_parts[ent] and ent.pac_drawing then
		for _, part in pairs(ent_parts[ent]) do
			part:CallRecursive("OnHide")
			part:SetKeyValueRecursive("last_hidden", nil)
			part:SetKeyValueRecursive("shown_from_rendering", false)
			part:SetKeyValueRecursive("draw_hidden", true)
		end

		pac.ResetBones(ent)
		ent.pac_drawing = false
	end
end

local function show_parts(ent)
	if ent_parts[ent] and (not ent.pac_drawing) and (not ent.pac_shouldnotdraw) and (not ent.pac_ignored) then
		for _, part in pairs(ent_parts[ent]) do
			part:SetKeyValueRecursive("last_hidden", nil)
			part:SetKeyValueRecursive("shown_from_rendering", true)
			part:SetKeyValueRecursive("draw_hidden", false)
		end

		pac.ResetBones(ent)
		ent.pac_drawing = true
	end
end

local function toggle_drawing_parts(ent, b)
	if b then
		ent.pac_drawing = false
		show_parts(ent)
		ent.pac_shouldnotdraw = false
	else
		ent.pac_drawing = true
		hide_parts(ent)
		ent.pac_shouldnotdraw = true
	end
end

local function render_override(ent, type, draw_only)
	if pac.profile then
		TIME = util_TimerCycle()
	end

	if max_render_time > 0 and ent ~= pac.LocalPlayer then
		render_time = SysTime()

		if ent.pac_render_time_stop and ent.pac_render_time_stop > render_time then
			return
		end
	end

	if not ent_parts[ent] then
		pac.UnhookEntityRender(ent)
	else
		if not draw_only then
			if type == 'opaque' or type == 'viewmodel' then pac.ResetBones(ent) end

			-- bones MUST be setup before drawing or else unexpected/random results might happen

			if pac.profile then
				for key, part in pairs(ent_parts[ent]) do
					if part:IsValid() then
						if not part:HasParent() then
							part:CallRecursiveProfiled("BuildBonePositions")
						end
					else
						ent_parts[ent][key] = nil
					end
				end
			else
				for key, part in pairs(ent_parts[ent]) do
					if part:IsValid() then
						if not part:HasParent() then
							part:CallRecursive("BuildBonePositions")
						end
					else
						ent_parts[ent][key] = nil
					end
				end
			end
		end

		if pac.profile then
			for key, part in pairs(ent_parts[ent]) do
				if part:IsValid() then
					if not part:HasParent() then
						if not draw_only then
							part:CallRecursiveProfiled('CThink')
						end

						if not (part.OwnerName == "viewmodel" and type ~= "viewmodel" or part.OwnerName ~= "viewmodel" and type == "viewmodel") then
							part:Draw(nil, nil, type)
						end
					end
				else
					ent_parts[ent][key] = nil
				end
			end
		else
			for key, part in pairs(ent_parts[ent]) do
				if part:IsValid() then
					if not part:HasParent() then
						if not draw_only then
							think(part)

							for i, child in ipairs(part:GetChildrenList()) do
								think(child)
							end
						end

						if not (part.OwnerName == "viewmodel" and type ~= "viewmodel" or part.OwnerName ~= "viewmodel" and type == "viewmodel") then
							part:Draw(nil, nil, type)
						end
					end
				else
					ent_parts[ent][key] = nil
				end
			end
		end
	end

	if pac.profile then
		TIME = util_TimerCycle()

		local id = ent:EntIndex()
		pac.profile_info[id] = pac.profile_info[id] or {types = {}, times_ran = 0}
		pac.profile_info[id].times_ran = pac.profile_info[id].times_ran + 1

		pac.profile_info[id].types[type] = pac.profile_info[id].types[type] or {}

		local data = pac.profile_info[id].types[type]

		data.total_render_time = (data.total_render_time or 0) + TIME
	end

	if max_render_time > 0 and ent ~= pac.LocalPlayer then
		ent.pac_render_times = ent.pac_render_times or {}

		local last = ent.pac_render_times[type] or 0

		render_time = (SysTime() - render_time) * 1000
		last = last + ((render_time - last) * FrameTime())
		ent.pac_render_times[type] = last

		if last > max_render_time then
			ent.pac_render_time_stop = SysTime() + 2 + (math.random() * 2)

			hide_parts(ent)
		end
	end

	render_SetColorModulation(1, 1, 1)
	render_SetBlend(1)

	render_MaterialOverride()
	render_ModelMaterialOverride()
end

function pac.RenderOverride(ent, type, draw_only)
	local ok, err = pcall(render_override, ent, type, draw_only)
	if not ok then
		pac.Message("failed to render ", tostring(ent), ":")
		print(err)

		if ent == pac.LocalPlayer then
			chat.AddText("your pac3 outfit failed to render!")
			chat.AddText(err)
			chat.AddText("hiding your outfit to prevent further errors")
		end

		ent.pac_error = err
		table.insert(pac.Errors, err)
		hide_parts(ent)
	else
		ent.pac_error = nil
	end
end

function pac.HookEntityRender(ent, part)
	if not ent_parts[ent] then
		ent_parts[ent] = {}
	end

	if ent_parts[ent][part] then
		return
	end

	pac.dprint("hooking render on %s to draw part %s", tostring(ent), tostring(part))

	pac.drawn_entities[ent:EntIndex()] = ent
	pac.profile_info[ent:EntIndex()] = nil

	ent_parts[ent] = ent_parts[ent] or {}
	ent_parts[ent][part] = part

	ent.pac_has_parts = true
end

function pac.UnhookEntityRender(ent, part)

	if part and ent_parts[ent] then
		ent_parts[ent][part] = nil
	end

	if ent_parts[ent] and not next(ent_parts[ent]) then
		ent_parts[ent] = nil
		ent.pac_has_parts = nil
		pac.drawn_entities[ent:EntIndex()] = nil
	end

	pac.profile_info[ent:EntIndex()] = nil
end

function pac.IgnoreEntity(ent, strID)
	strID = strID or 'generic'
	ent.pac_ignored = ent.pac_ignored or false
	ent.pac_ignored_data = ent.pac_ignored_data or {}
	ent.pac_ignored_data[strID] = true
	local newStatus = true

	if newStatus ~= ent.pac_ignored then
		ent.pac_ignored = newStatus
		toggle_drawing_parts(ent, not newStatus)
	end

	return true
end

function pac.UnIgnoreEntity(ent, strID)
	strID = strID or 'generic'
	ent.pac_ignored = ent.pac_ignored or false
	ent.pac_ignored_data = ent.pac_ignored_data or {}
	ent.pac_ignored_data[strID] = false
	local newStatus = false

	for _, v in pairs(ent.pac_ignored_data) do
		if v then
			newStatus = true
			break
		end
	end

	if newStatus ~= ent.pac_ignored then
		ent.pac_ignored = newStatus
		toggle_drawing_parts(ent, not newStatus)
	end

	return newStatus
end

function pac.ToggleIgnoreEntity(ent, status, strID)
	if status then
		return pac.IgnoreEntity(ent, strID)
	else
		return pac.UnIgnoreEntity(ent, strID)
	end
end

function pac.RenderScene(pos, ang)
	pac.EyePos = pos
	pac.EyeAng = ang
end

-- disable pop/push flashlight modes (used for stability in 2D context)
function pac.FlashlightDisable(b)
	pac.flashlight_disabled = b
end

do
	local draw_dist = 0
	local sv_draw_dist = 0
	local radius = 0
	local dst = 0
	local dummyv = Vector(0.577350,0.577350,0.577350)
	local fovoverride

	local pac_sv_hide_outfit_on_death = GetConVar("pac_sv_hide_outfit_on_death")
	local skip_frames = CreateConVar('pac_suppress_frames', '1', {FCVA_ARCHIVE}, 'Skip frames (reflections)')

	local function setup_suppress()
		local last_framenumber = 0
		local current_frame = 0
		local current_frame_count = 0

		return function()
			if skip_frames:GetBool() then
				local frame_number = FrameNumber()

				if frame_number == last_framenumber then
					current_frame = current_frame + 1
				else
					last_framenumber = frame_number

					if current_frame_count ~= current_frame then
						current_frame_count = current_frame
					end

					current_frame = 1
				end

				return current_frame < current_frame_count
			end
		end
	end

	local should_suppress = setup_suppress()

	function pac.PostDrawOpaqueRenderables(bDrawingDepth, bDrawingSkybox)
		if should_suppress() then return end

		-- commonly used variables
		max_render_time = max_render_time_cvar:GetFloat()
		pac.RealTime = RealTime()
		pac.FrameNumber = FrameNumber()

		draw_dist = cvar_distance:GetInt()
		fovoverride = cvar_fovoverride:GetInt()
		sv_draw_dist = GetConVar("pac_sv_draw_distance"):GetFloat()
		radius = 0

		if draw_dist == 0 then
			draw_dist = 32768
		end

		for key, ent in pairs(pac.drawn_entities) do
			if IsValid(ent) then
				ent.pac_pixvis = ent.pac_pixvis or util.GetPixelVisibleHandle()
				dst = ent:EyePos():Distance(pac.EyePos)
				radius = ent:BoundingRadius() * 3 * (ent:GetModelScale() or 1)

				if ent:GetNoDraw() then
					hide_parts(ent)
				else
					local isply = type(ent) == 'Player'

					if isply then
						if not Alive(ent) and pac_sv_hide_outfit_on_death:GetBool() then
							hide_parts(ent)
						else
							local rag = ent.pac_ragdoll or NULL

							if IsValid(rag) then
								if ent.pac_death_hide_ragdoll then
									rag:SetRenderMode(RENDERMODE_TRANSALPHA)

									local c = rag:GetColor()
									c.a = 0
									rag:SetColor(c)
									rag:SetNoDraw(true)
									if rag:GetParent() ~= ent then
										rag:SetParent(ent)
										rag:AddEffects(EF_BONEMERGE)
									end

									if ent.pac_draw_player_on_death then
										ent:DrawModel()
									end
								elseif ent.pac_death_ragdollize then
									rag:SetNoDraw(true)

									if not ent.pac_hide_entity then
										local col = ent.pac_color or dummyv
										local bri = ent.pac_brightness or 1

										render_ModelMaterialOverride(ent.pac_materialm)
										render_SetColorModulation(col.x * bri, col.y * bri, col.z * bri)
										render_SetBlend(ent.pac_alpha or 1)

										if ent.pac_invert then render_CullMode(1) end
										if ent.pac_fullbright then render_SuppressEngineLighting(true) end

										rag:DrawModel()
										rag:CreateShadow()

										render_ModelMaterialOverride()
										render_SetColorModulation(1,1,1)
										render_SetBlend(1)

										render_CullMode(0)
										render_SuppressEngineLighting(false)
									end
								end
							end

							if radius < 32 then
								radius = 128
							end
						end
					elseif not ent:IsNPC() then
						radius = radius * 4
					end

					local cond = draw_dist == -1 or
						ent.IsPACWorldEntity or
						(ent == pac.LocalPlayer and ent:ShouldDrawLocalPlayer() or (ent.pac_camera and ent.pac_camera:IsValid())) or
						ent ~= pac.LocalPlayer and
						(
							((fovoverride ~= 0 or util_PixelVisible(ent:EyePos(), radius, ent.pac_pixvis) ~= 0) or (dst < radius * 1.25)) and
							(
								(sv_draw_dist ~= 0 and (sv_draw_dist == -1 or dst <= sv_draw_dist)) or
								(ent.pac_draw_distance and (ent.pac_draw_distance <= 0 or ent.pac_draw_distance <= dst)) or
								(dst <= draw_dist)
							)
						)

					ent.pac_draw_cond = cond

					if cond then
						ent.pac_model = ent:GetModel() -- used for cached functions

						show_parts(ent)

						pac.RenderOverride(ent, "opaque")
					else
						hide_parts(ent)
					end
				end
			else
				pac.drawn_entities[key] = nil
			end
		end
	end

	local should_suppress = setup_suppress()

	function pac.PostDrawTranslucentRenderables(bDrawingDepth, bDrawingSkybox)
		if should_suppress() then return end

		for key, ent in pairs(pac.drawn_entities) do
			if ent.pac_draw_cond and ent_parts[ent] then -- accessing table of NULL doesn't do anything
				pac.RenderOverride(ent, "translucent", true)
			end
		end
	end
end

function pac.Think()
	for i, ply in ipairs(player.GetAll()) do
		if ent_parts[ply] and not Alive(ply) then
			local ent = ply:GetRagdollEntity()

			if IsValid(ent) then
				if ply.pac_ragdoll ~= ent then
					pac.OnClientsideRagdoll(ply, ent)
				end
			end
		end
	end

	do
		local mode = cvar_projected_texture:GetInt()

		if mode <= 0 then
			pac.projected_texture_enabled = false
		elseif mode == 1 then
			pac.projected_texture_enabled = true
		elseif mode >= 2 then
			pac.projected_texture_enabled = pac.LocalPlayer:FlashlightIsOn()
		end
	end

	for key, ent in pairs(pac.drawn_entities) do
		if IsValid(ent) then
			if ent.pac_drawing and ent:IsPlayer() then

				ent.pac_traceres = util.QuickTrace(ent:EyePos(), ent:GetAimVector() * 32000, {ent, ent:GetVehicle(), ent:GetOwner()})
				ent.pac_hitpos = ent.pac_traceres.HitPos

			end
		else
			pac.drawn_entities[key] = nil
		end
	end

	if pac.next_frame_funcs then
		for k, v in pairs(pac.next_frame_funcs) do
			v()
			pac.next_frame_funcs[k] = nil
		end
	end
end

function pac.PostDrawViewModel()
	for key, ent in pairs(pac.drawn_entities) do
		if IsValid(ent) then
			if ent.pac_drawing and ent_parts[ent] then
				pac.RenderOverride(ent, "viewmodel", true)
			end
		else
			pac.drawn_entities[key] = nil
		end
	end
end

function pac.DrawPhysgunBeam(ply, wep, enabled, target, bone, hitpos)

	if enabled then
		ply.pac_drawphysgun_event = {ply, wep, enabled, target, bone, hitpos}
	else
		ply.pac_drawphysgun_event = nil
	end

	if ply.pac_drawphysgun_event_part and ply.pac_drawphysgun_event_part:IsValid() then
		ply.pac_drawphysgun_event_part:OnThink()
	end


	if ply.pac_hide_physgun_beam then
		return false
	end
end

pac.HideEntityParts = hide_parts
pac.ShowEntityParts = show_parts
pac.TogglePartDrawing = toggle_drawing_parts

function pac.DisableEntity(ent)
	if ent_parts[ent] then
		for _, part in pairs(ent_parts[ent]) do
			part:CallRecursive("OnHide")
		end

		pac.ResetBones(ent)
	end

	ent.pac_drawing = false
end

-- todo
function pac.__check_vehicle(ply)
	if ent_parts[ply] then
		local done = {}
		for _, part in pairs(ent_parts[ply]) do
			local part = part:GetRootPart()
			if not done[part] then
				if part.OwnerName == "active vehicle" then
					part:CheckOwner()
				end
				done[part] = true
			end
		end
	end
end

function pac.OnClientsideRagdoll(ply, ent)
	ply.pac_ragdoll = ent

	if ply.pac_death_physics_parts then
		if ply.pac_physics_died then return end

		for _, part in pairs(parts_from_uid(ply:UniqueID())) do
			if part.is_model_part then
				pac.InitDeathPhysicsOnProp(part,ply,ent)
			end
		end
		ply.pac_physics_died = true
	elseif ply.pac_death_ragdollize then

		-- make props draw on the ragdoll
		if ply.pac_death_ragdollize then
			ply.pac_owner_override = ent
		end

		for _, part in pairs(ent_parts[ply]) do
			if part.last_owner ~= ent then
				part:SetOwner(ent)
				part.last_owner = ent
			end
		end
	end
end

function pac.PlayerSpawned(ply)
	if ent_parts[ply] then
		for _, part in pairs(ent_parts[ply]) do
			if part.last_owner and part.last_owner:IsValid() then
				part:SetOwner(ply)
				part.last_owner = nil
			end
		end
	end
	ply.pac_playerspawn = pac.RealTime -- used for events
end
pac.AddHook("PlayerSpawned")


function pac.EntityRemoved(ent)
	if IsActuallyValid(ent)  then
		local owner = ent:GetOwner()
		if IsActuallyValid(owner) and IsActuallyPlayer(owner) then
			for _, part in pairs(parts_from_uid(owner:UniqueID())) do
				if not part:HasParent() then
					part:CheckOwner(ent, true)
				end
			end
		elseif ent_parts[ent] then
			for _, part in pairs(ent_parts[ent]) do
				if part.dupe_remove then
					part:Remove()
				elseif not part:HasParent() then
					part:CheckOwner(ent, true)
				end
			end
		end
	end
end
pac.AddHook("EntityRemoved")


function pac.OnEntityCreated(ent)
	if not IsActuallyValid(ent) then return end

	local owner = ent:GetOwner()

	if IsActuallyValid(owner) and IsActuallyPlayer(owner) then
		for _, part in pairs(parts_from_uid(owner:UniqueID())) do
			if not part:HasParent() then
				part:CheckOwner(ent, false)
			end
		end
	end
end
pac.AddHook("OnEntityCreated")


pac.AddHook("EntityEmitSound", function(data)
	if pac.playing_sound then return end
	local ent = data.Entity

	if not ent:IsValid() or not ent.pac_has_parts then return end

	ent.pac_emit_sound = {name = data.SoundName, time = pac.RealTime, reset = true, mute_me = ent.pac_emit_sound and ent.pac_emit_sound.mute_me or false}

	for _, v in pairs(parts_from_uid(ent:IsPlayer() and ent:UniqueID() or ent:EntIndex())) do
		if v.ClassName == "event" and v.Event == "emit_sound" then
			v:GetParent():CallRecursive("Think")

			if ent.pac_emit_sound.mute_me then
				return false
			end
		end
	end

	if ent.pac_mute_sounds then
		return false
	end
end)

pac.AddHook("EntityFireBullets", function(ent, data)
	if not ent:IsValid() or not ent.pac_has_parts then return end
	ent.pac_fire_bullets = {name = data.AmmoType, time = pac.RealTime, reset = true}

	for _, v in pairs(parts_from_uid(ent:IsPlayer() and ent:UniqueID() or ent:EntIndex())) do
		if v.ClassName == "event" and v.Event == "fire_bullets" then
			v:GetParent():CallRecursive("Think")
		end
	end

	if ent.pac_hide_bullets then
		return false
	end
end)


do
	local enums = {}

	for key, val in pairs(_G) do
		if type(key) == "string" and key:find("PLAYERANIMEVENT_", nil, true) then
			enums[val] = key:gsub("PLAYERANIMEVENT_", ""):gsub("_", " "):lower()
		end
	end

	pac.AddHook("DoAnimationEvent", function(ply, event, data)
		-- update all parts once so OnShow and OnHide are updated properly for animation events
		if ply.pac_has_parts then
			ply.pac_anim_event = {name = enums[event], time = pac.RealTime, reset = true}

			for _, v in pairs(parts_from_uid(ply:UniqueID())) do
				if v.ClassName == "event" and v.Event == "animation_event" then
					v:GetParent():CallRecursive("Think")
				end
			end
		end
	end)
end

timer.Create("pac_gc", 2, 0, function()
	for ent, parts in pairs(ent_parts) do
		if not ent:IsValid() then
			for k,v in pairs(parts) do
				v:Remove()
			end
		end
	end
end)

function pac.RemovePartsFromUniqueID(uid)
	for key, part in pairs(parts_from_uid(uid)) do
		if not part:HasParent() then
			part:Remove()
		end
	end
end

function pac.UpdatePartsWithMetatable(META, name)
	-- update part functions only
	-- updating variables might mess things up
	for _, part in pairs(all_parts) do
		if part.ClassName == name then
			for k, v in pairs(META) do
				if type(v) == "function" then
					part[k] = v
				end
			end
		end
	end
end

function pac.GetRawMaterialFromName(str, ply_owner)
	for _, part in pairs(all_parts) do
		if part.GetRawMaterial and part:GetPlayerOwner() == ply_owner and str == part.Name then
			return part:GetRawMaterial()
		end
	end
end

function pac.RemoveUniqueIDPart(owner_uid, uid)
	if not uid_parts[owner_uid] then return end
	uid_parts[owner_uid][uid] = nil
end

function pac.SetUniqueIDPart(owner_uid, uid, part)
	uid_parts[owner_uid] = uid_parts[owner_uid] or {}
	uid_parts[owner_uid][uid] = part
end

function pac.AddPart(part)
	all_parts[part.Id] = part
end

function pac.RemovePart(part)
	all_parts[part.Id] = nil
end

function pac.LoadParts()
	local files = file.Find("pac3/core/client/parts/*.lua", "LUA")

	for _, name in pairs(files) do
		include("pac3/core/client/parts/" .. name)
	end
end

function pac.GetRegisteredParts()
	return class.GetAll("part")
end

function pac.GetLocalParts()
	return uid_parts[pac.LocalPlayer:UniqueID()]
end

function pac.GetPartFromUniqueID(owner_id, id)
	return uid_parts[owner_id] and uid_parts[owner_id][id] or pac.NULL
end

function pac.RemoveAllParts(owned_only, server)
	if server and pace then
		pace.RemovePartOnServer("__ALL__")
	end

	for _, part in pairs(pac.GetParts(owned_only)) do
		if part:IsValid() then
			local status, err = pcall(part.Remove, part)
			if not status then pac.Message('Failed to remove part: ' .. err .. '!') end
		end
	end

	if not owned_only then
		all_parts = {}
		uid_parts = {}
	end
end

function pac.GetPartCount(class, children)
	class = class:lower()
	local count = 0

	for _, part in pairs(children or pac.GetLocalParts()) do
		if part.ClassName:lower() == class then
			count = count + 1
		end
	end

	return count
end

function pac.CallPartHook(name, ...)
	for _, part in pairs(all_parts) do
		if part[name] then
			part[name](part, ...)
		end
	end
end

function pac.UpdateMaterialPart(how, self, val)
	if how == "update" then
		pac.RunNextFrame("material translucent " .. self.Id, function()
			for key, part in pairs(all_parts) do
				if part.Materialm == val and self ~= part then
					part.force_translucent = self.Translucent
				end
			end
		end)
	elseif how == "remove" then
		pac.RunNextFrame("remove materials" .. self.Id, function()
			for key, part in pairs(all_parts) do
				if part.Materialm == val and self ~= part then
					part.force_translucent = nil
					part.Materialm = nil
				end
			end
		end)
	elseif how == "show" then
		pac.RunNextFrame("refresh materials" .. self.Id, function()
			for key, part in pairs(all_parts) do
				if part.Material and part.Material ~= "" and part.Material == val then
					part:SetMaterial(val)
				end
			end
		end)
	end
end

function pac.RefreshSetModel()
	for _, part in pairs(all_parts) do
		if part.ClassName == "model" then
			part:SetModel(part:GetModel())
		end
	end
end

local MOVETYPE_NOCLIP = MOVETYPE_NOCLIP
local IN_SPEED = IN_SPEED
local SOLID_NONE = SOLID_NONE
local MOVETYPE_NONE = MOVETYPE_NONE
local IN_WALK = IN_WALK
local IN_DUCK = IN_DUCK

function pac.UpdateAnimation(ply)
	if not IsEntity(ply) or not ply:IsValid() then return end

	if ply.pac_death_physics_parts and ply:Alive() and ply.pac_physics_died then
		for _, part in pairs(all_parts) do
			if part:GetPlayerOwner() == ply and part.is_model_part then
				local ent = part:GetEntity()
				if ent:IsValid() then
					ent:PhysicsInit(SOLID_NONE)
					ent:SetMoveType(MOVETYPE_NONE)
					ent:SetNoDraw(true)
					ent.RenderOverride = nil

					part.skip_orient = false
				end
			end
		end
		ply.pac_physics_died = false
	end

	local tbl = ply.pac_pose_params

	if tbl then
		for _, data in pairs(ply.pac_pose_params) do
			ply:SetPoseParameter(data.key, data.val)
		end
	end

	if ply.pac_global_animation_rate and ply.pac_global_animation_rate ~= 1 then

		if ply.pac_global_animation_rate == 0 then
			ply:SetCycle((pac.RealTime * ply:GetModelScale() * 2)%1)
		elseif ply.pac_global_animation_rate ~= 1 then
			ply:SetCycle((pac.RealTime * ply.pac_global_animation_rate)%1)
		end

		return true
	end

	if ply.pac_holdtype_alternative_animation_rate then
		local length = ply:GetVelocity():Dot(ply:EyeAngles():Forward()) > 0 and 1 or -1
		local scale = ply:GetModelScale() * 2

		if scale ~= 0 then
			ply:SetCycle(pac.RealTime / scale * length)
		else
			ply:SetCycle(0)
		end

		return true
	end

	local vehicle = ply:GetVehicle()

	if ply.pac_last_vehicle ~= vehicle then
		if ply.pac_last_vehicle ~= nil then
			pac.__check_vehicle(ply)
		end
		ply.pac_last_vehicle = vehicle
	end
end
pac.AddHook("UpdateAnimation")

function pac.EffectReady(name)
	for _, part in pairs(all_parts) do
		if part.ClassName == "effect" and part.Effect == name then
			part.Ready = true
			part.waitingForServer = false
		end
	end
end

pac.AddHook("DrawPhysgunBeam")
pac.AddHook("PostDrawViewModel")
pac.AddHook("Think")
pac.AddHook("RenderScene")
pac.AddHook("PostDrawTranslucentRenderables")
pac.AddHook("PostDrawOpaqueRenderables")