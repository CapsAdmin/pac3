local L = pace.LanguageString

pace.HiddenProperties =
{
	Arguments = true,
}

pace.PropertyLimits = 
{
	Sequence = function(self, num)
		num = tonumber(num)
		return math.Round(math.min(num, -1))
	end,
	
	Skin = function(self, num)
		num = tonumber(num)
		return math.Round(math.max(num, 0))
	end,
	Bodygroup = function(self, num)
		num = tonumber(num)
		return math.Round(math.max(num, 0))
	end,
	BodygroupState = function(self, num)
		num = tonumber(num)
		return math.Round(math.max(num, 0))
	end,
	
	Size = function(self, num)
		self.sens = 0.25
		
		return num
	end,
	
	Alpha = function(self, num)
		self.sens = 0.25
		num = tonumber(num)
		return math.Clamp(num, 0, 1)
	end,
	OutlineAlpha = function(self, num)
		self.sens = 0.25
		num = tonumber(num)
		return math.Clamp(num, 0, 1)
	end,
}

function pace.TranslatePropertiesKey(key)					
	key = key:lower()
	
	if key == "bone" then
		return key
	end
	
	if key == "model" then
		return key
	end
	
	if key == "event" then
		return key
	end
	
	if key == "operator" then
		return key
	end	
	
	if key == "arguments" then
		return key
	end	
	
	if key == "ownername" then
		return key
	end	
	
	if key == "aimpartname" or key == "parentname" then
		return "part"
	end
	
	if key == "sequence" or key == "sequencename" then
		return "sequence"
	end
	
	if key == "material" or key == "spritepath" or key == "trailpath" then
		return "material"
	end	

	if key:find("color") then
		return "color"
	end
end

do -- container
	local PANEL = {}

	PANEL.ClassName = "properties_container"
	PANEL.Base = "DPanel"

	function PANEL:Paint(w, h)
		if net then
			self:GetSkin().tex.MenuBG(0, 0, (w or self:GetWide()) + (self.right and -1 or 3), (h or self:GetTall()) + 1)
		else
			self:GetSkin().DrawButtonBorder(self, 0, 0, (w or self:GetWide()) + (self.right and -1 or 3), (h or self:GetTall()) + 1)
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
		self:SetLeftWidth(91)
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
			table.insert(data, {key = key, val = val})
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
			local T = (pace.TranslatePropertiesKey(key) or type(val)):lower()
			
			if pace.PanelExists("properties_" .. T) then
				pnl = pace.CreatePanel("properties_" .. T)
			end

			if pnl then
				obj.editor_pnl = pnl
				
				pnl:SetValue(obj["Get" .. key](obj))
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
			local T = (pace.TranslatePropertiesKey(key) or type(val)):lower()
			
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
			lbl:SetFont("defaultsmall")
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

	function PANEL:SetValue(var, skip_encode)
		if self.editing then return end

		local str = tostring(skip_encode and var or self:Encode(var))
		
		self:SetTextColor(derma.Color(net and "text_dark" or "text_bright", self, color_black))
		self:SetFont("DefaultSmall")
		self:SetText("  " .. str) -- ugh
		self:SizeToContents()

		if #str > 0 then
			self:SetTooltip(str)
		end

		self.original_str = str
		self.original_var = var
	end
	
	-- kind of a hack
	local last_focus = NULL

	function PANEL:OnMousePressed(mcode)
		pace.BusyWithProperties = true
	
		if last_focus:IsValid() then
			last_focus:Reset()
		end	
				
		if mcode == MOUSE_LEFT then
			--if input.IsKeyDown(KEY_R) then
			--	self:Restart()
			--else
				self.MousePressing = true
				if self:MousePress(true) == false then return end
				if (self.last_press or 0) > RealTime() then
					self:EditText()
					self:DoubleClick()
					self.last_press = 0
					
					last_focus = self
				else
					self.last_press = RealTime() + 0.2
				end
			--end
		end
		
		if mcode == MOUSE_RIGHT and self.SpecialCallback then
			self:SpecialCallback()
		end
	end

	function PANEL:OnMouseReleased()
		pace.BusyWithProperties = false
		self:MousePress(false)
		self.MousePressing = false
	end

	function PANEL:IsMouseDown()
		if not input.IsMouseDown(MOUSE_LEFT) then
			pace.BusyWithProperties = false
			self.MousePressing = false
		end
		return self.MousePressing
	end

	function PANEL:DoubleClick()

	end
	
	function PANEL:MousePress()

	end
	
	function PANEL:Restart()
		self:SetValue("")
	end

	function PANEL:EditText()
		pace.BusyWithProperties = true
		
		self:SetText("")
		
		local pnl = vgui.Create("DTextEntry", self)
		self.editing = pnl
		pnl:SetFont("DefaultSmall")
		pnl:SetDrawBackground(false)
		pnl:SetDrawBorder(false)
		pnl:SetValue(self.original_str or "")
		pnl:SetKeyboardInputEnabled(true)
		pnl:RequestFocus()
		pnl:SelectAllOnFocus(true)
		
		local x,y = pnl:GetPos()
		pnl:SetPos(x+3,y-4)
				
		pnl.OnEnter = function()
			pace.BusyWithProperties = false
			self.editing = false
			
			pnl:Remove()
			
			self:SetValue(pnl:GetValue() or "", true)
			self.OnValueChanged(self:Decode(pnl:GetValue()))
		end
	end
	
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

	pace.RegisterPanel(PANEL)
end

