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

		for bone = 0, count or 1 do
			local name = ent:GetBoneName(bone)
			local friendly = name

			if name then
				for _, value in pairs(pac.BoneNameReplacements) do
					friendly = friendly:gsub(value[1], value[2])
				end

				friendly = friendly
				:Trim()
				:lower()
				:gsub("(.-)(%d+)", "%1 %2")
				
				local parent_i = ent:GetBoneParent(bone)
				if parent_i == -1 then
					parent_i = nil
				end

				tbl[friendly] =
				{
					friendly = friendly,
					real = name,
					bone = bone,
					i = bone,
					parent_i = parent_i,
				}
			end
		end
		
		local attachments = ent:GetAttachments()
		if attachments then
			for key, data in pairs(attachments) do	
				local parent_i = ent:GetParentAttachment(data.id)
				if parent_i == -1 then
					parent_i = nil
				end
				local friendly = data.name or "????"
				
				friendly = friendly
				:Trim()
				:lower()
				:gsub("(.-)(%d+)", "%1 %2")
			
				tbl[friendly] =
				{
					friendly = friendly,
					real = data.name or "?????",
					id = data.id,
					i = data.id,
					parent_i = parent_i,
					is_attachment = true,				
				}
			end
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

local UP = Vector(0,0,1):Angle()

pac.AddHook("pac_PlayerFootstep", function(ply, pos)
	ply.pac_last_footstep_pos = pos	
end)

local function GetBonePosition(ent, id)
	if pac.MatrixBoneMethod then		
		local mat = ent:GetBoneMatrix(id)
				
		if mat then
			return mat:GetTranslation(), mat:GetAngles()
		end
	end
	
	return ent:GetBonePosition(id)
end

local function GetBonePosition(ent, id)
	local pos, ang =  ent:GetBonePosition(id)
	
	if ang and ent:GetClass() == "viewmodel" and ent:GetOwner():IsPlayer() and ent:GetOwner():GetActiveWeapon().ViewModelFlip then
		ang.r = -ang.r
	end
		
	return pos, ang
end

function pac.GetBonePosAng(ent, id, parent)
	if not ent:IsValid() then return Vector(), Angle() end
	
	if ent:IsPlayer() and not ent:Alive() then
		local rag = ent:GetRagdollEntity() or NULL
		if rag:IsValid() then
			ent = rag
		end
	end
	
	if id == "hitpos" then
		if ent.pac_traceres then
			return ent.pac_traceres.HitPos, ent.pac_traceres.HitNormal:Angle()
		else
			local res = util.QuickTrace(ent:EyePos(), ent:EyeAngles():Forward() * 16000, {ent, ent:GetParent()})
			
			return res.HitPos, res.HitNormal:Angle()
		end
	end
	
	if id == "footstep" then
		if ent.pac_last_footstep_pos then
			return ent.pac_last_footstep_pos, UP
		end
	end
		
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
					pos, ang = posang.Pos, posang.Ang
				end
			else
				local posang = ent:GetAttachment(data.id)
				if posang then
					pos, ang = posang.Pos, posang.Ang
				end
			end
		else		
			if parent and data.parent_i then
				pos, ang = GetBonePosition(ent, data.parent_i)
				if not pos or not ang then
					pos, ang = GetBonePosition(ent, data.bone)
				end
			else
				pos, ang = GetBonePosition(ent, data.bone)
			end
		end
	else
		local id = id and ent:LookupBone(id) or nil
		if id then
			pos, ang = GetBonePosition(ent, id)
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