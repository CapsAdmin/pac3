local BUILDER, PART = pac.PartTemplate("base_movable")

--ultrakill parryables: club, slash, buckshot

PART.ClassName = "damage_zone"
PART.Group = 'advanced'
PART.Icon = 'icon16/package.png'

local renderhooks = {
	"PostDraw2DSkyBox",
	"PostDrawOpaqueRenderables",
	"PostDrawSkyBox",
	"PostDrawTranslucentRenderables",
	"PostDrawViewModel",
	"PostPlayerDraw",
	"PreDrawEffects",
	"PreDrawHalos",
	"PreDrawOpaqueRenderables",
	"PreDrawSkyBox",
	"PreDrawTranslucentRenderables",
	"PreDrawViewModel"
}


BUILDER:StartStorableVars()
	:SetPropertyGroup("Targets")
		:GetSet("AffectSelf",false)
		:GetSet("Players",true)
		:GetSet("NPC",true)
		:GetSet("PointEntities",true, {description = "Other source engine entities such as item_item_crate and prop_physics"})
	:SetPropertyGroup("Shape and Sampling")
		:GetSet("Radius", 20)
		:GetSet("Length", 50)
		:GetSet("HitboxMode", "Box", {enums = {
			["Box"] = "Box",
			["Cube"] = "Cube",
			["Sphere"] = "Sphere",
			["Cylinder (Raycasts Only)"] = "Cylinder",
			["Cylinder (Hybrid)"] = "CylinderHybrid",
			["Cylinder (From Spheres)"] = "CylinderSpheres",
			["Cone (Raycasts Only)"] = "Cone",
			["Cone (Hybrid)"] = "ConeHybrid",
			["Cone (From Spheres)"] = "ConeSpheres",
			["Ray"] = "Ray"
		}})
		:GetSet("Detail", 20)
		:GetSet("ExtraSteps",0)
		:GetSet("RadialRandomize", 1)
		:GetSet("PhaseRandomize", 1)
	:SetPropertyGroup("Falloff")
		:GetSet("DamageFalloff", false)
		:GetSet("DamageFalloffPower", 1)
	:SetPropertyGroup("Preview Rendering")
		:GetSet("Preview", false)
		:GetSet("RenderingHook", "PostDrawOpaqueRenderables", {enums = {
			["PostDraw2DSkyBox"] = "PostDraw2DSkyBox",
			["PostDrawOpaqueRenderables"] = "PostDrawOpaqueRenderables",
			["PostDrawSkyBox"] = "PostDrawSkyBox",
			["PostDrawTranslucentRenderables"] = "PostDrawTranslucentRenderables",
			["PostDrawViewModel"] = "PostDrawViewModel",
			["PostPlayerDraw"] = "PostPlayerDraw",
			["PreDrawEffects"] = "PreDrawEffects",
			["PreDrawHalos"] = "PreDrawHalos",
			["PreDrawOpaqueRenderables"] = "PreDrawOpaqueRenderables",
			["PreDrawSkyBox"] = "PreDrawSkyBox",
			["PreDrawTranslucentRenderables"] = "PreDrawTranslucentRenderables",
			["PreDrawViewModel"] = "PreDrawViewModel"
		}})
	:SetPropertyGroup("DamageInfo")
		:GetSet("Bullet", false, {description = "Fires a bullet on each target for the added hit decal"})
		:GetSet("Damage", 0)
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

			fire = -1, -- ent:Ignite(5)

			-- env_entity_dissolver
			dissolve_energy = 0,
			dissolve_heavy_electrical = 1,
			dissolve_light_electrical = 2,
			dissolve_core_effect = 3,

			heal = -1,
			armor = -1,
		}})
		:GetSet("DoNotKill",false, {description = "Will only damage to as low as critical health"})
		:GetSet("CriticalHealth",1)
	:SetPropertyGroup("HitOutcome")
		:GetSetPart("HitSoundPart")
		:GetSetPart("KillSoundPart")
		:GetSetPart("HitMarkerPart")
		:GetSet("HitMarkerLifetime", 1)
		:GetSetPart("KillMarkerPart")
		:GetSet("KillMarkerLifetime", 1)
		:GetSet("AllowOverlappingHitSounds", false, {description = "If false, then when there are entities killed, do not play the hit sound part at the same time, since the kill sound takes priority"})
		:GetSet("AllowOverlappingHitMarkers", false, {description = "If false, then for entities killed, do not spawn the hit marker part, since the kill marker takes priority and we don't want an overlap"})
		:GetSet("RemoveDuplicateHitMarkers", true, {description = "If true, hit markers on an entity will be removed before creating a new one.\nBE WARNED. You still have a limited budget to create hit markers. It will be enforced."})
		:GetSet("RemoveNPCWeaponsOnKill",false)
