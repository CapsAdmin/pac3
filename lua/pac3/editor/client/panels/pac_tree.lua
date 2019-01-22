local PANEL = vgui.Register("pac_dtree_node_button", {}, "DButton")
pace.pac_dtree_node_button = PANEL

function PANEL:Init()
	self:SetTextInset(32, 0)
	self:SetContentAlignment(4)
end

function PANEL:Paint(w, h)
	derma.SkinHook("Paint", "TreeNodeButton", self, w, h)
	return false
end

function PANEL:UpdateColours(skin)
	if self:IsSelected() then return self:SetTextStyleColor(skin.Colours.Tree.Selected) end
	if self.Hovered then return self:SetTextStyleColor(skin.Colours.Tree.Hover) end

	return self:SetTextStyleColor(skin.Colours.Tree.Normal)
end

local PANEL = vgui.Register("pac_dtree", {}, "DScrollPanel")
pace.pac_dtree = PANEL

AccessorFunc(PANEL, "m_bShowIcons",             "ShowIcons")
AccessorFunc(PANEL, "m_iIndentSize",            "IndentSize")
AccessorFunc(PANEL, "m_iLineHeight",            "LineHeight")
AccessorFunc(PANEL, "m_pSelectedItem",          "SelectedItem")
AccessorFunc(PANEL, "m_bClickOnDragHover",      "ClickOnDragHover")

function PANEL:Init()
	self:SetShowIcons(true)
	self:SetIndentSize(14)
	self:SetLineHeight(17)

	self.RootNode = self:GetCanvas():Add("pac_dtree_node")
	self.RootNode:SetRoot(self)
	self.RootNode:SetParentNode(self)
	self.RootNode:SetSize(5,5)
	self.RootNode:Dock(TOP)
	self.RootNode:SetText("")
	self.RootNode:SetExpanded(true, true)
	self.RootNode:DockMargin(0, 0, 0, 0)

	self:SetPaintBackground(true)
end

function PANEL:Root()
	return self.RootNode
end

function PANEL:AddNode(strName, strIcon)
	return self.RootNode:AddNode(strName, strIcon)
end

function PANEL:ChildExpanded(bExpand)
	self:InvalidateLayout()
end

function PANEL:ShowIcons()
	return self.m_bShowIcons
end

function PANEL:ExpandTo(bExpand)

end

function PANEL:SetExpanded(bExpand)

end

function PANEL:Clear()

end

function PANEL:Paint(w, h)
	derma.SkinHook("Paint", "Tree", self, w, h)
	return true
end

function PANEL:DoClick(node)
	return false
end

function PANEL:DoRightClick(node)
	return false
end

function PANEL:SetSelectedItem(node)
	if IsValid(self.m_pSelectedItem) then
		self.m_pSelectedItem:SetSelected(false)
		self:OnNodeDeselected(self.m_pSelectedItem)
	end

	self.m_pSelectedItem = node

	if node then
		node:SetSelected(true)
		node:OnNodeSelected(node)
	end
end

function PANEL:OnNodeSelected(node)

end

function PANEL:OnNodeDeselected(node)

end

function PANEL:MoveChildTo(child, pos)
	self:InsertAtTop(child)
end

function PANEL:LayoutTree()
	self:InvalidateChildren(true)
end

local PANEL = vgui.Register("pac_dtree_node", {}, "DPanel")
pace.pac_dtree_node = PANEL

AccessorFunc(PANEL, "m_pRoot",                  "Root")

AccessorFunc(PANEL, "m_pParentNode",            "ParentNode")

AccessorFunc(PANEL, "m_strPathID",              "PathID")
AccessorFunc(PANEL, "m_strWildCard",            "WildCard")
AccessorFunc(PANEL, "m_bNeedsPopulating",       "NeedsPopulating")

