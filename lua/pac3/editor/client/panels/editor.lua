local L = pace.LanguageString

local PANEL = {}

PANEL.ClassName = "editor"
PANEL.Base = "DFrame"
PANEL.menu_bar = NULL

PANEL.pac3_PanelsToRemove = {
	'btnMaxim', 'btnMinim'
}

local BAR_SIZE = 17
local RENDERSCORE_SIZE = 20

local use_tabs = CreateClientConVar("pac_property_tabs", 1, true)

local zoom_persistent = CreateClientConVar("pac_zoom_persistent", 0, true, false, 'Keep zoom between sessions.')
local zoom_mousewheel = CreateClientConVar("pac_zoom_mousewheel", 0, true, false, 'Enable zooming with mouse wheel.')
local zoom_smooth = CreateClientConVar("pac_zoom_smooth", 0, true, false, 'Enable smooth zooming.')

function PANEL:Init()
	self:SetTitle("")
	self:SetSizable(true)
	--self:DockPadding(2, 23, 2, 2)

	surface.SetFont(pace.CurrentFont)
	local _, h = surface.GetTextSize("|")
	RENDERSCORE_SIZE = h + 1

	local div = vgui.Create("DVerticalDivider", self)

	div:SetDividerHeight(RENDERSCORE_SIZE)
	div:Dock(FILL)
	div:SetTopMin(40)
	div:SetBottomMin(40)
	div:SetCookieName("pac3_editor")
	div:SetTopHeight(ScrH() / 1.4)
	div:LoadCookies()

	self.div = div

	self.treePanel = pace.CreatePanel("tree")
	self:SetTop(self.treePanel)

	local pnl = pace.CreatePanel("properties", div)
	pace.properties = pnl

	self.exit_button = vgui.Create("DButton")
	self.exit_button:SetText("")
	self.exit_button.DoClick = function() self:Close() end
	self.exit_button.Paint = function(self, w, h) derma.SkinHook("Paint", "WindowCloseButton", self, w, h) end
	self.exit_button:SetSize(31, 26)

	self.zoomframe = vgui.Create( "DPanel" )
	self.zoomframe:SetSize( 180, 150 )

		self.zoomsettings = vgui.Create("DPanel", self.zoomframe)
		self.zoomsettings:Dock(TOP)
		self.zoomsettings:DockPadding(4,0,4,4)

		local SETTING_MARGIN_TOP = 6
			self.persistcheckbox = vgui.Create("DCheckBoxLabel", self.zoomsettings)
			self.persistcheckbox:SetText("Persistent camera FOV")
			self.persistcheckbox:Dock(TOP)
			self.persistcheckbox:SetDark(true)
			self.persistcheckbox:DockMargin(0,SETTING_MARGIN_TOP,0,0)
			self.persistcheckbox:SetConVar("pac_zoom_persistent")

			self.persistlabel = vgui.Create("DLabel", self.zoomsettings)
			self.persistlabel:Dock(TOP)
			self.persistlabel:SetDark(true)
			self.persistlabel:SetText("Keep the zoom when reopening the editor.")
			self.persistlabel:SetWrap(true)
			self.persistlabel:SetAutoStretchVertical(true)

			self.mwheelcheckbox = vgui.Create("DCheckBoxLabel", self.zoomsettings)
			self.mwheelcheckbox:SetText("Enable mouse wheel")
			self.mwheelcheckbox:Dock(TOP)
			self.mwheelcheckbox:SetDark(true)
			self.mwheelcheckbox:DockMargin(0,SETTING_MARGIN_TOP,0,0)
			self.mwheelcheckbox:SetConVar("pac_zoom_mousewheel")

			self.mwheellabel = vgui.Create("DLabel", self.zoomsettings)
			self.mwheellabel:Dock(TOP)
			self.mwheellabel:SetDark(true)
			self.mwheellabel:SetText("Enable zooming with mouse wheel.\n+CTRL: Precise\n+SHIFT: Fast")
			self.mwheellabel:SetWrap(true)
			self.mwheellabel:SetAutoStretchVertical(true)

			self.smoothcheckbox = vgui.Create("DCheckBoxLabel", self.zoomsettings)
			self.smoothcheckbox:SetText("Smooth zooming")
			self.smoothcheckbox:Dock(TOP)
			self.smoothcheckbox:SetDark(true)
			self.smoothcheckbox:DockMargin(0,SETTING_MARGIN_TOP,0,0)
			self.smoothcheckbox:SetConVar("pac_zoom_smooth")

			self.smoothlabel = vgui.Create("DLabel", self.zoomsettings)
			self.smoothlabel:Dock(TOP)
			self.smoothlabel:SetDark(true)
			self.smoothlabel:SetText("Enable smooth zooming.")
			self.smoothlabel:SetWrap(true)
			self.smoothlabel:SetAutoStretchVertical(true)
			
		self.sliderpanel = vgui.Create("DPanel", self.zoomframe)
		self.sliderpanel:SetSize(180, 20)
		self.sliderpanel:Dock(TOP)

			self.zoomslider = vgui.Create("DNumSlider", self.sliderpanel)
			self.zoomslider:DockPadding(4,0,0,0)
			self.zoomslider:SetSize(200, 20)
			self.zoomslider:SetMin( 0 )				
			self.zoomslider:SetMax( 100 )				
			self.zoomslider:SetDecimals( 0 )	
			self.zoomslider:SetText("Camera FOV")
			self.zoomslider:SetDark(true)
			self.zoomslider:SetDefaultValue( 75 )

			if zoom_persistent:GetInt() == 1 then
				self.zoomslider:SetValue( pace.ViewFOV )
			else
				self.zoomslider:SetValue( 75 )
			end

	self.btnClose.Paint = function() end

	self:SetBottom(pnl)

	self:SetCookieName("pac3_editor")
	self:SetPos(self:GetCookieNumber("x"), BAR_SIZE)

	self:MakeBar()
	self.lastTopBarHover = 0

	self.okay = true
