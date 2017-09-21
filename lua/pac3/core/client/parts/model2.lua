local pac = pac

local render_SetColorModulation = render.SetColorModulation
local render_SetBlend = render.SetBlend
local render_CullMode = render.CullMode
local MATERIAL_CULLMODE_CW = MATERIAL_CULLMODE_CW
local MATERIAL_CULLMODE_CCW = MATERIAL_CULLMODE_CCW
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
		pac.GetSet(PART, "NoLighting", false)
		pac.GetSet(PART, "NoCulling", false)
		pac.GetSet(PART, "Invert", false)
		pac.GetSet(PART, "Alpha", 1, {editor_sensitivity = 0.25, editor_clamp = {0, 1}})
		pac.GetSet(PART, "ModelModifiers", "", {editor_panel = "model_modifiers"})
		pac.GetSet(PART, "Material", "", {editor_panel = "material"})
		pac.GetSet(PART, "Materials", "", {editor_panel = "model_materials"})
		--pac.GetSet(PART, "LightMap", "", {editor_panel = "textures"})
		pac.GetSet(PART, "LevelOfDetail", 0, {editor_clamp = {-1, 8}, editor_round = true})

		pac.SetupPartName(PART, "EyeTarget")

pac.EndStorableVars()

function PART:GetNiceName()
	local str = pac.PrettifyName(("/" .. self:GetModel()):match(".+/(.-)%."))

	return str and str:gsub("%d", "") or "error"
end

local temp = CreateMaterial(tostring({}), "VertexLitGeneric", {})

function PART:SetLevelOfDetail(val)
	self.LevelOfDetail = val
	local ent = self:GetEntity()
	if ent:IsValid() then
		ent:SetLOD(val)
	end
end

function PART:SetLightMap(val)
	self.LightMap = val

	if val == "" then
		self.lightmap_tex = nil
	else
		if not pac.resource.DownloadTexture(val, function(tex)
			self.lightmap_tex = tex
		end, self:GetPlayerOwner()) then
			temp:SetTexture("$basetexture", val)
			self.lightmap_tex = temp:GetTexture("$basetexture")
		end
	end
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

	if not self.Entity:IsValid() then return end

	local tbl = self:ModelModifiersToTable(str)

	if tbl.skin then
		self.Entity:SetSkin(tbl.skin)
		tbl.skin = nil
	end

	if not self.Entity:GetBodyGroups() then return end

	self.draw_bodygroups = {}

	for i, info in ipairs(self.Entity:GetBodyGroups()) do
		local val = tbl[info.name:lower()]
		if val then
			table.insert(self.draw_bodygroups, {info.id, val})
		end
	end
end

function PART:SetMaterial(str)
	self.Material = str

	if str == "" then
		if self.material_override_self then
			self.material_override_self[0] = nil
		end
	else
		self.material_override_self = self.material_override_self or {}
		self.material_override_self[0] = pac.Material(str, self)
	end

	if self.material_override_self and not next(self.material_override_self) then
		self.material_override_self = nil
	end
end

function PART:SetMaterials(str)
	self.Materials = str

	local materials = self:GetEntity():GetMaterials()

	if not materials then return end

	self.material_override_self = self.material_override_self or {}

	local tbl = str:Split(";")

	for i = 1, #materials do
		local path = tbl[i]
		if path and path ~= "" then
			self.material_override_self[i] = pac.Material(path, self)
		else
			self.material_override_self[i] = nil
		end
	end

	if not next(self.material_override_self) then
		self.material_override_self = nil
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

		if self.NoLighting then
			render.SuppressEngineLighting(true)
		end

		if self.NoCulling or self.Invert then
			render_CullMode(MATERIAL_CULLMODE_CW)
		end
	end

	if self.draw_bodygroups then
		for _, v in ipairs(self.draw_bodygroups) do
			ent:SetBodygroup(v[1], v[2])
		end
	end
end

function PART:PostEntityDraw(owner, ent, pos, ang)
	if self.Alpha ~= 0 and self.Size ~= 0 then
		self:ModifiersPostEvent("OnDraw")

		if self.NoLighting then
			render.SuppressEngineLighting(false)
		end

		if self.NoCulling then
			render_CullMode(MATERIAL_CULLMODE_CCW)
			self:DrawModel(ent, pos, ang)
		elseif self.Invert then
			render_CullMode(MATERIAL_CULLMODE_CCW)
		end
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
		local materials = self.material_override_self or self.material_override
		local set_material = false

		if self.material_override_self then
			if materials[0] then
				render_MaterialOverride(materials[0])
				set_material = true
			end

			for i = 1, #ent:GetMaterials() do
				local mat = materials[i]

				if mat then
					render.MaterialOverrideByIndex(i-1, mat)
				else
					render.MaterialOverrideByIndex(i-1, nil)
				end
			end
		elseif self.material_override then
			if materials[0] and materials[0][1] then
				render_MaterialOverride(materials[0][1]:GetRawMaterial())
				set_material = true
			end

			for i = 1, #ent:GetMaterials() do
				local stack = materials[i]
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

		if pac.render_material and not set_material then
			render_MaterialOverride()
		end

		if self.EyeTarget.cached_pos then
			if self.ClassName == "model2" then
				local attachment = ent:GetAttachment( ent:LookupAttachment( "eyes" ) )
				ent:SetEyeTarget(WorldToLocal( self.EyeTarget.cached_pos, self.EyeTarget.cached_ang, attachment.Pos, attachment.Ang ))
			else
				ent:SetEyeTarget(self.EyeTarget.cached_pos)
			end
		end

		--if self.lightmap_tex then render.SetLightmapTexture(self.lightmap_tex) end

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

