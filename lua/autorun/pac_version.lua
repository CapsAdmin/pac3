AddCSLuaFile()

if SERVER then
	local function pacVersion()
		local addonFound = false

		for k,v in pairs(select(2, file.Find( "addons/*", "GAME" ))) do
			if file.Exists("addons/"..v.."/lua/autorun/pac_init.lua", "GAME") then
				addonFound = true
				local dir = "addons/"..v.."/.git/"
				local head = file.Read(dir.."HEAD", "GAME") -- Where head points to
				if not head then break end

				head = string.match(head, "ref:%s+(%S+)")
				if not head then break end

				local lastCommit = string.match(file.Read( dir..head, "GAME") or "", "%S+")
				if not lastCommit then break end

				return "Git: " .. string.GetFileFromFilename(head) .. " (" .. lastCommit .. ")"
			end
		end

		if addonFound then
			return "unknown"
		else
			return "workshop"
		end
	end

	SetGlobalString("pac_version", pacVersion())
end

function _G.PAC_VERSION()
	return GetGlobalString("pac_version")
end

concommand.Add("pac_version", function()
	print(PAC_VERSION())
	if CLIENT and PAC_VERSION() == "workshop" then
		print("Fetching workshop info...")
		steamworks.FileInfo( "104691717", function(result)
			print("Updated: " .. os.date("%x %X", result.updated))
		end)
	end
end)
