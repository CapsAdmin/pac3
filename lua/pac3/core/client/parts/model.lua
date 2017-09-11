local pac = pac

local math_max                      = math.max
local math_min                      = math.min
local table_insert                  = table.insert
local table_remove                  = table.remove

local Matrix                        = Matrix
local Vector                        = Vector

local cam_PushModelMatrix           = cam.PushModelMatrix
local cam_PopModelMatrix            = cam.PopModelMatrix

local render                        = render
local render_CullMode               = render.CullMode
local render_SetColorModulation     = render.SetColorModulation
local render_SetBlend               = render.SetBlend
local render_SetMaterial            = render.SetMaterial
local render_ModelMaterialOverride  = render.MaterialOverride
local render_MaterialOverride       = render.ModelMaterialOverride
local render_PopFilterMag           = render.PopFilterMag
local render_PopFilterMin           = render.PopFilterMin
local render_PopFlashlightMode      = render.PopFlashlightMode
local render_PushFilterMag          = render.PushFilterMag
local render_PushFilterMin          = render.PushFilterMin
local render_PushFlashlightMode     = render.PushFlashlightMode
local render_SuppressEngineLighting = render.SuppressEngineLighting

local IMaterial_GetFloat            = FindMetaTable("IMaterial").GetFloat
local IMaterial_GetVector           = FindMetaTable("IMaterial").GetVector
local IMaterial_SetFloat            = FindMetaTable("IMaterial").SetFloat
local IMaterial_SetVector           = FindMetaTable("IMaterial").SetVector

local EF_BONEMERGE                  = EF_BONEMERGE

local MATERIAL_CULLMODE_CW          = MATERIAL_CULLMODE_CW
local MATERIAL_CULLMODE_CCW         = MATERIAL_CULLMODE_CCW

local TEXFILTER = TEXFILTER
local NULL = NULL
local Color = Color

pac.DisableColoring = false
pac.DisableDoubleFace = false

local PART = {}

PART.ClassName = "model"
PART.Category = "model"
PART.ManualDraw = true
PART.HandleModifiersManually = true
PART.Icon = 'icon16/shape_square.png'
PART.Group = 'model'

pac.StartStorableVars()

	pac.SetPropertyGroup("generic")
		pac.GetSet(PART, "Model", "models/dav0r/hoverball.mdl", {editor_panel = "model"})
		pac.GetSet(PART, "Material", "", {editor_panel = "material"})
		pac.GetSet(PART, "UseLegacyScale", false)

	pac.SetPropertyGroup("orientation")
		pac.GetSet(PART, "Size", 1, {editor_sensitivity = 0.25})
		pac.GetSet(PART, "Scale", Vector(1,1,1))
		pac.GetSet(PART, "BoneMerge", false)
		pac.GetSet(PART, "AlternativeScaling", false)

	pac.SetPropertyGroup("appearance")
		pac.GetSet(PART, "Color", Vector(255, 255, 255), {editor_panel = "color"})
		pac.GetSet(PART, "Brightness", 1)
		pac.GetSet(PART, "Alpha", 1, {editor_sensitivity = 0.25, editor_clamp = {0, 1}})
		pac.GetSet(PART, "Fullbright", false)
		pac.GetSet(PART, "CellShade", 0, {editor_sensitivity = 0.1})
		pac.GetSet(PART, "Invert", false)
		pac.GetSet(PART, "DoubleFace", false)
		pac.GetSet(PART, "Skin", 0, {editor_onchange = function(self, num) return math.Round(math.max(tonumber(num), 0)) end})
		pac.GetSet(PART, "Passes", 1)
		pac.GetSet(PART, "TintColor", Vector(0, 0, 0), {editor_panel = "color"})
		pac.GetSet(PART, "LightBlend", 1)
		pac.GetSet(PART, "ModelFallback", "", {editor_panel = "model"})
		pac.GetSet(PART, "TextureFilter", 3)
		pac.GetSet(PART, "BlurLength", 0)
		pac.GetSet(PART, "BlurSpacing", 0)
		pac.GetSet(PART, "UsePlayerColor", false)
		pac.GetSet(PART, "UseWeaponColor", false)
		pac.GetSet(PART, "LodOverride", -1)

	pac.SetPropertyGroup("other")
		pac.GetSet(PART, "OwnerEntity", false)

pac.EndStorableVars()

