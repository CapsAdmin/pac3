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

PART.FriendlyName = "model"
PART.ClassName = "model2"
PART.Category = "model"
PART.ManualDraw = true
PART.HandleModifiersManually = true
PART.Icon = 'icon16/shape_square.png'
PART.Group = "experimental"
PART.is_model_part = true

pac.StartStorableVars()

	pac.SetPropertyGroup(PART, "generic")
		pac.GetSet(PART, "Model", "", {editor_panel = "model"})

	pac.SetPropertyGroup(PART, "orientation")
		pac.GetSet(PART, "Size", 1, {editor_sensitivity = 0.25})
		pac.GetSet(PART, "Scale", Vector(1,1,1))
		pac.GetSet(PART, "BoneMerge", false)

	pac.SetPropertyGroup(PART, "appearance")
		pac.GetSet(PART, "Color", Vector(1, 1, 1), {editor_panel = "color2"})
		pac.GetSet(PART, "NoLighting", false)
		pac.GetSet(PART, "NoCulling", false)
		pac.GetSet(PART, "Invert", false)
		pac.GetSet(PART, "Alpha", 1, {editor_sensitivity = 0.25, editor_clamp = {0, 1}})
		pac.GetSet(PART, "ModelModifiers", "", {editor_panel = "model_modifiers"})
		pac.GetSet(PART, "Material", "", {editor_panel = "material"})
		pac.GetSet(PART, "Materials", "", {editor_panel = "model_materials"})
		pac.GetSet(PART, "LevelOfDetail", 0, {editor_clamp = {-1, 8}, editor_round = true})

		pac.SetupPartName(PART, "EyeTarget")

pac.EndStorableVars()

PART.Entity = NULL

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
		local val = tbl[info.name]
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

		if not pac.Handleurltex(self, str, function(mat)
			self.material_override_self = self.material_override_self or {}
			self.material_override_self[0] = mat
		end) then
			self.material_override_self[0] = pac.Material(str, self)
		end
	end

	if self.material_override_self and not next(self.material_override_self) then
		self.material_override_self = nil
	end
end

function PART:SetMaterials(str)
	self.Materials = str

	local materials = self:GetEntity():IsValid() and self:GetEntity():GetMaterials()

	if not materials then return end

	self.material_count = #materials

	self.material_override_self = self.material_override_self or {}

	local tbl = str:Split(";")

	for i = 1, #materials do
		local path = tbl[i]

		if path and path ~= "" then
			if not pac.Handleurltex(self, path, function(mat)
				self.material_override_self = self.material_override_self or {}
				self.material_override_self[i] = mat
			end) then
				self.material_override_self[i] = pac.Material(path, self)
			end
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

function PART:OnEvent(typ)
	if typ == "become_physics" then
		local ent = self:GetEntity()
		if ent:IsValid() then
			ent:PhysicsInit(SOLID_NONE)
			ent:SetMoveType(MOVETYPE_NONE)
			ent:SetNoDraw(true)
			ent.RenderOverride = nil

			self.skip_orient = false
		end
	end
end

function PART:Initialize()
	self.Entity = pac.CreateEntity(self:GetModel())
	self.Entity:SetNoDraw(true)
	self.Entity.PACPart = self
	self.material_count = 0
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

function PART:BindMaterials(ent)
	local materials = self.material_override_self or self.material_override
	local set_material = false

	if self.material_override_self then
		if materials[0] then
			render_MaterialOverride(materials[0])
			set_material = true
		end

		for i = 1, self.material_count do
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

		for i = 1, self.material_count do
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

	if (pac.render_material or self.BoneMerge) and not set_material then
		render_MaterialOverride()
	end
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
	end

	if self.draw_bodygroups then
		for _, v in ipairs(self.draw_bodygroups) do
			ent:SetBodygroup(v[1], v[2])
		end
	end

	if self.EyeTarget.cached_pos then
		if self.ClassName == "model2" then
			local attachment = ent:GetAttachment( ent:LookupAttachment( "eyes" ) )
			if attachment then
				ent:SetEyeTarget(WorldToLocal( self.EyeTarget.cached_pos, self.EyeTarget.cached_ang, attachment.Pos, attachment.Ang ))
			end
		else
			ent:SetEyeTarget(self.EyeTarget.cached_pos)
		end
	end
end

