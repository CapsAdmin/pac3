jit.on(true, true)

local pac = pac

local PART = {} 

PART.ClassName = "model"
PART.ManualDraw = true
PART.HandleModifiersManually = true

pac.StartStorableVars()
	pac.GetSet(PART, "BoneMerge", false)
	pac.GetSet(PART, "BoneMergeAlternative", false)
	pac.GetSet(PART, "Skin", 0)
	pac.GetSet(PART, "Fullbright", false)
	pac.GetSet(PART, "Invert", false)
	pac.GetSet(PART, "DoubleFace", false)
	pac.GetSet(PART, "Bodygroup", 0)
	pac.GetSet(PART, "BodygroupState", 0)
	pac.GetSet(PART, "Material", "")
	pac.GetSet(PART, "Color", Vector(255, 255, 255))
	pac.GetSet(PART, "TintColor", Vector(0, 0, 0))
	pac.GetSet(PART, "Brightness", 1)
	pac.GetSet(PART, "CellShade", 0)
	pac.GetSet(PART, "LightBlend", 1)
	pac.GetSet(PART, "Alpha", 1)
	pac.GetSet(PART, "Passes", 1)
	pac.GetSet(PART, "Scale", Vector(1,1,1))
	pac.GetSet(PART, "Size", 1)
	pac.GetSet(PART, "AlternativeScaling", false)
	pac.GetSet(PART, "OverallSize", 1)
	pac.GetSet(PART, "OriginFix", false)
	pac.GetSet(PART, "Model", "models/dav0r/hoverball.mdl")
	pac.GetSet(PART, "OwnerEntity", false)
	pac.GetSet(PART, "TextureFilter", 3)
	
	pac.GetSet(PART, "BlurLength", 0)
	pac.GetSet(PART, "BlurSpacing", 0)
	
	pac.GetSet(PART, "UseLegacyScale", false)
	
	pac.GetSet(PART, "UsePlayerColor", false)
	pac.GetSet(PART, "UseWeaponColor", false)
	
	pac.GetSet(PART, "LodOverride", -1)
pac.EndStorableVars()

function PART:GetNiceName()
	local str = pac.PrettifyName(("/".. self:GetModel()):match(".+/(.-)%."))
	
	return str and str:gsub("%d", "") or "error"
end

pac.GetSet(PART, "Entity", NULL)

function PART:GetEntity()
	if not self.Entity:IsValid() then
		self:Initialize()
	end

	return self.Entity
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

function PART:Initialize()	
	self.Entity = pac.CreateEntity(self:GetModel())
	self.Entity:SetNoDraw(true)
	self.Entity.PACPart = self
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
			
			function ent.RenderOverride(ent)
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
		else
			self.Entity = NULL
			
			ent.RenderOverride = nil
			pac.SetModelScale(ent, Vector(1,1,1), nil, self.UseLegacyScale)
		end
	end
	
	self.OwnerEntity = b
end

local pac = pac

