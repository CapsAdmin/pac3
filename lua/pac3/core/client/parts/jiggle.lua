local FrameTime = FrameTime
local util_QuickTrace = util.QuickTrace
local VectorRand = VectorRand
local Vector = Vector
local Angle = Angle
local physenv_GetGravity = physenv.GetGravity

local BUILDER, PART = pac.PartTemplate("base_drawable")

PART.ClassName = "jiggle"
PART.Group = 'model'
PART.Icon = 'icon16/chart_line.png'

BUILDER:StartStorableVars()

	BUILDER:SetPropertyGroup("orientation")
	BUILDER:SetPropertyGroup("dynamics")
	BUILDER:GetSet("Strain", 0.5, {editor_onchange = function(self, num)
		self.sens = 0.25
		num = tonumber(num)
		return math.Clamp(num, 0, 1) * 0.999
	end})
	BUILDER:GetSet("Speed", 1)
	BUILDER:GetSet("ConstantVelocity", Vector(0, 0, 0))
	BUILDER:GetSet("InitialVelocity", Vector(0, 0, 0))
	BUILDER:GetSet("LocalVelocity", true, {description = "Whether Constant Velocity and Initial Velocity should use the jiggle part's angles instead of being applied by world coordinates"})
	BUILDER:GetSet("ResetOnHide", false, {description = "Reinitializes the container's position to the base part position, and its speeds to 0, when the part is shown."})
	BUILDER:GetSet("Ground", false)

	BUILDER:SetPropertyGroup("angles")
	BUILDER:GetSet("JiggleAngle", true)
	BUILDER:GetSet("ClampAngles", false, {description = "Restrict the angles so it can't go beyond a certain amount too far from the jiggle's base angle. Components are below"})
	BUILDER:GetSet("AngleClampAmount", Vector(180,180,180))
	BUILDER:GetSet("ConstrainPitch", false, {description = "Do not jiggle the angles on the pitch component\nThe pitch that will remain is the jiggle's current or initial global pitch.\nThat only resets when the part is created, or if reset on hide, when shown; Or, it starts moving again when you turn this off."})
	BUILDER:GetSet("ConstrainYaw", false, {description = "Do not jiggle the angles on the yaw component\nThe yaw that will remain is the jiggle's current or initial global yaw.\nThat only resets when the part is created, or if reset on hide, when shown; Or, it starts moving again when you turn this off."})
	BUILDER:GetSet("ConstrainRoll", false, {description = "Do not jiggle the angles on the roll component\nThe roll that will remain is the jiggle's current or initial global roll.\nThat only resets when the part is created, or if reset on hide, when shown; Or, it starts moving again when you turn this off."})

	BUILDER:SetPropertyGroup("position")
	BUILDER:GetSet("JigglePosition", true)
	BUILDER:GetSet("ConstrainSphere", 0)
	BUILDER:GetSet("StopRadius", 0)
	BUILDER:GetSet("ConstrainX", false, {description = "Do not jiggle on X position coordinates"})
	BUILDER:GetSet("ConstrainY", false, {description = "Do not jiggle on Y position coordinates"})
	BUILDER:GetSet("ConstrainZ", false, {description = "Do not jiggle on Z position coordinates"})

BUILDER:EndStorableVars()

local math_AngleDifference = math.AngleDifference

function PART:Reset()
	local pos, ang = self:GetDrawPosition()

	self.pos = pos or Vector()
	self.vel = Vector()

	self.ang = ang or Angle()
	self.angvel = Angle()
end

function PART:Initialize()
	self.pos = Vector()
	self.vel = Vector()

	self.ang = Angle()
	self.angvel = Angle()

	self.first_time_reset = true
end

function PART:OnShow()
	if self.ResetOnHide then
		self:Reset()
	end

	if not self.InitialVelocity then return end
	local ang = self:GetWorldAngles()
	if self.LocalVelocity then
		self.vel = self.InitialVelocity.x * ang:Forward() + self.InitialVelocity.y * ang:Right() + self.InitialVelocity.z * ang:Up()
	else
		self.vel = self.InitialVelocity
	end
	
end

local inf, ninf = math.huge, -math.huge

local function check_num(num)
	if num ~= inf and num ~= ninf and (num >= 0 or num <= 0) then
		return num
	end

	return 0
end

