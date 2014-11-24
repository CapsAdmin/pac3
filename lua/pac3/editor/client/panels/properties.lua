local L = pace.LanguageString

local function SHOW_SPECIAL(pnl, parent, size)
	size = size or 150
	
	pnl:SetPos(pace.Editor:GetWide(), select(2, parent:LocalToScreen()) - size + 25)
	pnl:SetSize(size, size)
	pnl:MakePopup()		
end

local function FIX_MENU(menu)
	menu:SetMaxHeight(500)
	menu:InvalidateLayout(true, true)
	menu:SetPos(pace.Editor:GetPos() + pace.Editor:GetWide(), gui.MouseY() - (menu:GetTall() * 0.5))
end

local function populate_part_menu(menu, part, func)
	if part:HasChildren() then
		local menu, pnl = menu:AddSubMenu(part:GetName(), function()
			pace.current_part[func](pace.current_part, part)
		end)
		
		pnl:SetImage(pace.GetIconFromClassName(part.ClassName))
		
		for key, part in pairs(part:GetChildren()) do
			populate_part_menu(menu, part, func)
		end
	else
		menu:AddOption(part:GetName(), function()
			pace.current_part[func](pace.current_part, part)
		end):SetImage(pace.GetIconFromClassName(part.ClassName))
	end
end

pace.ActiveSpecialPanel = NULL
pace.extra_populates = {}

function pace.SafeRemoveSpecialPanel()
	if pace.ActiveSpecialPanel:IsValid() then
		pace.ActiveSpecialPanel:Remove()
	end
end

hook.Add("GUIMousePressed", "pace_SafeRemoveSpecialPanel", function()
	local pnl = pace.ActiveSpecialPanel
	if pnl:IsValid() then
		local x,y = gui.MousePos()
		local _x, _y = pnl:GetPos()
		if x < _x or y < _y or x > _x + pnl:GetWide() or y > _y + pnl:GetTall() then
			pnl:Remove()
		end
	end
end)

do -- container
	local PANEL = {}

	PANEL.ClassName = "properties_container"
	PANEL.Base = "DPanel"

	function PANEL:Paint(w, h)
		--self:GetSkin().tex.MenuBG(0, 0, w + (self.right and -1 or 3), h + 1)
		if not self.right then		
			surface.SetDrawColor(derma.Color("text_bright", self, color_white))
			surface.DrawRect(0,0,w+5,h)
			surface.SetDrawColor(derma.Color("text_dark", self, color_black))
			surface.DrawOutlinedRect(0,0,w+5,h+2)
		else
			surface.SetDrawColor(derma.Color("text_bright", self, color_white))
			surface.DrawRect(0,0,w,h)
			surface.SetDrawColor(derma.Color("text_dark", self, color_black))
			surface.DrawOutlinedRect(0,0,w,h+2)
		end
	end

	function PANEL:SetContent(pnl)
		pnl:SetParent(self)
		self.content = pnl
	end

	function PANEL:PerformLayout()
		local pnl = self.content or NULL
		if pnl:IsValid() then
			pnl:SetPos(0, 0)
			pnl:SetSize(self:GetSize())
		end
	end

	pace.RegisterPanel(PANEL)
end

