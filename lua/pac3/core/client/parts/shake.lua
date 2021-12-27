local BUILDER, PART = pac.PartTemplate("base_movable")

PART.ClassName = "shake"
PART.Group = 'effects'
PART.Icon = 'icon16/transmit.png'

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
		local radius = math.Clamp(self.Radius, 0.0001, 500)

		if eyedistance < radius then
			local amplitude = self.Amplitude
			if self.Falloff then
				amplitude = amplitude * (1 - (eyedistance / radius))
			end
			util.ScreenShake(position, amplitude, self.Frequency, math.Clamp(self.Duration, 0.0001, 2), 0)
		end
	end
end

BUILDER:Register()