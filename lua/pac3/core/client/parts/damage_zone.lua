local BUILDER, PART = pac.PartTemplate("base_movable")

--ultrakill parryables: club, slash, buckshot

PART.ClassName = "damage_zone"
PART.Group = "combat"
PART.Icon = "icon16/package.png"

PART.ImplementsDoubleClickSpecified = true

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

local recycle_hitmark = CreateConVar("pac_damage_zone_recycle_hitmarkers", "0", FCVAR_ARCHIVE, "Whether to use the experimental recycling system to save performance on spawning already created hit markers.\nIf this is 0, it will be more reliable but more costly because it creates new parts every time.")


BUILDER:StartStorableVars()
	:SetPropertyGroup("Targets")
		:GetSet("AffectSelf",false)
		:GetSet("Players",true)
		:GetSet("NPC",true)
		:GetSet("PointEntities",true, {description = "Other source engine entities such as item_item_crate and prop_physics"})
		:GetSet("Friendlies", true, {description = "friendly NPCs can be targeted"})
		:GetSet("Neutrals", true, {description = "neutral NPCs can be targeted"})
		:GetSet("Hostiles", true, {description = "hostile NPCs can be targeted"})
	:SetPropertyGroup("Shape and Sampling")
		:GetSet("Radius", 20, {editor_onchange = function(self,num) return math.floor(math.Clamp(num,-32768,32767)) end})
		:GetSet("Length", 50, {editor_onchange = function(self,num) return math.floor(math.Clamp(num,-32768,32767)) end})
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
		:GetSet("Detail", 20, {editor_onchange = function(self,num) return math.floor(math.Clamp(num,-32,31)) end})
		:GetSet("ExtraSteps",0, {editor_onchange = function(self,num) return math.floor(math.Clamp(num,-8,7)) end})
		:GetSet("RadialRandomize", 1, {editor_onchange = function(self,num) return math.Clamp(num,-8,7) end})
		:GetSet("PhaseRandomize", 1, {editor_onchange = function(self,num) return math.Clamp(num,-8,7) end})
	:SetPropertyGroup("Falloff")
		:GetSet("DamageFalloff", false)
		:GetSet("DamageFalloffPower", 1, {editor_onchange = function(self,num) return math.Clamp(num,-64,63) end})
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
		:GetSet("Damage", 0, {editor_onchange = function(self,num) return math.floor(math.Clamp(num,0,268435455)) end})
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
		:GetSet("DoNotKill",false, {description = "Only damage to as low as critical health;\nOnly heal to as high as critical health\nIn other words, converge to the critical health"})
		:GetSet("ReverseDoNotKill",false, {description = "Heal only if health is above critical health;\nDamage only if health is below critical health\nIn other words, move away from the critical health"})
		:GetSet("CriticalHealth",1, {editor_onchange = function(self,num) return math.floor(math.Clamp(num,0,65535)) end})
		:GetSet("MaxHpScaling", 0, {editor_clamp = {0,1}})
	:SetPropertyGroup("DamageOverTime")
		:GetSet("DOTMode", false, {description = "Damage over Time\nRepeats your damage a few times. Subject to serverside convar."})
		:GetSet("DOTMethod", "Debuff", {
			enums = {["Debuff"] = "Debuff", ["RefreshZone"] = "RefreshZone"},
			description = "Whether the DoT means to repeat the damage on the target (handled by the server, starting from one damagezone action), or it means to retrigger the zone (handled by you, the client, throughout multiple damagezone actions).\nDebuff is like the target is burning, RefreshZone is like the area is on fire (but doesn't \"ignite\" targets)"})
		:GetSet("DOTTime", 0, {editor_clamp = {0,32}, description = "delay between each repeated damage"})
		:GetSet("DOTCount", 0, {editor_onchange = function(self,num) return math.floor(math.Clamp(num,0,127)) end, description = "number of repeated damage instances"})
		:GetSet("NoInitialDOT", false, {description = "Skips the first instance (the instant one) of damage to achieve a delayed damage for example."})
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
		:GetSet("AttachPartsToTargetEntity",false, {description = "hitparts will be applied to the target entity rather than on the floating hitmarker entity\nThis will require pac_sv_damage_zone_allow_ragdoll_hitparts to be set to 1 serverside"})
		:GetSet("RemoveNPCWeaponsOnKill",false)
