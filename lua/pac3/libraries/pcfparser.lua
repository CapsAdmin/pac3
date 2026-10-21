local pcfparser = {}

local DEFINITION_TYPE = "DmeParticleSystemDefinition"

local function read_u16(data, pos)
	local a, b = data:byte(pos, pos + 1)
	if not b then return end
	return a + b * 256, pos + 2
end

local function read_u32(data, pos)
	local a, b, c, d = data:byte(pos, pos + 3)
	if not d then return end
	return a + b * 256 + c * 65536 + d * 16777216, pos + 4
end

local function read_string(data, pos)
	local stop = data:find("\0", pos, true)
	if not stop then return end
	return data:sub(pos, stop - 1), stop + 1
end

function pcfparser.ParseEffectNames(data)
	local names = {}
	if not data then return names end

	local header_start = data:find("<!-- dmx encoding binary ", 1, true)
	if header_start ~= 1 then return names end

	local version = tonumber(data:match("^(%d+)", header_start + 25))
	local header_end = data:find(" -->", header_start, true)
	if not version or not header_end or version > 5 then return names end

	local pos = header_end + 6
	local dict = {}

	if version >= 2 then
		local count
		if version <= 3 then
			count, pos = read_u16(data, pos)
		else
			count, pos = read_u32(data, pos)
		end
		if not count then return names end

		for i = 0, count - 1 do
			dict[i], pos = read_string(data, pos)
			if not pos then return names end
		end
	end

	local element_count
	element_count, pos = read_u32(data, pos)
	if not element_count then return names end

	for _ = 1, element_count do
		local type_name, name

		if version < 2 then
			type_name, pos = read_string(data, pos)
		elseif version <= 4 then
			local index
			index, pos = read_u16(data, pos)
			type_name = index and dict[index]
		else
			local index
			index, pos = read_u32(data, pos)
			type_name = index and dict[index]
		end
		if not pos then return names end

		if version <= 3 then
			name, pos = read_string(data, pos)
		elseif version == 4 then
			local index
			index, pos = read_u16(data, pos)
			name = index and dict[index]
		else
			local index
			index, pos = read_u32(data, pos)
			name = index and dict[index]
		end
		if not pos then return names end

		pos = pos + 16

		if type_name == DEFINITION_TYPE and name and name ~= "" then
			names[name:lower()] = name
		end
	end

	return names
end

function pcfparser.ReadEffectNames(path, game_path)
	local f = file.Open(path, "rb", game_path or "GAME")
	if not f then return {} end

	local data = f:Read(f:Size())
	f:Close()

	return pcfparser.ParseEffectNames(data)
end

return pcfparser
