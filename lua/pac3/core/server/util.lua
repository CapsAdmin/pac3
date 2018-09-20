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

function pac.AddHook(str, id, func, priority)
	id = "pac_" .. id

	if not DLib and not ULib then
		priority = nil
	end

	hook.Add(str, id, function(...)
		local status, a, b, c, d, e, f, g = pcall(func, ...)

		if not status then
			pac.Message('Error on hook ' .. str .. ' (' .. id .. ')! ', a)
			return
		end

		return a, b, c, d, e, f, g
	end, priority)
end

function pac.RemoveHook(str, id)
	id = "pac_" .. id

	hook.Remove(str, id)
end