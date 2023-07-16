pac = pac or {}

pac.LocalPlayer = LocalPlayer()
pac.LocalViewModel = pac.LocalPlayer:IsValid() and pac.LocalPlayer:GetViewModel() or NULL
pac.LocalHands = pac.LocalPlayer:IsValid() and pac.LocalPlayer:GetHands() or NULL
do
	local pac_enable = CreateClientConVar("pac_enable", "1", true)

	cvars.AddChangeCallback("pac_enable", function(_, old, new)
		if old == new then return end

		if tobool(new) then
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
include("class.lua")

pac.CompileExpression = include("pac3/libraries/expression.lua")
pac.resource = include("pac3/libraries/resource.lua")
pac.animations = include("pac3/libraries/animations.lua")

include("pac3/core/shared/init.lua")

pac.urltex = include("pac3/libraries/urltex.lua")

include("parts.lua")
include("max_render_time.lua")
include("part_pool.lua")
include("bones.lua")
include("hooks.lua")
include("owner_name.lua")
include("integration_tools.lua")
include("test.lua")
include("ear_grab_animation.lua")

pac.LoadParts()

hook.Add("OnEntityCreated", "pac_init", function(ent)
	local ply = LocalPlayer()
	if not ply:IsValid() then return end

	pac.LocalPlayer = ply
	pac.LocalViewModel = pac.LocalPlayer:GetViewModel()
	pac.LocalHands = pac.LocalPlayer:GetHands()

	pac.in_initialize = true
	hook.Run("pac_Initialized")
	pac.in_initialize = nil

	hook.Remove("OnEntityCreated", "pac_init")
end)
