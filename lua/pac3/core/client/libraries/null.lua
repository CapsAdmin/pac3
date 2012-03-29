local NULL = {}

local function FALSE()
	return false
end

function NULL:__index(key)
	if key:sub(0, 2) == "Is" then
		return FALSE
	end

	error(("tried to index %q on a nil value"):format(key), 2)
end

pac.NullMeta = NULL
pac.Null = setmetatable({}, NULL)
