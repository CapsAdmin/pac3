function pace.dprint(fmt, ...)
	if pace.debug then
		MsgN("\n")
		MsgN(">>>PAC3>>>")
		MsgN(fmt:format(...))
		if pace.debug_trace then
			MsgN("==TRACE==")
			debug.Trace()
			MsgN("==TRACE==")
		end
		MsgN("<<<PAC3<<<")
		MsgN("\n")
	end
end


function pace.CallHook(str, ...)
	hook.Call("pac_" .. str, GAMEMODE, ...)
end

function pace.AddHook(str, func)
	func = func or pac[str]
	hook.Add(str, "pac_" .. str, function(...)
		local args = {pcall(func, ...)}
		if not args[1] then
			ErrorNoHalt(args[2] .. "\n")
			--table.insert(pace.Errors, args[2])
		end
		table.remove(args, 1)
		return unpack(args)
	end)
end

function pace.RemoveHook(str)
	hook.Remove(str, "pac_" .. str)
end