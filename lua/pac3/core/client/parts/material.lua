local PART = {}

PART.ClassName = "material"
PART.HideGizmo = true

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
	PhongExpontent = "number",
	PhongTint = "Vector",
	PhongFresnelRanges = "Vector",
	PhongWarpTexture = "ITexture",
	PhongAlbedoTint = "boolean",
	PhongExponentTexture = "ITexture",
	
	Rimlight = "boolean",	
	RimlightBoost = "number",	
	RimlightExponent = "number",
	
	EnvMap = "ITexture",
	EnvMapMask = "ITexture",
	EnvMapTint = "Vector",
	EnvMapContrast = "number",
	EnvMapSaturation = "Vector",
	EnvMapMode = "number",
	
	--[[EmissiveBlendEnabled = "boolean",
	EmissiveBlendTexture = "ITexture",
	EmissiveBlendBaseTexture = "ITexture",
	EmissiveBlendFlowTexture = "ITexture",
	EmissiveBlendTint = "Vector",
	EmissiveBlendScrollVector = "Vector",
	
	HalfLambert = "boolean",]]
}

local function setup(PART)
	for name, T in pairs(PART.ShaderParams) do		
		if T == "ITexture" then
			pac.GetSet(PART, name, "")

			PART["Set" .. name] = function(self, var)
				self[name] = var
				
				local mat = self:GetMaterialFromParent()
				
				if mat then				
					if pac.urlmat and var:find("http") then
						var = var:gsub("https://", "http://")
						var = var:match("http[s]-://.+/.-%.%a+")
						if var then
							pac.urlmat.GetMaterialFromURL(
								var, 
								function(_, tex)
									if self:IsValid() then
										mat:SetMaterialTexture("$" .. name, tex)
										pac.dprint("set custom material texture %q to %s", var, name)
									end
								end,
								false
							)
							return
						end
					end	
					
					if var ~= "" then
						local _mat = Material(var)
						local tex = _mat:GetMaterialTexture("$" .. name)
						
						if not tex or tex:IsError() then
							tex = CreateMaterial("pac3_tex_" .. var .. "_" .. self.Id, "VertexLitGeneric", {["$basetexture"] = var}):GetMaterialTexture("$basetexture")
							if not tex or tex:IsError() then
								tex = _mat:GetMaterialTexture("$basetexture")
							end
						end
						
						mat:SetMaterialTexture("$" .. name, tex)
					else
						if name == "BumpMap" then
							self:SetBumpMap("dev/bump_normal")
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
					mat:SetMaterialInt("$" .. name, var and 1 or 0)
				end
			end
		elseif T == "number" then
			pac.GetSet(PART, name, 0)
			
			PART["Set" .. name] = function(self, var)
				self[name] = var
				
				local mat = self:GetMaterialFromParent()
				
				if mat then
					mat:SetMaterialFloat("$" .. name, var)
				end
			end
		elseif T == "Vector" then
			pac.GetSet(PART, name, Vector(0,0,0))
			
			PART["Set" .. name] = function(self, var)
				self[name] = var
				
				local mat = self:GetMaterialFromParent()
				
				if mat then
					mat:SetMaterialVector("$" .. name, var)
				end
			end
		end
	end
end

function PART:Initialize()
	self.StorableVars = {}

	pac.StartStorableVars()
		pac.GetSet(self, "Name", "")
		pac.GetSet(self, "Description", "")
		pac.GetSet(self, "OwnerName", "")
		pac.GetSet(self, "ParentName", "")
		pac.GetSet(self, "EditorExpand", false)
		--pac.GetSet(self, "CloakColorAlpha", 0)
		setup(self)
	pac.EndStorableVars()
end

function PART:GetMaterialFromParent()
	if self.Parent:IsValid() and self.Parent.Materialm then
		--print(self.Materialm and self.Materialm:GetName(), self.Parent.Materialm:GetName(), self.last_mat and self.last_mat:GetName())
		if not self.Materialm then
			local mat = CreateMaterial("pac_material_" .. SysTime(), "VertexLitGeneric", {})
			
			local tex = self.Parent.Materialm:GetMaterialTexture("$bumpmap")
			if tex and not tex:IsError() then
				mat:SetMaterialTexture("$bumpmap", tex)
			end
			
			local tex = self.Parent.Materialm:GetMaterialTexture("$basetexture")
			if tex and not tex:IsError() then
				mat:SetMaterialTexture("$basetexture", tex)
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