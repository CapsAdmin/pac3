language.Add("pac_projectile", "Projectile")

local PART = {}

PART.ClassName = "projectile"

pac.StartStorableVars()
	pac.GetSet(PART, "Speed", 1)
	pac.GetSet(PART, "Damping", 0)
	pac.GetSet(PART, "Gravity", true)
	pac.GetSet(PART, "Collisions", true)
	pac.GetSet(PART, "Sphere", false)
	pac.GetSet(PART, "Radius", 1)
	pac.GetSet(PART, "LifeTime", 5)
	pac.GetSet(PART, "AimDir", false)
	pac.GetSet(PART, "Sticky", false)
	pac.GetSet(PART, "Spread", 0)
	pac.GetSet(PART, "Delay", 0)
	pac.GetSet(PART, "Mass", 100)
	pac.SetupPartName(PART, "OutfitPart")
	pac.GetSet(PART, "Physical", false)
	pac.GetSet(PART, "CollideWithOwner", false)
pac.EndStorableVars()

function PART:OnShow(from_rendering)
	if not from_rendering then
		self.trigger = true
	end
end

function PART:OnDraw(owner, pos, ang)	
	if self.trigger then
		self:Shoot(pos, ang)
		self.trigger = false
	end
end

function PART:AttachToEntity(ent)
	if not self.OutfitPart:IsValid() then return false end
				
	ent.pac_draw_distance = 0			
			
	local tbl = self.OutfitPart:ToTable()
			
	tbl.self.Name = "projectile " .. self:GetPlayerOwner():UniqueID() .. os.clock()
	
	pac.SuppressCreatedEvents = true
	local part = pac.CreatePart(tbl.self.ClassName, self:GetPlayerOwner())
	
	local id = part.Id + self:GetPlayerOwner():UniqueID()
	
	part.show_in_editor = false
	part.CheckOwner = function() end
	part:SetPlayerOwner(self:GetPlayerOwner())
	part:SetTable(tbl, true)
	part:SetHide(false)
	part:RemoveOnNULLOwner(true)
	
	ent:CallOnRemove("pac_projectile_" .. id, function() part:Remove() end)
	
	part.Owner = ent
	
	ent.pac_parts = {part}
	pac.drawn_entities[id] = ent
		
	ent.RenderOverride = ent.RenderOverride or function()
		if self.AimDir then 
			ent:SetRenderAngles(ent:GetVelocity():Angle()) 
		end 
	end
	
	ent.pac_projectile_id = id
	ent.pac_projectile_part = part

	pac.SuppressCreatedEvents = false	
	
	return true
end

local enable = CreateClientConVar("pac_sv_projectiles", 0, true)

function PART:Shoot(pos, ang)
	local physics = self.Physical

	--[[if physics and not enable:GetBool() then
		MsgC(Color(255, 0, 0), "[pac3] projectiles are not enabled on the server, using clientside projectiles instead!\n")
		physics = false
	end]]

	if physics then	
		if pac.LocalPlayer ~= self:GetPlayerOwner() then return end
		
		local tbl = {}
		for key in pairs(self:GetStorableVars()) do
			tbl[key] = self[key]
		end
			
		net.Start("pac_projectile")
			net.WriteVector(pos)
			net.WriteAngle(ang)
			net.WriteTable(tbl)
		net.SendToServer()
	else	
		self.projectiles = self.projectiles or {}
		
		for key, ent in pairs(self.projectiles) do
			if not ent:IsValid() then
				self.projectiles[key] = nil
			end
		end
		
		if table.Count(self.projectiles) >= 30 then
			return
		end
		
		timer.Simple(self.Delay, function()
			
			if not self:IsValid() then return end
						
			local ent = pac.CreateEntity("models/props_junk/popcan01a.mdl")
			local idx = table.insert(self.projectiles, ent)
			
			ent:SetOwner(self:GetPlayerOwner(true))
			ent:SetPos(pos)
			ent:SetAngles(ang)
			
			if self.Sphere then
				ent:PhysicsInitSphere(math.Clamp(self.Radius, 1, 30))
			else
				ent:PhysicsInitBox(Vector(1,1,1) * - math.Clamp(self.Radius, 1, 30), Vector(1,1,1) * math.Clamp(self.Radius, 1, 30))
			end
			
			ent.RenderOverride = function() 
				if not self:IsValid() then
					return 
				end
			
				if not self:GetOwner(true):IsValid() then
					timer.Simple(0, function() SafeRemoveEntity(self) end)
				end
			
				if self.AimDir then 
					ent:SetRenderAngles(ent:GetVelocity():Angle()) 
				end 
				
				if self.Sticky then
					if ent.pac_projectile_stuck then
						ent:SetPos(ent.pac_projectile_stuck.pos)
						ent:SetAngles(ent.pac_projectile_stuck.ang)
					end
				
					local ang = ent:GetRenderAngles() or ent:GetAngles()
					local trace = util.QuickTrace(ent:GetPos(), ang:Forward() * ent:GetVelocity():Length() / 10, ent)
					
					if trace.Hit then
						local phys = ent:GetPhysicsObject()
						phys:EnableGravity(false)
						ent.pac_projectile_stuck = {pos = trace.HitPos, ang = trace.HitNormal:Angle()}
					end
				end
			end
					
			local phys = ent:GetPhysicsObject()
			phys:EnableGravity(self.Gravity)
			phys:AddVelocity((ang:Forward() + (VectorRand():Angle():Forward() * self.Spread)) * self.Speed * 1000)
			phys:EnableCollisions(self.Collisions)	
			phys:SetDamping(self.Damping, 0)			
			
			if self:AttachToEntity(ent) then
				timer.Simple(math.Clamp(self.LifeTime, 0, 10), function()
					if ent:IsValid() and ent.pac_projectile_id then					
						local id = ent.pac_projectile_id
						
						if ent.pac_projectile_part and ent.pac_projectile_part:IsValid() then
							ent.pac_projectile_part:Remove()
						end
						
						timer.Simple(0.5, function()
							SafeRemoveEntity(ent)
							pac.drawn_entities[id] = nil
						end)
					end
				end)
			end
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

do -- physical
	local Entity = Entity
	local projectiles = {}	
	hook.Add("Think", "pac_projectile", function()
		for key, data in pairs(projectiles) do
			if not data.ply:IsValid() then
				projectiles[key] = nil
				continue
			end

			local ent = Entity(data.ent_id)

			if ent:IsValid() then
				local part = pac.GetPartFromUniqueID(data.ply:UniqueID(), data.partuid)
				if part:IsValid() and part:GetPlayerOwner() == data.ply then
					part:AttachToEntity(ent)
				end
				projectiles[key] = nil
			end
		end
	end)
		
	net.Receive("pac_projectile_attach", function()
		local ply = net.ReadEntity()
		local ent_id = net.ReadInt(16)
		local partuid = net.ReadString()
		
		if ply:IsValid() then
			table.insert(projectiles, {ply = ply, ent_id = ent_id, partuid = partuid})
		end
	end)		
end

pac.RegisterPart(PART)