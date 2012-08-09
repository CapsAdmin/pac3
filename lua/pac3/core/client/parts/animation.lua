local PART = {}

PART.ClassName = "animation"
PART.HideGizmo = true
PART.ThinkTime = 0

PART.frame = 0

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
		if VERSION >= 150 then
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

local tonumber = tonumber

function PART:OnThink()
	if self:IsHiddenEx() then return end
	
	local ent = self:GetOwner()

	if ent:IsValid() then	
		
		local seq = ent:LookupSequence(self.SequenceName)
		local rate = self.Rate * FrameTime() / 2
		
		if seq == -1 then
			ent:SetSequence(tonumber(self.SequenceName) or -1)			
			return
		else
			ent:ResetSequence(seq)
			if rate == 0 then
				ent:SetCycle(self.Offset)
				return
			end
		end
				
		local min = self.Min
		local max = self.Max
		
		if self.PingPongLoop then
			self.frame = self.frame + rate / 2
			ent:SetCycle(min + math.abs(math.Round((self.frame + self.Offset)*0.5) - (self.frame + self.Offset)*0.5)*2 * (max - min))
		else
			self.frame = self.frame + rate
			ent:SetCycle(min + ((self.frame + self.Offset)*0.5)%1 * (max - min))
		end
	end
end
	
pac.RegisterPart(PART)