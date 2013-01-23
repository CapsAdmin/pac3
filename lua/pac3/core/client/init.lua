pac = pac or {}

include("libraries/null.lua")
include("libraries/class.lua")
include("libraries/luadata.lua")
include("libraries/haloex.lua")

include("pac3/core/shared/init.lua")

include("libraries/urltex.lua")
include("libraries/urlobj.lua")

function pac.LoadParts()
	local files
	
	if file.FindInLua then
		files = file.FindInLua("pac3/core/client/parts/*.lua")
	else
		files = file.Find("pac3/core/client/parts/*.lua", "LUA")
	end
	
	for _, name in pairs(files) do
		include("pac3/core/client/parts/" .. name)
	end
end

function pac.CheckParts()
	for key, part in pairs(pac.ActiveParts) do
		if not part:IsValid() then
			pac.ActiveParts[key] = nil
			pac.MakeNull(part)
		end
	end
end

function pac.RemoveAllPACEntities()
	for key, ent in pairs(ents.GetAll()) do
		if ent.pac_parts then
			pac.UnhookEntityRender(ent)
			--ent:Remove()
		end
		
		if ent.IsPACEntity then
			ent:Remove()
		end
	end
end

function pac.Panic()
	pac.RemoveAllParts()
	pac.RemoveAllPACEntities()
	pac.Parts = {}
end

include("util.lua")
include("parts.lua")

include("bones.lua")
include("hooks.lua")
include("drawing.lua")

include("owner.lua")

include("online.lua")
include("wear.lua")
include("contraption.lua")
include("expression.lua")

pac.LoadParts()

include("pac2_compat.lua")

function pac.Restart()
	if pac then pac.Panic() end
	
	local was_open
	
	if pace then 
		was_open = pace.Editor:IsValid() 
		pace.Panic() 
	end

	pac = {}
	pace = {}
	
	include("autorun/pac_init.lua")
	include("autorun/pace_init.lua")

	if was_open then 
		pace.OpenEditor() 
	end
	
	pace.LoadSession("autoload")
end

concommand.Add("pac_restart", pac.Restart)