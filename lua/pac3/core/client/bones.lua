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
				for _, value in pairs(pac.BoneNameReplacements) do
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
		
		for key, data in pairs(ent:GetAttachments()) do	
			local parent_i = ent:GetParentAttachment(data.id)
			if parent_i == -1 then
				parent_i = nil
			end
			local friendly = data.name
			
			friendly = friendly
			:Trim()
			:lower()
			:gsub("(.-)(%d+)", "%1 %2")
		
			tbl[friendly] =
			{
				friendly = friendly,
				real = data.name,
				id = data.id,
				i = data.id,
				parent_i = parent_i,
				is_attachment = true,				
			}
		end
		
		ent.pac_bone_count = count
	end

	return tbl
end

function pac.GetModelBones(ent)

	if not ent.pac_bones or ent:GetModel() ~= ent.pac_last_model then
		ent.pac_bones = pac.GetAllBones(ent)
		ent.pac_last_model = ent:GetModel()
	end

	return ent.pac_bones
end

function pac.GetBonePosAng(ent, id, parent)
	if not ent:IsValid() then return Vector(), Angle() end

	local pos, ang
	
	local bones = pac.GetModelBones(ent)
	local data = bones[id]
	
	if data then
		if data.is_attachment then
			if parent and data.parent_i then
				local posang = ent:GetAttachment(data.parent_i)
				
				if not posang then
					posang = ent:GetAttachment(data.id)
				end	
				
				if posang then
					return posang.Pos, posang.Ang
				end
			else
				local posang = ent:GetAttachment(data.id)
				if posang then
					return posang.Pos, posang.Ang
				end
			end
		end
		
		if parent and data.parent_i then
			pos, ang = ent:GetBonePosition(data.parent_i)
			if not pos or not ang then
				pos, ang = ent:GetBonePosition(data.bone)
			end
		else
			pos, ang = ent:GetBonePosition(data.bone)
		end
	end
	
	if not pos then 
		pos = ent:GetPos() 
	end
	
	if not ang then
		if ent:IsPlayer() then
			ang = ent:EyeAngles()
			ang.p = 0
		else
			ang = ent:GetAngles()
		end
	end
	
	return pos, ang
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
			ent:ManipulateBoneJiggle(i, 0)
		end
	end
end