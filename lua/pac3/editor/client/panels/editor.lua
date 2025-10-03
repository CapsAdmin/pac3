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
local pins = CreateClientConVar("pac_editor_pins", 1, true)
local pins_button = CreateClientConVar("pac_editor_pins_show_button", 1, true)

local zoom_persistent = CreateClientConVar("pac_zoom_persistent", 0, true, false, 'Keep zoom between sessions.')
local zoom_mousewheel = CreateClientConVar("pac_zoom_mousewheel", 0, true, false, 'Enable zooming with mouse wheel.')
local zoom_smooth = CreateClientConVar("pac_zoom_smooth", 0, true, false, 'Enable smooth zooming.')

local remember_divider = CreateConVar("pac_editor_remember_divider_height", "0", {FCVAR_ARCHIVE}, "Remember PAC3 editor's vertical divider position")
local remember_width = CreateConVar("pac_editor_remember_width", "0", {FCVAR_ARCHIVE}, "Remember PAC3 editor's width")

function pace.RefreshZoomBounds(zoomslider)
	if not IsValid(zoomslider) then return end
	if pace.Editor then
		if not zoomslider then
			zoomslider = pace.Editor.zoomslider
		end
		if pace.camera_orthographic then
			zoomslider:SetMin(-10000)
			zoomslider:SetMax(10000)
		else
			zoomslider:SetMin(0)
			zoomslider:SetMax(pace.max_fov)
			timer.Simple(0, function() zoomslider:SetValue(math.Clamp(pace.ViewFOV, 0, pace.max_fov)) end)
		end
	end
end

local function resize_properties(self)
	local w = self:GetWide()
	surface.SetFont(pace.CurrentFont)
	local _,h = surface.GetTextSize("|")
	local baseline = self.properties2.line_heights or 125
	local total_h = ScrH() - self.div:GetTopHeight()
	self.props_shared_pnl:SetSize(w, total_h)
	if pins:GetBool() then
		local baseline = self.properties2.line_heights or 125
		baseline = baseline + self.font_h

		self.properties_pnl_holder:SetPos(0,baseline + h)
		self.properties2_pnl_holder:SetPos(0,self.font_h)
	
		self.properties_pnl_holder:SetSize(w - 4, total_h - baseline - 2*h - 22)
		self.properties2_pnl_holder:SetSize(w - 4, baseline)
	else
		self.properties_pnl_holder:SetPos(0,0)
		self.properties_pnl_holder:SetSize(w - 4, total_h - h - 22)
	end
