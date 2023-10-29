
util.AddNetworkString("pac.AllowPlayerButtons")
util.AddNetworkString("pac.BroadcastPlayerButton")

util.AddNetworkString("pac.BroadcastPlayerInputs")

util.AddNetworkString("pac.RequestPlayerObjUsed")
util.AddNetworkString("pac.SendPlayerObjUsed")

util.AddNetworkString("pac.BroadcastDamageAttributions")

do -- button event
	net.Receive("pac.AllowPlayerButtons", function(length, client)
		local key = net.ReadUInt(8)

		client.pac_broadcast_buttons = client.pac_broadcast_buttons or {}
		client.pac_broadcast_buttons[key] = true
	end)

	local function broadcast_key(ply, key, down)
		if not ply.pac_broadcast_buttons then return end
		if not ply.pac_broadcast_buttons[key] then return end

		net.Start("pac.BroadcastPlayerButton")
		net.WriteEntity(ply)
		net.WriteUInt(key, 8)
		net.WriteBool(down)
		net.Broadcast()
	end

	pac.AddHook("PlayerButtonDown", "event", function(ply, key)
		broadcast_key(ply, key, true)
	end)

	pac.AddHook("PlayerButtonUp", "event", function(ply, key)
		broadcast_key(ply, key, false)
	end)
end

--[[do -- input event
	local input_enums = {
		IN_ATTACK,			--1
		IN_JUMP,			--2
		IN_DUCK,			--4
		IN_FORWARD,			--8
		IN_BACK,			--16
		IN_USE,				--32
		IN_CANCEL,			--64
		IN_LEFT,			--128
		IN_RIGHT,			--256
		IN_MOVELEFT,		--512
		IN_MOVERIGHT,		--1024
		IN_ATTACK2,			--2048
		IN_RUN,				--4096
		IN_RELOAD,			--8192
		IN_ALT1,			--16384
		IN_ALT2,			--32768
		IN_SCORE,			--65536
		IN_SPEED,			--131072
		IN_WALK,			--262144
		IN_ZOOM,			--524288
		IN_WEAPON1,			--1048576
		IN_WEAPON2,			--2097152
		IN_BULLRUSH,		--4194304
		IN_GRENADE1,		--8388608
		IN_GRENADE2			--16777216
	}

	local pac_broadcast_inputs = {}
	local last_input_broadcast = 0
	local player_last_input_broadcast_times = {}

	local function broadcast_inputs(update)

		if not update or not (last_input_broadcast + 0.05 < CurTime()) then return
		elseif update
			net.Start("pac.BroadcastPlayerInputs")
			net.WriteTable(pac_broadcast_inputs)
			net.WriteTable(player_last_input_broadcast_times)
			net.Broadcast()
			last_input_broadcast = CurTime()
		end
	end

	pac.AddHook("Tick", "PACBroadcastPlayerInputs", function()
		
		local update = false
		local updated_players = {}
		pac_broadcast_inputs = pac_broadcast_inputs or {}
		local last_broadcast_inputs = table.Copy(pac_broadcast_inputs)
		local time = CurTime()
		for _,ply in pairs(player.GetAll()) do
			if not pac_broadcast_inputs[ply] then pac_broadcast_inputs[ply] = {} end
			for _,v in pairs(input_enums) do

				if ply:KeyDown( v ) then
					pac_broadcast_inputs[ply][v] = true
				elseif ply:KeyDownLast( v ) then
					pac_broadcast_inputs[ply][v] = false
				end

				if last_broadcast_inputs[ply] and pac_broadcast_inputs[ply] then
					if last_broadcast_inputs[ply][v] ~= pac_broadcast_inputs[ply][v] then
						update = true
						player_last_input_broadcast_times[ply] = CurTime()
					end
				end

				
			end
		end
		broadcast_inputs(update)
		
	end)
end]]

do --is_using_entity
	local function send_player_used_object(client, ent, class, b, from_client)
		net.Start("pac.SendPlayerObjUsed")
		net.WriteEntity(client)
		net.WriteEntity(ent)
		net.WriteString(class)
		net.WriteBool(b)
		
		--print("BROADCAST", client, ent, class, b)
		net.Send(player.GetAll())
	end

	net.Receive("pac.RequestPlayerObjUsed", function(length, client)
		local from_client = true
		local override = true
		local ent_used = client:GetEntityInUse()
		local class = "nil"
		if ent_used and IsValid(ent_used) then
			if ent_used.GetClass ~= nil then
				class = ent_used:GetClass()
			end
		end
		if class == "player_pickup" then 
			override = false
		end
		
		send_player_used_object(client, ent_used, class, override, from_client)
	end)

	hook.Add("PlayerUse", "pac.PlayerUse", function( client, ent )
		local class = ent:GetClass()
		--print("USE", client,ent, class)
		if ent:GetClass() ~= "player_pickup" then
			send_player_used_object(client, ent, class, true, false)
		end
	end)
end

do --damage attribution
	timer.Simple(1, function()--call it regularly in case a new hook overrides the damage, we want the final one
		pac.AddHook("EntityTakeDamage", "pac.AttributeDamage", function(ent, dmg)
			local time = CurTime()
			if IsValid(dmg:GetAttacker()) then
				local tbl = {hit_time = time, attacker = dmg:GetAttacker(), dmg_amount = dmg:GetDamage(), dmg_type = dmg:GetDamageType(), inflictor = dmg:GetInflictor()}
				ent[dmg:GetInflictor()] = tbl
				net.Start("pac.BroadcastDamageAttributions")
				net.WriteEntity(ent)
				net.WriteTable(tbl)
				net.WriteBool(ent:Health() < dmg:GetDamage())
				net.Broadcast()
			end
			
		end)
	end)
end