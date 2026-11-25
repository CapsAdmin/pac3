local BUILDER, PART = pac.PartTemplate("base")

PART.ClassName = "poseparameter"

PART.ThinkTime = 0
PART.Group = {'modifiers', 'entity'}
PART.Icon = 'icon16/disconnect.png'

BUILDER:StartStorableVars()
	BUILDER:GetSet("PoseParameter", "", {enums = function(part) return part:GetPoseParameterList() end})
	BUILDER:GetSet("Range", 0)
    BUILDER:GetSet("RawRange", false, {description="Passes the raw value of Range to SetPoseParameter instead of remapping.\nFor example with head_yaw, a range of [-1,1] would then need to use [-75,75]"})
BUILDER:EndStorableVars()

function PART:GetNiceName()
	return pac.PrettifyName(self:GetPoseParameter())
end

function PART:GetPoseParameterList()
	local ent = self:GetOwner()

	local out = {}

	if ent:IsValid() then
		for i = 0, ent:GetNumPoseParameters()-1 do
			local name = ent:GetPoseParameterName(i)
			if name ~= "" then
				out[name] = {name = name, i = i, range = {ent:GetPoseParameterRange(i)}}
			end
		end
	end

	return out
end

function PART:SetRange(num)
	self.Range = num
	self:UpdateParams()
end

function PART:UpdateParams()
	local ent = self:GetOwner()

	if ent:IsValid() then
		if not self.pose_params or ent:GetModel() ~= self.last_owner_mdl then
			self.pose_params = self:GetPoseParameterList()
			self.last_owner_mdl = ent:GetModel()
		end

		local data = self.pose_params[self.PoseParameter]

		if data then
			local num

            if self.RawRange then 
                num = self.Range
            else
                num = Lerp((self.Range + 1) / 2, data.range[1] or 0, data.range[2] or 1)
            end

			ent.pac_pose_params = ent.pac_pose_params or {}
			ent.pac_pose_params[self.UniqueID] = ent.pac_pose_params[self.UniqueID] or {}

			ent.pac_pose_params[self.UniqueID].key  = data.name
			ent.pac_pose_params[self.UniqueID].val = num

			ent:SetPoseParameter(data.name, num)
		end
	end
end

function PART:OnBuildBonePositions()
    self:UpdateParams()
end

function PART:OnHide()
	local ent = self:GetOwner()

	if ent:IsValid() then
		ent.pac_pose_params = nil
		ent:ClearPoseParameters()
	end
end

function PART:OnShow(ent)
	self:UpdateParams()
end

BUILDER:Register()