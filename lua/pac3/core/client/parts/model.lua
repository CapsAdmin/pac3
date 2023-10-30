CreateConVar( "pac_model_max_scales", "10000", FCVAR_ARCHIVE, "Maximum scales model can have")




local pac = pac

local render_SetColorModulation = render.SetColorModulation
local render_SetBlend = render.SetBlend
local render_CullMode = render.CullMode
local MATERIAL_CULLMODE_CW = MATERIAL_CULLMODE_CW
local MATERIAL_CULLMODE_CCW = MATERIAL_CULLMODE_CCW
local render_MaterialOverride = render.ModelMaterialOverride
local cam_PushModelMatrix = cam.PushModelMatrix
local cam_PopModelMatrix = cam.PopModelMatrix
local Vector = Vector
local EF_BONEMERGE = EF_BONEMERGE
local NULL = NULL
local Color = Color
local Matrix = Matrix
local vector_origin = vector_origin
local render = render
local cam = cam
local surface = surface
local render_MaterialOverrideByIndex = render.MaterialOverrideByIndex
local render_SuppressEngineLighting = render.SuppressEngineLighting

local BUILDER, PART = pac.PartTemplate("base_drawable")

PART.FriendlyName = "model"
PART.ClassName = "model2"
PART.Category = "model"
PART.ManualDraw = true
PART.HandleModifiersManually = true
PART.Icon = 'icon16/shape_square.png'
PART.is_model_part = true
PART.ProperColorRange = true
PART.Group = 'model'

BUILDER:StartStorableVars()
	:SetPropertyGroup("generic")
		:PropertyOrder("Name")
		:PropertyOrder("Hide")
		:PropertyOrder("ParentName")
		:GetSet("Model", "", {editor_panel = "model"})
		:GetSet("ForceObjUrl", false)

	:SetPropertyGroup("orientation")
		:GetSet("Size", 1, {editor_sensitivity = 0.25})
		:GetSet("Scale", Vector(1,1,1))
		:GetSet("BoneMerge", false)
		:GetSet("LegacyTransform", false)

	:SetPropertyGroup("appearance")
		:GetSet("Color", Vector(1, 1, 1), {editor_panel = "color2"})
		:GetSet("Brightness", 1)
		:GetSet("NoLighting", false)
		:GetSet("NoCulling", false)
		:GetSet("Invert", false)
		:GetSet("Alpha", 1, {editor_sensitivity = 0.25, editor_clamp = {0, 1}})
		:GetSet("ModelModifiers", "", {hidden = true})
		:GetSet("Material", "", {editor_panel = "material"})
		:GetSet("Materials", "", {hidden = true})
		:GetSet("Skin", 0, {editor_onchange = function(self, num) return math.Round(math.Clamp(tonumber(num), 0, pace.current_part:GetOwner():SkinCount())) end})
		:GetSet("LevelOfDetail", 0, {editor_clamp = {-1, 8}, editor_round = true})
		:GetSetPart("EyeTarget")

:EndStorableVars()

PART.Owner = NULL

function PART:GetNiceName()
	local str = pac.PrettifyName(("/" .. self:GetModel()):match(".+/(.-)%."))

	return str and str:gsub("%d", "") or "error"
end

