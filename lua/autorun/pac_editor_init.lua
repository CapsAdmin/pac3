-- VLL_CURR_FILE is local to each file
if CLIENT and pac and pace and not VLL_CURR_FILE and not VLL2_FILEDEF then return end

if not pac then
	include("autorun/pac_core_init.lua")
end

if not pac then
	error("pac editor requires pac core")
end

if SERVER then
	local function add_files(dir)
		local files, folders = file.Find(dir .. "*", "LUA")

		for i = 1, #files do
			AddCSLuaFile(dir .. files[i])
		end

		for i = 1, #folders do
			add_files(dir .. folders[i] .. "/")
		end
	end

	add_files("pac3/editor/client/")
	add_files("pac3/editor/shared/")

	include("pac3/editor/server/init.lua")
end

if CLIENT then
	include("pac3/editor/client/init.lua")
end