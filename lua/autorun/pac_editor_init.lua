if not pac then
	include'pac_init.lua'
	PAC_EDITOR_INITED_PAC=true
end

if SERVER then AddCSLuaFile("pac3/editor/shared.lua") end
include("pac3/editor/shared.lua")

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

	add_files("pac3/editor/client/")

	include("pac3/editor/server/init.lua")

	-- for the default models
	resource.AddWorkshop("104691717")
end

if CLIENT then
	include("pac3/editor/client/init.lua")
end