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

function PART:GetNiceName()
	return pac.PrettifyName(self:GetEffect())
end

function PART:Initialize()
	self:SetEffect(self.Effect)
end

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

LOADED_PARTICLES = LOADED_PARTICLES or {}

for key, file_name in pairs(file.Find("particles/*.pcf", "GAME")) do
	if not LOADED_PARTICLES[file_name] then
		game.AddParticles("particles/" .. file_name)
	end
	LOADED_PARTICLES[file_name] = true
end

function PART:SetEffect(name)
	self.Effect = name
	self.Ready = false
	
	net.Start("pac_request_precache")
		net.WriteString(name)
	net.SendToServer()
end

net.Receive("pac_effect_precached", function()
	local name = net.ReadString()
	pac.dprint("effect %q precached!", name)
	for key, part in pairs(pac.GetParts()) do
		if part.ClassName == "effect" then
			if part.Effect == name then
				part.Ready = true
			end
		end
	end
end)

local CurTime = CurTime

function PART:OnDraw(owner, pos, ang)
	if not self.Ready then return end
	
	local ent = self:GetOwner()

	if ent:IsValid() then
		if self.Loop then
			local time = CurTime()
			if self.last_spew < time then
				ent:StopParticles()
				ent:StopParticleEmission()
				self:Emit(pos, ang)
				self.last_spew = time + math.max(self.Rate, 0.1)
			end
		end
	end
end

function PART:OnThink()
	if self:IsHidden() then
		local ent = self:GetOwner()
		if ent:IsValid() then
			ent:StopParticles()
			ent:StopParticleEmission()
		end	
	end
end

function PART:OnRemove()
	local ent = self:GetOwner()

	if ent:IsValid() and ent.IsPACEntity then
		ent:StopParticles()
		ent:StopParticleEmission()
	end
end

PART.OnHide = PART.OnRemove

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

local ParticleEffect = ParticleEffect
local ParticleEffectAttach = ParticleEffectAttach

function PART:Emit(pos, ang)
	local ent = self:GetOwner()
	
	if ent:IsValid() then
		if not self.Effect then
			ent:StopParticles()
			ent:StopParticleEmission()
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
			ent:StopParticles()
			ent:StopParticleEmission()
			ParticleEffectAttach(self.Effect, PATTACH_ABSORIGIN_FOLLOW, ent, 0)
		else
			ent:StopParticles()
			ent:StopParticleEmission()
			ParticleEffect(self.Effect, pos, ang, ent)
		end
	end
end

pac.RegisterPart(PART)