local PART = {}

PART.ClassName = "effect"

pac.StartStorableVars()
	pac.GetSet(PART, "Effect", "default")
	pac.GetSet(PART, "Loop", true)
	pac.GetSet(PART, "Follow", true)
	pac.GetSet(PART, "Rate", 1)
	
	--pac.GetSet(PART, "ControlPointA", "")
	--pac.GetSet(PART, "ControlPointB", "")
pac.EndStorableVars()

function PART:SetControlPointA(var)
	self.ControlPointA = var
	self:ResolveControlPoints()
end

function PART:SetControlPointB(var)
	self.ControlPointB = var
	self:ResolveControlPoints()
end

function PART:GetOwner()
	local parent = self:GetParent()
	
	if parent:IsValid() then		
		if parent.ClassName == "model" and parent.Entity:IsValid() then
			return parent.Entity
		end
	end
	
	return self.BaseClass.GetOwner(self)
end

PART.last_spew = 0

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

pac.AddHook("pac_EffectPrecached", function(name)
	pac.dprint("effect %q precached!", name)
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
	
	local ent = self:GetOwner()

	if ent:IsValid() then

		if self.Loop then
			local time = CurTime()
			if self.last_spew < time then
				ent:StopParticles()
				self:Emit(pos, ang)
				self.last_spew = time + math.max(self.Rate, 0.1)
			end
		end
	end
end

function PART:OnRemove()
	local ent = self:GetOwner()

	if ent:IsValid() and ent.IsPACEntity then
		ent:StopParticles()
		ent:Remove()
	end
end

function PART:ResolveControlPoints()
	for key, part in pairs(pac.GetParts()) do	
		if part:GetName() == self.ControlPointA then
			self.ControlPointAPart = part
			break
		end
	end
	
	for key, part in pairs(pac.GetParts()) do	
		if part:GetName() == self.ControlPointB then
			self.ControlPointBPart = part
			break
		end
	end
end

function PART:Emit(pos, ang)
	local ent = self:GetOwner()
	
	if ent:IsValid() then
		if not self.Effect then
			ent:StopParticles()
			return
		end
		
		if self.ControlPointAPart and self.ControlPointBPart then
			ent:CreateParticleEffect(
				self.Effect, 
				{
					entity = self.ControlPointAPart.Entity or self.ControlPointAPart:GetOwner(),
					attachtype = PATTACH_ABSORIGIN_FOLLOW,
				},
				{
					entity = self.ControlPointBPart.Entity or self.ControlPointBPart:GetOwner(),
					attachtype = PATTACH_ABSORIGIN_FOLLOW,
				}
			)
		elseif self.Follow then
			ParticleEffectAttach(self.Effect, PATTACH_ABSORIGIN_FOLLOW, ent, 1)
		else
			ent:StopParticles()
			ParticleEffect(self.Effect, pos, ang, ent)
		end
	end
end

pac.RegisterPart(PART)