local PANEL = {}

PANEL.ClassName = "editor"
PANEL.Base = "DFrame"

function PANEL:Init()
	self:SetTitle("pac3 editor")
	self:SetSizable(true)
	
	local div = vgui.Create("DVerticalDivider", self)
		div:SetDividerHeight(5)
		div:Dock(FILL)
	self.div = div
	
	self:SetTop(pace.CreatePanel("tree"))
	self:SetBottom(pace.CreatePanel("properties"))
end

function PANEL:PerformLayout()
	DFrame.PerformLayout(self)

	self.div:SetTopHeight(ScrH() - self.bottom:GetHeight() - 30)
	self.div:InvalidateLayout()
end

function PANEL:SetTop(pnl)
	self.top = pnl
	self.div:SetTop(pnl)
end

function PANEL:SetBottom(pnl)
	self.bottom = pnl
	self.div:SetBottom(pnl)
end

local last = 0

function PANEL:Think(...)
	if last < CurTime() and input.IsKeyDown(KEY_LCONTROL) and input.IsKeyDown(KEY_E) then
		if pace.Focused then
			pace.KillFocus()
		else
			pace.GainFocus()
		end
		last = CurTime() + 0.2
	end
	return DFrame.Think(self, ...)
end

pace.Focused = true

function pace.IsFocused()
	return pace.Focused
end

function pace.GainFocus()
	local self = pace.Editor
	if self:IsValid() then
		if self.allowclick ~= false then
			self:MakePopup()
			pace.Focused = true
			self:AlphaTo(255, 0.1, 0)
			self:MoveTo(0, 0, 0.1, 0)
		end
	end
end

function pace.KillFocus()
	local self = pace.Editor
	if self:IsValid() then
		self:KillFocus()
		self:SetMouseInputEnabled(false)
		self:SetKeyBoardInputEnabled(false)
		gui.EnableScreenClicker(false)
		pace.Focused = false
		self:AlphaTo(0, 0.1, 0)
		self:MoveTo(-self:GetWide(), 0, 0.1, 0)
		
		self.allowclick = false

		timer.Simple(0.2, function()
			self.allowclick = true
		end)
	end
end

pace.RegisterPanel(PANEL)