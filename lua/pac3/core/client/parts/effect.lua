local CurTime = CurTime

local BUILDER, PART = pac.PartTemplate("base_drawable")

PART.ClassName = "effect"
PART.Groups = {'effects', 'model', 'entity'}
PART.Icon = 'icon16/wand.png'

BUILDER:StartStorableVars()
	BUILDER:GetSet("Effect", "default", {enums = function() return pac.particle_list end})
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

function PART:GetNiceName()
	return pac.PrettifyName(self:GetEffect())
end

PART.last_spew = 0

function PART:Stop()
	if IsValid(self.fx) then
		self.fx:StopEmissionAndDestroyImmediately()
	end

	self.fx = nil
end

function PART:Initialize()
	self:SetEffect(self.Effect)
end

function PART:SetEffect(name)
	self.Effect = name
	self.Ready = false

	self:Stop()

	if not name or name == "" then return end

	if pac.pcfprovider and pac.pcfprovider.LoadEffect(name) then
		self.Ready = true
	end
end

function PART:GetPointEntity(point)
	if point and point:IsValid() then
		return point.Entity and point.Entity or point:GetOwner()
	end

	return NULL
end

function PART:UpdateControlPoints()
	local fx = self.fx
	if not IsValid(fx) then return end

	if self.Follow or self.UseParticleTracer then
		local pos, ang = self:GetDrawPosition()
		fx:SetControlPoint(0, pos)
		fx:SetControlPointOrientation(0, ang:Forward(), ang:Right(), ang:Up())
	end

	if self.PointA:IsValid() then
		local ent = self:GetPointEntity(self.PointA)
		if ent:IsValid() then
			fx:SetControlPoint(1, ent:GetPos())
		end
	end

	if self.PointB:IsValid() then
		local ent = self:GetPointEntity(self.PointB)
		if ent:IsValid() then
			fx:SetControlPoint(2, ent:GetPos())
		end
	end

	if self.PointC:IsValid() then
		local ent = self:GetPointEntity(self.PointC)
		if ent:IsValid() then
			fx:SetControlPoint(3, ent:GetPos())
		end
	end

	if self.PointD:IsValid() then
		local ent = self:GetPointEntity(self.PointD)
		if ent:IsValid() then
			fx:SetControlPoint(4, ent:GetPos())
		end
	end
end

function PART:OnDraw()
	local ent = self:GetOwner()
	if not ent:IsValid() then return end

	if not self.Ready then return end

	self:UpdateControlPoints()

	if self.Loop then
		local time = CurTime()
		if self.last_spew < time then
			self:Emit()
			self.last_spew = time + math.max(self.Rate, 0.1)
		end
	end
end

function PART:OnHide()
	self:Stop()
end

function PART:OnShow(from_rendering)
	if from_rendering then
		self:Emit()
	end
end

function PART:OnRemove()
	self:Stop()
end

function PART:Emit(pos, ang)
	local ent = self:GetOwner()
	if not ent:IsValid() then return end

	if not self.Ready or not self.Effect then
		self:Stop()
		return
	end

	self:Stop()

	if not pos then
		pos, ang = self:GetDrawPosition()
	end

	self.fx = CreateParticleSystemNoEntity(self.Effect, pos, ang)

	if IsValid(self.fx) then
		self:UpdateControlPoints()
	end
end

BUILDER:Register()