function PART:PostEntityDraw(owner, ent, pos, ang)
	if self.Alpha ~= 0 and self.Size ~= 0 then
		self:ModifiersPostEvent("OnDraw")

		if self.NoLighting then
			render.SuppressEngineLighting(false)
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
	if self.Alpha == 0 or self.Size == 0 then return end

	if self.NoCulling or self.Invert then
		render_CullMode(MATERIAL_CULLMODE_CW)
	end

	self:BindMaterials(ent)

	ent.pac_drawing_model = true
	ent:DrawModel()
	ent.pac_drawing_model = false

	if pac.projected_texture_enabled and not pac.flashlight_disabled then
		render.PushFlashlightMode(true)

		self:BindMaterials(ent)
		ent.pac_drawing_model = true
		ent:DrawModel()
		ent.pac_drawing_model = false

		render.PopFlashlightMode()
	end

	if self.NoCulling then
		render_CullMode(MATERIAL_CULLMODE_CCW)
		self:BindMaterials(ent)
		ent:DrawModel()
	elseif self.Invert then
		render_CullMode(MATERIAL_CULLMODE_CCW)
	end
end

function PART:DrawLoadingText(ent, pos, ang)
	cam.Start2D()
	cam.IgnoreZ(true)
		local pos2d = pos:ToScreen()

		surface.SetFont("DermaDefault")
		if self.errored then
			surface.SetTextColor(255, 0, 0, 255)
		else
			surface.SetTextColor(255, 255, 255, 255)
		end

		local str = self.loading .. string.rep(".", pac.RealTime * 3 % 3)
		local w, h = surface.GetTextSize(self.loading .. "...")

		surface.SetTextPos(pos2d.x - w / 2, pos2d.y - h / 2)
		surface.DrawText(str)
	cam.IgnoreZ(false)
	cam.End2D()
end

local ALLOW_TO_MDL = CreateConVar('pac_allow_mdl', '1', CLIENT and {FCVAR_REPLICATED} or {FCVAR_ARCHIVE, FCVAR_REPLICATED}, 'Allow to use custom MDLs')

function PART:RefreshModel()
	self.Entity.pac_bones = nil
	self:SetModelModifiers(self:GetModelModifiers())
	self:SetMaterials(self:GetMaterials())
	self:SetSize(self:GetSize())
	self:SetScale(self:GetScale())
end

function PART:RealSetModel(path)
	self.Entity:SetModel(path)
	self:RefreshModel()
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
				self.errored = nil
				self:RealSetModel(path)

				if self:GetEntity() == pac.LocalPlayer and pacx and pacx.SetModel then
					pacx.SetModel(self.Model)
				end

			end, function(err)
				pac.Message(err)
				self.loading = err
				self.errored = true
				self:RealSetModel("models/error.mdl")
			end, self:GetPlayerOwner())
		else
			self.loading = reason or "mdl is not allowed"
			self:RealSetModel("models/error.mdl")
			pac.Message(self, ' mdl files are not allowed')
		end
	else
		if self:GetEntity() == pac.LocalPlayer and pacx and pacx.SetModel then
			pacx.SetModel(self.Model)
		end

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
		self:ApplyMatrix()
	end
end

function PART:ApplyMatrix()
	local ent = self:GetEntity()
	if not ent:IsValid() then return end
	local mat = Matrix()
	if self.ClassName ~= "model2" then
		mat:Translate(self.Position + self.PositionOffset)
		mat:Rotate(self.Angles + self.AngleOffset)
	end
	mat:Scale(self.Scale * self.Size)
	if mat:IsIdentity() then
		ent:DisableMatrix("RenderMultiply")
	else
		ent:EnableMatrix("RenderMultiply", mat)
	end
end

function PART:SetSize(var)
	var = var or 1

	self.Size = var

	if not self:CheckScale() then
		self:ApplyMatrix()
	end
end