end

function PANEL:OnMousePressed()
	if self.m_bSizable and gui.MouseX() > ( self.x + self:GetWide() - 20 ) then
		self.Sizing = { gui.MouseX() - self:GetWide(), gui.MouseY() - self:GetTall() }
		self:MouseCapture( true )
		return
	end

	if self:GetDraggable() and gui.MouseY() < (self.y + 24) then
		self.Dragging = { gui.MouseX() - self.x, gui.MouseY() - self.y }
		self:MouseCapture( true )
		return
	end
end

function PANEL:OnMouseReleased(mc)
	if mc == MOUSE_RIGHT then
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

	self:DockMargin(2, 2, 2, 2)
	self:DockPadding(2, 2, 2, 2)
end

function PANEL:OnRemove()
	if self.menu_bar:IsValid() then
		self.menu_bar:Remove()
	end

	if self.exit_button:IsValid() then
		self.exit_button:Remove()
	end

	if self.zoomframe:IsValid() then
		self.zoomframe:Remove()
	end
end

function PANEL:Think(...)
	if not self.okay then return end
	DFrame.Think(self, ...)

	if self.Hovered and self.m_bSizable and gui.MouseX() > (self.x + self:GetWide() - 20) then
		self:SetCursor("sizewe")
		return
	end

	local bar = self.menu_bar

	self:SetTall(ScrH())
	local w = math.max(self:GetWide(), 200)
	self:SetWide(w)
	self:SetPos(math.Clamp(self:GetPos(), 0, ScrW() - w), 0)

	if x ~= self.last_x then
		self:SetCookie("x", x)
		self.last_x = x
	end

	if self.exit_button:IsValid() then

		if self:GetPos() + self:GetWide() / 2 < ScrW() / 2 then
			self.exit_button:SetPos(ScrW() - self.exit_button:GetWide() + 4, -4)
		else
			self.exit_button:SetPos(-4, -4)
		end
	end

	if self.zoomframe:IsValid() then

		self.zoomsettings:InvalidateLayout( true )
		self.zoomsettings:SizeToChildren( false, true )
		
		self.zoomframe:InvalidateLayout( true )
		self.zoomframe:SizeToChildren( false, true )

		if self:GetPos() + self:GetWide() / 2 < ScrW() / 2 then
			self.zoomframe:SetPos(ScrW() - self.zoomframe:GetWide(), ScrH() - self.zoomframe:GetTall())

		else
			self.zoomframe:SetPos(0,ScrH() - self.zoomframe:GetTall())
		end

		local x, y = self.zoomframe:GetPos()

		if pace.timeline.IsActive() then
			self.zoomframe:SetPos(x,y-pace.timeline.frame:GetTall())
		end

		if zoom_smooth:GetInt() == 1 then
			pace.SetZoom(self.zoomslider:GetValue(),true)
		else
			pace.SetZoom(self.zoomslider:GetValue(),false)
		end

		local mx, my = gui.MousePos()
		local x, y = self.zoomframe:GetPos()
		local xs, xy = self.zoomframe:GetSize()

		if mx > x and my > y and mx < x + xs and my < y + xy then
			self.zoomsettings:SetVisible(true)
			self.zoomsettings:RequestFocus()
		else
			self.zoomsettings:SetVisible(false)
		end
	end
