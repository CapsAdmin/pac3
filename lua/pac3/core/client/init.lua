pac = pac or {}

do
	local pac_enable = CreateClientConVar("pac_enable", "1", true)

	cvars.AddChangeCallback("pac_enable", function(_, _, value)
		value = tobool(value) or 0
		if value then
			pac.Enable()
		else
			pac.Disable()
		end
	end)

	function pac.IsEnabled()
		return pac_enable:GetBool()
	end

	function pac.Enable()
		pac.EnableDrawnEntities(true)
		pac.EnableAddedHooks()
		pac.CallHook("Enable")
		pac_enable:SetBool(true)
	end

	function pac.Disable()
		pac.EnableDrawnEntities(false)
		pac.DisableAddedHooks()
		pac.CallHook("Disable")
		pac_enable:SetBool(false)
	end
end

include("util.lua")

pac.NULL = include("pac3/libraries/null.lua")
pac.class = include("pac3/libraries/class.lua")
pac.CompileExpression = include("pac3/libraries/expression.lua")
pac.resource = include("pac3/libraries/resource.lua")
pac.animations = include("pac3/libraries/animations.lua")

include("pac3/core/shared/init.lua")

pac.urltex = include("pac3/libraries/urltex.lua")

include("parts.lua")
include("part_pool.lua")
include("bones.lua")
include("hooks.lua")
include("owner_name.lua")
include("friends_only.lua")
include("integration_tools.lua")

pac.LoadParts()

net.Receive("pac.TogglePartDrawing", function()
	local ent = net.ReadEntity()
	if ent:IsValid() then
		local b = (net.ReadBit() == 1)
		pac.TogglePartDrawing(ent, b)
	end
end)

hook.Add("Think", "pac_init", function()
	local ply = LocalPlayer()
	if not ply:IsValid() then return end

	pac.LocalPlayer = ply
	hook.Run("pac_Initialized")

	hook.Remove("Think", "pac_init")
end)
