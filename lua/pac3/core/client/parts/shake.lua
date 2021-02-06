local BUILDER, PART = pac.PartTemplate("base_movable")

PART.ClassName = "shake"

PART.Group = 'effects'
PART.Icon = 'icon16/transmit.png'

BUILDER:StartStorableVars()
	BUILDER:GetSet("Amplitude", 1)
	BUILDER:GetSet("Frequency", 1)
	BUILDER:GetSet("Duration", 0.5)
	BUILDER:GetSet("Radius", 100)
BUILDER:EndStorableVars()

function PART:OnShow(from_rendering)
	if not from_rendering then
		util.ScreenShake(self:GetDrawPosition(), self.Amplitude, self.Frequency, math.Clamp(self.Duration, 0.0001, 2), math.Clamp(self.Radius, 0.0001, 500))
	end
end

BUILDER:Register()