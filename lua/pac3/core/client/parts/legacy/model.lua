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

local BUILDER, PART = pac.PartTemplate("base_drawable")

PART.FriendlyName = "legacy model"
PART.ClassName = "model"
PART.Category = "model"
PART.ManualDraw = true
PART.HandleModifiersManually = true
PART.Icon = 'icon16/shape_square.png'
PART.Group = "legacy"
PART.ThinkTime = 0.5

PART.is_model_part = true

BUILDER:StartStorableVars()

	BUILDER:SetPropertyGroup("generic")
		BUILDER:PropertyOrder("Name")
		BUILDER:PropertyOrder("Hide")
		BUILDER:PropertyOrder("ParentName")
		BUILDER:GetSet("Model", "models/dav0r/hoverball.mdl", {editor_panel = "model"})
		BUILDER:GetSet("Material", "", {editor_panel = "material"})
		BUILDER:GetSet("UseLegacyScale", false)

	BUILDER:SetPropertyGroup("orientation")
		BUILDER:PropertyOrder("AimPartName")
		BUILDER:PropertyOrder("Bone")
		BUILDER:GetSet("BoneMerge", false)
		BUILDER:PropertyOrder("Position")
		BUILDER:PropertyOrder("Angles")
		BUILDER:PropertyOrder("EyeAngles")
		BUILDER:GetSet("Size", 1, {editor_sensitivity = 0.25})
		BUILDER:GetSet("Scale", Vector(1,1,1))
		BUILDER:PropertyOrder("PositionOffset")
		BUILDER:PropertyOrder("AngleOffset")
		BUILDER:GetSet("AlternativeScaling", false)

	BUILDER:SetPropertyGroup("appearance")
		BUILDER:GetSet("Color", Vector(255, 255, 255), {editor_panel = "color"})
		BUILDER:GetSet("Brightness", 1)
		BUILDER:GetSet("Alpha", 1, {editor_sensitivity = 0.25, editor_clamp = {0, 1}})
		BUILDER:GetSet("Fullbright", false)
		BUILDER:GetSet("CellShade", 0, {editor_sensitivity = 0.1})
		BUILDER:PropertyOrder("Translucent")
		BUILDER:GetSet("Invert", false)
		BUILDER:GetSet("DoubleFace", false)
		BUILDER:GetSet("Skin", 0, {editor_onchange = function(self, num) return math.Round(math.max(tonumber(num), 0)) end})
		BUILDER:GetSet("LodOverride", -1)
		BUILDER:GetSet("Passes", 1)
		BUILDER:GetSet("TintColor", Vector(0, 0, 0), {editor_panel = "color"})
		BUILDER:GetSet("LightBlend", 1)
		BUILDER:GetSet("ModelFallback", "", {editor_panel = "model"})
		BUILDER:GetSet("TextureFilter", 3)
		BUILDER:GetSet("BlurLength", 0)
		BUILDER:GetSet("BlurSpacing", 0)
		BUILDER:GetSet("UsePlayerColor", false)
		BUILDER:GetSet("UseWeaponColor", false)

	BUILDER:SetPropertyGroup("other")
		BUILDER:PropertyOrder("DrawOrder")
		BUILDER:GetSet("OwnerEntity", false)

BUILDER:EndStorableVars()

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
	self.Owner = pac.CreateEntity(self:GetModel(), is_obj)
	if not self.Owner:IsValid() then
		pac.Message("pac3 failed to create entity!")
		return
	end
	self.Owner:SetNoDraw(true)
	self.Owner.PACPart = self
	self.is_obj = is_obj
end


function PART:OnBecomePhysics()
	local ent = self:GetOwner()
	if not ent:IsValid() then return end
	ent:PhysicsInit(SOLID_NONE)
	ent:SetMoveType(MOVETYPE_NONE)
	ent:SetNoDraw(true)
	ent.RenderOverride = nil

	self.skip_orient = false
end

function PART:OnShow()
	local owner = self:GetParentOwner()
	local ent = self:GetOwner()

	if ent:IsValid() and owner:IsValid() and owner ~= ent then
		ent:SetPos(owner:EyePos())

		if self.OwnerEntity then
			self:SetOwnerEntity(self.OwnerEntity)
		end
	end

	if self.BlurLength > 0 then
		self.blur_history = {}
		self.blur_last_add = 0
	end
end

