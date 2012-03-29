include("autorun/pac_init.lua")

pace = pace or {}

include("config.lua")
include("logic.lua")
include("undo.lua")

include("mctrl.lua")
include("screenvec.lua")
include("language.lua")

include("panels.lua")

pace.ActivePanels = pace.ActivePanels or {}

function pace.OpenEditor()
	local editor = pace.CreatePanel("editor")
	editor:SetSize(ScrW() * 0.64, ScrH() * 0.8)
	editor:MakePopup()
	pace.Editor = editor
end

function pace.Call(str, ...)
	if pace["On" .. str] then
		pace["On" .. str](...)
	else
		ErrorNoHalt("missing function pace.On" .. str .. "!\n")
	end
end

pace.RegisterPanels()

pace.Panic()

pace.OpenEditor()
pace.SetViewOutfit(outfit)