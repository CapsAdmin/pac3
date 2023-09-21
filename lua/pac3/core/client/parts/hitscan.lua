language.Add("pac_hitscan", "Hitscan")
--local vector_origin = vector_origin
--local angle_origin = Angle(0,0,0)
--local WorldToLocal = WorldToLocal

local BUILDER, PART = pac.PartTemplate("base_drawable")

PART.ClassName = "hitscan"
PART.Group = 'advanced'
PART.Icon = 'icon16/user_gray.png'

BUILDER:StartStorableVars()
	:GetSet("ServerBullets",true, {description = "serverside bullets can do damage and exert a physical impact force"})
	:SetPropertyGroup("bullet properties")
		:GetSet("BulletImpact", false)
		:GetSet("Damage", 0)
		:GetSet("Force",1000)
		:GetSet("DamageFalloff", false, {description = "enable damage falloff. The lowest damage is not a fixed damage number, but a fraction of the total initial damage.\nThe server can still restrict the maximum distance of all bullets"})
		:GetSet("DamageFalloffDistance", 5000)
		:GetSet("DamageFalloffFraction", 0.5)
		
		:GetSet("DamageType", "generic", {enums = {
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
		:GetSet("Spread", 0)
		:GetSet("SpreadX", 1)
		:GetSet("SpreadY", 1)
		:GetSet("NumberBullets", 1)
		:GetSet("DistributeDamage", false, {description = "whether or not the damage should be divided equally to all bullets in NumberBullets.\nThe server can still force multi-shots to do that"})
		:GetSet("TracerSparseness", 1)
		:GetSet("MaxDistance", 10000)
		:GetSet("TracerName", "Tracer", {enums = {
			["Default bullet tracer"] = "Tracer",
			["AR2 pulse-rifle tracer"] = "AR2Tracer",
			["Helicopter tracer"] = "HelicopterTracer",
			["Airboat gun tracer"] = "AirboatGunTracer",
			["Airboat gun heavy tracer"] = "AirboatGunHeavyTracer",
			["Gauss tracer"] = "GaussTracer",
			["Hunter tracer"] = "HunterTracer",
			["Strider tracer"] = "StriderTracer",
			["Gunship tracer"] = "GunshipTracer",
			["Toolgun tracer"] = "ToolTracer",
			["Laser tracer"] = "LaserTracer"
		}})
		
BUILDER:EndStorableVars()

function PART:Initialize()
	self.bulletinfo = {}
	self.ent = self:GetRootPart():GetOwner()
	self:UpdateBulletInfo()
end

function PART:OnShow()
	self:UpdateBulletInfo()
	--self:GetWorldPosition()
	--self:GetWorldAngles()
	self:Shoot(self:GetDrawPosition())
end

function PART:OnDraw()
	self:GetWorldPosition()
	self:GetWorldAngles()
end

function PART:Shoot(pos, ang)
	if not self.ent then self:UpdateBulletInfo() end
	if not IsValid(self.ent) then return end

	self.bulletinfo.Src = pos
	self.bulletinfo.Dir = ang:Forward()
	self.bulletinfo.Spread = Vector(self.SpreadX*self.Spread,self.SpreadY*self.Spread,0)

	if self.NumberBullets == 0 then return end
	if self.ServerBullets and self.Damage ~= 0 then
		--print("WE NEED A BULLET IN THE SERVER!")
		--PrintTable(self.bulletinfo)
		
		net.Start("pac_hitscan")
		net.WriteEntity(self:GetRootPart():GetOwner())
		net.WriteTable(self.bulletinfo)
		net.WriteAngle(ang)
		net.WriteString(self.UniqueID)
		net.SendToServer()
	else
		self.ent:FireBullets(self.bulletinfo)
	end
end

function PART:UpdateBulletInfo()
	self.bulletinfo.Attacker = self:GetRootPart():GetOwner()
	self.ent = self:GetRootPart():GetOwner()
	if self.Damage == 0 then
	else self.bulletinfo.Damage = self.Damage end

	self.bulletinfo.Tracer = self.TracerSparseness

	self.bulletinfo.Force = self.Force
	self.bulletinfo.Distance = self.MaxDistance
	self.bulletinfo.Num = self.NumberBullets
	self.bulletinfo.Tracer = self.TracerSparseness --tracer every x bullets
	self.bulletinfo.TracerName = self.TracerName
	self.bulletinfo.DistributeDamage = self.DistributeDamage

	self.bulletinfo.DamageFalloff = self.DamageFalloff
	self.bulletinfo.DamageFalloffDistance = self.DamageFalloffDistance
	self.bulletinfo.DamageFalloffFraction = self.DamageFalloffFraction

	--[[bulletinfo.ammodata = {
		name = ""
		dmgtype = self.DamageType
		tracer = TRACER_LINE_AND_WHIZ
		maxcarry = -2

	}]]--
end


BUILDER:Register()

