local CurTime = CurTime
local ParticleEffect = ParticleEffect

local BUILDER, PART = pac.PartTemplate("base_drawable")

PART.ClassName = "effect"
PART.Groups = {"effects", "model", "entity"}
PART.Icon = "icon16/wand.png"

BUILDER:StartStorableVars()
	BUILDER:GetSet("Effect", "default", {enums = function() return pac.pcfprovider.GetParticleList() end})
	BUILDER:GetSet("Loop", true)
	BUILDER:GetSet("Follow", true)
	BUILDER:GetSet("Rate", 1, {editor_sensitivity = 0.1})
	BUILDER:GetSet("UseParticleTracer", false)

	BUILDER:GetSetPart("PointA")
	BUILDER:GetSetPart("PointB")
	BUILDER:GetSetPart("PointC")
	BUILDER:GetSetPart("PointD")

BUILDER:EndStorableVars()

BUILDER:RemoveProperty("Translucent")
PART.Translucent = false -- otherwise OnDraw won't be called

--local BaseClass_GetOwner = PART.GetOwner

function PART:GetNiceName()
	return pac.PrettifyName(self:GetEffect())
end

function PART:Initialize()
	self:SetEffect(self.Effect)
end

PART.last_spew = 0

function PART:SetEffect(name)
	self.Effect = name
	self.Ready = false
end

function PART:OnDraw()
	if not self.Ready then
		self.Ready = pac.pcfprovider.LoadEffect(self.Effect)
		return
	end

	local ent = self:GetOwner()

	if ent:IsValid() and self.Loop then
		local time = CurTime()
		if self.last_spew < time then
			local pos, ang = self:GetDrawPosition()

			ent:StopParticles()
			ent:StopParticleEmission()
			self:Emit(pos, ang)
			self.last_spew = time + math.max(self.Rate, 0.1)
		end
	end
end

function PART:OnHide()
	local ent = self:GetOwner()

	if ent:IsValid() then
		ent:StopParticles()
		ent:StopParticleEmission()
	end
end

function PART:OnShow(from_rendering)
	if from_rendering and self.Ready then
		self:Emit(self:GetDrawPosition())
	end
end

function PART:Emit(pos, ang)
	local ent = self:GetOwner()

	if ent:IsValid() then
		if not self.Effect then
			ent:StopParticles()
			ent:StopParticleEmission()
			return
		end

		if self.UseParticleTracer and self.PointA:IsValid() then
			local ent2 = self.PointA.Entity and self.PointA.Entity or self.PointA:GetOwner()

			util.ParticleTracerEx(
				self.Effect,
				ent:GetPos(),
				ent2:GetPos(),
				true,
				ent:EntIndex(),
				0
			)
			return
		end

		if self.PointA:IsValid() then
			local points = {}

			table.insert(points, {
				entity = self.PointA.Entity and self.PointA.Entity or self.PointA:GetOwner(),
				attachtype = PATTACH_ABSORIGIN_FOLLOW,
			})

			if self.PointB:IsValid() then
				table.insert(points, {
					entity = self.PointB.Entity and self.PointB.Entity or self.PointB:GetOwner(),
					attachtype = PATTACH_ABSORIGIN_FOLLOW,
				})
			end

			if self.PointC:IsValid() then
				table.insert(points, {
					entity = self.PointC.Entity and self.PointC.Entity or self.PointC:GetOwner(),
					attachtype = PATTACH_ABSORIGIN_FOLLOW,
				})
			end

			if self.PointD:IsValid() then
				table.insert(points, {
					entity = self.PointD.Entity and self.PointD.Entity or self.PointD:GetOwner(),
					attachtype = PATTACH_ABSORIGIN_FOLLOW,
				})
			end

			ent:CreateParticleEffect(self.Effect, points)
		elseif self.Follow then
			ent:StopParticles()
			ent:StopParticleEmission()
			CreateParticleSystem(ent, self.Effect, PATTACH_ABSORIGIN_FOLLOW, 0)
		else
			ent:StopParticles()
			ent:StopParticleEmission()
			ParticleEffect(self.Effect, pos, ang, ent)
		end
	end
end

BUILDER:Register()
