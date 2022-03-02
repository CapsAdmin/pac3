local BUILDER, PART = pac.PartTemplate("base")

PART.ClassName = "submaterial"

PART.Icon = 'icon16/picture_edit.png'
PART.Group = {'model', 'entity'}

BUILDER:StartStorableVars()
	BUILDER:GetSet("Material", "")
	BUILDER:GetSet("SubMaterialId", 1, {
		editor_onchange = function(self, num)
			num = tonumber(num) or 0
			local maxnum = 16

			return math.floor(math.Clamp(num, 0, maxnum))
		end,

		enums = function(part)
			local tbl = {}
			for i,v in ipairs(part:GetSubMaterialIdList()) do
				tbl[v] = tostring(i)
			end
			return tbl
		end,
	})
	BUILDER:GetSet("RootOwner", false, { hide_in_editor = true })
BUILDER:EndStorableVars()

function PART:SetRootOwner(b)
	self:SetRootOwnerDeprecated(b)
end

function PART:GetSubMaterialIdList()
	local out = {}

	local ent = self:GetOwner()

	if ent:IsValid() and ent.GetMaterials and #ent:GetMaterials() > 0 then
		out = ent:GetMaterials()
	end

	return out
end

function PART:UpdateSubMaterialId(id, material)
	id = tonumber(id) or self.SubMaterialId
	local ent = self:GetOwner()

	if ent ~= self.sub_last_owner then
		if IsValid(self.sub_last_owner) then
			self.sub_last_owner:SetSubMaterial(self.sub_last_owner_sub_id - 1, "")

			if self.sub_last_owner.pac_submaterials then
				self.sub_last_owner.pac_submaterials[self.sub_last_owner_sub_id] = nil
			end
		end

		self.sub_last_owner = ent
		self.sub_last_owner_sub_id = id
	end

	if not ent:IsValid() or not ent.GetMaterials then return end
	ent.pac_submaterials = ent.pac_submaterials or {}

	local mat = self.Materialm

	if not material then
		if self.Material and self.Material ~= "" and mat and not mat:IsError() then
			local matName = mat:GetName()
			material = matName:find("/", 1, true) and matName or "!" .. matName
		else
			material = ''
		end
	end

	if id > 0 then
		ent.pac_submaterials[id] = material
		ent:SetSubMaterial(id - 1, material)
	end
end

function PART:PostApplyFixes()
	self:UpdateSubMaterialId()
end

function PART:SetSubMaterialId(num)
	self:UpdateSubMaterialId(self.SubMaterialId, "")
	self.SubMaterialId = tonumber(num) or 1
	self:UpdateSubMaterialId()
end

function PART:FixMaterial()
	local mat = self.Materialm
	if not mat then return end

	local shader = mat:GetShader()
	if shader ~= "UnlitGeneric" then return end
	local tex_path = mat:GetString("$basetexture")

	if not tex_path then return end
	local params = {}

	params["$basetexture"] = tex_path
	params["$vertexcolor"] = 1
	params["$additive"] = 1

	self.Materialm = pac.CreateMaterial('pac_submat_fix_' .. pac.Hash(mat:GetName()), "VertexLitGeneric", params)
end

function PART:UrlTextHandler()
	return function(...)
		return self:Handleurltex(...)
	end
end

function PART:Handleurltex(mat, tex)
	if not IsValid(self) then return end
	if not mat or mat:IsError() or tex:IsError() then self.Materialm = nil return end

	self.Materialm = mat
	self:CallRecursive("OnMaterialChanged")

	self:UpdateSubMaterialId()
end

function PART:SetMaterial(var)
	var = var or ""

	if not pac.Handleurltex(self, var, self:UrlTextHandler()) then
		if var == "" then
			self.Materialm = nil
		else
			self.Materialm = pac.Material(var, self)
			self:FixMaterial()
			self:CallRecursive("OnMaterialChanged")
		end
	end

	self.Material = var
	self:UpdateSubMaterialId()
end

function PART:OnShow()
	local ent = self:GetOwner()

	if ent:IsValid() then
		self:UpdateSubMaterialId()
	end
end

function PART:OnHide(force)
	if self.DefaultOnHide or force then
		self:UpdateSubMaterialId(nil, "")
	end
end

function PART:OnRemove()
	self:OnHide(true)
end

function PART:OnUnParent(part)
	if not part:IsValid() then return end
	self:OnHide(true)
end

function PART:Clear()
	self:RemoveChildren()
	self:UpdateSubMaterialId(nil, "")
end

BUILDER:Register()