do -- list
	local PANEL = {}

	PANEL.ClassName = "properties"
	PANEL.Base = "Panel"

	AccessorFunc(PANEL, "item_height", "ItemHeight")

	function PANEL:Init()
		self.List = {}
				
		local divider = vgui.Create("DHorizontalDivider", self)
		local left = vgui.Create("DPanelList", divider)
			divider:SetLeft(left)
		self.left = left

		local right = vgui.Create("DPanelList", divider)
			divider:SetRight(right)
		self.right = right

		divider:SetDividerWidth(3)
		divider:SetLeftWidth(110)
		
		surface.SetFont(pace.CurrentFont)
		local w,h = surface.GetTextSize("W")
		local size = h + 2
		
		self:SetItemHeight(size)
				
		self.div = divider
		
		function divider:PerformLayout()
			DHorizontalDivider.PerformLayout(self)
			
			if self.m_pLeft then
				self.m_pLeft:SetWide( self.m_iLeftWidth + self.m_iDividerWidth )
			end
		end
		
		local scroll = vgui.Create("DVScrollBar", self)
		scroll:Dock(RIGHT)
		self.scr = scroll
		
		left.OnMouseWheeled = function(_, delta) scroll:OnMouseWheeled(delta) end
		--right.OnMouseWheeled = function(_, delta) scroll:OnMouseWheeled(delta) end
	end
	
	function PANEL:Paint(w, h)
		h = self:GetHeight()
		surface.SetDrawColor(derma.Color("text_dark", self, color_black))
		surface.DrawOutlinedRect(0,0,w,h-9)
	end

	function PANEL:GetHeight(hack)
		return (self.item_height * (#self.List+(hack or 1))) - (self.div:GetDividerWidth() + 1)
	end

	function PANEL:FixHeight()
		for key, data in pairs(self.List) do
			data.left:SetTall(self:GetItemHeight())
			data.right:SetTall(self:GetItemHeight())
		end
	end
	
	function PANEL:PerformLayout()
		self.scr:SetSize(10, self:GetHeight())
		self.scr:SetUp(self:GetTall(), self:GetHeight() - 10)
		self.div:SetPos(0,self.scr:GetOffset())
		local w, h = self:GetSize()
		self.div:SetSize(w - (self.scr.Enabled and self.scr:GetWide() or 0), self:GetHeight())
	end
	
	pace.CollapsedProperties = pac.luadata.ReadFile("pac3_editor/collapsed.txt") or {}
	
	function PANEL:AddCollapser(name)
		local left = vgui.Create("DButton", self)
		left:SetText("")
		self.left:AddItem(left)
		
		left.DoClick = function()
			pace.CollapsedProperties[name] = not pace.CollapsedProperties[name]
			pace.PopulateProperties(pace.current_part)
					
			pace.Editor:InvalidateLayout()	
			pac.luadata.WriteFile("pac3_editor/collapsed.txt", pace.CollapsedProperties)
		end
		
		local right = vgui.Create("DButton", self)
		right:SetText("")
		self.right:AddItem(right)
		
		right.DoClick = left.DoClick
		
		left.Paint = function(_, w, h)
			surface.SetDrawColor(derma.Color("control_color_bright", self, color_white))
			surface.DrawRect(0,0,w,h)
			
			local txt = L(name)
			local _, _h = surface.GetTextSize(txt)
			local middle = h/2 - _h/2
			
			surface.SetTextPos(11, middle)
			surface.SetTextColor(derma.Color("text_dark", self, color_black))
			surface.SetFont(pace.CurrentFont)
			surface.DrawText(txt)
			
			local txt = (pace.CollapsedProperties[name] and "+" or "-")
			local w = surface.GetTextSize(txt)
			surface.SetTextPos(6-w*0.5,middle)
			surface.DrawText(txt)
		end
		
		right.Paint = function(_,w,h)
			surface.SetDrawColor(derma.Color("control_color_bright", self, color_white))
			surface.DrawRect(0,0,w-1,h)
		end
		
		table.insert(self.List, {left = left, right = right, panel = var, key = key})
	end

	function PANEL:AddKeyValue(key, var, pos, obj)
		local btn = pace.CreatePanel("properties_label")
			btn:SetValue(" " .. L(key:gsub("%u", " %1"):lower()))
			btn.pac3_sort_pos = pos
			
			if obj then
				btn.key_name = key
				btn.part_namepart_name = obj.ClassName
			end
			
		self.left:AddItem(btn)

		local pnl = pace.CreatePanel("properties_container")
		pnl.right = true
		
		if type(var) == "Panel" then
			pnl:SetContent(var)
		end
		
		pnl.pac3_sort_pos = pos
		self.right:AddItem(pnl)

		table.insert(self.List, {left = btn, right = pnl, panel = var, key = key})
	end

	function PANEL:Clear()
		for key, data in pairs(self.List) do
			data.left:Remove()
			data.right:Remove()
		end
		
		self.left:Clear()
		self.right:Clear()

		self.List = {}
	end

	function PANEL:Populate(obj, dont_clear, group_override)	
		if dont_clear == nil then self:Clear() end

		local tbl = {}
		local data = {}		
		
		for key, val in pairs(obj.ClassName and obj:GetVars() or obj) do
			local callback
			if not obj.ClassName then
				callback = val.callback
				val = val.val
			end		
							
			if not obj.ClassName or (not pace.HiddenPropertyKeys[key] or pace.HiddenPropertyKeys[key] == obj.ClassName) and not pace.ShouldHideProperty(key) then
				local group = pace.ReversedPropertySheets[key:lower()]
				if group == nil then group = L"generic" end
				
				if pace.PropertySheets[obj.ClassName] then
					local reversed = {}
					for group, properties in pairs(pace.PropertySheets[obj.ClassName]) do
						for k,v in pairs(properties) do
							reversed[k] = group
						end
					end
					
					group = reversed[key:lower()]
					if group == nil then group = L"generic" end
				end
				
				if pace.PropertySheetPatterns[obj.ClassName] then
					for _group, pattern in pairs(pace.PropertySheetPatterns[obj.ClassName]) do
						local found
						
						if type(pattern) == "table" then
							for k,v in pairs(pattern) do 
								if key:lower():find(v) then
									found = true
									break
								end
							end
						else
							found = key:lower():find(pattern)
						end
						
						if found then
							group = _group
						end
					end
				end
										
				table.insert(data, {key = key, val = val, group = group_override or group, callback = callback})
			end
		end
		
		table.sort(data, function(a,b) return a.key > b.key end)
		
		local ordered_list = {}
		
		for k,v in pairs(pace.PropertyOrder) do table.insert(ordered_list, v) end
		for k,v in pairs(pac.VariableOrder) do table.insert(ordered_list, v) end
		
		local sorted_sheets = {}
		table.insert(sorted_sheets, "generic")
		
		if pace.PropertySheetPatterns[obj.ClassName] then
			for k,v in pairs(pace.PropertySheetPatterns[obj.ClassName]) do
				table.insert(sorted_sheets, k)
			end
		end
		
		if pace.PropertySheets[obj.ClassName] then
			for k,v in pairs(pace.PropertySheets[obj.ClassName]) do
				table.insert(sorted_sheets, k)
			end
		end
		
		for k,v in pairs(pace.PropertySheets) do
			table.insert(sorted_sheets, k)
		end
		
		for _, group in pairs(sorted_sheets) do
			for pos, str in pairs(ordered_list) do
				for i, val in pairs(data) do
					if val.key == str and val.group == group then
						table.insert(tbl, {pos = pos, key = val.key, val = val.val, group = val.group, callback = val.callback})
						table.remove(data, i)
					end
				end
			end
		end

		for pos, val in pairs(data) do
			table.insert(tbl, {pos = pos, key = val.key, val = val.val, group = val.group, callback = val.callback})
		end
				
		local current_group = nil

		for pos, data in pairs(tbl) do		
			local key, val = data.key, data.val

			if obj.ClassName then
				if pace.IsInBasicMode() and not pace.BasicProperties[key] then continue end
				
				if not pace.IsShowingDeprecatedFeatures() then
					local part = pace.DeprecatedProperties[key]
					if part == true or part == obj.ClassName then
						continue
					end
				end
			end

			local pnl
			local T = (pace.TranslatePropertiesKey(key, obj) or type(val)):lower()

			if pace.PanelExists("properties_" .. T) then
			
				if data.group and data.group ~= current_group then
					self:AddCollapser(data.group)
					current_group = data.group
				end
			
				if pace.CollapsedProperties[data.group] ~= nil and pace.CollapsedProperties[data.group] then continue end
			
				pnl = pace.CreatePanel("properties_" .. T)
			end
			
			if pnl then
				if obj.ClassName then
					
					if pnl.ExtraPopulate then
						table.insert(pace.extra_populates, pnl.ExtraPopulate)
						pnl:Remove()
						continue
					end
				
					pnl.CurrentKey = key
					obj.editor_pnl = pnl
					
					local val = obj["Get" .. key](obj)
					pnl:SetValue(val)
					pnl.LimitValue = pace.PropertyLimits[key]
					
					pnl.OnValueChanged = function(val)
						if T == "number" then
							val = tonumber(val) or 0
						elseif T == "string" then
							val = tostring(val)
						end
						pace.Call("VariableChanged", obj, key, val)
					end
					
					self:AddKeyValue(key, pnl, pos, obj)
				else
					pnl.CurrentKey = key
					pnl:SetValue(val)
					pnl.LimitValue = pace.PropertyLimits[key]
					pnl.OnValueChanged = data.callback
					self:AddKeyValue(key, pnl, pos)
				end
			end
		end
		
		self:FixHeight()
	end
	
	
	function PANEL:PopulateCustom(obj)
		self:Clear()

		local tbl = {}
		local data = {}
		
		for key, val in pairs(obj) do
			table.insert(data, {key = key, val = val.val, callback = val.callback})
		end
		
		table.sort(data, function(a,b) return a.key > b.key end)
		
		for pos, str in pairs(pace.PropertyOrder) do
			for i, val in pairs(data) do
				if val.key == str then
					table.insert(tbl, {pos = pos, key = val.key, val = val.val, callback = val.callback})
					table.remove(data, i)
				end
			end
		end

		for pos, val in pairs(data) do
			table.insert(tbl, {pos = pos, key = val.key, val = val.val, callback = val.callback})
		end
				
		for pos, data in pairs(tbl) do
			local key, val = data.key, data.val

			local pnl
			local T = (pace.TranslatePropertiesKey(key, obj) or type(val)):lower()
			
			if pace.PanelExists("properties_" .. T) then
				pnl = pace.CreatePanel("properties_" .. T)
			end

			if pnl then	
				pnl.CurrentKey = key
				pnl:SetValue(val)
				pnl.LimitValue = pace.PropertyLimits[key]
				pnl.OnValueChanged = data.callback
				self:AddItem(key, pnl, pos)
			end
		end
		
		self:FixHeight()
	end

	pace.RegisterPanel(PANEL)
end

do -- non editable string
	local DTooltip = _G.DTooltip
	if DTooltip and DTooltip.PositionTooltip then
		pace_Old_PositionTooltip = pace_Old_PositionTooltip or DTooltip.PositionTooltip
		function DTooltip.PositionTooltip(self, ...)
			if self.TargetPanel.pac_tooltip_hack then
				local args = {pace_Old_PositionTooltip(self, ...)}
									
				if ( !IsValid( self.TargetPanel ) ) then
					self:Remove()
					return;
				end

				self:PerformLayout()
				
				local x, y		= input.GetCursorPos()
				local w, h		= self:GetSize()
				
				local lx, ly	= self.TargetPanel:LocalToScreen( 0, 0 )
								
				y = math.min( y, ly - h )
				
				self:SetPos( x, y )
							
				
				return unpack(args)
			end
			
			return pace_Old_PositionTooltip(self, ...)
		end
	end
	

	local PANEL = {}

	PANEL.ClassName = "properties_label"
	PANEL.Base = "pace_properties_container"

	function PANEL:SetValue(str)
		local lbl = vgui.Create("DLabel")
			lbl:SetTextColor(derma.Color("text_dark", self, color_black))
			lbl:SetFont(pace.CurrentFont)
			lbl:SetText("  " .. str) -- ugh
			lbl:SizeToContents()
			lbl.pac_tooltip_hack = true
		self:SetContent(lbl)
		
		if self.part_name and self.key_name then
			lbl.OnCursorEntered = function() 
				
				if lbl.wiki_info then
					lbl:SetTooltip(lbl.wiki_info)
					return
				end
			
				if not lbl.fetching_wiki then
					lbl:SetCursor("waitarrow")
					pace.GetPropertyDescription(self.part_name, self.key_name, function(str)
						if lbl:IsValid() then
							lbl:SetTooltip(str)
							ChangeTooltip(lbl)
							lbl.wiki_info = str
							lbl:SetCursor("arrow")
						end
					end)
					lbl.fetching_wiki = true
				end	
			end
		end
	end

	pace.RegisterPanel(PANEL)
end

do -- base editable
	local PANEL = {}

	PANEL.ClassName = "properties_base_type"
	PANEL.Base = "DLabel"
	
	PANEL.SingleClick = true
	
	function PANEL:OnCursorMoved()
		self:SetCursor("hand")
	end
	
	function PANEL:Init(...)
		if self.SpecialCallback then
			local btn = vgui.Create("DButton", self)
			btn:SetSize(16, 16)
			btn:Dock(RIGHT)
			btn:SetText("...")
			btn.DoClick = function() self:SpecialCallback(self.CurrentKey) end
			btn.DoRightClick = self.SpecialCallback2 and function() self:SpecialCallback2(self.CurrentKey) end or btn.DoClick
		end
				
		if DLabel and DLabel.Init then
			return DLabel.Init(self, ...)
		end
	end

	function PANEL:SetValue(var, skip_encode)
		if self.editing then return end

		local str = tostring(skip_encode and var or self:Encode(var))
		
		self:SetTextColor(derma.Color("text_dark", self, color_black))
		self:SetFont(pace.CurrentFont)
		self:SetText("  " .. str) -- ugh
		self:SizeToContents()

		if #str > 10 then
			self:SetTooltip(str)
		end

		self.original_str = str
		self.original_var = var
	end
	
	-- kind of a hack
	local last_focus = NULL

	function PANEL:OnMousePressed(mcode)	
		if last_focus:IsValid() then
			last_focus:Reset()
			last_focus = NULL
		end	
				
		if mcode == MOUSE_LEFT then
			--if input.IsKeyDown(KEY_R) then
			--	self:Restart()
			--else
				self.MousePressing = true
				if self:MousePress(true) == false then return end
				if self.SingleClick or (self.last_press or 0) > RealTime() then
					self:EditText()
					self:DoubleClick()
					self.last_press = 0
					
					last_focus = self
				else
					self.last_press = RealTime() + 0.2
				end
			--end
		end
		
		if false and mcode == MOUSE_RIGHT then
			local menu = DermaMenu()
			menu:SetPos(gui.MousePos())
			menu:MakePopup()
			menu:AddOption(L"reset", function()
				self:Restart()
			end)
		end
	end

	function PANEL:OnMouseReleased()
		self:MousePress(false)
		self.MousePressing = false
	end

	function PANEL:IsMouseDown()
		if not input.IsMouseDown(MOUSE_LEFT) then
			self.MousePressing = false
		end
		return self.MousePressing
	end

	function PANEL:DoubleClick()

	end
	
	function PANEL:MousePress()

	end
	
	function PANEL:Restart()
		self:SetValue(self:Decode(""))
		self.OnValueChanged(self:Decode(""))
	end

	function PANEL:EditText()		
		self:SetText("")
		
		local pnl = vgui.Create("DTextEntry", self)
		self.editing = pnl
		pnl:SetFont(pace.CurrentFont)
		pnl:SetDrawBackground(false)
		pnl:SetDrawBorder(false)
		pnl:SetValue(self.original_str or "")
		pnl:SetKeyboardInputEnabled(true)
		pnl:RequestFocus()
		pnl:SelectAllOnFocus(true)
		
		local x,y = pnl:GetPos()
		pnl:SetPos(x+3,y-4)
		pnl:Dock(FILL)
				
		pnl.OnEnter = function()
			pace.BusyWithProperties = NULL
			self.editing = false
			
			pnl:Remove()
			
			self:SetValue(pnl:GetValue() or "", true)
			self.OnValueChanged(self:Decode(pnl:GetValue()))
		end
		
		pace.BusyWithProperties = pnl
	end
	
	pace.BusyWithProperties = NULL
	
	local function click()
		if not input.IsMouseDown(MOUSE_LEFT) then return end
		local pnl = pace.BusyWithProperties
		if pnl and pnl ~= true and pnl:IsValid() then
			local x, y = gui.MousePos()
			local _x, _y = pnl:GetParent():LocalToScreen()
			if x < _x or y < _y or x > _x + pnl:GetParent():GetWide() or y > _y + pnl:GetParent():GetTall() then
				pnl:OnEnter()
			end
		end
	end
	
	hook.Add("GUIMousePressed", "pace_property_text_edit", click)
	hook.Add("VGUIMousePressed", "pace_property_text_edit", click)
	
	function PANEL:Reset()
		if IsValid(self.editing) then
			self.editing:OnEnter()
			self.editing = false
		else
			self:SetValue(self.original_var)
			self.OnValueChanged(self.original_var)
		end
	end

	function PANEL:GetValue()
		return self.original_var
	end

	function PANEL:Encode(var)
		return var
	end

	function PANEL:Decode(var)
		return var
	end

	function PANEL:PerformLayout()
		self:SetSize(self:GetParent():GetSize())
	end

	pace.RegisterPanel(PANEL)
end

do -- string
	local PANEL = {}

	PANEL.ClassName = "properties_string"
	PANEL.Base = "pace_properties_base_type"
	
	PANEL.SingleClick = true
	
	pace.RegisterPanel(PANEL)
end

do -- vector
	local function VECTOR(ctor, type, arg1, arg2, arg3, encode, special_callback, sens)
		local PANEL = {}

		PANEL.ClassName = "properties_" .. type
		PANEL.Base = "pace_properties_container"

		function PANEL:Init(...)
			self.vector = ctor(0,0,0)

			local left = pace.CreatePanel("properties_number", self)
			local middle = pace.CreatePanel("properties_number", self)
			local right = pace.CreatePanel("properties_number", self)
			
			if encode then
				left.Encode = encode
				middle.Encode = encode
				right.Encode = encode
			end
			
			if sens then
				left.sens = sens
				middle.sens = sens
				right.sens = sens
			end
			
			left:SetMouseInputEnabled(true)
			left.OnValueChanged = function(num)			
				self.vector[arg1] = num
				
				if input.IsKeyDown(KEY_R) then
					self:Restart()
				elseif input.IsKeyDown(KEY_LSHIFT) then
					middle:SetValue(num)
					self.vector[arg2] = num
					
					right:SetValue(num)
					self.vector[arg3] = num
				end
				
				self.OnValueChanged(self.vector)
				self:InvalidateLayout()
			end

			middle:SetMouseInputEnabled(true)
			middle.OnValueChanged = function(num)			
				self.vector[arg2] = num
				
				if input.IsKeyDown(KEY_R) then
					self:Restart()
				elseif input.IsKeyDown(KEY_LSHIFT) then
					left:SetValue(num)
					self.vector[arg1] = num
					
					right:SetValue(num)
					self.vector[arg3] = num
				end
				
				self.OnValueChanged(self.vector)
				self:InvalidateLayout()
			end

			right:SetMouseInputEnabled(true)
			right.OnValueChanged = function(num)				
				self.vector[arg3] = num
				
				if input.IsKeyDown(KEY_R) then
					self:Restart()
				elseif input.IsKeyDown(KEY_LSHIFT) then
					middle:SetValue(num)
					self.vector[arg2] = num
					
					left:SetValue(num)
					self.vector[arg1] = num
				end
				
				self.OnValueChanged(self.vector)
				self:InvalidateLayout()
			end

			left:SetPaintBorderEnabled(true)
			middle:SetPaintBorderEnabled(true)
			right:SetPaintBorderEnabled(true)

			self.left = left
			self.middle = middle
			self.right = right
			
			if self.SpecialCallback then
				local btn = vgui.Create("DButton", self)
				btn:SetSize(16, 16)
				btn:Dock(RIGHT)
				btn:SetText("...")
				btn.DoClick = function() self:SpecialCallback() end
				btn.DoRightClick = self.SpecialCallback2 and function() self:SpecialCallback2(self.CurrentKey) end or btn.DoClick
			end
		end
		
		PANEL.SpecialCallback = special_callback		
		
		function PANEL:Restart()
			self.left:SetValue(0)
			self.middle:SetValue(0)
			self.right:SetValue(0)
			
			self.OnValueChanged(self.vector)
		end

		function PANEL:SetValue(vec)
			self.vector = vec

			self.left:SetValue(math.Round(vec[arg1], 4))
			self.middle:SetValue(math.Round(vec[arg2], 4))
			self.right:SetValue(math.Round(vec[arg3], 4))
		end

		function PANEL:PerformLayout()
			self.left:SizeToContents()
			self.left:SetWide(math.max(self.left:GetWide(), 22))
			
			self.middle:SizeToContents()
			self.middle:SetWide(math.max(self.middle:GetWide(), 22))
			
			self.right:SizeToContents()
			self.right:SetWide(math.max(self.right:GetWide(), 22))

			self.middle:MoveRightOf(self.left, 10)
			self.right:MoveRightOf(self.middle, 10)
		end
		
		function PANEL:OnValueChanged(vec)
		end

		pace.RegisterPanel(PANEL)
	end

	VECTOR(Vector, "vector", "x", "y", "z")
	VECTOR(Angle, "angle", "p", "y", "r")
	VECTOR(Vector, "color", "x", "y", "z", 
		function(_, num)		
			num = tonumber(num) or 0
	
			num = math.Round(num) 
			num = math.Clamp(num, 0, 255) 

			return tostring(num)
		end, 
		
		function(self)
			pace.SafeRemoveSpecialPanel()
			
			local frm = vgui.Create("DFrame")
			frm:SetTitle("color")
			
			SHOW_SPECIAL(frm, self, 300)
			
			local clr = vgui.Create("DColorMixer", frm)
			clr:Dock(FILL)
			clr:SetColor(Color(self.vector.x, self.vector.y, self.vector.z))
			
			local function tohex(vec)
				return ("#%X%X%X"):format(vec.x, vec.y, vec.z)
			end
			
			local function fromhex(str)
				local x,y,z = str:match("#?(..)(..)(..)")
				return Vector(tonumber("0x" .. x), tonumber("0x" .. y), tonumber("0x" .. z))
			end
			
			local html_color = vgui.Create("DTextEntry", frm)
			html_color:Dock(BOTTOM)
			html_color:SetText(tohex(self.vector))
			html_color.OnEnter = function() 
				local vec = fromhex(html_color:GetValue())
				clr:SetColor(Color(vec.x, vec.y, vec.z))
				self.OnValueChanged(vec)
				self:SetValue(vec)
			end
			
			function clr.Think()
				local clr = clr:GetColor() or Color(255, 255, 255, 255)
				local vec = Vector(clr.r, clr.g, clr.b)
				self.OnValueChanged(vec)
				self:SetValue(vec)
				html_color:SetText(tohex(vec))
			end
			
			pace.ActiveSpecialPanel = frm
		end,
		10
	)
end

do -- number
	local PANEL = {}

	PANEL.ClassName = "properties_number"
	PANEL.Base = "pace_properties_base_type"
	
	PANEL.sens = 1
	
	PANEL.SingleClick = false
	
	function PANEL:MousePress(bool)
		if bool then
			self.mousey = gui.MouseY()
			self.mousex = gui.MouseX()
			self.oldval = tonumber(self:GetValue()) or 0
		else
			self.mousey = nil
		end
	end
	
	function PANEL:OnCursorMoved()
		self:SetCursor("sizens")
	end
	
	function PANEL:SetNumberValue(val)		
		if self.LimitValue then
			val = self:LimitValue(val) or val
		end
		
		val = self:Encode(val)
		self:SetValue(val)
		self.OnValueChanged(tonumber(val))
	end
	
	function PANEL:OnMouseWheeled(delta)
		if not input.IsKeyDown(KEY_LCONTROL) then delta = delta / 10 end
		if input.IsKeyDown(KEY_LALT) then delta = delta / 10 end 
		local val = self:GetValue() + (self.oldval or 0) + (delta * self.sens)
		
		self:SetNumberValue(val)
	end

	function PANEL:Think()
		if self:IsMouseDown() then			
			local sens = self.sens
			
			if input.IsKeyDown(KEY_LALT) then
				sens = sens / 10
			end
			
			local delta = (self.mousey - gui.MouseY()) / 10
			local val = (self.oldval or 0) + (delta * sens)
			
			self:SetNumberValue(val)
		end
	end

	function PANEL:Encode(num)
		num = tonumber(num) or 0
		
		num = math.Round(num, 3)
		
		if input.IsKeyDown(KEY_LCONTROL) then
			num = math.Round(num)
		end
		
		return num
	end

	function PANEL:Decode(str)
		return tonumber(str) or 0
	end

	pace.RegisterPanel(PANEL)
end

do -- boolean
	local PANEL = {}

	PANEL.ClassName = "properties_boolean"
	PANEL.Base = "pace_properties_container"

	function PANEL:Init()
		local chck = vgui.Create("DCheckBox", self)
		chck.OnChange = function() 
			local b = chck:GetChecked()
			self.OnValueChanged(b) 
			self.lbl:SetText(L(tostring(b)))
		end
		self.chck = chck
		
		local lbl = vgui.Create("DLabel", self)
		lbl:SetFont(pace.CurrentFont)
		lbl:SetTextColor(derma.Color("text_dark", self, color_black))
		self.lbl = lbl
	end

	function PANEL:Paint() end
	
	function PANEL:SetValue(b)
		self.chck:SetChecked(b)
		self.chck:Toggle()
		self.chck:Toggle()
		self.lbl:SetText(L(tostring(b)))
	end

	function PANEL:OnValueChanged()

	end

	function PANEL:PerformLayout()
		self.BaseClass.PerformLayout(self)
		
		local s = 4
		
		self.chck:SetPos(s*0.5, s*0.5+1)
		self.chck:SetSize(self:GetTall()-s, self:GetTall()-s)

		self.lbl:MoveRightOf(self.chck, 5)
		self.lbl:CenterVertical()
		local w,h = self:GetParent():GetSize()
		self:SetSize(w-2,h)
	end
	
	pace.RegisterPanel(PANEL)
end

do -- bone
	local PANEL = {}

	PANEL.ClassName = "properties_bone"
	PANEL.Base = "pace_properties_base_type"
	
	function PANEL:SpecialCallback()
		pace.SelectBone(pace.current_part:GetOwner(), function(data)
			self:SetValue(L(data.friendly))
			self.OnValueChanged(data.friendly)
		end)
	end
	
	function PANEL:SpecialCallback2()
		local bones = pac.GetModelBones(pace.current_part:GetOwner())
		
		local menu = DermaMenu()
		
		menu:MakePopup()
		
		bones = table.ClearKeys(bones)
		table.sort(bones, function(a,b) return a.friendly > b.friendly end)
		for _, data in pairs(bones) do
			menu:AddOption(L(data.friendly), function()
				self:SetValue(L(data.friendly))
				self.OnValueChanged(data.friendly)
			end)
		end
		
		FIX_MENU(menu)
	end
	
	pace.RegisterPanel(PANEL)
end

do -- part
	local PANEL = {}

	PANEL.ClassName = "properties_part"
	PANEL.Base = "pace_properties_base_type"
	
	function PANEL:SpecialCallback()
		pace.SelectPart(pac.GetParts(true), function(part)
			self:SetValue(part:GetName())
			self.OnValueChanged(part)
		end)
	end
		
	function PANEL:SpecialCallback2(key)
		local menu = DermaMenu()
		
		menu:MakePopup()		
		
		for _, part in pairs(pac.GetParts(true)) do
			if not part:HasParent() then
				populate_part_menu(menu, part, "Set" .. key)
			end
		end
		
		FIX_MENU(menu)
	end
	
	pace.RegisterPanel(PANEL)
end

do -- owner
	local PANEL = {}

	PANEL.ClassName = "properties_ownername"
	PANEL.Base = "pace_properties_base_type"
	
	function PANEL:SpecialCallback()
		pace.SelectEntity(function(ent)
			pace.current_part:SetOwnerName(ent:EntIndex())
			local name = pace.current_part:GetOwnerName()
			self.OnValueChanged(name)
			self:SetValue(L(name))
		end)
	end
		
	function PANEL:SpecialCallback2()
		local menu = DermaMenu()
		menu:MakePopup()
				
		local function get_friendly_name(ent)
			local name = ent.GetName and ent:GetName()
			if not name or name == "" then
				name = ent:GetClass()
			end

			return ent:EntIndex() .. " - " .. name
		end
		
		for key, name in pairs(pac.OwnerNames) do
			menu:AddOption(name, function() pace.current_part:SetOwnerName(name) end)
		end
		
		local entities = menu:AddSubMenu(L"entities", function() end)
		entities.GetDeleteSelf = function() return false end
		for _, ent in pairs(ents.GetAll()) do
			if ent:EntIndex() > 0 then
				entities:AddOption(get_friendly_name(ent), function()
					pace.current_part:SetOwnerName(ent:EntIndex())
					self.OnValueChanged(ent:EntIndex())
				end)
			end
		end
		
		FIX_MENU(menu)
	end
	
	pace.RegisterPanel(PANEL)
end

do -- aimpart
	local PANEL = {}

	PANEL.ClassName = "properties_aimpartname"
	PANEL.Base = "pace_properties_base_type"
		
	function PANEL:SpecialCallback()
		pace.SelectPart(pac.GetParts(true), function(part)
			self:SetValue(part:GetName())
			self.OnValueChanged(part)
		end)
	end
		
	function PANEL:SpecialCallback2(key)
		local menu = DermaMenu()
		menu:MakePopup()
				
		for key, name in pairs(pac.AimPartNames) do
			menu:AddOption(L(key), function() pace.current_part:SetAimPartName(name) end):SetImage("icon16/eye.png")
		end
		
		for _, part in pairs(pac.GetParts(true)) do
			if not part:HasParent() then
				populate_part_menu(menu, part, "SetAimPartName")
			end
		end
		
		FIX_MENU(menu)
	end
	
	pace.RegisterPanel(PANEL)
end

do -- model
	local PANEL = {}

	PANEL.ClassName = "properties_model"
	PANEL.Base = "pace_properties_base_type"
	
	function PANEL:SpecialCallback2()
		pace.SafeRemoveSpecialPanel()
		g_SpawnMenu:Open()
	end
	
	function PANEL:SpecialCallback()
		pace.close_spawn_menu = true
		pace.SafeRemoveSpecialPanel()
		g_SpawnMenu:Open()
	end
	
	-- this is so lame
	
	--[[function PANEL:SpecialCallback()
		pace.SafeRemoveSpecialPanel()
		
		local frame = vgui.Create("DFrame")
		frame:SetTitle(L"models")
		frame:SetPos(pace.Editor:GetWide(), 0)
		frame:SetSize(pace.Editor:GetWide(), ScrH())
		
		local divider = vgui.Create("DVerticalDivider", frame)
		divider:Dock(FILL)
				
		local top = vgui.Create("DPanelList")
			top:EnableVerticalScrollbar(true)		
		divider:SetTop(top)
		
		local bottom = vgui.Create("DPanelList")
			bottom:Dock(FILL)
			bottom:EnableHorizontal(true)
			bottom:EnableVerticalScrollbar(true)
			bottom:SetSpacing(4, 4)
		divider:SetBottom(bottom)
		
		local function GetParentFolder(str)
			return str:match("(.*/)" .. (".*/"):rep(1)) or ""
		end
	
		local function populate(dir)
			frame:SetTitle(dir)
			
			local a,b = file.Find(dir .. "*", "GAME")
			local files = table.Merge(a or {}, b or {})
			
			if GetParentFolder(dir):find("/", nil, true) then
				local btn = vgui.Create("DButton")
					btn:SetText("..")
					top:AddItem(btn)
				
				function btn:DoClick()
					for k,v in pairs(top:GetItems()) do v:Remove() end
					for k,v in pairs(bottom:GetItems()) do v:Remove() end
					populate(GetParentFolder(dir))
				end
			end
					
			for _, name in pairs(files) do
				if not name:find("%.", nil, true) then
					local btn = vgui.Create("DButton")
					btn:SetText(name)
					top:AddItem(btn)
					
					function btn:DoClick()
						for k,v in pairs(top:GetItems()) do v:Remove() end
						for k,v in pairs(bottom:GetItems()) do v:Remove() end
						populate(dir .. name .. "/")
					end
				end
			end
			
			for _, name in pairs(files) do
				local dir = dir:match("../.-/(.+)")

				if name:find(".mdl", nil, true) then
					local btn = vgui.Create("SpawnIcon")
					btn:SetIconSize(64)
					btn:SetSize(64, 64)
											
					btn:SetModel(dir .. name)
					bottom:AddItem(btn)
					
					function btn.DoClick()
						pace.current_part:SetModel(dir .. name)
					end
				end
				
				-- umm
				
				if name:find(".vmt", nil, true) then
					local image = vgui.Create("DImageButton")
					image:SetSize(64, 64)
					local path = (dir .. name):match("materials/(.-)%.vmt")
					image:SetMaterial(path)
					image:SetTooltip(path)
					bottom:AddItem(image)
					
					function image.DoClick()
						pace.current_part:SetMaterial(path)
					end
				end
									

			end
			
			top:InvalidateLayout(true)
			bottom:InvalidateLayout(true)
		end

		populate("")
		
		pace.ActiveSpecialPanel = frame
	end]]
	
	pace.RegisterPanel(PANEL)
end

do -- material
	local PANEL = {}

	PANEL.ClassName = "properties_material"
	PANEL.Base = "pace_properties_base_type"
		
	function PANEL:SpecialCallback()
		pace.SafeRemoveSpecialPanel()
		
		local pnl = pace.CreatePanel("mat_browser")
		
		SHOW_SPECIAL(pnl, self, 300)
		
		function pnl.MaterialSelected(_, path)
			self:SetValue(path)
			self.OnValueChanged(path)
		end
		
		pace.ActiveSpecialPanel = pnl
	end
	
	pace.RegisterPanel(PANEL)
end

local function create_search_list(property, key, name, add_columns, get_list, get_current, add_line, select_value)
	select_value = select_value or function(val, key) return val end
	pace.SafeRemoveSpecialPanel()
		
	local frame = vgui.Create("DFrame")
	frame:SetTitle(L(name))
	frame:SetSize(300, 300)
	frame:Center()
	frame:SetSizable(true)

	local list = vgui.Create("DListView", frame)
	list:Dock(FILL)
	list:SetMultiSelect(false)
	
	add_columns(list)
	
	list.OnRowSelected = function(_, id, line) 
		local val = select_value(line.list_val, line.list_key)
		
		if property then
			property:SetValue(val)
			property.OnValueChanged(val)
		else
			if pace.current_part:IsValid() and pace.current_part["Set" .. key] then
				pace.Call("VariableChanged", pace.current_part, key, val)
			end
		end
	end
	
	local first = NULL
		
	local function build(find)	
		list:Clear()			
		
		local cur = get_current()
		
		for key, val in pairs(get_list()) do
			if (not find or find == "") or tostring(select_value(val, key)):lower():find(find) then
			
				local pnl = add_line(list, key, val)
				pnl.list_key = key
				pnl.list_val = val
				
				if not first:IsValid() then
					first = pnl
				end
				
				if cur == name then
					list:SelectItem(pnl)
				end
			end
		end
	end
	
	local search = vgui.Create("DTextEntry", frame)
	search:Dock(BOTTOM)
	search.OnTextChanged = function() build(search:GetValue()) end
	search.OnEnter = function() if first:IsValid() then list:SelectItem(first) end frame:Remove() end
	search:RequestFocus()
	frame:MakePopup()
	
	build()
	
	pace.ActiveSpecialPanel = frame
	
	return frame
end

do -- sequence list
	local PANEL = {}

	PANEL.ClassName = "properties_sequence"
	PANEL.Base = "pace_properties_base_type"
		
	function PANEL:SpecialCallback()
		create_search_list(
			self,
			self.CurrentKey,
			"animations", 
			function(list) 	
				list:AddColumn("id"):SetFixedWidth(25)
				list:AddColumn("name") 
			end,
			function() 
				return pace.current_part:GetSequenceList()
			end,
			function()
				return pace.current_part.ClassName == "animation" and pace.current_part:GetSequenceName()
			end,
			function(list, key, val)
				return list:AddLine(key, val)
			end
		)
	end
	
	pace.RegisterPanel(PANEL)
end

do -- pose parameter list
	local PANEL = {}

	PANEL.ClassName = "properties_poseparameter"
	PANEL.Base = "pace_properties_base_type"
		
	function PANEL:SpecialCallback()		
		create_search_list(
			self,
			self.CurrentKey,
			"pose parameters", 
			function(list) 	
				list:AddColumn("id"):SetFixedWidth(25)
				list:AddColumn("name") 
			end,
			function() 
				return pace.current_part:GetPoseParameterList()
			end,
			function()
				return pace.current_part:GetPoseParameter()
			end,
			function(list, key, val)
				return list:AddLine(key, val.name)
			end,
			function(val) 
				return val.name
			end
		)
	end
	
	pace.RegisterPanel(PANEL)
end

do -- event list
	local PANEL = {}

	PANEL.ClassName = "properties_event"
	PANEL.Base = "pace_properties_base_type"
		
	function PANEL:SpecialCallback()	
		local frame = create_search_list(
			self,
			self.CurrentKey,
			"events", 
			function(list) 	
				list:AddColumn("name") 
			end,
			function() 
				return pace.current_part.Events
			end,
			function()
				return pace.current_part.Event
			end,
			function(list, key, val)
				return list:AddLine(L(key:gsub("_", " ")))
			end,
			function(val, key)
				return key
			end
		)
		
		SHOW_SPECIAL(frame, self, 250)
	end
	
	pace.RegisterPanel(PANEL)
end

do -- operator list
	local PANEL = {}

	PANEL.ClassName = "properties_operator"
	PANEL.Base = "pace_properties_base_type"
		
	function PANEL:SpecialCallback()			
		local frame = create_search_list(
			self,
			self.CurrentKey,
			"operators", 
			function(list) 	
				list:AddColumn("name") 
			end,
			function() 
				return pace.current_part.Operators
			end,
			function()
				return pace.current_part.Operator
			end,
			function(list, key, val)
				return list:AddLine(L(val:gsub("_", " ")))
			end,
			function(val, key)
				return val
			end
		)
		
		SHOW_SPECIAL(frame, self, 250)
	end
	
	pace.RegisterPanel(PANEL)
end

do -- arguments
	local PANEL = {}

	PANEL.ClassName = "properties_arguments"
	PANEL.Base = "pace_properties_base_type"
		
	function PANEL:ExtraPopulate()	 
		local data = pace.current_part.Events[pace.current_part.Event]
		data = data and data.arguments
		
		if not data then return end

		local tbl = {}
		local args = {pace.current_part:GetParsedArguments(data)}
		if args then
			for pos, arg in pairs(data) do
				local nam, typ = next(arg)
				if args[pos] then
					arg = args[pos]
				else
					if typ == "string" then
						arg = ""
					elseif typ == "number" then
						arg = 0
					elseif typ == "boolean" then
						arg = false
					end
				end
				tbl[nam] = {val = arg, callback = function(val)
					local args = {pace.current_part:GetParsedArguments(data)}
					args[pos] = val
					pace.current_part:ParseArguments(unpack(args))
					--self:SetValue(pace.current_part.Arguments)
				end}
			end
			pace.properties:Populate(tbl, true, L"arguments")
		end
				
	end
	
	pace.RegisterPanel(PANEL)
end

do -- Proxy Functions
	local PANEL = {}

	PANEL.ClassName = "properties_proxyfunctions"
	PANEL.Base = "pace_properties_base_type"
		
	function PANEL:SpecialCallback()	
		pace.SafeRemoveSpecialPanel()
		 
		local frame = vgui.Create("DFrame")
		frame:SetTitle(L"functions")
		SHOW_SPECIAL(frame, self, 250)
		frame:SetSizable(true)

		local list = vgui.Create("DListView", frame)
		list:Dock(FILL)
		list:SetMultiSelect(false)
		list:AddColumn(L"function")

		list.OnRowSelected = function(_, id, line) 
			self:SetValue(line.event_name)
			self.OnValueChanged(line.event_name)
		end

		for name, _ in pairs(pace.current_part.Functions) do
			local pnl = list:AddLine(L(name))
			pnl.event_name = name
			
			if cur == name then
				list:SelectItem(pnl)
			end
		end
		
		pace.ActiveSpecialPanel = frame
	end
	
	pace.RegisterPanel(PANEL)
end

do -- Proxy Functions
	local PANEL = {}

	PANEL.ClassName = "properties_proxyinputs"
	PANEL.Base = "pace_properties_base_type"
		
	function PANEL:SpecialCallback()			
		local frame = create_search_list(
			self,
			self.CurrentKey,
			"operators", 
			function(list) 	
				list:AddColumn("name") 
			end,
			function() 
				return pace.current_part.Inputs
			end,
			function()
				return pace.current_part.Input
			end,
			function(list, key, val)
				return list:AddLine(L(key))
			end,
			function(val, key)
				return key
			end
		)
	end
	
	pace.RegisterPanel(PANEL)
end

do -- Proxy Variables
	local PANEL = {}

	PANEL.ClassName = "properties_proxyvars"
	PANEL.Base = "pace_properties_base_type"
		
	function PANEL:SpecialCallback()	
		local parent = pace.current_part.Parent
		
		if not parent:IsValid() then return end
		
		pace.SafeRemoveSpecialPanel()
		 
		local frame = vgui.Create("DFrame")
		frame:SetTitle(L"functions")
		SHOW_SPECIAL(frame, self, 250)
		frame:SetSizable(true)

		local list = vgui.Create("DListView", frame)
		list:Dock(FILL)
		list:SetMultiSelect(false)
		list:AddColumn(L"parent variables")

		list.OnRowSelected = function(_, id, line) 
			self:SetValue(line.event_name)
			self.OnValueChanged(line.event_name)
		end

		for key, _ in pairs(parent.StorableVars) do
			if key == "UniqueID" then continue end
			
			local T = type(parent[key])
			if T == "number" or T == "Vector" or T == "Angle" or T == "boolean" then
				local pnl = list:AddLine(L(key:gsub("%u", " %1"):lower()))
				pnl.event_name = key
				
				if cur == key then
					list:SelectItem(pnl)
				end
			end
		end
		
		pace.ActiveSpecialPanel = frame
	end
	
	pace.RegisterPanel(PANEL)
end


do -- bodygroup names
	local PANEL = {}

	PANEL.ClassName = "properties_bodygroupname"
	PANEL.Base = "pace_properties_base_type"
		
	function PANEL:SpecialCallback()	
		pace.SafeRemoveSpecialPanel()
		 
		local frame = vgui.Create("DFrame")
		frame:SetTitle(L"bodygroup names")
		SHOW_SPECIAL(frame, self, 250)
		frame:SetSizable(true)

		local list = vgui.Create("DListView", frame)
		list:Dock(FILL)
		list:SetMultiSelect(false)
		list:AddColumn(L"name")

		list.OnRowSelected = function(_, id, line) 
			self:SetValue(line.name)
			self.OnValueChanged(line.name)
		end

		for _, name in pairs(pace.current_part:GetBodyGroupNameList()) do
			local pnl = list:AddLine(L(name))
			pnl.name = name
			
			if cur == name then
				list:SelectItem(pnl)
			end
		end
		
		pace.ActiveSpecialPanel = frame
	end
	
	pace.RegisterPanel(PANEL)

end

do -- holdtype
	local PANEL = {}

	PANEL.ClassName = "properties_weaponholdtype"
	PANEL.Base = "pace_properties_base_type"
		
	function PANEL:SpecialCallback()	
		local frame = create_search_list(
			self,
			self.CurrentKey,
			L"holdtypes", 
			function(list) 	
				list:AddColumn("name") 
			end,
			function() 
				return pace.current_part.ValidHoldTypes
			end,
			function()
				return pace.current_part.HoldType
			end,
			function(list, key, val)
				return list:AddLine(key)
			end,
			function(val, key)
				return key
			end
		)
		
		pace.ActiveSpecialPanel = frame
	end
	
	pace.RegisterPanel(PANEL)
end

do -- effect
	local PANEL = {}

	PANEL.ClassName = "properties_effect"
	PANEL.Base = "pace_properties_base_type"
		
	function PANEL:SpecialCallback()		
		if not pace.particle_list then
			local found = {}

			for file_name in pairs(LOADED_PARTICLES) do
				local data = file.Read("particles/"..file_name, "GAME", "b")
				for str in data:gmatch("\3%c([%a_]+)%c") do
					found[str] = true
				end
			end

			pace.particle_list = found
		end
		
		local frame = create_search_list(
			self,
			self.CurrentKey,
			L"particle list", 
			function(list) 	
				list:AddColumn("name") 
			end,
			function() 
				return pace.particle_list
			end,
			function()
				return pace.current_part.Effect
			end,
			function(list, key, val)
				return list:AddLine(key)
			end,
			function(val, key)
				return key
			end
		)
	end
	
	pace.RegisterPanel(PANEL)
end

do -- script
	local PANEL = {}

	PANEL.ClassName = "properties_code"
	PANEL.Base = "pace_properties_base_type"
		
	function PANEL:SpecialCallback()	
		pace.SafeRemoveSpecialPanel()
		 
		local frame = vgui.Create("DFrame")
		frame:SetTitle(L"script")
		SHOW_SPECIAL(frame, self, 512)
		frame:SetSizable(true)

		local editor = vgui.Create("pace_luapad", frame)
		editor:Dock(FILL)

		editor:SetText(pace.current_part:GetCode())		
		editor.OnTextChanged = function(self)
			pace.current_part:SetCode(self:GetValue())
		end
		
		editor.last_error = ""
		
		function editor:CheckGlobal(str) 
			local part = pace.current_part
			
			if not part:IsValid() then frame:Remove() return end
						
			return part:ShouldHighlight(str)
		end
		
		function editor:Think()
			local part = pace.current_part
			
			if not part:IsValid() then frame:Remove() return end
						
			local title = L"script editor"
					  
			if part.Error then
				title = part.Error
			
				local line = tonumber(title:match("SCRIPT_ENV:(%d-):"))
				
				if line then
					title = title:match("SCRIPT_ENV:(.+)")
					if self.last_error ~= title then			
						editor:SetScrollPosition(line)							
						editor:SetErrorLine(line)
						self.last_error = title
					end
				end
			else	
				editor:SetErrorLine(nil)
				
				if part.script_printing then
					title = part.script_printing
					part.script_printing = nil
				end
			end
			
			frame:SetTitle(title)
		end
		
		pace.ActiveSpecialPanel = frame
	end
	
	pace.RegisterPanel(PANEL)
end
