pac = pac or {}

do
	local pac_enable = CreateClientConVar("pac_enable", "1",true)
	local pac_enable_bool = pac_enable:GetBool()

	cvars.AddChangeCallback("pac_enable", function(_, _, new)
		if (tonumber(new) or 0)>=1 then
			pac.Enable()
		else
			pac.Disable()
		end
	end)

	function pac.IsEnabled()
		return pac_enable_bool
	end

	function pac.Enable()
		-- add all the hooks back
		for _, data in pairs(pac.added_hooks) do
			hook.Add(data.event_name, data.id, data.func, data.priority)
		end

		pac.CallHook("Enable")

		pac_enable_bool = true
	end

	function pac.Disable()
		-- turn off all parts
		for ent in next, pac.drawn_entities do
			if ent:IsValid() then
				pac.DisableEntity(ent)
			else
				pac.drawn_entities[ent] = nil
			end
		end

		-- disable all hooks
		for _, data in pairs(pac.added_hooks) do
			hook.Remove(data.event_name, data.id)
		end

		pac.CallHook("Disable")

		pac_enable_bool = false
	end
end

CreateClientConVar("pac_hide_disturbing", "1", true, true, "Hide parts which outfit creators marked as 'nsfw' (e.g. gore or explicit content)")

include("util.lua")

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

pac.animations = include("pac3/libraries/animations.lua")

include("parts.lua")

include("part_pool.lua")

include("bones.lua")
include("hooks.lua")

include("owner_name.lua")

include("integration_tools.lua")
include("test.lua")

pac.LoadParts()

do
	local pac_friendonly = CreateClientConVar("pac_friendonly", 0, true, false, 'Load PACs from friends only')
	local pac_use_whitelist = CreateClientConVar("pac_use_whitelist", 0, true, false, 'Load PACs only from players listed in settings')
	local pac_use_whitelist_b = CreateClientConVar("pac_use_whitelist_b", 0, true, false, 'Whitelist acts as blacklist')

	function pac.FriendOnlyUpdate()
		local lply = LocalPlayer()

		if pac_friendonly:GetBool() then
			for k, v in ipairs(player.GetAll()) do
				if v ~= lply then
					pac.ToggleIgnoreEntity(v, v:GetFriendStatus() ~= "friend", 'pac_friendonly')
				end
			end
		else
			for k, v in ipairs(player.GetAll()) do
				if v ~= lply then
					pac.ToggleIgnoreEntity(v, false, 'pac_friendonly')
				end
			end
		end
	end

	function pac.UseWhitelistUpdates()
		local lply = LocalPlayer()

		if pac_use_whitelist:GetBool() then
			if pac_use_whitelist_b:GetBool() then
				for k, v in ipairs(player.GetAll()) do
					if v ~= lply then
						pac.ToggleIgnoreEntity(v, cookie.GetString('pac3_wear_wl_' .. v:UniqueID(), '0') == '1', 'pac_whitelist')
					end
				end
			else
				for k, v in ipairs(player.GetAll()) do
					if v ~= lply then
						pac.ToggleIgnoreEntity(v, cookie.GetString('pac3_wear_wl_' .. v:UniqueID(), '0') ~= '1', 'pac_whitelist')
					end
				end
			end
		else
			for k, v in ipairs(player.GetAll()) do
				if v ~= lply then
					pac.ToggleIgnoreEntity(v, false, 'pac_whitelist')
				end
			end
		end
	end

	function pac.UseWhitelistUpdatesPerPlayer(ply)
		if pac_use_whitelist:GetBool() then
			if pac_use_whitelist_b:GetBool() then
				pac.ToggleIgnoreEntity(ply, cookie.GetString('pac3_wear_wl_' .. ply:UniqueID(), '0') == '1', 'pac_whitelist')
			else
				pac.ToggleIgnoreEntity(ply, cookie.GetString('pac3_wear_wl_' .. ply:UniqueID(), '0') ~= '1', 'pac_whitelist')
			end
		else
			pac.ToggleIgnoreEntity(ply, false, 'pac_whitelist')
		end
	end

	cvars.AddChangeCallback("pac_friendonly", pac.FriendOnlyUpdate, "PAC3")
	cvars.AddChangeCallback("pac_use_whitelist", pac.UseWhitelistUpdates, "PAC3")
	cvars.AddChangeCallback("pac_use_whitelist_b", pac.UseWhitelistUpdates, "PAC3")

	pac.AddHook("NetworkEntityCreated", "friendonly", function(ply)
		if not IsValid(ply) or not ply:IsPlayer() then return end

		timer.Simple(4, function()
			if not ply:IsValid() then return end

			if pac_friendonly:GetBool() then
				pac.ToggleIgnoreEntity(ply, ply:GetFriendStatus() ~= "friend", 'pac_friendonly')
			else
				pac.ToggleIgnoreEntity(ply, false, 'pac_friendonly')
			end

			pac.UseWhitelistUpdatesPerPlayer(ply)
		end)
	end)

	pac.AddHook("pac_Initialized", "friendonly", pac.FriendOnlyUpdate)
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

timer.Simple(0.1, function()
	hook.Run("pac_Initialized")
end)
