language.Add("pac_hitscan", "Hitscan")
local ent
local bulletinfo = {}
--local vector_origin = vector_origin
--local angle_origin = Angle(0,0,0)
--local WorldToLocal = WorldToLocal

local BUILDER, PART = pac.PartTemplate("base_drawable")

PART.ClassName = "hitscan"
PART.Group = 'advanced'
PART.Icon = 'icon16/user_gray.png'

BUILDER:StartStorableVars()
	:GetSet("ServerBullets",true)
	:SetPropertyGroup("bullet properties")
		:GetSet("BulletImpact", false)
		:GetSet("Damage", 0)
		:GetSet("Force",1000)
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

function PART:OnShow()
	self:UpdateBulletInfo()
	self:GetWorldPosition()
	self:GetWorldAngles()
	self:Shoot(self:GetDrawPosition())
end

function PART:OnDraw()
	self:GetWorldPosition()
	self:GetWorldAngles()
end

function PART:Shoot(pos, ang)
	bulletinfo.Tracer = self.TracerSparseness
	bulletinfo.Src = pos
	bulletinfo.Dir = ang:Forward()
	bulletinfo.Spread = Vector(self.SpreadX*self.Spread,self.SpreadY*self.Spread,0)

	ent = self:GetOwner()
	if self.ServerBullets then
		print("WE NEED A BULLET IN THE SERVER!")
		net.Start("pac_hitscan")
		net.WriteEntity(ent)
		net.WriteTable(bulletinfo)
		net.SendToServer()
	else
		ent:FireBullets(bulletinfo)
	end
end

function PART:UpdateBulletInfo()
	bulletinfo.Attacker = ent
	if self.Damage == 0 then
	else bulletinfo.Damage = self.Damage end

	bulletinfo.Force = self.Force
	bulletinfo.Distance = self.MaxDistance
	bulletinfo.Num = self.NumberBullets
	bulletinfo.Tracer = self.TracerSparseness --tracer every x bullets
	bulletinfo.TracerName = self.TracerName

	--[[bulletinfo.ammodata = {
		name = ""
		dmgtype = self.DamageType
		tracer = TRACER_LINE_AND_WHIZ
		maxcarry = -2

	}]]--
end


BUILDER:Register()

