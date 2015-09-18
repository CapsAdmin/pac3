local PART = {}

PART.ClassName = "bodygroup"
PART.NonPhysical = true

pac.StartStorableVars()
	pac.GetSet(PART, "BodyGroupName", "")
	pac.GetSet(PART, "ModelIndex", 0)
pac.EndStorableVars()

function PART:GetNiceBodyGroupName()
	return self:GetBodyGroupName():gsub("^(%d+)",""):Trim()
end

function PART:OnShow()
	self:SetBodyGroupName(self:GetNiceBodyGroupName())
end

function PART:SetBodyGroupName(str)
	self.BodyGroupName = str
	self.bodygroup_info = nil
end

function PART:SetModelIndex(i)
	self.ModelIndex = i
	self.bodygroup_info = nil
end

function PART:OnThink()
	local ent = self:GetOwner()
	
	if ent:IsValid() then
		if not self.bodygroup_info then
			for k,v in pairs(ent:GetBodyGroups()) do
				if v.name:lower() == self:GetNiceBodyGroupName() then
					self.bodygroup_info = v
					self.bodygroup_info.model_index = math.Clamp(self:GetModelIndex(), 0, v.num - 1)
					
					if ent:IsPlayer() then
						ent.pac_bodygroup_info = self.bodygroup_info
					end
					break
				end
			end
		end
	
		if self.bodygroup_info and not ent:IsPlayer() then
			ent:SetBodygroup(self.bodygroup_info.id, self.bodygroup_info.model_index)
		end
	end
end

function PART:OnRemove()
	local ent = self:GetOwner()
	
	if ent:IsValid() and ent:IsPlayer() then
		ent.pac_bodygroup_info = nil
	end
end

-- for the editor

function PART:GetModelIndexList()
	local out = {}
	
	local ent = self:GetOwner()
	
	if ent:IsValid() then
		for k,v in pairs(ent:GetBodyGroups()) do
			if v.id == self.bodygroup_info.id then
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
