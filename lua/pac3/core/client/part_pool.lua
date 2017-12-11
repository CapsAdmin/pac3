
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
end)

pac.AddHook("OnEntityCreated", function(ent)
	if not IsActuallyValid(ent) then return end

	local owner = ent:GetOwner()

	if IsActuallyValid(owner) and IsActuallyPlayer(owner) then
		for _, part in pairs(parts_from_uid(owner:UniqueID())) do
			if not part:HasParent() then
				part:CheckOwner(ent, false)
			end
		end
	end
end)

timer.Create("pac_gc", 2, 0, function()
	for ent, parts in pairs(ent_parts) do
		if not ent:IsValid() then
			for _, v in pairs(parts) do
				v:Remove()
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

function pac.GetPropertyFromName(func, name, ply_owner)
	for _, part in pairs(parts_from_uid(ply_owner:UniqueID())) do
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
	return uid_parts[pac.LocalPlayer:UniqueID()]
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