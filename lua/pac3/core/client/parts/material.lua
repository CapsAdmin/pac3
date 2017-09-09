local PART = {}

PART.ClassName = "material"
PART.NonPhysical = true
PART.Group = {'modifiers', 'model', 'entity'}
PART.Icon = 'icon16/paintcan.png'

local group_ordering = {
	{pattern = "phong", group = "phong"},
	{pattern = "envmap", group = "env map"},
	{pattern = {"ambientocclusion", "halflambert"}, group = "ambient occlusion"},
	{pattern = "detail", group = "detail"},
	{pattern = "rimlight", group = "rimlight"},
	{pattern = {"cloak", "refract"}, group = "cloak"},
	{pattern = "color", group = "colors"},
	{pattern = {"bumpmap", "basetexture", "^envmapmask$", "lightwarptexture"}, group = "textures"},
	{pattern = "flesh", group = "flesh"},
	{pattern = "selfillum", group = "selfillum"},
	{pattern = "emissive", group ="emissive"},
}

PART.ShaderParams =
{
	BaseTexture = "ITexture",

	CloakPassEnabled  = "boolean",
	CloakFactor = {type = "number", extra = {editor_sensitivity = 0.25, editor_clamp = {0, 1}}},
	CloakColorTint = "Vector",
	RefractAmount = "number",

	BumpMap = "ITexture",
	LightWarpTexture = "ITexture",

	Detail = "ITexture",
	DetailTint = "Vector",
	DetailScale = "number",
	DetailBlendMode = {type = "number", extra = {on_change = function(pnl, num) return math.Round(math.max(num, 0)) end}},
	DetailBlendFactor = "number",

	Phong = "boolean",
	PhongBoost = "number",
	PhongExponent = "number",
	PhongTint = "Vector",
	PhongFresnelRanges = {type = "Vector", extra = {editor_panel = "color"}},
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
	Additive = "boolean",
	AlphaTest = "boolean",
	TranslucentX = "boolean",


	HalfLambert = "boolean",

	Selfillum = "boolean",
	SelfillumTint = "Vector",
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

	DistanceAlpha = "number",
	VertexAlpha = "boolean",
	Alpha = "number",
}

function PART:OnThink()
	if self.delay_set and self.Parent then
		self.delay_set()
		self.delay_set = nil
	end
end

local function setup(PART)
	local sorted = {}
	for k,v in pairs(PART.ShaderParams) do
		table.insert(sorted, {k = k, v = v})
	end
	table.sort(sorted, function(a, b) return a.k > b.k end)

	for pass = 1, 2 do
		for _, info in ipairs(group_ordering) do
			for _, v in ipairs(sorted) do
				local name, T = v.k, v.v

				local found

				if type(info.pattern) == "table" then
					for k,v in pairs(info.pattern) do
						if name:lower():find(v) then
							found = true
							break
						end
					end
				else
					found = name:lower():find(info.pattern)
				end

				if pass == 1 then
					if found then
						pac.SetPropertyGroup(info.group)
					else
						continue
					end
				elseif pass == 2 then
					if not found then
						pac.SetPropertyGroup()
					else
						continue
					end
				end

				do
					local extra
					if type(T) == "table" then
						extra = T.extra
						T = T.type
					end
					if T == "ITexture" then
						pac.GetSet(PART, name, "", {editor_panel = "textures"})

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

									if tex then
										mat:SetTexture("$" .. name, tex)
									end
								else
									mat:SetUndefined("$" .. name)
								end
							end
						end
					elseif T == "boolean" then
						pac.GetSet(PART, name, false)

						PART["Set" .. name] = function(self, var)
							self[name] = var

							local mat = self:GetMaterialFromParent()

							if mat then
								if name == "TranslucentX" then
									name = "Translucent"
								end

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
		end
	end
end

