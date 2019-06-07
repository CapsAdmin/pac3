
util.AddNetworkString("pac.TogglePartDrawing")
util.AddNetworkString("pac.BloodColor")
util.AddNetworkString("pac.AllowPlayerButtons")
util.AddNetworkString("pac.BroadcastPlayerButton")

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

do -- Blood Color
	local pac_allow_blood_color = GetConVar("pac_allow_blood_color")

	local allowed = {
		dont_bleed = _G.DONT_BLEED,
		red = _G.BLOOD_COLOR_RED,
		yellow = _G.BLOOD_COLOR_YELLOW,
		green = _G.BLOOD_COLOR_GREEN,
		mech = _G.BLOOD_COLOR_MECH,
		antlion = _G.BLOOD_COLOR_ANTLION,
		zombie = _G.BLOOD_COLOR_ZOMBIE,
		antlion_worker = _G.BLOOD_COLOR_ANTLION_WORKER,
	}

	local temp = {}
	for k,v in pairs(allowed) do
		temp[v] = k
	end
	allowed = temp

	net.Receive("pac.BloodColor", function(_, ply)
		if not pac_allow_blood_color:GetBool() then return end
		local num = net.ReadInt(6)
		if allowed[num] then
			ply.pac_bloodcolor = num
			ply:SetBloodColor(num)
		end
	end)

	timer.Create("pac_setbloodcolor", 10, 0, function()
		if not pac_allow_blood_color:GetBool() then return end

		for _, ply in ipairs(player.GetAll()) do
			if ply.pac_bloodcolor and ply.pac_bloodcolor ~= ply:GetBloodColor() then
				ply:SetBloodColor(ply.pac_bloodcolor)
			end
		end
	end)
end

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