function PART:GetDynamicProperties()
	local ent = self:GetOwner()
	if not ent:IsValid() or not ent:GetBodyGroups() then return end

	local tbl = {}

	if ent:SkinCount() and ent:SkinCount() > 1 then
		tbl.skin = {
			key = "skin",
			set = function(val)
				local tbl = self:ModelModifiersToTable(self:GetModelModifiers())
				tbl.skin = val
				self:SetModelModifiers(self:ModelModifiersToString(tbl))
			end,
			get = function()
				return self:ModelModifiersToTable(self:GetModelModifiers()).skin
			end,
			udata = {editor_onchange = function(self, num) return math.Clamp(math.Round(num), 0, ent:SkinCount() - 1) end},
		}
	end

	for _, info in ipairs(ent:GetBodyGroups()) do
		if info.num > 1 then
			tbl[info.name] = {
				key = info.name,
				set = function(val)
					local tbl = self:ModelModifiersToTable(self:GetModelModifiers())
					tbl[info.name] = val
					self:SetModelModifiers(self:ModelModifiersToString(tbl))
				end,
				get = function()
					return self:ModelModifiersToTable(self:GetModelModifiers())[info.name] or 0
				end,
				udata = {editor_onchange = function(self, num) return math.Clamp(math.Round(num), 0, info.num - 1) end, group = "bodygroups"},
			}
		end
	end

	if ent:GetMaterials() and #ent:GetMaterials() > 1 then
		for i, name in ipairs(ent:GetMaterials()) do
			name = name:match(".+/(.+)") or name
			tbl[name] = {
				key = name,
				get = function()
					local tbl = self.Materials:Split(";")
					return tbl[i] or ""
				end,
				set = function(val)
					local tbl = self.Materials:Split(";")
					tbl[i] = val

					for i, name in ipairs(ent:GetMaterials()) do
						tbl[i] = tbl[i] or ""
					end

					self:SetMaterials(table.concat(tbl, ";"))
				end,
				udata = {editor_panel = "material", editor_friendly = name, group = "sub materials"},
			}
		end
	end

	return tbl
end

function PART:SetLevelOfDetail(val)
	self.LevelOfDetail = val
	local ent = self:GetOwner()
	if ent:IsValid() then
		ent:SetLOD(val)
	end
end

function PART:SetSkin(var)
	self.Skin = var
	local owner = self:GetOwner()

	if owner:IsValid() then
		owner:SetSkin(var)
	end
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
	local owner = self:GetOwner()

	if not owner:IsValid() then return end

	local tbl = self:ModelModifiersToTable(str)

	if tbl.skin then
		self:SetSkin(tbl.skin)
		tbl.skin = nil
	end

	if not owner:GetBodyGroups() then return end

	self.draw_bodygroups = {}

	for i, info in ipairs(owner:GetBodyGroups()) do
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

	local materials = self:GetOwner():IsValid() and self:GetOwner():GetMaterials()

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
	self.cached_dynamic_props = nil
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

function PART:Initialize()
	self.Owner = pac.CreateEntity(self:GetModel())
	self.Owner:SetNoDraw(true)
	self.Owner.PACPart = self
	self.material_count = 0
end

function PART:OnShow()
	local owner = self:GetParentOwner()
	local ent = self:GetOwner()

	if ent:IsValid() and owner:IsValid() and owner ~= ent then
		ent:SetPos(owner:EyePos())
		ent:SetLegacyTransform(self.LegacyTransform)
		self:SetBone(self:GetBone())
	end
end

function PART:OnRemove()
	if not self.loading then
		SafeRemoveEntityDelayed(self.Owner,0.1)
	end
end

function PART:OnThink()
	self:CheckBoneMerge()
end

