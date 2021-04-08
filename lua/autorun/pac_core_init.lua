--[[#
	import_type("nattlua/glua.nlua")
	type pac = any
	type VLL_CURR_FILE = false
	type VLL2_FILEDEF = false


	type function include(path: string)
		local full_path = analyzer:ResolvePath("lua/" .. path:GetData())

		local code_data = assert(require("nattlua").File(full_path))

        assert(code_data:Lex())
        assert(code_data:Parse())

        local res = analyzer:AnalyzeRootStatement(code_data.SyntaxTree)

        analyzer.loaded = analyzer.loaded or {}
        analyzer.loaded[path] = res

        return res
	end

]]

-- VLL_CURR_FILE is local to each file
if CLIENT and pac and not VLL_CURR_FILE and not VLL2_FILEDEF then return end

if SERVER then
	local function add_files(dir)
		local files, folders = file.Find(dir .. "*", "LUA")

		for key, file_name in pairs(files) do
			AddCSLuaFile(dir .. file_name)
		end

		for key, folder_name in pairs(folders) do
			add_files(dir .. folder_name .. "/")
		end
	end

	add_files("pac3/core/client/")
	add_files("pac3/core/shared/")
	add_files("pac3/libraries/")

	include("pac3/core/server/init.lua")
end

if CLIENT then
	include("pac3/core/client/init.lua")
end

