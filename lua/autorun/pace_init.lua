if SERVER then
	local function getfiles(dir)
		local files
		
		if net then
			files = table.Merge(file.Find("lua/" .. dir .. "*", "GAME"))
		else
			files = file.FindInLua(dir .. "*")
		end
		
		return files
	end
	
	AddCSLuaFile("autorun/pace_init.lua")
		
	local function add_files(dir)		
		for _, name in pairs(getfiles(dir)) do
			if name:sub(-4) == ".lua" then
				AddCSLuaFile(dir .. name)
			elseif not name:find(".", nil, true) then
				add_files(dir .. name .. "/")
			end
		end
	end
	
	add_files("pac3/pace/")

	for _, name in pairs(getfiles("pac3/pace/translations/")) do
		resource.AddSingleFile("pac3/pace/translations/" .. name)
	end
end

if CLIENT then
	include("pac3/pace/init.lua")
end