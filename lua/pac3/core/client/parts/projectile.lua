local physprop_enums = {}
local physprop_indices = {}
for i=0,200,1 do
	local name = util.GetSurfacePropName(i)
	if name ~= "" then
		physprop_enums[name] = name
		physprop_indices[name] = i
	end
end

language.Add("pac_projectile", "Projectile")



local BUILDER, PART = pac.PartTemplate("base_movable")

PART.ClassName = "projectile"
PART.Group = {"advanced", "combat"}
PART.Icon = "icon16/bomb.png"

BUILDER:StartStorableVars()
	BUILDER:SetPropertyGroup("Firing")
		BUILDER:GetSet("Speed", 1)
		BUILDER:GetSet("AddOwnerSpeed", false)
		BUILDER:GetSet("Spread", 0)
		BUILDER:GetSet("NumberProjectiles", 1)
		BUILDER:GetSet("Delay", 0)
		BUILDER:GetSet("Maximum", 0)
		BUILDER:GetSet("RandomAngleVelocity", Vector(0,0,0))
		BUILDER:GetSet("LocalAngleVelocity", Vector(0,0,0))
	BUILDER:SetPropertyGroup("Physics")
		BUILDER:GetSet("Freeze", false, {description = "frozen like physgun"})
		BUILDER:GetSet("Mass", 100, {editor_clamp = {0,50000}}) --there's actually a 50k limit
		BUILDER:GetSet("ImpactSounds", true, {description = "allow physics impact sounds, applies to physical projectiles"})
		BUILDER:GetSet("SurfaceProperties", "default", {enums = physprop_enums})
		BUILDER:GetSet("RescalePhysMesh", false, {description = "experimental! tries to scale the collide mesh by the radius! Stay within  small numbers! 1 radius should be associated with a full-size model"})
		BUILDER:GetSet("OverridePhysMesh", false, {description = "experimental! tries to redefine the projectile's model to change the physics mesh"})
		BUILDER:GetSet("FallbackSurfpropModel", "models/props_junk/PopCan01a.mdl", {editor_friendly = "collide mesh", editor_panel = "model"})
		BUILDER:GetSet("Damping", 0)
		BUILDER:GetSet("Gravity", true)
		BUILDER:GetSet("Collisions", true)
		BUILDER:GetSet("Sphere", false)
		BUILDER:GetSet("Radius", 1, {editor_panel = "projectile_radii"})
		BUILDER:GetSet("Bounce", 0)
		BUILDER:GetSet("Sticky", false)
		BUILDER:GetSet("CollideWithOwner", false)
		BUILDER:GetSet("CollideWithSelf", false)
	BUILDER:SetPropertyGroup("Appearance")
		BUILDER:GetSetPart("OutfitPart")
		BUILDER:GetSet("RemoveOnHide", false)
		BUILDER:GetSet("AimDir", false)
		BUILDER:GetSet("DrawShadow", true)
	BUILDER:SetPropertyGroup("ActiveBehavior")
		BUILDER:GetSet("Physical", false)
		BUILDER:GetSet("DamageRadius", 50, {editor_panel = "projectile_radii"})
		BUILDER:GetSet("LifeTime", 5)
		BUILDER:GetSet("RemoveOnCollide", false)
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
		BUILDER:GetSet("Attract", 0, {editor_friendly = "attract force"})
		BUILDER:GetSet("AttractMode", "closest_to_projectile", {enums = {
			hitpos = "hitpos",
			hitpos_radius = "hitpos_radius",
			closest_to_projectile = "closest_to_projectile",
			closest_to_hitpos = "closest_to_hitpos",
		}})
		BUILDER:GetSet("AttractRadius", 200)

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
		if self.NumberProjectiles <= 0 then self.NumberProjectiles = 0 end
		if self.NumberProjectiles <= 50 then
			local pos,ang = self:GetDrawPosition()
			self:Shoot(pos,ang,self.NumberProjectiles)
		else chat.AddText(Color(255,0,0),"[PAC3] Trying to spawn too many projectiles! The limit is " .. 50) end
	end
end

function PART:GetSurfacePropsTable() --to view info over in the properties
	return util.GetSurfaceData(physprop_indices[self.SurfaceProperties])
end

local_projectiles = {}
function PART:AttachToEntity(ent, physical)
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
	ent.pac_projectile = self --that's just the launcher though
	if not physical then local_projectiles[group] = ent end

	return true
end

local enable = CreateClientConVar("pac_sv_projectiles", 0, true)

