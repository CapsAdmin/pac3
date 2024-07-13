-- VLL_CURR_FILE is local to each file
if CLIENT and pac and pace and pacx and not VLL_CURR_FILE and not VLL2_FILEDEF then return end

if not pace then
	include("autorun/pac_editor_init.lua")
end

if not pace then
	error("pac extra requires the pac editor")
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

	add_files("pac3/extra/client/")
	add_files("pac3/extra/shared/")

	include("pac3/extra/server/init.lua")
end

if CLIENT then
	include("pac3/extra/client/init.lua")
end

