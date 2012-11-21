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
	EnvMapContrast = "number",
	EnvMapSaturation = "Vector",
	EnvMapMode = "number",
	
	AmbientOcclusion = "boolean",
	AmbientOcclusionColor = "Vector",
	AmbientOcclusionTexture = "ITexture",
	
	BlendTintByBaseAlpha = "boolean", 
	BlendTintColorOverbase = "boolean",  
	ColorTint_Base = "Vector",
	ColorTint_Tmp = "Vector",
	Color2 = "Vector",
	
	--[[Selfillum = "boolean",
	SelillumTint = "Vector",
	SelfillumMask = "ITexture",
	Selfillum_Envmapmask_Alpha = "ITexture",
	SelfillumFresnel = "boolean",
	SelfillumFresnlenMinMaxExp = "Vector",]]
	
	HalfLambert = "boolean",
	
	--[[EmissiveBlendEnabled = "boolean",
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
					pac.HandleUrlMat(
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
			pac.GetSet(PART, name, Vector(0,0,0))
			
			PART["Set" .. name] = function(self, var)
				self[name] = var
				
				local mat = self:GetMaterialFromParent()
				
				if mat then
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

function PART:OnParent(parent)
	self:GetMaterialFromParent()
end

function PART:UpdateMaterial(now)
	self:GetMaterialFromParent()
	for key, val in pairs(self.StorableVars) do
		self["Set" .. key](self, self[key])
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