AddCSLuaFile()

local hash = include("pac3/libraries/hash_version.lua")

local pac3
local core
local editor

function _G.PAC_VERSION()
	core = core or hash.LuaPaths({
		"lua/pac3/core/",
	})

	editor = editor or hash.LuaPaths({
		"lua/pac3/editor/",
	})

	pac3 = pac3 or hash.LuaPaths({
		"lua/pac3/",
		"lua/autorun/netstream.lua",
		"lua/autorun/pac_version.lua",
		"lua/autorun/pac_core_init.lua",
		"lua/autorun/pac_editor_init.lua",
		"lua/autorun/pac_extra_init.lua",
		"lua/autorun/pac_init.lua",
		"lua/autorun/pac_init.lua",
		"lua/entities/gmod_wire_expression2/core/custom/pac.lua",
	})

	return {
		pac3 = pac3,
		editor = editor,
		core = core,
	}
end

local function dump_version(name, info, verbose)
	pac.Message(name .. " = " .. info.version_name .. " / " .. info.hash)
	if verbose then
		for _, path in ipairs(info.paths) do
			print("\t" .. path)
		end
	end
end
local function dump(info, verbose)
	dump_version("Addon", info.pac3, verbose)
	dump_version("Core", info.core, verbose)
	dump_version("Editor", info.editor, verbose)
end


if CLIENT then
	concommand.Add("pac_version", function(_, _, args)
		local info = PAC_VERSION()

		dump(info, args[1] == "1")
	end)

	net.Receive("pac_version_dump", function()
		local verbose = net.ReadBool()
		local info = net.ReadTable()

		dump(info, verbose)
	end)
end

if SERVER then
	util.AddNetworkString("pac_version_dump")
	concommand.Add("pac_version_server", function(ply, _, args)
		local verbose = args[1] == "1"
		local info = PAC_VERSION()

		if not ply:IsValid() then
			dump(info, verbose)
			return
		end

		if not ply:IsAdmin() then return end
		net.Start("pac_version_dump")
			net.WriteBool(verbose)
			net.WriteTable(info)
		net.Send(ply)
	end)
end