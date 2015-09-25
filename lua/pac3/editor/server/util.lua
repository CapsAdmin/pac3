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

function pace.AddHook(str, func)
	func = func or pac[str]
	hook.Add(str, "pac", function(...)
		return wrap_err(pcall(func, ...))
	end)
end

function pace.RemoveHook(str)
	hook.Remove(str, "pac")
end