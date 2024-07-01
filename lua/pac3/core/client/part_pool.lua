local pac = pac

local render_SetColorModulation = render.SetColorModulation
local render_SetBlend = render.SetBlend
local render_ModelMaterialOverride = render.ModelMaterialOverride
local render_MaterialOverride = render.MaterialOverride
local SysTime = SysTime
local IsEntity = IsEntity
local next = next
local pairs = pairs
local NULL = NULL

local entMeta = FindMetaTable("Entity")
local plyMeta = FindMetaTable("Player")
local IsValid = entMeta.IsValid
local IsPlayer = entMeta.IsPlayer
local IsDormant = entMeta.IsDormant
local GetEyePos = entMeta.EyePos
local Alive = plyMeta.Alive
local GetViewModel = plyMeta.GetViewModel
local GetHands = plyMeta.GetHands

local force_rendering = false
local forced_rendering = false

local function IsActuallyValid(ent)
	return IsEntity(ent) and pcall(ent.GetPos, ent)
end

local function IsActuallyPlayer(ent)
	return IsEntity(ent) and pcall(ent.UniqueID, ent)
end

local function IsActuallyRemoved(ent, cb)
	timer.Simple(0, function()
		if not IsValid(ent) then
			cb()
		end
	end)
end

function pac.ForceRendering(b)
	force_rendering = b
	if b then
		forced_rendering = b
	end
end

local ent_parts = _G.pac_local_parts or {}
local all_parts = _G.pac_all_parts or {}
local uid_parts = _G.pac_uid_parts or {}

if game.SinglePlayer() or (player.GetCount() == 1 and LocalPlayer():IsSuperAdmin()) then
	_G.pac_local_parts = ent_parts
	_G.pac_all_parts = all_parts
	_G.pac_uid_parts = uid_parts
end

local function parts_from_uid(owner_id)
	return uid_parts[owner_id] or {}
end

local function parts_from_ent(ent)
	local owner_id = IsValid(ent) and pac.Hash(ent)
	return uid_parts[owner_id] or {}
end

local classtype_viewmodel = "viewmodel"
local classtype_hands = "hands"

do
	local function render_override(ent, type)
		local parts = ent_parts[ent]

		if parts == nil or next(parts) == nil then
			pac.UnhookEntityRender(ent)
			goto CEASE_FUNCTION
		end

		if type == "update_legacy_bones" then
			pac.ResetBones(ent)

			for key, part in next, parts do
				if part:IsValid() then
					if not part:HasParent() then
						part:CallRecursive("BuildBonePositions")
					end
				else
					parts[key] = nil
				end
			end
		elseif type == "update" then
			for key, part in next, parts do
				if part:IsValid() then
					if not part:HasParent() then
						part:CallRecursive("Think")
					end
				else
					parts[key] = nil
				end
			end
		else
			for key, part in next, parts do
				if part:IsValid() then
					if not part:IsDrawHidden()
						and not part:HasParent()
						and ((part.OwnerName == classtype_viewmodel and type == classtype_viewmodel)
						or (part.OwnerName == classtype_hands and type == classtype_hands)
						or (part.OwnerName ~= classtype_viewmodel and part.OwnerName ~= classtype_hands and type ~= classtype_viewmodel and type ~= classtype_hands))
					then
						part:CallRecursive("Draw", type)
					end
				else
					parts[key] = nil
				end
			end
		end

		::CEASE_FUNCTION::

		render_SetColorModulation(1, 1, 1)
		render_SetBlend(1)

		render_MaterialOverride()
		render_ModelMaterialOverride()
	end

	local function on_error(msg)
		ErrorNoHalt(debug.traceback(msg))
	end

	function pac.RenderOverride(ent, type)
		if ent.pac_error then return end

		if pac.IsRenderTimeExceeded(ent) then
			if type == "opaque" then
				pac.DrawRenderTimeExceeded(ent)
			end
			return
		end

		local start = SysTime()
		local ok, err = xpcall(render_override, on_error, ent, type)
		pac.RecordRenderTime(ent, type, start)

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

	function pac.GetRenderTimeInfo(ent)
		return ent.pac_rendertime or {}
	end
