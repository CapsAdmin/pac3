local pac = pac
local class = pac.class

local part_count = 0 -- unique id thing
local pairs = pairs

local function merge_storable(tbl, base)
	if not base then return end
	if base.StorableVars then
		for k,v in pairs(base.StorableVars) do
			tbl.StorableVars[k] = v
		end
		merge_storable(tbl, base.BaseClass)
	end
end

local function initialize(part, owner)
	if part.PreInitialize then
		part:PreInitialize()
	end

	pac.AddPart(part)

	if owner then
		part:SetPlayerOwner(owner)
	end

	part:Initialize()
end

function pac.CreatePart(name, owner)
	owner = owner or pac.LocalPlayer

	if not name then
		name = "base"
	end

	local part = class.Create("part", name)

	if not part then
		pac.Message("Tried to create unknown part: " .. name .. '!')
		part = class.Create("part", "base")
	end

	part.Id = part_count
	part_count = part_count + 1

	part.IsEnabled = pac.CreateClientConVarFast("pac_enable_" .. name, "1", true,"boolean")
	part:SetUniqueID(tostring(util.CRC(os.time() + pac.RealTime + part_count)))

	merge_storable(part, part.BaseClass)

	if part.RemovedStorableVars then
		for k in pairs(part.RemovedStorableVars) do
			part.StorableVars[k] = nil
		end
	end

	if part.NonPhysical then
		pac.RemoveProperty(part, "Bone")
		pac.RemoveProperty(part, "Position")
		pac.RemoveProperty(part, "Angles")
		pac.RemoveProperty(part, "AngleVelocity")
		pac.RemoveProperty(part, "EyeAngles")
		pac.RemoveProperty(part, "AimName")
		pac.RemoveProperty(part, "AimPartName")
		pac.RemoveProperty(part, "PositionOffset")
		pac.RemoveProperty(part, "AngleOffset")
		pac.RemoveProperty(part, "Translucent")
		pac.RemoveProperty(part, "IgnoreZ")
		pac.RemoveProperty(part, "BlendMode")
		pac.RemoveProperty(part, "NoTextureFiltering")

		if part.ClassName ~= "group" then
			pac.RemoveProperty(part, "DrawOrder")
		end
	end

	part.DefaultVars = {}

	for key in pairs(part.StorableVars) do
		part.DefaultVars[key] = pac.class.Copy(part[key])
	end

	part.DefaultVars.UniqueID = "" -- uh

	local ok, err = xpcall(initialize, ErrorNoHalt, part, owner)
	if not ok then
		part:Remove()
		if part.ClassName ~= "base" then
			return pac.CreatePart("base", owner)
		end
	end

	pac.dprint("creating %s part owned by %s", part.ClassName, tostring(owner))

	timer.Simple(0.1, function()
		if part:IsValid() and part.show_in_editor ~= false and owner == pac.LocalPlayer then
			pac.CallHook("OnPartCreated", part)
		end
	end)

	return part
end

function pac.RegisterPart(META, name)
	META.TypeBase = "base"
	local _, name = class.Register(META, "part", name)

	if pac.UpdatePartsWithMetatable then
		pac.UpdatePartsWithMetatable(META, name)
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

		for _, part in pairs(part.children) do
			fixpart(part)
		end
	end

	return part_data
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


include("base_part.lua")