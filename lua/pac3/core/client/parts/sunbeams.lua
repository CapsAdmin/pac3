local PART = {}

PART.ClassName = "sunbeams"

pac.StartStorableVars()
	pac.GetSet(PART, "Darken", 0)
	pac.GetSet(PART, "Multiplier", 0.25)
	pac.GetSet(PART, "Size", 0.1)
pac.EndStorableVars()

function PART:OnDraw(owner, pos, ang)

	local spos = pos:ToScreen()
	
	local dist_mult = - math.Clamp(pac.EyePos:Distance(pos) / 1000, 0, 1) + 1
	
	DrawSunbeams(
		self.Darken, 
		dist_mult * self.Multiplier * (math.Clamp(pac.EyeAng:Forward():DotProduct((pos - pac.EyePos):Normalize()) - 0.5, 0, 1) * 2) ^ 5, 
		self.Size, 
		spos.x / ScrW(), 
		spos.y / ScrH()
	)
end

pac.RegisterPart(PART)