local PART = {}

PART.ClassName = "sound"

pac.StartStorableVars()
	pac.GetSet(PART, "Sound", "")
	pac.GetSet(PART, "Volume", 100)
	pac.GetSet(PART, "Pitch", 100)
pac.EndStorableVars()

function PART:Initialize()
	self:PlaySound()
end

function PART:OnRemove()
	self:StopSound()
end

function PART:OnShow()
	self:PlaySound()
end

function PART:OnHide()
	self:StopSound()
end

function PART:PlaySound()
	local ent = self:GetOwner()

	if ent:IsValid() then
		ent:EmitSound(self.Sound, self.Volume, self.Pitch)
	end
end

function PART:StopSound()
	local ent = self:GetOwner()

	if ent:IsValid() and ent.IsPACEntity then
		ent:StopSound(self.Sound)
	end
end

pac.RegisterPart(PART)