end

function pac.HideEntityParts(ent)
	if ent_parts[ent] and ent.pac_drawing then
		for _, part in pairs(ent_parts[ent]) do
			part:HideFromRendering()
		end

		pac.ResetBones(ent)
		ent.pac_drawing = false
	end
end

function pac.ShowEntityParts(ent)
	if not ent_parts[ent] or ent.pac_shouldnotdraw or ent.pac_ignored then return end

	if not ent.pac_drawing then
		for _, part in pairs(ent_parts[ent]) do
			part:ShowFromRendering()
		end

		pac.ResetBones(ent)
		ent.pac_drawing = true
		ent.pac_error = nil
	elseif ent.pac_fix_show_from_render and ent.pac_fix_show_from_render < SysTime() then
		for _, part in pairs(ent_parts[ent]) do
			part:ShowFromRendering()
		end

		ent.pac_fix_show_from_render = nil
	end
end

function pac.EnableDrawnEntities(bool)
	for ent in next, pac.drawn_entities do
		if IsValid(ent) then
			if bool then
				pac.ShowEntityParts(ent)
			else
				pac.HideEntityParts(ent)
			end
		else
			pac.drawn_entities[ent] = nil
		end
	end
end

function pac.HookEntityRender(ent, part)
	local parts = ent_parts[ent]

	if not parts then
		parts = {}
		ent_parts[ent] = parts
	end

	if parts[part] then
		return false
	end

	pac.dprint("hooking render on %s to draw part %s", tostring(ent), tostring(part))

	pac.drawn_entities[ent] = true

	parts[part] = part

	ent.pac_has_parts = true

	part:ShowFromRendering()
	return true
end

function pac.UnhookEntityRender(ent, part)
	if part and ent_parts[ent] then
		ent_parts[ent][part] = nil
	end

	if (ent_parts[ent] and not next(ent_parts[ent])) or not part then
		ent_parts[ent] = nil
		ent.pac_has_parts = nil
		pac.drawn_entities[ent] = nil

		if ent.pac_bones_once then
			pac.ResetBones(ent)
			ent.pac_bones_once = nil
		end
	end

	if part then
		part:HideFromRendering()
	end
end

