
local pac = pac

local render_SetColorModulation = render.SetColorModulation
local render_SetBlend = render.SetBlend
local render_ModelMaterialOverride = render.ModelMaterialOverride
local render_CullMode = render.CullMode
local render_SuppressEngineLighting = render.SuppressEngineLighting
local FrameNumber = FrameNumber
local RealTime = RealTime
local GetConVar = GetConVar
local NULL = NULL
local EF_BONEMERGE = EF_BONEMERGE
local RENDERMODE_TRANSALPHA = RENDERMODE_TRANSALPHA
local pairs = pairs
local util_PixelVisible = util.PixelVisible

local cvar_distance = CreateClientConVar("pac_draw_distance", "500")
local cvar_fovoverride = CreateClientConVar("pac_override_fov", "0")

local max_render_time_cvar = CreateClientConVar("pac_max_render_time", 0)

local entMeta = FindMetaTable('Entity')
local plyMeta = FindMetaTable('Player')
local IsValid = entMeta.IsValid
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

	pac.AddHook("PostDrawOpaqueRenderables", function(bDrawingDepth, bDrawingSkybox)
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
					pac.HideEntityParts(ent)
				else
					local isply = type(ent) == 'Player'

					if isply then
						if not Alive(ent) and pac_sv_hide_outfit_on_death:GetBool() then
							pac.HideEntityParts(ent)
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

						pac.ShowEntityParts(ent)

						pac.RenderOverride(ent, "opaque")
					else
						pac.HideEntityParts(ent)
					end
				end
			else
				pac.drawn_entities[key] = nil
			end
		end
	end)

	local should_suppress = setup_suppress()

	pac.AddHook("PostDrawTranslucentRenderables", function(bDrawingDepth, bDrawingSkybox)
		if should_suppress() then return end

		for _, ent in pairs(pac.drawn_entities) do
			if ent.pac_draw_cond and ent_parts[ent] then -- accessing table of NULL doesn't do anything
				pac.RenderOverride(ent, "translucent", true)
			end
		end
	end)
end


pac.AddHook("PostDrawViewModel", function()
	for key, ent in pairs(pac.drawn_entities) do
		if IsValid(ent) then
			if ent.pac_drawing and ent_parts[ent] then
				pac.RenderOverride(ent, "viewmodel", true)
			end
		else
			pac.drawn_entities[key] = nil
		end
	end
end)