AccessorFunc(PANEL, "m_bDirty",                 "Dirty",                FORCE_BOOL)
AccessorFunc(PANEL, "m_bNeedsChildSearch",      "NeedsChildSearch",     FORCE_BOOL)

AccessorFunc(PANEL, "m_bForceShowExpander",     "ForceShowExpander",    FORCE_BOOL)
AccessorFunc(PANEL, "m_bHideExpander",          "HideExpander",         FORCE_BOOL)
AccessorFunc(PANEL, "m_bDoubleClickToOpen",     "DoubleClickToOpen",    FORCE_BOOL)

AccessorFunc(PANEL, "m_bLastChild",             "LastChild",            FORCE_BOOL)
AccessorFunc(PANEL, "m_bDrawLines",             "DrawLines",            FORCE_BOOL)
AccessorFunc(PANEL, "m_strDraggableName",       "DraggableName")

function PANEL:Init()
	self:SetDoubleClickToOpen(true)

	self.Label = vgui.Create("pac_dtree_node_button", self)
	self.Label:SetDragParent(self)
	self.Label.DoClick = function() self:InternalDoClick() end
	self.Label.DoDoubleClick = function() self:InternalDoClick() end
	self.Label.DoRightClick = function() self:InternalDoRightClick() end
	self.Label.DragHover = function(s, t) self:DragHover(t) end

	self.Expander = vgui.Create("DExpandButton", self)
	self.Expander.DoClick = function() self:SetExpanded( not self.m_bExpanded) end
	self.Expander:SetVisible(false)

	self.Icon = vgui.Create("DImage", self)
	self.Icon:SetImage("icon16/folder.png")
	self.Icon:SizeToContents()

	self.fLastClick = SysTime()

	self:SetDrawLines(false)
	self:SetLastChild(false)
end

function PANEL:SetRoot(root)
	self.m_pRoot = root

	root.added_nodes = root.added_nodes or {}
	for i,v in ipairs(root.added_nodes) do
		if v == self then return end
	end
	table.insert(root.added_nodes, self)
end

function PANEL:OnRemove()
	local root = self:GetRoot()

	if not IsValid(root) then return end

	root.added_nodes = root.added_nodes or {}
	for i,v in ipairs(root.added_nodes) do
		if v == self then
			table.remove(root.added_nodes, i)
			break
		end
	end
end

function PANEL:IsRootNode()
	return self.m_pRoot == self.m_pParentNode
end

function PANEL:InternalDoClick()
	self:GetRoot():SetSelectedItem(self)

	if self:DoClick() then return end
	if self:GetRoot():DoClick(self) then return end

	if not self.m_bDoubleClickToOpen or (SysTime() - self.fLastClick < 0.3) then
		self:SetExpanded( not self.m_bExpanded)
	end

	self.fLastClick = SysTime()
end

function PANEL:OnNodeSelected(node)
	local parent = self:GetParentNode()
	if IsValid(parent) and parent.OnNodeSelected then
		parent:OnNodeSelected(node)
	end
end

function PANEL:InternalDoRightClick()
	if self:DoRightClick() then return end
	if self:GetRoot():DoRightClick(self) then return end
end

function PANEL:DoClick()
	return false
end

function PANEL:DoRightClick()
	return false
end

function PANEL:SetIcon(str)
	if not str then return end
	if str == "" then return end

	self.Icon:SetImage(str)
end

function PANEL:ShowIcons()
	return self:GetParentNode():ShowIcons()
end

function PANEL:GetLineHeight()
	return self:GetParentNode():GetLineHeight()
end

function PANEL:GetIndentSize()
	return self:GetParentNode():GetIndentSize()
end

function PANEL:SetText(strName)
	self.Label:SetText(strName)
end

function PANEL:ExpandRecurse(bExpand)
	self:SetExpanded(bExpand, true)

	if not self.ChildNodes then return end

	for k, Child in pairs(self.ChildNodes:GetItems()) do
		if Child.ExpandRecurse then
			Child:ExpandRecurse(bExpand)
		end
	end
