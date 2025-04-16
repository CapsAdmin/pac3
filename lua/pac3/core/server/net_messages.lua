
util.AddNetworkString("pac.AllowPlayerButtons")
util.AddNetworkString("pac.BroadcastPlayerButton")
util.AddNetworkString("pac_chat_typing_mirror")
util.AddNetworkString("pac_chat_typing_mirror_broadcast")
util.AddNetworkString("pac_fire_bullets_for_singleplayer")
util.AddNetworkString("pac_hide_bullets_get")

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

net.Receive("pac_chat_typing_mirror", function(len, ply)
	local str = net.ReadString()
	net.Start("pac_chat_typing_mirror_broadcast")
	net.WriteString(str)
	net.WriteEntity(ply)
	net.Broadcast()
end)

if game.SinglePlayer() then
	hook.Add("EntityFireBullets", "pac_bullet_singleplayer_hack", function(ent, data)
		if ent:IsPlayer() then
			net.Start("pac_fire_bullets_for_singleplayer") net.WriteEntity(ent) net.WriteUInt(game.GetAmmoID(data.AmmoType),8) net.Broadcast()
		end
		if ent:GetNWBool("pac_hide_bullets", false) then return false end
	end)
	net.Receive("pac_hide_bullets_get", function(len, ply)
		ply:SetNWBool("pac_hide_bullets",net.ReadBool())
	end)
end