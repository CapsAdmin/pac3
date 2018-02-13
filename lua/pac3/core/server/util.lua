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

function pac.AddHook(str, id, func)
	id = "pac_" .. id

	hook.Add(str, id, function(...)
		local args = {pcall(func, ...)}
		if not args[1] then
			ErrorNoHalt(args[2] .. "\n")
		end
		return unpack(args, 2)
	end)
end

function pac.RemoveHook(str, id)
	id = "pac_" .. id

	hook.Remove(str, id)
end