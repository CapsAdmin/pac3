local pcfparser = {}

local string_find = string.find
local string_sub = string.sub
local string_match = string.match
local string_lower = string.lower
local file_Open = file.Open

local DEFINITION_TYPE = "DmeParticleSystemDefinition"
local HEADER_PREFIX = "<!-- dmx encoding binary "
local STRING_CHUNK = 64
local GUID_SIZE = 16

local function read_u16(f, size)
	if f:Tell() + 2 > size then return end
	return f:ReadUShort()
end

local function read_u32(f, size)
	if f:Tell() + 4 > size then return end
	return f:ReadULong()
end

local function read_index(f, size, wide)
	if wide then return read_u32(f, size) end
	return read_u16(f, size)
end

local function read_string(f)
	local start = f:Tell()
	local str = {}

	while true do
		local chunk = f:Read(STRING_CHUNK)
		if not chunk or chunk == "" then return end

		local stop = string_find(chunk, "\0", 1, true)
		if stop then
			table.insert(str, string_sub(chunk, 1, stop - 1))
			f:Seek(start + #str + 1)
			return table.concat(str)
		end

		table.insert(str, chunk)
	end
end

function pcfparser.ParseEffectNames(f)
	local names = {}
	local size = f:Size()

	if f:Read(#HEADER_PREFIX) ~= HEADER_PREFIX then return names end

	local header = read_string(f)
	local version = header and tonumber(string_match(header, "^(%d+)"))
	if not version or version > 5 then return names end

	local dict = {}

	if version >= 2 then
		local count = read_index(f, size, version > 3)
		if not count then return names end

		for i = 0, count - 1 do
			dict[i] = read_string(f)
			if not dict[i] then return names end
		end
	end

	local element_count = read_u32(f, size)
	if not element_count then return names end

	for _ = 1, element_count do
		local type_name, name

		if version < 2 then
			type_name = read_string(f)
			if not type_name then return names end
		else
			local index = read_index(f, size, version > 4)
			if not index then return names end
			type_name = dict[index]
		end

		if version <= 3 then
			name = read_string(f)
			if not name then return names end
		else
			local index = read_index(f, size, version > 4)
			if not index then return names end
			name = dict[index]
		end

		if f:Tell() + GUID_SIZE > size then return names end
		f:Skip(GUID_SIZE)

		if type_name == DEFINITION_TYPE and name and name ~= "" then
			names[string_lower(name)] = name
		end
	end

	return names
end

function pcfparser.ReadEffectNames(path, game_path)
	local f = file_Open(path, "rb", game_path or "GAME")
	if not f then return {} end

	local ok, names = pcall(pcfparser.ParseEffectNames, f)
	f:Close()

	if not ok then error(names, 0) end

	return names
end

return pcfparser
