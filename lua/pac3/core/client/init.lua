pac = pac or {}

include("libraries/null.lua")
include("libraries/class.lua")
include("libraries/luadata.lua")
include("libraries/haloex.lua")
include("libraries/expression.lua")

include("pac3/core/shared/init.lua")

include("libraries/urltex.lua")
include("libraries/urlobj.lua")
include("libraries/urlogg.lua")

include("libraries/boneanimlib.lua")

include("util.lua")
include("parts.lua")

include("bones.lua")
include("hooks.lua")
include("drawing.lua")

include("owner_name.lua")

include("integration_tools.lua")
include("mat_proxies.lua")
include("wire_expression_extension.lua")

pac.LoadParts()

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

do
	local cvar_enable = CreateClientConVar("pac_enable", "1")

	cvars.AddChangeCallback("pac_enable", function(name)
		if GetConVarNumber(name) == 1 then
			pac.Enable()
		else
			pac.Disable()
		end
	end)

	function pac.IsEnabled()
		return cvar_enable:GetInt() >= 1
	end

	if cvar_enable:GetInt() == 0 then
		pac.Disable()
	end

end

hook.Add("Think", "pac_localplayer", function()
	local ply = LocalPlayer()
	if ply:IsValid() then
		pac.LocalPlayer = ply		
		hook.Remove("Think", "pac_localplayer")
	end
end)

hook.Run("pac_Initialized")