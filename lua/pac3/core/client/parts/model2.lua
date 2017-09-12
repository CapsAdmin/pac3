local pac = pac

local render_SetColorModulation = render.SetColorModulation
local render_SetBlend = render.SetBlend
local render_SetMaterial = render.SetMaterial
local render_ModelMaterialOverride = render.MaterialOverride
local render_MaterialOverride = render.ModelMaterialOverride

local Vector = Vector
local EF_BONEMERGE = EF_BONEMERGE
local NULL = NULL
local Color = Color

local PART = {}

PART.ClassName = "model2"
PART.Category = "model"
PART.ManualDraw = true
PART.HandleModifiersManually = true
PART.Icon = 'icon16/shape_square.png'
PART.Group = 'pac4'
PART.is_model_part = true

pac.StartStorableVars()

	pac.SetPropertyGroup("generic")
		pac.GetSet(PART, "Model", "", {editor_panel = "model"})

	pac.SetPropertyGroup("orientation")
		pac.GetSet(PART, "Size", 1, {editor_sensitivity = 0.25})
		pac.GetSet(PART, "Scale", Vector(1,1,1))
		pac.GetSet(PART, "BoneMerge", false)

	pac.SetPropertyGroup("appearance")
		pac.GetSet(PART, "Color", Vector(1, 1, 1), {editor_panel = "color2"})
		pac.GetSet(PART, "Alpha", 1, {editor_sensitivity = 0.25, editor_clamp = {0, 1}})
		pac.GetSet(PART, "ModelModifiers", "", {editor_panel = "model_modifiers"})

pac.EndStorableVars()

function PART:GetNiceName()
	local str = pac.PrettifyName(("/" .. self:GetModel()):match(".+/(.-)%."))

	return str and str:gsub("%d", "") or "error"
end

function PART:SetSkin(var)
	self.Skin = var
	self.Entity:SetSkin(var)
end

function PART:ModelModifiersToTable(str)
	if str == "" or (not str:find(";", nil, true) and not str:find("=", nil, true)) then return {} end

	local tbl = {}
	for _, data in ipairs(str:Split(";")) do
		local key, val = data:match("(.+)=(.+)")
		if key then
			key = key:Trim()
			val = tonumber(val:Trim())

			tbl[key] = val
		else
			print(data)
		end
	end

	return tbl
end

function PART:ModelModifiersToString(tbl)
	local str = ""
	for k,v in pairs(tbl) do
		str = str .. k .. "=" .. v .. ";"
	end
	return str
end

function PART:SetModelModifiers(str)
	self.ModelModifiers = str

	if not self.Entity:GetBodyGroups() then return end

	local tbl = self:ModelModifiersToTable(str)

	if tbl.skin then
		self.Entity:SetSkin(tbl.skin)
		tbl.skin = nil
	end

	for i, info in ipairs(self.Entity:GetBodyGroups()) do
		local val = tbl[info.name:lower()]
		if val then
			self.Entity:SetBodygroup(info.id, val)
		end
	end
end

function PART:Reset()
	self:Initialize()
	for _, key in pairs(self:GetStorableVars()) do
		if PART[key] then
			self["Set" .. key](self, self["Get" .. key](self))
		end
	end
end

function PART:Initialize()
	self.Entity = pac.CreateEntity(self:GetModel())
	self.Entity:SetNoDraw(true)
	self.Entity.PACPart = self
end

function PART:GetEntity()
	return self.Entity or NULL
end

function PART:OnShow()
	local owner = self:GetOwner()
	local ent = self:GetEntity()

	if ent:IsValid() and owner:IsValid() and owner ~= ent then
		ent:SetPos(owner:EyePos())
		self.BoneIndex = nil
	end
end

function PART:OnThink()
	self:CheckBoneMerge()
end

function PART:PreEntityDraw(owner, ent, pos, ang)
	if not ent:IsPlayer() and pos and ang then
		if not self.skip_orient then
			ent:SetPos(pos)
			ent:SetAngles(ang)
		else
			self.cached_pos = pos
			self.cached_ang = ang
		end
	end

	if self.Alpha ~= 0 and self.Size ~= 0 then
		self:ModifiersPreEvent("OnDraw")

		local r, g, b = self.Color.r, self.Color.g, self.Color.b

		-- render.SetColorModulation and render.SetAlpha set the material $color and $alpha.
		render_SetColorModulation(r,g,b)
		render_SetBlend(self.Alpha)
	end
end

function PART:PostEntityDraw(owner, ent, pos, ang)
	if self.Alpha ~= 0 and self.Size ~= 0 then
		self:ModifiersPostEvent("OnDraw")
	end
end

function PART:OnDraw(owner, pos, ang)
	local ent = self:GetEntity()

	if not ent:IsValid() then
		self:Reset()
		ent = self:GetEntity()
	end

	if self.loading then
		self:DrawLoadingText(ent, pos, ang)
		return
	end

	self:PreEntityDraw(owner, ent, pos, ang)
		self:DrawModel(ent, pos, ang)
	self:PostEntityDraw(owner, ent, pos, ang)

	pac.ResetBones(ent)
