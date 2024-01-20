local BUILDER, PART = pac.PartTemplate("base_movable")

PART.ClassName = "shake"
PART.Group = 'effects'
PART.Icon = 'icon16/transmit.png'

local draw_distance = CreateClientConVar("pac_limit_shake_draw_distance", "500", true, false)
local max_duration = CreateClientConVar("pac_limit_shake_duration", "2", true, false)
local max_amplitude = CreateClientConVar("pac_limit_shake_amplitude", "40", true, false)

BUILDER:StartStorableVars()
	BUILDER:SetPropertyGroup("generic")
	BUILDER:SetPropertyGroup("shake")
		BUILDER:GetSet("Amplitude", 1)
		BUILDER:GetSet("Falloff", false)
		BUILDER:GetSet("Frequency", 1)
		BUILDER:GetSet("Duration", 0.5)
		BUILDER:GetSet("Radius", 100)
BUILDER:EndStorableVars()

function PART:OnShow(from_rendering)
	if not from_rendering then
		local position = self:GetDrawPosition()
		local eyedistance = position:Distance(pac.EyePos)

		--clamp down the part's requested values with the viewer client's cvar
		local radius = math.Clamp(self.Radius, 0.0001, math.max(draw_distance:GetInt(),0.0001))
		local duration = math.Clamp(self.Duration, 0.0001, max_duration:GetInt())
		local amplitude = math.Clamp(self.Amplitude, 0.0001, max_amplitude:GetInt())

		if eyedistance < radius then
			local amplitude = self.Amplitude
			if self.Falloff then
				amplitude = amplitude * (1 - (eyedistance / radius))
			end
			util.ScreenShake(position, amplitude, self.Frequency, duration, 0)
		end
	end
end

BUILDER:Register()