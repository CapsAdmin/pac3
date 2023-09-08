local cam_IgnoreZ = cam.IgnoreZ
local vector_origin = vector_origin
local FrameTime = FrameTime
local angle_origin = Angle(0,0,0)
local WorldToLocal = WorldToLocal

local BUILDER, PART = pac.PartTemplate("base_drawable")

PART.ClassName = "particles"
PART.Group = 'effects'
PART.Icon = 'icon16/water.png'

BUILDER:StartStorableVars()
	BUILDER:SetPropertyGroup("generic")
		BUILDER:PropertyOrder("Name")
		BUILDER:PropertyOrder("Hide")
		BUILDER:PropertyOrder("ParentName")
		BUILDER:GetSet("Follow", false)
		BUILDER:GetSet("Additive", false)
		BUILDER:GetSet("FireOnce", false)
		BUILDER:GetSet("FireDelay", 0.2)
		BUILDER:GetSet("NumberParticles", 1)
		BUILDER:GetSet("PositionSpread", 0)
		BUILDER:GetSet("PositionSpread2", Vector(0,0,0))
		BUILDER:GetSet("DieTime", 3)
		BUILDER:GetSet("StartSize", 2)
		BUILDER:GetSet("EndSize", 20)
		BUILDER:GetSet("StartLength", 0)
		BUILDER:GetSet("EndLength", 0)
		BUILDER:GetSet("ParticleAngle", Angle(0,0,0))
		BUILDER:GetSet("AddFrametimeLife", false)
	BUILDER:SetPropertyGroup("stick")
		BUILDER:GetSet("AlignToSurface", true)
		BUILDER:GetSet("StickToSurface", true)
		BUILDER:GetSet("StickLifetime", 2)
		BUILDER:GetSet("StickStartSize", 20)
		BUILDER:GetSet("StickEndSize", 0)
		BUILDER:GetSet("StickStartAlpha", 255)
		BUILDER:GetSet("StickEndAlpha", 0)
	BUILDER:SetPropertyGroup("appearance")
		BUILDER:GetSet("Material", "effects/slime1")
		BUILDER:GetSet("StartAlpha", 255)
		BUILDER:GetSet("EndAlpha", 0)
		BUILDER:GetSet("Translucent", true)
		BUILDER:GetSet("Color2", Vector(255, 255, 255), {editor_panel = "color"})
		BUILDER:GetSet("Color1", Vector(255, 255, 255), {editor_panel = "color"})
		BUILDER:GetSet("RandomColor", false)
		BUILDER:GetSet("Lighting", true)
		BUILDER:GetSet("3D", false)
		BUILDER:GetSet("DoubleSided", true)
		BUILDER:GetSet("DrawManual", false)
	BUILDER:SetPropertyGroup("rotation")
		BUILDER:GetSet("ZeroAngle",true)
		BUILDER:GetSet("RandomRollSpeed", 0)
		BUILDER:GetSet("RollDelta", 0)
		BUILDER:GetSet("ParticleAngleVelocity", Vector(50, 50, 50))
	BUILDER:SetPropertyGroup("orientation")
	BUILDER:SetPropertyGroup("movement")
		BUILDER:GetSet("Velocity", 250)
		BUILDER:GetSet("Spread", 0.1)
		BUILDER:GetSet("AirResistance", 5)
		BUILDER:GetSet("Bounce", 5)
		BUILDER:GetSet("Gravity", Vector(0,0, -50))
		BUILDER:GetSet("Collide", true)
		BUILDER:GetSet("Sliding", true)
		--BUILDER:GetSet("AddVelocityFromOwner", false)
		BUILDER:GetSet("OwnerVelocityMultiplier", 0)




BUILDER:EndStorableVars()

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

function PART:GetEmitter()
	if not self.emitter then
		self.NextShot = 0
		self.Created = pac.RealTime + 0.1
		self.emitter = ParticleEmitter(vector_origin, self:Get3D())
	end

	return self.emitter
end

function PART:SetDrawManual(b)
	self.DrawManual = b
	self:GetEmitter():SetNoDraw(b)
end

function PART:SetNumberParticles(num)
	self.NumberParticles = math.Clamp(num, 0, 100)
end

function PART:Set3D(b)
	self["3D"] = b
	self.emitter = nil
end

function PART:OnShow(from_rendering)
	self.CanKeepFiring = true
	self.FirstShot = true
	if not from_rendering then
		self.NextShot = 0
		local pos, ang = self:GetDrawPosition()
		self:EmitParticles(self.Follow and vector_origin or pos, self.Follow and angle_origin or ang, ang)
	end
end

function PART:OnDraw()
	if not self.FireOnce then self.CanKeepFiring = true end
	local pos, ang = self:GetDrawPosition()
	local emitter = self:GetEmitter()

	emitter:SetPos(pos)
	if self.DrawManual or self.IgnoreZ or self.Follow or self.BlendMode ~= "" then

		if not self.nodraw then
			emitter:SetNoDraw(true)
			self.nodraw = true
		end

		if self.Follow then
			cam.Start3D(WorldToLocal(EyePos(), EyeAngles(), pos, ang))
			if self.IgnoreZ then cam.IgnoreZ(true) end
			emitter:Draw()
			if self.IgnoreZ then cam.IgnoreZ(false) end
			cam.End3D()
		else
			emitter:Draw()
		end
	else
		if self.nodraw then
			self:SetDrawManual(self:GetDrawManual())
			self.nodraw = false
		end
	end
	self:EmitParticles(self.Follow and vector_origin or pos, self.Follow and angle_origin or ang, ang)
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
		self:CallRecursive("OnMaterialChanged")
	end, "Sprite") then
		if var == "" then
			self.Materialm = nil
		else
			self.Materialm = pac.Material(var, self)
			self:CallRecursive("OnMaterialChanged")
		end
	end

	self.Material = var
end

function PART:EmitParticles(pos, ang, real_ang)
	if self.FireOnce and not self.FirstShot then self.CanKeepFiring = false end
	local emt = self:GetEmitter()
	if not emt then return end

	if self.NextShot < pac.RealTime and self.CanKeepFiring then
		if self.Material == "" then return end
		if self.Velocity == 500.01 then return end

		local originalAng = ang
		ang = ang:Forward()

		local double = 1
		if self.DoubleSided then
			double = 2
		end

		for _ = 1, self.NumberParticles do
			local mats = self.Material:Split(";")
			if #mats > 1 then
				self.Materialm = pac.Material(table.Random(mats), self)
				self:CallRecursive("OnMaterialChanged")
			end
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
					local owner = self:GetRootPart():GetOwner()
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

				if self.RandomRollSpeed ~= 0 then
					particle:SetRoll(self.RandomRollSpeed * 36)
				end

				if self.RollDelta ~= 0 then
					particle:SetRollDelta(self.RollDelta + roll)
				end

				particle:SetAirResistance(self.AirResistance)
				particle:SetBounce(self.Bounce)
				particle:SetGravity(self.Gravity)
				if self.ZeroAngle then particle:SetAngles(Angle(0,0,0))
				else particle:SetAngles(particle:GetAngles() + self.ParticleAngle) end
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
	self.FirstShot = false
end

BUILDER:Register()
