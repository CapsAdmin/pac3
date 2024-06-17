-- VLL_CURR_FILE is local to each file
if CLIENT and pac and not VLL_CURR_FILE and not VLL2_FILEDEF then return end

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

	add_files("pac3/core/client/")
	add_files("pac3/core/shared/")
	add_files("pac3/libraries/")

	include("pac3/core/server/init.lua")
end

if CLIENT then
	if pac and pac.Panic then
		ProtectedCall(pac.Panic)
	end

	include("pac3/core/client/init.lua")
end