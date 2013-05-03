local PART = {}

PART.ClassName = "poseparameter"
PART.NonPhysical = true
PART.ThinkTime = 0

pac.StartStorableVars()
	pac.GetSet(PART, "PoseParameter", "")
	pac.GetSet(PART, "Range", 0)
pac.EndStorableVars()

function PART:GetNiceName()
	return pac.PrettifyName(self:GetPoseParameter())
end

function PART:GetPoseParameterList()
	local ent = self:GetOwner()
	
	local out = {}
	
	if ent:IsValid() then
		for i = 1, ent:GetNumPoseParameters()-1 do
			local name = ent:GetPoseParameterName(i)
			if name ~= "" then
				out[name] = {name = name, i = i, range = {ent:GetPoseParameterRange(i)}}
			end
		end	
	end
	
	return out
end

function PART:OnThink(ent)
	local ent = self:GetOwner()
	
	if ent:IsValid() then		
		if self:IsHidden() then
			ent.pac_pose_param = nil
		else	
			if not self.pose_params or ent:GetModel() ~= self.last_owner_mdl then
				self.pose_params = self:GetPoseParameterList()
				self.last_owner_mdl = ent:GetModel()
			end
			
			local data = self.pose_params[self.PoseParameter]
			if data then
				local num = Lerp((self.Range + 1) / 2, data.range[1] or 0, data.range[2] or 1)
				
				ent.pac_pose_params = ent.pac_pose_params or {}
				ent.pac_pose_params[self.UniqueID] = ent.pac_pose_params[self.UniqueID] or {}
				
				ent.pac_pose_params[self.UniqueID].key  = data.name
				ent.pac_pose_params[self.UniqueID].val = num
				
				ent:SetPoseParameter(data.name, num)
			else
				ent.pac_pose_param = nil
			end
		end
	end
end

pac.RegisterPart(PART)