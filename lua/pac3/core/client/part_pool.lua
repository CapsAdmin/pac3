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
local force_rendering = false
local forced_rendering = false

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
	return IsEntity(ent) and pcall(ent.GetPos, ent)
end

local function IsActuallyPlayer(ent)
	return IsEntity(ent) and pcall(ent.UniqueID, ent)
end

local function IsActuallyRemoved(ent, cb)
	timer.Simple(0, function()
		if not ent:IsValid() then
			cb()
		end
	end)
end

--[[
	This state can happen when the Player is joined but not yet fully connected.
	At this point the SteamID is not yet set and the UniqueID call fails with a lua error.
]]
local function IsActuallyPlayer(ent)
	return IsEntity(ent) and pcall(ent.UniqueID, ent)
end

function pac.ForceRendering(b)
	force_rendering = b
	if b then
		forced_rendering = b
	end
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
			if ent.pac_render_time_exceeded then
				return
			end
			render_time = SysTime()
		end

		local parts = ent_parts[ent]
		if parts == nil or next(parts) == nil then
			pac.UnhookEntityRender(ent)
		else
			if type == "update" then
				pac.ResetBones(ent)

				for key, part in pairs(parts) do
					if part:IsValid() then
						if not part:HasParent() then
							if pac.profile then
								part:CallRecursiveProfiled('CThink')
								part:CallRecursiveProfiled("BuildBonePositions")
							else
								part:CallRecursive('CThink')
								part:CallRecursive("BuildBonePositions")
							end	
						else
							parts[key] = nil
						end
					end
				end
			else
				for key, part in pairs(parts) do
					if part:IsValid() then
						if not part:HasParent() then
							if part.OwnerName == "viewmodel" and type == "viewmodel" or
								part.OwnerName == "hands" and type == "hands" or
								part.OwnerName ~= "viewmodel" and part.OwnerName ~= "hands" and type ~= "viewmodel" and type ~= "hands" then

								part:Draw(nil, nil, type)
							end
						end
					else
						parts[key] = nil
					end
				end
			end			
		end

		if pac.profile then
			TIME = util_TimerCycle()

			pac.profile_info[ent] = pac.profile_info[ent] or {types = {}, times_ran = 0}
			pac.profile_info[ent].times_ran = pac.profile_info[ent].times_ran + 1

			pac.profile_info[ent].types[type] = pac.profile_info[ent].types[type] or {}

			local data = pac.profile_info[ent].types[type]

			data.total_render_time = (data.total_render_time or 0) + TIME
		end

		if max_render_time > 0 and ent ~= pac.LocalPlayer then
			ent.pac_render_times = ent.pac_render_times or {}

			local last = ent.pac_render_times[type] or 0

			render_time = (SysTime() - render_time) * 1000
			last = last + ((render_time - last) * FrameTime())
			ent.pac_render_times[type] = last

			if last > max_render_time then
				pac.Message(Color(255, 50, 50), tostring(ent) .. ": Render time limit exceeded!")
				ent.pac_render_time_exceeded = true
				pac.HideEntityParts(ent)
			end
		end

		render_SetColorModulation(1, 1, 1)
		render_SetBlend(1)

		render_MaterialOverride()
		render_ModelMaterialOverride()
	end

	local function on_error(msg)
		ErrorNoHalt(debug.traceback(msg))
	end

	function pac.RenderOverride(ent, type, draw_only)
		local ok, err = xpcall(render_override, on_error, ent, type, draw_only)
		if not ok then
			pac.Message("failed to render ", tostring(ent), ":")

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
			part:SetKeyValueRecursive("shown_from_rendering", nil)
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
			part:SetKeyValueRecursive("shown_from_rendering", FrameNumber())
			part:SetKeyValueRecursive("draw_hidden", false)
		end

		pac.ResetBones(ent)
		ent.pac_drawing = true
	end
end

-- Prevent radius AND pixvis based flickering at the cost of rendering a bit longer than necessary
local viscache=setmetatable({},{__mode='k'})
local function nodrawdelay(draw,ent)
	if draw and viscache[ent]~=false then
		viscache[ent] = false
		if pac.debug then print("PAC dodraw catch",ent) end
	elseif not draw then
		local c = viscache[ent]
		local fn = pac.FrameNumber
		if c~=nil then
			if c==false then
				viscache[ent] = fn
				if pac.debug then print("PAC dodraw override START",ent) end
				return true
			elseif c then
				if fn-c<3 then
					if pac.debug then print("PAC dodraw override",ent) end
					return true
				else
					viscache[ent] = nil
				end
			end
		end
	end
	return draw
end

function pac.HookEntityRender(ent, part)
	local parts = ent_parts[ent]
	if not parts then
		parts = {}
		ent_parts[ent] = parts
	end

	if parts[part] then
		return
	end

	pac.dprint("hooking render on %s to draw part %s", tostring(ent), tostring(part))

	pac.drawn_entities[ent] = true
	pac.profile_info[ent] = nil

	parts[part] = part

	ent.pac_has_parts = true
end