end

function PART:DrawModel(ent, pos, ang)
	if self.Alpha ~= 0 and self.Size ~= 0 then
		if self.material_override then
			if self.material_override[0] and self.material_override[0][1] then
				render_MaterialOverride(self.material_override[0][1]:GetRawMaterial())
			end

			for i = 1, #ent:GetMaterials() do
				local stack = self.material_override[i]
				if stack then
					local mat = stack[1]

					if mat then
						render.MaterialOverrideByIndex(i-1, mat:GetRawMaterial())
					else
						render.MaterialOverrideByIndex(i-1, nil)
					end
				end
			end
		end

		ent:DrawModel()
	end
end

function PART:DrawLoadingText(ent, pos, ang)
	cam.Start2D()
	cam.IgnoreZ(true)
		local pos2d = pos:ToScreen()

		surface.SetFont("DermaDefault")
		surface.SetTextColor(255, 255, 255, 255)

		local str = self.loading .. string.rep(".", pac.RealTime * 3 % 3)
		local w, h = surface.GetTextSize(self.loading .. "...")

		surface.SetTextPos(pos2d.x - w / 2, pos2d.y - h / 2)
		surface.DrawText(str)
	cam.IgnoreZ(false)
	cam.End2D()
end

function PART:SetModel(path)
	self.Model = path
	self.Entity = self:GetEntity()

	if path:find("^.-://") then
		self.loading = "downloading mdl zip"

		pac.DownloadMDL(path, function(path)
			self.loading = nil
			self.Entity.pac_bones = nil
			self.Entity:SetModel(path)
		end, function(err)
			pac.Message(err)
			self.loading = nil
			self.Entity.pac_bones = nil
			self.Entity:SetModel("error.mdl")
		end, self:GetPlayerOwner())
	else
		self.Entity.pac_bones = nil
		self.Entity:SetModel(path)
	end
end

local NORMAL = Vector(1,1,1)

function PART:CheckScale()
	-- RenderMultiply doesn't work with this..
	if self.BoneMerge and self.Entity:IsValid() and self.Entity:GetBoneCount() and self.Entity:GetBoneCount() > 1 then
		if self.Scale * self.Size ~= NORMAL then
			if not self.requires_bone_model_scale then
				self.requires_bone_model_scale = true
			end
			return true
		end

		self.requires_bone_model_scale = false
	end
end

function PART:SetAlternativeScaling(b)
	self.AlternativeScaling = b
	self:SetScale(self.Scale)
end

function PART:SetScale(var)
	var = var or Vector(1,1,1)

	self.Scale = var

	if not self:CheckScale() then
		pac.SetModelScale(self.Entity, self.Scale * self.Size, nil)
	end
end

function PART:SetSize(var)
	var = var or 1

	self.Size = var

	if not self:CheckScale() then
		pac.SetModelScale(self.Entity, self.Scale * self.Size, nil)
	end
end

function PART:CheckBoneMerge()
	local ent = self.Entity

	if self.skip_orient then return end

	if ent:IsValid() and not ent:IsPlayer() then
		if self.BoneMerge then
			local owner = self:GetOwner()

			if owner.pac_owner_override and owner.pac_owner_override:IsValid() then
				owner = owner.pac_owner_override
			end

			if ent:GetParent() ~= owner then
				ent:SetParent(owner)

				if not ent:IsEffectActive(EF_BONEMERGE) then
					ent:AddEffects(EF_BONEMERGE)
				end
			end
		else
			if ent:GetParent():IsValid() then
				ent:SetParent(NULL)

				if ent:IsEffectActive(EF_BONEMERGE) then
					ent:RemoveEffects(EF_BONEMERGE)
				end

				self.requires_bone_model_scale = false
			end
		end
	end
end

local SCALE_NORMAL = Vector(1, 1, 1)
function PART:OnBuildBonePositions()
	if self.AlternativeScaling then return end

	local ent = self:GetEntity()
	local owner = self:GetOwner()

	if not ent:IsValid() or not owner:IsValid() or not ent:GetBoneCount() or ent:GetBoneCount() < 1 then return end

	if self.requires_bone_model_scale then
		local scale = self.Scale * self.Size

		for i = 0, ent:GetBoneCount() - 1 do
			if i == 0 then
				ent:ManipulateBoneScale(i, ent:GetManipulateBoneScale(i) * Vector(scale.x ^ 0.25, scale.y ^ 0.25, scale.z ^ 0.25))
			else
				ent:ManipulateBonePosition(i, ent:GetManipulateBonePosition(i) + Vector((scale.x-1) ^ 4, 0, 0))
				ent:ManipulateBoneScale(i, ent:GetManipulateBoneScale(i) * scale)
			end
		end
	end
end

pac.RegisterPart(PART)
