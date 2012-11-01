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
	local ent = ents.CreateClientProp()

	if ent and ent:IsValid() then
		ent:SetModel(model)
			
		ent.IsPACEntity = true
	end
	
	return ent or NULL
end

do -- hook helpers
	pac.Errors = {}

	function pac.AddHook(str, func)
		func = func or pac[str]
		hook.Add(str, "pac_" .. str, function(...)
			local args = {pcall(func, ...)}
			if not args[1] then
				ErrorNoHalt("[pac3]" .. str .. " : " .. args[2] .. "\n")
				--pac.RemoveHook(str)
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
		return hook.Call("pac_" .. str, GAMEMODE, ...)
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

function pac.HandleUrlMat(part, url, callback)
	if url and pac.urlmat and url:find("http") then	
		local skip_cache = url:sub(1,1) == "_"
		url = url:gsub("https://", "http://")
		url = url:match("http[s]-://.+/.-%.%a+")
		if url then
			pac.urlmat.GetMaterialFromURL(
				url, 
				function(mat, tex)
					if part:IsValid() then
						if callback then
							callback(mat, tex)
						else
							part.Materialm = mat
							part:CallEvent("material_changed")
						end
						pac.dprint("set custom material texture %q to %s", url, part:GetName())
					end
				end,
				skip_cache
			)
			return true
		end
	end	
end

local mat
local Matrix = Matrix

function pac.SetModelScale(ent, scale, size)
	if not ent:IsValid() then return end
	if ent.pac_bone_scaling then return end

	if scale then
		mat = Matrix()
		mat:Scale(scale)
		ent:EnableMatrix("RenderMultiply", mat)
		ent.pac_model_scale = scale
	end
	
	if size then
		ent:SetModelScale(size == 1 and 1.000001 or size, 0)
	end
	
	if not scale and not size then
		ent:DisableMatrix("RenderMultiply")
		ent:SetupBones()
	end
end

-- no need to rematch the same pattern
pac.PatternCache = {{}}

function pac.StringFind(a, b, simple)
	if not a or not b then return end
	
	if simple then
		a = a:lower()
		b = b:lower()
	end
	
	local hash = a..b
	
	if pac.PatternCache[hash] ~= nil then
		return pac.PatternCache[hash]
	end
	
	if simple and a:find(b, nil, true) or not simple and a:find(b) then
		pac.PatternCache[hash] = true
		return true
	else
		pac.PatternCache[hash] = false
		return false
	end
end

function pac.HideWeapon(wep, hide)
	if hide then
		wep:SetNoDraw(true)
		wep.pac_wep_hiding = true
	else
		if wep.pac_wep_hiding then
			wep:SetNoDraw(false)
			wep.pac_wep_hiding = false
		end
	end
end

-- this function adds the unique id of the owner to the part name to resolve name conflicts
-- hack??

function pac.HandlePartName(ply, name)
	if ply:IsPlayer() and ply ~= LocalPlayer() then
		return ply:UniqueID() .. " " .. name
	end
	
	if not ply:IsPlayer() and ply:IsValid() then	
		return pac.CallHook("HandlePartName", ply, name) or (ply:EntIndex() .. " " .. name)
	end

	return name
end
