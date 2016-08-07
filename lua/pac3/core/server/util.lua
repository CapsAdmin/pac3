function pac.dprint(fmt, ...)
	if pac.debug then
		MsgN("\n")
		MsgN(">>>PAC3>>>")
		MsgN(fmt:format(...))
		if pac.debug_trace then
			MsgN("==TRACE==")
			debug.Trace()
			MsgN("==TRACE==")
		end
		MsgN("<<<PAC3<<<")
		MsgN("\n")
	end
end


function pac.CallHook(str, ...)
	hook.Call("pac_" .. str, GAMEMODE, ...)
end

function pac.AddHook(str, func)
	func = func or pac[str]
	hook.Add(str, "pac_" .. str, function(...)
		local args = {pcall(func, ...)}
		if not args[1] then
			ErrorNoHalt(args[2] .. "\n")
			--table.insert(pac.Errors, args[2])
		end
		table.remove(args, 1)
		return unpack(args)
	end)
end

function pac.RemoveHook(str)
	hook.Remove(str, "pac_" .. str)
end