end

local auto_size = CreateClientConVar("pac_auto_size_properties", 1, true)

function PANEL:PerformLayout()
	if not self.okay then return end

	DFrame.PerformLayout(self)

	for i, val in pairs(self.pac3_PanelsToRemove) do
		if IsValid(self[val]) then
			self[val].SetSize(self[val], 0, 0) -- Hacky
		end
	end

	if self.old_part ~= pace.current_part then
		self.div:InvalidateLayout()
		self.bottom:PerformLayout()
		pace.properties:PerformLayout()
		self.old_part = pace.current_part

		local sz = auto_size:GetInt()

		if sz > 0 then
			local newh = sz > 0 and (ScrH() - math.min(pace.properties:GetHeight() + RENDERSCORE_SIZE + BAR_SIZE - 6, ScrH() / 1.5))

			if sz >= 2 then
				local oldh = self.div:GetTopHeight()

				if newh<oldh then
					self.div:SetTopHeight(newh)
				end
			elseif sz >= 1 then
				self.div:SetTopHeight(newh)
			end
		end
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
				self.exit_button:AlphaTo(255, 0.1, 0)
				self.zoomframe:AlphaTo(255, 0.1, 0)
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
			self.exit_button:AlphaTo(0, 0.1, 0)
			self.zoomframe:AlphaTo(0, 0.1, 0)
		end

		self.allowclick = false

		timer.Simple(0.2, function()
			if self:IsValid() then
				self.allowclick = true
			end
		end)
	end
end

local drawProfileInfos = 0
local textCol, drawBox
local boxW, boxH

local function drawTimeBox(text, time, x, y)
	local str = string.format("%s: %.3f ms", L(text), time)
	drawBox(x, y, boxW - 5, RENDERSCORE_SIZE - 1)

	surface.SetTextPos(x + 5, y)
	surface.DrawText(str)
	return y + RENDERSCORE_SIZE
end

