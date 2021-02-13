
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


util.AddNetworkString("pac.AllowPlayerButtons")
util.AddNetworkString("pac.BroadcastPlayerButton")

do -- button event
	net.Receive("pac.AllowPlayerButtons", function(length, client)
		local key = net.ReadUInt(8)

		client.pac_broadcast_buttons = client.pac_broadcast_buttons or {}
		client.pac_broadcast_buttons[key] = true
	end)

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