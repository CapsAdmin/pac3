local PART = {}

PART.ClassName = "jiggle"

pac.StartStorableVars()
	pac.GetSet(PART, "Strain", 0.5)
	pac.GetSet(PART, "Speed", 1)
	pac.GetSet(PART, "ConstantVelocity", Vector(0, 0, 0))
	pac.GetSet(PART, "LocalVelocity", true)
	pac.GetSet(PART, "JiggleAngle", true)
	pac.GetSet(PART, "JigglePosition", true)
	pac.GetSet(PART, "ConstrainPitch", false)
	pac.GetSet(PART, "ConstrainYaw", false)
	pac.GetSet(PART, "ConstrainRoll", false)
	pac.GetSet(PART, "ConstrainX", false)
	pac.GetSet(PART, "ConstrainY", false)
	pac.GetSet(PART, "ConstrainZ", false)
pac.EndStorableVars()

local math_AngleDifference = math.AngleDifference

function PART:OnDraw(owner, pos, ang)	
	local delta = FrameTime() 
	local speed = self.Speed * delta
	
	if self.JigglePosition then
		self.vel = self.vel or VectorRand()
		self.pos = self.pos or pos * 1
				
		if not self.ConstrainX then self.vel.x = self.vel.x + (pos.x - self.pos.x) end
		if not self.ConstrainY then self.vel.y = self.vel.y + (pos.y - self.pos.y) end
		if not self.ConstrainZ then self.vel.z = self.vel.z + (pos.z - self.pos.z) end
		
		if self.ConstantVelocity then
			if self.LocalVelocity then
				self.vel = self.vel + 
				ang:Right() * self.ConstantVelocity.x +
				ang:Forward() * self.ConstantVelocity.y +
				ang:Up() * self.ConstantVelocity.z
			else
				self.vel = self.vel + self.ConstantVelocity
			end
		end
		
		if not self.ConstrainX then self.pos.x = self.pos.x + (self.vel.x * speed) end
		if not self.ConstrainY then self.pos.y = self.pos.y + (self.vel.y * speed) end
		if not self.ConstrainZ then self.pos.z = self.pos.z + (self.vel.z * speed) end
		
		if not self.ConstrainX then self.vel.x = self.vel.x * self.Strain end
		if not self.ConstrainY then self.vel.y = self.vel.y * self.Strain end
		if not self.ConstrainZ then self.vel.z = self.vel.z * self.Strain end

		if not self.LocalVelocity then
			if self.ConstrainX then self.pos.x = pos.x end
			if self.ConstrainY then self.pos.y = pos.y end
			if self.ConstrainZ then self.pos.z = pos.z end
		end
	else
		self.pos = pos
	end
		
	if self.JiggleAngle then
		self.angvel = self.angvel or ang * 1
		self.ang = self.ang or ang * 1
		
		if not self.ConstrainPitch then 
			self.angvel.p = self.angvel.p + math_AngleDifference(ang.p, self.ang.p) 
			self.ang.p = math_AngleDifference(self.ang.p, self.angvel.p * -speed)
			self.angvel.p = self.angvel.p * self.Strain
		end
		
		if not self.ConstrainYaw then 
			self.angvel.y = self.angvel.y + math_AngleDifference(ang.y, self.ang.y) 
			self.ang.y = math_AngleDifference(self.ang.y, self.angvel.y * -speed)
			self.angvel.y = self.angvel.y * self.Strain
		end
		
		if not self.ConstrainRoll then 
			self.angvel.r = self.angvel.r + math_AngleDifference(ang.r, self.ang.r) 
			self.ang.r = math_AngleDifference(self.ang.r, self.angvel.r * -speed)
			self.angvel.r = self.angvel.r * self.Strain
		end
	else
		self.ang = ang
	end
end

pac.RegisterPart(PART)