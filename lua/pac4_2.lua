RENDER_PARTS = RENDER_PARTS or {}
for i,v in pairs(RENDER_PARTS) do if v.ent:IsValid() then v.ent:Remove() end end
table.Empty(RENDER_PARTS)

local RENDER_PARTS = RENDER_PARTS
local RENDER_ENTS = {}

for k, v in pairs(hook.GetTable()) do
	for k2,v2 in pairs(v) do
		if k2 == "render_ents" then
			hook.Remove(k, k2)
		end
	end
end

function Outfit(ent)
	ent.render_ents_RenderOverride = ent.render_ents_RenderOverride or function(self) self:DrawModel()  end

	local function is_visible(ent)
		if ent:IsPlayer() then return ent:ShouldDrawLocalPlayer() end
		local dist = ent:BoundingRadius() * 2

		--if EyePos():Distance(ent:WorldSpaceCenter()) < 200 then return true end

		ent.render_ents_pixvis = ent.render_ents_pixvis or util.GetPixelVisibleHandle()
		local vis = util.PixelVisible(ent:GetPos(), dist, ent.render_ents_pixvis)

		return vis > 0
	end

	function ent:RenderOverride()
		self:render_ents_RenderOverride()

		if is_visible(self) then
			local num = FrameNumber()
			for i, part in ipairs(self.root_part:GetChildrenList()) do
				part:UpdatePosition(ent, num)

				if self.draw_manual then
					part.ent:DrawModel()
				end
			end
		end
	end

	hook.Add("PostRender", "render_ents", function()
		for i, ent in ipairs(RENDER_ENTS) do
			if is_visible(ent) then
				if not ent.hid_parts then
					for i, part in ipairs(ent.root_part:GetChildrenList()) do
						part.ent:SetNoDraw(false)
					end
					ent.hid_parts = true
					if ent:IsPlayer() then
						ent.draw_manual = false
					end
				end
			else
				if ent.hid_parts then
					for i, part in ipairs(ent.root_part:GetChildrenList()) do
						part.ent:SetNoDraw(true)
					end
					if ent:IsPlayer() then
						ent.draw_manual = true
					end
					ent.hid_parts = false
				end
			end
		end
	end)

	local root_part = Part()

	root_part.ent = ent
	root_part.Owner = ent

	ent.root_part = root_part

	table.insert(RENDER_ENTS, ent)

	return root_part
end

local META = {}
META.__index = META

function META:IsValid()
	return true
end

function Part(mdl, rendergroup, parent)
	local self = setmetatable({}, META)

	if mdl then
		local ent = ents.CreateClientProp()
		ent:SetModel(mdl)

		--ent:Spawn()
		ent:SetLOD(0)
		--ent:SetNoDraw(true)
		self.has_bones = ent:GetBoneCount() > 1

		table.insert(RENDER_PARTS, self)

		self.ent = ent
	end

	self.Children = {}
	self.Children2 = {}

	self.draw_matrix = Matrix()
	self.matrix = Matrix()
	self.Bone = 0

	if parent then
		self:SetParent(parent)
	end

	return self
end

function META:CreatePart(mdl, rendergroup)
	local part = Part(mdl, rendergroup, self)
	part.Owner = self.Owner
	return part
end

function META:GetPosAng()
	local pos = self.draw_matrix * self.matrix
	return pos:GetTranslation(), pos:GetAngles()
end

do
	local get_bone_pos = FindMetaTable("Entity").GetBonePosition
	local get_bone_matrix = FindMetaTable("Entity").GetBoneMatrix

	function META:UpdatePosition(owner, framenumber)
		if not self.Parent then return end

		if self.rebuild_matrix then
			self.Parent:UpdatePosition()

			self.matrix:Identity()
			if self.pos then self.matrix:Translate(self.pos) end
			if self.ang then self.matrix:Rotate(self.ang) end
			if self.scale then self.matrix:Scale(self.scale) end
			self.matrix = self.matrix * self.Parent.matrix

			self.ent:EnableMatrix("RenderMultiply", self.matrix)

			self.rebuild_matrix = false
		end

		local ent = self.Parent.ent

		if self.Attachment then
			ent.last_attachment = ent.last_attachment or {}
			ent.last_attachment[self.Attachment] = ent.last_attachment[self.Attachment] or {}

			if ent.last_attachment[self.Attachment].framenumber ~= framenumber then
				ent.last_attachment[self.Attachment].posang = ent:GetAttachment(self.Attachment)
				ent.last_attachment[self.Attachment].framenumber = framenumber
			end

			self.ent:SetPos(ent.last_attachment[self.Attachment].posang.Pos)
			self.ent:SetAngles(ent.last_attachment[self.Attachment].posang.Ang)
		else
			--[[ent.last_bone = ent.last_bone or {}
			ent.last_bone[self.Bone] = ent.last_bone[self.Bone] or {}

			if ent.last_bone[self.Bone].framenumber ~= framenumber then
				get_bone_pos(ent, self.Bone) -- if we don't call this function mat will return nil (?)

				ent.last_bone[self.Bone].mat = get_bone_matrix(ent, self.Bone)
				ent.last_bone[self.Bone].framenumber = framenumber
			end

			local mat = ent.last_bone[self.Bone].mat]]

			get_bone_pos(ent, self.Bone) -- if we don't call this function mat will return nil (?)
			local mat = get_bone_matrix(ent, self.Bone)

			if mat then
				self.ent:SetPos(mat:GetTranslation())
				self.ent:SetAngles(mat:GetAngles())

				self.draw_matrix = mat
			else
				self.ent:SetPos(self.ent:GetPos())
				self.ent:SetAngles(self.ent:GetAngles())
			end

			if self.has_bones then
				self.ent:InvalidateBoneCache()
			end
		end
	end
