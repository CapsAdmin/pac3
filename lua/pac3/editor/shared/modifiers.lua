
pace.ServerModifiers = {}
local cvarModifiers = {}

function pace.AddServerModifier(id, func)
	pace.ServerModifiers[id] = func
	return cvarModifiers[id]
end

function pace.GetServerModifiers()
	return pace.ServerModifiers
end

function pace.HandleModifiers(data, owner)
	if not owner:IsValid() then return end
	for key, func in pairs(pace.GetServerModifiers()) do
		if GetConVarNumber("pac_modifier_" .. key) ~= 0 then
			func(data, owner)
		end
	end
end

pace.ModifiersPath = "pac3/editor/shared/modifiers/"

function pace.LoadModifiers()
	local files = file.Find(pace.ModifiersPath .. "*", "LUA")

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

		include(pace.ModifiersPath .. val)
	end
end

timer.Simple(0, pace.LoadModifiers)
