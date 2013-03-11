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
		print("[pac3] what the fuck is this")
		debug.Trace()
		
		name = "base"
	end
		
	local part = class.Create("part", name)
	
	if not part then
		print("pac3 tried to create unknown part " .. name)
		part = class.Create("part", "base")
	end
		
	part.cvar_enable = CreateClientConVar("pac_enable_" .. name, 1, true)
	part.UniqueID = tostring(util.CRC(os.time() + pac.RealTime + part_count))
	
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
		
	part.Id = part_count
	part_count = part_count + 1
	
	pac.ActiveParts[part.Id] = part
	
	part:Initialize()
	
	if owner then
		part:SetPlayerOwner(owner)
	end
	
	pac.dprint("creating %s part owned by %s", part.ClassName, tostring(owner))
	
	if not skip_hook then
		pac.CallHook("OnPartCreated", part, owner == pac.LocalPlayer)
	end
	
	return part
end

function pac.RegisterPart(META, name)
	META.TypeBase = "base"
	
	class.Register(META, "part", name)
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
			if part:GetPlayerOwner() == pac.LocalPlayer and (part.show_in_editor == nil or part.show_in_editor == true) then
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