local L = pace.LanguageString

local languageID = CreateClientConVar("pac_editor_languageid", 1, true, false, "Whether we should show the language indicator inside of editable text entries.")

function pace.ShowSpecial(pnl, parent, size)
	size = size or 150

	pnl:SetPos(pace.Editor:GetWide(), select(2, parent:LocalToScreen()) - size + 25)
	pnl:SetSize(size, size)
	pnl:MakePopup()
end

function pace.FixMenu(menu)
	menu:SetMaxHeight(500)
	menu:InvalidateLayout(true, true)
	menu:SetPos(pace.Editor:GetPos() + pace.Editor:GetWide(), gui.MouseY() - (menu:GetTall() * 0.5))
end

local function DefineMoreOptionsLeftClick(self, callFuncLeft, callFuncRight)
	local btn = vgui.Create("DButton", self)
	btn:SetSize(16, 16)
	btn:Dock(RIGHT)
	btn:SetText("...")
	btn.DoClick = function() callFuncLeft(self, self.CurrentKey) end

	if callFuncRight then
		btn.DoRightClick = function() callFuncRight(self, self.CurrentKey) end
	else
		btn.DoRightClick = btn.DoClick
	end

	if self.OnMoreOptionsLeftClickButton then
		self:OnMoreOptionsLeftClickButton(btn)
	end

	return btn
end

function pace.CreateSearchList(property, key, name, add_columns, get_list, get_current, add_line, select_value, select_value_search)
	select_value = select_value or function(val, key) return val end
	select_value_search = select_value_search or select_value
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

		if property and property:IsValid() then
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
		local newList = {}

		for k, v in pairs(get_list()) do
			table.insert(newList, {k, v, tostring(k), tostring(v)})
		end

		table.sort(newList, function(a, b) return a[1] < b[1] end)
		if find then find = find:lower() end

		for i, data in ipairs(newList) do
			local key, val, keyFriendly, valFriendly = data[1], data[2], data[3], data[4]
			if (not find or find == "") or tostring(select_value_search(valFriendly, keyFriendly)):lower():find(find, nil, true) then

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

pace.ActiveSpecialPanel = NULL
pace.extra_populates = {}

function pace.SafeRemoveSpecialPanel()
	if pace.ActiveSpecialPanel:IsValid() then
		pace.ActiveSpecialPanel:Remove()
	end
end

