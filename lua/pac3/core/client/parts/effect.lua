local PART = {}

PART.ClassName = "effect"

pac.StartStorableVars()
	pac.GetSet(PART, "Effect", "default")
	pac.GetSet(PART, "Loop", true)
	pac.GetSet(PART, "Follow", true)
	pac.GetSet(PART, "Rate", 1)
pac.EndStorableVars()

PART.last_spew = 0
PART.Entity = NULL

function PART:Initialize()
	self.BaseClass.Initialize(self)

	self:SetEffect(self.Effect)
end

function PART:GetEntity()
	return 
		self.RealParent and 
		IsValid(self.RealParent.Entity) and 
		self.RealParent.Entity 
		or 		
		self:GetOwner()
		or
		NULL
end

function PART:SetEffect(name)
	self.Effect = name
	self.Ready = false
	if net then
		net.Start("pac_precache_effect")
			net.WriteString(name)
		net.SendToServer()
	else
		RunConsoleCommand("pac_precache_effect", name)
	end
end

pac.AddHook("EffectPrecached", function(name)
	for key, part in pairs(pac.GetParts()) do
		if part.ClassName == "effect" then
			if part.Effect == name then
				part.Ready = true
			end
		end
	end
end)

function PART:OnDraw(owner, pos, ang)
	if not self.Ready then return end
	
	local ent = self:GetEntity()

	if ent:IsValid() then

		ent:SetPos(pos)
		ent:SetAngles(ang)

		if self.Loop then
			local time = CurTime()
			if self.last_spew < time then
				ent:StopParticles()
				self:Emit()
				self.last_spew = time + self.Rate
			end
		end
	end
end

function PART:OnRemove()
	local ent = self:GetEntity()

	if ent:IsValid() and ent.IsPACEntity then
		ent:StopParticles()
		ent:Remove()
	end
end

function PART:Emit()
	local ent = self:GetEntity()
	
	if ent:IsValid() then
		if not self.Effect then
			ent:StopParticles()
		end

		if self.Follow then
			ParticleEffectAttach(self.Effect, PATTACH_ABSORIGIN_FOLLOW, ent, 1)
		else
			ent:StopParticles()
			ParticleEffect(self.Effect, ent:GetPos(), ent:GetAngles(), ent)
		end

		self:SetTooltip(self.Effect)
	end
end

pac.RegisterPart(PART)