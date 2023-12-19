local pac = pac
local part_count = 0 -- unique id thing
local pairs = pairs

pac.registered_parts = {}

local function on_error(msg)
	ErrorNoHalt(debug.traceback(msg))
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

function pac.CreatePart(name, owner, tbl, make_copy, level)
	level = level or 0
	name = name or "base"
	owner = owner or pac.LocalPlayer

	local META = pac.registered_parts[name]

	if not META then
		pac.Message("Tried to create unknown part: " .. name .. '!')
		META = pac.registered_parts.base
		if not META then
			return NULL
		end
	end

	local part = setmetatable({}, META)

	part.Id = part_count
	part_count = part_count + 1

	if not tbl or not tbl.self.UniqueID then
		part:SetUniqueID(pac.Hash())
	end

	part.DefaultVars = {}

	for key in pairs(part.StorableVars) do
		if key == "UniqueID" then
			part.DefaultVars[key] = ""
		else
			part.DefaultVars[key] = pac.CopyValue(part[key])
		end
	end

	local ok, err = xpcall(initialize, on_error, part, owner)

	if not ok then
		part:Remove()

		if part.ClassName ~= "base" then
			return pac.CreatePart("base", owner, tbl)
		end
	end

	if tbl then
		part:SetTable(tbl, make_copy, level)
	end

	if not META.GloballyEnabled then
		part:SetEnabled(false)
	end

	pac.dprint("creating %s part owned by %s", part.ClassName, tostring(owner))

	return part
end

local reloading = false

function pac.RegisterPart(META)
	assert(isstring(META.ClassName), "Part has no classname")
	assert(istable(META.StorableVars), "Part " .. META.ClassName .. " has no StorableVars")

	do
		local cvarName = "pac_enable_" .. string.Replace(META.ClassName, " ", "_"):lower()
		local cvar = CreateClientConVar(cvarName, "1", true)

		cvars.AddChangeCallback(cvarName, function(name, old, new)
			local enable = tobool(new)
			META.GloballyEnabled = enable
			if enable then
				pac.Message("enabling parts by class " .. META.ClassName)
			else
				pac.Message("disabling parts by class " .. META.ClassName)
			end
			pac.EnablePartsByClass(META.ClassName, enable)
		end)

		META.GloballyEnabled = cvar:GetBool()
	end

	META.__index = META
	pac.registered_parts[META.ClassName] = META

	if pac.UpdatePartsWithMetatable and _G.pac_ReloadParts then

		if PAC_RESTART then return end
		if not Entity(1):IsPlayer() then return end
		if pac.in_initialize then return end

		if not reloading then
			reloading = true
			_G.pac_ReloadParts()
			reloading = false
		end

		timer.Create("pac_reload", 0, 1, function()
			for _, other_meta in pairs(pac.registered_parts) do
				pac.UpdatePartsWithMetatable(other_meta)
			end
		end)
	end
end

function pac.LoadParts()
	print("loading all parts")

	include("base_part.lua")
	include("base_movable.lua")
	include("base_drawable.lua")

	local files = file.Find("pac3/core/client/parts/*.lua", "LUA")
	for _, name in pairs(files) do
		include("pac3/core/client/parts/" .. name)
	end

	local files = file.Find("pac3/core/client/parts/legacy/*.lua", "LUA")
	for _, name in pairs(files) do
		include("pac3/core/client/parts/legacy/" .. name)
	end
end

function pac.GetRegisteredParts()
	return pac.registered_parts
end


