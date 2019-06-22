local L = pace.LanguageString

local PANEL = {}

PANEL.ClassName = "tree"
PANEL.Base = "pac_dtree"

function PANEL:Init()
	pace.pac_dtree.Init(self)

	self:SetLineHeight(18)
	self:SetIndentSize(10)

	self.parts = {}

	self:Populate()

	pace.tree = self
end

do
	local pnl = NULL

	local function get_added_nodes(self)
		local added_nodes = {}
		for i,v in ipairs(self.added_nodes) do
			if v.part and v:IsVisible() then
				table.insert(added_nodes, v)
			end
		end
		table.sort(added_nodes, function(a, b) return select(2, a:LocalToScreen()) < select(2, b:LocalToScreen()) end)
		return added_nodes
	end

	local function scroll_to_node(self, node)
		timer.Simple(0.1, function()
			local _, y = self:LocalToScreen()
			local h = self:GetTall()

			local _, node_y = node:LocalToScreen()

			if node_y > y + h or node_y < y then
				self:ScrollToChild(node)
			end
		end)
	end

	function PANEL:Think(...)
		pnl = vgui.GetHoveredPanel() or NULL

		if
			not gui.IsGameUIVisible()  and
			pace.current_part:IsValid() and
			pace.current_part.editor_node and
			pace.current_part.editor_node:IsValid() and not
			(
				pace.BusyWithProperties:IsValid() or
				pace.ActiveSpecialPanel:IsValid() or
				pace.editing_viewmodel or
				pace.editing_hands or
				pace.properties.search:HasFocus()
			)
		then
			if input.IsKeyDown(KEY_LEFT) then
				pace.current_part:SetEditorExpand(false)
				pace.RefreshTree(true)
			elseif input.IsKeyDown(KEY_RIGHT) then
				pace.current_part:SetEditorExpand(true)
				pace.RefreshTree(true)
			end
			if input.IsKeyDown(KEY_UP) or input.IsKeyDown(KEY_PAGEUP) then
				local added_nodes = get_added_nodes(self)
				local offset = input.IsKeyDown(KEY_PAGEUP) and 10 or 1
				if not self.scrolled_up or self.scrolled_up < os.clock() then
					for i,v in ipairs(added_nodes) do
						if v == pace.current_part.editor_node then
							local node = added_nodes[i - offset] or added_nodes[1]
							if node then
								node:DoClick()
								scroll_to_node(self, node)
								break
							end
						end
					end

					self.scrolled_up = self.scrolled_up or os.clock() + 0.4
				end
			else
				self.scrolled_up = nil
			end

			if input.IsKeyDown(KEY_DOWN) or input.IsKeyDown(KEY_PAGEDOWN) then
				local added_nodes = get_added_nodes(self)
				local offset = input.IsKeyDown(KEY_PAGEDOWN) and 10 or 1
				if not self.scrolled_down or self.scrolled_down < os.clock() then
					for i,v in ipairs(added_nodes) do
						if v == pace.current_part.editor_node then
							local node = added_nodes[i + offset] or added_nodes[#added_nodes]
							if node then
								node:DoClick()
								scroll_to_node(self, node)
								break
							end
						end
					end

					self.scrolled_down = self.scrolled_down or os.clock() + 0.4
				end
			else
				self.scrolled_down = nil
			end
		end

		for key, part in pairs(pac.GetLocalParts()) do

			local node = part.editor_node

			if node and node:IsValid() then
				if node.add_button then
					node.add_button:SetVisible(false)
				end

				if part.event_triggered ~= nil then
					if part.event_triggered then
						node.Icon:SetImage("icon16/clock_red.png")
					else
						node.Icon:SetImage(part.Icon)
					end
				end
				if part.ClassName == "proxy" and part.Name == "" then
					node:SetText(part:GetName())
				end
			end
		end

		if pnl:IsValid() then
			local pnl = pnl:GetParent()

			if pnl and pnl.part and pnl.part:IsValid() then
				pace.Call("HoverPart", pnl.part)
				if pnl.add_button then
					pnl.add_button:SetVisible(true)
				end
			end
		end

		if pace.pac_dtree.Think then
			return pace.pac_dtree.Think(self, ...)
		end
	end
end

function PANEL:OnMouseReleased(mc)
	if mc == MOUSE_RIGHT then
		pace.Call("PartMenu")
	end
end

function PANEL:SetModel(path)
	local pnl = vgui.Create("SpawnIcon", self)
		pnl:SetModel(path or "")
		pnl:SetSize(16, 16)

		--[[if pnl.Entity and pnl.Entity:IsValid() then
			local mins, maxs = pnl.Entity:GetRenderBounds()
			pnl:SetCamPos(mins:Distance(maxs) * Vector(0.75, 0.75, 0.5) * 15)
			pnl:SetLookAt((maxs + mins) / 2)
			pnl:SetFOV(3)
		end

		pnl.SetImage = function() end
		pnl.GetImage = function() end]]

	self.Icon:Remove()
	self.Icon = pnl
end

local function install_drag(node)
	node:SetDraggableName("pac3")

	function node:DroppedOn(child)

		if not child.part then
			child = child:GetParent()
		end

		self:InsertNode(child)
		self:SetExpanded(true)

		if child.part and child.part:IsValid() then
			if self.part and self.part:IsValid() and child.part:GetParent() ~= self.part then
				child.part:SetParent(self.part)
			end
		end
	end

	local old = node.OnDrop

	function node:OnDrop(child, ...)
		-- we're hovering on the label, not the actual node
		-- so get the parent node instead
		if not child.part then
			child = child:GetParent()
		end

		if child.part and child.part:IsValid() then
			if self.part and self.part:IsValid() and self.part:GetParent() ~= child.part then
				self.part:SetParent(child.part)
			end
		elseif self.part and self.part:IsValid() then
			if self.part.ClassName ~= "group" then
				local group = pac.CreatePart("group", self.part:GetPlayerOwner())
				group:SetEditorExpand(true)
				self.part:SetParent(group)
				pace.TrySelectPart()
			else
				self.part:SetParent()
				pace.RefreshTree(true)
			end
		end

		return old(self, child, ...)
	end
end

local function install_expand(node)
	local old = node.SetExpanded
	node.SetExpanded = function(self, b, ...)
		if self.part and self.part:IsValid() then
			self.part:SetEditorExpand(b)
			return old(self, b, ...)
		end
	end

	local old = node.Expander.OnMousePressed
	node.Expander.OnMousePressed = function(pnl, code, ...)
		old(pnl, code, ...)

		if code == MOUSE_RIGHT then
			local menu = DermaMenu()
			menu:SetPos(gui.MousePos())
			menu:MakePopup()

			menu:AddOption(L"collapse all", function()
				node.part:CallRecursive('SetEditorExpand', false)
				pace.RefreshTree(true)
				pace.AddUndoRecursive(node.part, 'SetEditorExpand', true, false)
			end):SetImage('icon16/arrow_in.png')

			menu:AddOption(L"expand all", function()
				node.part:CallRecursive('SetEditorExpand', true)
				pace.RefreshTree(true)
				pace.AddUndoRecursive(node.part, 'SetEditorExpand', false, true)
			end):SetImage('icon16/arrow_down.png')
		end
	end
end

local fix_folder_funcs = function(tbl)
	tbl.MakeFolder = function() end
	tbl.FilePopulateCallback = function() end
	tbl.FilePopulate = function() end
	tbl.PopulateChildren = function() end
	tbl.ChildExpanded = function() end
	tbl.PopulateChildrenAndSelf = function() end
	return tbl
end

local function node_layout(self, ...)
	pace.pac_dtree_node.PerformLayout(self, ...)
	if self.Label then
		self.Label:SetFont(pace.CurrentFont)
		--self.Label:SetTextColor(derma.Color("text_dark", self, color_black))
	end

	if self.add_button then
		local x = self.Label:GetPos() + self.Label:GetTextInset() + 4
		surface.SetFont(pace.CurrentFont)
		local w = surface.GetTextSize(self.Label:GetText())
		self.add_button:SetPos(x + w, (self.Label:GetTall() - self.add_button:GetTall()) / 2)
	end
end

local function add_parts_menu(node)
	pace.Call("AddPartMenu", node.part)
end

-- a hack, because creating a new node button will mess up the layout
function PANEL:AddNode(...)

	if self.RootNode then
		install_drag(self.RootNode)
	end

	local node = fix_folder_funcs((self.RootNode and pace.pac_dtree.AddNode or pace.pac_dtree_node.AddNode)(self, ...))
	install_expand(node)
	install_drag(node)

	local add_button = node:Add("DImageButton")
	add_button:SetImage(pace.MiscIcons.new)
	add_button:SetSize(16, 16)
	add_button:SetVisible(false)
	add_button.DoClick = function() add_parts_menu(node) pace.Call("PartSelected", node.part) end
	add_button.DoRightClick = function() node:DoRightClick() end
	node.add_button = add_button
	node.SetModel = self.SetModel
	node.AddNode = PANEL.AddNode
	node.PerformLayout = node_layout

	return node
end

local enable_model_icons = CreateClientConVar("pac_editor_model_icons", "1")

function PANEL:PopulateParts(node, parts, children)
	fix_folder_funcs(node)

	local temp = {}
	for k,v in pairs(parts) do
		table.insert(temp, v)
	end
	parts = temp

	local tbl = {}

	table.sort(parts, function(a,b)
		return a and b and a:GetName() < b:GetName()
	end)

	for key, val in pairs(parts) do
		if not val:HasChildren() then
			table.insert(tbl, val)
		end
	end

	for key, val in pairs(parts) do
		if val:HasChildren() then
			table.insert(tbl, val)
		end
	end

	for key, part in pairs(tbl) do
		key = part.Id

		if part:GetRootPart().show_in_editor == false then goto CONTINUE end

		if not part:HasParent() or children then
			local part_node

			if IsValid(part.editor_node) then
				part_node = part.editor_node
			elseif IsValid(self.parts[key]) then
				part_node = self.parts[key]
			else
				part_node = node:AddNode(part:GetName())
			end

			fix_folder_funcs(part_node)

			if part.Description then part_node:SetTooltip(L(part.Description)) end

			part.editor_node = part_node
			part_node.part = part

			self.parts[key] = part_node

			part_node.DoClick = function()
				if not part:IsValid() then return end
				pace.Call("PartSelected", part)

				--part_node.add_button:SetVisible(true)

				return true
			end

			part_node.DoRightClick = function()
				if not part:IsValid() then return end

				pace.Call("PartMenu", part)
				pace.Call("PartSelected", part)
				part_node:InternalDoClick()
				return true
			end

			if enable_model_icons:GetBool() and part.is_model_part and part.GetModel and part:GetEntity():IsValid()
				and part.ClassName ~= "entity2" and part.ClassName ~= "weapon" -- todo: is_model_part is true, class inheritance issues?
			then
				part_node:SetModel(part:GetEntity():GetModel())
			elseif type(part.Icon) == "string" then
				part_node.Icon:SetImage(part.Icon)
			end

			if part.Group == "experimental" then
				local mat = Material(pace.GroupsIcons.experimental)
				local old = part_node.Icon.PaintOver
				part_node.Icon.PaintOver = function(_, w,h)
					local b = old and old(_,w,h)
					surface.SetMaterial(mat)
					surface.DrawTexturedRect(2,6,13,13)
					return b
				end
			end

			self:PopulateParts(part_node, part:GetChildren(), true)

			if part.newly_created then
				part_node:SetSelected(true)

				local function expand(part)
					if part:HasParent() and part.Parent.editor_node then
						part.Parent.editor_node:SetExpanded(true)
						expand(part.Parent)
					end
				end

				expand(part)

				part_node:SetSelected(true)
				part.newly_created = nil
			else
				part_node:SetSelected(false)
				part_node:SetExpanded(part:GetEditorExpand())
			end
		end
		::CONTINUE::
	end
end

function PANEL:SelectPart(part)
	for key, node in pairs(self.parts) do
		if not node.part or not node.part:IsValid() then
			node:Remove()
			self.parts[key] = nil
		else
			if node.part == part then
				node:SetSelected(true)
			else
				node:SetSelected(false)
			end
		end
	end
end

function PANEL:Populate(reset)

	self:SetLineHeight(18)
	self:SetIndentSize(2)

	for key, node in pairs(self.parts) do
		if reset or (not node.part or not node.part:IsValid()) then
			node:Remove()
			self.parts[key] = nil
		end
	end

	--[[self.m_pSelectedItem = nil

	for key, node in pairs(self:GetItems()) do
		node:Remove()
	end]]

	self:PopulateParts(self, pac.GetLocalParts())

	self:InvalidateLayout()
end

pace.RegisterPanel(PANEL)

local function remove_node(part)
	if (part.editor_node or NULL):IsValid() and part:GetRootPart().show_in_editor ~= false then
		part.editor_node:SetForceShowExpander()
		part.editor_node:GetRoot().m_pSelectedItem = nil
		part.editor_node:Remove()
		pace.RefreshTree()
	end
end

pac.AddHook("pac_OnPartRemove", "pace_remove_tree_nodes", remove_node)

local function refresh(part, localplayer)
	if localplayer and part:GetRootPart().show_in_editor ~= false then
		pace.RefreshTree(true)
	end
end
pac.AddHook("pac_OnWoreOutfit", "pace_create_tree_nodes", refresh)

local function refresh(part)
	if part:GetRootPart().show_in_editor ~= false then
		pace.RefreshTree(true)
	end
end
pac.AddHook("pac_OnPartCreated", "pace_create_tree_nodes", refresh)

function pace.RefreshTree(reset)
	if pace.tree:IsValid() then
		timer.Create("pace_refresh_tree",  0.01, 1, function()
			if pace.tree:IsValid() then
				pace.tree:Populate(reset)
				pace.tree.RootNode:SetExpanded(true, true) -- why do I have to do this?

				pace.TrySelectPart()
			end
		end)
	end
end
