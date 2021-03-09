pacx.ModifiersPath = "pac3/extra/shared/modifiers/"

pacx.Modifiers = {}

function pacx.AddServerModifier(id, change_callback)
	local name = "pac_modifier_" .. id

	local default = 1

	if GAMEMODE and GAMEMODE.FolderName and not GAMEMODE.FolderName:lower():find("sandbox") then
		default = 0
	end

	local cvar = CreateConVar(name, default, CLIENT and {FCVAR_REPLICATED} or {FCVAR_ARCHIVE, FCVAR_REPLICATED})

	if change_callback then
		cvars.AddChangeCallback(name, function()
			local enable = cvar:GetBool()
			change_callback(enable)

			if SERVER then
				-- https://github.com/Facepunch/garrysmod-issues/issues/3740
				net.Start("pacx_modifiers_change")
					net.WriteString(id)
					net.WriteBool(enable)
				net.Broadcast()
			end
		end, id .. "_change")
	end

	pacx.Modifiers[id] = change_callback or true

	return cvar
end

function pacx.LoadModifiers()
	local files = file.Find(pacx.ModifiersPath .. "*", "LUA")

	for key, val in pairs(files) do
		include(pacx.ModifiersPath .. val)
	end
end

if SERVER then
	util.AddNetworkString("pacx_modifiers_change")
end

if CLIENT then
	net.Receive("pacx_modifiers_change", function()
		local id = net.ReadString()
		local enable = net.ReadBool()
		local func = pacx.Modifiers[id]
		if type(func) == "function" then
			func(enable)
		end
	end)
end

timer.Simple(0, pacx.LoadModifiers)
