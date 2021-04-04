local BUILDER, PART = pac.PartTemplate("base_drawable")

PART.FriendlyName = "legacy light"
PART.ClassName = "light"
PART.Group = "legacy"

PART.Icon = 'icon16/lightbulb.png'

BUILDER:StartStorableVars()
	BUILDER:GetSet("Brightness", 1)
	BUILDER:GetSet("Size", 5, {editor_sensitivity = 0.25})
	BUILDER:GetSet("Style", 0, {editor_clamp = {0, 16}})
	BUILDER:GetSet("Color", Vector(255, 255, 255), {editor_panel = "color"})
BUILDER:EndStorableVars()

function PART:GetNiceName()
	local hue = pac.ColorToNames(self:GetColor())
	return hue .. " light"
end

local DynamicLight = DynamicLight

function PART:OnDraw()
	local pos = self:GetDrawPosition()
	local light = self.light or DynamicLight(tonumber(self.UniqueID))

	light.Pos = pos

	light.MinLight = self.Brightness
	light.Size = self.Size
	light.Style = self.Style

	light.r = self.Color.r
	light.g = self.Color.g
	light.b = self.Color.b

	-- 100000000 constant is better than calling pac.RealTime
	light.DieTime = 1000000000000 -- pac.RealTime

	self.light = light
end

function PART:OnHide()
	local light = self.light
	if light then
		light.DieTime = 0
		light.Size = 0
		light.MinLight = 0
		light.Pos = Vector()
	end
end

BUILDER:Register()