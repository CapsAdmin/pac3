local PART = {}

PART.ClassName = "effect"
PART.Base = "model"

pac.StartStorableVars()
	pac.GetSet(PART, "Effect", "default")
	pac.GetSet(PART, "Loop", true)
	pac.GetSet(PART, "Follow", true)
	pac.GetSet(PART, "Rate", 1)
pac.EndStorableVars()

function PART:Initialize()
	self.BaseClass.Initialize(self)

	self:SetEffect(self.Effect)
end

PART.last_spew = 0

function PART:PostPlayerDraw(owner, pos, ang)
	local ent = self.Entity

	if ent:IsValid() then

		ent:SetPos(pos)
		ent:SetAngles(ang)

		if self.Loop then
			local time = CurTime()
			if self.last_spew < time then
				ent:StopParticles()
				self:SetEffect(self.Effect)
				self.last_spew = time + self.Rate
			end
		end
	end
end

function PART:OnRemove()
	local ent = self.Entity

	if ent:IsValid() then
		ent:StopParticles()
		ent:Remove()
	end
end

function PART:SetEffect(name)
	local ent = self.Entity

	if ent:IsValid() then
		if not name then
			ent:StopParticles()
		end

		self.Effect = name

		if self.Follow then
			ParticleEffectAttach(self.Effect, PATTACH_ABSORIGIN_FOLLOW, ent, 1)
		else
			ent:StopParticles()
			ParticleEffect(self.Effect, ent:GetPos(), ent:GetAngles(), ent)
		end

		self:SetTooltip(name)
	end
end

pac.RegisterPart(PART)