local render_CullMode = render.CullMode
local render_SetColorModulation = render.SetColorModulation
local render_SetBlend = render.SetBlend
local render_ModelMaterialOverride = render.MaterialOverride
local render_MaterialOverride = render.ModelMaterialOverride
local render_SuppressEngineLighting = render.SuppressEngineLighting
local LocalToWorld = LocalToWorld
local MATERIAL_CULLMODE_CW = MATERIAL_CULLMODE_CW
local render=render

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
	
		if not pac.DisableDoubleFace then
			if self.DoubleFace then
				render_CullMode(MATERIAL_CULLMODE_CW)
			else
				if self.Invert then
					render_CullMode(MATERIAL_CULLMODE_CW)
				end
			end
		end
		
		if not pac.DisableColoring then
			if not self.Colorf then 
				self:SetColor(self:GetColor())
			end
		
			if self.UseWeaponColor or self.UsePlayerColor then 
				local owner = self:GetOwner(true)
				if owner:IsPlayer() then
					local c = owner:GetInfo("cl_playercolor")
					if c ~= self.last_playercolor then
						self:SetColor(self:GetColor())
						self.last_playercolor = c
					end
					local c = owner:GetInfo("cl_weaponcolor")
					if c ~= self.last_weaponcolor then
						self:SetColor(self:GetColor())
						self.last_weaponcolor = c
					end
					
				end
			end
			
			local r, g, b = self.Colorf.r, self.Colorf.g, self.Colorf.b

			if self.LightBlend ~= 1 then
				local 
				v = render.GetLightColor(pos) 
				r = r * v.r * self.LightBlend
				g = g * v.g * self.LightBlend
				b = b * v.b * self.LightBlend
				
				v = render.GetAmbientLightColor(pos)
				r = r * v.r * self.LightBlend
				g = g * v.g * self.LightBlend
				b = b * v.b * self.LightBlend
			end
			
			render_SetColorModulation(r,g,b) 
			render_SetBlend(self.Alpha)
		end
			
		if self.Fullbright then
			render_SuppressEngineLighting(true) 
		end
	end
end

local MATERIAL_CULLMODE_CCW = MATERIAL_CULLMODE_CCW
local WHITE = Material("models/debug/debugwhite")

function PART:PostEntityDraw(owner, ent, pos, ang)
	if self.Alpha ~= 0 and self.Size ~= 0 then
	
		if not pac.DisableDoubleFace then		
			if self.DoubleFace then
				render_CullMode(MATERIAL_CULLMODE_CCW)
				self:DrawModel(ent, pos, ang)
			else
				if self.Invert then
					render_CullMode(MATERIAL_CULLMODE_CCW)
				end
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
				
		self:ModifiersPostEvent("OnDraw")
	end
end

local render_SetMaterial = render.SetMaterial

function PART:OnDraw(owner, pos, ang)
	local ent = self.Entity
		
	if ent:IsValid() then		
	
		self:PreEntityDraw(owner, ent, pos, ang)
			self:DrawModel(ent, pos, ang)	
		self:PostEntityDraw(owner, ent, pos, ang)
		
		pac.ResetBones(ent)
				
		if self.OriginFix then
			self:SetPositionOffset(self:GetPositionOffset() + -ent:OBBCenter() * self.Scale * self.Size)
			self:SetOriginFix(false)
		end
		
		if ent.pac_can_legacy_scale ~= false then
			ent.pac_can_legacy_scale = not not ent.pac_can_legacy_scale
		end
	else
		timer.Simple(0, function()
			self:Initialize()
		end)
	end
end

local Matrix = Matrix
local cam_PushModelMatrix = cam.PushModelMatrix
local cam_PopModelMatrix = cam.PopModelMatrix

surface.CreateFont("pac_urlobj_loading", 
	{
		font = "Arial",
		size = 20,
		weight = 10,
		antialias = true,
		outline = true,
	}
)

-- ugh lol
local function RealDrawModel(self, ent, pos, ang) 
	if self.wavefront_mesh then
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
			self.wavefront_mesh:Draw()
		cam_PopModelMatrix()
	else
		ent:DrawModel()
	end
end

local render_PushFlashlightMode = render.PushFlashlightMode
local render_PopFlashlightMode = render.PopFlashlightMode

local render_PopFilterMin = render.PopFilterMin
local render_PopFilterMag = render.PopFilterMag
local render_PushFilterMag = render.PushFilterMag 
local render_PushFilterMin = render.PushFilterMin 

local table_insert = table.insert
local table_remove = table.remove
local math_abs = math.abs
local math_ceil = math.ceil

