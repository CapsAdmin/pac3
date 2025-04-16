local ScrW = ScrW
local ScrH = ScrH
local DrawSunbeams

local BUILDER, PART = pac.PartTemplate("base_drawable")

PART.ClassName = "sunbeams"
PART.Group = 'effects'
PART.Icon = 'icon16/weather_sun.png'
local draw_distance = CreateClientConVar("pac_limit_sunbeams_draw_distance", "1000", true, false)


BUILDER:StartStorableVars()
		BUILDER:GetSet("Darken", 0)
		BUILDER:GetSet("Multiplier", 0.25, {editor_sensitivity = 0.25})
		BUILDER:GetSet("Size", 0.1, {editor_sensitivity = 0.25})
		BUILDER:GetSet("DrawDistance", 1000, {editor_onchange = function(self, val) return math.max(val,0) end})
		BUILDER:GetSet("Translucent", true)

	BUILDER:SetPropertyGroup("Showtime dynamics")
		BUILDER:GetSet("EnableDynamics", false, {description = "If you want to make a fading effect, you can do it here instead of adding proxies.\nThe multiplier parts work multiplicatively, involving 3 terms: attack * multiplier * fade\nThe darken part works additively. It can add more darken on top of the existing darken value"})
		BUILDER:GetSet("EndMultiplier", 1)
		BUILDER:GetSet("StartMultiplier", 1)
		BUILDER:GetSet("MultiplierFadePower", 1)
		BUILDER:GetSet("MultiplierFadeSpeed", 1)
		BUILDER:GetSet("MultiplierAttack", 0, {description = "Additional fade-in time to optionally soften the flash. This is in terms of normalized speed"})

		BUILDER:GetSet("EndDarken", 0)
		BUILDER:GetSet("StartDarken", 0)
		BUILDER:GetSet("DarkenFadeSpeed", 1)
		BUILDER:GetSet("DarkenFadePower", 1)

BUILDER:EndStorableVars()

function PART:GetNiceName()
	local mult = self:GetMultiplier()
	return mult > 0 and "bright sunbeams" or mult < 0 and "dark sunbeams" or self.ClassName
end

function PART:OnShow()
	self.starttime = CurTime()
end

function PART:OnDraw()
	if not DrawSunbeams then DrawSunbeams = _G.DrawSunbeams end

	cam.Start2D()
	local pos = self:GetDrawPosition()
	local spos = pos:ToScreen()

	--clamp down the part's requested values with the viewer client's cvar
	local distance = math.min(self.DrawDistance, math.max(draw_distance:GetInt(),0.1))

	local dist_mult = - math.Clamp(pac.EyePos:Distance(pos) / distance, 0, 1) + 1

	if self.EnableDynamics then
		local lifetime = (CurTime() - self.starttime)

		local init_mult = 1
		if self.MultiplierAttack > 0 then init_mult = math.Clamp(lifetime*self.MultiplierAttack,0,1) end

		local fade_factor_m = math.Clamp(lifetime*self.MultiplierFadeSpeed,0,1)
		local fade_factor_d = math.Clamp(lifetime*self.DarkenFadeSpeed,0,1)
		local final_mult_mult = self.EnableDynamics and
			self.StartMultiplier + (self.EndMultiplier - self.StartMultiplier) * math.pow(fade_factor_m,self.MultiplierFadePower)
			or self.Multiplier

		local final_darken_add = self.EnableDynamics and
			self.StartDarken + (self.EndDarken - self.StartDarken) * math.pow(fade_factor_d,self.DarkenFadePower)
			or 0

		DrawSunbeams(
			self.Darken + final_darken_add,
			dist_mult * init_mult * self.Multiplier * final_mult_mult * (math.Clamp(pac.EyeAng:Forward():Dot((pos - pac.EyePos):GetNormalized()) - 0.5, 0, 1) * 2) ^ 5,
			self.Size,
			spos.x / ScrW(),
			spos.y / ScrH()
		)
	else
		DrawSunbeams(
			self.Darken,
			dist_mult * self.Multiplier * (math.Clamp(pac.EyeAng:Forward():Dot((pos - pac.EyePos):GetNormalized()) - 0.5, 0, 1) * 2) ^ 5,
			self.Size,
			spos.x / ScrW(),
			spos.y / ScrH()
		)
	end
	cam.End2D()
end

BUILDER:Register()