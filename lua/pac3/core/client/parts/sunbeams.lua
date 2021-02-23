local ScrW = ScrW
local ScrH = ScrH
local DrawSunbeams

local BUILDER, PART = pac.PartTemplate("base_drawable")

PART.ClassName = "sunbeams"
PART.Group = 'effects'
PART.Icon = 'icon16/weather_sun.png'

BUILDER:StartStorableVars()
	BUILDER:GetSet("Darken", 0)
	BUILDER:GetSet("Multiplier", 0.25, {editor_sensitivity = 0.25})
	BUILDER:GetSet("Size", 0.1, {editor_sensitivity = 0.25})
	BUILDER:GetSet("Translucent", true)
BUILDER:EndStorableVars()

function PART:GetNiceName()
	local mult = self:GetMultiplier()
	return mult > 0 and "bright sunbeams" or mult < 0 and "dark sunbeams" or self.ClassName
end

function PART:OnDraw()
	if not DrawSunbeams then DrawSunbeams = _G.DrawSunbeams end

	cam.Start2D()
	local pos = self:GetDrawPosition()
	local spos = pos:ToScreen()

	local dist_mult = - math.Clamp(pac.EyePos:Distance(pos) / 1000, 0, 1) + 1

	DrawSunbeams(
		self.Darken,
		dist_mult * self.Multiplier * (math.Clamp(pac.EyeAng:Forward():Dot((pos - pac.EyePos):GetNormalized()) - 0.5, 0, 1) * 2) ^ 5,
		self.Size,
		spos.x / ScrW(),
		spos.y / ScrH()
	)
	cam.End2D()
end

BUILDER:Register()