function PART:DrawModel(ent, pos, ang)
	if self.Alpha ~= 0 and self.Size ~= 0 then
	
		if self.loading_obj then
			cam.Start2D()
			cam.IgnoreZ(true)
				local pos2d = pos:ToScreen()
			
				surface.SetFont("pac_urlobj_loading")
				surface.SetTextColor(255, 255, 255, 255)
				
				
				local str = self.loading_obj .. ("."):rep(pac.RealTime*3%3)
				local w, h = surface.GetTextSize(self.loading_obj .. "...")
				
				surface.SetTextPos(pos2d.x - w/2, pos2d.y - h/2)
				surface.DrawText(str)
			cam.IgnoreZ(false)
			cam.End2D()
			return
		end
		
		local filter = self.texfilter_enum or 3
		
		if filter ~= 3 or self.wavefront_mesh then
			render_PushFilterMin(filter)
			render_PushFilterMag(filter)
		end
		
		render_MaterialOverride(self.Materialm) 
		render_ModelMaterialOverride(self.Materialm) 
		if self.Materialm then 
			render_SetMaterial(self.Materialm) 
		end
		
			
			if self.Passes > 1 and self.Alpha < 1 then
				for i = 1, self.Passes do
					RealDrawModel(self, ent, pos, ang)
				end
			else
				RealDrawModel(self, ent, pos, ang)
			end
														
		render_PushFlashlightMode(true)
			RealDrawModel(self, ent, pos, ang)
		render_PopFlashlightMode()
		
				
		if filter ~= 3 or self.wavefront_mesh then
			render_PopFilterMag()
			render_PopFilterMin()
		end
		
		if self.BlurLength > 0 then
			self.blur_history = self.blur_history or {}
			
			local len = self.BlurLength
			local spc = self.BlurSpacing
			
			if not self.blur_last_add or spc == 0 or self.blur_last_add < pac.RealTime then
				table_insert(self.blur_history, {pos, ang})
				self.blur_last_add = pac.RealTime + spc / 1000
			end
			
			local count = #self.blur_history
							
			len = math.min(len, 20)
					
			local delta = FrameTime() * 5				
			
			for i = 1, count do
				local pos, ang = self.blur_history[i][1], self.blur_history[i][2]
				
				render_SetBlend(self.Alpha * (i / count))
				
				ent:SetPos(pos)
				ent:SetAngles(ang)
				ent:SetupBones()
				
				RealDrawModel(self, ent, pos, ang)
			end

			while #self.blur_history >= len do
				table_remove(self.blur_history, 1) 
			end
		end
	end
end

local function set_mesh(part, mesh)		
	part.wavefront_mesh = mesh
	part.Entity.pac_bones = nil
	
	if not part.Materialm then
		part.Materialm = Material("error")
	end

	function part.Entity.pacDrawModel(ent)
		part:ModifiersPreEvent("OnDraw")
		part:DrawModel(ent, ent:GetPos(), ent:GetAngles())
		part:ModifiersPostEvent("OnDraw")
	end
	
	-- temp
	part.Entity:SetRenderBounds(Vector(1, 1, 1)*-300, Vector(1, 1, 1)*300)	
end

