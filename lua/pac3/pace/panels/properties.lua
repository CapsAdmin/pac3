do -- container
	local PANEL = {}

	PANEL.ClassName = "properties_container"
	PANEL.Base = "DPanel"

	function PANEL:Paint(w, h)
		surface.SetDrawColor(color_white)
		surface.DrawRect(0, 0, w or self:GetWide(), h or self:GetTall() + 1)
		surface.SetDrawColor(color_black)
		surface.DrawOutlinedRect(0, 0, w or self:GetWide(), h or self:GetTall() + 1)
	end

	function PANEL:SetContent(pnl)
		self:NoClipping(true)
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

	PANEL.List = {}

	AccessorFunc(PANEL, "item_height", "ItemHeight")

	function PANEL:Init()
		DHorizontalDivider.Init(self)

		local left = vgui.Create("DPanelList", self)
			left:Dock(FILL)
			self:SetLeft(left)
		self.left = left

		local right = vgui.Create("DPanelList", self)
			right:Dock(FILL)
			self:SetRight(right)
		self.right = right

		self:SetDividerWidth(1)
		self:SetLeftWidth(91)
		self:SetItemHeight(14)

		pace.properties = self
	end

	function PANEL:GetHeight()
		return (self.item_height * (#self.List + 1)) - (self:GetDividerWidth() + 1)
	end

	function PANEL:PerformLayout()
		DHorizontalDivider.PerformLayout(self)

		local sorted = table.Copy(self.List)

		for key, data in ipairs(self.List) do
			data.left:SetTall(self:GetItemHeight())
			data.right:SetTall(self:GetItemHeight())
		end
	end

	function PANEL:AddItem(key, var)
		local btn = pace.CreatePanel("properties_label")
		btn:SetValue(key)
		self.left:AddItem(btn)

		local pnl = pace.CreatePanel("properties_container")
		if type(var) == "Panel" then
			pnl:SetContent(var)
		end

		self.right:AddItem(pnl)

		table.insert(self.List, {left = btn, right = pnl, panel = var, key = key})
	end

	local function setup_var(pnl, obj, key)
		obj.editor_pnl = pnl
		pnl:SetValue(obj["Get" .. key](obj))
		pnl.OnValueChanged = function(val)
			pace.Call("VariableChanged", obj, key, val)
		end
	end

	function PANEL:Clear()
		for key, data in ipairs(self.List) do
			data.left:Remove()
			data.right:Remove()
		end

		self.List = {}
	end

	function PANEL:Populate(obj)
		self:Clear()

		local tbl = {}
		local data = obj:ToTable()

		for pos, str in ipairs(pace.PropertyOrder) do
			for key, val in pairs(data) do
				if key == str then
					table.insert(tbl, {key = key, val = val})
					data[key] = nil
				end
			end
		end

		for key, val in pairs(data) do
			table.insert(tbl, {key = key, val = val})
		end

		for _, data in ipairs(tbl) do
			local key, val = data.key, data.val

			if key ~= "ClassName" then
				local pnl
				local T = type(val):lower()

				if pace.PanelExists("properties_" .. T) then
					pnl = pace.CreatePanel("properties_" .. T)
				end

				if pnl then
					setup_var(pnl, obj, key)
					self:AddItem(key, pnl)
				end
			end
		end

		self:TellParentAboutSizeChanges()
		self:PerformLayout()
	end

	pace.RegisterPanel(PANEL)
end

do -- non editable string
	local PANEL = {}

	PANEL.ClassName = "properties_label"
	PANEL.Base = "pace_properties_container"

	function PANEL:SetValue(str)
		local lbl = vgui.Create("DLabel")
			lbl:SetTextColor(color_black)
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

		local str = skip_encode and var or self:Encode(var)

		self:SetTextColor(color_black)
		self:SetFont("DefaultSmall")
		self:SetText("  " .. str) -- ugh
		self:SizeToContents()

		if #str > 0 then
			self:SetTooltip(str)
		end

		self.original_str = str
		self.original_var = var
	end

	function PANEL:OnMousePressed(mcode)
		if mcode == MOUSE_LEFT then
			self.MousePressing = true
			if self:MousePress(true) == false then return end
			if (self.last_press or 0) > RealTime() then
				self:EditText()
				self:DoubleClick()
				self.last_press = 0
			else
				self.last_press = RealTime() + 0.2
			end
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

	function PANEL:EditText()

		self.editing = true
		self:SetText("")
		local pnl = vgui.Create("DTextEntry", self)
		pnl:SetFont("DefaultSmall")
		pnl:SetDrawBackground(false)
		pnl:SetDrawBorder(false)
		pnl:SetSize(self:GetSize())
		pnl:SetValue(self.original_str or "")
		pnl:SetKeyboardInputEnabled(true)
		pnl:RequestFocus()
		pnl.OnEnter = function()
			pnl:Remove()
			self:SetValue(pnl:GetValue() or "", true)
			self.OnValueChanged(self:Decode(pnl:GetValue()))
			self.editing = false
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
	local function VECTOR(ctor, type, arg1, arg2, arg3)
		local PANEL = {}

		PANEL.ClassName = "properties_" .. type
		PANEL.Base = "pace_properties_container"

		function PANEL:Init()
			self.vector = ctor(0,0,0)

			local left = pace.CreatePanel("properties_number", self)
			left:SetMouseInputEnabled(true)
			left.OnValueChanged = function(num)
				self.vector[arg1] = num
				self.OnValueChanged(self.vector)
				self:PerformLayout()
			end

			local middle = pace.CreatePanel("properties_number", self)
			middle:SetMouseInputEnabled(true)
			middle.OnValueChanged = function(num)
				self.vector[arg2] = num
				self.OnValueChanged(self.vector)
				self:PerformLayout()
			end

			local right = pace.CreatePanel("properties_number", self)
			right:SetMouseInputEnabled(true)
			right.OnValueChanged = function(num)
				self.vector[arg3] = num
				self.OnValueChanged(self.vector)
				self:PerformLayout()
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

		function PANEL:PerformLayout()
			self.left:SizeToContents()
			self.middle:SizeToContents()
			self.right:SizeToContents()

			self.middle:MoveRightOf(self.left, 10)
			self.right:MoveRightOf(self.middle, 10)
		end

		function PANEL:OnValueChanged()

		end

		pace.RegisterPanel(PANEL)
	end

	VECTOR(Vector, "vector", "x", "y", "z")
	VECTOR(Angle, "angle", "p", "y", "r")
end

do -- number
	local PANEL = {}

	PANEL.ClassName = "properties_number"
	PANEL.Base = "pace_properties_base_type"

	function PANEL:MousePress(bool)
		if bool then
			self.mousey = gui.MouseY()
			self.mousex = gui.MouseX()
			self.oldval = self:GetValue()
		else
			self.mousey = nil
		end
	end

	function PANEL:Think()
		if self:IsMouseDown() then
			local delta = (self.mousey - gui.MouseY()) / 10
			local val = self.oldval + delta
			self:SetValue(val)
			self.OnValueChanged(val)
		end
	end

	function PANEL:Encode(num)
		return tostring(num)
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
		chck.OnChange = function() self.OnValueChanged(chck:GetChecked()) end
		self.chck = chck
	end

	function PANEL:SetValue(b)
		self.chck:SetChecked(b)
	end

	function PANEL:OnValueChanged()

	end

	pace.RegisterPanel(PANEL)
end