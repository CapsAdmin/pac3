local PART = {}

PART.ClassName = "jiggle"

pac.StartStorableVars()
	pac.GetSet(PART, "Strain", 0.5)
	pac.GetSet(PART, "Speed", 1)
pac.EndStorableVars()

function PART:OnDraw(owner, pos, ang)	
	local delta = FrameTime() 
	
	self.vel = self.vel or VectorRand()
	self.pos = self.pos or VectorRand()
	
	self.vel = self.vel + (pos - self.pos)
	self.pos = self.pos + (self.vel * delta * self.Speed)
	self.vel = self.vel * self.Strain
		
	self.angvel = self.angvel or VectorRand()
	self.ang = self.ang or VectorRand()
	
	self.angvel = self.angvel + (ang - self.ang)
	self.ang = self.ang + (self.angvel * delta * self.Speed)
	self.angvel = self.angvel * self.Strain
end

pac.RegisterPart(PART)