BUILDER:EndStorableVars()





--a budget system to prevent mass abuse of hit marker parts
function CalculateHitMarkerPrice(part)
	if not part then return end

	if not part.known_hitmarker_size then part.known_hitmarker_size = 2*#util.TableToJSON(part:ToTable()) end
	return part.known_hitmarker_size
end

function HasBudget(owner, part)
	if not owner.pac_dmgzone_hitmarker_budget then
		owner.pac_dmgzone_hitmarker_budget = 50000 --50kB's worth of pac parts
	end
	
	if part then --calculate based on an additional part added
		--print("budget:" .. string.NiceSize(owner.pac_dmgzone_hitmarker_budget) .. ", cost: " .. string.NiceSize(CalculateHitMarkerPrice(part)))
		return owner.pac_dmgzone_hitmarker_budget - CalculateHitMarkerPrice(part) > 0
	else --get result from current state
		--print("budget:" .. string.NiceSize(owner.pac_dmgzone_hitmarker_budget))
		return owner.pac_dmgzone_hitmarker_budget > 0
	end
end

function PART:LaunchAuditAndEnforceSoftBan(amount, reason)
	if reason == "recursive loop" then
		self.stop_until = CurTime() + 3600
		owner.stop_hit_markers_until = CurTime() + 3600
		Derma_Message("HEY! You know infinite recursive loops are super duper dangerous?")
		surface.PlaySound("garrysmod/ui_return.wav")
		return
	end
	local owner = self:GetPlayerOwner()
	if owner ~= LocalPlayer() then return end
	owner.stop_hit_markers_admonishment_count = owner.stop_hit_markers_admonishment_count or 1
	owner.stop_hit_markers_admonishment_message_up = false
	local str_admonishment = "WARNING.\n"
	str_admonishment = str_admonishment .. "One of your hit marker parts is way too big. It went ".. string.NiceSize(amount) .. " overbudget at ONCE.\n"
	if self.HitBoxMode ~= "Ray" then
		if self.Radius > 300 or self.Length > 300 then
			str_admonishment = str_admonishment .. "Your damage zone is oversized too. Are you purposefully trying to target large numbers of targets?\n"
		end
	end
	str_admonishment = str_admonishment .. owner.stop_hit_markers_admonishment_count .. " warnings so far\n"
	if owner.stop_hit_markers_admonishment_count > 5 then
		self.stop_until = CurTime() + 2
		owner.stop_hit_markers_until = CurTime() + 180 --that's rough but necessary
		str_admonishment = str_admonishment .. "FIVE TIMES REPEAT OFFENDER. ENJOY YOUR BAN.\n"
	end

	self:SetWarning("One of your hit marker parts is way too big. It went ".. string.NiceSize(amount) .. " overbudget at ONCE.")
	timer.Simple(0.5, function() --don't open duplicate windows
		if not owner.stop_hit_markers_admonishment_message_up then
			surface.PlaySound("garrysmod/ui_return.wav")
			Derma_Message(str_admonishment)
			self:SetError(str_admonishment.."This part will be limited for 3 minutes")
			owner.stop_hit_markers_admonishment_message_up = true
			owner.stop_hit_markers_admonishment_count = owner.stop_hit_markers_admonishment_count + 1
			print(str_admonishment)
		end
	end)
	
end

function PART:ClearBudgetAdmonishmentWarning()
	self:SetError() self:SetWarning()
	owner = self:GetPlayerOwner()
	owner.stop_hit_markers_admonishment_message_up = false
	owner.stop_hit_markers_until = 0
end

local global_hitmarker_CSEnt_seed = 0

local spawn_queue = {}
local tick = 0

--multiple entities targeted + hit marker creating parts and setting up every time = FRAME DROPS
--so we tried the budget method, it didn't change the fact that it costs a lot.

--next solution:
--a table of 20 hit part slots to unhide instead of creating parts every time
--each player commands a table of hitmarker slots
--each slot has an entry for a hitpart which will be like a pigeon-hole for clientside hitmarker ents to share
--hitmarker removal will free up the slot
--[[
	owner.hitparts[free] = {
		active = true,
		specimen_part = FindOrCreateFloatingPart(ent, part_uid),
		hitmarker_id = ent_id,
		template_uid = part_uid
	}
]]

--add : go up until we find a free spot, register it in the table until the marker is removed and the entry is marked as inactive
--remove: go up until we find the spot with the same ent id and part uid


--hook.Add("Tick", "pac_spawn_hit")

local part_setup_runtimes = 0

--the floating part pool is player-owned
--uid-indexed for every individual part instance
--each entry is a table
--[[
	{
		active
		template_uid		--to identify from which part it's derived
		hitmarker_id		--to identify what entity it's attached to
		
	}
]]

