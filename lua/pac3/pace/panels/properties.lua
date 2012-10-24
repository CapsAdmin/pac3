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

pace.ActiveSpecialPanel = NULL

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
		self:GetSkin().tex.MenuBG(0, 0, (w or self:GetWide()) + (self.right and -1 or 3), (h or self:GetTall()) + 1)
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
	PANEL.Base = "DHorizontalDivider"

	AccessorFunc(PANEL, "item_height", "ItemHeight")

	function PANEL:Init()
		self.List = {}
		
		DHorizontalDivider.Init(self)

		local left = vgui.Create("DPanelList", self)
			self:SetLeft(left)
		self.left = left

		local right = vgui.Create("DPanelList", self)
			self:SetRight(right)
		self.right = right

		self:SetDividerWidth(2)
		self:SetLeftWidth(110)
		self:SetItemHeight(14)
	end

	function PANEL:GetHeight()
		return (self.item_height * (#self.List + 1)) - (self:GetDividerWidth() + 1)
	end

	function PANEL:FixHeight()
		for key, data in pairs(self.List) do
			data.left:SetTall(self:GetItemHeight())
			data.right:SetTall(self:GetItemHeight())
		end
	end

	function PANEL:AddItem(key, var, pos)
		local btn = pace.CreatePanel("properties_label")
			btn:SetValue(L(key:gsub("%u", " %1"):lower()))
			btn.pac3_sort_pos = pos
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

	function PANEL:Populate(obj)
		self:Clear()

		local tbl = {}
		local data = {}
		
		for key, val in pairs(obj:GetVars()) do
			if not pace.HiddenPropertyKeys[key] or pace.HiddenPropertyKeys[key] == obj.ClassName then
				table.insert(data, {key = key, val = val})
			end
		end
		
		table.sort(data, function(a,b) return a.key > b.key end)
		
		for pos, str in ipairs(pace.PropertyOrder) do
			for i, val in ipairs(data) do
				if val.key == str then
					table.insert(tbl, {pos = pos, key = val.key, val = val.val})
					table.remove(data, i)
				end
			end
		end

		for pos, val in ipairs(data) do
			table.insert(tbl, {pos = pos, key = val.key, val = val.val})
		end
				
		for pos, data in ipairs(tbl) do
			local key, val = data.key, data.val
			
			local pnl
			local T = (pace.TranslatePropertiesKey(key, obj) or type(val)):lower()
			
			if pace.PanelExists("properties_" .. T) then
				pnl = pace.CreatePanel("properties_" .. T)
			end

			if pnl then
				obj.editor_pnl = pnl
				
				local val = obj["Get" .. key](obj)
				pnl:SetValue(val)
				pnl.LimitValue = pace.PropertyLimits[key]
				
				pnl.OnValueChanged = function(val)
					pace.Call("VariableChanged", obj, key, val)
				end
				
				self:AddItem(key, pnl, pos)
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
		
		for pos, str in ipairs(pace.PropertyOrder) do
			for i, val in ipairs(data) do
				if val.key == str then
					table.insert(tbl, {pos = pos, key = val.key, val = val.val, callback = val.callback})
					table.remove(data, i)
				end
			end
		end

		for pos, val in ipairs(data) do
			table.insert(tbl, {pos = pos, key = val.key, val = val.val, callback = val.callback})
		end
				
		for pos, data in ipairs(tbl) do
			local key, val = data.key, data.val

			local pnl
			local T = (pace.TranslatePropertiesKey(key, obj) or type(val)):lower()
			
			if pace.PanelExists("properties_" .. T) then
				pnl = pace.CreatePanel("properties_" .. T)
			end

			if pnl then				
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
	local PANEL = {}

	PANEL.ClassName = "properties_label"
	PANEL.Base = "pace_properties_container"

	function PANEL:SetValue(str)
		local lbl = vgui.Create("DLabel")
			lbl:SetTextColor(derma.Color(net and "text_dark" or "text_bright", self, color_black))
			lbl:SetFont(pace.CurrentFont)
			lbl:SetText("  " .. str) -- ugh
			lbl:SizeToContents()
		self:SetContent(lbl)
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
			btn.DoClick = function() self:SpecialCallback() end
			btn.DoRightClick = self.SpecialCallback2 and function() self:SpecialCallback2() end or btn.DoClick
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
				
				if input.IsKeyDown(KEY_LSHIFT) then
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
				
				if input.IsKeyDown(KEY_LSHIFT) then
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
				
				if input.IsKeyDown(KEY_LSHIFT) then
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
				btn.DoRightClick = self.SpecialCallback2 and function() self:SpecialCallback2() end or btn.DoClick
			end
		end
		
		PANEL.SpecialCallback = special_callback		
		
		function PANEL:Restart()
			self.left:SetValue(0)
			self.middle:SetValue(0)
			self.right:SetValue(0)
			
			self.left:OnValueChanged(0)
			self.middle:OnValueChanged(0)
			self.right:OnValueChanged(0)
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
		
		function PANEL:OnValueChanged()

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
			
			SHOW_SPECIAL(frm, self)
			
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
				self:SetValue(vec)
				self.OnValueChanged(vec)
			end
			
			function clr.Think()
				local clr = clr:GetColor() or Color(255, 255, 255, 255)
				local vec = Vector(clr.r, clr.g, clr.b)
				self.OnValueChanged(vec)
				self:SetValue(vec)
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

	function PANEL:Think()
		if self:IsMouseDown() then			
			local sens = self.sens
			
			if input.IsKeyDown(KEY_LALT) then
				sens = sens / 10
			end
			
			local delta = (self.mousey - gui.MouseY()) / 10
			local val = self.oldval + (delta * sens)
			
			if self.LimitValue then
				val = self:LimitValue(val) or val
			end
			
			val = self:Encode(val)
			self:SetValue(val)
			self.OnValueChanged(tonumber(val))
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
		
		self.chck:SetPos(0, 2)
		self.chck:SetSize(12, 12)

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
		pace.SelectBone(pace.GetViewEntity(), function(data)
			self:SetValue(L(data.friendly))
			self.OnValueChanged(data.friendly)
		end)
	end
	
	function PANEL:SpecialCallback2()
		local ent = pace.GetViewEntity()
		local bones = pac.GetModelBones(ent)
		
		local menu = DermaMenu()
		
		menu:MakePopup()
		
		bones = table.ClearKeys(bones)
		table.sort(bones, function(a,b) return a.friendly > b.friendly end)
		for _, data in ipairs(bones) do
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
		pace.SelectPart(pac.GetParts(), function(part)
			self:SetValue(part:GetName())
			self.OnValueChanged(part)
		end)
	end
	
	function PANEL:SpecialCallback2()
		local menu = DermaMenu()
	
		menu:MakePopup()		
		
		for _, part in pairs(pac.GetParts(true)) do
			menu:AddOption(part:GetName(), function()
				self:SetValue(part:GetName())
				self.OnValueChanged(part)
			end)
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
			self.OnValueChanged(ent:EntIndex())
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
		
		for _, ent in pairs(ents.GetAll()) do
			menu:AddOption(get_friendly_name(ent), function()
				pace.current_part:SetOwnerName(ent:EntIndex())
				self.OnValueChanged(ent:EntIndex())
			end)
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
	end
	
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

do -- sequence list
		local PANEL = {}

	PANEL.ClassName = "properties_sequence"
	PANEL.Base = "pace_properties_base_type"
		
	function PANEL:SpecialCallback()
		pace.SafeRemoveSpecialPanel()
		
		local frame = vgui.Create("DFrame")
		frame:SetTitle(L"animations")
		frame:SetSize(300, 300)
		frame:Center()
		frame:SetSizable(true)

		local list = vgui.Create("DListView", frame)
		list:Dock(FILL)
		list:SetMultiSelect(false)
		list:AddColumn("id"):SetFixedWidth(25)
		list:AddColumn("name")

		list.OnRowSelected = function(_, id, line) 
			self:SetValue(line.seq_name)
			self.OnValueChanged(line.seq_name)
		end

		local cur = pace.current_part:GetSequenceName()
		
		for id, name in pairs(pace.current_part:GetSequenceList()) do
			local pnl = list:AddLine(id, name)
			pnl.seq_name = name
			pnl.seq_id = id
			
			if cur == name then
				list:SelectItem(pnl)
			end
		end
		
		pace.ActiveSpecialPanel = frame
	end
	
	pace.RegisterPanel(PANEL)
end

do -- event list
	local PANEL = {}

	PANEL.ClassName = "properties_event"
	PANEL.Base = "pace_properties_base_type"
		
	function PANEL:SpecialCallback()	
		pace.SafeRemoveSpecialPanel()
		
		local frame = vgui.Create("DFrame")
		frame:SetTitle(L"events")
		SHOW_SPECIAL(frame, self, 250)
		frame:SetSizable(true)

		local list = vgui.Create("DListView", frame)
		list:Dock(FILL)
		list:SetMultiSelect(false)
		list:AddColumn(L"event")

		list.OnRowSelected = function(_, id, line) 
			self:SetValue(line.event_name)
			self.OnValueChanged(line.event_name)
		end

		for name in pairs(pace.current_part.Events) do
			local pnl = list:AddLine(L(name:gsub("_", " ")))
			pnl.event_name = name
			
			if cur == name then
				list:SelectItem(pnl)
			end
		end
		
		pace.ActiveSpecialPanel = frame
	end
	
	pace.RegisterPanel(PANEL)
end

do -- operator list
	local PANEL = {}

	PANEL.ClassName = "properties_operator"
	PANEL.Base = "pace_properties_base_type"
		
	function PANEL:SpecialCallback()	
		pace.SafeRemoveSpecialPanel()
		 
		local frame = vgui.Create("DFrame")
		frame:SetTitle(L"operators")
		SHOW_SPECIAL(frame, self, 250)
		frame:SetSizable(true)

		local list = vgui.Create("DListView", frame)
		list:Dock(FILL)
		list:SetMultiSelect(false)
		list:AddColumn(L"operator")

		list.OnRowSelected = function(_, id, line) 
			self:SetValue(line.event_name)
			self.OnValueChanged(line.event_name)
		end

		for _, name in pairs(pace.current_part.Operators) do
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

do -- arguments
	local PANEL = {}

	PANEL.ClassName = "properties_arguments"
	PANEL.Base = "pace_properties_base_type"
		
	function PANEL:SpecialCallback()
		pace.SafeRemoveSpecialPanel()
		 
		local data = pace.current_part.Events[pace.current_part.Event]
		data = data and data.arguments
		
		if not data then return end
				
		local frame = vgui.Create("DFrame")
		frame:SetTitle(L"arguments")
		SHOW_SPECIAL(frame, self, 250)
		frame:SetSizable(true)
		frame:MakePopup()

		local list = vgui.Create("pace_properties", frame)
		list:Dock(FILL)
			
		local tbl = {}
		local args = {pace.current_part:GetParsedArguments(data)}
		if args then
			for pos, arg in ipairs(data) do
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
					self:SetValue(pace.current_part.Arguments)
				end}
			end
			list:PopulateCustom(tbl)
		end
		
		pace.ActiveSpecialPanel = frame
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
		pace.SafeRemoveSpecialPanel()
		 
		local frame = vgui.Create("DFrame")
		frame:SetTitle(L"functions")
		SHOW_SPECIAL(frame, self, 250)
		frame:SetSizable(true)

		local list = vgui.Create("DListView", frame)
		list:Dock(FILL)
		list:SetMultiSelect(false)
		list:AddColumn(L"input")

		list.OnRowSelected = function(_, id, line) 
			self:SetValue(line.event_name)
			self.OnValueChanged(line.event_name)
		end

		for name, _ in pairs(pace.current_part.Inputs) do
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
			if T == "number" or T == "Vector" or T == "Angle" then
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