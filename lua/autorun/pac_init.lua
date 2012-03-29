if SERVER then
	AddCSLuaFile("autorun/pac_init.lua")

	local function add_files(dir)
		for _, name in pairs(file.FindInLua(dir .. "*")) do
			if name:find(".lua", nil, true) then
				AddCSLuaFile(dir .. name)
			elseif not name:find(".", nil, true) then
				add_files(dir .. name .. "/")
			end
		end
	end

	add_files("pac3/core/client/")

	include("pac3/core/server/init.lua")
end

if CLIENT then
	include("pac3/core/client/init.lua")
end