local function FindOrCreateFloatingPart(owner, part_uid)
	owner.hitmarker_partpool = owner.hitmarker_partpool or {}
	
	for spec_uid,tbl in pairs(owner.hitmarker_partpool) do
		if tbl.template_uid == part_uid then
			if not tbl.active then
				return part --whoowee we found an already existing part
			end
		end
	end

	return part

end

local function FreeSpotInStack(owner)
	owner.hitparts = owner.hitparts or {}
	for i=1,20,1 do
		if owner.hitparts[i] then
			if not owner.hitparts[i].active then
				return i
			end
		else
			return i
		end
	end
	return nil
end

local function MatchInStack(owner, ent)
	owner.hitparts = owner.hitparts or {}
	for i=1,20,1 do
		if owner.hitparts[i] then
			--match: entry's template uid is the same as entity's template uid
			--if there's more, still match entry's specimen ID with specimen ID
			if owner.hitparts[i].pac_hitmarker_template_id == ent.pac_hitmarker_template_id and owner.hitparts[i].hitmarker_id == ent.marker_id then
				return i
			end
		end
	end
	return nil
end

local function AddHitMarkerToStack(owner, ent, part_uid, ent_id)
	owner.hitparts = owner.hitparts or {}
	local free = FreeSpotInStack()
	if free then
		owner.hitparts[free] = {active = true, specimen_part = FindOrCreateFloatingPart(ent, part_uid), hitmarker_id = ent_id, template_uid = part_uid}
	end
end

local function RemoveHitMarker(owner, ent)
	owner.hitparts = owner.hitparts or {}
	local match = MatchInStack(owner, ent)
	if match then
		owner.hitparts[match].active = false
	end
	SafeRemoveEntity(ent)
end

--grabbed the function from projectile.lua
function PART:AttachToEntity(part, ent, parent_ent, marker_id)
	if not part:IsValid() then return false end

	ent.pac_draw_distance = 0

	local tbl = part:ToTable()

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

	ent:CallOnRemove("pac_dmgzone_hitmarker_" .. id, function()
		group:Remove()
	end)
	group:CallRecursive("Think")
	
	parent_ent.pac_dmgzone_hitmarker_ents = parent_ent.pac_dmgzone_hitmarker_ents or {}
	ent.part = group
	ent.pac_hitmarker_template_id = part.UniqueID
	parent_ent.pac_dmgzone_hitmarker_ents[marker_id] = ent
	ent.marker_id = marker_id

	return true
end

local function RecursedHitmarker(part)
	if part.HitMarkerPart == part or part.KillMarkerPart == part then
		return true
	end
	if IsValid(part.HitMarkerPart) then
		for i,child in pairs(part.HitMarkerPart:GetChildrenList()) do
			if child.ClassName == "damage_zone" then
				if child.HitMarkerPart == part or child.KillMarkerPart == part then
					return true
				end
			end
		end
	end
	if IsValid(part.KillMarkerPart) then
		for i,child in pairs(part.KillMarkerPart:GetChildrenList()) do
			if child.ClassName == "damage_zone" then
				if child.HitMarkerPart == part or child.KillMarkerPart == part then
					return true
				end
			end
		end
	end
	
end

