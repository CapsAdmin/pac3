local LocalToWorld = LocalToWorld
local render_StartBeam = render.StartBeam
local render_AddBeam = render.AddBeam
local render_EndBeam = render.EndBeam
local color_white = color_white
local math_sin = math.sin
local math_pi = math.pi
local Angle = Angle
local Lerp = Lerp
local Vector = Vector
local Color = Color

-- feel free to use this wherever!
do
	local ax,ay,az = 0,0,0
	local bx,by,bz = 0,0,0
	local adx,ady,adz = 0,0,0
	local bdx,bdy,bdz = 0,0,0

	local frac = 0
	local wave = 0
	local bendmult = 0

	local vector = Vector()
	local color = Color(255, 255, 255, 255)

	function pac.DrawBeam(veca, vecb, dira, dirb, bend, res, width, start_color, end_color, frequency, tex_stretch, tex_scroll, width_bend, width_bend_size, width_start_mul, width_end_mul)

		if not veca or not vecb or not dira or not dirb then return end

		ax = veca.x; ay = veca.y; az = veca.z
		bx = vecb.x; by = vecb.y; bz = vecb.z

		adx = dira.x; ady = dira.y; adz = dira.z
		bdx = dirb.x; bdy = dirb.y; bdz = dirb.z

		bend = bend or 10
		res = math.max(res or 32, 2)
		width = width or 10
		start_color = start_color or color_white
		end_color = end_color or color_white
		frequency = frequency or 1
		tex_stretch = tex_stretch or 1
		width_bend = width_bend or 0
		width_bend_size = width_bend_size or 1
		tex_scroll = tex_scroll or 0
		width_start_mul = width_start_mul or 1
		width_end_mul = width_end_mul or 1

		render_StartBeam(res + 1)

			for i = 0, res do

				frac = i / res
				wave = frac * math_pi * frequency
				bendmult = math_sin(wave) * bend

				vector.x = Lerp(frac, ax, bx) + Lerp(frac, adx * bendmult, bdx * bendmult)
				vector.y = Lerp(frac, ay, by) + Lerp(frac, ady * bendmult, bdy * bendmult)
				vector.z = Lerp(frac, az, bz) + Lerp(frac, adz * bendmult, bdz * bendmult)

				color.r = start_color.r == end_color.r and start_color.r or Lerp(frac, start_color.r, end_color.r)
				color.g = start_color.g == end_color.g and start_color.g or Lerp(frac, start_color.g, end_color.g)
				color.b = start_color.b == end_color.b and start_color.b or Lerp(frac, start_color.b, end_color.b)
				color.a = start_color.a == end_color.a and start_color.a or Lerp(frac, start_color.a, end_color.a)

				render_AddBeam(
					vector,
					(width + ((math_sin(wave) ^ width_bend_size) * width_bend)) * Lerp(frac, width_start_mul, width_end_mul),
					(i / tex_stretch) + tex_scroll,
					color
				)

			end

		render_EndBeam()
	end
end

local BUILDER, PART = pac.PartTemplate("base_drawable")

PART.ClassName = "beam"
PART.Group = 'effects'
PART.Icon = 'icon16/vector.png'

BUILDER:StartStorableVars()
	BUILDER:SetPropertyGroup("generic")
		BUILDER:PropertyOrder("Name")
		BUILDER:PropertyOrder("Hide")
		BUILDER:PropertyOrder("ParentName")
		BUILDER:GetSet("Material", "cable/rope")
		BUILDER:GetSetPart("EndPoint")
		BUILDER:GetSet("Bend", 10)
		BUILDER:GetSet("Frequency", 1)
		BUILDER:GetSet("Resolution", 16)
		BUILDER:GetSet("Width", 1)
		BUILDER:GetSet("WidthBend", 0)
		BUILDER:GetSet("WidthBendSize", 1)
		BUILDER:GetSet("StartWidthMultiplier", 1)
		BUILDER:GetSet("EndWidthMultiplier", 1)
		BUILDER:GetSet("TextureStretch", 1)
		BUILDER:GetSet("TextureScroll", 0)
	BUILDER:SetPropertyGroup("orientation")
	BUILDER:SetPropertyGroup("appearance")
		BUILDER:GetSet("StartColor", Vector(255, 255, 255), {editor_panel = "color"})
		BUILDER:GetSet("EndColor", Vector(255, 255, 255), {editor_panel = "color"})
		BUILDER:GetSet("StartAlpha", 1)
		BUILDER:GetSet("EndAlpha", 1)
	BUILDER:SetPropertyGroup("other")
		BUILDER:PropertyOrder("DrawOrder")
BUILDER:EndStorableVars()

function PART:GetNiceName()
	local found = ("/" .. self:GetMaterial()):match(".*/(.+)")
	return found and pac.PrettifyName(found:gsub("%..+", "")) or "error"
end

function PART:Initialize()
	self:SetMaterial(self.Material)

	self.StartColorC = Color(255, 255, 255, 255)
	self.EndColorC = Color(255, 255, 255, 255)
end

function PART:SetStartColor(v)
	self.StartColorC = self.StartColorC or Color(255, 255, 255, 255)

	self.StartColorC.r = v.r
	self.StartColorC.g = v.g
	self.StartColorC.b = v.b

	self.StartColor = v
end

function PART:SetEndColor(v)
	self.EndColorC = self.EndColorC or Color(255, 255, 255, 255)

	self.EndColorC.r = v.r
	self.EndColorC.g = v.g
	self.EndColorC.b = v.b

	self.EndColor = v
end

function PART:SetStartAlpha(n)
	self.StartColorC = self.StartColorC or Color(255, 255, 255, 255)

	self.StartColorC.a = n * 255

	self.StartAlpha = n
end

function PART:SetEndAlpha(n)
	self.EndColorC = self.EndColorC or Color(255, 255, 255, 255)

	self.EndColorC.a = n * 255

	self.EndAlpha = n
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

			self.Materialm = CreateMaterial(tostring(self) .. "_pac_trail", "UnlitGeneric", params)
		end
	end
end

function PART:SetMaterial(var)
	var = var or ""

	self.Material = var

	if not pac.Handleurltex(self, var) then
		if isstring(var) then
			self.Materialm = pac.Material(var, self)
			self:FixMaterial()
			self:CallRecursive("OnMaterialChanged")
		elseif type(var) == "IMaterial" then
			self.Materialm = var
			self:FixMaterial()
			self:CallRecursive("OnMaterialChanged")
		end
	end
end

function PART:OnDraw()
	local part = self.EndPoint

	if self.Materialm and self.StartColorC and self.EndColorC and part:IsValid() and part.GetWorldPosition then
		local pos, ang = self:GetDrawPosition()
		render.SetMaterial(self.Materialm)
		pac.DrawBeam(
			pos,
			part:GetWorldPosition(),

			ang:Forward(),
			part:GetWorldAngles():Forward(),

			self.Bend,
			math.Clamp(self.Resolution, 1, 256),
			self.Width,
			self.StartColorC,
			self.EndColorC,
			self.Frequency,
			self.TextureStretch,
			self.TextureScroll,
			self.WidthBend,
			self.WidthBendSize,
			self.StartWidthMultiplier,
			self.EndWidthMultiplier
		)
	end
end

BUILDER:Register()