BUILDER:EndStorableVars()



--[[UNUSED
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
end]]

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

local hitparts_dump = {}
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
--[[
	owner.hitmarker_partpool[group.UniqueID] = {active, template_uid, group_part_data}
	owner.hitparts[free] = {active, specimen_part, hitmarker_id, template_uid}
]]

local must_remove_class = {
	entity, entity2, player_movement, weapon
}
local function CleanupParts(group)
	for i,part in ipairs(group:GetChildrenList()) do
		if must_remove_class[part.ClassName] then
			part:Remove()
		end
	end
end

function PART:FindOrCreateFloatingPart(owner, ent, part_uid, id, parent_ent)
	owner.hitmarker_partpool = owner.hitmarker_partpool or {}
	for spec_uid,tbl in pairs(owner.hitmarker_partpool) do
		if tbl.template_uid == part_uid then
			if not tbl.active then
				local part = pac.GetPartFromUniqueID(pac.Hash(owner), spec_uid)
				local group = part:GetRootPart()
				group:CallRecursive("Think")
				return pac.GetPartFromUniqueID(pac.Hash(owner), spec_uid) --whoowee we found an already existing part
			end
		end
	end
	--what if we don't!
	local tbl = pac.GetPartFromUniqueID(pac.Hash(owner), part_uid):ToTable()
	local group = pac.CreatePart("group", owner) --print("\tcreated a group for " .. id)
	table.insert(hitparts_dump, {self, group, ent})
	self.force_cleanup_hitparts = CurTime() + math.max(self.HitMarkerLifetime, self.KillMarkerLifetime)

	group:SetShowInEditor(false)

	local part = pac.CreatePart(tbl.self.ClassName, owner, tbl, tostring(tbl))
	group:AddChild(part)
	CleanupParts(group)

	group:CallRecursive("Think")
	owner.hitmarker_partpool[group.UniqueID] = {player_owner = self:GetPlayerOwner(), active = true, hitmarker_id = id, template_uid = part_uid, group_part_data = group}

	return group, owner.hitmarker_partpool[group.UniqueID]

end

local ragdolls = {}

net.Receive("pac_send_ragdoll", function(len)
	local entindex = net.ReadUInt(12)
	local rag = net.ReadEntity()
	ragdolls[entindex] = rag
	timer.Simple(2, function() ragdolls[entindex] = nil end)
end)

local function TryAttachPartToAnEntity(self,group,parent_ent,marker_ent,killing)
	local can_do_ragdolls = GetConVar("pac_sv_damage_zone_allow_ragdoll_hitparts"):GetBool()
	if killing and can_do_ragdolls then
		if isstring(killing) then
			group:SetOwner(parent_ent)
			return
		end
	end
	if self.AttachPartsToTargetEntity then
		--how to determine consent?? dunno I'll add a layer for outfit application consents if I ever implement pac sharing, but pac_sv_prop_outfits works for now
		if parent_ent:IsPlayer() then
			if killing and can_do_ragdolls then
				timer.Simple(0.05, function()
					local rag = parent_ent:GetRagdollEntity()
					TryAttachPartToAnEntity(self,group,rag,marker_ent,false)
				end)
				return
			end
			if GetConVar("pac_sv_prop_outfits"):GetInt() == 2 then
				group:SetOwnerName(parent_ent:EntIndex())
			else
				group:SetOwner(marker_ent)
			end
		else
			if killing and can_do_ragdolls then
				local ent_index = parent_ent:EntIndex()
				timer.Simple(0.05, function()
					rag = ragdolls[ent_index]
					if IsValid(rag) then
						rag = rag
						TryAttachPartToAnEntity(self,group,rag,ent, "ragdoll")
					end
				end)
				return
			end
			group:SetOwnerName(parent_ent:EntIndex())
		end
		
	else
		group:SetOwner(marker_ent)
	end