local damage_ids = {
	generic = 0, --generic damage
	crush = 1, --caused by physics interaction
	bullet = 2, --bullet damage
	slash = 3, --sharp objects, such as manhacks or other npcs attacks
	burn = 4, --damage from fire
	vehicle = 5, --hit by a vehicle
	fall = 6, --fall damage
	blast = 7, --explosion damage
	club = 8, --crowbar damage
	shock = 9, --electrical damage, shows smoke at the damage position
	sonic = 10, --sonic damage,used by the gargantua and houndeye npcs
	energybeam = 11, --laser
	nevergib = 12, --don't create gibs
	alwaysgib = 13, --always create gibs
	drown = 14, --drown damage
	paralyze = 15, --same as dmg_poison
	nervegas = 16, --neurotoxin damage
	poison = 17, --poison damage
	acid = 18, --
	airboat = 19, --airboat gun damage
	blast_surface = 20, --this won't hurt the player underwater
	buckshot = 21, --the pellets fired from a shotgun
	direct = 22, --
	dissolve = 23, --forces the entity to dissolve on death
	drownrecover = 24, --damage applied to the player to restore health after drowning
	physgun = 25, --damage done by the gravity gun
	plasma = 26, --
	prevent_physics_force = 27, --
	radiation = 28, --radiation
	removenoragdoll = 29, --don't create a ragdoll on death
	slowburn = 30, --

	explosion = 31, -- ent:Ignite(5)
	fire = 32, -- ent:Ignite(5)

	-- env_entity_dissolver
	dissolve_energy = 33,
	dissolve_heavy_electrical = 34,
	dissolve_light_electrical = 35,
	dissolve_core_effect = 36,

	heal = 37,
	armor = 38,
}
local attract_ids = {
	hitpos = 0,
	hitpos_radius = 1,
	closest_to_projectile = 2,
	closest_to_hitpos = 3,
}
function PART:Shoot(pos, ang, multi_projectile_count)
	local physics = self.Physical
	local multi_projectile_count = multi_projectile_count or 1

	if physics then
		if pac.LocalPlayer ~= self:GetPlayerOwner() then return end

		local tbl = {}

		net.Start("pac_projectile",true)
			net.WriteUInt(multi_projectile_count,7)
			net.WriteVector(pos)
			net.WriteAngle(ang)

			--bools
			net.WriteBool(self.Sphere)
			net.WriteBool(self.RemoveOnCollide)
			net.WriteBool(self.CollideWithOwner)
			net.WriteBool(self.RemoveOnHide)
			net.WriteBool(self.RescalePhysMesh)
			net.WriteBool(self.OverridePhysMesh)
			net.WriteBool(self.Gravity)
			net.WriteBool(self.AddOwnerSpeed)
			net.WriteBool(self.Collisions)
			net.WriteBool(self.CollideWithSelf)
			net.WriteBool(self.AimDir)
			net.WriteBool(self.DrawShadow)
			net.WriteBool(self.Sticky)
			net.WriteBool(self.BulletImpact)
			net.WriteBool(self.Freeze)
			net.WriteBool(self.ImpactSounds)

			--vectors
			net.WriteVector(self.RandomAngleVelocity)
			net.WriteVector(self.LocalAngleVelocity)

			--strings
			net.WriteString(self.OverridePhysMesh and string.sub(string.gsub(self.FallbackSurfpropModel, "^models/", ""),1,150) or "") --custom model is an unavoidable string
			net.WriteString(string.sub(self.UniqueID,1,12)) --long string but we can probably truncate it
			net.WriteUInt(physprop_indices[self.SurfaceProperties] or 0,10)
			net.WriteUInt(damage_ids[self.DamageType] or 0,7)
			net.WriteUInt(attract_ids[self.AttractMode] or 2,3)

			--numbers
			local using_decimal = (self.Radius % 1 ~= 0) and self.RescalePhysMesh
			net.WriteBool(using_decimal)
			if using_decimal then
				net.WriteFloat(self.Radius)
			else
				net.WriteUInt(self.Radius,12)
			end
			
			net.WriteUInt(self.DamageRadius,12)
			net.WriteUInt(self.Damage,24)
			net.WriteInt(1000*self.Speed,18)
			net.WriteUInt(self.Maximum,7)
			net.WriteUInt(100*self.LifeTime,14) --might need decimals
			net.WriteUInt(100*self.Delay,9) --might need decimals
			net.WriteUInt(self.Mass,16)
			net.WriteInt(100*self.Spread,10)
			net.WriteInt(100*self.Damping,20) --might need decimals
			net.WriteInt(self.Attract,14)
			net.WriteUInt(self.AttractRadius,10)
			net.WriteInt(100*self.Bounce,8) --might need decimals

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

			local ent = pac.CreateEntity(self.FallbackSurfpropModel)
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
				ent:PhysicsInitSphere(math.Clamp(self.Radius, 1, 500), self.SurfaceProperties)
			else
				ent:PhysicsInitBox(Vector(1,1,1) * - math.Clamp(self.Radius, 1, 500), Vector(1,1,1) * math.Clamp(self.Radius, 1, 500), self.SurfaceProperties)
				if self.OverridePhysMesh then
					local valid_fallback = util.IsValidModel( self.FallbackSurfpropModel ) and not IsUselessModel(self.FallbackSurfpropModel)
					ent:PhysicsInitBox(Vector(1,1,1) * - math.Clamp(self.Radius, 1, 500), Vector(1,1,1) * math.Clamp(self.Radius, 1, 500), self.FallbackSurfpropModel)
					if self.OverridePhysMesh and valid_fallback then
						ent:SetModel(self.FallbackSurfpropModel)
						ent:PhysicsInit(SOLID_VPHYSICS)
						ent:GetPhysicsObject():SetMaterial(self.SurfaceProperties)
					end
				end
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

			if self:AttachToEntity(ent, false) then

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
			for i = multi_projectile_count,1,-1 do
				spawn()
			end
		else
			timer.Simple(self.Delay, spawn)
		end
	end
