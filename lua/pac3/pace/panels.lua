pace.RegisteredPanels = {}

function pace.RegisterPanel(PANEL)
	pace.RegisteredPanels[PANEL.ClassName] = PANEL
	vgui.Register("pace_" .. PANEL.ClassName, PANEL, PANEL.Base)
end

function pace.PanelExists(class_name)
	return pace.RegisteredPanels[class_name] ~= nil
end

function pace.CreatePanel(class_name, parent)
	local pnl = vgui.Create("pace_" .. class_name, parent)
	table.insert(pace.ActivePanels, pnl)
	return pnl
end

function pace.RegisterPanels()
	for _, name in pairs(file.FindInLua("pac3/pace/panels/*.lua")) do
		include("pac3/pace/panels/" .. name)
	end
end

function pace.Panic()
	for key, pnl in ipairs(pace.ActivePanels) do
		if pnl:IsValid() then
			pnl:Remove()
			table.remove(pace.ActivePanels, key)
		end
	end
end