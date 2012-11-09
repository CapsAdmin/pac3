local pac = pac

pac.BoneNameReplacements =
{
	{"Anim_Attachment", "attach"},
	{"RH", "right hand"},
	{"LH", "left hand"},
	{"_L_", " left "},
	{"_R_", " right "},
	{"%p", " "},
	{"ValveBiped", ""},
	{"Bip01", ""},
	{"Neck1", "neck"},
	{"Head1", "head"},
	{"Toe0", "toe"},
	{"lowerarm", "lower arm"},
	{"Bip", ""},
	{" R", " right"},
	{" L", " left"},
}

function pac.GetAllBones(ent)
	ent = ent or NULL

	local tbl = {}

	if ent:IsValid() then
		ent:InvalidateBoneCache()
		ent:SetupBones()
	
		local count = ent:GetBoneCount()

		for i = 0, count or 1 do
			local name = ent:GetBoneName(i)
			local bone = ent:LookupBone(name)
			local friendly = name

			if bone then
				for _, value in ipairs(pac.BoneNameReplacements) do
					friendly = friendly:gsub(value[1], value[2])
				end

				friendly = friendly
				:Trim()
				:lower()
				:gsub("(.-)(%d+)", "%1 %2")
				
				local parent_i = ent:GetBoneParent(i)
				if parent_i == -1 then
					parent_i = nil
				end

				tbl[friendly] =
				{
					friendly = friendly,
					real = name,
					bone = bone,
					i = i,
					parent_i = parent_i,
				}
			end
		end
		
		ent.pac_bone_count = count
	end

	return tbl
end

function pac.GetModelBones(ent)
	if not ent then debug.Trace() end

	if ent:IsValid() and (not ent.pac_bones or ent:GetModel() ~= ent.pac_last_model or ent:GetBoneCount() ~= ent.pac_bone_count) then
		ent.pac_bones = pac.GetAllBones(ent)
		ent.pac_last_model = ent:GetModel()
	end

	return ent.pac_bones
end

local SCALE_RESET = Vector(1,1,1)
local ORIGIN_RESET = Vector(0,0,0)
local ANGLE_RESET = Angle(0,0,0)

function pac.ResetBones(ent)
	local count = ent:GetBoneCount() or -1
	if count > 1 then
		for i = 0, count do
			ent:ManipulateBoneScale(i, SCALE_RESET)
			ent:ManipulateBonePosition(i, ORIGIN_RESET)
			ent:ManipulateBoneAngles(i, ANGLE_RESET)
		end
	end
end