function PART:GetNiceName()
	local str = pac.PrettifyName(("/" .. self:GetModel()):match(".+/(.-)%."))

	return str and str:gsub("%d", "") or "error"
end

function PART:Reset()
	self:Initialize(self.is_obj)
	for _, key in pairs(self:GetStorableVars()) do
		if PART[key] then
			self["Set" .. key](self, self["Get" .. key](self))
		end
	end
end

function PART:SetUseLegacyScale(b)
	self.UseLegacyScale = b
	if not b then
		self.requires_bone_model_scale = false
	end
end

function PART:SetTextureFilter(num)
	self.TextureFilter = num

	self.texfilter_enum = math.Clamp(math.Round(num), 0, 3)
end

function PART:Initialize(is_obj)
	self.Entity = pac.CreateEntity(self:GetModel(), is_obj)
	if not self.Entity:IsValid() then
		pac.Message("Failed to create entity!")
	end
	self.Entity:SetNoDraw(true)
	self.Entity.PACPart = self
	self.is_obj = is_obj
end

function PART:GetEntity()
	return self.Entity or NULL
end

function PART:OnShow()
	local owner = self:GetOwner()
	local ent = self:GetEntity()

	if ent:IsValid() and owner:IsValid() and owner ~= ent then
		ent:SetPos(owner:EyePos())
		--ent:SetParent(owner)
		--ent:SetOwner(owner)
		self.BoneIndex = nil

		if self.OwnerEntity then
			self:SetOwnerEntity(self.OwnerEntity)
		end
	end

	if self.BlurLength > 0 then
		self.blur_history = {}
		self.blur_last_add = 0
	end
end

function PART:OnThink()
	pac.SetModelScale(self:GetEntity(), self.Scale * self.Size, nil, self.UseLegacyScale)

	self:CheckScale()
	self:CheckBoneMerge()

	local ent = self:GetEntity()
	if ent:IsValid() then
		ent.pac_matproxies = ent.pac_matproxies or {}
		ent.pac_matproxies.ItemTintColor = self.TintColor / 255
	end
end

function PART:SetOwnerEntity(b)
	local ent = self:GetOwner()
	if ent:IsValid() then
		if b then
			self.Entity = ent

			function ent.RenderOverride()
				if self:IsValid() then
					if not self.HideEntity then
						self:PreEntityDraw(ent, ent, ent:GetPos(), ent:GetAngles())
						ent:DrawModel()
						self:PostEntityDraw(ent, ent, ent:GetPos(), ent:GetAngles())
					end
				else
					ent.RenderOverride = nil
				end
			end
		elseif self.OwnerEntity then
			self.Entity = NULL

			ent.RenderOverride = nil
			pac.SetModelScale(ent, Vector(1,1,1), nil, self.UseLegacyScale)
		end
	end

	self.OwnerEntity = b
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

		if not pac.DisableDoubleFace and (self.DoubleFace or self.Invert) then
			render_CullMode(MATERIAL_CULLMODE_CW)
		end

		if not pac.DisableColoring then
			if not self.Colorf then
				self:SetColor(self:GetColor())
			end

			if self.UseWeaponColor or self.UsePlayerColor then
				local ply = self:GetPlayerOwner()
				if ply:IsValid() then
					local c

					c = ply:GetPlayerColor()
					if c ~= self.last_playercolor then
						self:SetColor(self:GetColor())
						self.last_playercolor = c
					end

					c = ply:GetWeaponColor()
					if c ~= self.last_weaponcolor then
						self:SetColor(self:GetColor())
						self.last_weaponcolor = c
					end
				end
			end

			-- Save existing material color and alpha
			if self.Materialm then
				-- this is so bad for GC performance
				self.OriginalMaterialColor = self.OriginalMaterialColor or IMaterial_GetVector (self.Materialm, "$color")
				self.OriginalMaterialAlpha = self.OriginalMaterialAlpha or IMaterial_GetFloat  (self.Materialm, "$alpha")
			end

			local r, g, b = self.Colorf.r, self.Colorf.g, self.Colorf.b

			if self.LightBlend ~= 1 then
				local v = render.GetLightColor(pos)
				r = r * v.r * self.LightBlend
				g = g * v.g * self.LightBlend
				b = b * v.b * self.LightBlend

				v = render.GetAmbientLightColor(pos)
				r = r * v.r * self.LightBlend
				g = g * v.g * self.LightBlend
				b = b * v.b * self.LightBlend
			end

			-- render.SetColorModulation and render.SetAlpha set the material $color and $alpha.
			render_SetColorModulation(r,g,b)
			render_SetBlend(self.Alpha)
		end

		if self.Fullbright then
			render_SuppressEngineLighting(true)
		end
	end
