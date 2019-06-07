language.Add("pac_projectile", "Projectile")

local PART = {}

PART.ClassName = "projectile"
PART.Group = 'advanced'
PART.Icon = 'icon16/bomb.png'

pac.StartStorableVars()
	pac.GetSet(PART, "Speed", 1)
	pac.GetSet(PART, "AddOwnerSpeed", false)
	pac.GetSet(PART, "Damping", 0)
	pac.GetSet(PART, "Gravity", true)
	pac.GetSet(PART, "Collisions", true)
	pac.GetSet(PART, "Sphere", false)
	pac.GetSet(PART, "Radius", 1)
	pac.GetSet(PART, "DamageRadius", 50)
	pac.GetSet(PART, "LifeTime", 5)
	pac.GetSet(PART, "AimDir", false)
	pac.GetSet(PART, "Sticky", false)
	pac.GetSet(PART, "Bounce", 0)
	pac.GetSet(PART, "BulletImpact", false)
	pac.GetSet(PART, "Damage", 0)
	pac.GetSet(PART, "DamageType", "generic", {enums = {
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

			explosion = -1, -- util.BlastDamage
			fire = -1, -- ent:Ignite(5)

			-- env_entity_dissolver
			dissolve_energy = 0,
			dissolve_heavy_electrical = 1,
			dissolve_light_electrical = 2,
			dissolve_core_effect = 3,

			heal = -1,
			armor = -1,
		}
	})
	pac.GetSet(PART, "Spread", 0)
	pac.GetSet(PART, "Delay", 0)
	pac.GetSet(PART, "Maximum", 0)
	pac.GetSet(PART, "Mass", 100)
	pac.GetSet(PART, "Attract", 0)
	pac.GetSet(PART, "AttractMode", "projectile_nearest", {enums = {
		hitpos = "hitpos",
		hitpos_radius = "hitpos_radius",
		closest_to_projectile = "closest_to_projectile",
		closest_to_hitpos = "closest_to_hitpos",
	}})
	pac.GetSet(PART, "AttractRadius", 200)
	pac.SetupPartName(PART, "OutfitPart")
	pac.GetSet(PART, "Physical", false)
	pac.GetSet(PART, "CollideWithOwner", false)
	pac.GetSet(PART, "RemoveOnCollide", false)
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
	tbl.self.UniqueID = util.CRC(tbl.self.UniqueID .. tbl.self.UniqueID)

	local part = pac.CreatePart(tbl.self.ClassName, self:GetPlayerOwner())

	local id = part.Id + self:GetPlayerOwner():UniqueID()

	part.show_in_editor = false
	part.CheckOwner = function(s) s.Owner = ent end
	part:SetPlayerOwner(self:GetPlayerOwner())
	part:SetTable(tbl)
	part:SetHide(false)

	part:SetOwner(ent)

	ent:CallOnRemove("pac_projectile_" .. id, function() part:Remove() end)

	pac.HookEntityRender(ent, part)

	ent.RenderOverride = ent.RenderOverride or function()
		if self.AimDir then
			ent:SetRenderAngles(ent:GetVelocity():Angle())
		end
	end

	ent.pac_projectile_id = id
	ent.pac_projectile_part = part

	return true
end

local enable = CreateClientConVar("pac_sv_projectiles", 0, true)

function PART:Shoot(pos, ang)
	local physics = self.Physical

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

		local count = 0

		for key, ent in pairs(self.projectiles) do
			if not ent:IsValid() then
				self.projectiles[key] = nil
			else
				count = count + 1
			end
		end

		local max = math.min(self.Maximum, 100)

		if max == 0 then
			max = 100
		end

		if count > max then
			return
		end

		local function spawn()

			if not self:IsValid() then return end

			local ent = pac.CreateEntity("models/props_junk/popcan01a.mdl")
			if not ent:IsValid() then return end

			local idx = table.insert(self.projectiles, ent)

			ent:AddCallback("PhysicsCollide", function(ent, data)
				local phys = ent:GetPhysicsObject()
				if self.Bounce > 0 then
					timer.Simple(0, function()
						if phys:IsValid() then
							phys:SetVelocity(data.OurOldVelocity - 2 * (data.HitNormal:Dot(data.OurOldVelocity) * data.HitNormal) * self.Bounce)
						end
					end)
				elseif self.Sticky then
					phys:SetVelocity(Vector(0,0,0))
					phys:EnableMotion(false)
					ent.pac_stuck = data.OurOldVelocity
				end

				if self.BulletImpact then
					ent:FireBullets{
						Attacker = ent:GetOwner(),
						Damage = 0,
						Force = 0,
						Num = 1,
						Src = data.HitPos - data.HitNormal,
						Dir = data.HitNormal,
						Distance = 10,
					}
				end

				if self.RemoveOnCollide then
					timer.Simple(0.01, function() SafeRemoveEntity(ent) end)
				end
			end)

			ent:SetOwner(self:GetPlayerOwner(true))
			ent:SetPos(pos)
			ent:SetAngles(ang)
			ent:SetCollisionGroup(COLLISION_GROUP_PROJECTILE)

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
					timer.Simple(0, function() SafeRemoveEntity(ent) end)
				end

				if self.AimDir then
					if ent.pac_stuck then
						ent:SetRenderAngles(ent.pac_stuck:Angle())
					else
						local angle = ent:GetVelocity():Angle()
						ent:SetRenderAngles(angle)
						ent.last_angle = angle
					end
				end
			end

			local phys = ent:GetPhysicsObject()
			phys:EnableGravity(self.Gravity)
			phys:AddVelocity((ang:Forward() + (VectorRand():Angle():Forward() * self.Spread)) * self.Speed * 1000)
			if self.AddOwnerSpeed and ent:GetOwner():IsValid() then
				phys:AddVelocity(ent:GetOwner():GetVelocity())
			end
			phys:EnableCollisions(self.Collisions)
			phys:SetDamping(self.Damping, 0)

			ent:SetCollisionGroup(COLLISION_GROUP_PROJECTILE)

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
		end

		if self.Delay == 0 then
			spawn()
		else
			timer.Simple(self.Delay, spawn)
		end
	end
end

function PART:OnRemove()
	if self.Physical then
		net.Start("pac_projectile_remove_all")
		net.SendToServer()
	elseif self.projectiles then
		for key, ent in pairs(self.projectiles) do
			SafeRemoveEntity(ent)
		end

		self.projectiles = {}
	end
end
--[[
function PART:OnHide()
	if self.RemoveOnHide then
		self:OnRemove()
	end
end
]]
do -- physical
	local Entity = Entity
	local projectiles = {}
	pac.AddHook("Think", "pac_projectile", function()
		for key, data in pairs(projectiles) do
			if not data.ply:IsValid() then
				projectiles[key] = nil
				goto CONTINUE
			end

			local ent = Entity(data.ent_id)

			if ent:IsValid() and ent:GetClass() == "pac_projectile" then
				local part = pac.GetPartFromUniqueID(data.ply:IsPlayer() and data.ply:UniqueID() or data.ply:EntIndex(), data.partuid)
				if part:IsValid() and part:GetPlayerOwner() == data.ply then
					part:AttachToEntity(ent)
				end
				projectiles[key] = nil
			end
			::CONTINUE::
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
