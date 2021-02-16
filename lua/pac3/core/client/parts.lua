local pac = pac
local part_count = 0 -- unique id thing
local pairs = pairs

pac.registered_parts = {}

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

function pac.CreatePart(name, owner, tbl)
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
		part:SetUniqueID(util.CRC(os.time() + pac.RealTime + part_count))
	end

	part.DefaultVars = {}

	for key in pairs(part.StorableVars) do
		if key == "UniqueID" then
			part.DefaultVars[key] = ""
		else
			part.DefaultVars[key] = pac.CopyValue(part[key])
		end
	end

	local ok, err = xpcall(initialize, ErrorNoHalt, part, owner)

	if not ok then
		part:Remove()
		if part.ClassName ~= "base" then
			return pac.CreatePart("base", owner, tbl)
		end
	end

	if tbl then
		part:SetTable(tbl)
	end

	pac.dprint("creating %s part owned by %s", part.ClassName, tostring(owner))

	return part
end

local reloading = false

function pac.RegisterPart(META)
	do
		local enabled = pac.CreateClientConVarFast("pac_enable_" .. META.ClassName, "1", true, "boolean")
		function META:IsEnabled()
			return enabled()
		end
	end

	META.__index = META
	pac.registered_parts[META.ClassName] = META

	if pac.UpdatePartsWithMetatable and _G.pac_ReloadParts then

		if PAC_RESTART or not Entity(1):IsPlayer() then return end

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