end

local DEFAULT_COLOR = Vector(1, 1, 1)
local WHITE = Material("models/debug/debugwhite")

function PART:PostEntityDraw(owner, ent, pos, ang)
	if self.Alpha ~= 0 and self.Size ~= 0 then
		if not pac.DisableDoubleFace then
			if self.DoubleFace then
				render_CullMode(MATERIAL_CULLMODE_CCW)
				self:DrawModel(ent, pos, ang)
			elseif self.Invert then
				render_CullMode(MATERIAL_CULLMODE_CCW)
			end
		end

		if self.Fullbright then
			render_SuppressEngineLighting(false)
		end

		if self.CellShade > 0 then
			self:CheckScale()
			self:CheckBoneMerge()

			pac.SetModelScale(ent, self.Scale * self.Size * (1 + self.CellShade), nil, self.UseLegacyScale)
				render_CullMode(MATERIAL_CULLMODE_CW)
					render_SetColorModulation(0,0,0)
						render_SuppressEngineLighting(true)
							render_MaterialOverride(WHITE)
								self:DrawModel(ent, pos, ang)
							render_MaterialOverride()
					render_SuppressEngineLighting(false)
				render_CullMode(MATERIAL_CULLMODE_CCW)
			pac.SetModelScale(ent, self.Scale * self.Size, nil, self.UseLegacyScale)
		end

		-- Restore material color and alpha
		if self.Materialm then
			IMaterial_SetVector (self.Materialm, "$color", self.OriginalMaterialColor or DEFAULT_COLOR)
			IMaterial_SetFloat  (self.Materialm, "$alpha", self.OriginalMaterialAlpha or 1)
			self.OriginalMaterialColor = nil
			self.OriginalMaterialAlpha = nil
		end

		self:ModifiersPostEvent("OnDraw")
	end
end

function PART:OnDraw(owner, pos, ang)
	local ent = self:GetEntity()

	if not ent:IsValid() then
		self:Reset()
		ent = self:GetEntity()
		if not ent:IsValid() then
			pac.Message("WTF", ent, self.Entity)
			return
		end
	end

	self:PreEntityDraw(owner, ent, pos, ang)
		self:DrawModel(ent, pos, ang)
	self:PostEntityDraw(owner, ent, pos, ang)

	pac.ResetBones(ent)

	if ent.pac_can_legacy_scale ~= false then
		ent.pac_can_legacy_scale = not not ent.pac_can_legacy_scale
	end
end

surface.CreateFont("pac_urlobj_loading",
	{
		font      = "Arial",
		size      = 20,
		weight    = 10,
		antialias = true,
		outline   = true,
	}
)

-- ugh lol
local function RealDrawModel(self, ent, pos, ang)
	if self.Mesh then
		ent:SetModelScale(0,0)
		ent:DrawModel()

		local matrix = Matrix()

		matrix:SetAngles(ang)
		matrix:SetTranslation(pos)

		if ent.pac_model_scale then
			matrix:Scale(ent.pac_model_scale)
		else
			matrix:Scale(self.Scale * self.Size)
		end

		cam_PushModelMatrix(matrix)
			self.Mesh:Draw()
		cam_PopModelMatrix()
	else
		ent:DrawModel()
	end
end

function PART:DrawModel(ent, pos, ang)
	if self.Alpha ~= 0 and self.Size ~= 0 then
		if self.loading_obj then
			self:DrawLoadingText(ent, pos, ang)
		end

		if self.loading_obj and not self.Mesh then return end

		local textureFilter = self.texfilter_enum or TEXFILTER.ANISOTROPIC
		if textureFilter ~= TEXFILTER.ANISOTROPIC or self.Mesh then
			render_PushFilterMin(textureFilter)
			render_PushFilterMag(textureFilter)
		end

		local mat = self.MaterialOverride or self.Materialm

		render_MaterialOverride(mat)
		render_ModelMaterialOverride(mat)
		if mat then
			render_SetMaterial(mat)
		end

		-- Render model
		local passCount = math_max (1, self.Passes)
		if self.Alpha >= 1 then
			passCount = math_min (passCount, 1)
		end

		for _ = 1, passCount do
			RealDrawModel(self, ent, pos, ang)
		end

		if pac.projected_texture_enabled and not pac.flashlight_disabled then
			render_PushFlashlightMode(true)
		end

		RealDrawModel(self, ent, pos, ang)

		if pac.projected_texture_enabled and not pac.flashlight_disabled then
			render_PopFlashlightMode()
		end

		if textureFilter ~= TEXFILTER.ANISOTROPIC or self.Mesh then
			render_PopFilterMag()
			render_PopFilterMin()
		end

		-- Render "blur"
		if self.BlurLength > 0 then
			self:DrawBlur(ent, pos, ang)
		end
	end
