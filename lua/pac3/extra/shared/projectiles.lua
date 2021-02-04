local enable = CreateConVar("pac_sv_projectiles", 0, CLIENT and {FCVAR_REPLICATED} or {FCVAR_ARCHIVE, FCVAR_REPLICATED})

do -- projectile entity
	local ENT = {}

	ENT.Type = "anim"
	ENT.Base = "base_anim"
	ENT.ClassName = "pac_projectile"

	function ENT:SetupDataTables()
		self:NetworkVar("Bool", 0, "AimDir")
		self:NetworkVar("Vector", 0, "OldVelocity")
	end

	if CLIENT then
		function ENT:Draw()
			if self:GetAimDir() then
				if self:GetOldVelocity() ~= vector_origin then
					self:SetRenderAngles(self:GetOldVelocity():Angle())
				elseif self:GetVelocity() ~= vector_origin then
					self:SetRenderAngles(self:GetVelocity():Angle())
				end
			end

			if self:GetParent():IsValid() and not self.done then
				self:SetPredictable(true)
				self.done = true
			end
		end

		net.Receive("pac_projectile_collide_event", function()
			local self = net.ReadEntity()
			local data = net.ReadTable()

			self.pac_event_collision_data = data
		end)
	end

	if SERVER then
		pac.AddHook("EntityTakeDamage", "pac_projectile", function(ent, dmg)
			local a, i = dmg:GetAttacker(), dmg:GetInflictor()

			if a == i and a:IsValid() and a.projectile_owner then
				local owner = a.projectile_owner
				if owner:IsValid() then
					dmg:SetAttacker(a.projectile_owner)
				end
			end
		end)

		ENT.projectile_owner = NULL

		function ENT:Initialize()
			self.next_target = 0
		end

		function ENT:SetData(ply, pos, ang, part)

			self.projectile_owner = ply

			local radius = math.Clamp(part.Radius, 1, 100)

			if part.Sphere then
				self:PhysicsInitSphere(radius)
			else
				self:PhysicsInitBox(Vector(1,1,1) * - radius, Vector(1,1,1) * radius)
			end

			local phys = self:GetPhysicsObject()
			phys:EnableGravity(part.Gravity)
			phys:AddVelocity((ang:Forward() + (VectorRand():Angle():Forward() * part.Spread)) * part.Speed * 1000)
			if part.AddOwnerSpeed then
				phys:AddVelocity(ply:GetVelocity())
			end
			phys:EnableCollisions(part.Collisions)
			if not part.Collisions then
				self:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
			end

			phys:SetMass(math.Clamp(part.Mass, 0.001, 50000))
			phys:SetDamping(0, 0)

			self:SetAimDir(part.AimDir)

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

			explosion = -1, -- util.BlastDamageInfo
			fire = -1, -- ent:Ignite(5)

			-- env_entity_dissolver
			dissolve_energy = 0,
			dissolve_heavy_electrical = 1,
			dissolve_light_electrical = 2,
			dissolve_core_effect = 3,

			heal = -1,
			armor = -1,
		}

		local dissolver_entity = NULL
		local function dissolve(target, attacker, typ)
			local ent = dissolver_entity:IsValid() and dissolver_entity or ents.Create("env_entity_dissolver")
			ent:Spawn()
			target:SetName(tostring({}))
			ent:SetKeyValue("dissolvetype", tostring(typ))
			ent:Fire("Dissolve", target:GetName())
			timer.Simple(5, function() SafeRemoveEntity(ent) end)
			dissolver_entity = ent
		end

		function ENT:Think()
			if not self.projectile_owner:IsValid() then
				self:Remove()
			end
		end

		function ENT:PhysicsUpdate(phys)
			if not self.part_data then return end

			phys:SetVelocity(phys:GetVelocity() / math.max(1 + (self.part_data.Damping / 100), 1))

			if self.part_data.Attract ~= 0 then
				local ply = self.projectile_owner

				if self.part_data.AttractMode == "hitpos" then
					local pos = ply:GetEyeTrace().HitPos

					local dir = pos - phys:GetPos()
					dir:Normalize()
					dir = dir * self.part_data.Attract

					phys:SetVelocity(phys:GetVelocity() + dir)
				elseif self.part_data.AttractMode == "hitpos_radius" then
					local pos = ply:EyePos() + ply:GetAimVector() * self.part_data.AttractRadius

					local dir = pos - phys:GetPos()
					dir:Normalize()
					dir = dir * self.part_data.Attract

					phys:SetVelocity(phys:GetVelocity() + dir)
				elseif self.part_data.AttractMode == "closest_to_projectile" or self.part_data.AttractMode == "closest_to_hitpos" then
					if self.next_target < CurTime() then
						local radius = math.Clamp(self.part_data.AttractRadius, 0, 300)
						local pos

						if self.part_data.AttractMode == "closest_to_projectile" then
							pos = phys:GetPos()
						else
							pos = ply:GetEyeTrace().HitPos
						end

						local closest_1 = {}
						local closest_2 = {}

						for _, ent in ipairs(ents.FindInSphere(pos, radius)) do
							if
								ent ~= self and
								ent ~= ply and
								ent:GetPhysicsObject():IsValid() and
								ent:GetClass() ~= self:GetClass()
							then
								local data = {dist = ent:NearestPoint(ent:GetPos()):Distance(pos), ent = ent}
								if ent:IsPlayer() or ent:IsNPC() then
									table.insert(closest_1, data)
								else
									table.insert(closest_2, data)
								end
							end
						end

						if closest_1[1] then
							table.sort(closest_1, function(a, b) return a.dist < b.dist end)
							self.target_ent = closest_1[1].ent
						elseif closest_2[1] then
							table.sort(closest_2, function(a, b) return a.dist < b.dist end)
							self.target_ent = closest_2[1].ent
						end

						self.next_target = CurTime() + 0.15
					end

					if self.target_ent and self.target_ent:IsValid() then
						local dir = self.target_ent:NearestPoint(phys:GetPos()) - phys:GetPos()
						dir:Normalize()
						dir = dir * self.part_data.Attract

						phys:SetVelocity(phys:GetVelocity() + dir)
					end
				end
			end
		end

		util.AddNetworkString("pac_projectile_collide_event")

		function ENT:PhysicsCollide(data, phys)
			if not self.part_data then return end
			if not self.projectile_owner:IsValid() then return end

			net.Start("pac_projectile_collide_event", true)
				net.WriteEntity(self)
				net.WriteTable({}) -- nothing for now
			net.SendPVS(data.HitPos)

			local ply = self.projectile_owner

			if self.part_data.Bounce ~= 0 then
				phys:SetVelocity(data.OurOldVelocity - 2 * (data.HitNormal:Dot(data.OurOldVelocity) * data.HitNormal) * self.part_data.Bounce)
			end

			if self.part_data.Sticky and (self.part_data.Bounce == 0 or not data.HitEntity:IsWorld()) then
				phys:SetVelocity(Vector(0,0,0))
				phys:Sleep()
				phys:EnableMotion(false)
				phys:EnableCollisions(false)

				timer.Simple(0, function() if self:IsValid() then self:SetCollisionGroup(COLLISION_GROUP_DEBRIS) end end)

				 if not data.HitEntity:IsWorld() then
					if data.HitEntity:GetBoneCount() then
						local closest = {}
						for id = 1, data.HitEntity:GetBoneCount() do
							local pos = data.HitEntity:GetBonePosition(id)
							if pos then
								table.insert(closest, {dist = pos:Distance(data.HitPos), id = id, pos = pos})
							end
						end
						if closest[1] then
							table.sort(closest, function(a, b) return a.dist < b.dist end)
							self:FollowBone(data.HitEntity, closest[1].id)
							self:SetLocalPos(util.TraceLine({start = data.HitPos, endpos = closest[1].pos}).HitPos - closest[1].pos)
						else
							self:SetPos(data.HitPos)
							self:SetParent(data.HitEntity)
						end
					else
						self:SetPos(data.HitPos)
						self:SetParent(data.HitEntity)
					end
				end

				self:SetOldVelocity(data.OurOldVelocity)
			end

			if self.part_data.BulletImpact then
				self:FireBullets{
					Attacker = ply,
					Damage = 0,
					Force = 0,
					Num = 1,
					Src = data.HitPos - data.HitNormal,
					Dir = data.HitNormal,
					Distance = 10,
				}
			end

			if self.part_data.DamageType:sub(0, 9) == "dissolve_" and damage_types[self.part_data.DamageType] then
				if data.HitEntity:IsPlayer() then
					local info = DamageInfo()
					info:SetAttacker(ply)
					info:SetInflictor(self)
					info:SetDamageForce(data.OurOldVelocity)
					info:SetDamagePosition(data.HitPos)
					info:SetDamage(100000)
					info:SetDamageType(damage_types.dissolve)

					data.HitEntity:TakeDamageInfo(info)
				else
					local can = hook.Run("CanProperty", ply, "remover", data.HitEntity)
					if can ~= false then
						dissolve(data.HitEntity, ply, damage_types[self.part_data.DamageType])
					end
				end
			end

			local damage_radius = math.Clamp(self.part_data.DamageRadius, 0, 300)

			if self.part_data.Damage > 0 then
				if self.part_data.DamageType == "heal" then
					if damage_radius > 0 then
						for _, ent in ipairs(ents.FindInSphere(data.HitPos, damage_radius)) do
							if ent ~= ply or self.part_data.CollideWithOwner then
								ent:SetHealth(math.min(ent:Health() + self.part_data.Damage, ent:GetMaxHealth()))
							end
						end
					else
						data.HitEntity:SetHealth(math.min(data.HitEntity:Health() + self.part_data.Damage, data.HitEntity:GetMaxHealth()))
					end
				elseif self.part_data.DamageType == "armor" then
					if damage_radius > 0 then
						for _, ent in ipairs(ents.FindInSphere(data.HitPos, damage_radius)) do
							if ent.SetArmor and ent.Armor then
								if ent ~= ply or self.part_data.CollideWithOwner then
									ent:SetArmor(math.min(ent:Armor() + self.part_data.Damage, ent.GetMaxArmor and ent:GetMaxArmor() or 100))
								end
							end
						end
					elseif data.HitEntity.SetArmor and data.HitEntity.Armor then
						data.HitEntity:SetArmor(math.min(data.HitEntity:Armor() + self.part_data.Damage, data.HitEntity.GetMaxArmor and data.HitEntity:GetMaxArmor() or 100))
					end
				else
					local info = DamageInfo()

					info:SetAttacker(ply)
					info:SetInflictor(self)

					if self.part_data.DamageType == "fire" then
						local ent = data.HitEntity
						if damage_radius > 0 then
							-- this should also use blast damage to find which entities it can damage
							for _, ent in ipairs(ents.FindInSphere(data.HitPos, damage_radius)) do
								if ent ~= self and ent:IsSolid() and hook.Run("CanProperty", ply, "ignite", ent) ~= false and (ent ~= ply or self.part_data.CollideWithOwner) then
									ent:Ignite(math.min(self.part_data.Damage, 5))
								end
							end
						elseif ent:IsSolid() and hook.Run("CanProperty", ply, "ignite", ent) ~= false then
							ent:Ignite(math.min(self.part_data.Damage, 5))
						end
					elseif self.part_data.DamageType == "explosion" then
						info:SetDamageType(damage_types.blast)
						info:SetDamage(math.Clamp(self.part_data.Damage, 0, 100000))
						util.BlastDamageInfo(info, data.HitPos, damage_radius)
					else
						info:SetDamageForce(data.OurOldVelocity)
						info:SetDamagePosition(data.HitPos)
						info:SetDamage(math.min(self.part_data.Damage, 100000))
						info:SetDamageType(damage_types[self.part_data.DamageType] or damage_types.generic)

						if damage_radius > 0 then
							for _, ent in ipairs(ents.FindInSphere(data.HitPos, damage_radius)) do
								if ent ~= ply or self.part_data.CollideWithOwner then
									ent:TakeDamageInfo(info)
								end
							end
						else
							data.HitEntity:TakeDamageInfo(info)
						end
					end
				end
			end

			if self.part_data.RemoveOnCollide then
				timer.Simple(0, function()
					SafeRemoveEntity(self)
				end)
			end
		end

		function ENT:OnRemove()
			if IsValid(self.pac_projectile_owner) then
				local ply = self.pac_projectile_owner
				ply.pac_projectiles = ply.pac_projectiles or {}
				ply.pac_projectiles[self] = nil
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
	util.AddNetworkString("pac_projectile_remove_all")

	net.Receive("pac_projectile_remove_all", function(len, ply)
		ply.pac_projectiles = ply.pac_projectiles or {}
		for k,v in pairs(ply.pac_projectiles) do
			SafeRemoveEntity(v)
		end
		ply.pac_projectiles = {}
	end)

	net.Receive("pac_projectile", function(len, ply)
		if not enable:GetBool() then return end

		pace.suppress_prop_spawn = true
		if hook.Run("PlayerSpawnProp", ply, "models/props_junk/popcan01a.mdl") == false then
			pace.suppress_prop_spawn = nil
			return
		end
		pace.suppress_prop_spawn = nil

		local pos = net.ReadVector()
		local ang = net.ReadAngle()
		local part = net.ReadTable()

		local radius_limit = 2000

		if pos:Distance(ply:EyePos()) > radius_limit * ply:GetModelScale() then
			local ok = false

			for _, ent in ipairs(ents.FindInSphere(pos, radius_limit)) do
				if (ent.CPPIGetOwner and ent:CPPIGetOwner() == ply) or ent.projectile_owner == ply or ent:GetOwner() == ply then
					ok = true
					break
				end
			end

			if not ok then
				pos = ply:EyePos()
			end
		end

		local function spawn()
			if not ply:IsValid() then return end

			ply.pac_projectiles = ply.pac_projectiles or {}

			if part.Maximum > 0 and table.Count(ply.pac_projectiles) >= part.Maximum then
				return
			end

			local ent = ents.Create("pac_projectile")
			SafeRemoveEntityDelayed(ent,math.Clamp(part.LifeTime, 0, 10))

			ent:SetModel("models/props_junk/popcan01a.mdl")
			ent:SetCollisionGroup(COLLISION_GROUP_INTERACTIVE_DEBRIS)
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

			ply.pac_projectiles[ent] = ent

			ent.pac_projectile_owner = ply
		end

		if part.Delay == 0 then
			spawn()
		else
			timer.Simple(part.Delay, spawn)
		end
	end)
end
