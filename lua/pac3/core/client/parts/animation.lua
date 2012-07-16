local PART = {}

PART.ClassName = "animation"
PART.HideGizmo = true

function PART:Initialize()
	self.StorableVars = {}
	
	pac.StartStorableVars()
		pac.GetSet(self, "Name", "")
		pac.GetSet(self, "Description", "")
		pac.GetSet(self, "OwnerName", "")
		pac.GetSet(self, "ParentName", "")
		pac.GetSet(self, "Hide", false)
		
		pac.GetSet(self, "Loop", true)
		pac.GetSet(self, "PingPongLoop", false)
		pac.GetSet(self, "SequenceName", "ragdoll")
		pac.GetSet(self, "Rate", 1)
		pac.GetSet(self, "Offset", 0)
		pac.GetSet(self, "Min", 0)
		pac.GetSet(self, "Max", 1)
	pac.EndStorableVars()
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
function PART:GetSequenceList()
	local ent = self:GetOwner()

	if ent:IsValid() then	
		if net then
			return ent:GetSequenceList()
		else
			local tbl = {}
			local last -- hack for gmod 12
			for i = 1, 1000 do 
				local name = ent:GetSequenceName(i)
				if name ~= "Unknown" and name ~= last then 
					tbl[i] = name
					last = name
				else
					return tbl
				end
			end
			return tbl
		end
	end
	return {"none"}
end

local UnPredictedCurTime = UnPredictedCurTime
local tonumber = tonumber

function PART:OnThink()
	if self:IsHiddenEx() then return end
	
	local ent = self:GetOwner()

	if ent:IsValid() then	
		local seq = ent:LookupSequence(self.SequenceName)
		
		if seq ~= -1 then
			ent:ResetSequence(seq)
		else
			ent:ResetSequence(tonumber(self.SequenceName) or -1)
		end
		
		if self.Rate > 0 then
			local frame = (UnPredictedCurTime() + self.Offset) * self.Rate
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