do

	function PART:OnThink()
		pac.SetModelScale(self:GetOwner(), self.Scale * self.Size, nil, self.UseLegacyScale)

		self:CheckScale()
		self:CheckBoneMerge()

		local ent = self:GetOwner()
		if ent:IsValid() then
			ent.pac_matproxies = ent.pac_matproxies or {}
			ent.pac_matproxies.ItemTintColor = self.TintColor / 255
		end
	end

	do
		local NULL = NULL

		local function BIND_MATPROXY(NAME, TYPE)

			local set = "Set" .. TYPE

			matproxy.Add(
				{
					name = NAME,

					init = function(self, mat, values)
						self.result = values.resultvar
					end,

					bind = function(self, mat, ent)
						ent = ent or NULL
						if ent:IsValid() then
							if ent.pac_matproxies and ent.pac_matproxies[NAME] then
								mat[set](mat, self.result, ent.pac_matproxies[NAME])
							end
						end
					end
				}
			)

		end

		-- tf2
		BIND_MATPROXY("ItemTintColor", "Vector")
	end
end

function PART:SetOwnerEntity(b)
	local ent = self:GetParentOwner()
	if ent:IsValid() then
		if b then
			self.Owner = ent

			function ent.RenderOverride()
				if self:IsValid() then
					if not self.HideEntity then
						self:PreEntityDraw(ent, ent:GetPos(), ent:GetAngles())
						ent:DrawModel()
						self:PostEntityDraw(ent, ent:GetPos(), ent:GetAngles())
					end
				else
					ent.RenderOverride = nil
				end
			end
		elseif self.OwnerEntity then
			self.Owner = NULL

			ent.RenderOverride = nil
			pac.SetModelScale(ent, Vector(1,1,1), nil, self.UseLegacyScale)

			self:Initialize()
		end
	end

	self.OwnerEntity = b
end

function PART:PreEntityDraw(ent, pos, ang)
	if not ent:IsPlayer() and pos and ang then
		if not self.skip_orient then
			ent:SetPos(pos)
			ent:SetAngles(ang)
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

			local r, g, b = self.Colorf[1], self.Colorf[2], self.Colorf[3]

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

function PART:PostEntityDraw(ent, pos, ang)
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

function PART:OnDraw()
	local ent = self:GetOwner()

	if not ent:IsValid() then
		self:Reset()
		ent = self:GetOwner()
		if not ent:IsValid() then
			pac.Message("WTF", ent, self:GetOwner())
			return
		end
	end

	local pos, ang = self:GetDrawPosition()

	self:PreEntityDraw(ent, pos, ang)
		self:DrawModel(ent, pos, ang)
	self:PostEntityDraw(ent, pos, ang)

	pac.SetupBones(ent)
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

do
	local _self, _ent, _pos, _ang
	local _return_status = false

	local function protected_real_draw_model()
		RealDrawModel(_self, _ent, _pos, _ang)
	end

	local function protected_inner_draw_model()
		local mat = _self.MaterialOverride or _self.Materialm

		render_MaterialOverride(mat)

		if mat then
			render_SetMaterial(mat)
		end

		pac.render_material = mat

		-- Render model
		local passCount = math_max (1, _self.Passes)

		if _self.Alpha >= 1 then
			passCount = math_min (passCount, 1)
		end

		for _ = 1, passCount do
			local status = ProtectedCall(protected_real_draw_model)

			if not status then
				_return_status = false
				return
			end
		end

		render_PushFlashlightMode(true)

		ProtectedCall(protected_real_draw_model)

		render_PopFlashlightMode()

		_return_status = true
	end

	function PART:DrawModel(ent, pos, ang)
		if self.Alpha == 0 or self.Size == 0 then return end

		if self.loading_obj then
			self:DrawLoadingText(ent, pos, ang)
		end

		if self.loading_obj and not self.Mesh then return end

		local textureFilter = self.texfilter_enum or TEXFILTER.ANISOTROPIC
		local filter_updated = textureFilter ~= TEXFILTER.ANISOTROPIC or self.Mesh

		if filter_updated then
			render_PushFilterMin(textureFilter)
			render_PushFilterMag(textureFilter)
		end

		_self, _ent, _pos, _ang = self, ent, pos, ang

		ProtectedCall(protected_inner_draw_model)

		if filter_updated then
			render_PopFilterMag()
			render_PopFilterMin()
		end

		-- Render "blur"
		if self.BlurLength > 0 and _return_status then
			self:DrawBlur(ent, pos, ang)
		end

		render_MaterialOverride()
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
	if pac.drawing_motionblur_alpha then return end
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
		pac.SetupBones(ent)

		RealDrawModel(self, ent, pos, ang)
	end

	local maximumBlurHistoryLength = math.min(self.BlurLength, 20)
	while #self.blur_history >= maximumBlurHistoryLength do
		table_remove(self.blur_history, 1)
	end
end

