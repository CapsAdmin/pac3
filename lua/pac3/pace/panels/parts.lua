local PANEL = {}

PANEL.ClassName = "parts"
PANEL.Base = "DVerticalDivider"

function PANEL:Init()
	DVerticalDivider.Init(self)

	local new = pace.CreatePanel("new", self)
		new:SizeToContents()
		self:SetTopHeight(new:GetTall())
	self:SetTop(new)

	self:SetBottom(pace.CreatePanel("properties", self))
end

pace.RegisterPanel(PANEL)