function PART:OnDraw()
	local pos, ang = self:GetDrawPosition()

	if self.first_time_reset then
		self:Reset()
		self.first_time_reset = false
	end

	local delta = FrameTime()
	local speed = self.Speed * delta

	self.vel = self.vel or VectorRand()
	self.pos = self.pos or pos * 1

	if self.StopRadius ~= 0 and self.pos and self.pos:DistToSqr(pos) < (self.StopRadius * self.StopRadius) then
		self.vel = Vector()
		return
	end

	if self.JigglePosition then
		if not self.ConstrainX then
			self.vel.x = self.vel.x + (pos.x - self.pos.x)

			if self.LocalVelocity then
				self.vel = self.vel + ang:Right() * self.ConstantVelocity.x
			else
				self.vel.x = self.vel.x + self.ConstantVelocity.x
			end

			self.pos.x = self.pos.x + (self.vel.x * (self.Invert and -speed or speed))
			self.vel.x = self.vel.x * self.Strain
		else
			self.pos.x = pos.x
		end

		if not self.ConstrainY then
			self.vel.y = self.vel.y + (pos.y - self.pos.y)

			if self.LocalVelocity then
				self.vel = self.vel + ang:Forward() * self.ConstantVelocity.y
			else
				self.vel.y = self.vel.y + self.ConstantVelocity.y
			end

			self.pos.y = self.pos.y + (self.vel.y * speed)
			self.vel.y = self.vel.y * self.Strain
		else
			self.pos.y = pos.y
		end

		if not self.ConstrainZ then
			self.vel.z = self.vel.z + (pos.z - self.pos.z)

			if self.LocalVelocity then
				self.vel = self.vel + ang:Up() * self.ConstantVelocity.z
			else
				self.vel.z = self.vel.z + self.ConstantVelocity.z
			end

			self.pos.z = self.pos.z + (self.vel.z * speed)
			self.vel.z = self.vel.z * self.Strain
		else
			self.pos.z = pos.z
		end

		if self.Ground then
			self.pos.z = util_QuickTrace(pos, physenv_GetGravity() * 100).HitPos.z
		end
	else
		self.pos = pos
	end

	if self.ConstrainSphere > 0 then
		local len = math.min(self.pos:Distance(pos), self.ConstrainSphere)

		self.pos = pos + (self.pos - pos):GetNormalized() * len
	end

	if self.JiggleAngle then
		self.angvel = self.angvel or ang * 1
		self.ang = self.ang or ang * 1

		if not self.ConstrainPitch then
			self.angvel.p = self.angvel.p + math_AngleDifference(ang.p, self.ang.p)
			self.ang.p = math_AngleDifference(self.ang.p, self.angvel.p * -speed)
			if self.ClampAngles then
				local p_angdiff = math_AngleDifference(self.ang.p, ang.p)
				if p_angdiff > self.AngleClampAmount.x or p_angdiff < -self.AngleClampAmount.x then
					self.ang.p = ang.p + math.Clamp(p_angdiff,-self.AngleClampAmount.x,self.AngleClampAmount.x)
				end
			end
			self.angvel.p = self.angvel.p * self.Strain
		end

		if not self.ConstrainYaw then
			self.angvel.y = self.angvel.y + math_AngleDifference(ang.y, self.ang.y)
			self.ang.y =  math_AngleDifference(self.ang.y, self.angvel.y * -speed)
			if self.ClampAngles then
				local y_angdiff = math_AngleDifference(self.ang.y, ang.y)
				if y_angdiff > self.AngleClampAmount.y or y_angdiff < -self.AngleClampAmount.y then
					self.ang.y = ang.y + math.Clamp(y_angdiff,-self.AngleClampAmount.y,self.AngleClampAmount.y)
				end
			end
			self.angvel.y = self.angvel.y * self.Strain
		end

		if not self.ConstrainRoll then
			self.angvel.r = self.angvel.r + math_AngleDifference(ang.r, self.ang.r)
			self.ang.r =  math_AngleDifference(self.ang.r, self.angvel.r * -speed)
			if self.ClampAngles then
				local r_angdiff = math_AngleDifference(self.ang.r, ang.r)
				if r_angdiff > self.AngleClampAmount.x or r_angdiff < -self.AngleClampAmount.z then
					self.ang.r = ang.r + math.Clamp(r_angdiff,-self.AngleClampAmount.z,self.AngleClampAmount.z)
				end
			end
			self.angvel.r = self.angvel.r * self.Strain
		end
	else
		self.ang = ang
	end
end

function PART:OnThink()
	self.pos.x = check_num(self.pos.x)
	self.pos.y = check_num(self.pos.y)
	self.pos.z = check_num(self.pos.z)

	self.ang.p = check_num(self.ang.p)
	self.ang.y = check_num(self.ang.y)
	self.ang.r = check_num(self.ang.r)
end

BUILDER:Register()