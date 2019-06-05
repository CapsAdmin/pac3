CreateConVar("pac_free_movement", -1, CLIENT and {FCVAR_REPLICATED} or {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "allow players to modify movement. -1 apply only allow when noclip is allowed, 1 allow for all gamemodes, 0 to disable")

local default = {}
default.JumpHeight = 200
default.StickToGround = true
default.GroundFriction = 0.12
default.AirFriction = 0.01
default.Gravity = Vector(0,0,-600)
default.Noclip = false
default.MaxGroundSpeed = 750
default.MaxAirSpeed = 1
default.AllowZVelocity = false
default.ReversePitch = false
default.UnlockPitch = false
default.VelocityToViewAngles = 0
default.RollAmount = 0

default.SprintSpeed = 750
default.RunSpeed = 300
default.WalkSpeed = 100
default.DuckSpeed = 25

default.FinEfficiency = 0
default.FinLiftMode = "normal"
default.FinCline = false

if SERVER then
	util.AddNetworkString("pac_modify_movement")

	net.Receive("pac_modify_movement", function(len, ply)
		local cvar = GetConVarNumber("pac_free_movement")
		if cvar == 1 or (cvar == -1 and hook.Run("PlayerNoClip", ply, true)) then
			local str = net.ReadString()
			if str == "disable" then
				ply.pac_movement = nil
			else
				if default[str] ~= nil then
					local val = net.ReadType()
					if type(val) == type(default[str]) then
						ply.pac_movement = ply.pac_movement or table.Copy(default)
						ply.pac_movement[str] = val
					end
				end
			end
		end
	end)
end

if CLIENT then
	pac.AddHook("InputMouseApply", "custom_movement", function(cmd, x,y, ang)
		local ply = LocalPlayer()
		local self = ply.pac_movement
		if not self then return end

		if ply:GetMoveType() == MOVETYPE_NOCLIP then
			if ply.pac_movement_viewang then
				ang.r = 0
				cmd:SetViewAngles(ang)
				ply.pac_movement_viewang = nil
			end
			return
		end

		if self.UnlockPitch then
			ply.pac_movement_viewang = ply.pac_movement_viewang or ang
			ang = ply.pac_movement_viewang

			local sens = GetConVarNumber("sensitivity") * 20
			x = x / sens
			y = y / sens

			if ang.p > 89 or ang.p < -89 then
				x = -x
			end

			ang.p = math.NormalizeAngle(ang.p + y)
			ang.y = math.NormalizeAngle(ang.y + -x)
		end

		if self.ReversePitch then
			ang.p = -ang.p
		end

		local vel = ply:GetVelocity()

		local roll = math.Clamp(vel:Dot(-ang:Right()) * self.RollAmount, -89, 89)
		if not vel:IsZero() then
			if vel:Dot(ang:Forward()) < 0 then
				vel = -vel
			end
			ang = LerpAngle(self.VelocityToViewAngles, ang, vel:Angle())
		end
		ang.r = roll

		cmd:SetViewAngles(ang)

		if self.UnlockPitch then
			return true
		end
	end)
end

local function badMovetype(ply)
	local mvtype = ply:GetMoveType()

	return mvtype == MOVETYPE_OBSERVER
		or mvtype == MOVETYPE_NOCLIP
		or mvtype == MOVETYPE_LADDER
		or mvtype == MOVETYPE_CUSTOM
		or mvtype == MOVETYPE_ISOMETRIC
end

pac.AddHook("Move", "custom_movement", function(ply, mv)
	local self = ply.pac_movement

	if not self then
		if not ply.pac_custom_movement_reset then
			if not badMovetype(ply) then
				ply:SetGravity(1)
				ply:SetMoveType(MOVETYPE_WALK)

				if ply.pac_custom_movement_jump_height then
					ply:SetJumpPower(ply.pac_custom_movement_jump_height)
					ply.pac_custom_movement_jump_height = nil
				end
			end

			ply.pac_custom_movement_reset = true
		end

		return
	end

	ply.pac_custom_movement_reset = nil
	ply.pac_custom_movement_jump_height = ply.pac_custom_movement_jump_height or ply:GetJumpPower()

	if badMovetype(ply) then return end

	mv:SetForwardSpeed(0)
	mv:SetSideSpeed(0)
	mv:SetUpSpeed(0)

	ply:SetJumpPower(self.JumpHeight)

	if self.Noclip then
		ply:SetMoveType(MOVETYPE_NONE)
	else
		ply:SetMoveType(MOVETYPE_WALK)
	end

	ply:SetGravity(0.00000000000000001)

	local on_ground = ply:IsOnGround()

	if not self.StickToGround then
		ply:SetGroundEntity(NULL)
	end


	local speed = self.RunSpeed

	if mv:KeyDown(IN_SPEED) then
		speed = self.SprintSpeed
	end

	if mv:KeyDown(IN_WALK) then
		speed = self.WalkSpeed
	end

	if mv:KeyDown(IN_DUCK) then
		speed = self.DuckSpeed
	end

	-- 0.175 = 71
	-- 0.272 = 80.5
	-- 0.447 = 106
	-- 0.672 = 179
	-- 0.822 = 330
	-- 0.922 = 751
	-- 0.95 = 1170
	-- 0.99 = 5870

	speed = speed * FrameTime()

	local ang = mv:GetAngles()
	local vel = Vector()

	if on_ground and self.StickToGround then
		ang.p = 0
	end

	if mv:KeyDown(IN_FORWARD) then
		vel = vel + ang:Forward() * speed
	elseif mv:KeyDown(IN_BACK) then
		vel = vel - ang:Forward() * speed
	end

	if mv:KeyDown(IN_MOVERIGHT) then
		vel = vel + ang:Right() * speed
	elseif mv:KeyDown(IN_MOVELEFT) then
		vel = vel - ang:Right() * speed
	end

	if self.AllowZVelocity then
		if mv:KeyDown(IN_JUMP) then
			vel = vel + ang:Up() * speed
		elseif mv:KeyDown(IN_DUCK) then
			vel = vel - ang:Up() * speed
		end
	end

	if not self.AllowZVelocity then
		vel.z = 0
	end
	local speed = vel * 66.66666

	local friction = (on_ground and self.GroundFriction or self.AirFriction)
	friction = -(friction) + 1

	if friction < 1 then
		if not on_ground then
			speed = speed * friction
		else
			speed = speed * (-friction+1)
		end
	end

	local vel = mv:GetVelocity()

	if not self.Noclip and self.StickToGround then -- work against ground friction
		local sv_friction = GetConVarNumber("sv_friction")

		if sv_friction > 0 and on_ground then
			sv_friction = 1 - (sv_friction * 15) / 1000
			vel = vel / sv_friction
		end
	end

	vel = vel * friction


	-- todo: don't allow adding more velocity to existing velocity if it exceeds
	-- but allow decreasing
	if not on_ground then
		speed = speed:GetNormalized() * math.Clamp(speed:Length(), 0, self.MaxAirSpeed)
		vel = vel + speed
	else
		vel = vel + speed
	end

	vel = vel + self.Gravity * 0.015

	if self.FinEfficiency > 0 then -- fin
		local curvel = vel
		local curup = ang:Forward()

		local vec1 = curvel
		local vec2 = curup
		vec1 = vec1 - 2*(vec1:Dot(vec2))*vec2
		local sped = vec1:Length()

		local finalvec = curvel
		local modf = math.abs(curup:Dot(curvel:GetNormalized()))
		local nvec = (curup:Dot(curvel:GetNormalized()))

		if (self.pln == 1) then

			if nvec > 0 then
				vec1 = vec1 + (curup * 10)
			else
				vec1 = vec1 + (curup * -10)
			end

			finalvec = vec1:GetNormalized() * (math.pow(sped, modf) - 1)
			finalvec = finalvec:GetNormalized()
			finalvec = (finalvec * self.FinEfficiency) + curvel
		end

		if (self.FinLiftMode ~= "none") then
			if (self.FinLiftMode == "normal") then
				local liftmul = 1 - math.abs(nvec)
				finalvec = finalvec + (curup * liftmul * curvel:Length() * self.FinEfficiency) / 700
			else
				local liftmul = (nvec / math.abs(nvec)) - nvec
				finalvec = finalvec + (curup * curvel:Length() * self.FinEfficiency * liftmul) / 700
			end
		end

		finalvec = finalvec:GetNormalized()
		finalvec = finalvec * curvel:Length()

		if self.FinCline then
			local trace = {
				start = mv:GetOrigin(),
				endpos = mv:GetOrigin() + Vector(0, 0, -1000000),
				mask = 131083
			}
			local trc = util.TraceLine(trace)

			local MatType = trc.MatType

			if (MatType == 67 or MatType == 77) then
				local heatvec = Vector(0, 0, 100)
				local cline = ((2 * (heatvec:Dot(curup)) * curup - heatvec)) * (math.abs(heatvec:Dot(curup)) / 1000)
				finalvec = finalvec + (cline * (self.FinEfficiency / 50))
			end
		end

		vel = finalvec
	end

	if on_ground and self.MaxGroundSpeed > 0 then
		vel = vel:GetNormalized() * math.min(vel:Length(), self.MaxGroundSpeed)
	end

	mv:SetVelocity(vel)

	if self.Noclip then
		mv:SetOrigin(mv:GetOrigin() + vel * 0.01)
	end

	return false
end)