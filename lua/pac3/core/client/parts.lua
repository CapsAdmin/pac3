local pac = pac
local class = pac.class

pac.ActiveParts = pac.ActiveParts or {}
pac.UniqueIDParts = pac.UniqueIDParts or {}

local part_count = 0 -- unique id thing
local pairs = pairs

local function remove(part, field)
	if part.StorableVars then 
		part.StorableVars[field] = nil 
	end
	class.RemoveField(part, field)
end

local function merge_storable(tbl, base)
	if not base then return end
	if base.StorableVars then
		for k,v in pairs(base.StorableVars) do
			tbl.StorableVars[k] = v
		end
		merge_storable(tbl, base.BaseClass)
	end
end

function pac.CreatePart(name, owner, skip_hook)
	owner = owner or pac.LocalPlayer
	
	if not name then
		name = "base"
	end
		
	local part = class.Create("part", name)
	
	if not part then
		print("pac3 tried to create unknown part " .. name)
		part = class.Create("part", "base")
	end
	
	part.Id = part_count
	part_count = part_count + 1	
	
	part.IsEnabled = pac.CreateClientConVarFast("pac_enable_" .. name, "1", true,"boolean")
	part:SetUniqueID(tostring(util.CRC(os.time() + pac.RealTime + part_count)))
	
	merge_storable(part, part.BaseClass)
	
	if part.NonPhysical then		
		remove(part, "Bone")
		remove(part, "Position")
		remove(part, "Angles")
		remove(part, "AngleVelocity")
		remove(part, "EyeAngles")
		remove(part, "AimName")
		remove(part, "AimPartName")
		remove(part, "AnglePartName")
		remove(part, "AnglePartMultiplier")
		remove(part, "PositionOffset")
		remove(part, "AngleOffset")
		remove(part, "Translucent")
		
		if part.ClassName ~= "group" then 
			remove(part, "DrawOrder") 
		end
	end
	
	part.DefaultVars = {}
	
	for key, val in pairs(part.StorableVars) do
		part.DefaultVars[key] = pac.class.Copy(part[key])
	end
	
	part.DefaultVars.UniqueID = "" -- uh
	
	if part.PreInitialize then 
		part:PreInitialize()
	end
		
	pac.ActiveParts[part.Id] = part
	
	if owner then
		part:SetPlayerOwner(owner)
	end
	
	part:Initialize()
		
	pac.dprint("creating %s part owned by %s", part.ClassName, tostring(owner))
	
	if not pac.SuppressCreatedEvents then
		pac.CallHook("OnPartCreated", part, owner == pac.LocalPlayer)
	end
		
	return part
end

function pac.RegisterPart(META, name)
	META.TypeBase = "base"	
	local _, name = class.Register(META, "part", name)
	
	-- update part functions only
	-- updating variables might mess things up
	for key, part in pairs(pac.GetParts()) do
		if part.ClassName == name then
			for k, v in pairs(META) do
				if type(v) == "function" then
					part[k] = v
				end
			end
		end
	end	
end

function pac.LoadParts()
	local files = file.Find("pac3/core/client/parts/*.lua", "LUA")
	
	for _, name in pairs(files) do
		include("pac3/core/client/parts/" .. name)
	end
end

function pac.GetRegisteredParts()
	return class.GetAll("part")
end

function pac.GetParts(owned_only)
	if owned_only then		
		return pac.UniqueIDParts[pac.LocalPlayer:UniqueID()] or {}
	end
	
	return pac.ActiveParts
end

function pac.GetPartFromUniqueID(owner_id, id)
	return pac.UniqueIDParts[owner_id] and pac.UniqueIDParts[owner_id][id] or pac.NULL
end

function pac.GetPartsFromUniqueID(owner_id)
	return pac.UniqueIDParts[owner_id] or {}
end

function pac.RemoveAllParts(owned_only, server)
	if server then
		pace.RemovePartOnServer("__ALL__")
	end
	
	for key, part in pairs(pac.GetParts(owned_only)) do
		if part:IsValid() then
			part:Remove()
		end
	end
	
	if not owned_only then
		pac.ActiveParts = {}
		pac.UniqueIDParts = {}
	end
end

function pac.GetPartCount(class, children)
	class = class:lower()
	local count = 0

	for key, part in pairs(children or pac.GetParts(true)) do
		if part.ClassName:lower() == class then
			count = count + 1
		end
	end

	return count
end

function pac.CallPartHook(name, ...)
	for key, part in pairs(pac.GetParts()) do
		if part[name] then
			part[name](part, ...)
		end
	end
end

function pac.GenerateNewUniqueID(part_data, base)
	local part_data = table.Copy(part_data)
	base = base or tostring(part_data)
	
	local function fixpart(part)
		for key, val in pairs(part.self) do
			if val ~= "" and (key == "UniqueID" or key:sub(-3) == "UID") then
				part.self[key] = util.CRC(base .. val)
			end
		end
		
		for key, part in pairs(part.children) do
			fixpart(part)
		end
	end
	
	return part_data
end

include("base_part.lua")