function PART:OnShow()
	if self.Preview then
		self:PreviewHitbox()
	end
	self.stop_until = self.stop_until or 0
	if self.stop_until then self:GetPlayerOwner().stop_hit_markers_admonishment_message_up = nil end
	if (self:GetPlayerOwner().stop_hit_markers_admonishment_message_up) or self.stop_until > CurTime() then return end

	if self:GetRootPart():GetOwner() ~= self:GetPlayerOwner() then --dumb workaround for when it activates before it realizes it needs to be hidden first
		timer.Simple(0.01, function() --wait to check if needs to be hidden first
			if self:IsHidden() or self:IsDrawHidden() then return end
			if self.Preview then
				self:PreviewHitbox()
			end
			if pac.LocalPlayer ~= self:GetPlayerOwner() then return end
			local tbl = {}
			for key in pairs(self:GetStorableVars()) do
				tbl[key] = self[key]
			end
			net.Start("pac_request_zone_damage")
			net.WriteVector(self:GetWorldPosition())
			net.WriteAngle(self:GetWorldAngles())
			net.WriteTable(tbl)
			net.WriteEntity(self:GetPlayerOwner())
			net.SendToServer()
		end)
	elseif (self.validTime > SysTime()) then
		return
	else
		if pac.LocalPlayer ~= self:GetPlayerOwner() then return end
		local tbl = {}
		for key in pairs(self:GetStorableVars()) do
			tbl[key] = self[key]
		end
		net.Start("pac_request_zone_damage")
		net.WriteVector(self:GetWorldPosition())
		net.WriteAngle(self:GetWorldAngles())
		net.WriteTable(tbl)
		net.WriteEntity(self:GetPlayerOwner())
		net.SendToServer()
	end

	net.Receive("pac_hit_results", function()
		
		local hit = net.ReadBool()
		local kill = net.ReadBool()
		local highest_dmg = net.ReadFloat()
		local ents_hit = net.ReadTable()
		local ents_kill = net.ReadTable()
		part_setup_runtimes = 0

		if RecursedHitmarker(self) then
			self:LaunchAuditAndEnforceSoftBan(nil,"recursive loop")
		end

		local pos = self:GetWorldPosition()
		local owner = self:GetPlayerOwner()

		self.lag_risk = table.Count(ents_hit) > 15

		local function ValidSound(part)
			if part ~= nil then
				if part.ClassName == "sound" or part.ClassName == "sound2" then
					return true
				end
			end
			return false
		end
		--grabbed the function from projectile.lua
		--here, we spawn a static hitmarker and the max delay is 8 seconds
		local function spawn(part, pos, ang, parent_ent, duration, owner)
			if part == self then return end --stop infinite feedback loops of using the damagezone as a hitmarker
			--what if people employ a more roundabout method? CRACKDOWN!
			

			if not owner.hitparts then owner.hitparts = {} end
			if not owner.hitparts_floatingparts then owner.hitparts_floatingparts = {} end

			if owner.stop_hit_markers_until then
				if owner.stop_hit_markers_until > CurTime() then return end
			end
			if self.lag_risk and math.random() > 0.5 then return end
			if not self:IsValid() then return end
			if not part:IsValid() then return end

			if not HasBudget(owner, part) then
				local overbudget = math.abs(owner.pac_dmgzone_hitmarker_budget - CalculateHitMarkerPrice(part))
				if overbudget > 10000 then
					self:LaunchAuditAndEnforceSoftBan(overbudget)
				end
				--print(owner, "is trying to go over budget by " .. string.NiceSize(math.abs(overbudget)))
				return
			else
				timer.Simple(1, function() self:ClearBudgetAdmonishmentWarning() end)
				local budget_add = CalculateHitMarkerPrice(part)
				--print(owner, "is within budget with " .. owner.pac_dmgzone_hitmarker_budget .. " left. can add " .. string.NiceSize(budget_add))
				owner.pac_dmgzone_hitmarker_budget = owner.pac_dmgzone_hitmarker_budget - CalculateHitMarkerPrice(part)
			end

			local start = SysTime()
			local ent = pac.CreateEntity("models/props_junk/popcan01a.mdl")
			if not ent:IsValid() then return end
			ent:SetNoDraw(true)
			ent:SetOwner(self:GetPlayerOwner(true))
			ent:SetPos(pos)
			ent:SetAngles(ang)
			global_hitmarker_CSEnt_seed = global_hitmarker_CSEnt_seed + 1

			--the spawn order needs to decide whether it can or can't create an ent or part

			local flush = self.RemoveDuplicateHitMarkers
			if flush then
				--go through the entity and remove the clientside hitmarkers entities
				if parent_ent.pac_dmgzone_hitmarker_ents then
					for id,ent in pairs(parent_ent.pac_dmgzone_hitmarker_ents) do
						if IsValid(ent) then
							if ent.part:IsValid() then
								owner.pac_dmgzone_hitmarker_budget = owner.pac_dmgzone_hitmarker_budget + CalculateHitMarkerPrice(part)
								ent.part:Remove()
							end
							RemoveHitMarker(ent, part.UniqueID, id)
						end
					end
				end
			end
			if FreeSpotInStack(owner) then
				if self:AttachToEntity(part, ent, parent_ent, global_hitmarker_CSEnt_seed) then
					timer.Simple(math.Clamp(duration, 0, 8), function()
						if ent:IsValid() then
							if parent_ent.pac_dmgzone_hitmarker_ents then
								for id,ent in pairs(parent_ent.pac_dmgzone_hitmarker_ents) do
									if IsValid(ent) then
										if ent.part:IsValid() then
											owner.pac_dmgzone_hitmarker_budget = owner.pac_dmgzone_hitmarker_budget + CalculateHitMarkerPrice(part)
											ent.part:Remove()
										end
										RemoveHitMarker(ent, part.UniqueID, id)
									end
								end
							end
	
							timer.Simple(0.5, function()
								RemoveHitMarker(ent, part.UniqueID, id)
							end)
						end
					end)
				end
			end
			
			local creation_delta = SysTime() - start
			--print(string.NiceTime(creation_delta))
			--print(100000 * creation_delta / CalculateHitMarkerPrice(part) .. "budget score")
			return creation_delta
		end

		if IsValid(self.HitMarkerPart) then
			--(self.HitMarkerPart, "price is", string.NiceSize(CalculateHitMarkerPrice(self.HitMarkerPart)))
		end

		if hit then
			self.dmgzone_hit_done = CurTime()
			--try not to play both sounds at once
			if ValidSound(self.HitSoundPart) then
				--if can overlap, always play
				if self.AllowOverlappingHitSounds then 
					self.HitSoundPart:PlaySound()
				--if cannot overlap, only play if there's only one entity or if we didn't kill
				elseif (table.Count(ents_kill) == 1) or not (kill and ValidSound(self.KillSoundPart)) then
					self.HitSoundPart:PlaySound()
				end
			end
			for ent,_ in pairs(ents_hit) do
				if IsValid(ent) then
					local ang = (ent:GetPos() - pos):Angle()
					if ents_kill[ent] then
						if self.AllowOverlappingHitMarkers then
							part_setup_runtimes = part_setup_runtimes + (spawn(self.HitMarkerPart, ent:WorldSpaceCenter(), ang, ent, self.HitMarkerLifetime, owner) or 0)
						end
					else
						part_setup_runtimes = part_setup_runtimes + (spawn(self.HitMarkerPart, ent:WorldSpaceCenter(), ang, ent, self.HitMarkerLifetime, owner) or 0)
					end
				end
			end
		end
		if kill then
			self.dmgzone_kill_done = CurTime()
			if ValidSound(self.KillSoundPart) then
				self.KillSoundPart:PlaySound()
			end

			for ent,_ in pairs(ents_kill) do
				if IsValid(ent) then
					local ang = (ent:GetPos() - pos):Angle()
					part_setup_runtimes = part_setup_runtimes + (spawn(self.KillMarkerPart, ent:WorldSpaceCenter(), ang, ent, self.KillMarkerLifetime, owner) or 0)
				end
			end
		end
		if IsValid(self.HitMarkerPart) then
			--print("runtimes were " .. string.FormattedTime( part_setup_runtimes).ms .. "ms.\n\t" .. 1000*part_setup_runtimes .. " impact.\n\t" .. table.Count(self.HitMarkerPart:GetChildrenList()) .. " children, " .. 1000*part_setup_runtimes / table.Count(self.HitMarkerPart:GetChildrenList()) .. " impact per children")
		end
	end)
	