function PART:CheckBoneMerge()
	local ent = self.Entity

	if self.skip_orient then return end

	if ent:IsValid() and not ent:IsPlayer() and ent:GetModel() then
		if self.BoneMerge then
			--[[if not self.ragdoll then
				self.Entity = ClientsideRagdoll(ent:GetModel())
				self.requires_bone_model_scale = true
				ent = self.Entity
				self.ragdoll = true
			end]]

			local owner = self:GetOwner()

			if owner.pac_owner_override and owner.pac_owner_override:IsValid() then
				owner = owner.pac_owner_override
			end

			if ent:GetParent() ~= owner then
				ent:SetParent(owner)

				if not ent:IsEffectActive(EF_BONEMERGE) then
					ent:AddEffects(EF_BONEMERGE)
					owner.pac_bonemerged = owner.pac_bonemerged or {}
					table.insert(owner.pac_bonemerged, ent)
					ent.RenderOverride = function()
						ent.pac_drawing_model = true
						ent:DrawModel()
						ent.pac_drawing_model = false
					end
				end
			end
		else
			--[[if self.ragdoll then
				self.Entity:Remove()
				ent = self:GetEntity()
				self.requires_bone_model_scale = true
				self.ragdoll = false
			end]]

			if ent:GetParent():IsValid() then
				local owner = ent:GetParent()
				ent:SetParent(NULL)

				if ent:IsEffectActive(EF_BONEMERGE) then
					ent:RemoveEffects(EF_BONEMERGE)
					ent.RenderOverride = nil

					if owner:IsValid() then
						owner.pac_bonemerged = owner.pac_bonemerged or {}
						for i, v in ipairs(owner.pac_bonemerged) do
							if v == ent then
								table.remove(owner.pac_bonemerged, i)
								break
							end
						end
					end
				end

				self.requires_bone_model_scale = false
			end
		end
	end
end

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

do
	local PART = {}

	PART.FriendlyName = "entity"
	PART.ClassName = "entity2"
	PART.Base = "model2"
	PART.Category = "model"
	PART.ManualDraw = true
	PART.HandleModifiersManually = true
	PART.Icon = 'icon16/shape_square.png'
	PART.Group = "experimental"
	PART.is_model_part = false

	pac.StartStorableVars()
		pac.GetSet(PART, "NoDraw", false)
	pac.EndStorableVars()

	pac.RemoveProperty(PART, "BoneMerge")
	pac.RemoveProperty(PART, "Bone")
	--pac.RemoveProperty(PART, "Position")
	--pac.RemoveProperty(PART, "Angles")
	--pac.RemoveProperty(PART, "PositionOffset")
	--pac.RemoveProperty(PART, "AngleOffset")
	pac.RemoveProperty(PART, "EyeAngles")
	pac.RemoveProperty(PART, "AimPartName")

	function PART:GetNiceName()
		local str = pac.PrettifyName(("/" .. self:GetModel()):match(".+/(.-)%."))

		local what = self:GetEntity():GetClass()

		return (str and str:gsub("%d", "") or "error") .. " " .. what .. " model"
	end


	function PART:SetPosition(pos)
		self.Position = pos
		self:ApplyMatrix()
	end

	function PART:SetAngles(ang)
		self.Angles = ang
		self:ApplyMatrix()
	end

	function PART:SetPositionOffset(pos)
		self.PositionOffset = pos
		self:ApplyMatrix()
	end

	function PART:SetAngleOffset(ang)
		self.AngleOffset = ang
		self:ApplyMatrix()
	end

	function PART:GetBonePosition()
		local ent = self:GetOwner()
		local ang = ent:GetAngles()
		if ent:IsPlayer() then
			ang.p = 0
		end
		return ent:GetPos(), ang
	end

	function PART:Initialize()
		self.material_count = 0
	end

	function PART:OnDraw(ent, pos, ang)
		self:PreEntityDraw(ent, ent, pos, ang)
			self:DrawModel(ent, pos, ang)
		self:PostEntityDraw(ent, ent, pos, ang)
	end

	function PART:GetEntity()
		local ent = self:GetOwner()
		self.Entity = ent
		return ent
	end

	local temp_mat = Material( "models/error/new light1" )

	function PART:OnShow()
		local ent = self:GetEntity()

		if self.Model == "" then
			self.Model = ent:GetModel() or ""
		end

		if ent:IsValid() then
			function ent.RenderOverride()
				-- if the draw call is not from pac don't bother
				if not ent.pac_drawing_model then
					return
				end

				if self:IsValid() and self:GetOwner():IsValid() then
					if ent.pac_bonemerged then
						for _, e in ipairs(ent.pac_bonemerged) do
							if e.pac_drawing_model then return end
						end
					end

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
			self:ApplyMatrix()
		end
	end

	function PART:OnHide()
		local ent = self:GetOwner()

		if ent:IsValid() then
			ent.RenderOverride = nil
			ent:DisableMatrix("RenderMultiply")
		end
	end

	function PART:RealSetModel(path)
		local ent = self:GetEntity()
		if not ent:IsValid() then return end

		ent:SetModel(path)

		self:RefreshModel()
	end

	function PART:OnRemove()
		local ent = self:GetEntity()
		if not ent:IsValid() then return end

		if ent == pac.LocalPlayer and pacx and pacx.SetModel then
			pacx.SetModel()
		end
	end

	function PART:OnThink()
		self:CheckBoneMerge()

		local ent = self:GetEntity()

		if ent:IsValid() then
			local old = ent:GetModel()
			if self.last_model ~= old then
				self:RefreshModel()
				self.last_model = old
			end
		end
	end

	pac.RegisterPart(PART)
