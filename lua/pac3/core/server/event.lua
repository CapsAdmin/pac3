
util.AddNetworkString("pac_proxy")
util.AddNetworkString("pac_event")

-- event
concommand.Add("pac_event", function(ply, _, args)
	if not args[1] then return end

	local event = args[1]
	local extra = tonumber(args[2]) or 0

	if extra == 2 or args[2] == "toggle" then
		ply.pac_event_toggles = ply.pac_event_toggles or {}
		ply.pac_event_toggles[event] = not ply.pac_event_toggles[event]

		extra = ply.pac_event_toggles[event] and 1 or 0
	end

	net.Start("pac_event", true)
		net.WriteEntity(ply)
		net.WriteString(event)
		net.WriteInt(extra, 8)
	net.Broadcast()
end)

concommand.Add("+pac_event", function(ply, _, args)
	if not args[1] then return end

	if args[2] == "2" or args[2] == "toggle" then
		local event = args[1]
		ply.pac_event_toggles = ply.pac_event_toggles or {}
		ply.pac_event_toggles[event] = true

		net.Start("pac_event", true)
			net.WriteEntity(ply)
			net.WriteString(event)
			net.WriteInt(1, 8)
		net.Broadcast()
	else
		net.Start("pac_event", true)
			net.WriteEntity(ply)
			net.WriteString(args[1] .. "_on")
		net.Broadcast()
	end
end)

concommand.Add("-pac_event", function(ply, _, args)
	if not args[1] then return end

	if args[2] == "2" or args[2] == "toggle" then
		local event = args[1]
		ply.pac_event_toggles = ply.pac_event_toggles or {}
		ply.pac_event_toggles[event] = false
		net.Start("pac_event", true)
			net.WriteEntity(ply)
			net.WriteString(event)
			net.WriteInt(0, 8)
		net.Broadcast()
	else
		net.Start("pac_event", true)
			net.WriteEntity(ply)
			net.WriteString(args[1] .. "_off")
		net.Broadcast()
	end
end)

-- proxy
concommand.Add("pac_proxy", function(ply, _, args)
	net.Start("pac_proxy", true)
		net.WriteEntity(ply)
		net.WriteString(args[1])

		net.WriteFloat(tonumber(args[2]) or 0)
		net.WriteFloat(tonumber(args[3]) or 0)
		net.WriteFloat(tonumber(args[4]) or 0)
	net.Broadcast()
end)
