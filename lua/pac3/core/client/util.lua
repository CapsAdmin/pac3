function pac.IsValidEntity(var)
	return IsEntity(var) and var:IsValid()
end

function pac.GetValidEntity(var)
	return pac.IsValidEntity(var) and var
end

function pac.MakeNull(tbl)
	if tbl then
		for k,v in pairs(tbl) do tbl[k] = nil end
		setmetatable(tbl, pac.NULLMeta)
	end
end

function pac.CreateEntity(model)
	local ent
	
	if net then 
		ent = ents.CreateClientProp()
	else
		ent = ents.Create("prop_physics")
	end
	
	ent:SetModel(model)
	ent:Spawn()
	
	ent.IsPACEntity = true
	
	return ent
end

do -- hook helpers
	pac.Errors = {}

	function pac.AddHook(str, func)
		func = func or pac[str]
		hook.Add(str, "pac_" .. str, function(...)
			if pac.Profiling then
				pac.StartProfiling(str)
			end
			local args = {pcall(func, ...)}
			if pac.Profiling then
				pac.StopProfiling(str)
			end
			if not args[1] then
				ErrorNoHalt("[pac3]" .. str .. " : " .. args[2] .. "\n")
				pac.RemoveHook(str)
				table.insert(pac.Errors, args[2])
			end
			table.remove(args, 1)
			return unpack(args)
		end)
	end

	function pac.RemoveHook(str)
		if hook.GetTable()[str] and hook.GetTable()[str]["pac_" .. str] then
			hook.Remove(str, "pac_" .. str)
		end
	end

	function pac.CallHook(str, ...)
		hook.Call("pac_" .. str, GAMEMODE, ...)
	end
end

do -- get set and editor vars
	local __store = false

	function pac.StartStorableVars()
		__store = true
	end

	function pac.EndStorableVars()
		__store = false
	end

	function pac.GetSet(tbl, key, ...)
		pac.class.GetSet(tbl, key, ...)

		if __store then
			tbl.StorableVars = tbl.StorableVars or {}
			tbl.StorableVars[key] = key
		end
	end

	function pac.IsSet(tbl, key, ...)
		pac.class.IsSet(tbl, key, ...)

		if __store then
			tbl.StorableVars = tbl.StorableVars or {}
			tbl.StorableVars[key] = key
		end
	end
end