local function set_mesh(part, mesh)
	local owner = part:GetOwner()
	part.Mesh = mesh
	pac.ResetBoneCache(owner)

	if not part.Materialm then
		part.Materialm = Material("error")
	end

	function owner.pacDrawModel(ent, simple)
		if simple then
			RealDrawModel(part, ent, ent:GetPos(), ent:GetAngles())
		else
			part:ModifiersPreEvent("OnDraw")
			part:DrawModel(ent, ent:GetPos(), ent:GetAngles())
			part:ModifiersPostEvent("OnDraw")
		end
	end

	-- temp
	owner:SetRenderBounds(Vector(1, 1, 1) * -300, Vector(1, 1, 1) * 300)
end

do
	pac.urlobj = include("pac3/libraries/urlobj/urlobj.lua")

	function PART:SetModel(modelPath)
		if modelPath:find("^mdlhttp") then
			self.Model = modelPath

			modelPath = modelPath:gsub("^mdl", "")

			pac.DownloadMDL(modelPath, function(path)
				if self:IsValid() and self:GetOwner():IsValid() then
					local ent = self:GetOwner()
					self.loading = nil
					pac.ResetBoneCache(ent)
					ent:SetModel(path)
				end
			end, function(err)
				pac.Message(err)
				if self:IsValid() and self:GetOwner():IsValid() then
					local ent = self:GetOwner()
					self.loading = nil
					pac.ResetBoneCache(ent)
					ent:SetModel("models/error.mdl")
				end
			end, self:GetPlayerOwner())

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

					if not meshes and err then
						self:GetOwner():SetModel("models/error.mdl")
						self.Mesh = nil
						return
					end

					if table.Count(meshes) == 1 then
						set_mesh(self, select(2, next(meshes)))
					else
						for key, mesh in pairs(meshes) do
							local part = pac.CreatePart("model", self:GetParentOwnerName())
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

		if self.is_obj or not self.Owner:IsValid() then
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
		pac.ResetBoneCache(self.Owner)
		self.Owner:SetModel(real_model)

		if not self:IsHidden() and not self:IsDrawHidden() then
			-- notify children about model change
			self:ShowFromRendering()
		end
	end
end

local NORMAL = Vector(1,1,1)

function PART:CheckScale()
	-- RenderMultiply doesn't work with this..
	if (self.UseLegacyScale or self.BoneMerge) and self.Owner:IsValid() and self.Owner:GetBoneCount() and self.Owner:GetBoneCount() > 1 then
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
			pac.SetModelScale(self.Owner, self.Scale, nil, self.UseLegacyScale)
			self.used_alt_scale = true
		end
	else
		if self.used_alt_scale then
			pac.SetModelScale(self.Owner, nil, 1, self.UseLegacyScale)
			self.used_alt_scale = false
		end
		if not self:CheckScale() then
			pac.SetModelScale(self.Owner, self.Scale * self.Size, nil, self.UseLegacyScale)
		end
	end
end

function PART:SetSize(var)
	var = var or 1

	self.Size = var

	if self.AlternativeScaling then
		pac.SetModelScale(self.Owner, nil, self.Size, self.UseLegacyScale)
		self.used_alt_scale = true
	else
		if self.used_alt_scale then
			pac.SetModelScale(self.Owner, nil, 1, self.UseLegacyScale)
			self.used_alt_scale = false
		end
		if not self:CheckScale() then
			pac.SetModelScale(self.Owner, self.Scale * self.Size, nil, self.UseLegacyScale)
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
		self.Colorf = {c.x, c.y, c.z}
	elseif self.UseWeaponColor and owner:IsValid() then
		local c = owner:GetWeaponColor() * self.Brightness
		self.Colorf = {c.x, c.y, c.z}
	else
		self.Colorf = {(var.r / 255) * self.Brightness, (var.g / 255) * self.Brightness, (var.b / 255) * self.Brightness}
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

			self.Materialm = pac.CreateMaterial(pac.uid"pac_fixmat_", "VertexLitGeneric", params)
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
			self:CallRecursive("OnMaterialChanged")
		end
	end

	self.Material = var
end

function PART:SetSkin(var)
	var = var or 0

	self.Skin = var
	self.Owner:SetSkin(var)
end

function PART:OnRemove()
	if not self.OwnerEntity then
		timer.Simple(0, function()
			SafeRemoveEntity(self.Owner)
		end)
	end
end

function PART:SetLodOverride(num)
	local ent = self.Owner
	if ent:IsValid() then
		ent:SetLOD(num)
		self.LodOverride = num
	end
end

function PART:CheckBoneMerge()
	local ent = self.Owner

	if self.skip_orient then return end

	if ent:IsValid() and not ent:IsPlayer() then
		if self.BoneMerge then
			local owner = self:GetParentOwner()

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

	local ent = self:GetOwner()
	local owner = self:GetParentOwner()

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

BUILDER:Register()
