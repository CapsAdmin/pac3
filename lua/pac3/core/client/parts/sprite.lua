local render_SetMaterial = render.SetMaterial
local render_DrawSprite = render.DrawSprite
local Color = Color
local Vector = Vector
local cam_IgnoreZ = cam.IgnoreZ

local PART = {}

PART.ClassName = "sprite"

pac.StartStorableVars()
	pac.GetSet(PART, "SizeX", 1)
	pac.GetSet(PART, "SizeY", 1)
	pac.GetSet(PART, "Size", 1)
	pac.GetSet(PART, "Color", Vector(255, 255, 255))
	pac.GetSet(PART, "Alpha", 1)
	pac.GetSet(PART, "SpritePath", "sprites/grip")
	pac.GetSet(PART, "Translucent", true)
	pac.GetSet(PART, "IgnoreZ", false)
pac.EndStorableVars()

function PART:GetNiceName()
	return pac.PrettifyName(("/" .. self:GetSpritePath()):match(".+/(.+)"):gsub("%..+", "")) or "error"
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
		local tex_path = mat:GetString("$basetexture")

		if tex_path then
			local params = {}

			params["$basetexture"] = tex_path
			params["$vertexcolor"] = 1
			params["$vertexalpha"] = 1

			self.Materialm = CreateMaterial("pac_fixmat_" .. os.clock(), "VertexLitGeneric", params)
		end
	end
end

function PART:SetMaterial(var)
	var = var or ""

	if not pac.Handleurltex(self, var) then
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
	if self.Materialm then
		if self.IgnoreZ then
			cam_IgnoreZ(true)
		end

		render_SetMaterial(self.Materialm)
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