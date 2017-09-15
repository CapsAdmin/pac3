pac4 = pac4 or {}
local pac4 = pac4

pac4.parts = pac4.parts or {}
for i,v in pairs(pac4.parts) do if v.Entity:IsValid() then v.Entity:Remove() end end
table.Empty(pac4.parts)

for k, v in pairs(hook.GetTable()) do
	for k2,v2 in pairs(v) do
		if k2 == "pac4" then
			hook.Remove(k, k2)
		end
	end
end

pac4.hooked_entities = {}

do
	local function is_visible(ent)
		if ent:IsPlayer() then
			return ent:ShouldDrawLocalPlayer()
		end

		local dist = ent:BoundingRadius() * 2

		--if EyePos():Distance(ent:WorldSpaceCenter()) < 200 then return true end

		ent.pac4_pixvis = ent.pac4_pixvis or util.GetPixelVisibleHandle()
		local vis = util.PixelVisible(ent:GetPos(), dist, ent.pac4_pixvis)

		return vis > 0
	end

	local function default_draw(ent)
		ent:DrawModel()
	end

	local function render_override(ent)
		if ent.pac4_RenderOverride and ent.pac4_RenderOverride ~= render_override then
			ent:pac4_RenderOverride()
		else
			default_draw(ent)
		end

		if is_visible(ent) then
			for i, part in ipairs(ent.root_part:GetChildrenList()) do
				part:UpdatePosition()

				if ent.draw_manual then
					part.Entity:DrawModel()
				end
			end
		end
	end

	local function check_parts()
		for i, ent in ipairs(pac4.hooked_entities) do
			if is_visible(ent) then
				if not ent.hid_parts then
					for i, part in ipairs(ent.root_part:GetChildrenList()) do
						part.Entity:SetNoDraw(false)
					end
					ent.hid_parts = true
					if ent:IsPlayer() then
						ent.draw_manual = false
					end
				end
			else
				if ent.hid_parts then
					for i, part in ipairs(ent.root_part:GetChildrenList()) do
						part.Entity:SetNoDraw(true)
					end
					if ent:IsPlayer() then
						ent.draw_manual = true
					end
					ent.hid_parts = false
				end
			end
		end
	end

	function pac4.HookEntityRender(ent)
		if ent.pac4_RenderOverride then
			ent.RenderOverride = ent.pac4_RenderOverride
			ent.pac4_RenderOverride = nil
		end

		ent.pac4_RenderOverride = ent.pac4_RenderOverride or ent.RenderOverride

		ent.RenderOverride = render_override

		local root_part = pac4.CreatePart()

		root_part.Entity = ent
		root_part.Owner = ent

		ent.root_part = root_part

		table.insert(pac4.hooked_entities, ent)

		hook.Add("PostEntityRender", "pac4", check_parts)

		return root_part
	end

	function pac4.UnhookEntityRender(ent)
		if ent.pac4_RenderOverride then
			ent.RenderOverride = ent.pac4_RenderOverride
			ent.pac4_RenderOverride = nil
		end

		for i,v in ipairs(pac4.hooked_entities) do
			if v == ent then
				table.remove(pac4.hooked_entities, i)
				break
			end
		end

		if not pac4.hooked_entities[1] then
			hook.Remove("PostEntityRender", "pac4")
		end
	end
end

do
	local META = {}
	META.__index = META

	function META:IsValid()
		return true
	end

	function pac4.CreatePart()
		local self = setmetatable({}, META)

		self.Children = {}
		self.Children2 = {}

		self.draw_matrix = Matrix()
		self.matrix = Matrix()
		self.Bone = 0

		table.insert(pac4.parts, self)

		return self
	end

	function META:CreatePart()
		local part = pac4.CreatePart()
		part:SetParent(self)
		return part
	end

	function META:GetEntity()
		self.Entity = self.Entity or ents.CreateClientProp()
		return self.Entity
	end

	function META:SetModel(path)
		local ent = self:GetEntity()
		ent:SetModel(path)
		self.has_bones = ent:GetBoneCount() > 1
	end

	function META:GetPosAng()
		local pos = self.draw_matrix * self.matrix
		return pos:GetTranslation(), pos:GetAngles()
	end

	do
		local get_bone_pos = FindMetaTable("Entity").GetBonePosition
		local get_bone_matrix = FindMetaTable("Entity").GetBoneMatrix

		function META:UpdatePosition()
			if not self.Parent then return end

			if self.rebuild_matrix then
				self.Parent:UpdatePosition()

				self.matrix:Identity()
				if self.pos then self.matrix:Translate(self.pos) end
				if self.ang then self.matrix:Rotate(self.ang) end
				if self.scale then self.matrix:Scale(self.scale) end
				self.matrix = self.matrix * self.Parent.matrix

				self.Entity:EnableMatrix("RenderMultiply", self.matrix)

				self.rebuild_matrix = false
			end

			local ent = self.Parent.Entity

			if self.Attachment then
				ent.last_attachment = ent.last_attachment or {}
				ent.last_attachment[self.Attachment] = ent.last_attachment[self.Attachment] or {}

				if ent.last_attachment[self.Attachment].framenumber ~= pac.FrameNumber then
					ent.last_attachment[self.Attachment].posang = ent:GetAttachment(self.Attachment)
					ent.last_attachment[self.Attachment].framenumber = pac.FrameNumber
				end

				self.Entity:SetPos(ent.last_attachment[self.Attachment].posang.Pos)
				self.Entity:SetAngles(ent.last_attachment[self.Attachment].posang.Ang)
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
					self.Entity:SetPos(mat:GetTranslation())
					self.Entity:SetAngles(mat:GetAngles())

					self.draw_matrix = mat
				else
					self.Entity:SetPos(self.Entity:GetPos())
					self.Entity:SetAngles(self.Entity:GetAngles())
				end

				if self.has_bones then
					self.Entity:InvalidateBoneCache()
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
end

timer.Simple(0.1, function()
	local root = pac4.HookEntityRender(LocalPlayer())

	local max = 1000

	local function random_model()
		return "models/props_c17/canister01a.mdl" or table.Random(spawnmenu.GetPropTable()["settings/spawnlist/002-comic props.txt"].contents).model
	end

	for i = 1, 5000 do
		local parent = root:CreatePart()
		parent:SetModel(random_model())
		--parent.Attachment = math.random(1, #root.Entity:GetAttachments())
		parent.Bone = math.random(0, root.Entity:GetBoneCount() - 1)

		for i = 1, math.random(1, 20) do
			local part = parent:CreatePart()
			part:SetModel(random_model())
			part.Bone = math.random(0, part.Entity:GetBoneCount() - 1)
			part:SetPos(VectorRand()*50)
			part:SetAngles(Angle(i,i,i)*30)
			parent = part

			if #pac4.parts > max then break end
		end

		if #pac4.parts > max then break end
	end

	print(#pac4.parts)
end)