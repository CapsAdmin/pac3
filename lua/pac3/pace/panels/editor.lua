local L = pace.LanguageString

local PANEL = {}

PANEL.ClassName = "editor"
PANEL.Base = "DFrame"

function PANEL:Init()	
	self:SetTitle("pac3 " .. L"editor")
	self:SetSizable(true)
	--self:DockPadding(2, 23, 2, 2)
	
	local div = vgui.Create("DVerticalDivider", self)
		div:SetDividerHeight(2)
		div:Dock(FILL)
		div:SetTopMin(0)
	self.div = div
	
	self:SetTop(pace.CreatePanel("tree"))
	local pnl = pace.CreatePanel("properties")
	pace.properties = pnl
	self:SetBottom(pnl)
	
	self:SetCookieName("pac3_editor")
	self:SetPos(self:GetCookieNumber("x"), 0)
end

function PANEL:Think(...)
	DFrame.Think(self, ...)
	
	self:SetTall(ScrH())
	local w = math.max(self:GetWide(), 200)
	self:SetWide(w)
	local x = self:GetPos()
	x = math.Clamp(x, 0, ScrW()-w)
	self:SetPos(x, 0)
		
	if x ~= self.last_x then
		self:SetCookie("x", x)
		self.last_x = x
	end
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
			self:MoveTo(self:GetCookieNumber("x") or 0, self:GetCookieNumber("y") or 0, 0.1, 0)
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
		
		self.allowclick = false

		timer.Simple(0.2, function()
			self.allowclick = true
		end)
	end
end

pace.RegisterPanel(PANEL)