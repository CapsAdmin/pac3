--[[
	TODO:
		maybe not use matrices for everything?
			difficult to cram everything into matrices sometimes, maybe it's
			best to do it at cache time

		lock mouse to axis?
		figure out a better way to mirror everything

		fix plane origin being off center when rotating
]]


if pac999_models then
	hook.Remove("RenderScene", "pac_999")
	hook.Remove("RenderScene", "pac_999_input")
	hook.Remove("PostDrawOpaqueRenderables", "pac_999")

	for _,v in pairs(pac999_models) do
		SafeRemoveEntity(v)
	end
	pac999_models = nil
end

_G.pac999 = _G.pac999 or {}
local pac999 = _G.pac999

pac999.TEST = true
pac999.DEBUG = false

pac999.Matrix44 = include("matrix44.lua")
pac999.utility = include("utility.lua")
pac999.camera = include("camera.lua")
pac999.input = include("input.lua")
pac999.models = include("models.lua")
pac999.entity = include("entity.lua")


local files = file.Find("pac3/core2/client/components/*.lua", "LUA")
for _, name in pairs(files) do
	include("pac3/core2/client/components/" .. name)
end

pac999.scene = include("scene.lua")

pac999.input.Init()

include("test.lua")