function pac.UpdateAnimation(ply)
	if not IsEntity(ply) or not ply:IsValid() then return end
		
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
end
pac.AddHook("UpdateAnimation")

function pac.TranslateActivity(ply, act)
	if IsEntity(ply) and ply:IsValid() then
	
		-- animation part
		if ply.pac_holdtype and ply.pac_holdtype[act] then
			return ply.pac_holdtype[act]
		end
		
		-- holdtype part
		if ply.pac_acttable then
			if ply.pac_acttable[act] and ply.pac_acttable[act] ~= -1 then
				return ply.pac_acttable[act]
			end
			
			if ply:GetVehicle():IsValid() and ply:GetVehicle():GetClass() == "prop_vehicle_prisoner_pod" then
				return ply.pac_acttable.sitting
			end
			
			if ply.pac_acttable.noclip ~= -1 and ply:GetMoveType() == MOVETYPE_NOCLIP then
				return ply.pac_acttable.noclip
			end
			
			if ply.pac_acttable.air ~= -1 and ply:GetMoveType() ~= MOVETYPE_NOCLIP and not ply:IsOnGround() then
				return ply.pac_acttable.air
			end	
		
			if ply.pac_acttable.fallback ~= -1 then
				return ply.pac_acttable.fallback
			end
		end
	end
end
pac.AddHook("TranslateActivity")


function pac.CalcMainActivity(ply, act) 
	if IsEntity(ply) and ply:IsValid() and ply.pac_sequence then
		return ply.pac_sequence, ply.pac_sequence
	end
end
pac.AddHook("CalcMainActivity")

function pac.pac_PlayerFootstep(ply, pos, snd, vol)
	ply.pac_last_footstep_pos = pos	

	if ply.pac_footstep_override then
		for key, part in pairs(ply.pac_footstep_override) do
			if not part:IsHidden() then
				part:PlaySound(snd, vol)
			end
		end
	end
	
	if ply.pac_mute_footsteps then
		return true
	end
end
pac.AddHook("pac_PlayerFootstep")

function pac.OnEntityCreated(ent)
	if ent:IsValid() and ent:GetOwner():IsPlayer() then
		for key, part in pairs(pac.GetParts()) do
			if not part:HasParent() and part:GetPlayerOwner() == ent:GetOwner() then
				part:CheckOwner(ent, false)
			end
		end
	end
end
pac.AddHook("OnEntityCreated")

function pac.EntityRemoved(ent)
	if ent:IsValid() and ent:GetOwner():IsPlayer() then
		for key, part in pairs(pac.GetParts()) do
			if not part:HasParent() and part:GetPlayerOwner() == ent:GetOwner() then
				part:CheckOwner(ent, true)
			end
		end
	end
end
pac.AddHook("EntityRemoved")

timer.Create("pac_gc", 2, 0, function()
	for key, part in pairs(pac.GetParts()) do
		if not part:GetPlayerOwner():IsValid() then
			part:Remove()
		end
	end
end)

net.Receive("pac_effect_precached", function()
	local name = net.ReadString()
	pac.CallHook("EffectPrecached", name)
end)