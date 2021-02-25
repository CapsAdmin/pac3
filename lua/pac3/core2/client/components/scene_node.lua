local BUILDER, META = pac999.entity.ComponentTemplate("node")

function META:Start()
	self.Children = {}
	self.Parent = nil
end

function META:Finish()
	for _, child in ipairs(self:GetAllChildren()) do
		child:Remove()
	end

	local parent = self:GetParent()
	if not parent then return end


	for i, obj in ipairs(parent:GetChildren()) do
		if obj == self then
			table.remove(parent.Children, i)
			break
		end
	end
end

function META:GetParent()
	return self.Parent
end

function META:GetChildren()
	return self.Children
end

local function GetChildrenRecursive(self, out)
	for _, child in ipairs(self.Children) do
		table.insert(out, child)
		GetChildrenRecursive(child, out)
	end
end


function META:GetAllChildren()
	local out = {}
	GetChildrenRecursive(self, out)
	return out
end

function META:GetParentList()
	local out = {}

	local node = self.Parent

	if not node then return out end

	repeat
		table.insert(out, node)
		node = node.Parent

	until not node

	return out
end

function META:AddChild(ent)
	assert(ent.node)
	ent.node.Parent = self
	table.insert(self.Children, ent.node)
end

function META:GetAllChildrenAndSelf(sort_callback)
	local out = {self}

	for i,v in ipairs(self:GetAllChildren()) do
		out[i+1] = v
	end

	if sort_callback then
		sort_callback(out)
	end

	return out
end

BUILDER:Register()