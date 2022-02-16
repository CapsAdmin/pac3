AddCSLuaFile()

if SERVER then
    local function pacVersion()
        if steamworks.IsSubscribed( "104691717" ) then
            return "workshop"
        end

        for k,v in pairs(select(2, file.Find( "addons/*", "GAME" ))) do
            if file.Exists("addons/"..v.."/lua/autorun/pac_init.lua", "GAME") then
                local dir = "addons/"..v.."/.git/"
                local head = file.Read(dir.."HEAD", "GAME") -- Where head points to
                if not head then break end

                head = string.match(head, "ref:%s+(%S+)")
                if not head then break end

                local lastCommit = file.Read( dir..head, "GAME")
                if not lastCommit then break end

                return lastCommit
            end
        end

        return "unknown"
    end
    SetGlobalString("pac_version", pacVersion())
end

function _G.PAC_VERSION()
    return GetGlobalString("pac_version")
end

concommand.Add("pac_version", function(_, _, args)
	print(PAC_VERSION())
end)
