
local PART = {}

PART.ClassName = "bodygroup"
PART.NonPhysical = true
PART.Groups = {'entity', 'model', 'modifiers'}
PART.Icon = 'icon16/user.png'

pac.StartStorableVars()
	pac.GetSet(PART, "BodyGroupName", "", {
		enums = function()
			return pace.current_part:GetBodyGroupNameList()
		end
	})
	pac.GetSet(PART, "ModelIndex", 0)
pac.EndStorableVars()

function PART:OnShow()
	self:SetBodyGroupName(self:GetBodyGroupName())
end

function PART:GetNiceName()
	return self.BodyGroupName ~= "" and self.BodyGroupName or "no bodygroup"
end

function PART:SetBodyGroupName(str)
	local owner = self:GetOwner()

	if owner:IsValid() and not self.markedFailed and self.bodygroup_index and self.oldBodygroup then
		owner:SetBodygroup(self.bodygroup_index, self.oldBodygroup)

		if owner:IsPlayer() then
			owner.pac_bodygroups_torender = owner.pac_bodygroups_torender or {}
			owner.pac_bodygroups_torender[self.bodygroup_index] = self.oldBodygroup
		end

		self.oldBodygroup = nil
	end

	self.BodyGroupName = str
	self.markedFailed = false
	self:UpdateBodygroupData()
end

function PART:SetModelIndex(i)
	self.ModelIndex = math.floor(tonumber(i) or 0)
	self.markedFailed = false
	self:UpdateBodygroupData()
end

function PART:UpdateBodygroupData()
	self.bodygroup_index = nil
	self.minIndex = 0
	self.maxIndex = 0
	local ent = self:GetOwner()

	if not IsValid(ent) or not ent:GetBodyGroups() then return end
	local fName = self.BodyGroupName:lower():Trim()

	if fName == '' then
		return
	end

	for i, info in ipairs(ent:GetBodyGroups()) do
		if info.name:lower():Trim() == fName then
			self.bodygroup_index = info.id
			self.maxIndex = info.num - 1
			self.markedFailed = false
			self.oldBodygroup = ent:GetBodygroup(info.id)
			return
		end
	end

	if not self.markedFailed then
		pac.Message(self, ' - Unable to find bodygroup ' .. fName .. ' on ', ent)
		self.markedFailed = true
	end
end

function PART:OnBuildBonePositions()
	if self.markedFailed then return end
	local owner = self:GetOwner()

	if not owner:IsValid() then return end
	if not self.bodygroup_index then
		self:UpdateBodygroupData()
		return
	end

	owner:SetBodygroup(self.bodygroup_index, self.ModelIndex)

	if owner:IsPlayer() then
		owner.pac_bodygroups_torender = owner.pac_bodygroups_torender or {}
		owner.pac_bodygroups_torender[self.bodygroup_index] = self.ModelIndex
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
			out[info.name] = info.name
		end
	end

	return out
end

pac.RegisterPart(PART)