function PART:BindMaterials(ent)
	local materials = self.material_override_self or self.material_override
	local material_bound = false

	if self.material_override_self then
		if materials[0] then
			render_MaterialOverride(materials[0])
			material_bound = true
		end

		for i = 1, self.material_count do
			local mat = materials[i]

			if mat then
				render_MaterialOverrideByIndex(i-1, mat)
			else
				render_MaterialOverrideByIndex(i-1, nil)
			end
		end
	elseif self.material_override then
		if materials[0] and materials[0][1] then
			render_MaterialOverride(materials[0][1]:GetRawMaterial())
			material_bound = true
		end

		for i = 1, self.material_count do
			local stack = materials[i]
			if stack then
				local mat = stack[1]

				if mat then
					render_MaterialOverrideByIndex(i-1, mat:GetRawMaterial())
				else
					render_MaterialOverrideByIndex(i-1, nil)
				end
			end
		end
	end

	if self.BoneMerge and not material_bound then
		render_MaterialOverride()
	end

	return material_bound
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

		local r, g, b = self.Color.r, self.Color.g, self.Color.b
		local brightness = self.Brightness

		-- render.SetColorModulation and render.SetAlpha set the material $color and $alpha.
		render_SetColorModulation(r*brightness, g*brightness, b*brightness)
		if not pac.drawing_motionblur_alpha then
			render_SetBlend(self.Alpha)
		end

		if self.NoLighting then
			render_SuppressEngineLighting(true)
		end
	end

	if self.draw_bodygroups then
		for _, v in ipairs(self.draw_bodygroups) do
			ent:SetBodygroup(v[1], v[2])
		end
	end

	if self.EyeTarget:IsValid() and self.EyeTarget.GetWorldPosition then
		ent:SetEyeTarget(self.EyeTarget:GetWorldPosition())
		ent.pac_modified_eyetarget = true
	elseif ent.pac_modified_eyetarget then
		ent:SetEyeTarget(vector_origin)
		ent.pac_modified_eyetarget = nil
	end
end

function PART:PostEntityDraw(ent, pos, ang)
	if self.Alpha ~= 0 and self.Size ~= 0 then
		self:ModifiersPostEvent("OnDraw")

		if self.NoLighting then
			render_SuppressEngineLighting(false)
		end
	end
end

function PART:OnDraw()
	local ent = self:GetOwner()

	if not ent:IsValid() then
		self:Reset()
		ent = self:GetOwner()
	end

	local pos, ang = self:GetDrawPosition()

	if self.loading then
		self:DrawLoadingText(ent, pos)
		return
	end


	self:PreEntityDraw(ent, pos, ang)
		self:DrawModel(ent, pos, ang)
	self:PostEntityDraw(ent, pos, ang)

	pac.ResetBones(ent)
end


local matrix = Matrix()
local IDENT_SCALE = Vector(1,1,1)
local _self, _ent, _pos, _ang

local function ent_draw_model(self, ent, pos, ang)
	if self.obj_mesh then
		ent:SetModelScale(0,0)
		ent:DrawModel()

		matrix:Identity()
		matrix:SetAngles(ang)
		matrix:SetTranslation(pos)
		matrix:SetScale(self.Scale * self.Size)

		cam_PushModelMatrix(matrix)
			self.obj_mesh:Draw()
		cam_PopModelMatrix()
	else
		if ent.needs_setupbones_from_legacy_bone_parts then
			pac.SetupBones(ent)
			ent.needs_setupbones_from_legacy_bone_parts = nil
		end
		ent:DrawModel()
	end
end

local function protected_ent_draw_model()
	ent_draw_model(_self, _ent, _pos, _ang)
end

function PART:DrawModel(ent, pos, ang)
	if self.loading then
		self:DrawLoadingText(ent, pos)
	end

	if self.Alpha == 0 or self.Size == 0 then return end
	if self.loading and not self.obj_mesh then return end

	if self.NoCulling or self.Invert then
		render_CullMode(MATERIAL_CULLMODE_CW)
	end

	local material_bound = false

	material_bound = self:BindMaterials(ent) or material_bound

	ent.pac_drawing_model = true
	ent_draw_model(self, ent, pos, ang)
	ent.pac_drawing_model = false

	_self, _ent, _pos, _ang = self, ent, pos, ang

	if self.ClassName ~= "entity2" then
		render.PushFlashlightMode(true)

		material_bound = self:BindMaterials(ent) or material_bound
		ent.pac_drawing_model = true
		ProtectedCall(protected_ent_draw_model)
		ent.pac_drawing_model = false

		render.PopFlashlightMode()
	end

	if self.NoCulling then
		render_CullMode(MATERIAL_CULLMODE_CCW)
		material_bound = self:BindMaterials(ent) or material_bound
		ProtectedCall(protected_ent_draw_model)
	elseif self.Invert then
		render_CullMode(MATERIAL_CULLMODE_CCW)
	end

	-- need to unbind mateiral
	if material_bound then
	    render_MaterialOverride()
	end