function pac.UnhookEntityRender(ent, part)

	if part and ent_parts[ent] then
		ent_parts[ent][part] = nil
	end

	if (ent_parts[ent] and not next(ent_parts[ent])) or not part then
		ent_parts[ent] = nil
		ent.pac_has_parts = nil
		pac.drawn_entities[ent] = nil
	end

	pac.profile_info[ent] = nil
end

pac.AddHook("Think", "events", function()
	for _, ply in ipairs(player.GetAll()) do
		if not ent_parts[ply] then continue end
		if pac.IsEntityIgnored(ply) then continue end

		if Alive(ply) then
			if ply.pac_revert_ragdoll then
				ply.pac_revert_ragdoll()
				ply.pac_revert_ragdoll = nil
			end
			continue
		end

		local rag = ply:GetRagdollEntity()
		if not IsValid(rag) then continue end

		-- so it only runs once
		if ply.pac_ragdoll == rag then continue end
		ply.pac_ragdoll = rag
		rag.pac_player = ply

		rag = hook.Run("PACChooseDeathRagdoll", ply, rag) or rag

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
		elseif ply.pac_death_ragdollize or ply.pac_death_ragdollize == nil then

			pac.HideEntityParts(ply)

			for _, part in pairs(ent_parts[ply]) do
				part:SetOwner(rag)
			end

			pac.ShowEntityParts(rag)

			ply.pac_revert_ragdoll = function()
				ply.pac_ragdoll = nil

				if not ent_parts[ply] then return end

				pac.HideEntityParts(rag)

				for _, part in pairs(ent_parts[ply]) do
					part:SetOwner(ply)
				end

				pac.ShowEntityParts(ply)
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

	for ent in next, pac.drawn_entities do
		if IsValid(ent) then
			if ent.pac_drawing and ent:IsPlayer() then

				ent.pac_traceres = util.QuickTrace(ent:EyePos(), ent:GetAimVector() * 32000, {ent, ent:GetVehicle(), ent:GetOwner()})
				ent.pac_hitpos = ent.pac_traceres.HitPos

			end
		else
			pac.drawn_entities[ent] = nil
		end
	end

	if pac.next_frame_funcs then
		for k, fcall in pairs(pac.next_frame_funcs) do
			fcall()
		end

		-- table.Empty is also based on undefined behavior
		-- god damnit
		for i, key in ipairs(table.GetKeys(pac.next_frame_funcs)) do
			pac.next_frame_funcs[key] = nil
		end
	end

	if pac.next_frame_funcs_simple and #pac.next_frame_funcs_simple ~= 0 then
		for i, fcall in ipairs(pac.next_frame_funcs_simple) do
			fcall()
		end

		for i = #pac.next_frame_funcs_simple, 1, -1 do
			pac.next_frame_funcs_simple[i] = nil
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

pac.AddHook("EntityRemoved", "change_owner", function(ent)
	if IsActuallyValid(ent) then
		if IsActuallyPlayer(ent) then
			local parts = parts_from_ent(ent)
			if next(parts) ~= nil then
				IsActuallyRemoved(ent, function()
					for _, part in pairs(parts) do
						if part.dupe_remove then
							part:Remove()
						end
					end
				end)
			end
		else
			local owner = ent:GetOwner()
			if IsActuallyPlayer(owner) then
				local parts = parts_from_ent(owner)
				if next(parts) ~= nil then
					IsActuallyRemoved(ent, function()
						for _, part in pairs(parts) do
							if not part:HasParent() then
								part:CheckOwner(ent, true)
							end
						end
					end)
				end
			end
		end
	end
end)

pac.AddHook("OnEntityCreated", "change_owner", function(ent)
	if not IsActuallyValid(ent) then return end

	local owner = ent:GetOwner()

	if IsActuallyValid(owner) and (not owner:IsPlayer() or IsActuallyPlayer(owner)) then
		for _, part in pairs(parts_from_ent(owner)) do
			if not part:HasParent() then
				part:CheckOwner(ent, false)
			end
		end
	end
end)

local function pac_gc()
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
end

timer.Create("pac_gc", 2, 0, function()
	ProtectedCall(pac_gc)
end)

cvars.AddChangeCallback("pac_hide_disturbing", function()
	for key, part in pairs(all_parts) do
		if part:GetPlayerOwner():IsValid() then
			part:SetIsDisturbing(part:GetIsDisturbing())
		end
	end
end, "PAC3")

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

function pac.GetLocalPart(id)
	local owner_id = pac.LocalPlayer:UniqueID()
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

		local skip_frames = CreateConVar('pac_suppress_frames', '1', {FCVA_ARCHIVE}, 'Skip frames (reflections)')

		local function setup_suppress()
			local last_framenumber = 0
			local current_frame = 0
			local current_frame_count = 0

			return function()
				if force_rendering then return end

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
		local pac_sv_draw_distance

		pac.AddHook("PostDrawOpaqueRenderables", "draw_opaque", function(bDrawingDepth, bDrawingSkybox)
			if should_suppress() then return end

			-- commonly used variables
			max_render_time = max_render_time_cvar:GetFloat()
			pac.RealTime = RealTime()
			pac.FrameNumber = FrameNumber()

			draw_dist = cvar_distance:GetInt()
			fovoverride = cvar_fovoverride:GetBool()
			pac_sv_draw_distance = pac_sv_draw_distance or GetConVar("pac_sv_draw_distance")
			sv_draw_dist = pac_sv_draw_distance:GetFloat()
			radius = 0

			if draw_dist <= 0 then
				draw_dist = 32768
			end

			if sv_draw_dist <= 0 then
				sv_draw_dist = 32768
			end

			draw_dist = math.min(sv_draw_dist, draw_dist)

			for ent in next, pac.drawn_entities do
				if not IsValid(ent) then
					pac.drawn_entities[ent] = nil
					goto CONTINUE
				end

				ent.pac_pixvis = ent.pac_pixvis or util.GetPixelVisibleHandle()
				dst = ent:EyePos():Distance(pac.EyePos)
				radius = ent:BoundingRadius() * 3 * (ent:GetModelScale() or 1)

				if ent:IsPlayer() or IsValid(ent.pac_player) then
					local ply = ent.pac_player or ent
					local rag = ply.pac_ragdoll

					if IsValid(rag) then
						if ply.pac_death_hide_ragdoll or ply.pac_draw_player_on_death then
							rag:SetRenderMode(RENDERMODE_TRANSALPHA)

							local c = rag:GetColor()
							c.a = 0
							rag:SetColor(c)
							rag:SetNoDraw(true)
							if rag:GetParent() ~= ply then
								rag:SetParent(ent)
								rag:AddEffects(EF_BONEMERGE)
							end

							if ply.pac_draw_player_on_death then
								ply:DrawModel()
							end
						end
					end

					if radius < 32 then
						radius = 128
					end
				elseif not ent:IsNPC() then
					radius = radius * 4
				end

				local cond = ent.IsPACWorldEntity -- or draw_dist == -1 or -- i assume this is a leftover from debugging?
				-- because we definitely don't want to draw ANY outfit present, right?

				if not cond then
					cond = ent == pac.LocalPlayer and ent:ShouldDrawLocalPlayer() or
						ent.pac_camera and ent.pac_camera:IsValid()
				end

				if not cond and ent ~= pac.LocalPlayer then
					cond = (
						ent.pac_draw_distance and (ent.pac_draw_distance <= 0 or ent.pac_draw_distance <= dst) or
						dst <= draw_dist
					) and (
						fovoverride or
						nodrawdelay(dst < radius * 1.25  or
						util_PixelVisible(ent:EyePos(), radius, ent.pac_pixvis) ~= 0,ent)
					)
				end

				ent.pac_draw_cond = cond

				if cond then
					ent.pac_model = ent:GetModel() -- used for cached functions

					pac.ShowEntityParts(ent)

					pac.RenderOverride(ent, "opaque")
				else
					if forced_rendering then
						forced_rendering = false
						return
					end

					pac.HideEntityParts(ent)
				end

				::CONTINUE::
			end
		end)

		local should_suppress = setup_suppress()

		pac.AddHook("PostDrawTranslucentRenderables", "draw_translucent", function(bDrawingDepth, bDrawingSkybox)
			if should_suppress() then return end

			for ent in next, pac.drawn_entities do
				if ent.pac_draw_cond and ent_parts[ent] then -- accessing table of NULL doesn't do anything
					pac.RenderOverride(ent, "translucent", true)
				end
			end
		end)
	end

	pac.AddHook("Think", "update_parts", function(viewmodelIn, playerIn, weaponIn)
		for ent in next, pac.drawn_entities do
			if IsValid(ent) then
				if ent.pac_drawing and ent_parts[ent] then
					pac.RenderOverride(ent, "update", true)
				end
			else
				pac.drawn_entities[ent] = nil
			end
		end
	end)


	local alreadyDrawing = 0

	pac.AddHook("PostDrawViewModel", "draw_firstperson", function(viewmodelIn, playerIn, weaponIn)
		if alreadyDrawing == FrameNumber() then return end

		alreadyDrawing = FrameNumber()

		for ent in next, pac.drawn_entities do
			if IsValid(ent) then
				if ent.pac_drawing and ent_parts[ent] then
					pac.RenderOverride(ent, "viewmodel", true)
				end
			else
				pac.drawn_entities[ent] = nil
			end
		end

		alreadyDrawing = 0
	end)

	local alreadyDrawing = 0
	local redrawCount = 0

	pac.LocalHands = NULL

	pac.AddHook("PostDrawPlayerHands", "draw_firstperson_hands", function(handsIn, viewmodelIn, playerIn, weaponIn)
		if alreadyDrawing == FrameNumber() then
			redrawCount = redrawCount + 1
			if redrawCount >= 5 then return end
		end

		pac.LocalHands = handsIn

		alreadyDrawing = FrameNumber()

		for ent in next, pac.drawn_entities do
			if IsValid(ent) then
				if ent.pac_drawing and ent_parts[ent] then
					pac.RenderOverride(ent, "hands", true)
				end
			else
				pac.drawn_entities[ent] = nil
			end
		end

		alreadyDrawing = 0
		redrawCount = 0
	end)
end
