language.Add("pac_projectile", "Projectile")

local BUILDER, PART = pac.PartTemplate("base_movable")

PART.ClassName = "projectile"
PART.Group = 'advanced'
PART.Icon = 'icon16/bomb.png'

BUILDER:StartStorableVars()
	BUILDER:GetSet("Speed", 1)
	BUILDER:GetSet("AddOwnerSpeed", false)
	BUILDER:GetSet("Damping", 0)
	BUILDER:GetSet("Gravity", true)
	BUILDER:GetSet("Collisions", true)
	BUILDER:GetSet("Sphere", false)
	BUILDER:GetSet("Radius", 1)
	BUILDER:GetSet("DamageRadius", 50)
	BUILDER:GetSet("LifeTime", 5)
	BUILDER:GetSet("AimDir", false)
	BUILDER:GetSet("Sticky", false)
	BUILDER:GetSet("Bounce", 0)
	BUILDER:GetSet("BulletImpact", false)
	BUILDER:GetSet("Damage", 0)
	BUILDER:GetSet("DamageType", "generic", {enums = {
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
	BUILDER:GetSet("Spread", 0)
	BUILDER:GetSet("Delay", 0)
	BUILDER:GetSet("Maximum", 0)
	BUILDER:GetSet("Mass", 100)
	BUILDER:GetSet("Attract", 0)
	BUILDER:GetSet("AttractMode", "projectile_nearest", {enums = {
		hitpos = "hitpos",
		hitpos_radius = "hitpos_radius",
		closest_to_projectile = "closest_to_projectile",
		closest_to_hitpos = "closest_to_hitpos",
	}})
	BUILDER:GetSet("AttractRadius", 200)
	BUILDER:GetSetPart("OutfitPart")
	BUILDER:GetSet("Physical", false)
	BUILDER:GetSet("CollideWithOwner", false)
	BUILDER:GetSet("CollideWithSelf", false)
	BUILDER:GetSet("RemoveOnCollide", false)
BUILDER:EndStorableVars()

PART.Translucent = false

function PART:OnShow(from_rendering)
	if not from_rendering then
		-- TODO:
		-- this makes sure all the parents of this movable have an up-to-date draw position
		-- GetBonePosition implicitly uses ent:GetPos() as the parent origin which is really bad,
		-- it should instead be using what pac considers to be the position
		--self:GetRootPart():CallRecursive("Draw", "opaque")
		local parents = self:GetParentList()
		-- call draw from root to the current part only on direct parents to update the position hiearchy
		for i = #parents, 1, -1 do
			local part = parents[i]
			if part.Draw then
				part:Draw("opaque")
			end
		end
		self:Shoot(self:GetDrawPosition())
	end
end

function PART:AttachToEntity(ent)
	if not self.OutfitPart:IsValid() then return false end

	ent.pac_draw_distance = 0

	local tbl = self.OutfitPart:ToTable()

	local group = pac.CreatePart("group", self:GetPlayerOwner())
	group:SetShowInEditor(false)

	local part = pac.CreatePart(tbl.self.ClassName, self:GetPlayerOwner(), tbl, tostring(tbl))
	group:AddChild(part)

	group:SetOwner(ent)
	group.SetOwner = function(s) s.Owner = ent end
	part:SetHide(false)

	local id = group.Id
	local owner_id = self:GetPlayerOwnerId()
	if owner_id then
		id = id .. owner_id
	end

	ent:CallOnRemove("pac_projectile_" .. id, function() group:Remove() end)
	group:CallRecursive("Think")

	ent.RenderOverride = ent.RenderOverride or function()
		if self.AimDir then
			ent:SetRenderAngles(ent:GetVelocity():Angle())
		end
	end

	ent.pac_projectile_part = group
	ent.pac_projectile = self

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

				if not self:GetRootPart():GetOwner():IsValid() then
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
					if ent:IsValid() then
						if ent.pac_projectile_part and ent.pac_projectile_part:IsValid() then
							ent.pac_projectile_part:Remove()
						end

						timer.Simple(0.5, function()
							SafeRemoveEntity(ent)
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
	if not self.Physical and self.projectiles then
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
				local part = pac.GetPartFromUniqueID(pac.Hash(data.ply), data.partuid)
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

BUILDER:Register()
