
util.AddNetworkString("pac_proxy")
util.AddNetworkString("pac_event")
util.AddNetworkString("pac_event_set_sequence")
util.AddNetworkString("pac_event_define_sequence_bounds")
util.AddNetworkString("pac_event_update_sequence_bounds")

-- event
concommand.Add("pac_event", function(ply, _, args)
	if args[1] == nil then
		ply:PrintMessage(HUD_PRINTCONSOLE, "\npac_event needs at least one argument.\nname: any name, preferably without spaces\nmode: a number.\n\t0 turns off\n\t1 turns on\n\t2 toggles on/off\n\twithout a second argument, the event is a single-shot\n\ne.g. pac_event light 2\n")
		return
	end

	local event = args[1]
	local extra = tonumber(args[2]) or 0

	if extra == 2 or args[2] == "toggle" then
		ply.pac_event_toggles = ply.pac_event_toggles or {}
		ply.pac_event_toggles[event] = not ply.pac_event_toggles[event]

		extra = ply.pac_event_toggles[event] and 1 or 0
	end

	if args[2] == "random" then
		local min = tonumber(args[3])
		local max = tonumber(args[4])
		if isnumber(min) and isnumber(max) then
			local append = math.floor(math.Rand(tonumber(args[3]), tonumber(args[4]) + 1))
			event = event .. append
		end
	end

	net.Start("pac_event", true)
		net.WriteEntity(ply)
		net.WriteString(event)
		net.WriteInt(extra, 8)
	net.Broadcast()
	ply.pac_command_events = ply.pac_command_events or {}
	ply.pac_command_events[event] = ply.pac_command_events[event] or {}
	ply.pac_command_events[event] = {name = event, time = pac.RealTime, on = extra}
end, nil,
[[pac_event triggers command events. it needs at least one argument.
name: any name, preferably without spaces
modes:
	0 turns off
	1 turns on
	2 toggles on/off
	without a second argument, the event is a single-shot
	random followed by two numbers will run a single-shot randomly, the name will be the base name with the number at the end

e.g.
	pac_event light 2
	pac_event attack random 1 3]])

net.Receive("pac_event_define_sequence_bounds", function(len, ply)
	local bounds = net.ReadTable()
	if bounds == nil then return end
	for event,tbl in pairs(bounds) do
		ply.pac_command_event_sequencebases = ply.pac_command_event_sequencebases or {}
		local current_seq_value = 1
		if ply.pac_command_event_sequencebases[event] then
			if ply.pac_command_event_sequencebases[event].current then
				current_seq_value = ply.pac_command_event_sequencebases[event].current
			end
		end
		ply.pac_command_event_sequencebases[event] = {name = event, min = tbl[1], max = tbl[2], current = current_seq_value}
	end
	net.Start("pac_event_update_sequence_bounds") net.WriteEntity(ply) net.WriteTable(bounds) net.Broadcast()
end)

concommand.Add("pac_event_sequenced_force_set_bounds", function(ply, cmd, args)
	if args[1] == nil then return end
	local event = args[1]
	local min = args[2]
	local max = args[3]
	ply.pac_command_event_sequencebases = ply.pac_command_event_sequencebases or {}
	ply.pac_command_event_sequencebases[event] = {name = event, min = tonumber(min), max = tonumber(max), current = 0}
	net.Start("pac_event_update_sequence_bounds") net.WriteEntity(ply) net.WriteTable(ply.pac_command_event_sequencebases) net.Broadcast()
end)

concommand.Add("pac_event_sequenced", function(ply, cmd, args)
	if args[1] == nil then
		ply:PrintMessage(HUD_PRINTCONSOLE, "\npac_event_sequenced needs at least one* argument.\nname: the base name of your series of events\naction: set, forward, backward\nnumber: if using the set mode, the number to set\n\ne.g. pac_event_sequenced hat_style set 3\n")
		return
	end

	local event = args[1]
	local action = args[2] or "+"
	local sequence_number = 0
	local set_target = tonumber(args[3]) or 1

	ply.pac_command_events = ply.pac_command_events or {}

	local data
	if ply.pac_command_event_sequencebases ~= nil then
		if ply.pac_command_event_sequencebases[event] == nil then ply.pac_command_event_sequencebases[event] = {name = event, min = 1, max = 1} end
	else
		ply.pac_command_event_sequencebases = {}
		ply.pac_command_event_sequencebases[event] = {name = event, min = 1, max = 1}
	end

	data = ply.pac_command_event_sequencebases[event]
	sequence_number = data.current

	local target_number = 1
	local min = data.min
	local max = data.max

	sequence_number = tonumber(data.current) or 1
	if action == "+" or action == "forward" or action == "add" or action == "sequence+" or action == "advance" then
		if sequence_number >= max then
			target_number = min
		else target_number = sequence_number + 1 end
		data.current = target_number

	elseif action == "-" or action == "backward" or action == "sub" or action == "sequence-" then
		if sequence_number <= min then
			target_number = max
		else target_number = sequence_number - 1 end
		data.current = target_number

	elseif action == "set" then
		sequence_number = set_target or 1
		target_number = set_target
		data.current = target_number
	else
		ply:PrintMessage(HUD_PRINTCONSOLE, "\npac_event_sequenced : wrong action name. Valid action names are:\nforward, +, add, sequence+ or advance\nbackward, -, sub, or sequence-\nset")
		return
	end
	net.Start("pac_event_set_sequence")
	net.WriteEntity(ply)
	net.WriteString(event)
	net.WriteUInt(target_number,8)
	net.Broadcast()
end)

