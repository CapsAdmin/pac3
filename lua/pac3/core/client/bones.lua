local NULL = NULL
local LerpVector = LerpVector
local LerpAngle = LerpAngle
local Angle = Angle
local Vector = Vector
local util_QuickTrace = util.QuickTrace
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
			for _, data in pairs(attachments) do
				local parent_i = ent:GetParentAttachment(data.id)
				if parent_i == -1 then
					parent_i = nil
				end
				local friendly = data.name or "????"

				friendly = friendly
				:Trim()
				:lower()
				:gsub("(.-)(%d+)", "%1 %2")

				if not tbl[friendly] then -- Some of bones CAN be attachments! So we defined them before already.
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
		end

		tbl.hitpos = {friendly = "hit position", is_special = true}
		tbl.footstep = {friendly = "footsteps", is_special = true}
		tbl.skirt = {friendly = "skirt", is_special = true}
		tbl.skirt2 = {friendly = "skirt2", is_special = true}
		tbl.hitpos_ent_ang = {friendly = "hitpos_ent_ang", is_special = true}
		tbl.hitpos_ent_ang_zero_pitch = {friendly = "hitpos_ent_ang_zero_pitch", is_special = true}
		tbl.pos_ang = {friendly = "pos_ang", is_special = true}
		tbl.pos_eyeang = {friendly = "pos_eyeang", is_special = true}
		tbl.eyepos_eyeang = {friendly = "eyepos_eyeang", is_special = true}
		tbl.eyepos_ang = {friendly = "eyepos_ang", is_special = true}
		tbl.pos_noang = {friendly = "pos_noang", is_special = true}

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

local function GetBonePosition(ent, id)
	local pos, ang, mat = ent:GetBonePosition(id)

	if not pos then return end

	if ang.p ~= ang.p then ang.p = 0 end
	if ang.y ~= ang.y then ang.y = 0 end
	if ang.r ~= ang.r then ang.r = 0 end

	if pos == ent:GetPos() then
		mat = ent:GetBoneMatrix(id)
		if mat then
			pos = mat:GetTranslation()
			ang = mat:GetAngles()
		end
	end

	if ent:GetClass() == "viewmodel" and ent:GetOwner():IsPlayer() and ent:GetOwner():GetActiveWeapon().ViewModelFlip then
		ang.r = -ang.r
	end

	return pos, ang
end

local angle_origin = Angle(0,0,0)

function pac.GetBonePosAng(ent, id, parent)
	if not ent:IsValid() then return Vector(), Angle() end

	local override = ent.pac_owner_override
	if override and override:IsValid() then
		ent = override
	end

	if id == "pos_ang" then
		return ent:GetPos(), ent:GetAngles()
	end

	if id == "pos_noang" then
		return ent:GetPos(), angle_origin
	end

	if id == "pos_eyeang" then
		return ent:GetPos(), ent:EyeAngles()
	end

	if id == "eyepos_eyeang" then
		return ent:EyePos(), ent:EyeAngles()
	end

	if id == "eyepos_ang" then
		return ent:EyePos(), ent:GetAngles()
	end

	if id == "hitpos" or id == "hit position" then
		if ent.pac_traceres then
			return ent.pac_traceres.HitPos, ent.pac_traceres.HitNormal:Angle()
		else
			local res = util_QuickTrace(ent:EyePos(), ent:EyeAngles():Forward() * 16000, {ent, ent:GetParent()})

			return res.HitPos, res.HitNormal:Angle()
		end
	end

	if id == "hitpos_ent_ang" then
		if ent.pac_traceres then
			return ent.pac_traceres.HitPos, ent:EyeAngles()
		else
			local res = util_QuickTrace(ent:EyePos(), ent:EyeAngles():Forward() * 16000, {ent, ent:GetParent()})

			return res.HitPos, ent:EyeAngles()
		end
	end

	if id == "hitpos_ent_ang_zero_pitch" then
		if ent.pac_traceres then
			local ang = ent:EyeAngles()
			ang.p = 0
			return ent.pac_traceres.HitPos, ang
		else
			local res = util_QuickTrace(ent:EyePos(), ent:EyeAngles():Forward() * 16000, {ent, ent:GetParent()})

			return res.HitPos, ent:EyeAngles()
		end
	end

	if id == "footstep" then
		if ent.pac_last_footstep_pos then
			return ent.pac_last_footstep_pos, UP
		end
	end

	if id == "skirt" then
		local apos, aang = pac.GetBonePosAng(ent, "left thigh", parent)
		local bpos, bang = pac.GetBonePosAng(ent, "right thigh", parent)

		return LerpVector(0.5, apos, bpos), LerpAngle(0.5, aang, bang)
	end

	if id == "skirt2" then
		local apos, aang = pac.GetBonePosAng(ent, "left calf", parent)
		local bpos, bang = pac.GetBonePosAng(ent, "right calf", parent)

		return LerpVector(0.5, apos, bpos), LerpAngle(0.5, aang, bang)
	end

	local pos, ang

	local bones = pac.GetModelBones(ent)
	local data = bones[id]

	if data and not data.is_special then
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

do -- bone manipulation for boneanimlib
	local SCALE_RESET = Vector(1,1,1)
	local ORIGIN_RESET = Vector(0,0,0)
	local ANGLE_RESET = Angle(0,0,0)

	function pac.ResetBones(ent)
		ent.pac_boneanim = ent.pac_boneanim or {positions = {}, angles = {}}

		local count = ent:GetBoneCount() or -1

		if count > 1 then
			for i = 0, count do
				ent:ManipulateBoneScale(i, SCALE_RESET)
				ent:ManipulateBonePosition(i, ent.pac_boneanim.positions[i] or ORIGIN_RESET)
				ent:ManipulateBoneAngles(i, ent.pac_boneanim.angles[i] or ANGLE_RESET)
				ent:ManipulateBoneJiggle(i, 0)
			end
		end

		hook.Call("PAC3ResetBones", nil, ent)
	end

	function pac.ManipulateBonePosition(ply, id, var)
		ply.pac_boneanim = ply.pac_boneanim or {positions = {}, angles = {}}

		ply.pac_boneanim.positions[id] = var

		if not ply.pac_parts then
			ply:ManipulateBonePosition(id, var)
		end
	end

	function pac.ManipulateBoneAngles(ply, id, var)
		ply.pac_boneanim = ply.pac_boneanim or {positions = {}, angles = {}}

		ply.pac_boneanim.angles[id] = var

		if not ply.pac_parts then
			ply:ManipulateBoneAngles(id, var)
		end
	end
end