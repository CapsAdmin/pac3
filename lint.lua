package.path = '/home/caps/github/nattlua/?.lua;' .. package.path

local nl = require("nattlua")

local function GetFilesRecursively(dir, ext)
    ext = ext or ".lua"

    local f = assert(io.popen("find " .. dir))
    local lines = f:read("*all")
    local paths = {}
    for line in lines:gmatch("(.-)\n") do
        if line:sub(-4) == ext then
            table.insert(paths, line)
        end
    end
    return paths
end

local function read_file(path)
	local f = assert(io.open(path, "r"))
	local contents = f:read("*all")
	f:close()
	return contents
end

local function write_file(path, contents)
	local f = assert(io.open(path, "w"))
	f:write(contents)
	f:close()
end

local lua_files = GetFilesRecursively("./lua/", ".lua")

local blacklist = {
	["./lua/entities/gmod_wire_expression2/core/custom/pac.lua"] = true,
}

local config = {
	preserve_whitespace = false,
	string_quote = "\"",
	no_semicolon = true,
	force_parenthesis = true,
	extra_indent = {
		StartStorableVars = {
			to = "EndStorableVars",
		},

		Start2D = {to = "End2D"},
		Start3D = {to = "End3D"},
		Start3D2D = {to = "End3D2D"},

		-- in case it's localized
		cam_Start2D = {to = "cam_End2D"},
		cam_Start3D = {to = "cam_End3D"},
		cam_Start3D2D = {to = "cam_End3D2D"},
		cam_Start = {to = "cam_End"},

		Start = {
			to = {
				SendToServer = true,
				Send = true,
				Broadcast = true,
				End = true,
			}
		},

		SetPropertyGroup = "toggle",
	}
}

for _, path in ipairs(lua_files) do
	if not blacklist[path] then
		local lua_code = read_file(path)
		local new_lua_code = assert(nl.Code(lua_code, "@" .. path, config)):Emit() .. "\n"
		--assert(loadstring(new_lua_code, "@" .. path))
		write_file(path, new_lua_code)
	end
end