pac.AddHook("Think", "events", function()
	for _, ply in player.Iterator() do
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
		if not IsValid(rag) then
			pac.HideEntityParts(ply)
			continue
		end

		-- so it only runs once
		if ply.pac_ragdoll == rag then continue end
		ply.pac_ragdoll = rag
		rag.pac_ragdoll_owner = ply

		rag = hook.Run("PACChooseDeathRagdoll", ply, rag) or rag

		if ply.pac_death_physics_parts then
			if ply.pac_physics_died then return end

			for _, part in next, parts_from_uid(pac.Hash(ply)) do
				if part.is_model_part then
					local ent = part:GetOwner()
					if IsValid(ent) then
						rag:SetNoDraw(true)

						part.skip_orient = true

						ent:SetParent(NULL)
						ent:SetNoDraw(true)
						ent:PhysicsInitBox(Vector(1, 1, 1) * -5, Vector(1, 1, 1) * 5)
						ent:SetCollisionGroup(COLLISION_GROUP_DEBRIS)

						local phys = ent:GetPhysicsObject()
						phys:AddAngleVelocity(VectorRand() * 1000)
						phys:AddVelocity(ply:GetVelocity() + VectorRand() * 30)
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

			for _, part in next, ent_parts[ply] do
				part:SetOwner(rag)
			end

			rag:SetOwner(ply)
			pac.ShowEntityParts(rag)

			ply.pac_revert_ragdoll = function()
				ply.pac_ragdoll = nil

				if not ent_parts[ply] then return end

				pac.HideEntityParts(rag)

				for _, part in next, ent_parts[ply] do
					part:SetOwner(ply)
				end

				pac.ShowEntityParts(ply)
			end
		end
	end

	if pac.last_flashlight_on ~= pac.LocalPlayer:FlashlightIsOn() then
		local lamp = ProjectedTexture()

		lamp:SetTexture("effects/flashlight001")
		lamp:SetFarZ(5000)
		lamp:SetColor(Color(0, 0, 0, 255))

		lamp:SetPos(GetEyePos(pac.LocalPlayer) - pac.LocalPlayer:GetAimVector() * 400)
		lamp:SetAngles(pac.LocalPlayer:EyeAngles())
		lamp:Update()

		pac.AddHook("PostRender", "flashlight_stuck_fix", function()
			pac.RemoveHook("PostRender", "flashlight_stuck_fix")
			lamp:Remove()
		end)

		pac.last_flashlight_on = pac.LocalPlayer:FlashlightIsOn()
	end

	for ent in next, pac.drawn_entities do
		if IsValid(ent) then
			if ent.pac_drawing and IsPlayer(ent) then
				ent.pac_traceres = util.QuickTrace(GetEyePos(ent), ent:GetAimVector() * 32000, {ent, ent:GetVehicle(), ent:GetOwner()})
				ent.pac_hitpos = ent.pac_traceres.HitPos
			end
		else
			pac.drawn_entities[ent] = nil
		end
	end

	if pac.next_frame_funcs then
		for _, fcall in next, pac.next_frame_funcs do
			fcall()
		end

		-- table.Empty is also based on undefined behavior
		-- god damnit
		local func_keys = table.GetKeys(pac.next_frame_funcs)
		for i = 1, #func_keys do
			pac.next_frame_funcs[func_keys[i]] = nil
		end
	end

	if pac.next_frame_funcs_simple and pac.next_frame_funcs_simple[1] then
		for i = 1, #pac.next_frame_funcs_simple do
			pac.next_frame_funcs_simple[i]()
		end

		for i = #pac.next_frame_funcs_simple, 1, -1 do
			pac.next_frame_funcs_simple[i] = nil
		end
	end
end)

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
							if part.ClassName == "group" then
								if part:GetOwnerName() == classtype_hands then
									part:UpdateOwnerName()
								end
								part:HideInvalidOwners()
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

	if IsActuallyValid(owner) and (not IsPlayer(owner) or IsActuallyPlayer(owner)) then
		for _, part in pairs(parts_from_ent(owner)) do
			if part.ClassName == "group" then
				part:UpdateOwnerName(ent, false)
			end
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

function pac.UpdatePartsWithMetatable(META)
	for _, part in pairs(all_parts) do
		if META.ClassName == part.ClassName then
			for k, v in pairs(META) do
				-- update part functions only
				-- updating variables might mess things up
				if isfunction(v) then
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

	pac.NotifyPartCreated(part)
end

function pac.AddPart(part)
	all_parts[part.Id] = part
end

function pac.RemovePart(part)
	all_parts[part.Id] = nil
end

function pac.GetLocalParts()
	return uid_parts[pac.Hash(pac.LocalPlayer)] or {}
end

function pac.GetPartFromUniqueID(owner_id, id)
	return uid_parts[owner_id] and uid_parts[owner_id][id] or NULL
end

function pac.FindPartByPartialUniqueID(owner_id, crumb)
	if not crumb then return NULL end
	if not isstring(crumb) then return NULL end
	if #crumb <= 3 then return NULL end
	local closest_match
	local length_of_closest_match = 0
	if uid_parts[owner_id] then
		if uid_parts[owner_id][crumb] then
			return uid_parts[owner_id][crumb]
		end

		for _, part in pairs(uid_parts[owner_id]) do
			local start_i,end_i = string.find(part.UniqueID, crumb)
			if start_i or end_i then
				closest_match = part
				if length_of_closest_match < end_i - start_i + 1 then
					closest_match = part
					length_of_closest_match = end_i - start_i + 1
				end

			end
		end

	end
	return closest_match or NULL
end

