local enable = CreateConVar("pac_sv_projectiles", 0, bit.bor(FCVAR_REPLICATED, FCVAR_ARCHIVE))

do -- projectile entity
	local ENT = {}

	ENT.Type = "anim"
	ENT.Base = "base_anim"
	ENT.ClassName = "pac_projectile"

	function ENT:SetupDataTables()
		self:SetDTBool(0, "AimDir")
	end

	if CLIENT then
		function ENT:Draw()
			if self.dt.AimDir then
				self:SetRenderAngles(self:GetVelocity():Angle())
			end
		end
	end

	if SERVER then

		--fix missing attacker
		hook.Add("EntityTakeDamage", "pac_projectile", function(ent, dmg)

			local a, i = dmg:GetAttacker(), dmg:GetInflictor()

			if a == i and a:IsValid() and a.projectile_owner then
				local owner = a.projectile_owner
				if owner:IsValid() then
					dmg:SetAttacker(a.projectile_owner)
				end
			end

		end)

		function ENT:SetData(ply, pos, ang, part)

			self.projectile_owner = ply

			if part.Sphere then
				self:PhysicsInitSphere(math.Clamp(part.Radius, 1, 30))
			else
				self:PhysicsInitBox(Vector(1,1,1) * - math.Clamp(part.Radius, 1, 30), Vector(1,1,1) * math.Clamp(part.Radius, 1, 30))
			end

			local phys = self:GetPhysicsObject()
			phys:EnableGravity(part.Gravity)
			phys:AddVelocity((ang:Forward() + (VectorRand():Angle():Forward() * part.Spread)) * part.Speed * 1000)
			phys:EnableCollisions(part.Collisions)
			phys:SetDamping(part.Damping, 0)
			phys:SetMass(math.Clamp(part.Mass, 0.001, 50000))

			self.dt.AimDir = part.AimDir

			self.part_data = part
		end

		local damage_types = {
			generic = 0, --generic damage
			crush = 1, --caused by physics interaction
			bullet = 2, --bullet damage
			slash = 4, --sharp objects, such as manhacks or other npcs attacks
			burn = 8, --damage from fire
			vehicle = 16, --hit by a vehicle
			fall = 32, --fall damage
			blast = 64, --explosion damage
			club = 128, --crowbar damage
			shock = 256, --electrical damage, shows smoke at the damage position
			sonic = 512, --sonic damage,used by the gargantua and houndeye npcs
			energybeam = 1024, --laser
			nevergib = 4096, --don't create gibs
			alwaysgib = 8192, --always create gibs
			drown = 16384, --drown damage
			paralyze = 32768, --same as dmg_poison
			nervegas = 65536, --neurotoxin damage
			poison = 131072, --poison damage
			acid = 1048576, --
			airboat = 33554432, --airboat gun damage
			blast_surface = 134217728, --this won't hurt the player underwater
			buckshot = 536870912, --the pellets fired from a shotgun
			direct = 268435456, --
			dissolve = 67108864, --forces the entity to dissolve on death
			drownrecover = 524288, --damage applied to the player to restore health after drowning
			physgun = 8388608, --damage done by the gravity gun
			plasma = 16777216, --
			prevent_physics_force = 2048, --
			radiation = 262144, --radiation
			removenoragdoll = 4194304, --don't create a ragdoll on death
			slowburn = 2097152, --
		}

		function ENT:PhysicsCollide(data)
			if self.part_data and self.part_data.Sticky and data.HitEntity:IsWorld() then
				local phys = self:GetPhysicsObject()
				phys:SetVelocity(Vector(0,0,0))
				phys:Sleep()
				phys:EnableMotion(false)
			end

			if self.part_data.BulletImpact then
				self:FireBullets{
					Attacker = self:GetOwner(),
					Damage = 0,
					Force = 0,
					Num = 1,
					Src = data.HitPos - data.HitNormal,
					Dir = data.HitNormal,
				}
			end

			if self.part_data.Damage > 0 and data.HitEntity.Health then
				local info = DamageInfo()

				info:SetAttacker(self:GetOwner():IsValid() and self:GetOwner() or self)
				info:SetInflictor(self)
				info:SetDamageForce(data.OurOldVelocity)
				info:SetDamagePosition(data.HitPos)
				info:SetDamage(math.min(self.part_data.Damage, data.HitEntity:Health())) -- just making sure
				info:SetDamageType(damage_types[self.part_data.DamageType] or damage_types.generic)

				data.HitEntity:TakeDamageInfo(info)
			end

			if self.part_data.RemoveOnCollide then
				timer.Simple(0.01, function() SafeRemoveEntity(self) end)
			end
		end
	end

	scripted_ents.Register(ENT, ENT.ClassName)
end

if SERVER then
	for key, ent in pairs(ents.FindByClass("pac_projectile")) do
		ent:Remove()
	end

	util.AddNetworkString("pac_projectile")
	util.AddNetworkString("pac_projectile_attach")

	net.Receive("pac_projectile", function(len, ply)
		if not enable:GetBool() then return end

		if pace then pace.suppress_prop_spawn = true end
		if hook.Run("PlayerSpawnProp", ply, "models/props_junk/popcan01a.mdl") == false then
			if pace then pace.suppress_prop_spawn = nil end
			return
		end
		if pace then pace.suppress_prop_spawn = nil end

		local pos = net.ReadVector()
		local ang = net.ReadAngle()
		-- Is this even used???
		ply.pac_projectiles = ply.pac_projectiles or {}
		if table.Count( ply.pac_projectiles ) >= 30 then
			return
		end

		local part = net.ReadTable()

		if pos:Distance(ply:EyePos()) > 200 * ply:GetModelScale() then
			if FindMetaTable("Entity").CPPIGetOwner then
				for _, ent in ipairs(ents.FindInSphere(pos, 200)) do
					if ent:CPPIGetOwner() == ply then
						break
					end
				end
			else
				pos = ply:EyePos()
			end
		end

		timer.Simple(part.Delay, function()

			if not ply:IsValid() then return end

			local ent = ents.Create("pac_projectile")
			SafeRemoveEntityDelayed(ent,math.Clamp(part.LifeTime, 0, 10))

			ent:SetModel("models/props_junk/popcan01a.mdl")

			ent:SetPos(pos)
			ent:SetAngles(ang)
			ent:Spawn()

			if not part.CollideWithOwner then
				ent:SetOwner(ply)
			end

			ent:SetData(ply, pos, ang, part)

			ent:SetPhysicsAttacker(ply)

			if ent.CPPISetOwner then
				ent:CPPISetOwner(ply)
			end

			net.Start("pac_projectile_attach")
				net.WriteEntity(ply)
				net.WriteInt(ent:EntIndex(), 16)
				net.WriteString(part.UniqueID)
			net.Broadcast()
		end)
	end)
end