end

function PANEL:ExpandTo(bExpand)
	self:SetExpanded(bExpand, true)
	self:GetParentNode():ExpandTo(bExpand)
end

function PANEL:SetExpanded(bExpand)

	if self.m_pParentNode:IsValid() then
		self:GetParentNode():ChildExpanded(bExpand)
	end
	self.Expander:SetExpanded(bExpand)
	self.m_bExpanded = bExpand
	self:InvalidateLayout(true)

	if not self.ChildNodes then return end

	local StartTall = self:GetTall()

	if self.ChildNodes then
		self.ChildNodes:SetVisible(bExpand)
		if bExpand then
			self.ChildNodes:InvalidateLayout(true)
		end
	end

	self:InvalidateLayout(true)
end

function PANEL:ChildExpanded(bExpand)
	self.ChildNodes:InvalidateLayout(true)
	self:InvalidateLayout(true)
	self:GetParentNode():ChildExpanded(bExpand)
end

function PANEL:Paint()
end

function PANEL:HasChildren()
	if not IsValid(self.ChildNodes) then return false end
	return self.ChildNodes:HasChildren()
end


function PANEL:DoChildrenOrder()
	if not self.ChildNodes then return end

	local last = table.Count(self.ChildNodes:GetChildren())
	for k, Child in pairs(self.ChildNodes:GetChildren()) do
		Child:SetLastChild(k == last)
	end
end

function PANEL:PerformRootNodeLayout()
	self.Expander:SetVisible(false)
	self.Label:SetVisible(false)
	self.Icon:SetVisible(false)

	if IsValid(self.ChildNodes) then
		self.ChildNodes:Dock(TOP)
		self:SetTall(self.ChildNodes:GetTall())
	end
end

function PANEL:PerformLayout()
	if self:IsRootNode() then
		return self:PerformRootNodeLayout()
	end

	local LineHeight = self:GetLineHeight()

	if self.m_bHideExpander then
		self.Expander:SetPos(-11, 0)
		self.Expander:SetSize(15, 15)
		self.Expander:SetVisible(false)
	else
		self.Expander:SetPos(2, 0)
		self.Expander:SetSize(15, 15)
		self.Expander:SetVisible(self:HasChildren() or self:GetForceShowExpander())
		self.Expander:SetZPos(10)
	end

	self.Label:StretchToParent(0, nil, 0, nil)
	self.Label:SetTall(LineHeight)

	if self:ShowIcons() then
		self.Icon:SetVisible(true)
		self.Icon:SetPos(self.Expander.x + self.Expander:GetWide() + 4, (LineHeight - self.Icon:GetTall()) * 0.5)
		self.Label:SetTextInset(self.Icon.x + self.Icon:GetWide() + 4, 0)
	else
		self.Icon:SetVisible(false)
		self.Label:SetTextInset(self.Expander.x + self.Expander:GetWide() + 4, 0)
	end

	if not self.ChildNodes or not self.ChildNodes:IsVisible() then
		self:SetTall(LineHeight)
	return end

	self.ChildNodes:SizeToContents()
	self:SetTall(LineHeight + self.ChildNodes:GetTall())

	self.ChildNodes:StretchToParent(LineHeight, LineHeight, 0, 0)

	self:DoChildrenOrder()
end

function PANEL:CreateChildNodes()
	if self.ChildNodes then return end

	self.ChildNodes = vgui.Create("DListLayout", self)
	self.ChildNodes:SetDropPos("852")
	self.ChildNodes:SetVisible(self.m_bExpanded)
	self.ChildNodes.OnChildRemoved = function()
		self.ChildNodes:InvalidateLayout()
	end

	self.ChildNodes.OnModified = function()
		self:OnModified()
	end

	self:InvalidateLayout()
end

