-- event
concommand.Add("pac_event", function(ply, _, args)
	if not args[1] then return end

	local event = args[1]
	local extra = args[2] or 0

	if extra == "2" or extra == "toggle" then
		ply.pac_event_toggles = ply.pac_event_toggles or {}
		ply.pac_event_toggles[event] = not ply.pac_event_toggles[event]

		extra = ply.pac_event_toggles[event] and "1" or "0"
	end

	umsg.Start("pac_event")
		umsg.Entity(ply)
		umsg.String(event)
		umsg.Char(extra)
	umsg.End()
end)

concommand.Add("+pac_event", function(ply, _, args)
	if not args[1] then return end

	if args[2] == "2" or args[2] == "toggle" then
		local event = args[1]
		ply.pac_event_toggles = ply.pac_event_toggles or {}
		ply.pac_event_toggles[event] = true

		umsg.Start("pac_event")
			umsg.Entity(ply)
			umsg.String(event)
			umsg.Char("1")
		umsg.End()
	else
		umsg.Start("pac_event")
			umsg.Entity(ply)
			umsg.String(args[1] .. "_on")
		umsg.End()
	end
end)

concommand.Add("-pac_event", function(ply, _, args)
	if not args[1] then return end

	if args[2] == "2" or args[2] == "toggle" then
		local event = args[1]
		ply.pac_event_toggles = ply.pac_event_toggles or {}
		ply.pac_event_toggles[event] = false
		umsg.Start("pac_event")
			umsg.Entity(ply)
			umsg.String(args[1])
			umsg.Char("0")
		umsg.End()
	else
		umsg.Start("pac_event")
			umsg.Entity(ply)
			umsg.String(args[1] .. "_off")
		umsg.End()
	end
end)

-- proxy
concommand.Add("pac_proxy", function(ply, _, args)
	umsg.Start("pac_proxy")
		umsg.Entity(ply)
		umsg.String(args[1])

		umsg.Float(tonumber(args[2]) or 0)
		umsg.Float(tonumber(args[3]) or 0)
		umsg.Float(tonumber(args[4]) or 0)
	umsg.End()
end)