
pac.ServerModifiers = {}
local cvarModifiers = {}

function pac.AddServerModifier(id, func)
	pac.ServerModifiers[id] = func
	return cvarModifiers[id]
end

function pac.GetServerModifiers()
	return pac.ServerModifiers
end

function pac.HandleModifiers(data, owner)
	if not owner:IsValid() then return end
	for key, func in pairs(pac.GetServerModifiers()) do
		if GetConVarNumber("pac_modifier_" .. key) ~= 0 then
			func(data, owner)
		end
	end
end

pac.ModifiersPath = "pac3/core/shared/modifiers/"

function pac.LoadModifiers()
	local files = file.Find(pac.ModifiersPath .. "*", "LUA")

	for key, val in pairs(files) do
		local name = val:match("(.-)%.")

		local default = 1

		if GAMEMODE and GAMEMODE.FolderName and not GAMEMODE.FolderName:lower():find("sandbox") then
			default = 0
		end

		local cvar

		if SERVER then
			cvar = CreateConVar("pac_modifier_" .. name, default, bit.bor(FCVAR_REPLICATED, FCVAR_ARCHIVE))
		end

		if CLIENT then
			cvar = CreateClientConVar("pac_modifier_" .. name, default, true, true)
		end

		cvarModifiers[name] = cvar

		include(pac.ModifiersPath .. val)
	end
end

timer.Simple(0, pac.LoadModifiers)
