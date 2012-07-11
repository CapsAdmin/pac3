--[[
	luadata by CapsAdmin (fuck copyright, do what you want with this)

	-- encodes table to string
		string 	luadata.Encode(tbl)

	-- decodes string to table
	-- it will throw an error if there's a syntax error in the table
		table 	luadata.Decode(str)

	-- writes the table to file ( it's just "file.Write(path, luadata.Encode(str))" )
		nil 	luadata.WriteFile(path, tbl)
		table 	luadata.ReadFile(path)

	-- returns a string of how the variable is typically initialized
		string  luadata.ToString(var)

	-- will let you add your own tostring function for a custom type
	-- if you have made a custom data object, you can do this "mymatrix.LuaDataType = "Matrix33""
	-- and it will make luadata.Type return that instead
		nil		luadata.SetModifier(type, callback)

]]
luadata = luadata or {} local s = luadata

luadata.EscapeSequences = {
	[("\a"):byte()] = [[\a]],
	[("\b"):byte()] = [[\b]],
	[("\f"):byte()] = [[\f]],
	[("\t"):byte()] = [[\t]],
	[("\r"):byte()] = [[\r]],
	[("\v"):byte()] = [[\v]],
}

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

--[[ 	-- comment these out if you don't want shit like this to be storeable
	["Entity"] = function(var)
		if var:IsPlayer() then
			return ("player.GetByUniqueID(%q)"):format(var:UniqueID())
		end

		return ("Entity(%i)"):format(var:EntIndex())
	end,
	["Panel"] = function(var)
		return "NULL"
	end,
	["NULL"] = function(var)
		return "NULL"
	end, ]]

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
	local func = s.Types[s.Type(var)]
	return func and func(var)
end

function luadata.Encode(tbl, __brackets)
	if luadata.Hushed then return end

	local str = __brackets and "{\n" or ""

	for key, value in pairs(tbl) do
		value = s.ToString(value)
		key = s.ToString(key)

		if key and value and key ~= "__index" then
			str = str .. ("\t"):rep(tab) ..  ("[%s] = %s,\n"):format(key, value)
		end
	end

	str = str .. ("\t"):rep(tab-1) .. (__brackets and "}" or "")

	return str
end

function luadata.Decode(str)
	return CompileString("return {\n" .. str .. "\n}", "luadata")()
end

do -- file extension

	function luadata.WriteFile(path, tbl)
		if luadata.Hushed then return end

		file.Write(path, luadata.Encode(tbl))
	end

	function luadata.ReadFile(path)
		return luadata.Decode(file.Read(path) or "")
	end

	function luadata.SetKeyValueInFile(path, key, value)
		if luadata.Hushed then return end

		local tbl = luadata.ReadFile(path)
		tbl[key] = value
		luadata.WriteFile(path, tbl)
	end

	function luadata.AppendValueToFile(path, value)
		if luadata.Hushed then return end

		local tbl = luadata.ReadFile(path)
		table.insert(tbl, value)
		luadata.WriteFile(path, tbl)
	end

	function luadata.Hush(bool)
		luadata.Hushed = bool
	end

end

do -- option extension
	function luadata.AccessorFunc(tbl, func_name, var_name, nw, def)
		tbl["Set" .. func_name] = function(self, val)
			self[nw and "SetLuaDataNWOption" or "SetLuaDataOption"](self, var_name, val or def)
		end

		tbl["Get" .. func_name] = function(self, val)
			return self[nw and "GetLuaDataNWOption" or "GetLuaDataOption"](self, var_name, def)
		end
	end

	local meta = FindMetaTable("Player")

	function meta:LoadLuaDataOptions()
		self.LuaDataOptions = luadata.ReadFile("luadata_options/" .. self:UniqueID() .. ".txt")

		for key, value in pairs(self.LuaDataOptions) do
			if key:sub(0, 3) == "_nw" then
				self:SetNWString("ld_" .. key:sub(4), glon.encode(value))
			end
		end
	end

	if SERVER then
		hook.Add("OnEntityCreated", "luadata_player_spawn", function(ply)
			if ply:IsValid() and _R.Player == getmetatable(ply) then
				ply:LoadLuaDataOptions()
			end
		end)
	end

	function meta:SaveLuaDataOptions()
		luadata.WriteFile("luadata_options/" .. self:UniqueID() .. ".txt", self.LuaDataOptions)
	end

	function meta:SetLuaDataOption(key, value)
		if not self.LuaDataOptions then self:LoadLuaDataOptions() end
		self.LuaDataOptions[key] = value
		self:SaveLuaDataOptions()
	end

	function meta:GetLuaDataOption(key, def)
		if not self.LuaDataOptions then self:LoadLuaDataOptions() end
		return self.LuaDataOptions[key] or def
	end

	function meta:SetLuaDataNWOption(key, value)
		self:SetLuaDataOption("_nw"..key, value)
		self:SetNWString("ld_" .. key, glon.encode(value))
	end

	function meta:GetLuaDataNWOption(key, def)
		local value

		if SERVER then
			value = self:GetLuaDataOption("_nw"..key)

			if value then
				return value
			end
		end

		value = self:GetNWString("ld_" .. key, false)

		return type(value) == "string" and glon.decode(value) or def
	end
end