end

local function FreeSpotInStack(owner)
	owner.hitparts = owner.hitparts or {}
	owner.hitparts_freespots = owner.hitparts_freespots or {}
	for i=1,50,1 do
		if owner.hitparts_freespots[i] == nil then owner.hitparts_freespots[i] = false return i end 
		if owner.hitparts_freespots[i] ~= false then
			if owner.hitparts[i] then
				if not owner.hitparts[i].active then
					return i
				end
			else
				return i
			end
		end
	end
	return nil
end

--[[
	owner.hitmarker_partpool[group.UniqueID] = {active, template_uid, group_part_data}
	owner.hitparts[free] = {active, specimen_part, hitmarker_id, template_uid}
]]

local function MatchInStack(owner, ent)
	owner.hitparts = owner.hitparts or {}
	for i=1,50,1 do
		if owner.hitparts[i] then
			if owner.hitparts[i].template_uid == ent.template_uid and owner.hitparts[i].hitmarker_id == ent.marker_id then
				return i
			end
			--match: entry's template uid is the same as entity's template uid
			--if there's more, still match entry's specimen ID with specimen ID
		end
	end

	return nil
end

local function UIDMatchInStackForExistingPart(owner, ent, part_uid, ent_id)
	owner.hitparts = owner.hitparts or {}
	for i=1,50,1 do
		if owner.hitparts[i] then
			--print(i, "match compare:", owner.hitparts[i].active, owner.hitparts[i].specimen_part, owner.hitparts[i].hitmarker_id, owner.hitparts[i].template_uid == part_uid)
			if owner.hitparts[i].template_uid == part_uid then
				if owner.hitmarker_partpool then
					for spec_uid,tbl in pairs(owner.hitmarker_partpool) do
						if tbl.template_uid == part_uid then
							if not tbl.active then
								return tbl.group_part_data
							end
						end
					end
				end
			end
		end
	end

	return nil
end

--[[
	owner.hitmarker_partpool[group.UniqueID] = {active, template_uid, group_part_data}
	owner.hitparts[free] = {active, specimen_part, hitmarker_id, template_uid}
]]
function PART:AddHitMarkerToStack(index, owner, ent, part_uid, ent_id, parent_ent, killing)
	--print("trying to add to stack:")
	--print("\t\t",owner, ent, part_uid, ent_id, parent_ent)
	owner.hitparts = owner.hitparts or {}
	local free = FreeSpotInStack(owner)
	local returned_part = nil
	local existingpart = UIDMatchInStackForExistingPart(owner, ent, part_uid, ent_id)
	returned_part = existingpart

	if free and not existingpart then
		local group, tbl = self:FindOrCreateFloatingPart(owner, ent, part_uid, ent_id, parent_ent)
		owner.hitparts[index] = {active = true, specimen_part = group, hitmarker_id = ent_id, template_uid = part_uid, csent = ent, parent_ent = parent_ent}
		returned_part = owner.hitparts[index].specimen_part
		TryAttachPartToAnEntity(self,group,parent_ent,ent, killing)
	else
		owner.hitparts[index] = {active = true, specimen_part = returned_part, hitmarker_id = ent_id, template_uid = part_uid, csent = ent, parent_ent = parent_ent}
		TryAttachPartToAnEntity(self,existingpart,parent_ent,ent, killing)
	end
	

	return returned_part
end

local function RemoveHitMarker(owner, ent, uid, id)
	owner.hitparts = owner.hitparts or {}

	local match = MatchInStack(owner, ent)
	if match then
		if owner.hitparts[match] then
			owner.hitparts[match].active = false
		end
	end
	if owner.hitmarker_partpool then
		for spec_uid,tbl in pairs(owner.hitmarker_partpool) do
			if tbl.hitmarker_id == id then
				tbl.active = false
				tbl.group_part_data:SetHide(true)
				tbl.group_part_data:SetShowInEditor(false)
				tbl.group_part_data:SetOwnerName(owner:EntIndex())
				--print(tbl.group_part_data, "dormant")
			end
		end
	end
	--SafeRemoveEntity(ent)
