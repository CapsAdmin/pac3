local PANEL = {}

PANEL.ClassName = "sheet"
PANEL.Base = "DPropertySheet"

function PANEL:Init()
	local prt = self:AddSheet("parts", pace.CreatePanel("parts"))
	local prp = self:AddSheet("properties", pace.CreatePanel("properties"))
end

pace.RegisterPanel(PANEL)