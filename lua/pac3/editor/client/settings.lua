
local PANEL = {}

function PANEL:Init()
	local pnl = vgui.Create("DPropertySheet", self)
	pnl:Dock(FILL)

	local properties_filter = pace.FillWearSettings(pnl)
	
	pnl:AddSheet("Wear / Ignore", properties_filter)
	self.sheet = pnl
	
	--local properties_shortcuts = pace.FillShortcutSettings(pnl)
	--pnl:AddSheet("Editor Shortcuts", properties_shortcuts)
end

vgui.Register( "pace_settings", PANEL, "DPanel" )

function pace.OpenSettings()
	if IsValid(pace.settings_panel) then
		pace.settings_panel:Remove()
	end
	local pnl = vgui.Create("DFrame")
	pnl:SetTitle("pac settings")
	pace.settings_panel = pnl
	pnl:SetSize(600,600)
	pnl:MakePopup()
	pnl:Center()
	pnl:SetSizable(true)

	local pnl = vgui.Create("pace_settings", pnl)
	pnl:Dock(FILL)
end

concommand.Add("pace_settings", function()
	pace.OpenSettings()
end)