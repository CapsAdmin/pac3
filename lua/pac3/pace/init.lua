include("autorun/pac_init.lua")

pace = pace or {}

include("language.lua")

include("select.lua")
include("view.lua")
include("config.lua")
include("logic.lua")
include("undo.lua")

include("mctrl.lua")
include("screenvec.lua")

include("panels.lua")

pace.ActivePanels = pace.ActivePanels or {}

function pace.OpenEditor()
	local editor = pace.CreatePanel("editor")
		editor:SetSize(220, ScrH())
		editor:Dock(LEFT)
		editor:MakePopup()
		editor.Close = function() pace.Call("CloseEditor") editor:Remove() end
	pace.Editor = editor
	
	pace.Call("OpenEditor")
end

concommand.Add("pac_editor", function()
	pace.Panic()
	----include("autorun/pac_init.lua")
	--include("autorun/pace_init.lua")
	timer.Simple(0.1, function() pace.OpenEditor() end)
end)

function pace.Call(str, ...)
	if pace["On" .. str] then
		pace["On" .. str](...)
	else
		ErrorNoHalt("missing function pace.On" .. str .. "!\n")
	end
end

function pace.Panic()
	for key, pnl in pairs(pace.ActivePanels) do
		if pnl:IsValid() then
			pnl:Remove()
			table.remove(pace.ActivePanels, key)
		end
	end
end

pace.RegisterPanels()