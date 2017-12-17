local cam_IgnoreZ = cam.IgnoreZ
local vector_origin = vector_origin
local FrameTime = FrameTime
local angle_origin = Angle(0,0,0)
local WorldToLocal = WorldToLocal

local PART = {}

PART.ClassName = "particles"
PART.Group = 'effects'
PART.Icon = 'icon16/water.png'

pac.StartStorableVars()
	pac.SetPropertyGroup(PART, "generic")
		pac.PropertyOrder(PART, "Name")
		pac.PropertyOrder(PART, "Hide")
		pac.PropertyOrder(PART, "ParentName")
		pac.GetSet(PART, "Follow", false)
		pac.GetSet(PART, "Additive", false)
		pac.GetSet(PART, "FireDelay", 0.2)
		pac.GetSet(PART, "NumberParticles", 1)
		pac.GetSet(PART, "PositionSpread", 0)
		pac.GetSet(PART, "PositionSpread2", Vector(0,0,0))
		pac.GetSet(PART, "DieTime", 3)
		pac.GetSet(PART, "StartSize", 2)
		pac.GetSet(PART, "EndSize", 20)
		pac.GetSet(PART, "StartLength", 0)
		pac.GetSet(PART, "EndLength", 0)
		pac.GetSet(PART, "ParticleAngle", Angle(0,0,0))
		pac.GetSet(PART, "AddFrametimeLife", false)
	pac.SetPropertyGroup(PART, "stick")
		pac.GetSet(PART, "AlignToSurface", true)
		pac.GetSet(PART, "StickToSurface", true)
		pac.GetSet(PART, "StickLifetime", 2)
		pac.GetSet(PART, "StickStartSize", 20)
		pac.GetSet(PART, "StickEndSize", 0)
		pac.GetSet(PART, "StickStartAlpha", 255)
		pac.GetSet(PART, "StickEndAlpha", 0)
	pac.SetPropertyGroup(PART, "appearance")
		pac.GetSet(PART, "Material", "effects/slime1")
		pac.GetSet(PART, "StartAlpha", 255)
		pac.GetSet(PART, "EndAlpha", 0)
		pac.GetSet(PART, "Translucent", true)
		pac.GetSet(PART, "Color2", Vector(255, 255, 255), {editor_panel = "color"})
		pac.GetSet(PART, "Color1", Vector(255, 255, 255), {editor_panel = "color"})
		pac.GetSet(PART, "RandomColor", false)
		pac.GetSet(PART, "Lighting", true)
		pac.GetSet(PART, "3D", false)
		pac.GetSet(PART, "DoubleSided", true)
		pac.GetSet(PART, "DrawManual", false)
	pac.SetPropertyGroup(PART, "rotation")
		pac.GetSet(PART, "RandomRollSpeed", 0)
		pac.GetSet(PART, "RollDelta", 0)
		pac.GetSet(PART, "ParticleAngleVelocity", Vector(50, 50, 50))
	pac.SetPropertyGroup(PART, "orientation")
	pac.SetPropertyGroup(PART, "movement")
		pac.GetSet(PART, "Velocity", 250)
		pac.GetSet(PART, "Spread", 0.1)
		pac.GetSet(PART, "AirResistance", 5)
		pac.GetSet(PART, "Bounce", 5)
		pac.GetSet(PART, "Gravity", Vector(0,0, -50))
		pac.GetSet(PART, "Collide", true)
		pac.GetSet(PART, "Sliding", true)
		--pac.GetSet(PART, "AddVelocityFromOwner", false)
		pac.GetSet(PART, "OwnerVelocityMultiplier", 0)




pac.EndStorableVars()

function PART:GetNiceName()
	return pac.PrettifyName(("/".. self:GetMaterial()):match(".+/(.+)")) or "error"
end

local function RemoveCallback(particle)
	particle:SetLifeTime(0)
	particle:SetDieTime(0)

	particle:SetStartSize(0)
	particle:SetEndSize(0)

	particle:SetStartAlpha(0)
	particle:SetEndAlpha(0)
