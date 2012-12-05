local pac = pac
local class = pac.class

pac.ActiveParts = pac.ActiveParts or {}
local part_count = 0 -- unique id thing
local pairs = pairs

local function remove(part, field)
	if part.StorableVars then 
		part.StorableVars[field] = nil 
	end
	class.RemoveField(part, field)
end

function pac.CreatePart(name, owner)
	owner = owner or LocalPlayer()
	
	local part = class.Create("part", name)
	
	if not part then
		print("pac3 tried to create unknown part " .. name or "unknown")
		part = class.Create("part", "base")
	end
		
	part.UniqueID = tostring(util.CRC(os.time() + RealTime() + part_count))
	
	if part.NonPhysical then		
		remove(part, "Bone")
		remove(part, "Position")
		remove(part, "Angles")
		remove(part, "AngleVelocity")
		remove(part, "EyeAngles")
		remove(part, "AimName")
		remove(part, "DrawOrder")
	end
	
	if part.PreInitialize then 
		part:PreInitialize()
	end
		
	part.Id = part_count
	part_count = part_count + 1
	
	pac.ActiveParts[part.Id] = part
	
	part:Initialize()
	
	if owner then
		part:SetPlayerOwner(owner)
	end
	
	pac.dprint("creating %s part owned by %s", part.ClassName, tostring(owner))
	
	pac.CallHook("OnPartCreated", part, owner == LocalPlayer())
	
	return part
end

function pac.RegisterPart(META, name)
	if not META.Base then
		class.InsertIntoBaseField(META, "base")
	end
	
	class.Register(META, "part", name)
	
	for _, part in pairs(pac.GetParts()) do
		if part.ClassName == META.ClassName then
			for k,v in pairs(META) do
				part[k] = v
			end
		end
	end
end

function pac.GetRegisteredParts()
	return class.GetAll("part")
end

function pac.GetPart(name)
	return class.Get("part", name)
end

function pac.GetParts(owned_only)
	if owned_only then		
		local tbl = {}
		for key, part in pairs(pac.ActiveParts) do
			if part:GetPlayerOwner() == LocalPlayer() or not part:GetPlayerOwner():IsPlayer() then
				tbl[key] = part
			end
		end
		return tbl
	end
	return pac.ActiveParts
end

function pac.RemoveAllParts(owned_only, server)
	if server then
		pac.RemovePartOnServer("__ALL__")
	else
		for key, part in pairs(pac.GetParts(owned_only)) do
			if part:IsValid() then
				part:Remove()
			end
		end
	end
	if not owned_only then
		pac.ActiveParts = {}
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

include("base_part.lua")