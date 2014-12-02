function pac.UpdateAnimation(ply)
	if not IsEntity(ply) or not ply:IsValid() then return end
		
	if ply.pac_death_physics_parts and ply:Alive() and ply.pac_physics_died then
		for _, part in pairs(pac.GetParts()) do
			if part:GetPlayerOwner() == ply and part.ClassName == "model" then
				local ent = part:GetEntity()
				ent:PhysicsInit(SOLID_NONE)
				ent:SetMoveType(MOVETYPE_NONE)
				ent:SetNoDraw(true)
				ent.RenderOverride = nil
				
				part.skip_orient = false
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
	
	if ply.pac_bodygroup_info then
		ply:SetBodygroup(ply.pac_bodygroup_info.id, ply.pac_bodygroup_info.model_index)
	end
end
pac.AddHook("UpdateAnimation")

local function mod_speed(cmd, speed)
	if speed and speed ~= 0 then
		local forward = cmd:GetForwardMove()
		forward = forward > 0 and speed or forward < 0 and -speed or 0
		
		local side = cmd:GetSideMove()
		side = side > 0 and speed or side < 0 and -speed or 0
		
		
		cmd:SetForwardMove(forward)
		cmd:SetSideMove(side)
	end	
end

function pac.CreateMove(cmd)
	if cmd:KeyDown(IN_SPEED) then
		mod_speed(cmd, pac.LocalPlayer.pac_sprint_speed)
	elseif cmd:KeyDown(IN_WALK) then
		mod_speed(cmd, pac.LocalPlayer.pac_walk_speed)
	elseif cmd:KeyDown(IN_DUCK) then
		mod_speed(cmd, pac.LocalPlayer.pac_crouch_speed)
	else
		mod_speed(cmd, pac.LocalPlayer.pac_run_speed)
	end
end
pac.AddHook("CreateMove")

function pac.TranslateActivity(ply, act)
	if IsEntity(ply) and ply:IsValid() then
	
		-- animation part
		if ply.pac_animation_sequences and next(ply.pac_animation_sequences) then
			-- dont do any holdtype stuff if theres a sequence
			return
		end
		
		if ply.pac_animation_holdtypes then
			local key, val = next(ply.pac_animation_holdtypes)
			if key then			
				if not val.part:IsValid() then
					ply.pac_animation_holdtypes[key] = nil
				else
					return val[act]
				end
			end
		end
		
		-- holdtype part
		if ply.pac_holdtypes then
			local key, act_table = next(ply.pac_holdtypes)
			
			if key then
				if not act_table.part:IsValid() then
					ply.pac_holdtypes[key] = nil
				else
					
					if act_table[act] and act_table[act] ~= -1 then
						return act_table[act]
					end
					
					if ply:GetVehicle():IsValid() and ply:GetVehicle():GetClass() == "prop_vehicle_prisoner_pod" then
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
	end
end
pac.AddHook("TranslateActivity")


function pac.CalcMainActivity(ply, act) 
	if IsEntity(ply) and ply:IsValid() and ply.pac_animation_sequences then
		local key, val = next(ply.pac_animation_sequences)
		
		if not key then return end
		
		if not val.part:IsValid() then
			ply.pac_animation_sequences[key] = nil
			return
		end
		
		return val.seq, val.seq
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

local function IsActuallyValid(ent)
	return IsEntity(ent) and pcall(ent.GetPos, ent)
end

local function IsActuallyPlayer(ent)
	return IsEntity(ent) and pcall(ent.UniqueID, ent)
end

function pac.OnEntityCreated(ent)
	if IsActuallyValid(ent) then
		if ent:GetClass() == "class C_HL2MPRagdoll" then
			for key, ply in pairs(player.GetAll()) do
				if ply:GetRagdollEntity() == ent then
					if ply.pac_parts then
						if ply.pac_death_physics_parts then
							if not ply.pac_physics_died then
								for _, part in pairs(pac.GetPartsFromUniqueID(ply:UniqueID())) do
									if part.ClassName == "model" then
										ent:SetNoDraw(true)
										
										part.skip_orient = true
										
										local ent = part:GetEntity()
										ent:SetParent(NULL)
										ent:SetNoDraw(true)
										ent:PhysicsInitBox(Vector(1,1,1) * -5, Vector(1,1,1) * 5)
										ent:SetCollisionGroup(COLLISION_GROUP_DEBRIS) 
										
										local phys = ent:GetPhysicsObject()
										phys:AddAngleVelocity(VectorRand() * 1000)
										phys:AddVelocity(ply:GetVelocity()  + VectorRand() * 30)
										phys:Wake()
										
										function ent.RenderOverride(ent)
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
								ply.pac_physics_died = true
							end
						else
							timer.Create("pac_" .. ply:UniqueID() .. "_ragttach", 0.25, 1, function()
								local parts = ply.pac_parts
							
								for key, part in pairs(parts) do
									if not part.last_owner then
										part:SetOwner(ent)
										part.last_owner = ent
									end
								end
							end)
						end
					end
					
					break
				end
			end
		end
		
		local owner = ent:GetOwner()
		
		if IsActuallyValid(owner) and IsActuallyPlayer(owner) then
			for key, part in pairs(pac.GetPartsFromUniqueID(owner:UniqueID())) do
				if not part:HasParent() then
					part:CheckOwner(ent, false)
				end
			end
		end
	end
end
pac.AddHook("OnEntityCreated")

function pac.PlayerSpawned(ply)
	if ply.pac_parts then
		for key, part in pairs(ply.pac_parts) do
			if part.last_owner and part.last_owner:IsValid() then
				part:SetOwner(ent)
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
			for key, part in pairs(pac.GetPartsFromUniqueID(owner:UniqueID())) do
				if not part:HasParent() then
					part:CheckOwner(ent, true)
				end
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