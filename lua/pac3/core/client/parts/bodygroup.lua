
local PART = {}

PART.ClassName = "bodygroup"
PART.NonPhysical = true
PART.Groups = {'entity', 'model', 'modifiers'}
PART.Icon = 'icon16/user.png'
PART.RenderPriority = 2

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

function PART:SetBodyGroupName(str)
	self.BodyGroupName = str
	self:UpdateBodygroupData()
end

function PART:SetModelIndex(i)
	self.ModelIndex = math.floor(tonumber(i) or 0)
	self:UpdateBodygroupData()
end

function PART:UpdateBodygroupData()
	self.bodygroup_index = nil
	self.minIndex = 0
	self.maxIndex = 0
	local ent = self:GetOwner()

	if not IsValid(ent) then return end
	local fName = self.BodyGroupName:lower()

	for i, info in ipairs(ent:GetBodyGroups()) do
		if info.name == fName then
			self.bodygroup_index = info.id
			self.maxIndex = info.num - 1
			break
		end
	end
end

function PART:Draw(event, pos, ang, draw_type)
	if not self.last_enabled or self:IsHidden() then return end
	if not self.bodygroup_index then return self:DrawChildren(event, pos, ang, draw_type) end
	local ent = self:GetOwner()
	if not IsValid(ent) then return self:DrawChildren(event, pos, ang, draw_type) end
	if self.ModelIndex < self.minIndex or self.ModelIndex > self.maxIndex then return self:DrawChildren(event, pos, ang, draw_type) end
	ent:SetBodygroup(self.bodygroup_index, self.ModelIndex)
	self:DrawChildren(event, pos, ang, draw_type)
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
