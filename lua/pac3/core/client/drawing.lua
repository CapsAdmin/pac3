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

pac.drawn_entities = pac.drawn_entities or {}
local pairs = pairs

pac.LocalPlayer = LocalPlayer()
pac.RealTime = 0
pac.FrameNumber = 0

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

local render_time = math.huge
local max_render_time_cvar = CreateClientConVar("pac_max_render_time", 0)
local max_render_time = 0

local TIME = math.huge

pac.profile_info = {}
pac.profile = true

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
	if ent.pac_parts and ent.pac_drawing then
		for _, part in pairs(ent.pac_parts) do
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
	if ent.pac_parts and (not ent.pac_drawing) and (not ent.pac_shouldnotdraw) and (not ent.pac_ignored) then
		for _, part in pairs(ent.pac_parts) do
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

pac.HideEntityParts = hide_parts
pac.ShowEntityParts = show_parts
pac.TogglePartDrawing = toggle_drawing_parts

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

	if not ent.pac_parts then
		pac.UnhookEntityRender(ent)
	else
		if not draw_only then

			pac.ResetBones(ent)

			-- bones MUST be setup before drawing or else unexpected/random results might happen
			for key, part in pairs(ent.pac_parts) do
				if part:IsValid() then
					if not part:HasParent() then
						part:CallRecursive("BuildBonePositions")
					end
				else
					ent.pac_parts[key] = nil
				end
			end
		end

		for key, part in pairs(ent.pac_parts) do
			if part:IsValid() then
				if not part:HasParent() then
					if not draw_only then
						think(part)

						local child = part:GetChildrenList()
						for i = 1, #child do
							think(child[i])
						end
					end

					if not (part.OwnerName == "viewmodel" and type ~= "viewmodel" or part.OwnerName ~= "viewmodel" and type == "viewmodel") then
						part:Draw("OnDraw", nil, nil, type)
					end
				end
			else
				ent.pac_parts[key] = nil
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

pac.Errors = {}

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

pac.firstperson_parts = pac.firstperson_parts or {}

function pac.HookEntityRender(ent, part)
	if not ent.pac_parts then
		ent.pac_parts = {}
	end

	if ent.pac_parts[part] then
		return
	end

	pac.dprint("hooking render on %s to draw part %s", tostring(ent), tostring(part))

	ent.pac_parts[part] = part
	pac.drawn_entities[ent:EntIndex()] = ent
	pac.profile_info[ent:EntIndex()] = nil
end

function pac.UnhookEntityRender(ent, part)

	if part and ent.pac_parts then
		ent.pac_parts[part] = nil
	end

	if ent.pac_parts and not next(ent.pac_parts) then
		pac.drawn_entities[ent:EntIndex()] = nil
		ent.pac_parts = nil
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

local util_PixelVisible = util.PixelVisible
local cvar_distance = CreateClientConVar("pac_draw_distance", "500")
local cvar_fovoverride = CreateClientConVar("pac_override_fov", "0")

pac.EyePos = vector_origin
function pac.RenderScene(pos, ang)
	pac.EyePos = pos
	pac.EyeAng = ang
end
pac.AddHook("RenderScene")

function pac.PostPlayerDraw(ply)
	ply.pac_last_drawn = pac.RealTime
end
pac.AddHook("PostPlayerDraw")

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

	function pac.RenderScreenspaceEffects()
		cam.Start3D()

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
			if ent:IsValid() then
				ent.pac_pixvis = ent.pac_pixvis or util.GetPixelVisibleHandle()
				dst = ent:EyePos():Distance(pac.EyePos)
				radius = ent:BoundingRadius() * 3 * (ent:GetModelScale() or 1)

				if ent:GetNoDraw() then
					hide_parts(ent)
				else
					if ent:IsPlayer() then
						if not ent:Alive() and pac_sv_hide_outfit_on_death:GetBool() then
							hide_parts(ent)
						else
							local rag = ent.pac_ragdoll or NULL
							if rag:IsValid() then
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

					if
						draw_dist == -1 or
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
					then
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

		for key, ent in pairs(pac.drawn_entities) do
			if ent:IsValid() then
				if ent.pac_drawing and ent.pac_parts then
					pac.RenderOverride(ent, "translucent", true)
				end
			else
				pac.drawn_entities[key] = nil
			end
		end

		cam.End3D()
	end

	pac.AddHook("RenderScreenspaceEffects")
end

local cvar_projected_texture = CreateClientConVar("pac_render_projected_texture", "0")

function pac.Think()
	do
		for _, ply in ipairs(player.GetAll()) do
			if ply.pac_parts and not ply:Alive() then
				local ent = ply:GetRagdollEntity()

				if ent and ent:IsValid() then
					if ply.pac_ragdoll ~= ent then
						pac.OnClientsideRagdoll(ply, ent)
					end
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
		if ent:IsValid() then
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
pac.AddHook("Think")

do
	function pac.PostDrawViewModel()
		for key, ent in pairs(pac.drawn_entities) do
			if ent:IsValid() then
				if ent.pac_drawing and ent.pac_parts then
					pac.RenderOverride(ent, "viewmodel", true)
				end
			else
				pac.drawn_entities[key] = nil
			end
		end
	end
	pac.AddHook("PostDrawViewModel")

end

function pac.DrawPhysgunBeam(ent)
	if ent.pac_hide_physgun_beam then
		return false
	end
end
pac.AddHook("DrawPhysgunBeam")