end

local function SlideCallback(particle, hitpos, normal)
	particle:SetBounce(1)
	local vel = particle:GetVelocity()
	vel.z = 0
	particle:SetVelocity(vel)
	particle:SetPos(hitpos + normal)
end

local function StickCallback(particle, hitpos, normal)
	particle:SetAngleVelocity(Angle(0, 0, 0))

	if particle.Align then
		local ang = normal:Angle()
		ang:RotateAroundAxis(normal, particle:GetAngles().y)
		particle:SetAngles(ang)
	end

	if particle.Stick then
		particle:SetVelocity(Vector(0, 0, 0))
		particle:SetGravity(Vector(0, 0, 0))
	end

	particle:SetLifeTime(0)
	particle:SetDieTime(particle.StickLifeTime or 0)

	particle:SetStartSize(particle.StickStartSize or 0)
	particle:SetEndSize(particle.StickEndSize or 0)

	particle:SetStartAlpha(particle.StickStartAlpha or 0)
	particle:SetEndAlpha(particle.StickEndAlpha or 0)
end

function PART:CreateEmitter()
	self.NextShot = pac.RealTime
	self.Created = pac.RealTime + 0.1

	if self.last_3d ~= self["3D"] then
		self.emitter = ParticleEmitter(self.cached_pos, self["3D"])
		self.last_3d = self["3D"]
	end
end

function PART:SetDrawManual(b)
	self.DrawManual = b
	self.emitter:SetNoDraw(b)
end

PART.Initialize = PART.CreateEmitter

function PART:SetNumberParticles(num)
	self.NumberParticles = math.Clamp(num, 0, 100)
end

function PART:Set3D(b)
	self["3D"] = b
	self:CreateEmitter()
end

function PART:OnDraw(owner, pos, ang)
	if not self:IsHidden() then
		self.emitter:SetPos(pos)
		if self.DrawManual or self.IgnoreZ or self.Follow or self.BlendMode ~= "" then

			if not self.nodraw then
				self.emitter:SetNoDraw(true)
				self.nodraw = true
			end

			if self.Follow then
				cam.Start3D(WorldToLocal(EyePos(), EyeAngles(), pos, ang))
				if self.IgnoreZ then cam.IgnoreZ(true) end
				self.emitter:Draw()
				if self.IgnoreZ then cam.IgnoreZ(false) end
				cam.End3D()
			else
				self.emitter:Draw()
			end
		else
			if self.nodraw then
				self:SetDrawManual(self:GetDrawManual())
				self.nodraw = false
			end
		end
		self:EmitParticles(self.Follow and vector_origin or pos, self.Follow and angle_origin or ang, ang)
	end
end

function PART:SetAdditive(b)
	self.Additive = b

	self:SetMaterial(self:GetMaterial())
end

function PART:SetMaterial(var)
	var = var or ""

	if not pac.Handleurltex(self, var, function(mat)
		mat:SetFloat("$alpha", 0.999)
		mat:SetInt("$spriterendermode", self.Additive and 5 or 1)
		self.Materialm = mat
		self:CallEvent("material_changed")
	end, "Sprite") then
		if var == "" then
			self.Materialm = nil
		else
			self.Materialm = pac.Material(var, self)
			self:CallEvent("material_changed")
		end
	end

	self.Material = var
end