function PART:SetModel(var,override)
	self.Entity = self:GetEntity()

	if var and var:find("http") and pac.urlobj then
		self.loading_obj = "downloading"
		
		pac.urlobj.GetObjFromURL(var, false, false,
			function(meshes, err)
				if not self:IsValid() then return end
				
				self.loading_obj = false
				
				self.Entity = self:GetEntity()
				
				if not meshes and err then
					self.Entity:SetModel("error.mdl")
					self.wavefront_mesh = nil
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
		
		self.Model = var
		return
	end
	
	self.wavefront_mesh = nil
	
	var = hook.Run("pac_model:SetModel",self,var) or var
	
	self.Model = var
	self.Entity:SetModel(var)

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

local VEC3_NOMRAL = Vector(1,1,1)

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
		local c = Vector(owner:GetInfo("cl_playercolor")) * self.Brightness
		self.Colorf = Color(c.r, c.g, c.b)
	elseif self.UseWeaponColor and owner:IsValid() then
		local c = Vector(owner:GetInfo("cl_weaponcolor")) * self.Brightness
		self.Colorf = Color(c.r, c.g, c.b)
	else
		self.Colorf = Color((var.r/255) * self.Brightness, (var.g/255) * self.Brightness, (var.b/255) * self.Brightness)
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
			
			self.Materialm = CreateMaterial("pac_fixmat_" .. os.clock(), "VertexLitGeneric", params)
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

function PART:SetBodygroupState(var)
	var = var or 0

	self.BodygroupState = var
	timer.Simple(0, function() 
		if self:IsValid() and self.Entity:IsValid() then
			self.Entity:SetBodygroup(self.Bodygroup, var) 
		end
	end)		
end

function PART:SetBodygroup(var)
	var = var or 0

	self.Bodygroup = var
	timer.Simple(0, function() 
		if self:IsValid() and self.Entity:IsValid() then
			self.Entity:SetBodygroup(var, self.BodygroupState) 
		end
	end)		
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

function PART:SetBoneMergeAlternative(b)
	
	self.BoneMergeAlternative = b

	local ent = self.Entity
	if ent:IsValid() then
		ent.pac_bones = nil
		local owner = self:GetOwner()
		if owner:IsValid() then 
			owner.pac_bones = nil
		end
		
		if b then
			ent:SetParent(owner)
		else
			ent:SetParent(NULL)
		end
	end
end

function PART:SetLodOverride(num)
	local ent = self.Entity
	if ent:IsValid() then
		ent:SetLOD(num)
		self.LodOverride = num
	end
end

local EF_BONEMERGE = EF_BONEMERGE

function PART:CheckBoneMerge()
	local ent = self.Entity
	
	if self.skip_orient then return end
	
	if ent:IsValid() and not ent:IsPlayer() then			
		if self.BoneMerge and not self.BoneMergeAlternative then
			local owner = self:GetOwner()
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

local bad_bones = 
{
	["ValveBiped.Bip01_L_Finger0"] = true,
	["ValveBiped.Bip01_L_Finger01"] = true,
	["ValveBiped.Bip01_L_Finger02"] = true, 

	["ValveBiped.Bip01_L_Finger1"] = true,
	["ValveBiped.Bip01_L_Finger11"] = true, 
	["ValveBiped.Bip01_L_Finger12"] = true,

	["ValveBiped.Bip01_L_Finger2"] = true,
	["ValveBiped.Bip01_L_Finger21"] = true,
	["ValveBiped.Bip01_L_Finger22"] = true,


	["ValveBiped.Bip01_R_Finger0"] = true,
	["ValveBiped.Bip01_R_Finger01"] = true,
	["ValveBiped.Bip01_R_Finger02"] = true,

	["ValveBiped.Bip01_R_Finger1"] = true,
	["ValveBiped.Bip01_R_Finger11"] = true,
	["ValveBiped.Bip01_R_Finger12"] = true,

	["ValveBiped.Bip01_R_Finger2"] = true,
	["ValveBiped.Bip01_R_Finger21"] = true,
	["ValveBiped.Bip01_R_Finger22"] = true,
}

local SCALE_NORMAL = Vector(1, 1, 1)
local Vector = Vector

function PART:OnBuildBonePositions()

	if self.AlternativeScaling then return end

	local ent = self:GetEntity()
	local owner = self:GetOwner()
	
	if not ent:IsValid() or not owner:IsValid() or not ent:GetBoneCount() or ent:GetBoneCount() < 1 then return end
	
	if self.OverallSize ~= 1 then
		for i = 0, ent:GetBoneCount()-1 do
			ent:ManipulateBoneScale(i, ent:GetManipulateBoneScale(i) * SCALE_NORMAL * self.OverallSize)
		end
	end
	
	if self.requires_bone_model_scale then		
		local scale = self.Scale * self.Size
		
		for i = 0, ent:GetBoneCount()-1 do	
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