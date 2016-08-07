pac = pac or {}

include("libraries/null.lua")
include("libraries/class.lua")
include("libraries/luadata.lua")
include("libraries/haloex.lua")
include("libraries/expression.lua")

include("pac3/core/shared/init.lua")

include("libraries/urltex.lua")

-- Caching
include("libraries/caching/crypto.lua")
include("libraries/caching/cache.lua")

-- "urlobj"
include("libraries/urlobj/urlobj.lua")
include("libraries/urlobj/queueitem.lua")

-- WebAudio
include("libraries/webaudio/urlogg.lua")
include("libraries/webaudio/browser.lua")
include("libraries/webaudio/stream.lua")
include("libraries/webaudio/streams.lua")

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

include("net_messages.lua")

pac.LoadParts()

function pac.Enable()
	-- parts were marked as not drawing, so they will show on the next frame

	-- add all the hooks back
	for event, data in pairs(pac.added_hooks) do
		pac.AddHook(event, data.func)
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
	for event in pairs(pac.added_hooks) do
		pac.RemoveHook(event)
	end

	pac.CallHook("Disable")
end

do
	local pac_enable = CreateClientConVar("pac_enable", "1",true)
	local pac_enable_bool = pac_enable:GetBool()
	cvars.AddChangeCallback("pac_enable", function(name,old,new)
		if (tonumber(new) or 0)>=1 then
			pac_enable_bool=true
			pac.Enable()
		else
			pac_enable_bool=false
			pac.Disable()
		end
	end)

	function pac.IsEnabled()
		return pac_enable_bool
	end

	if pac_enable:GetInt() == 0 then
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

timer.Simple(0.1, function()
	hook.Run("pac_Initialized")
end)