local function add_transform(texture_name)
	local position_key = texture_name.."Position"
	local scale_key = texture_name.."Scale"
	local angle_key = texture_name.."Angle"
	local angle_center_key = texture_name.."AngleCenter"

	pac.GetSet(PART, position_key, Vector(0, 0, 0))
	pac.GetSet(PART, scale_key, Vector(1, 1, 1))
	pac.GetSet(PART, angle_key, 0, {editor_sensitivity = 0.25})
	pac.GetSet(PART, angle_center_key, Vector(0.5, 0.5, 0))

	PART.TransformVars = PART.TransformVars or {}
	PART.TransformVars[position_key] = true
	PART.TransformVars[scale_key] = true
	PART.TransformVars[angle_key] = true
	PART.TransformVars[angle_center_key] = true

	local shader_key = "$"..texture_name.."transform"

	local function setup_matrix(self)
		self.matrix = self.matrix or Matrix()
		self.translation_vector = self.translation_vector or Vector(0, 0, 0)
		self.rotation_angle = self.rotation_angle or Angle(0, 0, 0)

		self.matrix:Identity()
		self.matrix:Translate(self.translation_vector)

		self.matrix:Translate(self[angle_center_key])
		self.matrix:Rotate(self.rotation_angle)
		self.matrix:Translate(-self[angle_center_key])

		self.matrix:SetScale(self[scale_key])
	end

	PART["Set" .. position_key] = function(self, vec)
		self[position_key] = vec
		setup_matrix(self)

		self.translation_vector.x = self[position_key].x%1
		self.translation_vector.y = self[position_key].y%1

		self:GetRawMaterial():SetMatrix(shader_key, self.matrix)
	end

	PART["Set" .. scale_key] = function(self, vec)
		self[scale_key] = vec
		setup_matrix(self)

		self:GetRawMaterial():SetMatrix(shader_key, self.matrix)
	end

	PART["Set" .. angle_key] = function(self, num)
		self[angle_key] = num
		setup_matrix(self)

		self.rotation_angle.y = self[angle_key]*360

		self:GetRawMaterial():SetMatrix(shader_key, self.matrix)
	end

	PART["Set" .. angle_center_key] = function(self, vec)
		self[angle_center_key] = vec
		setup_matrix(self)

		self:GetRawMaterial():SetMatrix(shader_key, self.matrix)
	end

end


pac.StartStorableVars()

	setup(PART)
	add_transform("BaseTexture")
	--add_transform("Bump") -- doesn't work
	--add_transform("EnvMapMask")
pac.EndStorableVars()

function PART:GetMaterialFromParent()
	if self:GetParent():IsValid() then
		if not self.Materialm then
			local mat = CreateMaterial(pac.uid"pac_material_", "VertexLitGeneric", {})

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

function PART:SetTranslucent(b)
	self.Translucent = b
	self:UpdateMaterial()
end

function PART:GetRawMaterial()
	if not self.Materialm then
		local mat = CreateMaterial(pac.uid"pac_material_", "VertexLitGeneric", {})
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
		if self.ShaderParams[key] or self.TransformVars[key] then
			self["Set" .. key](self, self["Get"..key](self))
		end
	end

	local mat = self.Materialm
	local self = self

	pac.RunNextFrame("material translucent " .. self.Id, function()
		for key, part in pairs(pac.GetParts()) do
			if part.Materialm == mat and self ~= part then
				part.force_translucent = self.Translucent
			end
		end
	end)
end

function PART:OnRemove()
	local mat = self.Materialm
	local self = self

	pac.RunNextFrame("remove materials" .. self.Id, function()
		for key, part in pairs(pac.GetParts()) do
			if part.Materialm == mat and self ~= part then
				part.force_translucent = nil
				part.Materialm = nil
			end
		end
	end)
end

function PART:OnEvent(event, ...)
	if self.suppress_event then return end
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

function PART:OnHide()
	local parent = self:GetParent()

	if parent:IsValid() and parent.SetMaterial then
		self.suppress_event = true
		parent:SetMaterial(parent.Material)
		self.suppress_event = nil
	end
end

function PART:OnShow()
	self:UpdateMaterial()

	local name = self.Name

	pac.RunNextFrame("refresh materials" .. self.Id, function()
		for key, part in pairs(pac.GetParts()) do
			if part.Material and part.Material ~= "" and part.Material == name then
				part:SetMaterial(name)
			end
		end
	end)
end

pac.RegisterPart(PART)