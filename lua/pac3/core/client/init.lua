pac = pac or {}

include("libraries/luadata.lua")
include("libraries/class.lua")
include("libraries/null.lua")

-- no need to rematch the same pattern
pac.PatternCache = {{}}

function pac.LoadParts()
	for _, name in pairs(file.FindInLua("pac3/core/client/parts/*.lua")) do
		include("pac3/core/client/parts/" .. name)
	end
end

do -- utils
	function pac.IsValidEntity(var)
		return IsEntity(var) and var:IsValid()
	end

	function pac.GetValidEntity(var)
		return pac.IsValidEntity(var) and var
	end

	function pac.MakeNull(tbl)
		if tbl then
			for k,v in pairs(tbl) do tbl[k] = nil end
			setmetatable(tbl, pac.NullMeta)
		end
	end

	function pac.CreateEntity(model)
		local ent = ents.Create("prop_physics")
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
				local args = {pcall(func, ...)}
				if not args[1] then
					ErrorNoHalt(args[2] .. "\n")
					table.insert(pac.Errors, args[2])
				end
				table.remove(args, 1)
				return unpack(args)
			end)
		end

		function pac.RemoveHook(str)
			hook.Remove(str, "pac_" .. str)
		end

		function pac.CallHook(str, ...)
			hook.Call("pac_" .. str, GAMEMODE, ...)
		end
	end

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

function pac.RemoveAllPACEntities()
	for key, ent in pairs(ents.GetAll()) do
		if ent.IsPACEntity then
			ent:Remove()
		end
	end
end

function pac.Clear()

end

include("outfits.lua")
include("parts.lua")

include("meta/outfit.lua")
include("meta/part.lua")

include("bones.lua")
include("hooks.lua")

include("online.lua")
include("submit.lua")

pac.LoadParts()