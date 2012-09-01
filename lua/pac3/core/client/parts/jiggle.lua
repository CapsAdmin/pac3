local PART = {}

PART.ClassName = "jiggle"

pac.StartStorableVars()
	pac.GetSet(PART, "Strain", 0.5)
	pac.GetSet(PART, "Speed", 1)
	pac.GetSet(PART, "JiggleAngle", true)
	pac.GetSet(PART, "JigglePosition", true)
	pac.GetSet(PART, "ConstrainPitch", false)
	pac.GetSet(PART, "ConstrainYaw", false)
	pac.GetSet(PART, "ConstrainRoll", false)
pac.EndStorableVars()

local math_AngleDifference = math.AngleDifference

function PART:OnDraw(owner, pos, ang)	
	local delta = FrameTime() 
	
	if self.JigglePosition then
		self.vel = self.vel or VectorRand()
		self.pos = self.pos or pos * 1 
		
		self.vel = self.vel + (pos - self.pos)
		self.pos = self.pos + (self.vel * delta * self.Speed)
		self.vel = self.vel * self.Strain
	else
		self.pos = pos
	end
		
	if self.JiggleAngle then
		self.angvel = self.angvel or ang * 1
		self.ang = self.ang or ang * 1
		
		if not self.ConstrainPitch then self.angvel.p = self.angvel.p + math_AngleDifference(ang.p, self.ang.p) end
		if not self.ConstrainYaw then self.angvel.y = self.angvel.y + math_AngleDifference(ang.y, self.ang.y) end
		if not self.ConstrainRoll then self.angvel.r = self.angvel.r + math_AngleDifference(ang.r, self.ang.r) end
		
		if not self.ConstrainPitch then self.ang.p = math_AngleDifference(self.ang.p, self.angvel.p * -(delta * self.Speed)) end
		if not self.ConstrainYaw then self.ang.y = math_AngleDifference(self.ang.y, self.angvel.y * -(delta * self.Speed)) end
		if not self.ConstrainRoll then self.ang.r = math_AngleDifference(self.ang.r, self.angvel.r * -(delta * self.Speed)) end
		
		if not self.ConstrainPitch then self.angvel.p = self.angvel.p * self.Strain end
		if not self.ConstrainYaw then self.angvel.y = self.angvel.y * self.Strain end
		if not self.ConstrainRoll then self.angvel.r = self.angvel.r * self.Strain end
	else
		self.ang = ang
	end
end

pac.RegisterPart(PART)