end

--[[
	owner.hitmarker_partpool[group.UniqueID] = {active, template_uid, group_part_data}
	owner.hitparts[free] = {active, specimen_part, hitmarker_id, template_uid}
]]
function PART:AssignFloatingPartToEntity(index, part, owner, ent, parent_ent, template_uid, marker_id)

	if not IsValid(part) then return false end

	ent.pac_draw_distance = 0

	local group = part
	local part2 = group:GetChildrenList()[1]

	owner.hitmarker_partpool[group.UniqueID] = 	{active = true, hitmarker_id = marker_id, template_uid = template_uid, group_part_data = group}
	owner.hitparts[index] = 					{active = true, hitmarker_id = marker_id, template_uid = template_uid, specimen_part = group, csent = ent, parent_ent = parent_ent}
	self.hitmarkers[group.UniqueID] = owner.hitmarker_partpool[group.UniqueID]

	parent_ent.pac_dmgzone_hitmarker_ents = parent_ent.pac_dmgzone_hitmarker_ents or {}
	ent.part = group
	ent.parent_ent = parent_ent
	ent.template_uid = template_uid
	parent_ent.pac_dmgzone_hitmarker_ents[marker_id] = ent
	ent.marker_id = marker_id

	group:SetShowInEditor(false)

	TryAttachPartToAnEntity(self,group,parent_ent,ent)
	
	
	timer.Simple(0, function() group:SetHide(false) part2:SetHide(false) group:CallRecursive("Think") group:CallRecursive("CalcShowHide") end)
	
	
	--print(parent_ent, group:IsHidden(), part2:IsHidden())
	
	owner.hitparts_freespots[index] = false
	--print(group, "assigned to " .. marker_id .. " / " .. parent_ent:EntIndex())

end

function PART:ClearHitMarkers()
	for uid, part in pairs(self.hitmarkers) do
		if IsValid(part) then part:GetRootOwner():Remove() end
	end
	local ply = self:GetPlayerOwner()
	if ply.hitparts then
		for i,v in pairs(ply.hitparts) do
			v.specimen_part:Remove()
		end
	end
	ply.hitmarker_partpool = nil
	ply.hitparts = nil
	--second pass
	local remaining_parts = {}
	for i,v in ipairs(hitparts_dump) do
		if v[2]:IsValid() then
			if self == v[1] then
				v[2]:Remove()
				hitparts_dump[i] = nil
			end
		else
			hitparts_dump[i] = nil
		end
		--if it survives, reinsert it
		if hitparts_dump[i] then table.insert(remaining_parts, v) end
	end
	hitparts_dump = remaining_parts
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

local hitbox_ids = {
	["Box"] = 1,
	["Cube"] = 2,
	["Sphere"] = 3,
	["Cylinder"] = 4,
	["CylinderHybrid"] = 5,
	["CylinderSpheres"] = 6,
	["Cone"] = 7,
	["ConeHybrid"] = 8,
	["ConeSpheres"] = 9,
	["Ray"] = 10
}

--the hit results net receiver needs to resolve to the part but UID strings is a bit weighty so partial UID are a compromise
local part_partialUID_caches = {}

