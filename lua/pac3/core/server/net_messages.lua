util.AddNetworkString("pac.TogglePartDrawing")
function pac.TogglePartDrawing(ent, b, who) --serverside interface to clientside function of the same name
	net.Start("pac.TogglePartDrawing")
	net.WriteEntity(ent)
	net.WriteBit(b)
	if not who then
		net.Broadcast()
	else
		net.Send(who)
	end
end

util.AddNetworkString("pac.TouchFlexes.ClientNotify")
net.Receive( "pac.TouchFlexes.ClientNotify", function( length, client )
	local index = net.ReadInt(13)
	local ent = Entity(index)
	if ent and ent:IsValid() and ent.GetFlexNum and ent:GetFlexNum() > 0 then
		local target = ent:GetFlexWeight(1) or 0
		ent:SetFlexWeight(1,target)
	end
end )


do -- Blood Color
	util.AddNetworkString("pac.BloodColor")
	net.Receive( "pac.BloodColor", function( length, ply )
		local BloodColor = net.ReadInt( 6 )
		BloodColor = math.Clamp( math.Round( BloodColor ), -2, 4 )
		if( BloodColor == -2 or BloodColor == 4 )then  BloodColor = 0  end
		
		ply.pac_bloodcolor = BloodColor
	end )

	timer.Create("pac_setbloodcolor", 1, 0, function()
		for _, Ply in pairs( player.GetAll() )do
			if( Ply.pac_bloodcolor and Ply.pac_bloodcolor ~= Ply:GetBloodColor() )then
				Ply:SetBloodColor( Ply.pac_bloodcolor )
			end
		end
	end)
end

do -- button event
	util.AddNetworkString("pac.AllowPlayerButtons")
	net.Receive("pac.AllowPlayerButtons", function(length, client)
		local key = net.ReadUInt(8)

		client.pac_broadcast_buttons = client.pac_broadcast_buttons or {}
		client.pac_broadcast_buttons[key] = true
	end)

	util.AddNetworkString("pac.BroadcastPlayerButton")
	local function broadcast_key(ply, key, down)
		if ply.pac_broadcast_buttons and ply.pac_broadcast_buttons[key] then
			net.Start("pac.BroadcastPlayerButton")
			net.WriteEntity(ply)
			net.WriteUInt(key, 8)
			net.WriteBool(down)
			net.Broadcast()
		end
	end

	pac.AddHook("PlayerButtonDown", "event", function(ply, key)
		broadcast_key(ply, key, true)
	end)

	pac.AddHook("PlayerButtonUp", "event", function(ply, key)
		broadcast_key(ply, key, false)
	end)
end

do
	CreateConVar("pac_free_movement", -1, {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "allow players to modify movement. -1 apply only allow when noclip is allowed, 1 allow for all gamemodes, 0 to disable")

	util.AddNetworkString("pac_modify_movement")
	local allowed = {
		RunSpeed = "RunSpeed",
		WalkSpeed = "WalkSpeed",
		CrouchSpeed = "CrouchedWalkSpeed",
		--AltWalkSpeed = "",
		--AltCrouchSpeed = "",
		JumpHeight = "JumpPower",
	}
	net.Receive("pac_modify_movement", function(len, ply)
		local str = net.ReadString()
		local func = allowed[str]
		if func then
			local num = net.ReadFloat()
			local cvar = GetConVarNumber("pac_free_movement")
			if num == -1 or cvar == 1 or (cvar == -1 and hook.Run("PlayerNoClip", ply, true)) then

				ply.pac_modify_movement_old = ply.pac_modify_movement_old or {}
				local env = ply.pac_modify_movement_old

				env[str] = env[str] or ply["Get" .. func](ply)

				if num == -1 then
					ply["Set" .. func](ply, env[str])
					env[str] = nil
				else
					ply["Set" .. func](ply, math.min(num, 10000))
				end
			end
		end
	end)
end