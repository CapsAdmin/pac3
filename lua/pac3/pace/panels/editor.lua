local PANEL = {}

PANEL.ClassName = "editor"
PANEL.Base = "DFrame"

function PANEL:Init()
	local right = vgui.Create("DHorizontalDivider", self)
		right:Dock(FILL)
	self.right = right

	local left = vgui.Create("DHorizontalDivider", self)
		left:Dock(FILL)
		right:SetLeft(left)
	self.left = left

	self:SetTitle("pac3 editor")
	self:SetSizable(true)

	self:SetRight(pace.CreatePanel("parts"))
	self:SetLeft(pace.CreatePanel("tree"))
	self:SetMiddle(pace.CreatePanel("view"))
end

function PANEL:PerformLayout()
	DFrame.PerformLayout(self)

	self.right:SetLeftWidth(self:GetWide() - 200)
	self.left:SetLeftWidth(180)

end

function PANEL:SetRight(pnl)
	self.right:SetRight(pnl)
end

function PANEL:SetLeft(pnl)
	self.left:SetLeft(pnl)
end

function PANEL:SetMiddle(pnl)
	self.left:SetRight(pnl)
end

pace.RegisterPanel(PANEL)