do -- vector
	local function VECTOR(ctor, type, arg1, arg2, arg3, encode, special_callback, sens)
		local PANEL = {}

		PANEL.ClassName = "properties_" .. type
		PANEL.Base = "pace_properties_container"

		function PANEL:Init()
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
			
			if special_callback then
				left.SpecialCallback = function(self2) special_callback(self, self2) end
				middle.SpecialCallback = function(self2) special_callback(self, self2) end
				right.SpecialCallback = function(self2) special_callback(self, self2) end
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
		end

		function PANEL:SetValue(vec)
			self.vector = vec

			self.left:SetValue(math.Round(vec[arg1], 3))
			self.middle:SetValue(math.Round(vec[arg2], 3))
			self.right:SetValue(math.Round(vec[arg3], 3))
		end

		function PANEL:SpecialCallback()
			self.left:SetValue(0)
			self.middle:SetValue(0)
			self.right:SetValue(0)
			
			self.OnValueChanged(ctor(0,0,0))
		end
		
		function PANEL:PerformLayout()
			self.left:SizeToContents()
			self.left:SetWide(math.max(self.left:GetWide(), 12))
			
			self.middle:SizeToContents()
			self.middle:SetWide(math.max(self.middle:GetWide(), 12))
			
			self.right:SizeToContents()
			self.right:SetWide(math.max(self.right:GetWide(), 12))

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
			local frm = vgui.Create("DFrame")
			frm:SetSize(200, 200)
			frm:Center()
			frm:MakePopup()
			frm:SetTitle("")
		
			local clr = vgui.Create("DColorMixer", frm)
			clr:Dock(FILL)
			clr:SetColor(Color(self.vector.x, self.vector.y, self.vector.z))
			
			function clr.Think()
				if net then
					local clr = clr:GetColor() or Color(255, 255, 255, 255)
					local vec = Vector(clr.r, clr.g, clr.b)
					self.OnValueChanged(vec)
					self:SetValue(vec)
				else
					if 
						clr.ColorCube:GetDragging() or 
						clr.AlphaBar:GetDragging() or 
						clr.RGBBar:GetDragging() 
					then
						local clr = clr:GetColor() or Color(255, 255, 255, 255)
						local vec = Vector(clr.r, clr.g, clr.b)
						self.OnValueChanged(vec)
						self:SetValue(vec)
					end
				end
			end
		end,
		10
	)
end

do -- number
	local PANEL = {}

	PANEL.ClassName = "properties_number"
	PANEL.Base = "pace_properties_base_type"
	
	PANEL.sens = 1
	
	function PANEL:MousePress(bool)
		if bool then
			self.mousey = gui.MouseY()
			self.mousex = gui.MouseX()
			self.oldval = tonumber(self:GetValue()) or 0
		else
			self.mousey = nil
		end
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
			self.lbl:SetText(tostring(b))
		end
		self.chck = chck
		
		local lbl = vgui.Create("DLabel", self)
		lbl:SetTextColor(derma.Color(net and "text_dark" or "text_bright", self, color_black))
		self.lbl = lbl
	end

	function PANEL:SetValue(b)
		self.chck:SetChecked(b)
		self.lbl:SetText(tostring(b))
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
			self:SetValue(data.friendly)
			self.OnValueChanged(data.friendly)
		end)
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
			self.OnValueChanged(part:GetName())
		end)
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
		end)
	end
	
	pace.RegisterPanel(PANEL)
end

do -- model
	local PANEL = {}

	PANEL.ClassName = "properties_model"
	PANEL.Base = "pace_properties_base_type"
		
	function PANEL:SpecialCallback()
		g_SpawnMenu:Open()
		
		--[[pac.AddHook("VGUIMousePressed", function(panel, mcode)
			if net then
				print(panel:Find("ContenIcon"))
				if panel:GetClassName() == "ContentIcon" and panel.spawnname then
					self:SetValue(panel.spawnname)
				end
			else
			
			end
		end)]]
	end
	
	pace.RegisterPanel(PANEL)
end

do -- material
	local PANEL = {}

	PANEL.ClassName = "properties_material"
	PANEL.Base = "pace_properties_base_type"
		
	function PANEL:SpecialCallback()		
		local pnl = pace.CreatePanel("mat_browser")
		
		function pnl.MaterialSelected(_, path)
			self:SetValue(path)
			self.OnValueChanged(path)
		end
		
		pac.MatBrowser = pnl
	end
	
	pace.RegisterPanel(PANEL)
end

do -- sequence list
		local PANEL = {}

	PANEL.ClassName = "properties_sequence"
	PANEL.Base = "pace_properties_base_type"
		
	function PANEL:SpecialCallback()	
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
	end
	
	pace.RegisterPanel(PANEL)
end

do -- event list
	local PANEL = {}

	PANEL.ClassName = "properties_event"
	PANEL.Base = "pace_properties_base_type"
		
	function PANEL:SpecialCallback()	
		local frame = vgui.Create("DFrame")
		frame:SetTitle(L"events")
		frame:SetSize(300, 300)
		frame:Center()
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
	end
	
	pace.RegisterPanel(PANEL)
end

do -- operator list
	local PANEL = {}

	PANEL.ClassName = "properties_operator"
	PANEL.Base = "pace_properties_base_type"
		
	function PANEL:SpecialCallback()	
		local frame = vgui.Create("DFrame")
		frame:SetTitle(L"operators")
		frame:SetSize(300, 300)
		frame:Center()
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
	end
	
	pace.RegisterPanel(PANEL)
end

do -- arguments
	local PANEL = {}

	PANEL.ClassName = "properties_arguments"
	PANEL.Base = "pace_properties_base_type"
		
	function PANEL:SpecialCallback()	
		local data = pace.current_part.Events[pace.current_part.Event]
		data = data and data.arguments
		
		if not data then return end
				
		local frame = vgui.Create("DFrame")
		frame:SetTitle(L"arguments")
		frame:SetSize(300, 300)
		frame:Center()
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
	end
	
	pace.RegisterPanel(PANEL)
end