end

function PART:DrawLoadingText(ent, pos)
	cam.Start2D()
	cam.IgnoreZ(true)
		local pos2d = pos:ToScreen()

		surface.SetFont("DermaDefault")

		if self.errored then
			surface.SetTextColor(255, 0, 0, 255)
			local str = self.loading:match("^(.-):\n") or self.loading:match("^(.-)\n") or self.loading:sub(1, 100)
			local w, h = surface.GetTextSize(str)
			surface.SetTextPos(pos2d.x - w / 2, pos2d.y - h / 2)
			surface.DrawText(str)
			self:SetError(str)
		else
			surface.SetTextColor(255, 255, 255, 255)
			local str = self.loading .. string.rep(".", pac.RealTime * 3 % 3)
			local w, h = surface.GetTextSize(self.loading .. "...")

			surface.SetTextPos(pos2d.x - w / 2, pos2d.y - h / 2)
			surface.DrawText(str)
			self:SetError()
		end
	cam.IgnoreZ(false)
	cam.End2D()
end

local ALLOW_TO_MDL = CreateConVar('pac_allow_mdl', '1', CLIENT and {FCVAR_REPLICATED} or {FCVAR_ARCHIVE, FCVAR_REPLICATED}, 'Allow to use custom MDLs')

function PART:RefreshModel()
	if self.refreshing_model then return end

	self.refreshing_model = true

	local ent = self:GetOwner()

	if ent:IsValid() then
		pac.ResetBoneCache(ent)
	end

	self.cached_dynamic_props = nil

	self:SetModelModifiers(self:GetModelModifiers())
	self:SetMaterials(self:GetMaterials())
	self:SetSize(self:GetSize())
	self:SetScale(self:GetScale())
	self:SetSkin(self:GetSkin())
	self:SetLevelOfDetail(self:GetLevelOfDetail())

	if not self:IsHidden() and not self:IsDrawHidden() then
		-- notify children about model change
		self:ShowFromRendering()
	end

	self.refreshing_model = false
end

function PART:RealSetModel(path)
	self:GetOwner():SetModel(path)
	self:RefreshModel()
end

function PART:SetForceObjUrl(value)
	self.ForceObjUrl = value
	self:ProcessModelChange()
end

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

function PART:ProcessModelChange()
	local owner = self:GetOwner()
	if not owner:IsValid() then return end
	local path = self.Model

	if path:find("://", nil, true) then
		if path:StartWith("objhttp") or path:StartWith("obj:http") or path:match("%.obj%p?") or self.ForceObjUrl then
			path = path:gsub("^objhttp","http"):gsub("^obj:http","http")
			self.loading = "downloading obj"

			pac.urlobj.GetObjFromURL(path, false, false,
				function(meshes, err)

					local function set_mesh(part, mesh)
						local owner = part:GetOwner()
						part.obj_mesh = mesh
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

						owner:SetRenderBounds(Vector(1, 1, 1) * -300, Vector(1, 1, 1) * 300)
					end

					if not self:IsValid() then return end

					self.loading = false

					if not meshes and err then
						owner:SetModel("models/error.mdl")
						self.obj_mesh = nil
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
						self.loading = nil
					else
						self.loading = statusMessage
					end
				end
			)
		else
			local status, reason = hook.Run('PAC3AllowMDLDownload', self:GetPlayerOwner(), self, path)

			if ALLOW_TO_MDL:GetBool() and status ~= false then
				self.loading = "downloading mdl zip"
				pac.DownloadMDL(path, function(mdl_path)
					self.loading = nil
					self.errored = nil

					if self.ClassName == "entity2" then
						pac.emut.MutateEntity(self:GetPlayerOwner(), "model", self:GetOwner(), path)
					end

					self:RealSetModel(mdl_path)

				end, function(err)

					if pace and pace.current_part == self and not IsValid(pace.BusyWithProperties) then
						pace.MessagePrompt(err, "HTTP Request Failed for " .. path, "OK")
					else
						pac.Message(Color(0, 255, 0), "[model] ", Color(255, 255, 255), "HTTP Request Failed for " .. path .. " - " .. err)
					end

					self.loading = err
					self.errored = true
					self:RealSetModel("models/error.mdl")
				end, self:GetPlayerOwner())
			else
				local msg = reason or "mdl's are not allowed"
				self.loading = msg
				self:SetError(msg)
				self:RealSetModel("models/error.mdl")
				pac.Message(self, msg)
			end
		end
	elseif path ~= "" then
		if self.ClassName == "entity2" then
			pac.emut.MutateEntity(self:GetPlayerOwner(), "model", owner, path)
		end

		self:RealSetModel(path)
	end