--more compressed net message
function PART:SendNetMessage()
	part_partialUID_caches[string.sub(self.UniqueID,0,6)] = self
	pac.Blocked_Combat_Parts = pac.Blocked_Combat_Parts or {}
	if pac.LocalPlayer ~= self:GetPlayerOwner() then return end
	if not GetConVar('pac_sv_damage_zone'):GetBool() then return end
	if util.NetworkStringToID( "pac_request_zone_damage" ) == 0 then self:SetError("This part is deactivated on the server") return end
	if pac.Blocked_Combat_Parts then
		if pac.Blocked_Combat_Parts[self.ClassName] then return end
	end
	if not pac.CountNetMessage() then self:SetInfo("Went beyond the allowance") end

	if GetConVar("pac_sv_combat_enforce_netrate_monitor_serverside"):GetBool() then
		if not pac.CountNetMessage() then self:SetInfo("Went beyond the allowance") return end
	end

	net.Start("pac_request_zone_damage", true)

	net.WriteVector(self:GetWorldPosition())
	net.WriteAngle(self:GetWorldAngles())
	net.WriteUInt(self.Damage, 28)
	net.WriteUInt(self.MaxHpScaling*1000,10)
	net.WriteInt(self.Length, 16)
	net.WriteInt(self.Radius, 16)
	net.WriteBool(self.AffectSelf)
	net.WriteBool(self.NPC)
	net.WriteBool(self.Players)
	net.WriteBool(self.PointEntities)
	net.WriteBool(self.Friendlies)
	net.WriteBool(self.Neutrals)
	net.WriteBool(self.Hostiles)
	net.WriteUInt(hitbox_ids[self.HitboxMode] or 1,5)
	net.WriteUInt(damage_ids[self.DamageType] or 0,7)
	net.WriteInt(self.Detail,6)
	net.WriteInt(self.ExtraSteps,4)
	net.WriteInt(math.floor(math.Clamp(8*self.RadialRandomize,-64, 63)), 7)
	net.WriteInt(math.floor(math.Clamp(8*self.PhaseRandomize,-64, 63)), 7)
	net.WriteBool(self.DamageFalloff)
	net.WriteInt(math.floor(math.Clamp(8*self.DamageFalloffPower,-512, 511)), 12)
	net.WriteBool(self.Bullet)
	net.WriteBool(self.DoNotKill)
	net.WriteBool(self.ReverseDoNotKill)
	net.WriteUInt(self.CriticalHealth, 16)
	net.WriteBool(self.RemoveNPCWeaponsOnKill)
	net.WriteBool(self.DOTMode and (self.DOTMethod == "Debuff"))
	net.WriteBool(self.NoInitialDOT and (self.DOTMethod == "Debuff"))
	net.WriteUInt(self.DOTCount, 7)
	net.WriteUInt(math.ceil(math.Clamp(64*self.DOTTime, 0, 2047)), 11)
	net.WriteString(string.sub(self.UniqueID,0,6))
	local using_hit_feedback = IsValid(self.HitMarkerPart) or IsValid(self.KillMarkerPart)
	net.WriteBool(using_hit_feedback)
	net.SendToServer()
end

function PART:OnShow()
	self.remaining_DOT_count = self.DOTCount
	self.next_DOT = self.NoInitialDOT and CurTime() + self.DOTTime or CurTime() - 1

	if pace.still_loading_wearing then return end
	if self.validTime > SysTime() then return end

	if self.Preview then
		self:PreviewHitbox()
	end
	self.stop_until = self.stop_until or 0
	if self.stop_until then self:GetPlayerOwner().stop_hit_markers_admonishment_message_up = nil end
	if (self:GetPlayerOwner().stop_hit_markers_admonishment_message_up) or self.stop_until > CurTime() then return end

	if self.DOTMethod == "RefreshZone" then return end --handle with Think

	if self:GetRootPart():GetOwner() ~= self:GetPlayerOwner() then --dumb workaround for when it activates before it realizes it needs to be hidden first
		timer.Simple(0.01, function() --wait to check if needs to be hidden first
			if self:IsHidden() or self:IsDrawHidden() then return end
			if self.Preview then
				self:PreviewHitbox()
			end

			self:SendNetMessage()
		end)
	else
		self:SendNetMessage()
	end
end

function PART:OnDoubleClickSpecified()
	self:SendNetMessage()
end

local dmgzone_requesting_corpses = {}
function PART:SetAttachPartsToTargetEntity(b)
	self.AttachPartsToTargetEntity = b
	if pac.LocalPlayer ~= self:GetPlayerOwner() then return end
	if self.KillMarkerPart == nil then return end
	if b then
		net.Start("pac_request_ragdoll_sends")
		net.WriteBool(true)
		net.SendToServer()
		dmgzone_requesting_corpses[self] = true
	else
		dmgzone_requesting_corpses[self] = nil
		if table.Count(dmgzone_requesting_corpses) == 0 then
			net.Start("pac_request_ragdoll_sends")
			net.WriteBool(false)
			net.SendToServer()
		end
	end
