pac = pac or {}

include("libraries/null.lua")
include("libraries/class.lua")
include("libraries/luadata.lua")
include("libraries/haloex.lua")

include("pac3/core/shared/init.lua")

include("libraries/urltex.lua")
include("libraries/urlobj.lua")
include("libraries/urlogg.lua")

function pac.LoadParts()
	local files = file.Find("pac3/core/client/parts/*.lua", "LUA")
	
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

include("owner_name.lua")

include("expression.lua")
include("integration_tools.lua")
include("mat_proxies.lua")

pac.LoadParts()

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
	include("autorun/pac_editor_init.lua")

	if was_open then 
		pace.OpenEditor() 
	end
end

concommand.Add("pac_restart", pac.Restart)

local cvar_enable = CreateClientConVar("pac_enable", "1")

cvars.AddChangeCallback("pac_enable", function(name)
	if GetConVarNumber(name) == 1 then
		pac.Enable()
	else
		pac.Disable()
	end
end)

function pac.Enable()
	-- parts were marked as not drawing, so they will show on the next frame

	-- add all the hooks back
	for event, func in pairs(pac.AddedHooks) do
		pac.AddHook(event, func)
	end
	
	pac.CallHook("Enable")
end

function pac.Disable()
	-- turn off all parts
	for key, ent in pairs(pac.drawn_entities) do
		if ent:IsValid() then
		
			if ent.pac_parts then
				for key, part in pairs(ent.pac_parts) do
					part:CallRecursive("OnHide")
				end
				
				pac.ResetBones(ent)				
			end
			
			ent.pac_drawing = false
			
		else
			pac.drawn_entities[key] = nil
		end
	end
	
	-- disable all hooks
	for event in pairs(pac.AddedHooks) do
		pac.RemoveHook(event)
	end
	
	pac.CallHook("Disable")
end

if GetConVarNumber("pac_enable") == 0 then
	pac.Disable()
end

hook.Add("Think", "pac_localplayer", function()
	local ply = LocalPlayer()
	if ply:IsValid() then
		pac.LocalPlayer = LocalPlayer() 
		
		-- uuumm
		if E2Helper then
			E2Helper.Descriptions["pacSetKeyValue"] = "Sets a property value on given part. Part unique id is recommended but you can also input name."
		end
		
		hook.Remove("Think", "pac_localplayer")
	end
end)

hook.Run("pac_Initialized")