end

do -- parenting
	META.OnParent = META.OnParent or function() end
	META.OnChildAdd = META.OnChildAdd or function() end
	META.OnChildRemove = META.OnChildRemove or function() end
	META.OnUnParent = META.OnUnParent or function() end

	function META:GetParent()
		return self.Parent or NULL
	end

	function META:GetChildren()
		return self.Children
	end

	function META:GetChildrenList()
		if not self.children_list then
			self:BuildChildrenList()
		end

		return self.children_list
	end

	function META:GetParentList()

		if not self.parent_list then
			self:BuildParentList()
		end

		return self.parent_list
	end

	function META:AddChild(obj, pos)
		if self == obj or obj:HasChild(self) then
			return false
		end

		obj:UnParent()

		obj.Parent = self

		if not self:HasChild(obj) then
			self.Children2[obj] = obj
			if pos then
				table.insert(self.Children, pos, obj)
			else
				table.insert(self.Children, obj)
			end
		end

		self.children_list = nil
		self.parent_list = nil
		obj.parent_list = nil

		obj:OnParent(self)

		if not obj.suppress_child_add then
			obj.suppress_child_add = true
			self:OnChildAdd(obj)
			obj.suppress_child_add = nil
		end

		return true
	end

	function META:SetParent(obj)
		if not obj:IsValid() then self:UnParent() return end
		return obj:AddChild(self)
	end

	function META:ContainsParent(obj)
		for _, v in ipairs(self:GetParentList()) do
			if v == obj then
				return true
			end
		end
	end

	function META:HasParent()
		return self.Parent:IsValid()
	end

	function META:HasChildren()
		return self.Children[1] ~= nil
	end

	function META:HasChild(obj)
		return self.Children2[obj] ~= nil
	end

	function META:UnparentChild(var)
		local obj = self.Children2[var]
		if obj == var then
			obj:OnUnParent(self)
			self:OnChildRemove(obj)

			obj.Parent = NULL
			obj.children_list = nil
			obj.parent_list = nil

			self.Children2[obj] = nil
			for i,v in ipairs(self.Children) do
				if v == var then
					table.remove(self.Children, i)
					break
				end
			end
		end
	end

	function META:GetRoot()
		if not self:HasParent() then return self end

		self.RootPart = self.RootPart or NULL

		if not self.RootPart:IsValid() then
			self:BuildParentList()
		end

		return self.RootPart
	end

	function META:RemoveChildren()
		for _, obj in ipairs(self:GetChildrenList()) do
			if obj:IsValid() then
				obj:OnUnParent(self)
				obj:Remove()
			end
		end
		self.children_list = nil
	end

	function META:UnParent()
		local parent = self:GetParent()

		if parent:IsValid() then
			parent:UnparentChild(self)
			self:OnUnParent(parent)
		end
	end

	local function add_children_to_list(parent, list)
		for _, child in ipairs(parent:GetChildren()) do
			table.insert(list, child)
			add_children_to_list(child, list)
		end
	end

	function META:BuildChildrenList()
		self.children_list = {}

		add_children_to_list(self, self.children_list)
	end

	function META:BuildParentList()
		self.parent_list = {}

		if not self:HasParent() then return end

		local parent = self:GetParent()

		while parent:IsValid() do
			table.insert(self.parent_list, parent)
			parent = parent:GetParent()
		end

		self.RootPart = self.parent_list[#self.parent_list]
	end
end

function META:InvalidateMatrix()
	self.rebuild_matrix = true
	for i, v in ipairs(self:GetChildrenList()) do
		v.rebuild_matrix = true
	end
end

function META:SetPos(pos)
	self.pos = pos
	self:InvalidateMatrix()
end

function META:SetAngles(ang)
	self.ang = ang
	self:InvalidateMatrix()
end

function META:SetScale(scale)
	self.scale = scale
	self:InvalidateMatrix()
end


timer.Simple(0.1, function()
local root = Outfit(LocalPlayer())

local max = 1000

local function random_model()
	return "models/props_c17/canister01a.mdl" or table.Random(spawnmenu.GetPropTable()["settings/spawnlist/002-comic props.txt"].contents).model
end

for i = 1, 5000 do
	local parent = root:CreatePart(random_model())
	--parent.Attachment = math.random(1, #root.ent:GetAttachments())
	parent.Bone = math.random(0, root.ent:GetBoneCount() - 1)

	for i = 1, math.random(1, 20) do
		local part = parent:CreatePart(random_model())
		part.Bone = math.random(0, part.ent:GetBoneCount() - 1)
		part:SetPos(VectorRand()*50)
		part:SetAngles(Angle(i,i,i)*30)
		parent = part

		if #RENDER_PARTS > max then break end
	end

	if #RENDER_PARTS > max then break end
end

print(#RENDER_PARTS)
end)