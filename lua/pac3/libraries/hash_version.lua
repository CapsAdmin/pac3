local function find_recursive_lua(dir, out)
	local files, folders = file.Find(dir .. "*", "LUA")

	for _, file_name in ipairs(files) do
		table.insert(out, "lua/" .. dir .. file_name)
	end

	for _, folder_name in pairs(folders) do
		find_recursive_lua(dir .. folder_name .. "/", out)
	end
end

local write_int32 = function(v)
	return string.char(
		bit.band(bit.rshift(v, 24), 0xFF),
		bit.band(bit.rshift(v, 16), 0xFF),
		bit.band(bit.rshift(v,  8), 0xFF),
		bit.band(v, 0xFF)
	)
end

local function crc128(str)
	local hash = ""

	hash = hash .. write_int32(tonumber(util.CRC(str)))
	hash = hash .. write_int32(tonumber(util.CRC(hash)))
	hash = hash .. write_int32(tonumber(util.CRC(hash)))
	hash = hash .. write_int32(tonumber(util.CRC(hash)))

	return hash
end

local function sum_bytes(bytes)
	local num = 0
	for i = 1, #bytes do
		num = num + bytes:byte(i)
	end
	return num
end

local function bytes_to_hex(bytes)
	local out = {}
	for i = 1, #bytes do
		out[i] = ("%x"):format(bytes:byte(i))
	end
	return table.concat(out)
end

local function HASH(str)
	return crc128(str)
end

local hash_version = {}

local function expand_paths(paths)
	local out = {}
	for _, path in ipairs(paths) do
		if path:EndsWith("/") then
			if path:StartWith("lua/") then
				path = path:sub(5)
			end
			find_recursive_lua(path, out)
		else
			table.insert(out, path)
		end
	end
	return out
end

function hash_version.LuaPaths(lua_paths)
	local paths = expand_paths(lua_paths)

	local hash = ""
	local words = {}

	local done = {}
	local path_hash = {}

	local function add_word(word)
		if not done[word] and #word > 2 then
			table.insert(words, word)
			done[word] = true
		end
	end

	for _, path in ipairs(paths) do
		path = path:sub(5)
		local lua = file.Read(path, "LUA")

		if lua then
			lua:gsub("(%u%l+)", add_word)

			path_hash[path] = HASH(lua)
			hash = hash .. path_hash[path]
		end
	end

	if not words[1] then
		return {
			version_name = "unknown version",
			hash = "",
			paths = {},
		}
	end

	table.sort(words)

	local final = HASH(hash)
	local frac = sum_bytes(final)
	local seed = frac + 1

	math.randomseed(seed)

	local function get_word()
		return words[math.ceil(math.random(1, #words))]
	end

	local version_name = get_word() .. "-" .. get_word() .. "-" .. get_word()
	local hash = bytes_to_hex(final)

	math.randomseed(CurTime())

	local list = {}
	for path, hash in pairs(path_hash) do
		table.insert(list, path .. " - " .. hash:gsub(".", function(char) return ("%x"):format(char:byte()) end))
	end

	table.sort(list, function(a, b) return a:Split("-")[1] < b:Split("-")[1] end)

	return {
		version_name = version_name,
		hash = hash,
		paths = list,
	}
end

return hash_version