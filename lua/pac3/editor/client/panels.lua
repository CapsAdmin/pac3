pace.RegisteredPanels = {}

function pace.RegisterPanel(PANEL)
	pace.RegisteredPanels[PANEL.ClassName] = PANEL
	vgui.Register("pace_" .. PANEL.ClassName, PANEL, PANEL.Base)
end

function pace.PanelExists(class_name)
	return pace.GetRegisteredPanel(class_name) ~= nil
end

function pace.GetRegisteredPanel(class_name)
	return pace.RegisteredPanels[class_name]
end

function pace.CreatePanel(class_name, parent)
	local pnl = vgui.Create("pace_" .. class_name, parent)
	table.insert(pace.ActivePanels, pnl)
	return pnl
end

function pace.RegisterPanels()
	local files

	if file.FindInLua then
		files = file.FindInLua("pac3/editor/client/panels/*.lua")
	else
		files = file.Find("pac3/editor/client/panels/*.lua", "LUA")
	end

	for _, name in pairs(files) do
		include("pac3/editor/client/panels/" .. name)
	end
end