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
		local count = ent:GetBoneCount() or 1

		for i = 0, count do
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
	end

	return tbl
end

function pac.GetModelBones(ent)

	if ent:IsValid() and (not ent.pac_bones or ent:GetModel() ~= ent.pac_last_model) then
		ent.pac_bones = pac.GetAllBones(ent)
		ent.pac_last_model = ent:GetModel()
	end

	return ent.pac_bones
end

function pac.GetModelBonesSorted(ent, o)
	local bones = o or table.Copy(pac.GetModelBones(ent))
	bones = table.ClearKeys(bones)

	table.sort(bones, function(a,b)
		return a.friendly > b.friendly
	end)

	return bones
end

function pac.HookBuildBone(ent)
	ent.BuildBonePositions = function(...)
		hook.Call("EntityBuildBonePositions", GAMEMODE, ...)
	end
end