concommand.Add("+pac_event", function(ply, _, args)
	if not args[1] then
		ply:PrintMessage(HUD_PRINTCONSOLE, "+pac_event needs a name argument, and the toggling argument. e.g. +pac_event hold_light 2\nwithout the toggling arg, implicitly adds _on to the command name, like running \"pac_event name_on\", and \"pac_event name_off\" when released")
		return
	end

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
end, nil, "activates a command event. more effective when bound. \ne.g. \"+pac_event name\" will run \"pac_event name_on\" when the button is held, \"pac_event name_off\" when the button is held. Take note these are instant commands, they would need a command event with duration.\nmeanwhile, \"+pac_event name 2\" will run \"pac_event name 1\" when the button is held, \"pac_event name 0\" when the button is held. Take note these are held commands.")

concommand.Add("-pac_event", function(ply, _, args)
	if not args[1] then
		ply:PrintMessage(HUD_PRINTCONSOLE, "-pac_event needs a name argument, and the toggling argument. e.g. +pac_event hold_light 2\nwithout the toggling arg, implicitly adds _on to the command name, like running \"pac_event name_off\"")
		return
	end

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
	str = args[1]
	if args[1] == nil then
		ply:PrintMessage(HUD_PRINTCONSOLE, "\npac_proxy needs at least two arguments.\nname\nnumber, or a series of numbers for a vector. increment notation is available, such as ++1 or --1.\ne.g. pac_proxy myvector 1 2 3\ne.g. pac_proxy value ++5")
		return
	end

	if ply:IsValid() then
		ply.pac_proxy_events = ply.pac_proxy_events or {}
	end
	local x
	local y
	local z
	if ply.pac_proxy_events[str] ~= nil then
		if args[2] then
			if string.sub(args[2],1,2) == "++" or string.sub(args[2],1,2) == "--" then
				x = ply.pac_proxy_events[str].x + tonumber(string.sub(args[2],2,#args[2]))
			else x = tonumber(args[2]) or ply.pac_proxy_events[str].x or 0 end
		end

		if args[3] then
			if string.sub(args[3],1,2) == "++" or string.sub(args[3],1,2) == "--" then
				y = ply.pac_proxy_events[str].y + tonumber(string.sub(args[3],2,#args[3]))
			else y = tonumber(args[3]) or ply.pac_proxy_events[str].y or 0 end
		end
		if not args[3] then y = 0 end

		if args[4] then
			if string.sub(args[4],1,2) == "++" or string.sub(args[4],1,2) == "--" then
				z = ply.pac_proxy_events[str].z + tonumber(string.sub(args[4],2,#args[4]))
			else z = tonumber(args[4]) or ply.pac_proxy_events[str].z or 0 end
		end
		if not args[4] then z = 0 end
	else
		x = tonumber(args[2]) or 0
		y = tonumber(args[3]) or 0
		z = tonumber(args[4]) or 0
	end
	ply.pac_proxy_events[str] = {name = str, x = x, y = y, z = z}

	net.Start("pac_proxy", true)
		net.WriteEntity(ply)
		net.WriteString(args[1])

		net.WriteFloat(x or 0)
		net.WriteFloat(y or 0)
		net.WriteFloat(z or 0)
	net.Broadcast()
end, nil,
[[pac_proxy sets the number of a command function in a proxy. it is typically accessed as command(\"value\") needs at least two arguments.
name: any name, preferably without spaces
numbers: a number, or a series of numbers for a vector. increment notation is available, such as ++1 and --1.
e.g. pac_proxy myvector 1 2 3
e.g. pac_proxy value ++5]])
