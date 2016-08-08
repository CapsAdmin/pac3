util.AddNetworkString("pac.net.TogglePartDrawing")
function pac.TogglePartDrawing(ent, b, who) --serverside interface to clientside function of the same name
	net.Start("pac.net.TogglePartDrawing")
	net.WriteEntity(ent)
	net.WriteBit(b)
	if not who then
		net.Broadcast()
	else
		net.Send(who)
	end
end

util.AddNetworkString("pac.net.TouchFlexes.ClientNotify")
net.Receive( "pac.net.TouchFlexes.ClientNotify", function( length, client )
	local index = net.ReadInt(13)
	local ent = Entity(index)
	local target = ent:GetFlexWeight(1) or 0
	if ent and ent:IsValid() and ent.GetFlexNum and ent:GetFlexNum() > 0 then ent:SetFlexWeight(1,target) end
end )

do -- button event
	util.AddNetworkString("pac.net.AllowPlayerButtons")
	net.Receive("pac.net.AllowPlayerButtons", function(length, client)
		local key = net.ReadUInt(8)

		client.pac_broadcast_buttons = client.pac_broadcast_buttons or {}
		client.pac_broadcast_buttons[key] = true
	end)

	util.AddNetworkString("pac.net.BroadcastPlayerButton")
	local function broadcast_key(ply, key, down)
		if ply.pac_broadcast_buttons and ply.pac_broadcast_buttons[key] then
			net.Start("pac.net.BroadcastPlayerButton")
			net.WriteEntity(ply)
			net.WriteUInt(key, 8)
			net.WriteBool(down)
			net.Broadcast()
		end
	end

	hook.Add("PlayerButtonDown", "pac_event", function(ply, key)
		broadcast_key(ply, key, true)
	end)

	hook.Add("PlayerButtonUp", "pac_event", function(ply, key)
		broadcast_key(ply, key, false)
	end)
end
