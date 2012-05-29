local PART = {}

PART.ClassName = "light"

pac.StartStorableVars()
	pac.GetSet(PART, "Color", Vector(255, 255, 255))
	pac.GetSet(PART, "Brightness", 1)
	pac.GetSet(PART, "Size", 10)
pac.EndStorableVars()

function PART:OnDraw(owner, pos, ang)
	local params = DynamicLight()
	if params then
		params.Pos = pos
		params.r = self.Color.r
		params.g = self.Color.g
		params.b = self.Color.b
		params.Brightness = self.Brightness
		params.Size = self.Size
		params.Decay = 0
		params.DieTime = CurTime() + 0.5
	end
end

pac.RegisterPart(PART)