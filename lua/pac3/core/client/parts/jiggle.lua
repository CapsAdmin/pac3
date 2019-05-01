local FrameTime = FrameTime
local util_QuickTrace = util.QuickTrace
local VectorRand = VectorRand
local Vector = Vector
local Angle = Angle
local physenv_GetGravity = physenv.GetGravity

local PART = {}

PART.ClassName = "jiggle"
PART.Group = 'model'
PART.Icon = 'icon16/chart_line.png'

pac.StartStorableVars()
	pac.GetSet(PART, "Strain", 0.5, {editor_onchange = function(self, num)
		self.sens = 0.25
		num = tonumber(num)
		return math.Clamp(num, 0, 1) * 0.999
	end})
	pac.GetSet(PART, "Speed", 1)
	pac.GetSet(PART, "ConstantVelocity", Vector(0, 0, 0))
	pac.GetSet(PART, "LocalVelocity", true)
	pac.GetSet(PART, "JiggleAngle", true)
	pac.GetSet(PART, "JigglePosition", true)

	pac.GetSet(PART, "ConstrainPitch", false)
	pac.GetSet(PART, "ConstrainYaw", false)
	pac.GetSet(PART, "ConstrainRoll", false)

	pac.GetSet(PART, "ConstrainX", false)
	pac.GetSet(PART, "ConstrainY", false)
	pac.GetSet(PART, "ConstrainZ", false)

	pac.GetSet(PART, "ConstrainSphere", 0)
	pac.GetSet(PART, "StopRadius", 0)
	pac.GetSet(PART, "Ground", false)
	pac.GetSet(PART, "ResetOnHide", false)
pac.EndStorableVars()

local math_AngleDifference = math.AngleDifference

function PART:Reset()
	local pos, ang = self:HasParent() and not self.Parent.NonPhysical and self.Parent:GetDrawPosition() or self:GetBonePosition()

	self.pos = pos
	self.vel = Vector()

	self.ang = ang
	self.angvel = Angle()
end

function PART:Initialize()
	self:Reset()
	self.AllowSetupPositionFrameSkip = false
end

function PART:OnShow()
	if self.ResetOnHide then
		self:Reset()
	end
end

function PART:OnDraw(owner, pos, ang)
	local delta = FrameTime()
	local speed = self.Speed * delta

	self.vel = self.vel or VectorRand()
	self.pos = self.pos or pos * 1

	if self.StopRadius ~= 0 and self.pos and self.pos:Distance(pos) < self.StopRadius then
		self.vel = Vector()
	return end

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
			self.angvel.p = self.angvel.p * self.Strain
		end

		if not self.ConstrainYaw then
			self.angvel.y = self.angvel.y + math_AngleDifference(ang.y, self.ang.y)
			self.ang.y = math_AngleDifference(self.ang.y, self.angvel.y * -speed)
			self.angvel.y = self.angvel.y * self.Strain
		end

		if not self.ConstrainRoll then
			self.angvel.r = self.angvel.r + math_AngleDifference(ang.r, self.ang.r)
			self.ang.r = math_AngleDifference(self.ang.r, self.angvel.r * -speed)
			self.angvel.r = self.angvel.r * self.Strain
		end
	else
		self.ang = ang
	end
end

pac.RegisterPart(PART)