pac.AddHook("GUIMousePressed", "pace_SafeRemoveSpecialPanel", function()
	local pnl = pace.ActiveSpecialPanel
	if pnl:IsValid() then
		local x,y = input.GetCursorPos()
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
		--surface.SetDrawColor(255, 255, 255, 255)
		--surface.DrawRect(0,0,w,h)
		--self:GetSkin().tex.CategoryList.Outer(0, 0, w, h)

		--self:GetSkin().tex.MenuBG(0, 0, w + (self.right and -1 or 3), h + 1)

		if not self.right then
			--surface.SetDrawColor(self:GetSkin().Colours.Properties.Border)
			--surface.DrawRect(0,0,w+5,h)
		else
			--surface.SetDrawColor(self:GetSkin().Colours.Properties.Border)
			--surface.DrawRect(0,0,w,h)
		end

		self.AltLine = self.alt_line
		derma.SkinHook( "Paint", "CategoryButton", self, w, h )
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

		local search = vgui.Create("DTextEntry", self)
		search:Dock(TOP)
		search.Kill = function()
			search:SetVisible(false)
			search.searched_something = false
			search:SetText("")
			search:SetEnabled(false)

			for i,v in ipairs(self.List) do
				v.left:SetVisible(true)
				v.right:SetVisible(true)
			end
		end

		search.OnEnter = search.Kill

		search.OnTextChanged = function()
			self.scr:SetScroll(0)

			local pattern = search:GetValue()
			if pattern == "" and search.searched_something then
				search:Kill()
				search:KillFocus()
				pace.Editor:KillFocus()
				pace.Editor:MakePopup()
			else
				search.searched_something = true
				local group

				for i,v in ipairs(self.List) do
					local found = false

					if v.panel then
						if v.panel:GetText():find(pattern) then
							found = true
						end

						if v.left:GetValue():find(pattern) then
							found = true
						end
					elseif v.left and v.left.text then
						group = v.left.text
					end

					if group and group:find(pattern) then
						found = true
					end

					if not found and v.panel then
						v.left:SetVisible(false)
						v.right:SetVisible(false)
					end
				end

				for i,v in ipairs(self.List) do
					if not v.panel then
						local hide_group = true

						for i = i+1, #self.List do
							local val = self.List[i]
							if not val.panel then
								break
							end

							if val.left:IsVisible() then
								hide_group = false
								break
							end
						end

						if hide_group then
							v.left:SetVisible(false)
							v.right:SetVisible(false)
						end
					end
				end
			end
		end
		search:SetVisible(false)
		self.search = search

		self.List = {}

		local divider = vgui.Create("DHorizontalDivider", self)

		local left = vgui.Create("DPanelList", divider)
			divider:SetLeft(left)
		self.left = left

		local right = vgui.Create("DPanelList", divider)
			divider:SetRight(right)
		self.right = right

		divider:SetDividerWidth(3)

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

	function PANEL:GetHeight(hack)
		return (self.item_height * (#self.List+(hack or 1))) - (self.div:GetDividerWidth() + 1)
	end

	function PANEL:PerformLayout()
		self.scr:SetSize(10, self:GetHeight())
		self.scr:SetUp(self:GetTall(), self:GetHeight() - 10)
		self.search:SetZPos(1)
		self.div:SetPos(0, (self.search:IsVisible() and self.search:GetTall() or 0) + self.scr:GetOffset())
		local w, h = self:GetSize()
		local scroll_width = self.scr.Enabled and self.scr:GetWide() or 0
		self.div:SetLeftWidth((w/2) - scroll_width)
		self.div:SetSize(w - scroll_width, self:GetHeight())
	end

	function PANEL:Paint(w, h)
		self:GetSkin().tex.CategoryList.Outer(0, 0, w, h)
	end

	pace.CollapsedProperties = pace.luadata.ReadFile("pac3_editor/collapsed.txt") or {}

	function PANEL:AddCollapser(name)
		assert(name)
		for i,v in ipairs(self.List) do
			if v.group == name then
				return
			end
		end

		local left = vgui.Create("DButton", self)
		left:SetTall(self:GetItemHeight())
		left:SetText("")
		left.text = name

		self.left:AddItem(left)

		left.DoClick = function()
			pace.CollapsedProperties[name] = not pace.CollapsedProperties[name]
			pace.PopulateProperties(pace.current_part)

			pace.Editor:InvalidateLayout()
			pace.luadata.WriteFile("pac3_editor/collapsed.txt", pace.CollapsedProperties)
		end

		left.GetValue = function() return name end

		local right = vgui.Create("DButton", self)
		right:SetTall(self:GetItemHeight())
		right:SetText("")
		self.right:AddItem(right)

		right.DoClick = left.DoClick

		left.Paint = function(_, w, h)
			--surface.SetDrawColor(left:GetSkin().Colours.Category.Header)
			--surface.DrawRect(0,0,w*2,h)
			left:GetSkin().tex.CategoryList.Header( 0, 0, w*2, h )

			surface.SetFont(pace.CurrentFont)

			local txt = L(name)
			local _, _h = surface.GetTextSize(txt)
			local middle = h/2 - _h/2

			--surface.SetTextPos(11, middle)
			--surface.SetTextColor(derma.Color("text_dark", self, color_black))
			--surface.SetFont(pace.CurrentFont)
			--surface.DrawText(txt)
			draw.TextShadow({text = txt, font = pace.CurrentFont, pos = {11, middle}, color = left:GetSkin().Colours.Category.Header}, 1, 100)

			local txt = (pace.CollapsedProperties[name] and "+" or "-")
			local w = surface.GetTextSize(txt)
			draw.TextShadow({text = txt, font = pace.CurrentFont, pos = {6-w*0.5, middle}, color = left:GetSkin().Colours.Category.Header}, 1, 100)

		end

		right.Paint = function(_,w,h)
			left:GetSkin().tex.CategoryList.Header(-w,0,w*2,h)
		end

		table.insert(self.List, {left = left, right = right, panel = var, key = key, group = name})

		return #self.List
	end

	function PANEL:AddKeyValue(key, var, pos, obj, udata, group)
		local btn = pace.CreatePanel("properties_label")
			btn:SetTall(self:GetItemHeight())

			do
				local key = key
				if key:EndsWith("UID") then
					key = key:sub(1, -4)
				end

				btn:SetValue(L((udata and udata.editor_friendly or key):gsub("%u", " %1"):lower()):Trim())
			end

			if obj then
				btn.key_name = key
				btn.part_namepart_name = obj.ClassName
			end



		local pnl = pace.CreatePanel("properties_container")
		pnl:SetTall(self:GetItemHeight())
		pnl.right = true
		pnl.alt_line = #self.List%2 == 1
		btn.alt_line = pnl.alt_line

		if ispanel(var) then
			pnl:SetContent(var)
		end

		self.left:AddItem(btn)
		self.right:AddItem(pnl)

		local pos

		if group then
			for i, v in ipairs(self.List) do
				if v.group == group then
					for i = i + 1, #self.List do
						local v = self.List[i]
						if v.group or not v then
							pos = i
							break
						end
					end
				end
			end
		end

		if pos then
			table.insert(self.left.Items, pos, table.remove(self.left.Items))
			table.insert(self.right.Items, pos, table.remove(self.right.Items))

			table.insert(self.List, pos, {left = btn, right = pnl, panel = var, key = key})
		else
			table.insert(self.List, {left = btn, right = pnl, panel = var, key = key})
		end
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

	local function FlatListToGroups(list)
		local temp = {}

		for _, prop in ipairs(list) do
			if prop.udata.hidden then continue end

			local group = prop.udata.group or "generic"
			temp[group] = temp[group] or {}
			table.insert(temp[group], prop)
		end

		return temp
	end

	local function SortGroups(groups)
		local out = {}

		local temp = {}
		table.Add(temp, pac.GroupOrder[pace.current_part.ClassName] or {})
		table.Add(temp, pac.GroupOrder.none)
		local done = {}
		for i, name in ipairs(temp) do
			for group, props in pairs(groups) do
				if group == name then
					if not done[group] then
						table.insert(out, {group = group, props = props})
						done[group] = true
					end
				end
			end
		end

		for group, props in pairs(groups) do
			if not done[group] then
				table.insert(out, {group = group, props = props})
			end
		end

		return out
	end

	function PANEL:Populate(flat_list)
		self:Clear()

		for _, data in ipairs(SortGroups(FlatListToGroups(flat_list))) do
			self:AddCollapser(data.group or "generic")
			for pos, prop in ipairs(data.props) do

				if prop.udata and prop.udata.hide_in_editor then
					continue
				end

				local val = prop.get()
				local T = type(val):lower()

				if prop.udata and prop.udata.editor_panel then
					T = prop.udata.editor_panel or T
				elseif pace.PanelExists("properties_" .. prop.key:lower()) then
					T = prop.key:lower()
				elseif not pace.PanelExists("properties_" .. T) then
					T = "string"
				end

				if pace.CollapsedProperties[prop.udata.group] ~= nil and pace.CollapsedProperties[prop.udata.group] then goto CONTINUE end

				local pnl = pace.CreatePanel("properties_" .. T)

				if pnl.PostInit then
					pnl:PostInit()
				end

				if prop.udata and prop.udata.description then
					pnl:SetTooltip(L(prop.udata.description))
				end

				local part = pace.current_part
				part.pace_properties = part.pace_properties or {}
				part.pace_properties[prop.key] = pnl
				pnl.part = part
				pnl.udata = prop.udata

				if prop.udata.enums then
					DefineMoreOptionsLeftClick(pnl, function(self)
						pace.CreateSearchList(
							self,
							self.CurrentKey,
							L(prop.key),

							function(list)
								list:AddColumn("enum")
							end,

							function()
								local tbl

								if isfunction(prop.udata.enums) then
									if pace.current_part:IsValid() then
										tbl = prop.udata.enums(pace.current_part)
									end
								else
									tbl = prop.udata.enums
								end

								local enums = {}

								if tbl then
									for k, v in pairs(tbl) do
										if not isstring(v) then
											v = k
										end

										if not isstring(k) then
											k = v
										end

										enums[k] = v
									end
								end

								return enums
							end,

							function()
								return pace.current_part[prop.key]
							end,

							function(list, key, val)
								return list:AddLine(key)
							end,

							function(val, key)
								return val
							end
						)
					end)
				end
				if prop.udata.editor_sensitivity or prop.udata.editor_clamp or prop.udata.editor_round then
					pnl.LimitValue = function(self, num)
						if prop.udata.editor_sensitivity then
							self.sens = prop.udata.editor_sensitivity
						end
						if prop.udata.editor_clamp then
							num = math.Clamp(num, unpack(prop.udata.editor_clamp))
						end
						if prop.udata.editor_round then
							num = math.Round(num)
						end
						return num
					end
				elseif prop.udata.editor_onchange then
					pnl.LimitValue = prop.udata.editor_onchange
				end

				pnl.CurrentKey = prop.key

				if pnl.ExtraPopulate then
					table.insert(pace.extra_populates, {pnl = pnl, func = pnl.ExtraPopulate})
					pnl:Remove()
					goto CONTINUE
				end

				pnl:SetValue(val)

				pnl.OnValueChanged = function(val)
					if T == "number" then
						val = tonumber(val) or 0
					elseif T == "string" then
						val = tostring(val)
					end

					pace.Call("VariableChanged", pace.current_part, prop.key, val)
				end

				self:AddKeyValue(prop.key, pnl, pos, flat_list, prop.udata)

				::CONTINUE::
			end
		end
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

				if (  not IsValid( self.TargetPanel ) ) then
					self:Remove()
					return;
				end

				self:PerformLayout()

				local x, y      = input.GetCursorPos()
				local w, h      = self:GetSize()

				local lx, ly    = self.TargetPanel:LocalToScreen( 0, 0 )

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
			lbl:SetTextColor(self.alt_line and self:GetSkin().Colours.Category.AltLine.Text or self:GetSkin().Colours.Category.Line.Text)
			lbl:SetFont(pace.CurrentFont)
			lbl:SetText(str)
			lbl:SetTextInset(10, 0)
			lbl:SizeToContents()
			lbl.pac_tooltip_hack = true
			self.lbl = lbl
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

	function PANEL:GetValue()
		return self.lbl:GetValue()
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

	function PANEL:OnValueChanged()

	end

	function PANEL:Init(...)
		if DLabel and DLabel.Init then
			local status = DLabel.Init(self, ...)
			self:SetText('')
			self:SetMouseInputEnabled(true)
			return status
		end

		return status
	end

	function PANEL:PostInit()
		if self.MoreOptionsLeftClick then
			self:DefineMoreOptionsLeftClick(self.MoreOptionsLeftClick, self.MoreOptionsRightClick)
		end
	end

	function PANEL:DefineMoreOptionsLeftClick(callFuncLeft, callFuncRight)
		return DefineMoreOptionsLeftClick(self, callFuncLeft, callFuncRight)
	end

	function PANEL:SetValue(var, skip_encode)
		if self.editing then return end

		local value = skip_encode and var or self:Encode(var)
		if isnumber(value) then
			-- visually round numbers so 0.6 doesn't show up as 0.600000000001231231 on wear
			value = math.Round(value, 7)
		end
		local str = tostring(value)

		self:SetTextColor(self.alt_line and self:GetSkin().Colours.Category.AltLine.Text or self:GetSkin().Colours.Category.Line.Text)
		self:SetFont(pace.CurrentFont)
		self:SetText("  " .. str) -- ugh
		self:SizeToContents()

		if #str > 10 then
			self:SetTooltip(str)
		else
			self:SetTooltip()
		end

		self.original_str = str
		self.original_var = var

		if self.OnValueSet then
			self:OnValueSet(var)
		end
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
			--  self:Restart()
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

		if mcode == MOUSE_RIGHT then
			local menu = DermaMenu()
			menu:SetPos(input.GetCursorPos())
			menu:MakePopup()
			self:PopulateContextMenu(menu)
		end
	end

	function PANEL:PopulateContextMenu(menu)
		menu:AddOption(L"copy", function()
			pace.clipboard = pac.CopyValue(self:GetValue())
		end):SetImage(pace.MiscIcons.copy)
		menu:AddOption(L"paste", function()
			self:SetValue(pac.CopyValue(pace.clipboard))
			self.OnValueChanged(self:GetValue())
		end):SetImage(pace.MiscIcons.paste)

		--left right swap available on strings (and parts)
		if type(self:GetValue()) == 'string' then
			menu:AddSpacer()
			menu:AddOption(L"change sides", function()
				local var
				local part
				if self.udata and self.udata.editor_panel == "part" then
					part = pac.GetPartFromUniqueID(pac.Hash(pac.LocalPlayer), self:GetValue())
					var = part:IsValid() and part:GetName()
				else
					var = self:GetValue()
				end

				local var_flip
				if string.match(var, "left") != nil then
					var_flip = string.gsub(var,"left","right")
				elseif string.match(var, "right") != nil then
					var_flip = string.gsub(var,"right","left")
				end

				if self.udata and self.udata.editor_panel == "part" then
					local target = pac.FindPartByName(pac.Hash(pac.LocalPlayer), var_flip or var, pace.current_part)
					self:SetValue(target or part)
					self.OnValueChanged(target or part)
				else
                self:SetValue(var_flip or var)
                self.OnValueChanged(var_flip or var)
            end
		end):SetImage("icon16/arrow_switch.png")

		--numeric sign flip available on numbers
		elseif type(self:GetValue()) == 'number' then
			menu:AddSpacer()
			menu:AddOption(L"flip sign (+/-)", function()
				local val = self:GetValue()
				self:SetValue(-val)
				self.OnValueChanged(self:GetValue())
			end):SetImage("icon16/arrow_switch.png")
		end

		menu:AddSpacer()
		menu:AddOption(L"reset", function()
			if pace.current_part and pace.current_part.DefaultVars[self.CurrentKey] then
				local val = pac.CopyValue(pace.current_part.DefaultVars[self.CurrentKey])
				self:SetValue(val)
				self.OnValueChanged(val)
			end
		end):SetImage(pace.MiscIcons.clear)
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

	function PANEL:EncodeEdit(str)
		return str
	end

	function PANEL:DecodeEdit(str)
		return str
	end

	function PANEL:EditText()
		local oldText = self:GetText()
		self:SetText("")

		local pnl = vgui.Create("DTextEntry")
		self.editing = pnl
		pnl:SetFont(pace.CurrentFont)
		pnl:SetDrawBackground(false)
		pnl:SetDrawBorder(false)
		pnl:SetText(self:EncodeEdit(self.original_str or ""))
		pnl:SetKeyboardInputEnabled(true)
		pnl:SetDrawLanguageID(languageID:GetBool())
		pnl:RequestFocus()
		pnl:SelectAllOnFocus(true)

		pnl.OnTextChanged = function() oldText = pnl:GetText() end

		local hookID = tostring({})
		local textEntry = pnl
		local delay = os.clock() + 0.1

		pac.AddHook('Think', hookID, function(code)
			if not IsValid(self) or not IsValid(textEntry) then return pac.RemoveHook('Think', hookID) end
			if textEntry:IsHovered() or self:IsHovered() then return end
			if delay > os.clock() then return end
			if not input.IsMouseDown(MOUSE_LEFT) and not input.IsKeyDown(KEY_ESCAPE) then return end
			pac.RemoveHook('Think', hookID)
			self.editing = false
			pace.BusyWithProperties = NULL
			textEntry:Remove()
			self:SetText(oldText)
			pnl:OnEnter()
		end)

		--local x,y = pnl:GetPos()
		--pnl:SetPos(x+3,y-4)
		--pnl:Dock(FILL)
		local x, y = self:LocalToScreen()
		local inset_x = self:GetTextInset()
		pnl:SetPos(x+5 + inset_x, y)
		pnl:SetSize(self:GetSize())
		pnl:SetWide(ScrW())
		pnl:MakePopup()

		pnl.OnEnter = function()
			pace.BusyWithProperties = NULL
			self.editing = false

			pnl:Remove()

			self:SetText(tostring(self:Encode(self:DecodeEdit(pnl:GetText() or ""))), true)
			self.OnValueChanged(self:Decode(self:GetText()))
		end

		local old = pnl.Paint
		pnl.Paint = function(...)
			if not self:IsValid() then pnl:Remove() return end

			surface.SetFont(pnl:GetFont())
			local w = surface.GetTextSize(pnl:GetText()) + 6

			surface.DrawRect(0, 0, w, pnl:GetTall())
			surface.SetDrawColor(self:GetSkin().Colours.Properties.Border)
			surface.DrawOutlinedRect(0, 0, w, pnl:GetTall())

			pnl:SetWide(w)

			old(...)
		end

		pace.BusyWithProperties = pnl
	end

	pace.BusyWithProperties = NULL

	local function click()
		if not input.IsMouseDown(MOUSE_LEFT) then return end
		local pnl = pace.BusyWithProperties
		if pnl and pnl ~= true and pnl:IsValid() then
			local x, y = input.GetCursorPos()
			local _x, _y = pnl:GetParent():LocalToScreen()
			if x < _x or y < _y or x > _x + pnl:GetParent():GetWide() or y > _y + pnl:GetParent():GetTall() then
				pnl:OnEnter()
			end
		end
	end

	pac.AddHook("GUIMousePressed", "pace_property_text_edit", click)
	pac.AddHook("VGUIMousePressed", "pace_property_text_edit", click)

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

		PANEL.vector_type = type

		function PANEL:Init(...)
			self.vector = ctor(0,0,0)

			local left = pace.CreatePanel("properties_number", self)
			local middle = pace.CreatePanel("properties_number", self)
			local right = pace.CreatePanel("properties_number", self)

			left.PopulateContextMenu = function(_, menu) self:PopulateContextMenu(menu) end
			middle.PopulateContextMenu = function(_, menu) self:PopulateContextMenu(menu) end
			right.PopulateContextMenu = function(_, menu) self:PopulateContextMenu(menu) end

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

			local function on_change(arg1, arg2, arg3)
				local restart = 0

				return function(num)
					self.vector[arg1] = num

					if input.IsKeyDown(KEY_R) then
						self:Restart()
						restart = os.clock() + 0.1
					elseif input.IsKeyDown(KEY_LSHIFT) then
						middle:SetValue(num)
						self.vector[arg2] = num

						right:SetValue(num)
						self.vector[arg3] = num
					end

					if restart > os.clock() then
						self:Restart()
						return
					end

					self.OnValueChanged(self.vector * 1)
					self:InvalidateLayout()

					if self.OnValueSet then
						self:OnValueSet(self.vector * 1)
					end
				end
			end

			left:SetMouseInputEnabled(true)
			left.OnValueChanged = on_change(arg1, arg2, arg3)

			middle:SetMouseInputEnabled(true)
			middle.OnValueChanged = on_change(arg2, arg1, arg3)

			right:SetMouseInputEnabled(true)
			right.OnValueChanged = on_change(arg3, arg2, arg1)

			self.left = left
			self.middle = middle
			self.right = right

			if self.MoreOptionsLeftClick then
				local btn = vgui.Create("DButton", self)
				btn:SetSize(16, 16)
				btn:Dock(RIGHT)
				btn:SetText("...")
				btn.DoClick = function() self:MoreOptionsLeftClick(self.CurrentKey) end
				btn.DoRightClick = self.MoreOptionsRightClick and function() self:MoreOptionsRightClick(self.CurrentKey) end or btn.DoClick

				if type == "color" or type == "color2" then
					btn:SetText("")
					btn.Paint = function(_,w,h)
						if type == "color2" then
							surface.SetDrawColor(self.vector.x*255, self.vector.y*255, self.vector.z*255, 255)
						else
							surface.SetDrawColor(self.vector.x, self.vector.y, self.vector.z, 255)
						end
						surface.DrawRect(0,0,w,h)
						surface.SetDrawColor(self:GetSkin().Colours.Properties.Border)
						surface.DrawOutlinedRect(0,0,w,h)
					end
				end
			end

			self.Paint = function() end
		end

		PANEL.MoreOptionsLeftClick = special_callback

		function PANEL:Restart()
			if pace.current_part and pace.current_part.DefaultVars[self.CurrentKey] then
				self.vector = pac.CopyValue(pace.current_part.DefaultVars[self.CurrentKey])
			else
				self.vector = ctor(0,0,0)
			end

			self.left:SetValue(self.vector[arg1])
			self.middle:SetValue(self.vector[arg2])
			self.right:SetValue(self.vector[arg3])

			self.OnValueChanged(self.vector * 1)
		end

		function PANEL:PopulateContextMenu(menu)
			menu:AddOption(L"copy", function()
				pace.clipboard = pac.CopyValue(self.vector)
			end):SetImage(pace.MiscIcons.copy)
			menu:AddOption(L"paste", function()
				local val = pac.CopyValue(pace.clipboard)
				if isnumber(val) then
					val = ctor(val, val, val)
				elseif isvector(val) and type == "angle" then
					val = ctor(val.x, val.y, val.z)
				elseif isangle(val) and type == "vector" then
					val = ctor(val.p, val.y, val.r)
				end

				if _G.type(val):lower() == type or type == "color" then
					self:SetValue(val)

					self.OnValueChanged(self.vector * 1)
				end
			end):SetImage(pace.MiscIcons.paste)
			menu:AddSpacer()
			menu:AddOption(L"reset", function()
				if pace.current_part and pace.current_part.DefaultVars[self.CurrentKey] then
					local val = pac.CopyValue(pace.current_part.DefaultVars[self.CurrentKey])
					self:SetValue(val)
					self.OnValueChanged(val)
				end
			end):SetImage(pace.MiscIcons.clear)
		end

		function PANEL:SetValue(vec)
			self.vector = vec * 1

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

	local function tohex(vec, color2)
		return color2 and ("#%.2X%.2X%.2X"):format(vec.x * 255, vec.y * 255, vec.z * 255) or ("#%.2X%.2X%.2X"):format(vec.x, vec.y, vec.z)
	end

	local function fromhex(str)
		local r, g, b

		if #str <= 4 then -- Supports "#xxx" and "xxx"
			r, g, b = str:match("#?(.)(.)(.)")

			if r and g and b then
				r, g, b = r .. r, g .. g, b .. b
			end
		elseif #str <= 7 then -- Supports "#xxxxxx" and "xxxxxx"
			r, g, b = str:match("#?(..)(..)(..)")
		end

		if r and g and b then
			return Color(tonumber(r, 16) or 255, tonumber(g, 16) or 255, tonumber(b, 16) or 255)
		end
	end

	local function fromColorStr(str)
		local r1, g1, b1 = str:match("([0-9]+), *([0-9]+), *([0-9]+)")
		local r2, g2, b2 = str:match("([0-9]+) +([0-9]+) +([0-9]+)")

		if r1 and g1 and b1 then
			return Color(tonumber(r1) or 255, tonumber(g1) or 255, tonumber(b1) or 255)
		elseif r2 and g2 and b2 then
			return Color(tonumber(r2) or 255, tonumber(g2) or 255, tonumber(b2) or 255)
		end
	end

	local function uncodeValue(valIn)
		local fromHex = fromhex(valIn)
		local fromShareXColorStr = fromColorStr(valIn)

		return fromHex or fromShareXColorStr
	end

	VECTOR(Vector, "color", "x", "y", "z",
		function(self, num) -- this function needs second argument
			local pnum = tonumber(num)

			if not pnum then
				local uncode = uncodeValue(num)

				if uncode then
					timer.Simple(0, function()
						local parent = self:GetParent()
						parent.left:SetValue(uncode.r, true)
						parent.middle:SetValue(uncode.g, true)
						parent.right:SetValue(uncode.b, true)

						parent.left.OnValueChanged(uncode.r)
						parent.middle.OnValueChanged(uncode.g)
						parent.right.OnValueChanged(uncode.b)
					end)

					return '0'
				end

				return '0'
			end

			return tostring(math.Clamp(math.Round(pnum or 0), 0, 255))
		end,

		function(self)
			pace.SafeRemoveSpecialPanel()

			local dlibbased = vgui.GetControlTable("DLibColorMixer")

			local frm = vgui.Create("DFrame")
			frm:SetTitle("Color")

			pace.ShowSpecial(frm, self, 300)

			if dlibbased then
				frm:SetWide(500)
			end

			local clr = vgui.Create(dlibbased and "DLibColorMixer" or "DColorMixer", frm)
			clr:Dock(FILL)
			clr:SetAlphaBar(false) -- Alpha isn't needed
			clr:SetColor(Color(self.vector.x, self.vector.y, self.vector.z))

			local html_color

			if not dlibbased then
				html_color = vgui.Create("DTextEntry", frm)
				html_color:Dock(BOTTOM)
				html_color:SetText(tohex(self.vector))

				html_color.OnEnter = function()
					local valGet = uncodeValue(html_color:GetValue())

					if valGet then
						clr:SetColor(valGet)
					end
				end
			end

			function clr.ValueChanged(_, newColor) -- Only update values when the Color mixer value changes
				local vec = Vector(newColor.r, newColor.g, newColor.b)
				self.OnValueChanged(vec)
				self:SetValue(vec)

				if not dlibbased then
					html_color:SetText(tohex(vec))
				end
			end

			pace.ActiveSpecialPanel = frm
		end,
		10
	)

	VECTOR(Vector, "color2", "x", "y", "z",
		function(_, num)
			num = tonumber(num) or 0

			if input.IsKeyDown(KEY_LCONTROL) then
				num = math.Round(num)
			end

			return tostring(num)
		end,

		function(self)
			pace.SafeRemoveSpecialPanel()

			local dlibbased = vgui.GetControlTable("DLibColorMixer")

			local frm = vgui.Create("DFrame")
			frm:SetTitle("color")

			pace.ShowSpecial(frm, self, 300)

			if dlibbased then
				frm:SetWide(500)
			end

			local clr = vgui.Create(dlibbased and "DLibColorMixer" or "DColorMixer", frm)
			clr:Dock(FILL)
			clr:SetAlphaBar(false)
			clr:SetColor(Color(self.vector.x * 255, self.vector.y * 255, self.vector.z * 255))

			local html_color

			if not dlibbased then
				html_color = vgui.Create("DTextEntry", frm)
				html_color:Dock(BOTTOM)
				html_color:SetText(tohex(self.vector, true))
				html_color.OnEnter = function()
					local col = uncodeValue(html_color:GetValue())
					if col then
						local vec = col:ToVector()
						clr:SetColor(col)
						self.OnValueChanged(vec)
						self:SetValue(vec)
					end
				end
			end

			function clr.ValueChanged(_, newcolor)
				local vec = Vector(newcolor.r / 255, newcolor.g / 255, newcolor.b / 255)
				self.OnValueChanged(vec)
				self:SetValue(vec)

				if not dlibbased then
					html_color:SetText(tohex(vec, true))
				end
			end

			pace.ActiveSpecialPanel = frm
		end,
		0.25
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
		local val = self:GetValue() + (delta * self.sens)

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

			if input.IsKeyDown(KEY_R) then
				if pace.current_part and pace.current_part.DefaultVars[self.CurrentKey] then
					val = pace.current_part.DefaultVars[self.CurrentKey]
				end
			end

			self:SetNumberValue(val)

			if gui.MouseY()+1 >= ScrH() then
				self.mousey = 0
				self.oldval = val
				input.SetCursorPos(gui.MouseX(), 0)
			elseif gui.MouseY() <= 0 then
				self.mousey = ScrH()
				self.oldval = val
				input.SetCursorPos(gui.MouseX(), ScrH())
			end
		end
	end

	function PANEL:Encode(num)
		if not tonumber(num) then
			local ok, res = pac.CompileExpression(num)
			if ok then
				num = res() or 0
			end
		end

		num = tonumber(num) or 0

		if self:IsMouseDown() then
			if input.IsKeyDown(KEY_LCONTROL) then
				num = math.Round(num)
			elseif input.IsKeyDown(KEY_PAD_MINUS) or input.IsKeyDown(KEY_MINUS) then
				num = -num
			end


			if input.IsKeyDown(KEY_LALT) then
				num = math.Round(num, 5)
			else
				num = math.Round(num, 3)
			end
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
			if self.during_change then return end
			local b = chck:GetChecked()
			self.OnValueChanged(b)
			self.lbl:SetText(L(tostring(b)))
		end
		self.chck = chck

		local lbl = vgui.Create("DLabel", self)
		lbl:SetFont(pace.CurrentFont)
		lbl:SetTextColor(self.alt_line and self:GetSkin().Colours.Category.AltLine.Text or self:GetSkin().Colours.Category.Line.Text)
		self.lbl = lbl
	end

	function PANEL:Paint() end

	function PANEL:SetValue(b)
		self.during_change = true
		self.chck:SetChecked(b)
		self.chck:Toggle()
		self.chck:Toggle()
		self.lbl:SetText(L(tostring(b)))
		self.during_change = false
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