function pac.FindPartByName(owner_id, str, exclude)
	if uid_parts[owner_id] then
		if uid_parts[owner_id][str] then
			return uid_parts[owner_id][str]
		end

		for _, part in pairs(uid_parts[owner_id]) do
			if part == exclude then continue end
			if part:GetName() == str then
				return part
			end
		end

		for _, part in pairs(uid_parts[owner_id]) do
			if part == exclude then continue end
			if pac.StringFind(part:GetName(), str) then
				return part
			end
		end

		for _, part in pairs(uid_parts[owner_id]) do
			if part == exclude then continue end
			if pac.StringFind(part:GetName(), str, true) then
				return part
			end
		end
	end

	return NULL
end

function pac.GetLocalPart(id)
	local owner_id = pac.Hash(pac.LocalPlayer)
	return uid_parts[owner_id] and uid_parts[owner_id][id] or NULL
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

function pac.NotifyPartCreated(part)
	local owner_id = part:GetPlayerOwnerId()
	if not uid_parts[owner_id] then return end

	for _, p in pairs(uid_parts[owner_id]) do
		p:OnOtherPartCreated(part)

		if part:GetPlayerOwner() == pac.LocalPlayer then
			pac.CallHook("OnPartCreated", part)
		end
	end
end

function pac.CallRecursiveOnAllParts(func_name, ...)
	for _, part in pairs(all_parts) do
		if part[func_name] then
			local ret = part[func_name](part, ...)
			if ret ~= nil then
				return ret
			end
		end
	end
end

function pac.CallRecursiveOnOwnedParts(ent, func_name, ...)
	local owned_parts = parts_from_ent(ent)
	for _, part in pairs(owned_parts) do
		if part[func_name] then
			local ret = part[func_name](part, ...)
			if ret ~= nil then
				return ret
			end
		end
	end
end

function pac.EnablePartsByClass(classname, enable)
	for _, part in pairs(all_parts) do
		if part.ClassName == classname then
			part:SetEnabled(enable)
		end
	end
end

function pac.UpdateButtonEvents(ply, key, down)
	for _,part in pairs(all_parts) do
		if part:GetPlayerOwner() == ply and part.ClassName == "event" and part.Event == "button" then
			part.pac_broadcasted_buttons_holduntil = part.pac_broadcasted_buttons_holduntil or {}
			part.holdtime = part.holdtime or 0
			part.toggleimpulsekey = part.toggleimpulsekey or {}
			part.toggleimpulsekey[key] = down
			part.pac_broadcasted_buttons_holduntil[key] = part.pac_broadcasted_buttons_holduntil[key] or 0
			ply.pac_broadcasted_buttons_lastpressed[key] = ply.pac_broadcasted_buttons_lastpressed[key] or 0
			part.pac_broadcasted_buttons_holduntil[key] = ply.pac_broadcasted_buttons_lastpressed[key] + part.holdtime
		end
	end
end

function pac.StopSound()
	for _,part in pairs(all_parts) do
		if part.ClassName == "sound" or part.ClassName == "sound2" or part.ClassName == "ogg" or part.ClassName == "webaudio" then
			part:StopSound(true)
		end
	end
end

function pac.ForceUpdateSoundVolumes()
	for _,part in pairs(all_parts) do
		if part.ClassName == "sound" then
			if part.csptch then part.csptch:ChangeVolume(math.Clamp(part.Volume * pac.volume, 0.001, 1), 0) end
		elseif part.ClassName == "sound2" or part.ClassName == "ogg" then
			if part.last_stream and part.last_stream.SetVolume then part.last_stream:SetVolume(part.Volume * pac.volume) end
		elseif part.ClassName == "webaudio" then
			for key, stream in pairs(part.streams) do
				if stream and stream.SetVolume then stream:SetVolume(part.Volume * pac.volume) end
			end
		end
	end
end

cvars.AddChangeCallback("pac_hide_disturbing", function()
	for _, part in pairs(all_parts) do
		if part:IsValid() then
			part:UpdateIsDisturbing()
		end
	end
end, "PAC3")

