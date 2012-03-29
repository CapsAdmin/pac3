local PANEL = {}

PANEL.ClassName = "tree"
PANEL.Base = "DTree"

function PANEL:Init()
	DTree.Init(self)

	self:Dock(FILL)
	self:SetLineHeight(16)
	self:SetIndentSize(1)

	self:Populate()

	pace.tree = self
end

function PANEL:SetModel(path)
	local pnl = vgui.Create("DModelPanel", self)
		pnl:SetModel(path)
		pnl:SetSize(16, 16)

		local mins, maxs = pnl.Entity:GetRenderBounds()
		pnl:SetCamPos(mins:Distance(maxs) * Vector(0.75, 0.75, 0.5) * 15)
		pnl:SetLookAt((maxs + mins) / 2)
		pnl:SetFOV(3)

		pnl.SetImage = function() end
		pnl.GetImage = function() end

	self.Icon:Remove()
	self.Icon = pnl
end

-- a hack,  because creating a new node button will mess up the layout
function PANEL:AddNode(...)

	local node = DTree.AddNode(self, ...)

	node.SetModel = self.SetModel

	node.AddNode = function(...)
		local node = DTree_Node.AddNode(...)
		node.SetModel = self.SetModel
		return node
	end

	return node
end

local function populate_parts(node, parts, children)
	for key, part in ipairs(parts) do
		if children or not part:HasParent() then
			local part_node = pace.tree.rebuild and part.editor_node or node:AddNode(part:GetName())
			part.editor_node = part_node

			part_node.DoClick = function()
				pace.Call("PartSelected", part, outfit)
				return true
			end
			part_node.DoRightClick = function()
				pace.Call("PartMenu", part)
				return true
			end

			if part.ClassName == "model" then
				part_node:SetModel(part:GetModel())
			else
				part_node.Icon:SetImage(pace.PartIcons[part.ClassName] or "gui/silkicons/plugin")
			end

			populate_parts(part_node, part:GetChildren(), true)
		end
	end
end

function PANEL:Populate()
	for key, outfit in ipairs(pac.GetOutfits()) do

		local outfit_node = pace.tree.rebuild and outfit.editor_node or self:AddNode(outfit:GetName())
		outfit.editor_node = outfit_node

		outfit_node.Icon:SetImage(pace.PartIcons["outfit"])
		outfit_node.DoClick = function()
			pace.Call("OutfitSelected", outfit)
			return true
		end
		outfit_node.DoRightClick = function()
			pace.Call("OutfitMenu", outfit)
			return true
		end

		populate_parts(outfit_node, outfit:GetParts())
	end

	self:StretchToParent()
	self:PerformLayout()
end

pace.RegisterPanel(PANEL)

local function remove_node(obj)
	if (obj.editor_node or NULL):IsValid() then
		obj.editor_node:Remove()
		pace.RefreshTree(true)
	end
end

hook.Add("pac_OnPartRemove", "pace_remove_tree_nodes", remove_node)
hook.Add("pac_OnOutfitRemove", "pace_remove_tree_nodes", remove_node)