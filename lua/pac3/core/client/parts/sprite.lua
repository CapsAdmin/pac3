local render_SetMaterial = render.SetMaterial
local render_DrawSprite = render.DrawSprite
local Color = Color
local Vector = Vector
local cam_IgnoreZ = cam.IgnoreZ

local PART = {}

PART.ClassName = "sprite"
PART.Group = 'effects'
PART.Icon = 'icon16/layers.png'

pac.StartStorableVars()
	pac.SetPropertyGroup()
		pac.GetSet(PART, "IgnoreZ", false)
		pac.GetSet(PART, "SizeX", 1, {editor_sensitivity = 0.25})
		pac.GetSet(PART, "SizeY", 1, {editor_sensitivity = 0.25})
		pac.GetSet(PART, "SpritePath", "sprites/grip", {editor_panel = "material"})

	pac.SetPropertyGroup(PART, "orientation")
		pac.GetSet(PART, "Size", 1, {editor_sensitivity = 0.25})

	pac.SetPropertyGroup(PART, "appearance")
		pac.GetSet(PART, "Color", Vector(255, 255, 255), {editor_panel = "color"})
		pac.GetSet(PART, "Alpha", 1, {editor_sensitivity = 0.25, editor_clamp = {0, 1}})
		pac.GetSet(PART, "Translucent", true)
pac.EndStorableVars()

function PART:GetNiceName()
	if not self:GetSpritePath() then
		return "error"
	end

	local match = pac.PrettifyName("/" .. self:GetSpritePath()):match(".+/(.+)")
	return match and match:gsub("%..+", "") or "error"
end

function PART:SetColor(v)
	self.ColorC = self.ColorC or Color(255, 255, 255, 255)

	self.ColorC.r = v.r
	self.ColorC.g = v.g
	self.ColorC.b = v.b

	self.Color = v
end

function PART:SetAlpha(n)
	self.ColorC = self.ColorC or Color(255, 255, 255, 255)

	self.ColorC.a = n * 255

	self.Alpha = n
end

function PART:Initialize()
	self:SetSpritePath(self.SpritePath)
end

function PART:SetSpritePath(var)
	self:SetMaterial(var)
end

function PART:FixMaterial()
	local mat = self.Materialm

	if not mat then return end

	local shader = mat:GetShader()

	if shader == "VertexLitGeneric" or shader == "Cable" then
		local tex_path = mat:GetTexture("$basetexture")

		if tex_path then
			local params = {}

			params["$basetexture"] = tex_path:GetName()
			params["$vertexcolor"] = 1
			params["$vertexalpha"] = 1

			self.Materialm = CreateMaterial("pac_fixmat_" .. os.clock(), "UnlitGeneric", params)
			self.Materialm:SetTexture("$basetexture", tex_path)
		end
	end
end

function PART:SetMaterial(var)
	var = var or ""

	if not pac.Handleurltex(self, var, nil, "UnlitGeneric", {["$translucent"] = "1"}) then
		if type(var) == "string" then
			self.Materialm = pac.Material(var, self)
			self:CallEvent("material_changed")
		elseif type(var) == "IMaterial" then
			self.Materialm = var
			self:CallEvent("material_changed")
		end
	end

	self:FixMaterial()

	self.SpritePath = var
end

function PART:OnDraw(owner, pos, ang)
	local mat = self.MaterialOverride or self.Materialm
	if mat then
		if self.IgnoreZ then
			cam_IgnoreZ(true)
		end

		render_SetMaterial(mat)
		render_DrawSprite(pos, self.SizeX * self.Size, self.SizeY * self.Size, self.ColorC)

		if self.IgnoreZ then
			cam_IgnoreZ(false)
		end
	end
end

function PART:OnRestore(data)
	self:SetMaterial(data.SpritePath)
end

pac.RegisterPart(PART)
