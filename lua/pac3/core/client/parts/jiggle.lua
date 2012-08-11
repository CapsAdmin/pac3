local PART = {}

PART.ClassName = "jiggle"

pac.StartStorableVars()
	pac.GetSet(PART, "Strain", 0.5)
	pac.GetSet(PART, "Speed", 1)
	pac.GetSet(PART, "JiggleAngle", true)
	pac.GetSet(PART, "JigglePosition", true)
pac.EndStorableVars()

local math_AngleDifference = math.AngleDifference
local function subang(a,b)
	return Angle(
		math.AngleDifference(a.p, b.p),
		math.AngleDifference(a.y, b.y),
		math.AngleDifference(a.r, b.r)
	)
end

function PART:OnDraw(owner, pos, ang)	
	local delta = FrameTime() 
	
	if self.JigglePosition then
		self.vel = self.vel or VectorRand()
		self.pos = self.pos or pos
		
		self.vel = self.vel + (pos - self.pos)
		self.pos = self.pos + (self.vel * delta * self.Speed)
		self.vel = self.vel * self.Strain
	else
		self.pos = pos
	end
	
	if self.JiggleAngle then
		self.angvel = self.angvel or ang
		self.ang = self.ang or ang
		
		self.angvel = self.angvel + subang(ang, self.ang)
		self.ang = subang(self.ang, self.angvel * -(delta * self.Speed))
		self.angvel = self.angvel * self.Strain
	else
		self.ang = ang
	end
end

pac.RegisterPart(PART)