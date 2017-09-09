pac = pac or {}

pac.NULL = include("pac3/libraries/null.lua")
pac.class = include("pac3/libraries/class.lua")

pac.haloex = include("pac3/libraries/haloex.lua")
pac.CompileExpression = include("pac3/libraries/expression.lua")
pac.resource = include("pac3/libraries/resource.lua")

include("pac3/core/shared/init.lua")

pac.urltex = include("pac3/libraries/urltex.lua")

-- Caching
include("pac3/libraries/caching/crypto.lua")
include("pac3/libraries/caching/cache.lua")

-- "urlobj"
include("pac3/libraries/urlobj/urlobj.lua")
include("pac3/libraries/urlobj/queueitem.lua")

-- WebAudio
include("pac3/libraries/webaudio/urlogg.lua")
include("pac3/libraries/webaudio/browser.lua")
include("pac3/libraries/webaudio/stream.lua")
include("pac3/libraries/webaudio/streams.lua")

include("pac3/libraries/boneanimlib.lua")

include("util.lua")
include("parts.lua")

include("bones.lua")
include("hooks.lua")
include("drawing.lua")

include("owner_name.lua")

include("integration_tools.lua")

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
				for _, part in pairs(ent.pac_parts) do
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
	cvars.AddChangeCallback("pac_enable", function(_, _, new)
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

	local pac_friendonly = CreateClientConVar("pac_friendonly", 0, true)

	function pac.FriendOnlyUpdate()
		local lply = LocalPlayer()
		for k, v in pairs(player.GetAll()) do
			if v ~= lply then
				pac.ToggleIgnoreEntity(v, v:GetFriendStatus() ~= "friend", 'pac_friendonly')
			end
		end
	end

	cvars.AddChangeCallback("pac_friendonly", pac.FriendOnlyUpdate)

	hook.Add("NetworkEntityCreated", "pac_friendonly", function(ply)
		if not IsValid(ply) or not ply:IsPlayer() then return end
		timer.Simple(0, function()
			if pac_friendonly:GetBool() and ply:GetFriendStatus() ~= "friend" then
				pac.IgnoreEntity(ply)
				ply.pac_friendonly = true
			end
		end)
	end)
	hook.Add("pac_Initialized", "pac_friendonly", pac.FriendOnlyUpdate)

end

hook.Add("Think", "pac_localplayer", function()
	local ply = LocalPlayer()
	if ply:IsValid() then
		pac.LocalPlayer = ply
		hook.Remove("Think", "pac_localplayer")
	end
end)

do
	local NULL = NULL

	local function BIND_MATPROXY(NAME, TYPE)

		local set = "Set" .. TYPE

		matproxy.Add(
			{
				name = NAME,

				init = function(self, mat, values)
					self.result = values.resultvar
				end,

				bind = function(self, mat, ent)
					ent = ent or NULL
					if ent:IsValid() then
						if ent.pac_matproxies and ent.pac_matproxies[NAME] then
							mat[set](mat, self.result, ent.pac_matproxies[NAME])
						end
					end
				end
			}
		)

	end

	-- tf2
	BIND_MATPROXY("ItemTintColor", "Vector")
end

net.Receive("pac.TogglePartDrawing", function()
	local ent = net.ReadEntity()
	if ent:IsValid() then
		local b = (net.ReadBit() == 1)
		pac.TogglePartDrawing(ent, b)
	end
end )

function pac.TouchFlexes(ent)
	local index = ent:EntIndex()
	if index == -1 then return end
	net.Start("pac.TouchFlexes.ClientNotify")
	net.WriteInt(index,13)
	net.SendToServer()
end

timer.Simple(0.1, function()
	hook.Run("pac_Initialized")
end)