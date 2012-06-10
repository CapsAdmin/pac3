pac = pac or {}

--include("libraries/profiler.lua")
include("libraries/luadata.lua")
include("libraries/class.lua")
include("libraries/null.lua")

-- no need to rematch the same pattern
pac.PatternCache = {{}}

function pac.LoadParts()
	local files
	
	if file.FindInLua then
		files = file.FindInLua("pac3/core/client/parts/*.lua")
	else
		files = file.Find("pac3/core/client/parts/*.lua", LUA_PATH)
	end
	
	for _, name in pairs(files) do
		include("pac3/core/client/parts/" .. name)
	end
end

function pac.RemoveAllPACEntities()
	for key, ent in pairs(ents.GetAll()) do
		if ent.IsPACEntity then
			ent:Remove()
		end
	end
end

function pac.Panic()
	pac.RemoveAllParts()
	--pac.RemoveAllPACEntities()
	pac.Parts = {}
end

include("util.lua")
include("parts.lua")

include("bones.lua")
include("hooks.lua")

-- include("online.lua")
include("submit.lua")

pac.LoadParts()

include("pac2_compat.lua")

function pac.StringFind(a, b, simple)
	if simple then
		a = a:lower()
		b = b:lower()
	end
	
	local hash = a..b
	
	if pac.PatternCache[hash] ~= nil then
		return pac.PatternCache[hash]
	end
	
	if simple and a:find(b, nil, true) or not simple and a:find(b) then
		pac.PatternCache[hash] = true
		return true
	else
		pac.PatternCache[hash] = false
		return false
	end
end

function pac.HideWeapon(wep, hide)
	if hide then
		if not wep.RenderOverride then
			wep.RenderOverride = function() end
		end
	else
		if wep.RenderOverride then
			wep.RenderOverride = nil
		end
	end
end

concommand.Add("pac_restart", function()
	if pac then pac.Panic() end
	local was_open
	if pace then was_open = pace.Editor:IsValid() pace.Panic() end

	pac = {}
	pace = {}
	
	include("autorun/pac_init.lua")
	include("autorun/pace_init.lua")

	if was_open then 
		pace.OpenEditor() 
	end
end)