end

function PART:DrawLoadingText(ent, pos, ang)
	cam.Start2D()
	cam.IgnoreZ(true)
		local pos2d = pos:ToScreen()

		surface.SetFont("pac_urlobj_loading")
		surface.SetTextColor(255, 255, 255, 255)

		local str = self.loading_obj .. string.rep(".", pac.RealTime * 3 % 3)
		local w, h = surface.GetTextSize(self.loading_obj .. "...")

		surface.SetTextPos(pos2d.x - w / 2, pos2d.y - h / 2)
		surface.DrawText(str)
	cam.IgnoreZ(false)
	cam.End2D()
end

function PART:DrawBlur(ent, pos, ang)
	self.blur_history = self.blur_history or {}

	local blurSpacing = self.BlurSpacing

	if not self.blur_last_add or blurSpacing == 0 or self.blur_last_add < pac.RealTime then
		table_insert(self.blur_history, {pos, ang})
		self.blur_last_add = pac.RealTime + blurSpacing / 1000
	end

	local blurHistoryLength = #self.blur_history
	for i = 1, blurHistoryLength do
		pos, ang = self.blur_history[i][1], self.blur_history[i][2]

		render_SetBlend(self.Alpha * (i / blurHistoryLength))

		ent:SetPos(pos)
		ent:SetAngles(ang)
		ent:SetupBones()

		RealDrawModel(self, ent, pos, ang)
	end

	local maximumBlurHistoryLength = math.min(self.BlurLength, 20)
	while #self.blur_history >= maximumBlurHistoryLength do
		table_remove(self.blur_history, 1)
	end
end

local function set_mesh(part, mesh)
	part.Mesh = mesh
	part.Entity.pac_bones = nil

	if not part.Materialm then
		part.Materialm = Material("error")
	end

	function part.Entity.pacDrawModel(ent, simple)
		if simple then
			RealDrawModel(part, ent, ent:GetPos(), ent:GetAngles())
		else
			part:ModifiersPreEvent("OnDraw")
			part:DrawModel(ent, ent:GetPos(), ent:GetAngles())
			part:ModifiersPostEvent("OnDraw")
		end
	end

	-- temp
	part.Entity:SetRenderBounds(Vector(1, 1, 1) * -300, Vector(1, 1, 1) * 300)
end

function PART:SetModel(modelPath)
	self.Entity = self:GetEntity()

	if modelPath:find("^mdlhttp") then
		self.Model = modelPath

		modelPath = modelPath:gsub("^mdl", "")

		pac.DownloadMDL(modelPath, function(path)
			self.Entity.pac_bones = nil
			self.Entity:SetModel(path)
		end, pac.Message, self:GetPlayerOwner())

		return
	end

	if modelPath and modelPath:find("http") and pac.urlobj then
		self.loading_obj = "downloading"

		if not self.is_obj then
			self:Initialize(true)
		end

		pac.urlobj.GetObjFromURL(modelPath, false, false,
			function(meshes, err)
				if not self:IsValid() then return end

				self.loading_obj = false

				self.Entity = self:GetEntity()

				if not meshes and err then
					self.Entity:SetModel("error.mdl")
					self.Mesh = nil
					return
				end

				if table.Count(meshes) == 1 then
					set_mesh(self, select(2, next(meshes)))
				else
					for key, mesh in pairs(meshes) do
						local part = pac.CreatePart("model", self:GetOwnerName())
						part:SetName(key)
						part:SetParent(self)
						part:SetMaterial(self:GetMaterial())
						set_mesh(part, mesh)
					end

					self:SetAlpha(0)
				end
			end,
			function(finished, statusMessage)
				if finished then
					self.loading_obj = nil
				else
					self.loading_obj = statusMessage
				end
			end
		)

		self.Model = modelPath
		return
	end

	if self.is_obj or not self.Entity:IsValid() then
		self:Initialize(false)
	end

	self.Mesh = nil

	local real_model = modelPath
	local ret = hook.Run("pac_model:SetModel", self, modelPath, self.ModelFallback)
	if ret == nil then
		real_model = pac.FilterInvalidModel(real_model,self.ModelFallback)
	else
		modelPath = ret or modelPath
		real_model = modelPath
		real_model = pac.FilterInvalidModel(real_model,self.ModelFallback)
	end

	self.Model = modelPath
	self.Entity.pac_bones = nil
	self.Entity:SetModel(real_model)
