
pacx.ServerModifiers = {}

function pacx.AddServerModifier(id, func)
	local cvar

	local default = 1

	if GAMEMODE and GAMEMODE.FolderName and not GAMEMODE.FolderName:lower():find("sandbox") then
		default = 0
	end

	if SERVER then
		cvar = CreateConVar("pac_modifier_" .. id, default, CLIENT and {FCVAR_REPLICATED} or {FCVAR_ARCHIVE, FCVAR_REPLICATED})
	else
		cvar = CreateClientConVar("pac_modifier_" .. id, default, true, true)
	end

	pacx.ServerModifiers[id] = function(...)
		if not cvar:GetBool() then return end
		return func(...)
	end

	return cvar
end

function pacx.GetServerModifiers()
	return pacx.ServerModifiers
end

function pacx.HandleModifiers(data, owner)
	if not owner:IsValid() then return end
	for key, func in pairs(pacx.GetServerModifiers()) do
		if GetConVarNumber("pac_modifier_" .. key) ~= 0 then
			func(data, owner)
		end
	end
end

pacx.ModifiersPath = "pac3/extra/shared/modifiers/"

function pacx.LoadModifiers()
	local files = file.Find(pacx.ModifiersPath .. "*", "LUA")

	for key, val in pairs(files) do
		include(pacx.ModifiersPath .. val)
	end
end

pac.AddHook("pac_OnWoreOutfit", "pacx_modifiers", function(owner, part_data)
	pacx.HandleModifiers(part_data, owner)
end)

pac.AddHook("pac_RemoveOutfit", "pacx_modifiers", function(owner)
	pacx.HandleModifiers(nil, owner)
end)

timer.Simple(0, pacx.LoadModifiers)