end

--revertable to projectile part's version which wastes time creating new parts but has less issues
function PART:LegacyAttachToEntity(part, ent)
	if not part:IsValid() then return false end

	ent.pac_draw_distance = 0

	local tbl = part:ToTable()

	local group = pac.CreatePart("group", self:GetPlayerOwner())
	table.insert(hitparts_dump, {self, group, ent})
	self.force_cleanup_hitparts = CurTime() + math.max(self.HitMarkerLifetime, self.KillMarkerLifetime)
	group:SetShowInEditor(false)

	local part_clone = pac.CreatePart(tbl.self.ClassName, self:GetPlayerOwner(), tbl, tostring(tbl))
	group:AddChild(part_clone)

	group:SetOwner(ent)
	group.SetOwner = function(s) s.Owner = ent end
	part_clone:SetHide(false)

	local id = group.Id
	local owner_id = self:GetPlayerOwnerId()
	if owner_id then
		id = id .. owner_id
	end

	ent:CallOnRemove("pac_hitmarker_" .. id, function() group:Remove() end)
	group:CallRecursive("Think")

	ent.pac_hitmark_part = group
	ent.pac_hitmark = self --that's just the launcher though

	return true
end

net.Receive("pac_hit_results", function(len)
	local uid = net.ReadString() or ""
	local self = part_partialUID_caches[uid]
	if not self then return end
	local hit = net.ReadBool()
	if hit then
		self.dmgzone_hit_done = CurTime()
	end
	local kill = net.ReadBool()
	if kill then
		self.dmgzone_kill_done = CurTime()
	end
	local highest_dmg = net.ReadFloat() or 0
	--most damagezone won't use hitparts, skip the writetables
	local do_ents_feedback = net.ReadBool()
	local ents_hit = {}
	local ents_kill = {}
	if do_ents_feedback then
		ents_hit = net.ReadTable(true)
		if kill then ents_kill = net.ReadTable(true) end
	end
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
	local function spawn(part, pos, ang, parent_ent, duration, owner, killing)
		if not IsValid(owner) then return end
		if part == self then return end --stop infinite feedback loops of using the damagezone as a hitmarker
		--what if people employ a more roundabout method? CRACKDOWN!


		if not recycle_hitmark:GetBool() then
			local ent = parent_ent
			local cs_ent = false
			if not self.AttachPartsToTargetEntity then
				ent = pac.CreateEntity("models/props_junk/popcan01a.mdl")
				cs_ent = true
				ent:SetNoDraw(true)
				ent:SetPos(pos)
			end
			self:LegacyAttachToEntity(killing and self.KillMarkerPart or self.HitMarkerPart, ent)

			timer.Simple(math.Clamp(killing and self.KillMarkerLifetime or self.HitMarkerLifetime, 0, 30), function()
				if IsValid(ent) then
					if ent.pac_hitmark_part and ent.pac_hitmark_part:IsValid() then
						ent.pac_hitmark_part:Remove()
					end

					if cs_ent then
						SafeRemoveEntityDelayed(ent, 0.5)
					end
				end
			end)
			return
		end

		if not owner.hitparts then owner.hitparts = {} end

		if owner.stop_hit_markers_until then
			if owner.stop_hit_markers_until > CurTime() then return end
		end
		if self.lag_risk and math.random() > 0.5 then return end
		if not self:IsValid() then return end
		if not part:IsValid() then return end


		local start = SysTime()
		local ent = pac.CreateEntity("models/props_junk/popcan01a.mdl")
		if not ent:IsValid() then return end
		ent.is_pac_hitmarker = true
		ent:SetNoDraw(true)
		ent:SetOwner(self:GetPlayerOwner())
		ent:SetPos(pos)
		ent:SetAngles(ang)
		global_hitmarker_CSEnt_seed = global_hitmarker_CSEnt_seed + 1
		local csent_id = global_hitmarker_CSEnt_seed

		--the spawn order needs to decide whether it can or can't create an ent or part

		local flush = self.RemoveDuplicateHitMarkers
		if flush then
			--go through the entity and remove the clientside hitmarkers entities
			if parent_ent.pac_dmgzone_hitmarker_ents then
				for id,ent2 in pairs(parent_ent.pac_dmgzone_hitmarker_ents) do
					if IsValid(ent2) then
						if ent2.part:IsValid() then
							ent2.part:SetHide(true)
						end
					end
				end
			end
		end

		local free_spot = FreeSpotInStack(owner)
		
		if free_spot then
			if part:IsValid() then --self:AttachToEntity(part, ent, parent_ent, global_hitmarker_CSEnt_seed)
				--print("free spot should be " .. free_spot)
				local newpart
				local bool = UIDMatchInStackForExistingPart(owner, ent, part.UniqueID, csent_id)
				if bool then
					newpart = bool
					--print("\tpart is existing")
				else
					newpart = self:AddHitMarkerToStack(free_spot, owner, ent, part.UniqueID, csent_id, parent_ent, killing)
					--print("\tpart should be added")
				end

				self:AssignFloatingPartToEntity(free_spot, newpart, owner, ent, parent_ent, part.UniqueID, csent_id)

				if self.Preview then MsgC("hitmarker:", bool and Color(0,255,0) or Color(0,200,255), bool and "existing" or "created", " : ", newpart, "\n") end
				timer.Simple(math.Clamp(duration, 0, 8), function()
					if ent:IsValid() then
						if parent_ent.pac_dmgzone_hitmarker_ents then
							for id,ent2 in pairs(parent_ent.pac_dmgzone_hitmarker_ents) do
								if IsValid(ent2) then
									RemoveHitMarker(owner, ent2, part.UniqueID, id)
									owner.hitparts_freespots[free_spot] = true
									--SafeRemoveEntity(ent2)
								end
							end
						end
					end
				end)
			end
		end

		local creation_delta = SysTime() - start

		return creation_delta
	end

	if hit then
		--try not to play both sounds at once
		if ValidSound(self.HitSoundPart) then
			--if can overlap, always play
			if self.AllowOverlappingHitSounds then
				self.HitSoundPart:PlaySound()
			--if cannot overlap, only play if there's only one entity or if we didn't kill
			elseif (table.Count(ents_kill) <= 1) or not (kill and ValidSound(self.KillSoundPart)) then
				self.HitSoundPart:PlaySound()
			end
		end
		if self.HitMarkerPart then
			for _,ent in ipairs(ents_hit) do
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
	end
	if kill then
		self.dmgzone_kill_done = CurTime()
		if ValidSound(self.KillSoundPart) then
			self.KillSoundPart:PlaySound()
		end
		if self.KillMarkerPart then
			for _,ent in ipairs(ents_kill) do
				if IsValid(ent) then
					local ang = (ent:GetPos() - pos):Angle()
					part_setup_runtimes = part_setup_runtimes + (spawn(self.KillMarkerPart, ent:WorldSpaceCenter(), ang, ent, self.KillMarkerLifetime, owner, true) or 0)
				end
			end
		end
	end
	if self.HitMarkerPart or self.KillMarkerPart then
		if owner.hitparts then
			self:SetInfo(table.Count(owner.hitparts) .. " hitmarkers in slot")
		end
	end
end)

