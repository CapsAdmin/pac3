-- event
concommand.Add("pac_event", function(ply, _, args)
	if not args[1] then return end
	umsg.Start("pac_event")
		umsg.Entity(ply)
		umsg.String(args[1])
	umsg.End()
end)

concommand.Add("+pac_event", function(ply, _, args)
	if not args[1] then return end
	umsg.Start("pac_event")
		umsg.Entity(ply)
		umsg.String(args[1] .. "_on")
	umsg.End()
end)

concommand.Add("-pac_event", function(ply, _, args)
	if not args[1] then return end
	umsg.Start("pac_event")
		umsg.Entity(ply)
		umsg.String(args[1] .. "_off")
	umsg.End()
end)

-- proxy
concommand.Add("pac_proxy", function(ply, _, args)
	umsg.Start("pac_proxy")
		umsg.Entity(ply)
		umsg.String(args[1])
		umsg.Float(tonumber(args[2]) or 0)
	umsg.End()
end)