local CurTime = CurTime
local math_Clamp = math.Clamp

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
	return hook.Call("pac_" .. str, GAMEMODE, ...)
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

function pac.RatelimitAlert( ply, id, message )
	if not ply.pac_ratelimit_alerts then
		ply.pac_ratelimit_alerts = {}
	end

	if CurTime() >= ( ply.pac_ratelimit_alerts[id] or 0 ) then
		ply.pac_ratelimit_alerts[id] = CurTime() + 3
		if isstring(message) then
			pac.Message(message)
		end
		if istable(message) then
			pac.Message(unpack(message))
		end
	end
end

local RatelimitAlert = pac.RatelimitAlert

function pac.RatelimitPlayer( ply, name, buffer, refill, message )
	local ratelimitName = "pac_ratelimit_" .. name
	local checkName = "pac_ratelimit_check_" .. name

	if not ply[ratelimitName] then ply[ratelimitName] = buffer end

	local curTime = CurTime()
	if not ply[checkName] then ply[checkName] = curTime end

	local dripSize = curTime - ply[checkName]
	ply[checkName] = curTime

	local drip = dripSize / refill
	local newVal = ply[ratelimitName] + drip

	ply[ratelimitName] = math_Clamp(newVal, 0, buffer)

	if ply[ratelimitName] >= 1 then
		ply[ratelimitName] = ply[ratelimitName] - 1
		return true
	else
		if message then
			RatelimitAlert(ply, name, message)
		end
		return false
	end
end

function pac.GetRateLimitPlayerBuffer( ply, name )
	local ratelimitName = "pac_ratelimit_" .. name
	return ply[ratelimitName] or 0
end