end

function PART:OnHide()
	hook.Remove(self.RenderingHook, "pace_draw_hitbox"..self.UniqueID)
	for _,v in pairs(renderhooks) do
		hook.Remove(v, "pace_draw_hitbox"..self.UniqueID)
	end
end

function PART:OnRemove()
	hook.Remove(self.RenderingHook, "pace_draw_hitbox")
	for _,v in pairs(renderhooks) do
		hook.Remove(v, "pace_draw_hitbox")
	end
end

local previousRenderingHook

function PART:PreviewHitbox()
	
	if previousRenderingHook ~= self.RenderingHook then
		for _,v in pairs(renderhooks) do
			hook.Remove(v, "pace_draw_hitbox"..self.UniqueID)
		end
		previousRenderingHook = self.RenderingHook
	end

	if not self.Preview then return end

	hook.Add(self.RenderingHook, "pace_draw_hitbox"..self.UniqueID, function()
		if not self.Preview then hook.Remove(self.RenderingHook, "pace_draw_hitbox"..self.UniqueID) end
		self:GetWorldPosition()
		if self.HitboxMode == "Box" then
			local mins =  Vector(-self.Radius, -self.Radius, -self.Length)
			local maxs = Vector(self.Radius, self.Radius, self.Length)
			render.DrawWireframeBox( self:GetWorldPosition(), Angle(0,0,0), mins, maxs, Color( 255, 255, 255 ) )
		elseif self.HitboxMode == "Cube" then
			--mat:Rotate(Angle(SysTime()*100,0,0))
			local mins =  Vector(-self.Radius, -self.Radius, -self.Radius)
			local maxs = Vector(self.Radius, self.Radius, self.Radius)
			render.DrawWireframeBox( self:GetWorldPosition(), Angle(0,0,0), mins, maxs, Color( 255, 255, 255 ) )
		elseif self.HitboxMode == "Sphere" then
			render.DrawWireframeSphere( self:GetWorldPosition(), self.Radius, 10, 10, Color( 255, 255, 255 ) )
		elseif self.HitboxMode == "Cylinder" or self.HitboxMode == "CylinderHybrid" then
			local obj = Mesh()
			self:BuildCylinder(obj)
			render.SetMaterial( Material( "models/wireframe" ) )
			mat = Matrix()
			mat:Translate(self:GetWorldPosition())
			mat:Rotate(self:GetWorldAngles())
			cam.PushModelMatrix( mat )
			obj:Draw()
			cam.PopModelMatrix()
			if LocalPlayer() == self:GetPlayerOwner() then
				if self.Radius ~= 0 then
					local sides = self.Detail
					if self.Detail < 1 then sides = 1 end
					
					local area_factor = self.Radius*self.Radius / (400 + 100*self.Length/math.max(self.Radius,0.1)) --bigger radius means more rays needed to cast to approximate the cylinder detection
					local steps = 3 + math.ceil(4*(area_factor / ((4 + self.Length/4) / (20 / math.max(self.Detail,1)))))
					if self.HitboxMode == "CylinderHybrid" and self.Length ~= 0 then
						area_factor = 0.15*area_factor
						steps = 1 + math.ceil(4*(area_factor / ((4 + self.Length/4) / (20 / math.max(self.Detail,1)))))
					end
					steps = math.max(steps + math.abs(self.ExtraSteps),1)
					
					--print("steps",steps, "total casts will be "..steps*self.Detail)
					for ringnumber=1,0,-1/steps do --concentric circles go smaller and smaller by lowering the i multiplier
						phase = math.random()
						for i=1,0,-1/sides do
							if ringnumber == 0 then i = 0 end
							x = self:GetWorldAngles():Right()*math.cos(2 * math.pi * i + phase * self.PhaseRandomize)*self.Radius*ringnumber*(1 - math.random() * (ringnumber) * self.RadialRandomize)
							y = self:GetWorldAngles():Up()   *math.sin(2 * math.pi * i + phase * self.PhaseRandomize)*self.Radius*ringnumber*(1 - math.random() * (ringnumber) * self.RadialRandomize)
							local startpos = self:GetWorldPosition() + x + y
							local endpos = self:GetWorldPosition() + self:GetWorldAngles():Forward()*self.Length + x + y
							render.DrawLine( startpos, endpos, Color( 255, 255, 255 ), false )
						end
					end
					if self.HitboxMode == "CylinderHybrid" and self.Length ~= 0 then
						--fast sphere check on the wide end
						if self.Length/self.Radius >= 2 then
							render.DrawWireframeSphere( self:GetWorldPosition() + self:GetWorldAngles():Forward()*(self.Length - self.Radius), self.Radius, 10, 10, Color( 255, 255, 255 ) )
							render.DrawWireframeSphere( self:GetWorldPosition() + self:GetWorldAngles():Forward()*(self.Radius), self.Radius, 10, 10, Color( 255, 255, 255 ) )
							if self.Radius ~= 0 then
								local counter = 0
								for i=math.floor(self.Length / self.Radius) - 1,1,-1 do
									render.DrawWireframeSphere( self:GetWorldPosition() + self:GetWorldAngles():Forward()*(self.Radius*i), self.Radius, 10, 10, Color( 255, 255, 255 ) )
									if counter == 100 then break end
									counter = counter + 1
								end
							end
							--render.DrawWireframeSphere( self:GetWorldPosition() + self:GetWorldAngles():Forward()*(self.Length - 0.5*self.Radius), 0.5*self.Radius, 10, 10, Color( 255, 255, 255 ) )
						end
					end
				elseif self.Radius == 0 then render.DrawLine( self:GetWorldPosition(), self:GetWorldPosition() + self:GetWorldAngles():Forward()*self.Length, Color( 255, 255, 255 ), false ) end
			end
		elseif self.HitboxMode == "CylinderSpheres" then
			local obj = Mesh()
			self:BuildCylinder(obj)
			render.SetMaterial( Material( "models/wireframe" ) )
			mat = Matrix()
			mat:Translate(self:GetWorldPosition())
			mat:Rotate(self:GetWorldAngles())
			cam.PushModelMatrix( mat )
			obj:Draw()
			cam.PopModelMatrix()
			if self.Length ~= 0 and self.Radius ~= 0 then
				local counter = 0
				--render.DrawWireframeSphere( self:GetWorldPosition(), self.Radius, 10, 10, Color( 255, 255, 255 ) )
				for i=0,1,1/(math.abs(self.Length/self.Radius)) do
					render.DrawWireframeSphere( self:GetWorldPosition() + self:GetWorldAngles():Forward()*self.Length*i, self.Radius, 10, 10, Color( 255, 255, 255 ) )
					if counter == 200 then break end
					counter = counter + 1
				end
				render.DrawWireframeSphere( self:GetWorldPosition() + self:GetWorldAngles():Forward()*(self.Length), self.Radius, 10, 10, Color( 255, 255, 255 ) )
			elseif self.Radius == 0 then
				render.DrawLine( self:GetWorldPosition(), self:GetWorldPosition() + self:GetWorldAngles():Forward()*self.Length, Color( 255, 255, 255 ), false )
			end
		elseif self.HitboxMode == "Cone" or self.HitboxMode == "ConeHybrid" then
			local obj = Mesh()
			self:BuildCone(obj)
			render.SetMaterial( Material( "models/wireframe" ) )
			mat = Matrix()
			mat:Translate(self:GetWorldPosition())
			mat:Rotate(self:GetWorldAngles())
			cam.PushModelMatrix( mat )
			obj:Draw()
			cam.PopModelMatrix()
			if LocalPlayer() == self:GetPlayerOwner() then
				if self.Radius ~= 0 then
					local sides = self.Detail
					if self.Detail < 1 then sides = 1 end
					local startpos = self:GetWorldPosition()
					local area_factor = self.Radius*self.Radius / (400 + 100*self.Length/math.max(self.Radius,0.1)) --bigger radius means more rays needed to cast to approximate the cylinder detection
					local steps = 3 + math.ceil(4*(area_factor / ((4 + self.Length/4) / (20 / math.max(self.Detail,1)))))
					if self.HitboxMode == "ConeHybrid" and self.Length ~= 0 then
						area_factor = 0.15*area_factor
						steps = 1 + math.ceil(4*(area_factor / ((4 + self.Length/4) / (20 / math.max(self.Detail,1)))))
					end
					steps = math.max(steps + math.abs(self.ExtraSteps),1)
					
					--print("steps",steps, "total casts will be "..steps*self.Detail)
					for ringnumber=1,0,-1/steps do --concentric circles go smaller and smaller by lowering the i multiplier
						phase = math.random()
						local ray_thickness = math.Clamp(0.5*math.log(self.Radius) + 0.05*self.Radius,0,10)*(1.5 - 0.7*ringnumber)
						for i=1,0,-1/sides do
							if ringnumber == 0 then i = 0 end
							x = self:GetWorldAngles():Right()*math.cos(2 * math.pi * i + phase * self.PhaseRandomize)*self.Radius*ringnumber*(1 - math.random() * (ringnumber) * self.RadialRandomize)
							y = self:GetWorldAngles():Up()   *math.sin(2 * math.pi * i + phase * self.PhaseRandomize)*self.Radius*ringnumber*(1 - math.random() * (ringnumber) * self.RadialRandomize)
							local endpos = self:GetWorldPosition() + self:GetWorldAngles():Forward()*self.Length + x + y
							render.DrawLine( startpos, endpos, Color( 255, 255, 255 ), false )
						end
						--[[render.DrawWireframeBox(self:GetWorldPosition() + self:GetWorldAngles():Forward()*self.Length + self:GetWorldAngles():Right() * self.Radius * ringnumber, Angle(0,0,0),
							Vector(ray_thickness,ray_thickness,ray_thickness),
							Vector(-ray_thickness,-ray_thickness,-ray_thickness),
							Color(255,255,255))]]
					end
					if self.HitboxMode == "ConeHybrid" and self.Length ~= 0 then
						--fast sphere check on the wide end
						local radius_multiplier = math.atan(math.abs(self.Length/self.Radius)) / (1.5 + 0.1*math.sqrt(self.Length/self.Radius))
						if self.Length/self.Radius > 0.5 then
							render.DrawWireframeSphere( self:GetWorldPosition() + self:GetWorldAngles():Forward()*(self.Length - self.Radius * radius_multiplier), self.Radius * radius_multiplier, 10, 10, Color( 255, 255, 255 ) )
							--render.DrawWireframeSphere( self:GetWorldPosition() + self:GetWorldAngles():Forward()*(self.Length - 0.5*self.Radius), 0.5*self.Radius, 10, 10, Color( 255, 255, 255 ) )
						end
					end
				elseif self.Radius == 0 then
					render.DrawLine( self:GetWorldPosition(), self:GetWorldPosition() + self:GetWorldAngles():Forward()*self.Length, Color( 255, 255, 255 ), false )
				end
			end
		elseif self.HitboxMode == "ConeSpheres" then
			local obj = Mesh()
			self:BuildCone(obj)
			render.SetMaterial( Material( "models/wireframe" ) )
			mat = Matrix()
			mat:Translate(self:GetWorldPosition())
			mat:Rotate(self:GetWorldAngles())
			cam.PushModelMatrix( mat )
			obj:Draw()
			cam.PopModelMatrix()
			if self.Radius ~= 0 then
				local steps
				steps = math.Clamp(4*math.ceil(self.Length / (self.Radius or 1)),1,50)
				for i = 1,0,-1/steps do
					render.DrawWireframeSphere( self:GetWorldPosition() + self:GetWorldAngles():Forward()*self.Length*i, i * self.Radius, 10, 10, Color( 255, 255, 255 ) )
				end

				steps = math.Clamp(math.ceil(self.Length / (self.Radius or 1)),1,4)
				for i = 0,1/8,1/128 do
					render.DrawWireframeSphere( self:GetWorldPosition() + self:GetWorldAngles():Forward()*self.Length*i, i * self.Radius, 10, 10, Color( 255, 255, 255 ) )
				end
			elseif self.Radius == 0 then
				render.DrawLine( self:GetWorldPosition(), self:GetWorldPosition() + self:GetWorldAngles():Forward()*self.Length, Color( 255, 255, 255 ), false )
			end
		elseif self.HitboxMode == "Ray" then
			render.DrawLine( self:GetWorldPosition(), self:GetWorldPosition() + self:GetWorldAngles():Forward()*self.Length, Color( 255, 255, 255 ), false )
		end
	end)
