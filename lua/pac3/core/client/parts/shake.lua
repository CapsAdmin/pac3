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
		
		local amplitude = (self.Falloff and (1 - (eyedistance / radius) ^ 2) * self.Amplitude) or (eyedistance < radius and self.Amplitude or 0)

		util.ScreenShake(position, amplitude, self.Frequency, math.Clamp(self.Duration, 0.0001, 2), 0)
	end
end

BUILDER:Register()