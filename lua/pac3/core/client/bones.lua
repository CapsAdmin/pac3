local NULL = NULL
local LerpVector = LerpVector
local LerpAngle = LerpAngle
local Angle = Angle
local Vector = Vector
local util_QuickTrace = util.QuickTrace
local pac = pac
local pac_isCameraAllowed = pac.CreateClientConVarFast("pac_enable_camera_as_bone", "1", true, "boolean")

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

		local count = (ent:GetBoneCount() or 0) - 1

		for bone = 0, count do
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
		tbl.camera = {friendly = "camera", is_special = true}
		tbl.player_eyes = {friendly = "player_eyes", is_special = true}
		tbl.physgun_beam_endpos = {friendly = "physgun_beam_endpos", is_special = true}

		ent.pac_bone_count = count + 1
	end

	return tbl
end

function pac.GetModelBones(ent)
	if not ent or not ent:IsValid() then return {} end

	if not ent.pac_bones or ent:GetModel() ~= ent.pac_last_model then
		ent:InvalidateBoneCache()
		ent:SetupBones()

		if ent.pac_holdtypes then
			ent.pac_holdtypes = {}
		end

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

	if (ent:GetClass() == "viewmodel" or ent == pac.LocalHands) and
		ent:GetOwner():IsPlayer() and ent:GetOwner():GetActiveWeapon().ViewModelFlip then
		ang.r = -ang.r
	end

	return pos, ang
end

local angle_origin = Angle(0,0,0)

function pac.GetBonePosAng(ent, id, parent)
	if not ent:IsValid() then return Vector(), Angle() end

	if id == "physgun_beam_endpos" then
		if ent.pac_drawphysgun_event then

			local ply, wep, enabled, target, bone, hitpos = unpack(ent.pac_drawphysgun_event)

			local endpos

			if enabled then
				if target:IsValid() then
					if bone ~= 0 then
						local wpos, wang = target:GetBonePosition(target:TranslatePhysBoneToBone(bone))
						endpos = LocalToWorld(hitpos, Angle(), wpos, wang)
					else
						endpos = target:LocalToWorld(hitpos)
					end
				else
					endpos = ply.pac_traceres and ply.pac_traceres.HitPos or util_QuickTrace(ply:EyePos(), ply:EyeAngles():Forward() * 16000, {ply, ply:GetParent()}).HitPos
				end
			end

			return endpos, Angle()
		end
	end

	if id == "camera" then
		if pac_isCameraAllowed() then
			return pac.EyePos, pac.EyeAng
		else
			return ent:EyePos(), ent:EyeAngles()
		end
	end

	if id == "player_eyes" then
		local oldEnt = ent -- Track reference to the original entity in case we aren't allowed to draw here
		local ent = ent.pac_traceres and ent.pac_traceres.Entity or util_QuickTrace(ent:EyePos(), ent:EyeAngles():Forward() * 16000, {ent, ent:GetParent()}).Entity
		local allowed = pac_isCameraAllowed()

		if ent:IsValid() and (allowed or ent ~= pac.LocalPlayer) then -- Make sure we don't draw on viewer's screen if we aren't allowed to
			return ent:EyePos(), ent:EyeAngles()
		end

		if allowed then
			return pac.EyePos, pac.EyeAng
		else
			return oldEnt:EyePos(), oldEnt:EyeAngles()
		end
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
		local bone_id = id and ent:LookupBone(id) or nil
		if bone_id then
			pos, ang = GetBonePosition(ent, bone_id)
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
	local SCALE_RESET = Vector(1, 1, 1)
	local ORIGIN_RESET = Vector(0, 0, 0)
	local ANGLE_RESET = Angle(0, 0, 0)

	local entmeta = FindMetaTable("Entity")

	local ManipulateBoneScale = entmeta.ManipulateBoneScale
	local ManipulateBonePosition = entmeta.ManipulateBonePosition
	local ManipulateBoneAngles = entmeta.ManipulateBoneAngles
	local ManipulateBoneJiggle = entmeta.ManipulateBoneJiggle

	function pac.ResetBones(ent)
		local pac_boneanim = ent.pac_boneanim
		local count = (ent:GetBoneCount() or 0) - 1

		if pac_boneanim then
			for i = 0, count do
				ManipulateBoneScale(ent, i, SCALE_RESET)
				ManipulateBonePosition(ent, i, pac_boneanim.positions[i] or ORIGIN_RESET)
				ManipulateBoneAngles(ent, i, pac_boneanim.angles[i] or ANGLE_RESET)
				ManipulateBoneJiggle(ent, i, 0)
			end
		else
			for i = 0, count do
				ManipulateBoneScale(ent, i, SCALE_RESET)
				ManipulateBonePosition(ent, i, ORIGIN_RESET)
				ManipulateBoneAngles(ent, i, ANGLE_RESET)
				ManipulateBoneJiggle(ent, i, 0)
			end
		end

		hook.Call("PAC3ResetBones", nil, ent)

		local i = ent.pac_bones_select_target
		if i and count >= i then
			ManipulateBoneScale(ent, i, ent:GetManipulateBoneScale(i) * (1 + math.sin(RealTime() * 4) * 0.1))
			ent.pac_bones_select_target = nil
		end
	end

	function pac.ManipulateBonePosition(ply, id, var)
		ply.pac_boneanim = ply.pac_boneanim or {positions = {}, angles = {}}

		ply.pac_boneanim.positions[id] = var

		if not ply.pac_has_parts then
			ply:ManipulateBonePosition(id, var)
		end
	end

	function pac.ManipulateBoneAngles(ply, id, var)
		ply.pac_boneanim = ply.pac_boneanim or {positions = {}, angles = {}}

		ply.pac_boneanim.angles[id] = var

		if not ply.pac_has_parts then
			ply:ManipulateBoneAngles(id, var)
		end
	end
end

if LocalPlayer():IsValid() then
	timer.Simple(0, function()
		for _, v in ipairs(ents.GetAll()) do
			v.pac_bones = nil
			v.pac_last_model = nil
		end
	end)
end
