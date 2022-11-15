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
	local function get_added_nodes(self)
		local added_nodes = {}
		for i,v in ipairs(self.added_nodes) do
			if v.part and v:IsVisible() and v:IsExpanded() then
				table.insert(added_nodes, v)
			end
		end
		table.sort(added_nodes, function(a, b) return select(2, a:LocalToScreen()) < select(2, b:LocalToScreen()) end)
		return added_nodes
	end

	local function scroll_to_node(self, node)
		timer.Simple(0.1, function()
			if not self:IsValid() then return end
			if not node:IsValid() then return end

			local _, y = self:LocalToScreen()
			local h = self:GetTall()

			local _, node_y = node:LocalToScreen()

			if node_y > y + h or node_y < y then
				self:ScrollToChild(node)
			end
		end)
	end

	local info_image = {
		pace.MiscIcons.info,
		pace.MiscIcons.warning,
		pace.MiscIcons.error,
	}

	function PANEL:Think(...)
		if not pace.current_part:IsValid() then return end

		if
			pace.current_part.pace_tree_node and
			pace.current_part.pace_tree_node:IsValid() and not
			(
				pace.BusyWithProperties:IsValid() or
				pace.ActiveSpecialPanel:IsValid() or
				pace.editing_viewmodel or
				pace.editing_hands or
				pace.properties.search:HasFocus()
			) and
			not gui.IsConsoleVisible()
		then
			if input.IsKeyDown(KEY_LEFT) then
				pace.Call("VariableChanged", pace.current_part, "EditorExpand", false)
			elseif input.IsKeyDown(KEY_RIGHT) then
				pace.Call("VariableChanged", pace.current_part, "EditorExpand", true)
			end

			if input.IsKeyDown(KEY_UP) or input.IsKeyDown(KEY_PAGEUP) then
				local added_nodes = get_added_nodes(self)
				local offset = input.IsKeyDown(KEY_PAGEUP) and 10 or 1
				if not self.scrolled_up or self.scrolled_up < os.clock() then
					for i,v in ipairs(added_nodes) do
						if v == pace.current_part.pace_tree_node then
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
						if v == pace.current_part.pace_tree_node then
							local node = added_nodes[i + offset] or added_nodes[#added_nodes]
							if node then
								node:DoClick()
								--scroll_to_node(self, node)
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

		for _, part in pairs(pac.GetLocalParts()) do
			local node = part.pace_tree_node
			if not node or not node:IsValid() then continue end

			if node.add_button then
				node.add_button:SetVisible(false)
			end

			if part.Info then
				local info = part.Info
				node.info:SetTooltip(info.message)
				node.info:SetImage(info_image[info.type])
				node.info:SetVisible(true)
			else
				node.info:SetVisible(false)
			end

			if part.ClassName == "event" then
				if part.is_active then
					node.Icon:SetImage("icon16/clock_red.png")
				else
					node.Icon:SetImage(part.Icon)
				end
			end

			if part.ClassName == "custom_animation" then
				local anim = part:GetLuaAnimation()
				if anim then
					node:SetText(part:GetName() .. " [" .. string.format("%.2f", anim.Frame + anim.FrameDelta) .. "]")
				end
			end

			if (part.ClassName == "proxy" or part.ClassName == "event") and part.Name == "" then
				node:SetText(pace.pac_show_uniqueid:GetBool() and string.format("%s (%s)", part:GetName(), part:GetPrintUniqueID()) or part:GetName())
			end

			if part:IsHiddenCached() then
				if not node.Icon.event_icon then
					local pnl = vgui.Create("DImage", node.Icon)
					pnl:SetImage("icon16/clock_red.png")
					pnl:SetSize(8, 8)
					pnl:SetPos(8, 8)
					pnl:SetVisible(false)
					node.Icon.event_icon = pnl
				end

				node.Icon.event_icon:SetVisible(true)
			else
				if node.Icon.event_icon then
					node.Icon.event_icon:SetVisible(false)
				end
			end
		end

		local pnl = vgui.GetHoveredPanel() or NULL

		if pnl:IsValid() then
			local pnl = pnl:GetParent()

			if IsValid(pnl) and IsValid(pnl.part) then
				pace.Call("HoverPart", pnl.part)
				if pnl.add_button then
					pnl.add_button:SetVisible(true)
				end
			end
		end
	end
end

function PANEL:OnMouseReleased(mc)
	if mc == MOUSE_RIGHT then
		pace.Call("PartMenu")
	end
end

function PANEL:SetModel(path)
	if not file.Exists(path, "GAME") then
		path = player_manager.TranslatePlayerModel(path)
		if not file.Exists(path, "GAME") then
			print(path, "is invalid")
			return
		end
	end

	local pnl = vgui.Create("SpawnIcon", self)
	pnl:SetModel(path or "")
	pnl:SetSize(16, 16)

	self.Icon:Remove()
	self.Icon = pnl

	self.ModelPath = path
end

function PANEL:GetModel()
	return self.ModelPath
end

local function install_drag(node)
	node:SetDraggableName("pac3")

	local old = node.OnDrop
	function node:OnDrop(child, ...)
		-- we're hovering on the label, not the actual node
		-- so get the parent node instead
		if not child.part then
			child = child:GetParent()
		end

		if child.part and child.part:IsValid() then
			if self.part and self.part:IsValid() and self.part:GetParent() ~= child.part then
				pace.RecordUndoHistory()
				self.part:SetParent(child.part)
				pace.RecordUndoHistory()
			end
		elseif self.part and self.part:IsValid() then
			if self.part.ClassName ~= "group" then
				pace.RecordUndoHistory()
				local group = pac.CreatePart("group", self.part:GetPlayerOwner())
				group:SetEditorExpand(true)
				self.part:SetParent(group)
				pace.RecordUndoHistory()
				pace.TrySelectPart()

			else
				pace.RecordUndoHistory()
				self.part:SetParent()
				pace.RecordUndoHistory()
				pace.RefreshTree(true)
			end
		end

		return old(self, child, ...)
	end

	function node:DroppedOn(child)

		if not child.part then
			child = child:GetParent()
		end

		self:InsertNode(child)
		self:SetExpanded(true)

		if child.part and child.part:IsValid() then
			if self.part and self.part:IsValid() and child.part:GetParent() ~= self.part then
				pace.RecordUndoHistory()
				child.part:SetParent(self.part)
				pace.RecordUndoHistory()
			end
		end

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
			menu:SetPos(input.GetCursorPos())
			menu:MakePopup()

			menu:AddOption(L"collapse all", function()
				node.part:CallRecursive('SetEditorExpand', false)
				pace.RefreshTree(true)
			end):SetImage('icon16/arrow_in.png')

			menu:AddOption(L"expand all", function()
				node.part:CallRecursive('SetEditorExpand', true)
				pace.RefreshTree(true)
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

	if self.info then
		local is_adding = self.add_button:IsVisible()
		local x = self.Label:GetPos() + self.Label:GetTextInset() + (is_adding and self.add_button:GetWide() + 4 or 4)
		surface.SetFont(pace.CurrentFont)
		local w = surface.GetTextSize(self.Label:GetText())
		self.info:SetPos(x + w, (self.Label:GetTall() - self.info:GetTall()) / 2)
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
	node.GetModel = self.GetModel
	node.AddNode = PANEL.AddNode
	node.PerformLayout = node_layout

	local info = node:Add("DImageButton")
	info:SetImage(pace.MiscIcons.info)
	info:SetSize(16, 16)
	info:SetVisible(false)
	info.DoClick = function() pace.MessagePrompt(info:GetTooltip()) end
	node.info = info

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

		if not part:GetShowInEditor() then goto CONTINUE end

		if not part:HasParent() or children then
			local part_node

			if IsValid(part.pace_tree_node) then
				part_node = part.pace_tree_node
			elseif IsValid(self.parts[key]) then
				part_node = self.parts[key]
			else
				part_node = node:AddNode(pace.pac_show_uniqueid:GetBool() and string.format("%s (%s)", part:GetName(), part:GetPrintUniqueID()) or part:GetName())
			end

			fix_folder_funcs(part_node)

			if part.Description then part_node:SetTooltip(L(part.Description)) end

			part.pace_tree_node = part_node
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

			if
				enable_model_icons:GetBool() and
				part.is_model_part and
				part.GetModel and
				part:GetOwner():IsValid()
			then
				part_node:SetModel(part:GetOwner():GetModel(), part.Icon)
			elseif isstring(part.Icon) then
				part_node.Icon:SetImage(part.Icon)
			end

			self:PopulateParts(part_node, part:GetChildren(), true)

			if part.newly_created then
				part_node:SetSelected(true)

				local function expand(part)
					if part:HasParent() and part.Parent.pace_tree_node then
						part.Parent.pace_tree_node:SetExpanded(true)
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

	self:InvalidateLayout()
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
	if not part:GetShowInEditor() then return end

	if (part.pace_tree_node or NULL):IsValid() then
		part.pace_tree_node:SetForceShowExpander()
		part.pace_tree_node:GetRoot().m_pSelectedItem = nil
		part.pace_tree_node:Remove()
		pace.RefreshTree()
	end
end

pac.AddHook("pac_OnPartRemove", "pace_remove_tree_nodes", remove_node)


local last_refresh = 0
local function refresh(part)
	if last_refresh > SysTime() then return end
	if not part:GetShowInEditor() then return end


	last_refresh = SysTime() + 0.1
	timer.Simple(0, function()
		if not part:IsValid() then return end
		if not part:GetShowInEditor() then return end

		pace.RefreshTree(true)
	end)
end

pac.AddHook("pac_OnWoreOutfit", "pace_refresh_tree_nodes", refresh)
pac.AddHook("pac_OnPartParent", "pace_refresh_tree_nodes", refresh)
pac.AddHook("pac_OnPartCreated", "pace_refresh_tree_nodes", refresh)

pac.AddHook("pace_OnVariableChanged", "pace_create_tree_nodes", function(part, key, val)
	if key == "EditorExpand" then
		local node = part.pace_tree_node
		if IsValid(node) then
			node:SetExpanded(val)
		end
	end
end)

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

if Entity(1):IsPlayer() and not PAC_RESTART and not VLL2_FILEDEF then
	pace.OpenEditor()
	pace.RefreshTree(true)
end