end

function PART:OnThink()
	if self.Preview then self:PreviewHitbox() end
end

function PART:BuildCylinder(obj)
	local sides = 30
	local circle_tris = {}
	for i=1,sides,1 do
		local vert1 = {pos = Vector(0,          self.Radius*math.sin((i-1)*(2*math.pi / sides)),self.Radius*math.cos((i-1)*(2*math.pi / sides))), u = 0, v = 0 }
		local vert2 = {pos = Vector(0,          self.Radius*math.sin((i-0)*(2*math.pi / sides)),self.Radius*math.cos((i-0)*(2*math.pi / sides))), u = 0, v = 0 }
		local vert3 = {pos = Vector(self.Length,self.Radius*math.sin((i-1)*(2*math.pi / sides)),self.Radius*math.cos((i-1)*(2*math.pi / sides))), u = 0, v = 0 }
		local vert4 = {pos = Vector(self.Length,self.Radius*math.sin((i-0)*(2*math.pi / sides)),self.Radius*math.cos((i-0)*(2*math.pi / sides))), u = 0, v = 0 }
		--print(vert1.pos,vert3.pos,vert2.pos,vert4.pos)
		--{vert1,vert2,vert3}
		--{vert4,vert3,vert2}
		table.insert(circle_tris, vert1)
		table.insert(circle_tris, vert2)
		table.insert(circle_tris, vert3)

		table.insert(circle_tris, vert3)
		table.insert(circle_tris, vert2)
		table.insert(circle_tris, vert1)

		table.insert(circle_tris, vert4)
		table.insert(circle_tris, vert3)
		table.insert(circle_tris, vert2)

		table.insert(circle_tris, vert2)
		table.insert(circle_tris, vert3)
		table.insert(circle_tris, vert4)

		--circle_tris[8*(i-1) + 1] = vert1
		--circle_tris[8*(i-1) + 2] = vert2
		--circle_tris[8*(i-1) + 3] = vert3
		--circle_tris[8*(i-1) + 4] = vert4
		--circle_tris[8*(i-1) + 5] = vert3
		--circle_tris[8*(i-1) + 6] = vert2
	end
	obj:BuildFromTriangles( circle_tris )
