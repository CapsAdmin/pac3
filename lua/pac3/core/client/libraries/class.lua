local printf = function(fmt, ...) MsgN(string.format(fmt, ...)) end

local class = {}

class.Registered = {}

local function checkfield(tbl, key, def)
    tbl[key] = tbl[key] or def
	
    if not tbl[key] then
        error(string.format("The key %q was not found!", key), 3)
    end

    return tbl[key]
end

local function table_copy(tbl)
	if getmetatable(tbl) then return tbl end
	
	local out = {}
	
	for k,v in pairs(tbl) do
		if type(v) == "table" then
			out[k] = table_copy(v)
		else
			if type(v) == "Vector" or type(v) == "Angle" then 
				v = v * 1 
			end 
		
			out[k] = v
		end
	end
	
	return out
end

function class.Copy(var) 
	if type(var) == "Vector" or type(var) == "Angle" then 
		return var * 1 
	end 
	
	if type(var) == "table" then
		return table_copy(var)
	end
	
	return var 
end

function class.GetSet(tbl, name, def)
    if type(def) == "number" then
		tbl["Set" .. name] = tbl["Set" .. name] or function(self, var) self[name] = tonumber(var) end
		tbl["Get" .. name] = tbl["Get" .. name] or function(self, var) return tonumber(self[name]) end
	else
		tbl["Set" .. name] = tbl["Set" .. name] or function(self, var) self[name] = var end
		tbl["Get" .. name] = tbl["Get" .. name] or function(self, var) return self[name] end
	end
	tbl["__def" .. name] = def
    tbl[name] = def
end

function class.IsSet(tbl, name, def)
	if type(def) == "number" then
		tbl["Set" .. name] = tbl["Set" .. name] or function(self, var) self[name] = tonumber(var) end
	else
		tbl["Set" .. name] = tbl["Set" .. name] or function(self, var) self[name] = var end
	end
    tbl["Is" .. name] = tbl["Is" .. name] or function(self, var) return self[name] ~= nil end
	tbl["__def" .. name] = def
    tbl[name] = def
end

function class.RemoveField(tbl, name)
	tbl["Set" .. name] = nil
    tbl["Get" .. name] = nil
    tbl["Is" .. name] = nil
	tbl["__def" .. name] = nil
    tbl[name] = nil
end

function class.Get(type, name)
    if not type then return end
    if not name then return end
    return class.Registered[type] and class.Registered[type][name] or nil
end

function class.GetAll(type)
	return class.Registered[type]
end

function class.Register(META, type, name)
    local type = checkfield(META, "Type", type)
    local name = checkfield(META, "ClassName", name)

    class.Registered[type] = class.Registered[type] or {}
    class.Registered[type][name] = META
end

function class.InsertIntoBaseField(META, var, pos)

	local T1 = type(META.Base)
	local T2 = type(var)

	if T1 == "table" then
		if T2 == "table" and not var.Type then
			for key, base in pairs(var) do
				table.insert(META.Base, key, base)
			end
		else
			if table.HasValue(META.Base, var) then return end

			if pos then
				table.insert(META.Base, pos, var)
			else
				table.insert(META.Base, var)
			end
		end
	end

	if META.ClassName == var then return end

	if T1 == "string" then
		META.Base = {META.Base}
		class.InsertIntoBaseField(META, var, pos)
	end

	if T1 == "nil" then
		META.Base = {var}
	end
end

function class.Derive(obj, var)
	local T = type(var)

	if T == "nil" then
		return
	end

	if T == "string" then
		var = class.Get(obj.Type, var)
		T = type(var)
	end

	if T == "table" then
		if var.Type then
			obj.BaseClass = table_copy(var)
		else
			for _, base in pairs(var) do
				class.Derive(obj, base)
			end
		end

		if var.Base then
			class.Derive(var, var.Base)
		end

		for key, val in pairs(var) do
			if type(val) == "table" then
				if getmetatable(val) then
					obj[key] = val
				else
					obj[key] = obj[key] or {}
					table.Merge(obj[key], table_copy(val))
				end
			end
		end
	end

	-- the code below is kinda huh
	local tbl = {}
	local cur = obj
	for i = 1, 10 do
		if cur then
			table.insert(tbl, cur)
			cur = cur.BaseClass
		else
			break
		end
	end

	for _, base in pairs(tbl) do
		for key, val in pairs(base) do
			obj[key] = obj[key] or val
		end
	end

	obj.__bases = tbl
end

function class.Create(type, class_name)
    local META = class.Get(type, class_name)
	
    if not META then
        printf("tried to create unknown %s %q!", type or "no type", class_name or "no class")
        return
    end

	META = table_copy(META)
	class.Derive(META, META.Base)

	if not META.__tostring then
		function META:__tostring()
			return string.format("%s[%s]", self.Type, self.ClassName)
		end
	end

	if META.Base then
		function META:__index(key)
			if META[key] ~= nil then
				return META[key]
			end

			for key, base in pairs(META.__bases) do
				if base[key] ~= nil then
					return base[key]
				end
			end
			
			if META.__indexx then
				return META.__indexx(self, key)
			end
		end
	else
		META.__index = META
	end
	
	local default_vars = {}
	
	for key, val in pairs(META) do
		if key:sub(1, 5) == "__def" then
			default_vars[key:sub(6)] = class.Copy(val)
		end
	end
			
	local obj = setmetatable(default_vars, META)
	
	return obj
end

pac.class = class