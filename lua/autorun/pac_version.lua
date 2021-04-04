AddCSLuaFile()

local function dump_version(name, info, verbose)
	pac.Message(name .. " = " .. info.version_name .. " / " .. info.hash)
	if verbose then
		for _, path in ipairs(info.paths) do
			print("\t" .. path)
		end
	end
end

local function dump(info, verbose)
	dump_version("Addon", info.addon, verbose)
	dump_version("Core", info.core, verbose)
	dump_version("Editor", info.editor, verbose)
end

if CLIENT then
	local info

	function _G.PAC_VERSION()
		return info
	end

	net.Receive("pac_version", function()
		info = net.ReadTable()
	end)

	concommand.Add("pac_version", function(_, _, args)
		if not info then
			print("pac version has not been received from server yet")
			return
		end
		dump(info, args[1] == "1")
	end)
end

if SERVER then
	local hash = include("pac3/libraries/hash_version.lua")

	function _G.PAC_VERSION()
		return {
			addon = hash.LuaPaths({
				"lua/pac3/",
				"lua/autorun/netstream.lua",
				"lua/autorun/pac_version.lua",
				"lua/autorun/pac_core_init.lua",
				"lua/autorun/pac_editor_init.lua",
				"lua/autorun/pac_extra_init.lua",
				"lua/autorun/pac_init.lua",
				"lua/autorun/pac_init.lua",
				"lua/entities/gmod_wire_expression2/core/custom/pac.lua",
			}),
			editor = hash.LuaPaths({
				"lua/pac3/editor/",
			}),
			core = hash.LuaPaths({
				"lua/pac3/core/",
			}),
		}
	end

	util.AddNetworkString("pac_version")

	local info = PAC_VERSION()

	concommand.Add("pac_calc_version", function(ply, _, args)
		if not ply:IsAdmin() or not ply:IsValid() then return end

		local verbose = args[1] == "1"
		info = PAC_VERSION()

		net.Start("pac_version")
			net.WriteTable(info)
		net.Broadcast()

		dump(info, verbose)
	end)

	hook.Add("PlayerInitialSpawn", "pac_version", function( ply)
		local id = "pac_version_" .. pac.Hash(ply)
		hook.Add("SetupMove", id, function(self, mov, cmd)
			if self == ply and not cmd:IsForced() then
				hook.Remove("SetupMove", id)

				net.Start("pac_version")
					net.WriteTable(info)
				net.Send(ply)
			end
		end)
	end)
end