end

function PART:SetModel(path)
	self.Model = path

	local owner = self:GetOwner()
	if not owner:IsValid() then return end

	self.old_model = path
	self:ProcessModelChange()
end

local NORMAL = Vector(1,1,1)

function PART:CheckScale()
	local owner = self:GetOwner()
	if not owner:IsValid() then return end

	-- RenderMultiply doesn't work with this..
	if self.BoneMerge and owner:GetBoneCount() and owner:GetBoneCount() > 1 then
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

function PART:SetScale(vec)
	local max_scale = GetConVar("pac_model_max_scales"):GetFloat()
	local largest_scale = math.max(math.abs(vec.x), math.abs(vec.y), math.abs(vec.z))

	if vec and max_scale > 0 and (LocalPlayer() ~= self:GetPlayerOwner()) then --clamp for other players if they have pac_model_max_scales convar more than 0
		vec = Vector(math.Clamp(vec.x, -max_scale, max_scale), math.Clamp(vec.y, -max_scale, max_scale), math.Clamp(vec.z, -max_scale, max_scale))
	end
	if largest_scale > 10000 then --warn about the default max scale
		self:SetError("Scale is being limited due to having an excessive component. Default maximum values are 10000")
	else self:SetError() end --if ok, clear the warning
	vec = vec or Vector(1,1,1)

	self.Scale = vec

	if not self:CheckScale() then
		self:ApplyMatrix()
	end
end

local vec_one = Vector(1,1,1)

function PART:ApplyMatrix()
	local ent = self:GetOwner()
	if not ent:IsValid() then return end

	local mat = Matrix()

	if self.ClassName ~= "model2" then
		mat:Translate(self.Position + self.PositionOffset)
		mat:Rotate(self.Angles + self.AngleOffset)
	end

	if ent:IsPlayer() or ent:IsNPC() then
		pac.emut.MutateEntity(self:GetPlayerOwner(), "size", ent, self.Size, {
			StandingHullHeight = self.StandingHullHeight,
			CrouchingHullHeight = self.CrouchingHullHeight,
			HullWidth = self.HullWidth,
		})

		if self.Size == 1 and self.Scale == vec_one then
			if self.InverseKinematics then
				if ent:GetModelScale() ~= 1 then
					ent:SetModelScale(1, 0)
				end
				ent:SetIK(true)
			else
				ent:SetModelScale(1.000001, 0)
				ent:SetIK(false)
			end
		end

		mat:Scale(self.Scale)
	else
		mat:Scale(self.Scale * self.Size)
	end

	ent.pac_model_scale = mat:GetScale()

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
	local ent = self:GetOwner()

	if ent == pac.LocalHands or ent == pac.LocalViewModel then return end

	if self.skip_orient then return end

	if ent:IsValid() and not ent:IsPlayer() and ent:GetModel() then
		if self.BoneMerge then
			local owner = self:GetParentOwner()

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
include("model/entity.lua")
include("model/weapon.lua")