local function PostRenderVGUI()
	if drawProfileInfos ~= FrameNumber() then return end
	local x, y = gui.MousePos()
	x = x + 3
	y = y + 3

	surface.SetFont(pace.CurrentFont)

	local part = pace.current_part
	surface.SetTextColor(textCol)

	if not IsValid(part) then return end
	local selfTime = part.selfDrawTime
	local selfTimeB = part.BuildBonePositionsRuntime
	local selfTimeT = part.CThinkRuntime
	local childTimeO = part.childrenOpaqueDrawTime or 0
	local childTimeTD = part.childrenTranslucentDrawTime or 0
	local childTimeB = part.BuildBonePositionsRuntimeChildren or 0
	local childTimeT = part.CThinkRuntimeChildren or 0
	local childTime = childTimeO + childTimeT + childTimeB + childTimeTD

	part.childEditorAverageTime = Lerp(0.03, part.childEditorAverageTime or 0, childTime)
	y = drawTimeBox("overall children render time", part.childEditorAverageTime * 1000, x, y)

	if selfTime or selfTimeB or selfTimeT then
		local selfTime2 = (selfTime or 0) + (selfTimeB or 0) + (selfTimeT + 0)
		part.selfEditorAverageTime = Lerp(0.03, part.selfEditorAverageTime or 0, selfTime2)
		y = drawTimeBox("overall part render time", part.selfEditorAverageTime * 1000, x, y)
	end

	if selfTime then
		part.selfEditorAverageTimeR = Lerp(0.03, part.selfEditorAverageTimeR or 0, selfTime)
		y = drawTimeBox("part draw time", part.selfEditorAverageTimeR * 1000, x, y)
	end

	if selfTimeT then
		part.selfEditorAverageTimeT = Lerp(0.03, part.selfEditorAverageTimeT or 0, selfTimeT)
		y = drawTimeBox("part think time", part.selfEditorAverageTimeT * 1000, x, y)
	end

	if selfTimeB then
		part.selfEditorAverageTimeB = Lerp(0.03, part.selfEditorAverageTimeB or 0, selfTimeB)
		y = drawTimeBox("part bones time", part.selfEditorAverageTimeB * 1000, x, y)
	end

	part.childEditorAverageTimeTD = Lerp(0.03, part.childEditorAverageTimeTD or 0, childTimeTD + childTimeO)
	y = drawTimeBox("overall children draw time", part.childEditorAverageTimeTD * 1000, x, y)

	part.childEditorAverageTimeT = Lerp(0.03, part.childEditorAverageTimeT or 0, childTimeT)
	y = drawTimeBox("overall children think time", part.childEditorAverageTimeT * 1000, x, y)

	part.childEditorAverageTimeB = Lerp(0.03, part.childEditorAverageTimeB or 0, childTimeB)
	y = drawTimeBox("overall children bones time", part.childEditorAverageTimeB * 1000, x, y)
end

function PANEL:PaintOver(w, h)
	if not self.okay then return end

	local renderTime = pace.RenderTimes and pace.RenderTimes[LocalPlayer():EntIndex()]

	if not renderTime then return end

	local x = 2
	local y = 2
	y = y + self.menu_bar:GetTall()
	y = y + self.top:GetTall()
	boxW, boxH = w, h

	local mx, my = gui.MousePos()
	local cx, cy = self:LocalToScreen(x, y)

	if cx <= mx and cy <= my and mx <= cx + w - 5 and my <= cy + RENDERSCORE_SIZE - 1 and self:IsChildHovered() then
		drawProfileInfos = FrameNumber()
	end

	surface.SetFont(pace.CurrentFont)

	textCol = self:GetSkin().Colours.Category.Line.Text
	drawBox = self:GetSkin().tex.Menu_Strip
	surface.SetTextColor(textCol)
	cam.IgnoreZ(true)
	local str = string.format("%s: %.3f ms", L("average render time"), renderTime * 1000)
	drawBox(x, y, w - 5, RENDERSCORE_SIZE - 1)

	surface.SetTextPos(x + 5, y)
	surface.DrawText(str)
	cam.IgnoreZ(false)
end

function PANEL:Paint(w,h)
	if not self.okay then return end


	--surface.SetDrawColor(0, 0, 0, 255)
	--surface.DrawRect(0,0,w,h)
	-- there are some skins that have a transparent dframe
	-- so the categories that the properties draw will be transparent

	self:GetSkin().tex.Tab_Control( 0, 0, w, h )

	--DFrame.Paint(self, w,h)
end

pace.RegisterPanel(PANEL)

pac.AddHook('PostRenderVGUI', 'pac_DrawProfileInfos', PostRenderVGUI)
