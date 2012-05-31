local PART = {}

PART.ClassName = "animation"		

pac.StartStorableVars()
	pac.GetSet(PART, "Loop", true)
	pac.GetSet(PART, "PingPongLoop", true)
	pac.GetSet(PART, "Name", "invalid name")
	pac.GetSet(PART, "Sequence", -1)
	pac.GetSet(PART, "Rate", 1)
	pac.GetSet(PART, "Offset", 0)
	pac.GetSet(PART, "Min", 0)
	pac.GetSet(PART, "Max", 1)
pac.EndStorableVars()

function PART:GetEntity()
	return self.Parent:IsValid() and self.Parent.ClassName == "model" and self.Parent:GetEntity() or self:GetOwner()
end

function PART:OnDraw()
	local ent = self:GetEntity()

	if ent:IsValid() then	
		local seq = ent:LookupSequence(self.Name)
		
		if seq ~= -1 then
			ent:ResetSequence(seq)
		else
			ent:ResetSequence(self.Sequence)
		end
		
		if self.Rate > 0 then
			local frame = (CurTime() + self.Offset) * self.Rate
			local min = self.Min
			local max = self.Max
			if self.PingPongLoop then
				ent:SetCycle(min + math.abs(math.Round(frame*0.5) - frame*0.5)*2 * (max - min))
			else
				ent:SetCycle(min + frame%1 * (max - min))
			end
		else
			ent:SetCycle(self.Offset)
		end
	end
end
	
pac.RegisterPart(PART)