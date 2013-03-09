local PART = {}

PART.ClassName = "projectile"

pac.StartStorableVars()
	pac.GetSet(PART, "Speed", 1)
	pac.GetSet(PART, "Damping", 0)
	pac.GetSet(PART, "Gravity", true)
	pac.GetSet(PART, "Collisions", true)
	pac.GetSet(PART, "Radius", 1)
	pac.GetSet(PART, "LifeTime", 5)
	pac.GetSet(PART, "AimDir", false)
	pac.GetSet(PART, "Sticky", false)
	pac.GetSet(PART, "Spread", 0)
	pac.SetupPartName(PART, "OutfitPart")
pac.EndStorableVars()

function PART:OnShow(from_event)
	if from_event then
		self.trigger = true
	end
end

function PART:OnDraw(owner, pos, ang)	
	if self.trigger then
		self:Shoot(pos, ang)
		self.trigger = false
	end
end

function PART:Shoot(pos, ang)		
	self.projectiles = self.projectiles or {}
	
	if table.Count(self.projectiles) >= 30 then
		return
	end
	
	local ent = pac.CreateEntity("models/props_junk/popcan01a.mdl")
	local idx = table.insert(self.projectiles, ent)
	
	ent:SetOwner(self:GetPlayerOwner(true))
	ent:SetPos(pos)
	ent:SetAngles(ang)
	ent:PhysicsInitBox(Vector(1,1,1) * - math.Clamp(self.Radius, 1, 10), Vector(1,1,1) * math.Clamp(self.Radius, 1, 10))
	
	ent.RenderOverride = function() 
		if self.AimDir then 
			ent:SetRenderAngles(ent:GetVelocity():Angle()) 
		end 
		
		if self.Sticky then
			if ent.pac_projectile_stuck then
				ent:SetPos(ent.pac_projectile_stuck.pos)
				ent:SetAngles(ent.pac_projectile_stuck.ang)
			end
		
			local ang = ent:GetRenderAngles() or ent:GetAngles()
			local trace = util.QuickTrace(ent:GetPos(), ang:Forward() * 50, ent)
			
			if trace.Hit then
				local phys = ent:GetPhysicsObject()
				phys:EnableGravity(false)
				ent.pac_projectile_stuck = {pos = trace.HitPos, ang = trace.HitNormal:Angle()}
			end
		end
	end
	
	timer.Simple(math.Clamp(self.LifeTime, 0, 10), function()
		SafeRemoveEntity(ent)
	end)
		
	
	
	local phys = ent:GetPhysicsObject()
	phys:EnableGravity(self.Gravity)
	phys:AddVelocity((ang:Forward() + (VectorRand():Angle():Forward() * self.Spread)) * self.Speed * 1000)
	phys:EnableCollisions(self.Collisions)	
	phys:SetDamping(self.Damping, 0)
	if self.OutfitPart:IsValid() then
		ent.pac_draw_distance = 0			
		
		local tbl = self.OutfitPart:ToTable()
		
		tbl.self.Name = "projectile " .. self:GetPlayerOwner():UniqueID() .. os.clock()
		local part = pac.CreatePart(tbl.self.ClassName, self:GetPlayerOwner(), true)
		
		local id = part.Id + self:GetPlayerOwner():UniqueID()
		
		part.show_in_editor = false
		part.CheckOwner = function() end
		part:SetPlayerOwner(self:GetPlayerOwner())
		part:SetTable(tbl)
		part:SetHide(false)
		
		part.Owner = ent
		
		ent.pac_parts = {part}
		pac.drawn_entities[id] = ent
					
		ent:CallOnRemove("pac_projectile_remove", function()
			if self:IsValid() then self.projectiles[idx] = nil end
			pac.drawn_entities[id] = nil
			part:Remove()
		end)
		
	end	
end

function PART:OnRemove()
	if self.projectiles then
		for key, ent in pairs(self.projectiles) do
			SafeRemoveEntity(ent)
		end
		
		self.projectiles = {}
	end
end

PART.OnHide = OnRemove

pac.RegisterPart(PART)