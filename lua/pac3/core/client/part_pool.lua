
local pac = pac

local render_SetColorModulation = render.SetColorModulation
local render_SetBlend = render.SetBlend
local render_ModelMaterialOverride = render.ModelMaterialOverride
local render_MaterialOverride = render.MaterialOverride
local SysTime = SysTime
local util_TimerCycle = util.TimerCycle
local FrameTime = FrameTime
local NULL = NULL
local pairs = pairs

local cvar_projected_texture = CreateClientConVar("pac_render_projected_texture", "0")

local render_time = math.huge
CreateClientConVar("pac_max_render_time", 0)
local max_render_time = 0

local TIME = math.huge

local entMeta = FindMetaTable('Entity')
local plyMeta = FindMetaTable('Player')
local IsValid = entMeta.IsValid
local Alive = plyMeta.Alive

local function IsActuallyValid(ent)
	return IsValid(ent) and IsEntity(ent) and pcall(ent.GetPos, ent)
end

local ent_parts = {}
local all_parts = {}
local uid_parts = {}

local function parts_from_uid(owner_id)
	return uid_parts[owner_id] or {}
end

local function parts_from_ent(ent)
	local owner_id = IsValid(ent) and ent:IsPlayer() and ent:UniqueID() or ent:EntIndex()
	return uid_parts[owner_id] or {}
end

do
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

								for _, child in ipairs(part:GetChildrenList()) do
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

				pac.HideEntityParts(ent)
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
			pac.HideEntityParts(ent)
		else
			ent.pac_error = nil
		end
	end
end

function pac.HideEntityParts(ent)
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

function pac.ShowEntityParts(ent)
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

pac.AddHook("Think", function()
	for _, ply in ipairs(player.GetAll()) do
		if (ply.pac_death_physics_parts or ply.pac_death_ragdollize) and ent_parts[ply] and not Alive(ply) then
			local rag = ply:GetRagdollEntity()

			if IsValid(rag) then
				if ply.pac_ragdoll ~= rag then
					ply.pac_ragdoll = rag

					if ply.pac_death_physics_parts then
						if ply.pac_physics_died then return end

						pac.CallPartEvent("physics_ragdoll_death", rag, ply)

						for _, part in pairs(parts_from_uid(ply:UniqueID())) do
							if part.is_model_part then
								local ent = part:GetEntity()
								if ent:IsValid() then
									rag:SetNoDraw(true)

									part.skip_orient = true

									ent:SetParent(NULL)
									ent:SetNoDraw(true)
									ent:PhysicsInitBox(Vector(1,1,1) * -5, Vector(1,1,1) * 5)
									ent:SetCollisionGroup(COLLISION_GROUP_DEBRIS)

									local phys = ent:GetPhysicsObject()
									phys:AddAngleVelocity(VectorRand() * 1000)
									phys:AddVelocity(ply:GetVelocity()  + VectorRand() * 30)
									phys:Wake()

									function ent.RenderOverride()
										if part:IsValid() then
											if not part.HideEntity then
												part:PreEntityDraw(ent, ent, ent:GetPos(), ent:GetAngles())
												ent:DrawModel()
												part:PostEntityDraw(ent, ent, ent:GetPos(), ent:GetAngles())
											end
										else
											ent.RenderOverride = nil
										end
									end
								end
							end
						end
						ply.pac_physics_died = true
					elseif ply.pac_death_ragdollize then

						-- make props draw on the ragdoll
						if ply.pac_death_ragdollize then
							ply.pac_owner_override = rag
						end

						for _, part in pairs(ent_parts[ply]) do
							if part.last_owner ~= rag then
								part:SetOwner(rag)
								part.last_owner = rag
							end
						end
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
end)


function pac.DisableEntity(ent)
	if ent_parts[ent] then
		for _, part in pairs(ent_parts[ent]) do
			part:CallRecursive("OnHide")
		end

		pac.ResetBones(ent)
	end

	ent.pac_drawing = false
end

pac.AddHook("PlayerSpawned", function(ply)
	if ent_parts[ply] then
		for _, part in pairs(ent_parts[ply]) do
			if part.last_owner and part.last_owner:IsValid() then
				part:SetOwner(ply)
				part.last_owner = nil
			end
		end
	end
	ply.pac_playerspawn = pac.RealTime -- used for events
end)

pac.AddHook("EntityRemoved", function(ent)
	if IsActuallyValid(ent)  then
		local owner = ent:GetOwner()
		if IsActuallyValid(owner)  then
			for _, part in pairs(parts_from_ent(owner)) do
				if part.dupe_remove then
					part:Remove()
				elseif not part:HasParent() then
					part:CheckOwner(ent, true)
				end
			end
		end
	end
end)

pac.AddHook("OnEntityCreated", function(ent)
	if not IsActuallyValid(ent) then return end

	local owner = ent:GetOwner()
	if not IsActuallyValid(owner) then return end

	for _, part in pairs(parts_from_ent(owner)) do
		if not part:HasParent() then
			part:CheckOwner(ent, false)
		end
	end
end)

timer.Create("pac_gc", 2, 0, function()
	for ent, parts in pairs(ent_parts) do
		if not ent:IsValid() then
			ent_parts[ent] = nil
		end
	end

	for key, part in pairs(all_parts) do
		if not part:GetPlayerOwner():IsValid() then
			part:Remove()
		end
	end
end)

function pac.RemovePartsFromUniqueID(uid)
	for _, part in pairs(parts_from_uid(uid)) do
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

function pac.GetPropertyFromName(func, name, ent_owner)
	for _, part in pairs(parts_from_ent(ent_owner)) do
		if part[func] and name == part.Name then
			return part[func](part)
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

function pac.GetLocalParts()
	return uid_parts[pac.LocalPlayer:UniqueID()] or {}
end

function pac.GetPartFromUniqueID(owner_id, id)
	return uid_parts[owner_id] and uid_parts[owner_id][id] or pac.NULL
end

function pac.RemoveAllParts(owned_only, server)
	if server and pace then
		pace.RemovePartOnServer("__ALL__")
	end

	for _, part in pairs(owned_only and pac.GetLocalParts() or all_parts) do
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

function pac.UpdateMaterialParts(how, uid, self, val)
	pac.RunNextFrame("material " .. how .. " " .. self.Id, function()
		for _, part in pairs(parts_from_uid(uid)) do
			if how == "update" or how == "remove" then
				if part.Materialm == val and self ~= part then
					if how == "update" then
						part.force_translucent = self.Translucent
					else
						part.force_translucent = nil
						part.Materialm = nil
					end
				end
			elseif how == "show" then
				if part.Material and part.Material ~= "" and part.Material == val then
					part:SetMaterial(val)
				end
			end
		end
	end)
end

function pac.CallPartEvent(event, ...)
	for _, part in pairs(all_parts) do
		local ret = part:OnEvent(event, ...)
		if ret ~= nil then
			return ret
		end
	end
end


do -- drawing
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

end
