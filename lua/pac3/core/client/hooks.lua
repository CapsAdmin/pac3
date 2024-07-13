local MOVETYPE_NOCLIP = MOVETYPE_NOCLIP
local next = next
local IsEntity = IsEntity

local entMeta = FindMetaTable("Entity")
local IsEntValid = entMeta.IsValid
local GetTable = entMeta.GetTable
local SetCycle = entMeta.SetCycle
local SetPoseParameter = entMeta.SetPoseParameter

local classname_prisoner_pod = "prop_vehicle_prisoner_pod"

pac.AddHook("RenderScene", "eyeangles_eyepos", function(pos, ang)
	pac.EyePos = pos
	pac.EyeAng = ang
end)

pac.AddHook("DrawPhysgunBeam", "physgun_event", function(ply, wep, enabled, target, bone, hitpos)
	if enabled then
		ply.pac_drawphysgun_event = {ply, wep, enabled, target, bone, hitpos}
	else
		ply.pac_drawphysgun_event = nil
	end

	local pac_drawphysgun_event_part = ply.pac_drawphysgun_event_part
	if pac_drawphysgun_event_part then
		for event in next, pac_drawphysgun_event_part do
			if event:IsValid() then
				event:OnThink()
			else
				pac_drawphysgun_event_part[event] = nil
			end
		end
	end

	if ply.pac_hide_physgun_beam then
		return false
	end
end)

do
	pac.AddHook("UpdateAnimation", "event_part", function(ply)
		if not IsEntity(ply) or not IsEntValid(ply) then return end
		local plyTbl = GetTable(ply)

		if plyTbl.pac_death_physics_parts and ply:Alive() and plyTbl.pac_physics_died then
			pac.CallRecursiveOnOwnedParts(ply, "OnBecomePhysics")
			plyTbl.pac_physics_died = false
		end

		do
			local tbl = plyTbl.pac_pose_params

			if tbl then
				for _, data in next, tbl do
					SetPoseParameter(ply, data.key, data.val)
				end
			end
		end

		local animrate = 1

		if plyTbl.pac_global_animation_rate and plyTbl.pac_global_animation_rate ~= 1 then
			if plyTbl.pac_global_animation_rate == 0 then
				animrate = ply:GetModelScale() * 2
			elseif plyTbl.pac_global_animation_rate ~= 1 then
				SetCycle(ply, (pac.RealTime * plyTbl.pac_global_animation_rate) % 1)

				animrate = plyTbl.pac_global_animation_rate
			end
		end

		if plyTbl.pac_animation_sequences then
			local part, thing = next(plyTbl.pac_animation_sequences)

			if part and part:IsValid() then
				if part.OwnerCycle then
					if part.Rate == 0 then
						animrate = 1
						SetCycle(ply, part.Offset % 1)
					else
						animrate = animrate * part.Rate
					end
				end
			elseif part and not part:IsValid() then
				plyTbl.pac_animation_sequences[part] = nil
			end
		end

		if animrate ~= 1 then
			SetCycle(ply, (pac.RealTime * animrate) % 1)
			return true
		end

		if plyTbl.pac_holdtype_alternative_animation_rate then
			local length = ply:GetVelocity():Dot(ply:GetAimVector()) > 0 and 1 or -1
			local scale = ply:GetModelScale() * 2

			if scale ~= 0 then
				SetCycle(ply, pac.RealTime / scale * length)
			else
				SetCycle(ply, 0)
			end

			return true
		end

		local vehicle = ply:GetVehicle()

		if plyTbl.pac_last_vehicle ~= vehicle then
			if plyTbl.pac_last_vehicle ~= nil then
				pac.CallRecursiveOnAllParts("OnVehicleChanged", ply, vehicle)
			end
			plyTbl.pac_last_vehicle = vehicle
		end
	end)
end

pac.AddHook("TranslateActivity", "events", function(ply, act)
	if not IsEntity(ply) or not IsEntValid(ply) then return end
	local plyTbl = GetTable(ply)

	-- animation part
	if plyTbl.pac_animation_sequences and next(plyTbl.pac_animation_sequences) then
		-- dont do any holdtype stuff if theres a sequence
		return
	end

	if plyTbl.pac_animation_holdtypes then
		local key, val = next(plyTbl.pac_animation_holdtypes)
		if key then
			if not val.part:IsValid() then
				plyTbl.pac_animation_holdtypes[key] = nil
			else
				return val[act]
			end
		end
	end

	-- holdtype part
	if plyTbl.pac_holdtypes then
		local key, act_table = next(plyTbl.pac_holdtypes)

		if key then
			if not act_table.part:IsValid() then
				plyTbl.pac_holdtypes[key] = nil
			else
				if act_table[act] and act_table[act] ~= -1 then
					return act_table[act]
				end

				local vehicle = ply:GetVehicle()

				if IsEntValid(vehicle) and vehicle:GetClass() == classname_prisoner_pod then
					return act_table.sitting
				end

				if act_table.noclip ~= -1 and ply:GetMoveType() == MOVETYPE_NOCLIP then
					return act_table.noclip
				end

				if act_table.air ~= -1 and ply:GetMoveType() ~= MOVETYPE_NOCLIP and not ply:IsOnGround() then
					return act_table.air
				end

				if act_table.fallback ~= -1 then
					return act_table.fallback
				end
			end
		end
	end
end)

pac.AddHook("CalcMainActivity", "events", function(ply, act)
	if not IsEntity(ply) or not IsEntValid(ply) then return end
	local plyTbl = GetTable(ply)

	if plyTbl.pac_animation_sequences then
		local key, val = next(plyTbl.pac_animation_sequences)

		if not key then return end

		if not val.part:IsValid() then
			plyTbl.pac_animation_sequences[key] = nil
			return
		end

		return val.seq, val.seq
	end
end)

pac.AddHook("pac_PlayerFootstep", "events", function(ply, pos, snd, vol)
	ply.pac_last_footstep_pos = pos

	if ply.pac_footstep_override then
		for _, part in next, ply.pac_footstep_override do
			if not part:IsHidden() then
				part:PlaySound(snd, vol)
			end
		end
	end

	if ply.pac_mute_footsteps then
		return true
	end
end)

net.Receive("pac_effect_precached", function()
	local name = net.ReadString()
	pac.CallHook("EffectPrecached", name)
end)