end

function PART:SetRadius(val)
	self.Radius = val
	local sv_dist = GetConVar("pac_sv_projectile_max_phys_radius"):GetInt()
	if self.Radius > sv_dist then
		self:SetInfo("Your radius is beyond the server's maximum permitted! Server max is " .. sv_dist)
	else
		self:SetInfo(nil)
	end
end

function PART:SetDamageRadius(val)
	self.DamageRadius = val
	local sv_dist = GetConVar("pac_sv_projectile_max_damage_radius"):GetInt()
	if self.DamageRadius > sv_dist then
		self:SetInfo("Your damage radius is beyond the server's maximum permitted! Server max is " .. sv_dist)
	else
		self:SetInfo(nil)
	end
end

function PART:SetAttractRadius(val)
	self.AttractRadius = val
	local sv_dist = GetConVar("pac_sv_projectile_max_attract_radius"):GetInt()
	if self.AttractRadius > sv_dist then
		self:SetInfo("Your attract radius is beyond the server's maximum permitted! Server max is " .. sv_dist)
	else
		self:SetInfo(nil)
	end
end

function PART:SetSpeed(val)
	self.Speed = val
	local sv_max = GetConVar("pac_sv_projectile_max_speed"):GetInt()
	if self.Speed > sv_max then
		self:SetInfo("Your speed is beyond the server's maximum permitted! Server max is " .. sv_max)
	else
		self:SetInfo(nil)
	end
end

function PART:SetMass(val)
	self.Mass = val
	local sv_max = GetConVar("pac_sv_projectile_max_mass"):GetInt()
	if self.Mass > sv_max then
		self:SetInfo("Your mass is beyond the server's maximum permitted! Server max is " .. sv_max)
	elseif val > 50000 then
		self:SetInfo("The game has a maximum of 50k mass")
	else
		self:SetInfo(nil)
	end
end

function PART:SetDamage(val)
	self.Damage = val
	local sv_max = GetConVar("pac_sv_damage_zone_max_damage"):GetInt()
	if self.Damage > sv_max then
		self:SetInfo("Your damage is beyond the server's maximum permitted! Server max is " .. sv_max)
	else
		self:SetInfo(nil)
	end
end

pac.AddHook("Think", "pac_cleanup_CS_projectiles", function()
	for rootpart,ent in pairs(local_projectiles) do
		if ent.pac_projectile_part == rootpart then
			local tbl = ent.pac_projectile_part:GetChildren()
			local partchild = tbl[next(tbl)] --ent.pac_projectile_part is the root group, but outfit part is the first child

			if IsValid(partchild) then
				if partchild:IsHidden() then
					SafeRemoveEntity(ent)
				end
			end
		end
	end

end)

--[[
function PART:OnHide()
	if self.RemoveOnHide then
		self:OnRemove()
	end
end
]]

--[[if ent.pac_projectile_part then
	local partchild = next(ent.pac_projectile_part:GetChildren()) --ent.pac_projectile_part is the root group, but outfit part is the first child
	if IsValid(part) then
		if partchild:IsHidden() then
			if ent.pac_projectile.RemoveOnHide then
				net.Start("pac_projectile_remove")
				net.WriteInt(data.ent_id)
				net.SendToServer()
			end
		end
	end
end]]

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
				local part = pac.FindPartByPartialUniqueID(pac.Hash(data.ply), data.partuid)
				if part:IsValid() and part:GetPlayerOwner() == data.ply then
					part:AttachToEntity(ent, true)
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
		local surfprop = net.ReadString()

		if ply:IsValid() then
			table.insert(projectiles, {ply = ply, ent_id = ent_id, partuid = partuid})
		end

		local ent = Entity(ent_id)

		ent.Think = function()
			if ent.pac_projectile_part then
				local tbl = ent.pac_projectile_part:GetChildren()
				local partchild = tbl[next(tbl)] --ent.pac_projectile_part is the root group, but outfit part is the first child
				if IsValid(partchild) then
					if partchild:IsHidden() then
						if ent.pac_projectile.RemoveOnHide and not ent.markedforremove then
							ent.markedforremove = true
							net.Start("pac_projectile_remove")
							net.WriteInt(ent_id, 16)
							net.SendToServer()

						end
					end
				end

			end
		end
	end)
end

BUILDER:Register()