function PART:EmitParticles(pos, ang, real_ang)
	local emt = self.emitter
	if not emt then return end

	if self.NextShot < pac.RealTime then
		if self.Material == "" then return end
		if self.Velocity == 500.01 then return end

		local originalAng = ang
		ang = ang:Forward()

		local double = 1
		if self.DoubleSided then
			double = 2
		end

		for _ = 1, self.NumberParticles do

			local vec = Vector()

			if self.Spread ~= 0 then
				vec = Vector(
					math.sin(math.Rand(0, 360)) * math.Rand(-self.Spread, self.Spread),
					math.cos(math.Rand(0, 360)) * math.Rand(-self.Spread, self.Spread),
					math.sin(math.random()) * math.Rand(-self.Spread, self.Spread)
				)
			end

			local color

			if self.RandomColor then
				color =
				{
					math.random(math.min(self.Color1.r, self.Color2.r), math.max(self.Color1.r, self.Color2.r)),
					math.random(math.min(self.Color1.g, self.Color2.g), math.max(self.Color1.g, self.Color2.g)),
					math.random(math.min(self.Color1.b, self.Color2.b), math.max(self.Color1.b, self.Color2.b))
				}
			else
				color = {self.Color1.r, self.Color1.g, self.Color1.b}
			end

			local roll = math.Rand(-self.RollDelta, self.RollDelta)

			if self.PositionSpread ~= 0 then
				pos = pos + Angle(math.Rand(-180, 180), math.Rand(-180, 180), math.Rand(-180, 180)):Forward() * self.PositionSpread
			end

			do
				local vecAdd = Vector(
					math.Rand(-self.PositionSpread2.x, self.PositionSpread2.x),
					math.Rand(-self.PositionSpread2.x, self.PositionSpread2.y),
					math.Rand(-self.PositionSpread2.z, self.PositionSpread2.z)
				)
				vecAdd:Rotate(originalAng)
				pos = pos + vecAdd
			end

			for i = 1, double do
				local particle = emt:Add(self.Materialm or self.Material, pos)

				if double == 2 then
					local ang_
					if i == 1 then
						ang_ = (ang * -1):Angle()
					elseif i == 2 then
						ang_ = ang:Angle()
					end

					particle:SetAngles(ang_)
				else
					particle:SetAngles(ang:Angle())
				end

				if self.OwnerVelocityMultiplier ~= 0 then
					local owner = self:GetOwner(true)
					if owner:IsValid() then
						vec = vec + (owner:GetVelocity() * self.OwnerVelocityMultiplier)
					end
				end

				particle:SetVelocity((vec + ang) * self.Velocity)
				particle:SetColor(unpack(color))
				particle:SetColor(unpack(color))

				local life = math.Clamp(self.DieTime, 0.0001, 50)
				if self.AddFrametimeLife then
					life = life + FrameTime()
				end
				particle:SetDieTime(life)

				particle:SetStartAlpha(self.StartAlpha)
				particle:SetEndAlpha(self.EndAlpha)
				particle:SetStartSize(self.StartSize)
				particle:SetEndSize(self.EndSize)
				particle:SetStartLength(self.StartLength)
				particle:SetEndLength(self.EndLength)
				particle:SetRoll(self.RandomRollSpeed * 36)
				particle:SetRollDelta(self.RollDelta + roll)
				particle:SetAirResistance(self.AirResistance)
				particle:SetBounce(self.Bounce)
				particle:SetGravity(self.Gravity)
				particle:SetAngles(particle:GetAngles() + self.ParticleAngle)
				particle:SetLighting(self.Lighting)

				if not self.Follow then
					particle:SetCollide(self.Collide)
				end

				if self.Sliding then
					particle:SetCollideCallback(SlideCallback)
				end

				if self["3D"] then
					if not self.Sliding then
						if i == 1 then
							particle:SetCollideCallback(RemoveCallback)
						else
							particle:SetCollideCallback(StickCallback)
						end
					end

					particle:SetAngleVelocity(Angle(self.ParticleAngleVelocity.x, self.ParticleAngleVelocity.y, self.ParticleAngleVelocity.z))

					particle.Align = self.Align
					particle.Stick = self.Stick
					particle.StickLifeTime = self.StickLifeTime
					particle.StickStartSize = self.StickStartSize
					particle.StickEndSize = self.StickEndSize
					particle.StickStartAlpha = self.StickStartAlpha
					particle.StickEndAlpha = self.StickEndAlpha
				end
			end
		end

		self.NextShot = pac.RealTime + self.FireDelay
	end
end

pac.RegisterPart(PART)