end

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

	local props_shared_pnl = vgui.Create("DPanel", div)
	self.props_shared_pnl = props_shared_pnl
	local properties_pnl_holder = vgui.Create("DPanel", props_shared_pnl)
	local pnl = pace.CreatePanel("properties", properties_pnl_holder)
	pnl:Dock(FILL)
	pace.properties = pnl
	self.properties = pnl
	self.properties_pnl_holder = properties_pnl_holder

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

			self.limitfovcheckbox = vgui.Create("DCheckBoxLabel", self.zoomsettings)
			self.limitfovcheckbox:SetText("Expanded FOV")
			self.limitfovcheckbox:SetChecked(pace.max_fov ~= 100)
			self.limitfovcheckbox:Dock(TOP)
			self.limitfovcheckbox:SetDark(true)
			self.limitfovcheckbox:DockMargin(0,SETTING_MARGIN_TOP,0,0)


			self.orthocheckbox = vgui.Create("DCheckBoxLabel", self.zoomsettings)
			self.orthocheckbox:SetText("Orthographic")
			self.orthocheckbox:Dock(TOP)
			self.orthocheckbox:SetDark(true)
			self.orthocheckbox:DockMargin(0,SETTING_MARGIN_TOP,0,0)
			self.orthocheckbox:SetConVar("pac_camera_orthographic")
			self.orthocheckbox:SetTooltip("Orthographic view projects parallel rays perpendicular to a rectangle. Instead of degrees, it is in terms of distance units (Hammer Units)\n\nThere are still —possibly engine-related— issues where objects and world geometry can disapear if looking from the wrong angle due to culling. Especially worse in tight spaces.")

			self.ortholabel = vgui.Create("DLabel", self.zoomsettings)
			self.ortholabel:Dock(TOP)
			self.ortholabel:SetDark(true)
			self.ortholabel:SetText("Enable orthographic view.")
			self.ortholabel:SetWrap(true)
			self.ortholabel:SetAutoStretchVertical(true)

			self.ortho_nearz = vgui.Create("DNumSlider", self.zoomsettings)
			self.ortho_nearz:Dock(TOP)
			self.ortho_nearz:SetMin( 0 )
			self.ortho_nearz:SetMax( 5000 )
			self.ortho_nearz:SetDecimals( 1 )
			self.ortho_nearz:SetText("NearZ")
			self.ortho_nearz:SetDark(true)
			self.ortho_nearz:SetDefaultValue( 0 )
			self.ortho_nearz:SetValue( 0 )

			self.ortho_farz = vgui.Create("DNumSlider", self.zoomsettings)
			self.ortho_farz:Dock(TOP)
			self.ortho_farz:SetMin( 0 )
			self.ortho_farz:SetMax( 64000 )
			self.ortho_farz:SetDecimals( 1 )
			self.ortho_farz:SetText("FarZ")
			self.ortho_farz:SetDark(true)
			self.ortho_farz:SetDefaultValue( 64000 )
			self.ortho_farz:SetValue( 64000 )
			if not pace.camera_orthographic then
				self.ortho_nearz:Hide()
				self.ortho_farz:Hide()
			end


		self.sliderpanel = vgui.Create("DPanel", self.zoomframe)
		self.sliderpanel:SetSize(180, 20)
		self.sliderpanel:Dock(TOP)

			self.zoomslider = vgui.Create("DNumSlider", self.sliderpanel)
			self.zoomslider:DockPadding(4,0,0,0)
			self.zoomslider:SetSize(200, 20)
			self.zoomslider:SetDecimals( 0 )
			self.zoomslider:SetText("Camera FOV")
			if pace.camera_orthographic then
				self.zoomslider:SetText("Ortho. Width")
			end
			pace.RefreshZoomBounds(self.zoomslider)
			self.zoomslider:SetDark(true)
			self.zoomslider:SetDefaultValue( 75 )

			if zoom_persistent:GetInt() == 1 then
				self.zoomslider:SetValue( pace.ViewFOV )
			else
				self.zoomslider:SetValue( 75 )
			end
			local zoomslider = self.zoomslider
			function self.limitfovcheckbox:OnChange(b)
				if b then
					pace.max_fov = 179
				else
					pace.max_fov = 100
				end
				pace.RefreshZoomBounds(zoomslider)
			end

	self.btnClose.Paint = function() end

	self:SetBottom(props_shared_pnl)
	local clr = self:GetSkin().control_color_active --Color(70,200,255)
	local _,font_h = surface.GetTextSize("|")
	self.font_h = font_h + 2
	self.props_shared_pnl.Paint = function(self, w, h)
		if not pins:GetBool() then return end
		surface.SetFont(pace.CurrentFont)
		local _,font_h = surface.GetTextSize("|")
		self.font_h = font_h + 2
	    draw.RoundedBox(2, 0, 0, w, font_h + 5, clr)
		draw.SimpleText("pinned", pace.CurrentFont, 5, 0, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	end
	local properties2_pnl_holder = vgui.Create("DPanel", props_shared_pnl)
	local pnl2 = pace.CreatePanel("properties", properties2_pnl_holder)
	local collapse_pin_btn = vgui.Create("DButton", props_shared_pnl)
	self.collapse_pin_btn = collapse_pin_btn
	collapse_pin_btn:SetSize(self.font_h,self.font_h) collapse_pin_btn:SetImage("icon16/arrow_down.png") collapse_pin_btn:SetText("") collapse_pin_btn:SetTooltip("expand/collapse pinned properties")
	function collapse_pin_btn:DoClick()
		pins:SetBool(not pins:GetBool())
		--notify once
		if not self.clicked_once then pace.FlashNotification("you can hide the button by right clicking it") self.clicked_once = true end
	end
	function collapse_pin_btn:DoRightClick()
		local menu = DermaMenu()
		menu:SetPos(input.GetCursorPos())
		menu:AddOption("disable the pins collapser button", function()
			pins_button:SetBool(false)
			pace.FlashNotification("to re-enable the button display, run pac_editor_pins_show_button 1")
		end)
		menu:AddOption("replace the pins collapser button with a keyboard shortcut", function()
			pins_button:SetBool(false)
			pace.OpenSettings("Editor menu Settings")
			timer.Simple(0.5, function()
				GetConVar("pac_editor_shortcuts_legacy_mode"):SetBool(true)
				pace.shortcutaction_choices:ChooseOptionID(table.KeyFromValue(pace.PACActionShortcut_Dictionary, "toggle_pins"))
				Derma_StringRequest("bind request", "Pick a bind for toggle_pins", "TAB", function(str) pace.AssignEditorShortcut("toggle_pins", {[1] = str}, 1) end)
			end)
		end)
	end

	pnl2:Dock(FILL)
	pnl2.is_pins = true
	self.collapse_pin_btn = collapse_pin_btn
	pace.properties2 = pnl2
	self.properties2 = pnl2
	pnl.pins_counterpart = pnl2
	self.properties2_pnl_holder = properties2_pnl_holder

	self:SetCookieName("pac3_editor")
	self:SetPos(self:GetCookieNumber("x"), BAR_SIZE)

	if remember_width:GetBool() then
		self.init_w = math.max(self:GetCookieNumber("width"), 200)
	else
		self.init_w = 280
	end
	if remember_divider:GetBool() then
		pace.vertical_div_height = self:GetCookieNumber("y_divider")
	end

	self:MakeBar()
	self.lastTopBarHover = 0
	self.rendertime_data = {}
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
	if remember_divider:GetBool() then
		pace.vertical_div_height = self.div:GetTopHeight()
	end

	if remember_width:GetBool() then
		pace.editor_width = math.max(self:GetWide(), 200)
	end

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

function PANEL:IsLeft() --which side the editor is on.
	return self:GetPos() + self:GetWide() / 2 < ScrW() / 2
end

function PANEL:Think(...)
	if not self.okay then return end
	DFrame.Think(self, ...)
	
	surface.SetFont(pace.CurrentFont)
	local _,h = surface.GetTextSize("|")
	if pins:GetBool() then
		self.properties2_pnl_holder:Show()
		self.properties2:KillFocus()

		self.collapse_pin_btn:SetPos(self:GetWide() - self.font_h - 4, 0)
		self.collapse_pin_btn:SetSize(self.font_h, self.font_h)
		self.collapse_pin_btn:SetImage("icon16/arrow_down.png")
	else
		self.properties2_pnl_holder:Hide()

		self.collapse_pin_btn:SetPos(self:GetWide() - self.font_h - 4, 0)
		self.collapse_pin_btn:SetSize(self.font_h, self.font_h)
		self.collapse_pin_btn:SetImage("icon16/arrow_up.png")
	end
	resize_properties(self)
	if not pins_button:GetBool() then
		self.collapse_pin_btn:Hide()
	else
		self.collapse_pin_btn:Show()
	end

	if self.Hovered and self.m_bSizable and gui.MouseX() > (self.x + self:GetWide() - 20) then
		self:SetCursor("sizewe")
		return
	end

	for k,v in pairs(pac.GetRenderTimeInfo(pac.LocalPlayer)) do
		self.rendertime_data[k] = Lerp(0.03, self.rendertime_data[k] or 0, v)
	end

	local bar = self.menu_bar


	self:SetTall(ScrH() - (self.y_offset or 0))
	local w = math.max(self:GetWide(), 200)

	--wtf the GetWide isn't saved on Init??? I have to do this?
	if self.init_w then
		w = self.init_w
		self.init_w = nil
	end
	self:SetWide(w)
	self:SetPos(math.Clamp(self:GetPos(), 0, ScrW() - w), (self.y_offset or 0))

	if x ~= self.last_x then
		self:SetCookie("x", x)
		self.last_x = x
	end
	if w ~= self.last_w then
		self:SetCookie("width", w)
		self.last_w = w
	end
	if pace.vertical_div_height ~= self.last_vertical_div_height then
		self:SetCookie("y_divider", pace.vertical_div_height)
		self.last_vertical_div_height = pace.vertical_div_height
	end

	if self.exit_button:IsValid() then

		if self:IsLeft() then
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

		if pace.zoom_reset then
			self.zoomslider:SetValue(75)
			pace.zoom_reset = nil
		end
		if pace.OverridingFOVSlider then
			self.zoomslider:SetValue(pace.ViewFOV)
		end

		if zoom_smooth:GetInt() == 1 then
			pace.SetZoom(self.zoomslider:GetValue(),true)
		else
			pace.SetZoom(self.zoomslider:GetValue(),false)
		end

		local mx, my = input.GetCursorPos()
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
		if remember_divider:GetBool() then
			pace.vertical_div_height = self.div:GetTopHeight()
		end
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
					if remember_divider:GetBool() then
						self.div:SetTopHeight(pace.vertical_div_height)
					else
						self.div:SetTopHeight(newh)
					end
				end
			elseif sz >= 1 then

				if remember_divider:GetBool() then
					if remember_divider:GetBool() then
						self.div:SetTopHeight(pace.vertical_div_height)
					else
						self.div:SetTopHeight(newh)
					end
				else
					self.div:SetTopHeight(newh)
				end
			end
		end
	end
	resize_properties(self)
end

function PANEL:SetTop(pnl)
	self.top = pnl
	self.div:SetTop(pnl)
end

function PANEL:SetBottom(pnl)
	self.bottom = pnl
	self.div:SetBottom(pnl)
end

pace.Focused = false

function pace.IsFocused()
	return pace.Focused
end

local fade_time = 0.1

function pace.GainFocus(show_editor)
	local self = pace.Editor
	if self:IsValid() then
		if self.allowclick ~= false then
			self:MakePopup()
			pace.Focused = true

			timer.Remove("pac_editor_visibility")

			self:SetVisible(true)
			self.exit_button:SetVisible(true)
			self.zoomframe:SetVisible(true)

			self:AlphaTo(255, fade_time, 0)
			self.exit_button:AlphaTo(255, fade_time, 0)
			self.zoomframe:AlphaTo(255, fade_time, 0)
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
			self:AlphaTo(0, fade_time, 0)
			self.exit_button:AlphaTo(0, fade_time, 0)
			self.zoomframe:AlphaTo(0, fade_time, 0)

			timer.Create("pac_editor_visibility", fade_time, 1, function()
				self:SetVisible(false)
				self.exit_button:SetVisible(false)
				self.zoomframe:SetVisible(false)
			end)
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

end

pac.AddHook('PostRenderVGUI', 'pac_DrawProfileInfos', PostRenderVGUI)

function PANEL:PaintOver(w, h)
	if not self.okay then return end
	textCol = self:GetSkin().Colours.Category.Line.Text
	local text = _G.PAC_VERSION and PAC_VERSION()
	if text then
		surface.SetFont("DermaDefault")
		local x, y = self:LocalToScreen()
		local w, h = surface.GetTextSize(text)
		x = x + self:GetWide() + 4
		y = y + self:GetTall() - 4 - h

		local mx, my = gui.MousePos()
		local cx, cy = self:LocalToScreen(x, y)

		local hovering = false
		DisableClipping(true)

		if mx > x and mx < x + w and my > y and my < y + h then
			hovering = true
			text = "pac version: " .. text
			w, h = surface.GetTextSize(text)

			surface.SetDrawColor(0,0,0,255)
			surface.DrawRect(x,y,w,h)
		end

		surface.SetTextPos(x,y)
		surface.SetTextColor(255,255,255,hovering and 255 or 100)
		surface.DrawText(text)
		DisableClipping(false )
	end

	local data = self.rendertime_data

	local x = 2
	local y = 2
	y = y + self.menu_bar:GetTall()
	y = y + self.top:GetTall()
	boxW, boxH = w, h

	surface.SetFont(pace.CurrentFont)

	textCol = self:GetSkin().Colours.Category.Line.Text
	drawBox = self:GetSkin().tex.Menu_Strip
	surface.SetTextColor(textCol)
	cam.IgnoreZ(true)

	local total = 0
	for k,v in pairs(data) do
		total = total + v
	end

	local str = string.format("%s: %.3f ms", L("average render time"), total * 1000)
	drawBox(x, y, w - 5, RENDERSCORE_SIZE - 1)

	local mx, my = input.GetCursorPos()
	local cx, cy = self:LocalToScreen(x, y)

	if cx <= mx and cy <= my and mx <= cx + w - 5 and my <= cy + RENDERSCORE_SIZE - 1 and self:IsChildHovered() then
		surface.SetFont(pace.CurrentFont)
		surface.SetTextColor(textCol)

		local x, y = input.GetCursorPos()
		x = x + 3
		y = y + 3

		DisableClipping(true)
		for type, time in pairs(self.rendertime_data) do
			y = drawTimeBox(type, time * 1000, x, y)
		end
		DisableClipping(false)
	end

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
