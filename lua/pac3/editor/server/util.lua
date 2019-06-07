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


local function wrap_err(ok,...)
	if not ok then
		ErrorNoHalt(tostring((...)) .. "\n")
	end
	return ...
end

function pace.PCallCriticalFunction(ply, func, ...)
	if ply.pac_pcall_last_error and ply.pac_pcall_last_error + 1 > SysTime() then
		local time = RealTime()
		if not ply.pac_pcall_next_print or ply.pac_pcall_next_print < time then
			pac.Message("cannot handle net message from ", ply, " because it errored less than 1 second ago")
			ply.pac_pcall_next_print = time + 1
		end
		return false
	end

	local ok, msg = pcall(func, ...)

	if ok then
		return ok, msg
	end

	pac.Message("net receive error from ", ply, ": ", msg)

	ply.pac_pcall_last_error = SysTime()

	return false
end

function pace.PCallNetReceive(receive, id, func)
	receive(id, function(len, ply, ...)
		pace.PCallCriticalFunction(ply, func, len, ply, ...)
	end)
end