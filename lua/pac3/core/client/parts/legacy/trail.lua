local Lerp = Lerp
local tonumber = tonumber
local table_insert = table.insert
local table_remove = table.remove
local math_ceil = math.ceil
local math_abs = math.abs
local render_StartBeam = render.StartBeam
local cam_IgnoreZ = cam.IgnoreZ
local render_EndBeam = render.EndBeam
local render_AddBeam = render.AddBeam
local render_SetMaterial = render.SetMaterial

local BUILDER, PART = pac.PartTemplate("base_drawable")

PART.FriendlyName = "legacy trail"
PART.ClassName = "trail"
PART.Group = "legacy"

PART.Icon = 'icon16/arrow_undo.png'

BUILDER:StartStorableVars()
	BUILDER:SetPropertyGroup("generic")
		BUILDER:PropertyOrder("Name")
		BUILDER:PropertyOrder("Hide")
		BUILDER:PropertyOrder("ParentName")
		BUILDER:GetSet("TrailPath", "trails/laser", {editor_panel = "material"})
		BUILDER:GetSet("StartSize", 3)
		BUILDER:GetSet("EndSize", 0)
		BUILDER:GetSet("Length", 100)
		BUILDER:GetSet("Spacing", 1)

	BUILDER:SetPropertyGroup("orientation")
	BUILDER:SetPropertyGroup("appearance")
		BUILDER:GetSet("StartColor", Vector(255, 255, 255), {editor_panel = "color"})
		BUILDER:GetSet("EndColor", Vector(255, 255, 255), {editor_panel = "color"})
		BUILDER:GetSet("StartAlpha", 1)
		BUILDER:GetSet("EndAlpha", 1)
		BUILDER:PropertyOrder("Translucent")
		BUILDER:GetSet("Stretch", false)
	BUILDER:SetPropertyGroup("other")
		BUILDER:PropertyOrder("DrawOrder")
BUILDER:EndStorableVars()

function PART:GetNiceName()
	local str = pac.PrettifyName("/" .. self:GetTrailPath())
	local matched = str and str:match(".+/(.+)")
	return matched and matched:gsub("%..+", "") or "error"
end

PART.LastAdd = 0

function PART:Initialize()
	self:SetTrailPath(self.TrailPath)

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

function PART:SetTrailPath(var)
	self.TrailPath = var
	self:SetMaterial(var)
end

function PART:SetMaterial(var)
	var = var or ""

	if not pac.Handleurltex(self, var) then
		if isstring(var) then
			self.Materialm = pac.Material(var, self)
			self:CallRecursive("OnMaterialChanged")
		elseif type(var) == "IMaterial" then
			self.Materialm = var
			self:CallRecursive("OnMaterialChanged")
		end
	end

	if self.Materialm then
		local shader = self.Materialm:GetShader()
		if shader == "VertexLitGeneric" or shader == "Cable" or shader == "LightmappedGeneric" then
			self.Materialm = pac.MakeMaterialUnlitGeneric(self.Materialm, self.Id)
		end
	end
end

function PART:OnShow()
	self.points = {}
end

function PART:OnHide()
	self.points = {}
end

local temp_color = Color(255, 255, 255)

function PART:OnDraw()
	local mat = self.MaterialOverride or self.Materialm

	if mat and self.StartColorC and self.EndColorC then
		self.points = self.points or {}

		local len = tonumber(self.Length)
		local spc = tonumber(self.Spacing)

		local pos, ang = self:GetDrawPosition()

		if spc == 0 or self.LastAdd < pac.RealTime then
			table_insert(self.points, pos)
			self.LastAdd = pac.RealTime + spc / 1000
		end

		local count = #self.points

		if spc > 0 then
			len = math_ceil(math_abs(len - spc))
		end

		render_SetMaterial(mat)

		render_StartBeam(count)
			for k, v in pairs(self.points) do
				local width = k / (len / self.StartSize)

				local coord = (1 / count) * (k - 1)

				temp_color.r = Lerp(coord, self.EndColorC.r, self.StartColorC.r)
				temp_color.g = Lerp(coord, self.EndColorC.g, self.StartColorC.g)
				temp_color.b = Lerp(coord, self.EndColorC.b, self.StartColorC.b)
				temp_color.a = Lerp(coord, self.EndColorC.a, self.StartColorC.a)

				render_AddBeam(k == count and pos or v, width + self.EndSize, self.Stretch and coord or width, temp_color)
			end
		render_EndBeam()

		if count >= len then
			table_remove(self.points, 1)
		end
	end
end

BUILDER:Register()