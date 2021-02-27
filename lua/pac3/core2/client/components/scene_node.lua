local BUILDER, META = pac999.entity.ComponentTemplate("node")

BUILDER:GetSet("SortOrder", 0)
BUILDER:GetSet("Children", {})
BUILDER:GetSet("Parent", NULL)

function META:Start()
	self.Children = {}
	self.ChildrenMap = {}
end

function META:Finish()
	self:UnParent()
	
	for _, child in ipairs(self:GetChildrenList()) do
		--child.entity:RemoveComponent(self.ClassName)
		child.entity:Remove()
	end
end

META.is_valid = true

function META:IsValid()
	return self.is_valid
end


function META:OnParent() end
function META:OnChildAdd() end
function META:OnUnParent() end


function META:SetSortOrder(num)
	self.SortOrder = num
	if self:HasParent() then
		self:GetParent():SortChildren()
	end
end

do -- children
	function META:GetChildren()
		return self.Children
	end

	local function add_recursive(part, tbl)
		for _, child in ipairs(part.Children) do
			table.insert(tbl, child)
			add_recursive(child, tbl)
		end
	end

	function META:GetChildrenList()
		if not self.children_list then
			local tbl = {}

			add_recursive(self, tbl)

			self.children_list = tbl
		end

		return self.children_list
	end

	function META:InvalidateChildrenList()
		self.children_list = nil

		for _, parent in ipairs(self:GetParentList()) do
			parent.children_list = nil
		end
	end
end

do -- parent
	function META:SetParent(part)
		if not part or not part:IsValid() then
			self:UnParent()
			return false
		else
			return part:AddChild(self)
		end
	end

	function META:GetParentList()
		if not self.parent_list then
			local tbl = {}

			local part = self.Parent
			local i = 1

			while part:IsValid() do
				tbl[i] = part
				part = part.Parent
				i = i + 1
			end

			self.parent_list = tbl
		end

		return self.parent_list
	end

	function META:InvalidateParentList()
		self.parent_list = nil
		self:CallRecursiveExcludeSelf("InvalidateParentList")
	end
end

function META:AddChild(ent)
	local part = ent.node

	if not part or not part:IsValid() then
		self:UnParent()
		return
	end

	if self == part or part:HasChild(self) then
		return false
	end

	part:UnParent()

	part.Parent = self

	if not part:HasChild(self) then
		self.ChildrenMap[part] = part
		table.insert(self.Children, part)
	end

	self:InvalidateChildrenList()

	part:OnParent(self)
	self:OnChildAdd(part)

	if self:HasParent() then
		self:GetParent():SortChildren()
	end

	part:SortChildren()
	self:SortChildren()

	self:InvalidateParentList()
	part:InvalidateParentList()
end

do
	local sort = function(a, b)
		return a.SortOrder < b.SortOrder
	end

	function META:SortChildren()
		table.sort(self.Children, sort)
	end
end

function META:HasParent()
	return self.Parent:IsValid()
end

function META:HasChildren()
	return self.Children[1] ~= nil
end

function META:HasChild(part)
	return self.ChildrenMap[part] ~= nil
end

function META:RemoveChild(part)
	self.ChildrenMap[part] = nil

	for i, val in ipairs(self:GetChildren()) do
		if val == part then
			self:InvalidateChildrenList()
			table.remove(self.Children, i)
			part:OnUnParent(self)
			break
		end
	end
end

function META:GetRootPart()
	local list = self:GetParentList()
	if list[1] then
		return list[#list]
	end
	return self
end

function META:CallRecursive(func, ...)
	if self[func] then
		self[func](self, ...)
	end

	for _, child in ipairs(self:GetChildrenList()) do
		if child[func] then
			child[func](child, ...)
		end
	end
end

function META:CallRecursiveExcludeSelf(func, ...)
	for _, child in ipairs(self:GetChildrenList()) do
		if child[func] then
			child[func](child, ...)
		end
	end
end

function META:SetKeyValueRecursive(key, val)
	self[key] = val

	for _, child in ipairs(self:GetChildrenList()) do
		child[key] = val
	end
end

function META:RemoveChildren()
	self:InvalidateChildrenList()

	for i, part in ipairs(self:GetChildren()) do
		part:Remove(true)
		self.Children[i] = nil
		self.ChildrenMap[part] = nil
	end
end

function META:UnParent()
	local parent = self:GetParent()

	if parent:IsValid() then
		parent:RemoveChild(self)
	end

	self:OnUnParent(parent)

	self.Parent = NULL
end

META.is_valid = true

function META:Remove()
	if not self.is_valid then return end
	self.is_valid = false

	self:InvalidateChildrenList()

	for _, part in ipairs(self:GetChildren()) do
		local owner_id = part:GetPlayerOwnerId()

		if owner_id then
			pac.RemoveUniqueIDPart(owner_id, part.UniqueID)
		end

		pac.RemovePart(part)
	end

	if self:HasParent() then
		self:GetParent():RemoveChild(self)
	end

	self:RemoveChildren()
end

function META:Deattach()
	
end

BUILDER:Register()