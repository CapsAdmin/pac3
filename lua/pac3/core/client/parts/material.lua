local PART = {}

PART.ClassName = "material"
PART.NonPhysical = true

PART.ShaderParams =
{
	BaseTexture = "ITexture",
	
	CloakPassEnabled  = "boolean",
	CloakFactor = "number",
	--CloakColorTint = "Vector",
	RefractAmount = "number",
	
	BumpMap = "ITexture",
	LightWarpTexture = "ITexture",

	Detail = "ITexture",
	DetailTint = "Vector",
	DetailScale = "number",
	DetailBlendMode = "number",
	DetailBlendFactor = "number",
	
	Phong = "boolean",
	PhongBoost = "number",
	PhongExponent = "number",
	PhongTint = "Vector",
	PhongFresnelRanges = "Vector",
	PhongWarpTexture = "ITexture",
	PhongAlbedoTint = "boolean",
	PhongExponentTexture = "ITexture",
	
	Rimlight = "boolean",	
	RimlightBoost = "number",	
	RimlightExponent = "number",
	
	-- doesn't do anything i think
	EnvMap = "ITexture",
	EnvMapMask = "ITexture",
	EnvMapTint = "Vector",
	EnvMapMode = "number",
	EnvMapContrast = "number",
	EnvMapMaskScale = "number",
	EnvMapSaturation = "Vector",
	NormalMapAlphaEnvMapMask = "boolean",
	BaseAlphaEnvMapMask = "boolean",
	Selfillum_EnvMapMask_Alpha = "number",
	
	AmbientOcclusion = "boolean",
	AmbientOcclusionColor = "Vector",
	AmbientOcclusionTexture = "ITexture",
	
	BlendTintByBaseAlpha = "boolean", 
	BlendTintColorOverBase = "Vector",  
	ColorTint_Base = "Vector",
	ColorTint_Tmp = "Vector",
	Color = "Vector",
	Color2 = "Vector",

	
	HalfLambert = "boolean",
	
	-- feature bloat?
--[[
	
	Selfillum = "boolean",
	SelillumTint = "Vector",
	SelfillumMask = "ITexture",
	Selfillum_Envmapmask_Alpha = "ITexture",
	SelfillumFresnel = "boolean",
	SelfillumFresnlenMinMaxExp = "Vector",

 	FleshInteriorEnabled = "boolean", --"0", "Enable Flesh interior blend pass" )
	FleshInteriorTexture = "ITexture", --"", "Flesh color texture" )
	FleshInteriorNoiseTexture = "ITexture", --"", "Flesh noise texture" )
	FleshBorderTexture1D = "ITexture", --"", "Flesh border 1D texture" )
	FleshNormalTexture = "ITexture", --"", "Flesh normal texture" )
	FleshSubsurfaceTexture = "ITexture", --"", "Flesh subsurface texture" )
	FleshCubeTexture = "ITexture", --"", "Flesh cubemap texture" )
	FleshBorderNoiseScale = "number", --"1.5", "Flesh Noise UV scalar for border" )
	FleshDebugForceFleshOn = "boolean", --"0", "Flesh Debug full flesh" )
	--FleshEFFECTCENTERRADIUS1, SHADER_PARAM_TYPE_VEC4, "[0 0 0 0.001]", "Flesh effect center and radius" )
	--FleshEFFECTCENTERRADIUS2, SHADER_PARAM_TYPE_VEC4, "[0 0 0 0.001]", "Flesh effect center and radius" )
	--FleshEFFECTCENTERRADIUS3, SHADER_PARAM_TYPE_VEC4, "[0 0 0 0.001]", "Flesh effect center and radius" )
	--FleshEFFECTCENTERRADIUS4, SHADER_PARAM_TYPE_VEC4, "[0 0 0 0.001]", "Flesh effect center and radius" )
	FleshSubsurfaceTint = "Vector", --"[1 1 1]", "Subsurface Color" )
	FleshBorderWidth = "number", --"0.3", "Flesh border" )
	FleshBorderSoftness = "number", --"0.42", "Flesh border softness (> 0.0 && <= 0.5)" )
	FleshBorderTint = "Vector", --"[1 1 1]", "Flesh border Color" )
	FleshGlobalOpacity = "number", --"1.0", "Flesh global opacity" )
	FleshGlossBrightness = "number", --"0.66", "Flesh gloss brightness" )
	FleshScrollSpeed = "number", --"1.0", "Flesh scroll speed" )
	
	EmissiveBlendEnabled = "boolean",
	EmissiveBlendTexture = "ITexture",
	EmissiveBlendBaseTexture = "ITexture",
	EmissiveBlendFlowTexture = "ITexture",
	EmissiveBlendTint = "Vector",
	EmissiveBlendScrollVector = "Vector",
	
	HalfLambert = "boolean",]]
}