do -- drawing
	local pac = pac

	local FrameNumber = FrameNumber
	local RealTime = RealTime
	local EF_BONEMERGE = EF_BONEMERGE
	local RENDERMODE_TRANSALPHA = RENDERMODE_TRANSALPHA

	local cvar_distance = CreateClientConVar("pac_draw_distance", "500")

	pac.Errors = {}
	pac.firstperson_parts = pac.firstperson_parts or {}
	pac.EyePos = vector_origin
	pac.drawn_entities = pac.drawn_entities or {}
	pac.RealTime = 0
	pac.FrameNumber = 0

	local skip_frames = CreateConVar("pac_optimization_render_once_per_frame", "0", {FCVAR_ARCHIVE}, "render only once per frame (will break water reflections and vr)")

	local function setup_suppress()
		local last_framenumber = 0
		local current_frame = 0
		local current_frame_count = 0

		return function(force)
			if not force and (force_rendering or not skip_frames:GetBool()) then
				return
			end

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

	do
		local draw_dist = 0
		local sv_draw_dist = 0
		local dst = 0

		local localplayer
		local pac_sv_draw_distance

		pac.AddHook("Think", "update_parts", function()
			localplayer = localplayer or LocalPlayer()	-- LocalPlayer never changes once its valid, right?

			-- commonly used variables
			pac.LocalPlayer = localplayer
			pac.LocalViewModel = GetViewModel(localplayer)
			pac.LocalHands = GetHands(localplayer)
			pac.RealTime = RealTime()
			pac.FrameNumber = pac.FrameNumber + 1

			pac_sv_draw_distance = pac_sv_draw_distance or GetConVar("pac_sv_draw_distance")

			draw_dist = cvar_distance:GetInt()
			sv_draw_dist = pac_sv_draw_distance:GetFloat()

			if draw_dist <= 0 then
				draw_dist = 32768
			end

			if sv_draw_dist <= 0 then
				sv_draw_dist = 32768
			end

			-- square the dist vars to fit with dst which uses DistToSqr for efficiency
			sv_draw_dist = sv_draw_dist ^ 2
			draw_dist = draw_dist ^ 2

			if draw_dist > sv_draw_dist then
				draw_dist = sv_draw_dist
			end

			for ent in next, pac.drawn_entities do
				if not IsValid(ent) then
					pac.drawn_entities[ent] = nil
					goto CONTINUE
				end

				if IsDormant(ent) then goto CONTINUE end

				pac.ResetRenderTime(ent)

				dst = GetEyePos(ent):DistToSqr(pac.EyePos)

				if IsPlayer(ent) or IsValid(ent.pac_ragdoll_owner) then
					local ply = ent.pac_ragdoll_owner or ent
					local rag = ply.pac_ragdoll

					if IsValid(rag) and (ply.pac_death_hide_ragdoll or ply.pac_draw_player_on_death) then
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

				-- if it's a world entity always draw
				local cond = ent.IsPACWorldEntity

				-- if the entity is the hands, check if we should not draw the localplayer
				if (ent == pac.LocalHands or ent == pac.LocalViewModel) and not localplayer:ShouldDrawLocalPlayer() then
					cond = true
				end

				-- if it's a player, draw if we can see them
				if not cond and ent == localplayer then
					cond = ent:ShouldDrawLocalPlayer()
				end

				-- if the entity has a camera part, draw if it's valid
				if not cond and ent.pac_camera then
					cond = ent.pac_camera:IsValid()
				end

				-- if the condition is not satisified, check draw distance
				if not cond and ent ~= localplayer then
					if ent.pac_draw_distance then
						-- custom draw distance - is it 0 for infinite range, or under the custom distance (squared to fit with DistToSqr)
						cond = ent.pac_draw_distance <= 0 or dst <= (ent.pac_draw_distance ^ 2)
					else
						-- otherwise check the cvar
						cond = dst <= draw_dist
					end
				end

				ent.pac_is_drawing = cond

				if cond then
					pac.ShowEntityParts(ent)
					pac.RenderOverride(ent, "update")
				else
					if forced_rendering then
						forced_rendering = false
						return
					end

					pac.HideEntityParts(ent)
				end

				::CONTINUE::
			end

			-- we increment the framenumber here because we want to invalidate any FrameNumber caches when we draw
			-- this prevents functions like movable:GetWorldMatrix() from caching the matrix in the update hook
			pac.FrameNumber = pac.FrameNumber + 1
		end)
	end

	local setupBonesGuard = false
	function pac.SetupBones(ent)
		-- Reentrant protection
		if setupBonesGuard then return end
		setupBonesGuard = true
		local ok, err = pcall(ent.SetupBones, ent)
		setupBonesGuard = false
		if not ok then error(err) end
	end

	local skybox_nwkey = "pac_in_skybox"

	do
		local should_suppress = setup_suppress()

		pac.AddHook("PreDrawOpaqueRenderables", "draw_opaque", function(bDrawingDepth, bDrawingSkybox)
			if should_suppress(true) then return end

			for ent in next, pac.drawn_entities do
				if ent.pac_is_drawing
					and ent_parts[ent]	-- accessing table of NULL doesn't do anything
					and not IsDormant(ent)
				then
					pac.RenderOverride(ent, "update_legacy_bones")
				end
			end
		end)

		local should_suppress = setup_suppress()

		pac.AddHook("PostDrawOpaqueRenderables", "draw_opaque", function(bDrawingDepth, bDrawingSkybox, isDraw3DSkybox)
			if should_suppress() then return end

			for ent in next, pac.drawn_entities do
				if ent.pac_is_drawing
					and ent_parts[ent]	-- accessing table of NULL doesn't do anything
					and not IsDormant(ent)
					and (not isDraw3DSkybox or ent:GetNW2Bool(skybox_nwkey))
				then
					pac.RenderOverride(ent, "opaque")
				end
			end
		end)
	end

	do
		local should_suppress = setup_suppress()

		pac.AddHook("PostDrawTranslucentRenderables", "draw_translucent", function(bDrawingDepth, bDrawingSkybox, isDraw3DSkybox)
			if should_suppress() then return end

			for ent in next, pac.drawn_entities do
				if ent.pac_is_drawing
					and ent_parts[ent]	-- accessing table of NULL doesn't do anything
					and not IsDormant(ent)
					and (not isDraw3DSkybox or ent:GetNW2Bool(skybox_nwkey))
				then
					pac.RenderOverride(ent, "translucent")
				end
			end
		end)
	end

	pac.AddHook("UpdateAnimation", "update_animation_parts", function(ply)
		if ply.pac_is_drawing and ent_parts[ply] then -- accessing table of NULL doesn't do anything
			local parts = ent_parts[ply]
			for _, part in next, parts do
				part:CallRecursive("OnUpdateAnimation", ply)
			end
		end
	end)

	local drawing_viewmodel = false
	pac.AddHook("PostDrawViewModel", "draw_firstperson", function(viewmodelIn, playerIn, weaponIn)
		if drawing_viewmodel then return end

		for ent in next, pac.drawn_entities do
			if IsValid(ent) then
				if ent.pac_drawing and ent_parts[ent] then
					drawing_viewmodel = true
					pac.RenderOverride(ent, classtype_viewmodel)
					drawing_viewmodel = false
				end
			else
				pac.drawn_entities[ent] = nil
			end
		end
	end)

	local drawing_hands = false
	pac.AddHook("PostDrawPlayerHands", "draw_firstperson_hands", function(handsIn, viewmodelIn, playerIn, weaponIn)
		if drawing_hands then return end

		for ent in next, pac.drawn_entities do
			if IsValid(ent) then
				if ent.pac_drawing and ent_parts[ent] then
					drawing_hands = true
					pac.RenderOverride(ent, classtype_hands)
					drawing_hands = false
				end
			else
				pac.drawn_entities[ent] = nil
			end
		end
	end)
end