end

function PART:BuildCone(obj)
	local sides = 30
	local circle_tris = {}
	local verttip = {pos = Vector(0,0,0), u = 0, v = 0 }
	for i=1,sides,1 do
		local vert1 = {pos = Vector(self.Length,self.Radius*math.sin((i-1)*(2*math.pi / sides)),self.Radius*math.cos((i-1)*(2*math.pi / sides))), u = 0, v = 0 }
		local vert2 = {pos = Vector(self.Length,self.Radius*math.sin((i-0)*(2*math.pi / sides)),self.Radius*math.cos((i-0)*(2*math.pi / sides))), u = 0, v = 0 }
		--print(vert1.pos,vert3.pos,vert2.pos,vert4.pos)
		--{vert1,vert2,vert3}
		--{vert4,vert3,vert2}
		table.insert(circle_tris, verttip)
		table.insert(circle_tris, vert1)
		table.insert(circle_tris, vert2)

		table.insert(circle_tris, vert2)
		table.insert(circle_tris, vert1)
		table.insert(circle_tris, verttip)

		--circle_tris[8*(i-1) + 1] = vert1
		--circle_tris[8*(i-1) + 2] = vert2
		--circle_tris[8*(i-1) + 3] = vert3
		--circle_tris[8*(i-1) + 4] = vert4
		--circle_tris[8*(i-1) + 5] = vert3
		--circle_tris[8*(i-1) + 6] = vert2
	end
	obj:BuildFromTriangles( circle_tris )
end

function PART:Initialize()
	self.validTime = SysTime() + 2
end

BUILDER:Register()