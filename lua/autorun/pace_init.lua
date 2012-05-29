if SERVER then
	AddCSLuaFile("autorun/pace_init.lua")
		
	local function add_files(dir)
		local files
		
		if net then
			local _files, _folders = file.Find(dir .. "*", LUA_PATH)
			files = {}
			for k,v in pairs(_files) do 
				table.insert(files, v)
			end
			
			for k,v in pairs(_folders) do 
				table.insert(files, v)
			end
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

	add_files("pac3/pace/")
end

if CLIENT then
	include("pac3/pace/init.lua")
end