function PART:OnThink()
	if self.delay_set and self.Parent then
		self.delay_set()
		self.delay_set = nil
	end
end

local function setup(PART)
	for name, T in pairs(PART.ShaderParams) do		
		if T == "ITexture" then
			pac.GetSet(PART, name, "")

			PART["Set" .. name] = function(self, var)
				self[name] = var
								
				if 
					self.SKIP or
					pac.Handleurltex(
						self, 
						var, 
						function(_, tex) 
							local mat = self:GetMaterialFromParent()
							if mat then
								mat:SetTexture("$" .. name, tex)
								
								self.SKIP = true
								self:UpdateMaterial()
								self.SKIP = false
							else
								self.delay_set = function()
									local mat = self:GetMaterialFromParent()
									if mat then
										mat:SetTexture("$" .. name, tex)
										self.SKIP = true
										self:UpdateMaterial()
										self.SKIP = false
									end
								end
							end
						end
					)
				then
					return
				end
				
				local mat = self:GetMaterialFromParent()
				
				if mat then				
					if var ~= "" then
						local _mat = Material(var)
						local tex = _mat:GetTexture("$" .. name) 

						if not tex or tex:GetName() == "error" then
							tex = CreateMaterial("pac3_tex_" .. var .. "_" .. self.Id, "VertexLitGeneric", {["$basetexture"] = var}):GetTexture("$basetexture")
														
							if not tex or tex:GetName() == "error" then
								tex = _mat:GetTexture("$basetexture")
							end
						end
						
						mat:SetTexture("$" .. name, tex)
					else
						if name == "BumpMap" then
							mat:SetString("$bumpmap", "dev/bump_normal")
						end
					end
				end
			end
		elseif T == "boolean" then	
			pac.GetSet(PART, name, false)
			
			PART["Set" .. name] = function(self, var)
				self[name] = var
				
				local mat = self:GetMaterialFromParent()
				
				if mat then
					mat:SetInt("$" .. name, var and 1 or 0) -- setint crashes?
				end
			end
		elseif T == "number" then
			pac.GetSet(PART, name, 0)
			
			PART["Set" .. name] = function(self, var)
				self[name] = var
				
				local mat = self:GetMaterialFromParent()
				
				if mat then
					mat:SetFloat("$" .. name, var)
				end
			end
		elseif T == "Vector" then
			local def = Vector(0,0,0)
			
			-- hack
			local key = name:lower()
			if key == "color" or key == "color2" then
				def = Vector(1,1,1)
			end
			
			pac.GetSet(PART, name, def)
			
			PART["Set" .. name] = function(self, var)
				self[name] = var
				
				local mat = self:GetMaterialFromParent()
				
				if mat then	
					if key == "color" or key == "color2" then
						timer.Simple(0.1, function() mat:SetVector("$" .. name, var) end)
					end
				
					mat:SetVector("$" .. name, var)
				end
			end
		end
	end
end

pac.StartStorableVars()
	setup(PART)
pac.EndStorableVars()


function PART:GetMaterialFromParent()
	if self:GetParent():IsValid() then
		--print(self.Materialm and self.Materialm:GetName(), self.Parent.Materialm:GetName(), self.last_mat and self.last_mat:GetName())
		if not self.Materialm then
			local mat = CreateMaterial("pac_material_" .. SysTime(), "VertexLitGeneric", {})
			
			if self.Parent.Materialm then
				local tex
				tex = self.Parent.Materialm:GetTexture("$bumpmap")
				if tex and not tex:IsError() then
					mat:SetTexture("$bumpmap", tex)
				end
				
				local tex = self.Parent.Materialm:GetTexture("$basetexture")
				if tex and not tex:IsError() then
					mat:SetTexture("$basetexture", tex)
				end
			end
			
			self.Materialm = mat
		end
		
		self.Parent.Materialm = self.Materialm
		
		return self.Materialm
	end
end

function PART:GetRawMaterial()
	if not self.Materialm then
		local mat = CreateMaterial("pac_material_" .. SysTime(), "VertexLitGeneric", {})
		self.Materialm = mat
	end
	
	return self.Materialm
end

function PART:OnParent(parent)
	self:GetMaterialFromParent()
end

function PART:UpdateMaterial(now)
	self:GetMaterialFromParent()
	for key, val in pairs(self.StorableVars) do
		if self.ShaderParams[key] then
			self["Set" .. key](self, self[key])
		end
	end
end

function PART:OnEvent(event, ...)
	if event == "material_changed" then
		self:UpdateMaterial()
	end
end

function PART:OnParent(parent)
	self:UpdateMaterial()
end

function PART:OnUnParent(parent)
	self.Materialm = nil
	self.updated = false
end

pac.RegisterPart(PART)