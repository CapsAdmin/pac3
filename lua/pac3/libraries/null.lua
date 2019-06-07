local NULL = {}

NULL.LuaDataType = "pac_null"
NULL.ClassName = "NULL"

local function FALSE()
	return false
end

function NULL:__tostring()
	return "pac_null"
end

function NULL:IsValid()
	return false
end

function NULL:__index(key)
	if key == "IsValid" then
		return FALSE
	end

	if key == "ClassName" then
		return "NULL"
	end

	if type(key) == "string" and key:sub(0, 2) == "Is" then
		return FALSE
	end

	error(("tried to index %q on a null part"):format(key), 2)
end

return NULL