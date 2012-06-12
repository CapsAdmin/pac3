if SERVER then
	AddCSLuaFile("autorun/pac_init.lua")

	local function add_files(dir)
		local files
		
		if not file.FindInLua then
			files = table.Merge(file.Find("lua/" .. dir .. "*", "GAME"))
		else
			files = file.FindInLua(dir .. "*")
		end
		
		for _, name in pairs(files) do
			if name:sub(-4) == ".lua" then
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