function PANEL:AddPanel(pPanel)
	self:CreateChildNodes()

	self.ChildNodes:Add(pPanel)
	self:InvalidateLayout()
end

function PANEL:AddNode(strName, strIcon)
	self:CreateChildNodes()

	local pNode = vgui.Create("pac_dtree_node", self)
		pNode:SetText(strName)
		pNode:SetParentNode(self)
		pNode:SetRoot(self:GetRoot())
		pNode:SetIcon(strIcon)
		pNode:SetDrawLines( not self:IsRootNode())

		self:InstallDraggable(pNode)

	self.ChildNodes:Add(pNode)
	self:InvalidateLayout()

	return pNode
end

function PANEL:InsertNode(pNode)
	self:CreateChildNodes()

	pNode:SetParentNode(self)
	pNode:SetRoot(self:GetRoot())
	self:InstallDraggable(pNode)

	self.ChildNodes:Add(pNode)
	self:InvalidateLayout()

	return pNode
end

function PANEL:InstallDraggable(pNode)
	local DragName = self:GetDraggableName()
	if not DragName then return end

	-- Make this node draggable
	pNode:SetDraggableName(DragName)
	pNode:Droppable(DragName)

	-- Allow item dropping onto us
	self.ChildNodes:MakeDroppable(DragName, true, true)
end

function PANEL:DroppedOn(pnl)
	self:InsertNode(pnl)
	self:SetExpanded(true)
end

function PANEL:SetSelected(b)
	self.Label:SetSelected(b)
	self.Label:InvalidateLayout()
	if self.OnSelected then
		self:OnSelected(b)
	end
end

function PANEL:Think()

end

function PANEL:DragHoverClick(HoverTime)
	if not self.m_bExpanded then
		self:SetExpanded(true)
	end

	if self:GetRoot():GetClickOnDragHover() then
		self:InternalDoClick()
	end
end


function PANEL:MoveToTop()
	local parent = self:GetParentNode()
	if not IsValid(parent) then return end

	self:GetParentNode():MoveChildTo(self, 1)
end

function PANEL:MoveChildTo(child)
	self.ChildNodes:InsertAtTop(child)
end

function PANEL:GetText()
	return self.Label:GetText()
end

function PANEL:GetIcon()
	return self.Icon:GetImage()
end

function PANEL:CleanList()
	for k, panel in pairs(self.Items) do

		if not IsValid(panel) or panel:GetParent() ~= self.pnlCanvas then
			self.Items[k] = nil
		end
	end
end

function PANEL:Insert(pNode, pNodeNextTo, bBefore)
	pNode:SetParentNode(self)
	pNode:SetRoot(self:GetRoot())

	self:CreateChildNodes()

	if bBefore then
		self.ChildNodes:InsertBefore(pNodeNextTo, pNode)
	else
		self.ChildNodes:InsertAfter(pNodeNextTo, pNode)
	end

	self:InvalidateLayout()
end

function PANEL:LeaveTree(pnl)
	self.ChildNodes:RemoveItem(pnl, true)
	self:InvalidateLayout()
end


function PANEL:OnModified()
end

function PANEL:GetChildNode(iNum)
	if not IsValid(self.ChildNodes)  then return end
	return self.ChildNodes:GetChild(iNum)
end

function PANEL:Paint(w, h)
	derma.SkinHook("Paint", "TreeNode", self, w, h)
end

function PANEL:Copy()
	local copy = vgui.Create("pac_dtree_node", self:GetParent())
	copy:SetText(self:GetText())
	copy:SetIcon(self:GetIcon())
	copy:SetRoot(self:GetRoot())
	copy:SetParentNode(self:GetParentNode())

	if self.ChildNodes then
		for k, v in pairs(self.ChildNodes:GetChildren()) do
			local childcopy = v:Copy()
			copy:InsertNode(childcopy)
		end
	end

	self:SetupCopy(copy)

	return copy
end

function PANEL:SetupCopy(copy)

end