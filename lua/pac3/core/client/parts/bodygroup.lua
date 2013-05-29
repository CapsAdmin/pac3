local PART = {}

PART.ClassName = "bodygroup"
PART.NonPhysical = true

pac.StartStorableVars()
	pac.GetSet(PART, "BodyGroupName", "")
	pac.GetSet(PART, "ModelIndex", 0)
pac.EndStorableVars()

function PART:OnShow()
	self:SetBodyGroupName(self:GetBodyGroupName())
end

function PART:SetBodyGroupName(str)
	self.BodyGroupName = str
	
	self.bodygroup_index = nil
	
	local ent = self:GetOwner()
	
	if ent:IsValid() then
		str = str:lower()
		for k,v in pairs(ent:GetBodyGroups()) do
			if v.name == str then
				self.bodygroup_index = v.id
				break
			end
		end
	end
	
	self:SetModelIndex(self:GetModelIndex())
end

function PART:SetModelIndex(i)
	self.ModelIndex = i
	
	if self.bodygroup_index then
		local ent = self:GetOwner()
		
		if ent:IsValid() then
			for k,v in pairs(ent:GetBodyGroups()) do
				if v.id == self.bodygroup_index then
					i = math.Clamp(i, 0, v.num - 1)
					
					ent:SetBodygroup(v.id, i)
					break
				end
			end
		end
	end
end

-- for the editor

function PART:GetModelIndexList()
	local out = {}
	
	local ent = self:GetOwner()
	
	if ent:IsValid() then
		for k,v in pairs(ent:GetBodyGroups()) do
			if v.id == self.bodygroup_index then
				for k,v in pairs(v.submodels) do
					table.insert(out, v)
				end
				break
			end
		end
	end
	
	return out
end

function PART:GetBodyGroupNameList()
	local out = {}
	
	local ent = self:GetOwner()
	
	if ent:IsValid() then
		for k,v in pairs(ent:GetBodyGroups()) do
			table.insert(out, v.name:lower())
		end
	end
	
	return out
end

pac.RegisterPart(PART)