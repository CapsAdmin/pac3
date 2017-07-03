local L = pace.LanguageString

local PANEL = {}

PANEL.ClassName = "editor"
PANEL.Base = "DFrame"
PANEL.menu_bar = NULL

PANEL.pac3_PanelsToRemove = {
	'btnClose', 'btnMaxim', 'btnMinim'
}

local BAR_SIZE = 17
local RENDERSCORE_SIZE = 13

local use_tabs = CreateClientConVar("pac_property_tabs", 1, true)

function PANEL:Init()
	self:SetTitle("")
	self:SetSizable(true)
	--self:DockPadding(2, 23, 2, 2)

	surface.SetFont(pace.CurrentFont)
	local _, h = surface.GetTextSize("|")
	RENDERSCORE_SIZE = h+1

	local div = vgui.Create("DVerticalDivider", self)
		div:SetDividerHeight(RENDERSCORE_SIZE)
		div:Dock(FILL)
		div:SetTopMin(0)
		div:SetCookieName("pac3_editor")
		div:SetTopHeight(ScrH()/1.4)
		div:LoadCookies()
	self.div = div

	self:SetTop(pace.CreatePanel("tree"))

	local pnl = pace.CreatePanel("properties", div)
	pace.properties = pnl

	self:SetBottom(pnl)

	self:SetCookieName("pac3_editor")
	self:SetPos(self:GetCookieNumber("x"), BAR_SIZE)

	self:MakeBar()
end

function PANEL:OnMousePressed()
	if self.m_bSizable && gui.MouseX() > ( self.x + self:GetWide() - 20 ) then
		self.Sizing = { gui.MouseX() - self:GetWide(), gui.MouseY() - self:GetTall() }
		self:MouseCapture( true )
		return
	end

	if ( self:GetDraggable() && gui.MouseY() < (self.y + 24) ) then
		self.Dragging = { gui.MouseX() - self.x, gui.MouseY() - self.y }
		self:MouseCapture( true )
		return
	end
end

function PANEL:OnMouseReleased(mc)
	if mc==MOUSE_RIGHT then
		self:Close()
	end

	self.BaseClass.OnMouseReleased(self,mc)

end

function PANEL:MakeBar()
	if self.menu_bar:IsValid() then self.menu_bar:Remove() end

	local bar = vgui.Create("DMenuBar", self)
	bar:SetSize(self:GetWide(), BAR_SIZE)
	pace.Call("MenuBarPopulate", bar)
	pace.MenuBar = bar

	self.menu_bar = bar

	self:DockMargin(2,2,2,2)
	self:DockPadding(2,2,2,2)
end

function PANEL:OnRemove()
	if self.menu_bar:IsValid() then
		self.menu_bar:Remove()
	end
end

function PANEL:Think(...)
	DFrame.Think(self, ...)

	if self.Hovered && self.m_bSizable && gui.MouseX() > ( self.x + self:GetWide() - 20 ) then
		self:SetCursor("sizewe")
		return
	end

	local bar = self.menu_bar

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

local auto_size = CreateClientConVar("pac_auto_size_properties", 1, true)

function PANEL:PerformLayout()
	DFrame.PerformLayout(self)

	for i, val in pairs(self.pac3_PanelsToRemove) do
		if IsValid(self[val]) then
			self[val].SetSize(self[val], 0, 0) -- Hacky
		end
	end

	self.div:InvalidateLayout()
	self.bottom:PerformLayout()
	pace.properties:PerformLayout()
	local sz = auto_size:GetInt()
	local newh = sz >0 and 	(
								ScrH() - math.min(pace.properties:GetHeight() + RENDERSCORE_SIZE + BAR_SIZE - 6, ScrH() / 1.5)
							)
	if sz >= 2 then
		local oldh = self.div:GetTopHeight()
		if newh<oldh then
			self.div:SetTopHeight(newh)
		end
	elseif sz >= 1 then
		self.div:SetTopHeight(newh)
	end
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

function pace.GainFocus(show_editor)
	local self = pace.Editor
	if self:IsValid() then
		if self.allowclick ~= false then
			self:MakePopup()
			pace.Focused = true
			if not show_editor then
				self:AlphaTo(255, 0.1, 0)
			end
		end
	end
end

function pace.KillFocus(show_editor)
	local self = pace.Editor
	if self:IsValid() then
		self:KillFocus()
		self:SetMouseInputEnabled(false)
		self:SetKeyBoardInputEnabled(false)
		gui.EnableScreenClicker(false)
		pace.Focused = false

		if not show_editor then
			self:AlphaTo(0, 0.1, 0)
		end

		self.allowclick = false

		timer.Simple(0.2, function()
			if self:IsValid() then
				self.allowclick = true
			end
		end)
	end
end

function PANEL:PaintOver(w, h)
	local renderTime = pace.RenderTimes and pace.RenderTimes[LocalPlayer():EntIndex()]

	if renderTime then
		--local x, y = self.top:LocalToScreen()
		local x = 2
		local y = 2
		y = y + self.menu_bar:GetTall()
		y = y + self.top:GetTall()

		surface.SetFont(pace.CurrentFont)
		local str = string.format("%s: %.3f ms", L("average render time"), renderTime * 1000)
		local _w, _h = surface.GetTextSize(str)

		cam.IgnoreZ(true)
		--surface.SetDrawColor(255, 255, 255, 255)
		self:GetSkin().tex.Panels.Bright(x,y,w-5, RENDERSCORE_SIZE-1)

		surface.SetTextColor(self:GetSkin().Colours.Tree.Normal)
		surface.SetTextPos(x+5, y)
		surface.DrawText(str)
		cam.IgnoreZ(false)
	end
end

pace.RegisterPanel(PANEL)