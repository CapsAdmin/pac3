local luadata = {}

local tab = 0

luadata.Types = {
	["number"] = function(var)
		return ("%s"):format(var)
	end,
	["string"] = function(var)
		return ("%q"):format(var)
	end,
	["boolean"] = function(var)
		return ("%s"):format(var and "true" or "false")
	end,
	["Vector"] = function(var)
		return ("Vector(%s, %s, %s)"):format(var.x, var.y, var.z)
	end,
	["Angle"] = function(var)
		return ("Angle(%s, %s, %s)"):format(var.p, var.y, var.r)
	end,
	["table"] = function(var)
		if
			type(var.r) == "number" and
			type(var.g) == "number" and
			type(var.b) == "number" and
			type(var.a) == "number"
		then
			return ("Color(%s, %s, %s, %s)"):format(var.r, var.g, var.b, var.a)
		end

		tab = tab + 1
		local str = luadata.Encode(var, true)
		tab = tab - 1
		return str
	end,
}

function luadata.SetModifier(type, callback)
	luadata.Types[type] = callback
end

function luadata.Type(var)
	local t

	if IsEntity(var) then
		if var:IsValid() then
			t = "Entity"
		else
			t = "NULL"
		end
	else
		t = type(var)
	end

	if t == "table" then
		if var.LuaDataType then
			t = var.LuaDataType
		end
	end

	return t
end

function luadata.ToString(var)
	local func = luadata.Types[luadata.Type(var)]
	return func and func(var)
end

function luadata.Encode(tbl, __brackets)
	local str = __brackets and "{\n" or ""

	for key, value in pairs(tbl) do
		value = luadata.ToString(value)
		key = luadata.ToString(key)

		if key and value and key ~= "__index" then
			str = str .. ("\t"):rep(tab) ..  ("[%s] = %s,\n"):format(key, value)
		end
	end

	str = str .. ("\t"):rep(tab-1) .. (__brackets and "}" or "")

	return str
end

function luadata.Decode(str)
	local func = CompileString("return {\n" .. str .. "\n}", "luadata", false)
	
	if type(func) == "string" then
		MsgN("luadata decode error:")
		MsgN(err)
		
		return {}
	end
	
	local ok, err = pcall(func)
	
	if not ok then
		MsgN("luadata decode error:")
		MsgN(err)
		return {}
	end
	
	return err
end

do -- file extension
	function luadata.WriteFile(path, tbl)
		file.Write(path, luadata.Encode(tbl))
	end

	function luadata.ReadFile(path)
		return luadata.Decode(file.Read(path) or "")
	end
end

pac.luadata = luadata