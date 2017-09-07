local PART = {}

PART.ClassName = "bodygroup"
PART.NonPhysical = true
PART.Groups = {'entity', 'model', 'modifiers'}
PART.Icon = 'icon16/user.png'

pac.StartStorableVars()
	pac.GetSet(PART, "BodyGroupName", "", {enums = function()
		return pace.current_part:GetBodyGroupNameList()
	end})
	pac.GetSet(PART, "ModelIndex", 0)
pac.EndStorableVars()

function PART:OnShow()
	self:SetBodyGroupName(self:GetBodyGroupName())
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
			for _, info in pairs(ent:GetBodyGroups()) do
				if info.name == self.BodyGroupName:lower() then
					self.bodygroup_info = info
					self.bodygroup_info.model_index = math.Clamp(self.ModelIndex, 0, info.num - 1)

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
		for _, info in pairs(ent:GetBodyGroups()) do
			if info.id == self.bodygroup_info.id then
				for _, model in pairs(info.submodels) do
					table.insert(out, model)
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
		for _, info in pairs(ent:GetBodyGroups()) do
			out[info.name] = info.name:lower()
		end
	end

	return out
end

pac.RegisterPart(PART)