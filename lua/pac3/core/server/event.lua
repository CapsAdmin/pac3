-- event
concommand.Add("pac_event", function(ply, _, args)
	umsg.Start("pac_event")
		umsg.Entity(ply)
		umsg.String(args[1])
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