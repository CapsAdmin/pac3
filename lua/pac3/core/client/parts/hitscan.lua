language.Add("pac_hitscan", "Hitscan")
--local vector_origin = vector_origin
--local angle_origin = Angle(0,0,0)
--local WorldToLocal = WorldToLocal

local BUILDER, PART = pac.PartTemplate("base_drawable")

PART.ClassName = "hitscan"
PART.Group = "combat"
PART.Icon = "icon16/user_gray.png"

BUILDER:StartStorableVars()
	:GetSet("ServerBullets", true, {description = "serverside bullets can do damage and exert a physical impact force"})
	:SetPropertyGroup("bullet properties")
		:GetSet("BulletImpact", false)
		:GetSet("Damage", 1, {editor_onchange = function (self,val) return math.floor(math.Clamp(val,0,268435455)) end})
		:GetSet("Force",1000, {editor_onchange = function (self,val) return math.floor(math.Clamp(val,0,65535)) end})
		:GetSet("AffectSelf", false, {description = "whether to allow to damage yourself"})
		:GetSet("DamageFalloff", false, {description = "enable damage falloff. The lowest damage is not a fixed damage number, but a fraction of the total initial damage.\nThe server can still restrict the maximum distance of all bullets"})
		:GetSet("DamageFalloffDistance", 5000, {editor_onchange = function (self,val) return math.floor(math.Clamp(val,0,65535)) end})
		:GetSet("DamageFalloffFraction", 0.5, {editor_clamp = {0,1}})
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
		:GetSet("NumberBullets", 1, {editor_onchange = function (self,val) return math.floor(math.Clamp(val,0,511)) end})
		:GetSet("DistributeDamage", false, {description = "whether or not the damage should be divided equally to all bullets in NumberBullets.\nThe server can still force multi-shots to do that"})
		:GetSet("TracerSparseness", 1, {editor_onchange = function (self,val) return math.floor(math.Clamp(val,0,255)) end})
		:GetSet("MaxDistance", 10000, {editor_onchange = function (self,val) return math.floor(math.Clamp(val,0,65535)) end})
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
	if not GetConVar("pac_sv_hitscan"):GetBool() or pac.Blocked_Combat_Parts[self.ClassName] then self:SetError("hitscan parts are disabled on this server!") end
end

function PART:OnShow()
	self:Shoot()
end

function PART:OnDraw()
	self:GetWorldPosition()
	self:GetWorldAngles()
end

function PART:Shoot()
	if self.NumberBullets == 0 then return end
	if self.ServerBullets and self.Damage ~= 0 then
		self:SendNetMessage()
	else
		self.bulletinfo.Attacker = self:GetRootPart():GetOwner()
		self.ent = self:GetRootPart():GetOwner()
		if self.Damage ~= 0 then self.bulletinfo.Damage = self.Damage end

		self.bulletinfo.Src = self:GetWorldPosition()
		self.bulletinfo.Dir = self:GetWorldAngles():Forward()
		self.bulletinfo.Spread = Vector(self.SpreadX*self.Spread,self.SpreadY*self.Spread,0)

		self.bulletinfo.Force = self.Force
		self.bulletinfo.Distance = self.MaxDistance
		self.bulletinfo.Num = self.NumberBullets
		self.bulletinfo.Tracer = self.TracerSparseness --tracer every x bullets
		self.bulletinfo.TracerName = self.TracerName
		self.bulletinfo.DistributeDamage = self.DistributeDamage

		self.bulletinfo.DamageFalloff = self.DamageFalloff
		self.bulletinfo.DamageFalloffDistance = self.DamageFalloffDistance
		self.bulletinfo.DamageFalloffFraction = self.DamageFalloffFraction

		if IsValid(self.ent) then self.ent:FireBullets(self.bulletinfo) end
	end
end


--NOT THE ACTUAL DAMAGE TYPES. UNIQUE IDS TO COMPRESS NET MESSAGES
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

	fire = 31, -- ent:Ignite(5)

	-- env_entity_dissolver
	dissolve_energy = 32,
	dissolve_heavy_electrical = 33,
	dissolve_light_electrical = 34,
	dissolve_core_effect = 35,

	heal = 36,
	armor = 37,
}

local tracer_ids = {
	["Tracer"] = 1,
	["AR2Tracer"] = 2,
	["HelicopterTracer"] = 3,
	["AirboatGunTracer"] = 4,
	["AirboatGunHeavyTracer"] = 5,
	["GaussTracer"] = 6,
	["HunterTracer"] = 7,
	["StriderTracer"] = 8,
	["GunshipTracer"] = 9,
	["ToolgunTracer"] = 10,
	["LaserTracer"] = 11
}


function PART:SendNetMessage()
	if pac.LocalPlayer ~= self:GetPlayerOwner() then return end
	if not GetConVar('pac_sv_hitscan'):GetBool() then return end
	if util.NetworkStringToID( "pac_hitscan" ) == 0 then self:SetError("This part is deactivated on the server") return end
	pac.Blocked_Combat_Parts = pac.Blocked_Combat_Parts or {}
	if pac.Blocked_Combat_Parts[self.ClassName] then
		return
	end
	if not GetConVar("pac_sv_combat_enforce_netrate_monitor_serverside"):GetBool() then
		if not pac.CountNetMessage() then self:SetInfo("Went beyond the allowance") return end
	end

	net.Start("pac_hitscan", true)
	net.WriteBool(self.AffectSelf)
	net.WriteVector(self:GetWorldPosition())
	net.WriteAngle(self:GetWorldAngles())

	net.WriteUInt(damage_ids[self.DamageType] or 0,7)
	net.WriteUInt(math.abs(math.Clamp(10000 * self.SpreadX*self.Spread, 0, 1048575)), 20)
	net.WriteUInt(math.abs(math.Clamp(10000 * self.SpreadY*self.Spread, 0, 1048575)), 20)
	net.WriteUInt(self.Damage, 28)
	net.WriteUInt(self.TracerSparseness, 8)
	net.WriteUInt(self.Force, 16)
	net.WriteUInt(self.MaxDistance, 16)
	net.WriteUInt(self.NumberBullets, 9)
	net.WriteUInt(tracer_ids[self.TracerName], 4)
	net.WriteBool(self.DistributeDamage)

	net.WriteBool(self.DamageFalloff)
	net.WriteUInt(self.DamageFalloffDistance, 16)
	net.WriteUInt(math.Clamp(math.floor(self.DamageFalloffFraction * 1000),0, 1000), 10)

	net.WriteString(string.sub(self.UniqueID,1,8))

	net.SendToServer()
end

function PART:SetDamage(val)
	self.Damage = val
	local sv_max = GetConVar("pac_sv_hitscan_max_damage"):GetInt()
	if self.Damage > sv_max then
		self:SetInfo("Your damage is beyond the server's maximum permitted! Server max is " .. sv_max)
	else
		self:SetInfo(nil)
	end
end

function PART:SetNumberBullets(val)
	self.NumberBullets = val
	local sv_max = GetConVar("pac_sv_hitscan_max_bullets"):GetInt()
	if self.NumberBullets > sv_max then
		self:SetInfo("Your bullet count is beyond the server's maximum permitted! Server max is " .. sv_max)
	else
		self:SetInfo(nil)
	end
end


BUILDER:Register()

