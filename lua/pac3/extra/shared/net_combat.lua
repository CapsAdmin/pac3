local grab_consents = {}
local damage_zone_consents = {}
local grab_pairs = {}
local pairs_grabbed_by = {}

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

if SERVER then
	local function maximized_ray_mins_maxs(startpos,endpos,padding)
		local maxsx,maxsy,maxsz
		local highest_sq_distance = 0
		for xsign = -1, 1, 2 do
			for ysign = -1, 1, 2 do
				for zsign = -1, 1, 2 do
					local distance_tried = (startpos + Vector(padding*xsign,padding*ysign,padding*zsign)):DistToSqr(endpos - Vector(padding*xsign,padding*ysign,padding*zsign))
					if distance_tried > highest_sq_distance then
						highest_sq_distance = distance_tried
						maxsx,maxsy,maxsz = xsign,ysign,zsign
					end
				end
			end
		end
		return Vector(padding*maxsx,padding*maxsy,padding*maxsz),Vector(padding*-maxsx,padding*-maxsy,padding*-maxsz)
	end
	util.AddNetworkString("pac_hitscan")
	util.AddNetworkString("pac_request_position_override_on_entity")
	util.AddNetworkString("pac_request_angle_reset_on_entity")
	util.AddNetworkString("pac_request_velocity_force_on_entity")
	util.AddNetworkString("pac_request_zone_damage")
	util.AddNetworkString("pac_signal_player_combat_consent")
	util.AddNetworkString("pac_signal_stop_lock")
	util.AddNetworkString("pac_request_lock_break")
	util.AddNetworkString("pac_request_player_combat_consent_update")
	

	net.Receive("pac_hitscan", function(len,ply)
		print("WE SHOULD DO A BULLET IN THE SERVER!")
		ent = net.ReadEntity()
		bulletinfo = net.ReadTable()
		print("hitscan!", ent)
		PrintTable(bulletinfo)
		ent:FireBullets(bulletinfo)
	end)

	net.Receive("pac_request_zone_damage", function(len,ply)
		--print("message from ",ply)
		local pos = net.ReadVector()
		local ang = net.ReadAngle()
		local tbl = net.ReadTable()
		local ply_ent = net.ReadEntity()
		local dmg_info = DamageInfo()
		dmg_info:SetDamage(tbl.Damage)
		dmg_info:IsBulletDamage(tbl.Bullet)
		dmg_info:SetDamageForce(Vector(0,0,0))
		dmg_info:SetAttacker(ply_ent)
		dmg_info:SetInflictor(ply_ent)
		--print("entity: ",ply_ent)

		dmg_info:SetDamageType(damage_types[tbl.DamageType]) --print(tbl.DamageType .. " resolves to " .. damage_types[tbl.DamageType])

		local ratio
		if tbl.Radius == 0 then ratio = tbl.Length
		else ratio = math.abs(tbl.Length / tbl.Radius) end

		if tbl.HitboxMode == "Sphere" then
			local ents_hits = ents.FindInSphere(pos, tbl.Radius)
			ProcessDamagesList(ents_hits, dmg_info, tbl, pos, ang)
		elseif tbl.HitboxMode == "Box" or tbl.HitboxMode == "Cube" then
			local mins
			local maxs
			if tbl.HitboxMode == "Box" then
				mins = pos - Vector(tbl.Radius, tbl.Radius, tbl.Length)
				maxs = pos + Vector(tbl.Radius, tbl.Radius, tbl.Length)
			elseif tbl.HitboxMode == "Cube" then
				mins = pos - Vector(tbl.Radius, tbl.Radius, tbl.Radius)
				maxs = pos + Vector(tbl.Radius, tbl.Radius, tbl.Radius)
			end

			local ents_hits = ents.FindInBox(mins, maxs)
			ProcessDamagesList(ents_hits, dmg_info, tbl, pos, ang)
		elseif tbl.HitboxMode == "Cylinder" or tbl.HitboxMode == "CylinderHybrid" then
			local ents_hits = {}
			if tbl.Radius ~= 0 then
				local sides = tbl.Detail
				if tbl.Detail < 1 then sides = 1 end
				local area_factor = tbl.Radius*tbl.Radius / (400 + 100*tbl.Length/math.max(tbl.Radius,0.1)) --bigger radius means more rays needed to cast to approximate the cylinder detection
				local steps = 3 + math.ceil(4*(area_factor / ((4 + tbl.Length/4) / (20 / math.max(tbl.Detail,1)))))
				if tbl.HitboxMode == "CylinderHybrid" and tbl.Length ~= 0 then
					area_factor = 0.15*area_factor
					steps = 1 + math.ceil(4*(area_factor / ((4 + tbl.Length/4) / (20 / math.max(tbl.Detail,1)))))
				end
				steps = math.max(steps + math.abs(tbl.ExtraSteps),1)
				
				--print("steps",steps, "total casts will be "..steps*self.Detail)
				for ringnumber=1,0,-1/steps do --concentric circles go smaller and smaller by lowering the i multiplier
					phase = math.random()
					local ray_thickness = math.Clamp(0.5*math.log(tbl.Radius) + 0.05*tbl.Radius,0,10)*(1 - 0.7*ringnumber)
					for i=1,0,-1/sides do
						if ringnumber == 0 then i = 0 end
						x = ang:Right()*math.cos(2 * math.pi * i + phase * tbl.PhaseRandomize)*tbl.Radius*ringnumber*(1 - math.random() * (ringnumber) * tbl.RadialRandomize)
						y = ang:Up()   *math.sin(2 * math.pi * i + phase * tbl.PhaseRandomize)*tbl.Radius*ringnumber*(1 - math.random() * (ringnumber) * tbl.RadialRandomize)
						local startpos = pos + x + y
						local endpos = pos + ang:Forward()*tbl.Length + x + y
						MergeTargetsByID(ents_hits, ents.FindAlongRay(startpos, endpos, maximized_ray_mins_maxs(startpos,endpos,ray_thickness)))
					end
				end
				if tbl.HitboxMode == "CylinderHybrid" and tbl.Length ~= 0 then
					--fast sphere check on the wide end
					if tbl.Length/tbl.Radius >= 2 then
						MergeTargetsByID(ents_hits,ents.FindInSphere(pos + ang:Forward()*(tbl.Length - tbl.Radius), tbl.Radius))
						MergeTargetsByID(ents_hits,ents.FindInSphere(pos + ang:Forward()*tbl.Radius, tbl.Radius))
						if tbl.Radius ~= 0 then
							local counter = 0
							for i=math.floor(tbl.Length / tbl.Radius) - 1,1,-1 do
								MergeTargetsByID(ents_hits,ents.FindInSphere(pos + ang:Forward()*(tbl.Radius*i), tbl.Radius))
								if counter == 100 then break end
								counter = counter + 1
							end
						end
						--render.DrawWireframeSphere( self:GetWorldPosition() + self:GetWorldAngles():Forward()*(self.Length - 0.5*self.Radius), 0.5*self.Radius, 10, 10, Color( 255, 255, 255 ) )
					end
				end
			elseif tbl.Radius == 0 then MergeTargetsByID(ents_hits,ents.FindAlongRay(pos, pos + ang:Forward()*tbl.Length)) end
			ProcessDamagesList(ents_hits, dmg_info, tbl, pos, ang)
		elseif tbl.HitboxMode == "CylinderSpheres" then
			local ents_hits = {}
			if tbl.Length ~= 0 and tbl.Radius ~= 0 then
				local counter = 0
				MergeTargetsByID(ents_hits,ents.FindInSphere(pos, tbl.Radius))
				for i=0,1,1/(math.abs(tbl.Length/tbl.Radius)) do
					MergeTargetsByID(ents_hits,ents.FindInSphere(pos + ang:Forward()*tbl.Length*i, tbl.Radius))
					if counter == 200 then break end
					counter = counter + 1
				end
				MergeTargetsByID(ents_hits,ents.FindInSphere(pos + ang:Forward()*tbl.Length, tbl.Radius))
				--render.DrawWireframeSphere( self:GetWorldPosition() + self:GetWorldAngles():Forward()*(self.Length - 0.5*self.Radius), 0.5*self.Radius, 10, 10, Color( 255, 255, 255 ) )
			elseif tbl.Radius == 0 then MergeTargetsByID(ents_hits,ents.FindAlongRay(pos, pos + ang:Forward()*tbl.Length)) end
			ProcessDamagesList(ents_hits, dmg_info, tbl, pos, ang)
		elseif tbl.HitboxMode == "Cone" or tbl.HitboxMode == "ConeHybrid" then
			local ents_hits = {}
			if tbl.Radius ~= 0 then
				local sides = tbl.Detail
				if tbl.Detail < 1 then sides = 1 end
				local startpos = pos-- + Vector(0,       self.Radius,self.Radius)
				local area_factor = tbl.Radius*tbl.Radius / (400 + 100*tbl.Length/math.max(tbl.Radius,0.1)) --bigger radius means more rays needed to cast to approximate the cylinder detection
				local steps = 3 + math.ceil(4*(area_factor / ((4 + tbl.Length/4) / (20 / math.max(tbl.Detail,1)))))
				if tbl.HitboxMode == "ConeHybrid" and tbl.Length ~= 0 then
					area_factor = 0.15*area_factor
					steps = 1 + math.ceil(4*(area_factor / ((4 + tbl.Length/4) / (20 / math.max(tbl.Detail,1)))))
				end
				steps = math.max(steps + math.abs(tbl.ExtraSteps),1)
				--print("steps",steps, "total casts will be "..steps*self.Detail)
				local timestart = SysTime()
				local casts = 0
				for ringnumber=1,0,-1/steps do --concentric circles go smaller and smaller by lowering the ringnumber multiplier
					phase = math.random()
					local ray_thickness = 5 * (2 - ringnumber)
					
					--print("ring " .. ringnumber .. " phase " .. phase)
					for i=1,0,-1/sides do
						--print("radius " .. tbl.Radius*ringnumber*(1 - math.random() * (ringnumber) * tbl.RadialRandomize))
						if ringnumber == 0 then i = 0 end
						x = ang:Right()*math.cos(2 * math.pi * i + phase * tbl.PhaseRandomize)*tbl.Radius*ringnumber*(1 - math.random() * (ringnumber) * tbl.RadialRandomize)
						y = ang:Up()   *math.sin(2 * math.pi * i + phase * tbl.PhaseRandomize)*tbl.Radius*ringnumber*(1 - math.random() * (ringnumber) * tbl.RadialRandomize)
						local endpos = pos + ang:Forward()*tbl.Length + x + y
						MergeTargetsByID(ents_hits,ents.FindAlongRay(startpos, endpos, maximized_ray_mins_maxs(startpos,endpos,ray_thickness)))
						casts = casts + 1
					end
				end
				print(casts .. " casts")
				if tbl.HitboxMode == "ConeHybrid" and tbl.Length ~= 0 then
					--fast sphere check on the wide end
					local radius_multiplier = math.atan(math.abs(ratio)) / (1.5 + 0.1*math.sqrt(ratio))
					if ratio > 0.5 then
						MergeTargetsByID(ents_hits,ents.FindInSphere(pos + ang:Forward()*(tbl.Length - tbl.Radius * radius_multiplier), tbl.Radius * radius_multiplier))
					end
				end
			elseif tbl.Radius == 0 then MergeTargetsByID(ents_hits,ents.FindAlongRay(pos, pos + ang:Forward()*tbl.Length)) end
			ProcessDamagesList(ents_hits, dmg_info, tbl, pos, ang)
		elseif tbl.HitboxMode == "ConeSpheres" then
			local ents_hits = {}
			local steps
			steps = math.Clamp(4*math.ceil(tbl.Length / (tbl.Radius or 1)),1,50)
			for i = 1,0,-1/steps do
				--PrintTable(ents.FindInSphere(pos + ang:Forward()*tbl.Length*i, i * tbl.Radius))
				MergeTargetsByID(ents_hits,ents.FindInSphere(pos + ang:Forward()*tbl.Length*i, i * tbl.Radius))
			end

			steps = math.Clamp(math.ceil(tbl.Length / (tbl.Radius or 1)),1,4)
			for i = 0,1/8,1/128 do
				--PrintTable(ents.FindInSphere(pos + ang:Forward()*tbl.Length*i, i * tbl.Radius))
				--MergeTargetsByID(ents_hits,ents.FindInSphere(pos + ang:Forward()*tbl.Length*i, i * tbl.Radius))
			end
			if tbl.Radius == 0 then MergeTargetsByID(ents_hits,ents.FindAlongRay(pos, pos + ang:Forward()*tbl.Length)) end
			ProcessDamagesList(ents_hits, dmg_info, tbl, pos, ang)
		elseif tbl.HitboxMode =="Ray" then
			local startpos = pos + Vector(0,0,0)
			local endpos = pos + ang:Forward()*tbl.Length
			ents_hits = ents.FindAlongRay(startpos, endpos)
			ProcessDamagesList(ents_hits, dmg_info, tbl, pos, ang)

			if tbl.Bullet then
				local bullet = {}
				bullet.Src = pos + ang:Forward()
				bullet.Dir = ang:Forward()*50000
				bullet.Damage = -1
				bullet.Force = 0
				bullet.Entity = dmg_info:GetAttacker()
				dmg_info:GetInflictor():FireBullets(bullet)
			end
		end

	end)

	function ProcessDamagesList(ents_hits, dmg_info, tbl, pos, ang)
		print("received", #ents_hits, "potential targets")
		--print("process hurt ", #ents_hits)
		--PrintTable(ents_hits)
		local bullet = {}
		bullet.Src = pos + ang:Forward()
		bullet.Dir = ang:Forward()*50000
		bullet.Damage = -1
		bullet.Force = 0
		bullet.Entity = dmg_info:GetAttacker()
		if #ents_hits == 0 then
			if tbl.Bullet then
				dmg_info:GetInflictor():FireBullets(bullet)
			end
			return
		end
		
		for _,ent in pairs(ents_hits) do
			if IsEntity(ent) then
				if (not tbl.AffectSelf) and ent == dmg_info:GetInflictor() then --nothing
				elseif (ent:IsPlayer() and tbl.Players) or (ent:IsNPC() and tbl.NPC) or (string.find(ent:GetClass(), "npc") ~= nil) or (string.find(ent:GetClass(), "drg_") ~= nil) or (ent:GetClass() == "prop_physics") then
					--local oldvel = ent:GetVelocity()
					local ents2 = {dmg_info:GetInflictor()}
					if tbl.Bullet then
						for _,v in ipairs(ents_hits) do
							if v ~= ent then table.insert(ents2,v) end
						end
					end

					if tbl.DamageType == "heal" then
						ent:SetHealth(math.min(ent:Health() + tbl.Damage, ent:GetMaxHealth()))
					elseif tbl.DamageType == "armor" then
						ent:SetArmor(math.min(ent:Armor() + tbl.Damage, ent:GetMaxArmor()))
					else
						if tbl.Bullet then
							traceresult = util.TraceLine({filter = ents2, start = pos, endpos = pos + 50000*(ent:WorldSpaceCenter() - dmg_info:GetAttacker():WorldSpaceCenter())})
							--print(traceresult.Fraction)
							bullet.Dir = traceresult.Normal
							bullet.Src = traceresult.HitPos + traceresult.HitNormal*5
							dmg_info:GetInflictor():FireBullets(bullet)
						end
						if ent:IsPlayer() then
							if (ent == dmg_info:GetInflictor() and tbl.AffectSelf) then
								ent:TakeDamageInfo(dmg_info)
								print(ent, "hurt themself")
							elseif damage_zone_consents[ent] == true or ent:IsBot() then
								ent:TakeDamageInfo(dmg_info)
								print(dmg_info:GetAttacker(), "hurt", ent)
							else print("can't do that because",ent,damage_zone_consents[ent]) end
						else
							ent:TakeDamageInfo(dmg_info)
							print(dmg_info:GetAttacker(), "hurt", ent)
						end
					end
					--local newvel = ent:GetVelocity()
					--ent:SetVelocity( oldvel - newvel)
				end
			end
		end
	end

	function MergeTargetsByID(tbl1, tbl2)
		for i,v in pairs(tbl2) do
			tbl1[v:EntIndex()] = v
		end
	end

	net.Receive("pac_request_position_override_on_entity", function(len, ply)

		local pos = net.ReadVector()
		local ang = net.ReadAngle()
		local override_ang = net.ReadBool()
		local targ_ent = net.ReadEntity()
		local auth_ent = net.ReadEntity()
		if not grab_pairs[auth_ent] then
			grab_pairs[auth_ent] = targ_ent
			pairs_grabbed_by[targ_ent] = auth_ent
			print(auth_ent, "grabs", targ_ent)
		end

		if targ_ent:EntIndex() == 0 then return end
		if targ_ent ~= auth_ent and grab_consents[targ_ent] == false then return end
		
		if override_ang and not targ_ent:IsPlayer() then
			targ_ent:SetAngles(ang)
		elseif override_ang and (auth_ent == targ_ent) and targ_ent:IsPlayer() then
			targ_ent:SetEyeAngles(ang)
		end
		targ_ent:SetPos(pos)
		
		if targ_ent:IsPlayer() then targ_ent:SetVelocity(-targ_ent:GetVelocity()) end

		if targ_ent:GetClass() == "prop_ragdoll" then targ_ent:GetPhysicsObject():SetPos(pos) end
	end)

	net.Receive("pac_request_angle_reset_on_entity", function(len, ply)
		local ang = net.ReadAngle()
		local delay = net.ReadFloat()
		local targ_ent = net.ReadEntity()
		local auth_ent = net.ReadEntity()

		targ_ent:SetAngles(ang)
		targ_ent:PhysWake()
		table.RemoveByValue(grab_pairs,auth_ent)
	end)

	net.Receive("pac_request_velocity_force_on_entity", function(len,ply)

	end)

	net.Receive("pac_signal_player_combat_consent", function(len,ply)
		mode = net.ReadString()
		b = net.ReadBool()
		--print("message from", ply, "consent for",mode,"is",b)
		if mode == "grab" then
			grab_consents[ply] = b
			--PrintTable(grab_consents)
		elseif mode == "damage_zone" then
			damage_zone_consents[ply] = b
			--PrintTable(grab_consents)
		elseif mode == "all" then
			grab_consents[ply] = b
			damage_zone_consents[ply] = b
		end
	end)

	net.Receive("pac_signal_stop_lock", function(len,ply)
		print("Requesting lock break")
		PrintTable(grab_pairs)
		for p,targ in pairs(grab_pairs) do
			if grab_pairs[p] == targ and ply == targ then
				print("from",p)
				if p:IsPlayer() then
					net.Start("pac_request_lock_break")
					net.WriteEntity(ply)
					net.Send(p)
				elseif targ:IsPlayer() then
					net.Start("pac_request_lock_break")
					net.WriteEntity(ply)
					net.Send(targ)
				end

			end
		end
	end)

	concommand.Add("pac_refresh_consents", function()
		pac_combat_RefreshConsents()
	end)

	function pac_combat_RefreshConsents()
		for _,ent in pairs(ents.GetAll()) do
			if ent:IsPlayer() then
				net.Start("pac_request_player_combat_consent_update")
				net.Send(ent)
				--print(ent, "does that player consent grabs?", grab_consents[ent], "and damage zone?", damage_zone_consents[ent])
			end
		end
	end

	timer.Create("pac_timer_refresh_client_consents", 10, 0, function() pac_combat_RefreshConsents() end)
end

if CLIENT then
	CreateConVar("pac_client_grab_consent", "0", FCVAR_ARCHIVE, true)
	CreateConVar("pac_client_damage_zone_consent", "0", FCVAR_ARCHIVE, true)

	concommand.Add( "pac_stop_lock", function()
		net.Start("pac_signal_stop_lock")
		net.SendToServer()
	end, "asks the server to breakup any lockpart hold on your player")

	concommand.Add( "pac_break_lock", function()
		net.Start("pac_signal_stop_lock")
		net.SendToServer()
	end, "asks the server to breakup any lockpart hold on your player")

	net.Receive("pac_request_player_combat_consent_update", function()
		--print("player receives request to update consents")
		net.Start("pac_signal_player_combat_consent")
		net.WriteString("grab")
		net.WriteBool(GetConVar("pac_client_grab_consent"):GetBool())
		net.SendToServer()

		net.Start("pac_signal_player_combat_consent")
		net.WriteString("damage_zone")
		net.WriteBool(GetConVar("pac_client_damage_zone_consent"):GetBool())
		net.SendToServer()
	end)
end

