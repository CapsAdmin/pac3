local MOVETYPE_NOCLIP = MOVETYPE_NOCLIP
local IN_SPEED = IN_SPEED
local SOLID_NONE = SOLID_NONE
local MOVETYPE_NONE = MOVETYPE_NONE
local IN_WALK = IN_WALK
local IN_DUCK = IN_DUCK

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
		for _, part in pairs(ply.pac_footstep_override) do
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

function pac.InitDeathPhysicsOnProp(part,ply,plyent)
	local ent = part:GetEntity()
	if not ent:IsValid() then return end

	plyent:SetNoDraw(true)
	part.skip_orient = true

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

function pac.NetworkEntityCreated(ply)
	if not ply:IsPlayer() then return end

	if ply.pac_player_size then
		pac.SetPlayerSize(ply,ply.pac_player_size,true)
	end

end
pac.AddHook("NetworkEntityCreated")

function pac.NotifyShouldTransmit(ent,st)
	if not st then return end
	if ent:IsPlayer() then
		local ply = ent
		if ply.pac_player_size then
			pac.SetPlayerSize(ply,ply.pac_player_size,true)
			timer.Simple(0,function()
				if not ply:IsValid() then return end
				if ply.pac_player_size then
					pac.SetPlayerSize(ply,ply.pac_player_size,true)
				end
			end)
		end
	end
end
pac.AddHook("NotifyShouldTransmit")

net.Receive("pac_effect_precached", function()
	local name = net.ReadString()
	pac.CallHook("EffectPrecached", name)
end)