concommand.Add("pac_cleanup_damagezone_hitmarks", function()
	print(hitparts_dump, #hitparts_dump .. " parts detected")
	for i,v in ipairs(hitparts_dump) do
		if v[2]:IsValid() then
			v[2]:Remove()
		end
		hitparts_dump[i] = nil
	end

	if LocalPlayer().hitparts then
		for i,v in pairs(LocalPlayer().hitparts) do
			v.specimen_part:Remove()
		end
	end

	LocalPlayer().hitmarker_partpool = nil
	LocalPlayer().hitparts = nil
end)


function PART:OnHide()
	pac.RemoveHook(self.RenderingHook, "pace_draw_hitbox"..self.UniqueID)
	for _,v in pairs(renderhooks) do
		pac.RemoveHook(v, "pace_draw_hitbox"..self.UniqueID)
	end
end

function PART:OnRemove()
	part_partialUID_caches[string.sub(self.UniqueID,0,6)] = nil
	pac.RemoveHook(self.RenderingHook, "pace_draw_hitbox")
	for _,v in pairs(renderhooks) do
		pac.RemoveHook(v, "pace_draw_hitbox")
	end
	self:ClearHitMarkers()
end

local previousRenderingHook

function PART:PreviewHitbox()

	if previousRenderingHook ~= self.RenderingHook then
		for _,v in pairs(renderhooks) do
			pac.RemoveHook(v, "pace_draw_hitbox"..self.UniqueID)
		end
		previousRenderingHook = self.RenderingHook
	end

	if not self.Preview then return end

	pac.AddHook(self.RenderingHook, "pace_draw_hitbox"..self.UniqueID, function()
		if not self.Preview then pac.RemoveHook(self.RenderingHook, "pace_draw_hitbox"..self.UniqueID) end
		if not IsValid(self) then pac.RemoveHook(self.RenderingHook, "pace_draw_hitbox"..self.UniqueID) end
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
	if self.DOTMethod == "RefreshZone" then
		if self.DOTTime == 0 then return end --get outta here with those zero delays
		if (CurTime() > self.next_DOT) and (self.remaining_DOT_count > 0) then
			self:SendNetMessage()
			self.remaining_DOT_count = self.remaining_DOT_count - 1
			self.next_DOT = CurTime() + self.DOTTime
		end
	end
	if self.force_cleanup_hitparts < CurTime() then self:ClearHitMarkers() end
end

function PART:GetNiceName()
	local str = ""
	if self.DOTMode then
		str = str .. " [DoT " .. self.DOTCount .. "x : " .. self.DOTTime .. "s]"
	end
	str = str .. " " .. self.DamageType .. " " .. self.Damage
	if self.MaxHpScaling ~= 0 then str = str .. " + " .. 100*self.MaxHpScaling .. "% max HP" end
	if self.ReverseDoNotKill then
		if self.DamageType == "heal" then
			str = str .. " [if HP > " .. self.CriticalHealth .. "]"
		else
			str = str .. " [if HP < " .. self.CriticalHealth .. "]"
		end
	elseif self.DoNotKill then
		str = str .. " [stop at " .. self.CriticalHealth .. " HP]"
	end
	return "damage zone" .. str
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
	self.force_cleanup_hitparts = 0
	self.hitmarkers = {}
	if not GetConVar("pac_sv_damage_zone"):GetBool() or pac.Blocked_Combat_Parts[self.ClassName] then self:SetError("damage zones are disabled on this server!") end
	self.validTime = SysTime() + 5 --jank fix to try to stop activation on load
	timer.Simple(0.1, function() --jank fix on the jank fix to allow it earlier on projectiles and hitmarkers
		local ent = self:GetRootPart():GetOwner()
		if IsValid(ent) then
			if ent.is_pac_hitmarker or ent.pac_projectile_part then
				self.validTime = 0
			end
		end
	end)

end

function PART:SetRadius(val)
	self.Radius = val
	local sv_dist = GetConVar("pac_sv_damage_zone_max_radius"):GetInt()
	if self.Radius > sv_dist then
		self:SetInfo("Your radius is beyond the server's maximum permitted! Server max is " .. sv_dist)
	else
		self:SetInfo(nil)
	end
end

function PART:SetLength(val)
	self.Length = val
	local sv_dist = GetConVar("pac_sv_damage_zone_max_length"):GetInt()
	if self.Length > sv_dist then
		self:SetInfo("Your length is beyond the server's maximum permitted! Server max is " .. sv_dist)
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


BUILDER:Register()