local ALLOW_TO_MDL = CreateConVar('pac_allow_mdl', '1', {FCVAR_ARCHIVE, FCVAR_REPLICATED}, 'Allow to use custom MDLs')

function PART:RealSetModel(path)
	self.Entity.pac_bones = nil
	self.Entity:SetModel(path)
	self:SetModelModifiers(self:GetModelModifiers())
	self:SetMaterials("")
end

function PART:SetModel(path)
	self.Model = path
	self.Entity = self:GetEntity()

	if path:find("^.-://") then
		local status, reason = hook.Run('PAC3AllowMDLDownload', self:GetPlayerOwner(), self, path)

		if ALLOW_TO_MDL:GetBool() and status ~= false then
			self.loading = "downloading mdl zip"

			pac.DownloadMDL(path, function(path)
				self.loading = nil
				self:RealSetModel(path)
			end, function(err)
				pac.Message(err)
				self.loading = nil
				self:RealSetModel("error.mdl")
			end, self:GetPlayerOwner())
		else
			self.loading = reason or "mdl is not allowed"
			self.Entity:SetModel("error.mdl")
			pac.Message(self, ' mdl files are not allowed')
		end
	else
		self:RealSetModel(path)
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

	if ent:IsValid() and not ent:IsPlayer() and ent:GetModel() then
		if self.BoneMerge then
			if not self.ragdoll then
				self.Entity = ClientsideRagdoll(ent:GetModel())
				self.requires_bone_model_scale = true
				ent = self.Entity
				self.ragdoll = true
			end

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
			if self.ragdoll then
				self.Entity:Remove()
				ent = self:GetEntity()
				self.requires_bone_model_scale = true
				self.ragdoll = false
			end

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


local PART = {}

PART.ClassName = "entity2"
PART.Base = "model2"
PART.Category = "model"
PART.ManualDraw = true
PART.HandleModifiersManually = true
PART.Icon = 'icon16/shape_square.png'
PART.Group = 'pac4'
PART.is_model_part = false

pac.StartStorableVars()
	pac.GetSet(PART, "NoDraw", false)
pac.EndStorableVars()

pac.RemoveProperty(PART, "BoneMerge")
pac.RemoveProperty(PART, "Bone")
pac.RemoveProperty(PART, "Position")
pac.RemoveProperty(PART, "Angles")
pac.RemoveProperty(PART, "PositionOffset")
pac.RemoveProperty(PART, "AngleOffset")
pac.RemoveProperty(PART, "EyeAngles")
pac.RemoveProperty(PART, "AimPartName")

function PART:Initialize() end
function PART:OnDraw(ent, pos, ang)
	self:PreEntityDraw(ent, ent, pos, ang)
		self:DrawModel(ent, pos, ang)
	self:PostEntityDraw(ent, ent, pos, ang)
	pac.ResetBones(ent)
end

	local temp_mat = Material( "models/error/new light1" )

function PART:OnShow()
	local ent = self:GetOwner()
	self.Entity = ent

	self.Model = ent:GetModel() or ""

	if ent:IsValid() then
		function ent.RenderOverride()
			if self:IsValid() then
				-- so eyes work
				if self.NoDraw then
					render.SetBlend(0)
					render.ModelMaterialOverride(temp_mat)
					ent:DrawModel()
					render.SetBlend(1)
					render.ModelMaterialOverride()
					return
				end
				self:Draw(ent:GetPos(), ent:GetAngles(), self.Translucent and "translucent" or "opaque")
			else
				ent.RenderOverride = nil
			end
		end

	end
end

function PART:OnHide()
	local ent = self:GetOwner()

	if ent:IsValid() then
		ent.RenderOverride = nil
	end
end

function PART:RealSetModel(path)
	local ent = self:GetEntity()
	if not ent:IsValid() then return end
	if ent == pac.LocalPlayer and pacx and pacx.SetModel then
		pacx.SetModel(path)
	else
		ent:SetModel(path)
	end
end

pac.RegisterPart(PART)


local PART = {}

PART.ClassName = "weapon"
PART.Base = "model2"
PART.Category = "model"
PART.ManualDraw = true
PART.HandleModifiersManually = true
PART.Icon = 'icon16/shape_square.png'
PART.Group = 'pac4'
PART.is_model_part = false

function PART:Initialize()
	self.Entity = NULL
end
function PART:OnDraw(ent, pos, ang)
	local ent = self:GetEntity()
	self:PreEntityDraw(ent, ent, pos, ang)
		self:DrawModel(ent, pos, ang)
	self:PostEntityDraw(ent, ent, pos, ang)
	pac.ResetBones(ent)
end

function PART:OnThink()
	self:OnShow()
end

function PART:OnShow()
	local ent = self:GetOwner(true)
	if ent:IsValid() and ent.GetActiveWeapon then
		local wep = ent:GetActiveWeapon()
		if wep:IsValid() and wep ~= self.Entity then
			self.Entity = wep
			wep:SetNoDraw(true)
		end
	end
end

function PART:OnHide()
	local ent = self.Entity

	if ent:IsValid() then
		ent:SetNoDraw(false)
	end
end

function PART:RealSetModel(path)
	local ent = self:GetEntity()
	if ent:IsValid() then
		ent:SetModel(path)
	end
end

pac.RegisterPart(PART)