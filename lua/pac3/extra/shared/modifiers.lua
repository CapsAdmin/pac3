
pacx.ServerModifiers = {}
local cvarModifiers = {}

function pacx.AddServerModifier(id, func)
	pacx.ServerModifiers[id] = func
	return cvarModifiers[id]
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

		include(pacx.ModifiersPath .. val)
	end
end

hook.Add("pac_WearOutfit", "pacx_modifiers", function(owner, part_data)
	pacx.HandleModifiers(part_data, owner)
end)

hook.Add("pac_RemoveOutfit", "pacx_modifiers", function(owner)
	pacx.HandleModifiers(nil, owner)
end)

timer.Simple(0, pacx.LoadModifiers)
