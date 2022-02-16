local cam_Start3D = cam.Start3D
local cam_Start3D2D = cam.Start3D2D
local EyePos = EyePos
local EyeAngles = EyeAngles
local draw_SimpleTextOutlined = draw.SimpleTextOutlined
local DisableClipping = DisableClipping
local render_CullMode = render.CullMode
local cam_End3D2D = cam.End3D2D
local cam_End3D = cam.End3D
local TEXT_ALIGN_CENTER = TEXT_ALIGN_CENTER
local surface_SetFont = surface.SetFont
local Color = Color

local BUILDER, PART = pac.PartTemplate("base_drawable")

PART.ClassName = "text"
PART.Group = 'effects'
PART.Icon = 'icon16/text_align_center.png'

BUILDER:StartStorableVars()
	BUILDER:GetSet("Text", "")
	BUILDER:GetSet("Font", "default")
	BUILDER:GetSet("Size", 1, {editor_sensitivity = 0.25})
	BUILDER:GetSet("Outline", 0)
	BUILDER:GetSet("Color", Vector(255, 255, 255), {editor_panel = "color"})
	BUILDER:GetSet("Alpha", 1, {editor_sensitivity = 0.25, editor_clamp = {0, 1}})
	BUILDER:GetSet("OutlineColor", Vector(255, 255, 255), {editor_panel = "color"})
	BUILDER:GetSet("OutlineAlpha", 1, {editor_onchange = function(self, num)
		self.sens = 0.25
		num = tonumber(num)
		return math.Clamp(num, 0, 1)
	end})
	BUILDER:GetSet("Translucent", true)
BUILDER:EndStorableVars()

function PART:GetNiceName()
	return '"' .. self:GetText() .. '"'
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

function PART:SetOutlineColor(v)
	self.OutlineColorC = self.OutlineColorC or Color(255, 255, 255, 255)

	self.OutlineColorC.r = v.r
	self.OutlineColorC.g = v.g
	self.OutlineColorC.b = v.b

	self.OutlineColor = v
end

function PART:SetOutlineAlpha(n)
	self.OutlineColorC = self.OutlineColorC or Color(255, 255, 255, 255)
	self.OutlineColorC.a = n * 255

	self.OutlineAlpha = n
end

function PART:SetFont(str)
	if not pcall(surface_SetFont, str) then
		str = "DermaDefault"
	end

	self.Font = str
end

function PART:OnDraw()
	local pos, ang = self:GetDrawPosition()

	if self.Text ~= "" then
		cam_Start3D(EyePos(), EyeAngles())
			cam_Start3D2D(pos, ang, self.Size)
			local oldState = DisableClipping(true)

			draw_SimpleTextOutlined(self.Text, self.Font, 0,0, self.ColorC, TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER, self.Outline, self.OutlineColorC)
			render_CullMode(1) -- MATERIAL_CULLMODE_CW

			draw_SimpleTextOutlined(self.Text, self.Font, 0,0, self.ColorC, TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER, self.Outline, self.OutlineColorC)
			render_CullMode(0) -- MATERIAL_CULLMODE_CCW

			DisableClipping(oldState)
			cam_End3D2D()
		cam_End3D()
	end
end

function PART:SetText(str)
	self.Text = str
end

BUILDER:Register()