end

local NORMAL = Vector(1,1,1)

function PART:CheckScale()
	-- RenderMultiply doesn't work with this..
	if (self.UseLegacyScale or self.BoneMerge) and self.Entity:IsValid() and self.Entity:GetBoneCount() and self.Entity:GetBoneCount() > 1 then
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

	if self.AlternativeScaling then
		if not self:CheckScale() then
			pac.SetModelScale(self.Entity, self.Scale, nil, self.UseLegacyScale)
			self.used_alt_scale = true
		end
	else
		if self.used_alt_scale then
			pac.SetModelScale(self.Entity, nil, 1, self.UseLegacyScale)
			self.used_alt_scale = false
		end
		if not self:CheckScale() then
			pac.SetModelScale(self.Entity, self.Scale * self.Size, nil, self.UseLegacyScale)
		end
	end
end

function PART:SetSize(var)
	var = var or 1

	self.Size = var

	if self.AlternativeScaling then
		pac.SetModelScale(self.Entity, nil, self.Size, self.UseLegacyScale)
		self.used_alt_scale = true
	else
		if self.used_alt_scale then
			pac.SetModelScale(self.Entity, nil, 1, self.UseLegacyScale)
			self.used_alt_scale = false
		end
		if not self:CheckScale() then
			pac.SetModelScale(self.Entity, self.Scale * self.Size, nil, self.UseLegacyScale)
		end
	end
end

function PART:SetBrightness(num)
	self.Brightness = num
	self:SetColor(self:GetColor())
end

function PART:SetColor(var)
	self.Color = var
	local owner = self:GetPlayerOwner()

	if self.UsePlayerColor and owner:IsValid() then
		local c = owner:GetPlayerColor() * self.Brightness
		self.Colorf = Color(c.r, c.g, c.b)
	elseif self.UseWeaponColor and owner:IsValid() then
		local c = owner:GetWeaponColor() * self.Brightness
		self.Colorf = Color(c.r, c.g, c.b)
	else
		self.Colorf = Color((var.r / 255) * self.Brightness, (var.g / 255) * self.Brightness, (var.b / 255) * self.Brightness)
	end
end

function PART:SetUseWeaponColor(b)
	self.UseWeaponColor = b
	self:SetColor(self:GetColor())
end

function PART:SetUsePlayerColor(b)
	self.UsePlayerColor = b
	self:SetColor(self:GetColor())
end

function PART:FixMaterial()
	local mat = self.Materialm

	if not mat then return end

	local shader = mat:GetShader()

	if shader == "UnlitGeneric" then
		local tex_path = mat:GetString("$basetexture")

		if tex_path then
			local params = {}

			params["$basetexture"] = tex_path
			params["$vertexcolor"] = 1
			params["$additive"] = 1

			self.Materialm = CreateMaterial(pac.uid"pac_fixmat_", "VertexLitGeneric", params)
		end
	end
end

function PART:SetMaterial(var)
	var = var or ""

	if not pac.Handleurltex(self, var) then
		if var == "" then
			self.Materialm = nil
		else
			self.Materialm = pac.Material(var, self)
			self:FixMaterial()
			self:CallEvent("material_changed")
		end
	end

	self.Material = var
end

function PART:SetSkin(var)
	var = var or 0

	self.Skin = var
	self.Entity:SetSkin(var)
end

function PART:OnRemove()
	if not self.OwnerEntity then
		timer.Simple(0, function()
			SafeRemoveEntity(self.Entity)
		end)
	end
end

function PART:SetLodOverride(num)
	local ent = self.Entity
	if ent:IsValid() then
		ent:SetLOD(num)
		self.LodOverride = num
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
