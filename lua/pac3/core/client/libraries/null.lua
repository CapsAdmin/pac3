local NULL = {}

local function FALSE()
	return false
end

function NULL:__tostring()
	return "NULL"
end

function NULL:IsValid()
	return false
end

function NULL:__index(key)
	if type(key) == "string" and string.sub(key, 0, 2) == "Is" then
		return FALSE
	end

	error(("tried to index %q on a null value"):format(key), 2)
end

pac.NULLMeta = NULL
pac.NULL = setmetatable({}, NULL)
