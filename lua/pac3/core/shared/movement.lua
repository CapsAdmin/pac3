local movementConvar = CreateConVar("pac_free_movement", -1, CLIENT and {FCVAR_REPLICATED} or {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "allow players to modify movement. -1 apply only allow when noclip is allowed, 1 allow for all gamemodes, 0 to disable")
local allowMass = CreateConVar("pac_player_movement_allow_mass", 1, CLIENT and {FCVAR_REPLICATED} or {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "enables changing player mass in player movement. 1 to enable, 0 to disable", 0, 1)
local massUpperLimit = CreateConVar("pac_player_movement_max_mass", 50000, CLIENT and {FCVAR_REPLICATED} or {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "restricts the maximum mass that players can use with player movement", 85, 50000)
local massLowerLimit = CreateConVar("pac_player_movement_min_mass", 0, CLIENT and {FCVAR_REPLICATED} or {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "restricts the minimum mass that players can use with player movement", 0, 85)
local massDamageScale = CreateConVar("pac_player_movement_physics_damage_scaling", 1, CLIENT and {FCVAR_REPLICATED} or {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "restricts the damage scaling applied to players by modified mass values. 1 to enable, 0 to disable", 0, 1)

local default = {
	JumpHeight = 200,
	StickToGround = true,
	GroundFriction = 0.12,
	AirFriction = 0.01,
	HorizontalAirFrictionMultiplier = 1,
	StrafingStrengthMultiplier = 1,
	Gravity = Vector(0,0,-600),
	Mass = 85,
	Noclip = false,
	MaxGroundSpeed = 750,
	MaxAirSpeed = 750,
	AllowZVelocity = false,
	ReversePitch = false,
	UnlockPitch = false,
	VelocityToViewAngles = 0,
	RollAmount = 0,

	SprintSpeed = 400,
	RunSpeed = 200,
	WalkSpeed = 100,
	DuckSpeed = 50,

	FinEfficiency = 0,
	FinLiftMode = "normal",
	FinCline = false
}

if SERVER then
	util.AddNetworkString("pac_modify_movement")

	net.Receive("pac_modify_movement", function(len, ply)
		local cvar = movementConvar:GetInt()
		if cvar == 0 or (cvar == -1 and hook.Run("PlayerNoClip", ply, true)==false) then return end

		local str = net.ReadString()
		if str == "disable" then
			ply.pac_movement = nil
			ply:GetPhysicsObject():SetMass(default.Mass)
			ply.scale_mass = 1
		else
			if default[str] ~= nil then
				local val = net.ReadType()
				if type(val) == type(default[str]) then
					ply.pac_movement = ply.pac_movement or table.Copy(default)
					ply.pac_movement[str] = val
				end
			end
		end
	end)
end

if CLIENT then
	local sensitivityConvar = GetConVar("sensitivity")
	pac.AddHook("InputMouseApply", "custom_movement", function(cmd, x,y, ang)
		local ply = pac.LocalPlayer
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

			local sens = sensitivityConvar:GetFloat() * 20
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

local frictionConvar = GetConVar("sv_friction")
local lasttime = 0
pac.AddHook("Move", "custom_movement", function(ply, mv)
	lasttime = SysTime()
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

	if SERVER then
		if allowMass:GetInt() == 1 then
			ply:GetPhysicsObject():SetMass(math.Clamp(self.Mass, massLowerLimit:GetFloat(), massUpperLimit:GetFloat()))
		end
	end

	if (movementConvar:GetInt() == 1 or (movementConvar:GetInt() == -1 and hook.Run("PlayerNoClip", ply, true) == true)) and massDamageScale:GetInt() == 1 then
		ply.scale_mass = 85/math.Clamp(self.Mass, math.max(massLowerLimit:GetFloat(), 0.01), massUpperLimit:GetFloat())
	else
		ply.scale_mass = 1
	end

	pac.AddHook("EntityTakeDamage", "PAC3MassDamageScale", function(target, dmginfo)
		if target:IsPlayer() and dmginfo:IsDamageType(DMG_CRUSH or DMG_VEHICLE) then
			dmginfo:ScaleDamage(target.scale_mass or 1)
		end
	end)

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

	if not on_ground and not self.AllowZVelocity then
		speed = speed * self.StrafingStrengthMultiplier
	end

  --speed = speed * FrameTime()

	local ang = mv:GetAngles()
	local vel = Vector()

	if on_ground and self.StickToGround then
		ang.p = 0
	end

	if mv:KeyDown(IN_FORWARD) then
		vel = vel + ang:Forward()
	elseif mv:KeyDown(IN_BACK) then
		vel = vel - ang:Forward()
	end

	if mv:KeyDown(IN_MOVERIGHT) then
		vel = vel + ang:Right()
	elseif mv:KeyDown(IN_MOVELEFT) then
		vel = vel - ang:Right()
	end


	vel = vel:GetNormalized() * speed

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

	local speed = vel --That makes speed the driver (added velocity)
	if not on_ground and not self.AllowZVelocity then
		speed = speed * self.StrafingStrengthMultiplier
	end

	local vel = mv:GetVelocity()

	--@note ground friction
	if on_ground and not self.Noclip and self.StickToGround then -- work against ground friction
		local sv_friction = frictionConvar:GetInt()
		--ice and glass go too fast? what do?
		if sv_friction > 0 then
			sv_friction = 1 - (sv_friction * 15) / 1000 --default is 8, and the formula ends up being equivalent to 0.12 groundfriction variable multiplying vel by 0.88
			vel = vel / sv_friction
		end
	end

	vel = vel + self.Gravity * 0

	-- todo: don't allow adding more velocity to existing velocity if it exceeds
	-- but allow decreasing
	if not on_ground then
		if ply:WaterLevel() >= 2 then
			local ground_speed = self.RunSpeed

			if mv:KeyDown(IN_SPEED) then
				ground_speed = self.SprintSpeed
			end

			if mv:KeyDown(IN_WALK) then
				ground_speed = self.WalkSpeed
			end

			if mv:KeyDown(IN_DUCK) then
				ground_speed = self.DuckSpeed
			end
			if self.MaxGroundSpeed == 0 then self.MaxGroundSpeed = 400 end
			if self.MaxAirSpeed == 0 then self.MaxAirSpeed = 400 end
			local water_speed = math.min(ground_speed, self.MaxAirSpeed, self.MaxGroundSpeed)
			--print("water speed " .. water_speed)

			ang = ply:EyeAngles()
			local vel2 = Vector()

			if mv:KeyDown(IN_FORWARD) then
				vel2 = water_speed*ang:Forward()
			elseif mv:KeyDown(IN_BACK) then
				vel2 = -water_speed*ang:Forward()
			end

			if mv:KeyDown(IN_MOVERIGHT) then
				vel2 = vel2 + ang:Right()
			elseif mv:KeyDown(IN_MOVELEFT) then
				vel2 = vel2 - ang:Right()
			end

			vel = vel + vel2 * math.min(FrameTime(),0.3) * 2

		else
			local friction = self.AirFriction
			local friction_mult = -(friction) + 1

			local hfric = friction * self.HorizontalAirFrictionMultiplier
			local hfric_mult = -(hfric) + 1

			vel.x = vel.x * hfric_mult
			vel.y = vel.y * hfric_mult
			vel.z = vel.z * friction_mult
			vel = vel + self.Gravity * 0.015

			speed = speed:GetNormalized() * math.Clamp(speed:Length(), 0, self.MaxAirSpeed) --base driver speed but not beyond max?
			--why should the base driver speed depend on friction?

			--reminder: vel is the existing speed, speed is the driver (added velocity)
			--vel = vel + (speed * FrameTime()*(66.666*friction))
			vel.x = vel.x  + (speed.x * math.min(FrameTime(),0.3)*(66.666*hfric))
			vel.y = vel.y  + (speed.y * math.min(FrameTime(),0.3)*(66.666*hfric))
			vel.z = vel.z  + (speed.z * math.min(FrameTime(),0.3)*(66.666*friction))
		end
	else
		local friction = self.GroundFriction
		friction = -(friction) + 1

		vel = vel * friction

		speed = speed:GetNormalized() * math.min(speed:Length(), self.MaxGroundSpeed)

		local trace = {
			start = mv:GetOrigin(),
			endpos = mv:GetOrigin() + Vector(0, 0, -20),
			mask = MASK_SOLID_BRUSHONLY
		}
		local trc = util.TraceLine(trace)
		local special_surf_fric = 1
		--print(trc.MatType)
		if trc.MatType == MAT_GLASS then
			special_surf_fric = 0.6
		elseif trc.MatType == MAT_SNOW then
			special_surf_fric = 0.4
		end

		--vel = vel + (special_surf_fric * speed * FrameTime()*(75.77*(-friction+1)))
		vel = vel + (special_surf_fric * speed * math.min(FrameTime(),0.3)*(75.77*(-friction+1)))

		vel = vel + self.Gravity * 0.015
	end

	if self.FinEfficiency > 0 then -- fin
		local curvel = vel
		local curup = ang:Forward()
		local curspeed = curvel:Length()

		local vec1 = curvel
		local vec2 = curup
		vec1 = vec1 - 2 * (vec1:Dot(vec2)) * vec2

		local finalvec = curvel
		local modf = math.abs(curup:Dot(curvel:GetNormalized()))
		local nvec = curup:Dot(curvel:GetNormalized())

		if (self.pln == 1) then
			if nvec > 0 then
				vec1 = vec1 + (curup * 10)
			else
				vec1 = vec1 + (curup * -10)
			end

			finalvec = vec1:GetNormalized() * (math.pow(curspeed, modf) - 1)
			finalvec = finalvec:GetNormalized()
			finalvec = (finalvec * self.FinEfficiency) + curvel
		end

		if self.FinLiftMode ~= "none" then
			if self.FinLiftMode == "normal" then
				local liftmul = 1 - math.abs(nvec)
				finalvec = finalvec + (curup * liftmul * curspeed * self.FinEfficiency) / 700
			else
				local liftmul = (nvec / math.abs(nvec)) - nvec
				finalvec = finalvec + (curup * curspeed * self.FinEfficiency * liftmul) / 700
			end
		end

		finalvec = finalvec:GetNormalized()
		finalvec = finalvec * curspeed

		if self.FinCline then
			local trace = {
				start = mv:GetOrigin(),
				endpos = mv:GetOrigin() + Vector(0, 0, -1000000),
				mask = 131083
			}

			local trc = util.TraceLine(trace)

			local MatType = trc.MatType

			if MatType == 67 or MatType == 77 then
				local heatvec = Vector(0, 0, 100)
				local cline = (2 * (heatvec:Dot(curup)) * curup - heatvec) * (math.abs(heatvec:Dot(curup)) / 1000)
				finalvec = finalvec + (cline * (self.FinEfficiency / 50))
			end
		end

		vel = finalvec
	end

	mv:SetVelocity(vel)

	if self.Noclip then
		mv:SetOrigin(mv:GetOrigin() + vel * 0.01)
	end

	return false
end)