end

do
	local PART = {}

	PART.ClassName = "weapon"
	PART.Base = "model2"
	PART.Category = "model"
	PART.ManualDraw = true
	PART.HandleModifiersManually = true
	PART.Icon = 'icon16/shape_square.png'
	PART.Group = "experimental"
	PART.is_model_part = false

	pac.StartStorableVars()
		pac.SetPropertyGroup(PART, "generic")
			pac.GetSet(PART, "OverridePosition", false)
			pac.GetSet(PART, "NoDraw", false)
			pac.GetSet(PART, "Class", "all", {enums = function()
				local out = {
					["physgun"] = "weapon_physgun",
					["357"] = "weapon_357",
					["alyxgun"] = "weapon_alyxgun",
					["annabelle"] = "weapon_annabelle",
					["ar2"] = "weapon_ar2",
					["brickbat"] = "weapon_brickbat",
					["bugbait"] = "weapon_bugbait",
					["crossbow"] = "weapon_crossbow",
					["crowbar"] = "weapon_crowbar",
					["frag"] = "weapon_frag",
					["physcannon"] = "weapon_physcannon",
					["pistol"] = "weapon_pistol",
					["rpg"] = "weapon_rpg",
					["shotgun"] = "weapon_shotgun",
					["smg1"] = "weapon_smg1",
					["striderbuster"] = "weapon_striderbuster",
					["stunstick"] = "weapon_stunstick",
				}
				for _, tbl in pairs(weapons.GetList()) do
					if not tbl.ClassName:StartWith("ai_") then
						local friendly = tbl.ClassName:match("weapon_(.+)") or tbl.ClassName
						out[friendly] = tbl.ClassName
					end
				end
				return out
			end})
	pac.EndStorableVars()

	pac.RemoveProperty(PART, "Model")

	function PART:GetNiceName()
		if self.Class ~= "all" then
			return self.Class
		end
		return self.ClassName
	end

	function PART:Initialize()
		self.material_count = 0
	end
	function PART:OnDraw(ent, pos, ang)
		local ent = self:GetEntity()
		if not ent:IsValid() then return end

		local old
		if self.OverridePosition then
			old = ent:GetParent()
			ent:SetParent(NULL)
			ent:SetRenderOrigin(pos)
			ent:SetRenderAngles(ang)
			ent:SetupBones()
		end
		ent.pac_render = true

		self:PreEntityDraw(ent, ent, pos, ang)
			self:DrawModel(ent, pos, ang)
		self:PostEntityDraw(ent, ent, pos, ang)
		pac.ResetBones(ent)

		if self.OverridePosition then
			ent:MarkShadowAsDirty()
			--ent:SetParent(old)
		end
		ent.pac_render = nil
	end

	PART.AlwaysThink = true

	function PART:OnThink()
		local ent = self:GetOwner(true)
		if ent:IsValid() and ent.GetActiveWeapon then
			local wep = ent:GetActiveWeapon()
			if wep:IsValid() then
				if wep ~= self.Entity then
					if self.Class == "all" or (self.Class:lower() == wep:GetClass():lower()) then
						self:OnHide()
						self.Entity = wep
						self:SetEventHide(false)
						wep.RenderOverride = function()
							wep:DrawShadow(false)
							if wep.pac_render then
								if not self.NoDraw then
									wep:DrawModel()
								end
							end
						end
						wep.pac_weapon_part = self
					else
						self:SetEventHide(true)
						self:OnHide()
					end
				end
			end
		end
	end

	function PART:OnHide()
		local ent = self:GetOwner(true)

		if ent:IsValid() and ent.GetActiveWeapon then
			for k,v in pairs(ent:GetWeapons()) do
				if v.pac_weapon_part == self then
					v.RenderOverride = nil
					v:DrawShadow(true)
					v:SetParent(ent)
				end
			end
			self.Entity = NULL
		end
	end

	pac.RegisterPart(PART)
end