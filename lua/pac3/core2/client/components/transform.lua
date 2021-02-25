local utility = pac999.utility

local BUILDER, META = pac999.entity.ComponentTemplate("transform")

BUILDER:StartStorableVars()
	:GetSet("TRMatrix", Matrix())
	:GetSet("TRScale", Vector(1,1,1))
	:GetSet("LocalScale", Vector(1,1,1))
	:GetSet("Scale", Vector(1,1,1))
	:GetSet("CageSizeMin", Vector(0,0,0))
	:GetSet("CageSizeMax", Vector(0,0,0))
	:GetSet("CageMax", Vector(1,1,1)*0)
	:GetSet("CageMin", Vector(1,1,1)*0)
	:GetSet("CageScaleMin", Vector(1,1,1))
	:GetSet("CageScaleMax", Vector(1,1,1))
	:GetSet("IgnoreParentScale", false)
:EndStorableVars()

function META:Start()
	self.TRMatrix = Matrix()
end

if pac999.DEBUG then
	function META.EVENTS:Update()
		debugoverlay.BoxAngles(
			self.entity:GetWorldPosition(),
			self.entity:GetMin(),
			self.entity:GetMax(),
			self.entity:GetWorldAngles(),
			0,
			Color(0,0,255,1),
			true
		)
	end
end

function META:LocalToWorldMatrix(pos, ang)
	local lmat = Matrix()
	lmat:SetTranslation(pos)
	lmat:SetAngles(ang)

	return self:GetWorldMatrix() * lmat
end

function META:GetParentMatrix()
	local wmat = self:GetMatrix()

	if self.entity.node and self.entity.node:GetParent() then
		wmat = self.entity.node:GetParent().entity.transform:GetMatrix()
	end

	return wmat
end

function META:WorldToLocalMatrix(pos, ang)
	local lmat = Matrix()

	if pos then
		lmat:SetTranslation(pos)
	end

	if ang then
		lmat:SetAngles(ang)
	end

	local wmat = self:GetParentMatrix()


	return wmat:GetInverse() * lmat
end

function META:LocalToWorld(pos, ang)
	local wmat = self:LocalToWorldMatrix(pos, ang)
	return wmat:GetTranslation(), wmat:GetAngles()
end

function META:WorldToLocal(pos, ang)
	local wmat = self:WorldToLocalMatrix(pos, ang)
	return wmat:GetTranslation(), wmat:GetAngles()
end

function META:WorldToLocalPosition(pos)
	return self:WorldToLocalMatrix(pos):GetTranslation()
end

function META:WorldToLocalAngles(ang)
	return self:WorldToLocalMatrix(nil, ang):GetAngles()
end

function META:GetWorldMatrix()
	local m = self.entity.transform:GetMatrix() * self.entity.transform:GetScaleMatrix()
	--m:Translate(-self.entity.transform:GetCageCenter())

	return m
end

do
	function META:SetCageSizeMax(s)
		self.CageSizeMax = s
		s = s * 1

		local max = self:GetCageMin()

		if max.x ~= 0 then
			s.x = 1 + s.x / max.x/2
		end

		if max.y ~= 0 then
			s.y = 1 + s.y / max.y/2
		end

		if max.z ~= 0 then
			s.z = 1 + s.z / max.z/2
		end

		self:SetCageScaleMax(s)
	end

	function META:SetCageSizeMin(s)
		self.CageSizeMin = s

		s = s * 1

		local min = self:GetCageMin()

		if min.x ~= 0 then
			s.x = 1 - s.x / min.x/2
		end

		if min.y ~= 0 then
			s.y = 1 - s.y / min.y/2
		end

		if min.z ~= 0 then
			s.z = 1 - s.z / min.z/2
		end

		self:SetCageScaleMin(s)
	end

	function META:SetCageScaleMin(val)
		self.CageScaleMin = val
		self:InvalidateScaleMatrix()
	end

	function META:SetCageScaleMax(val)
		self.CageScaleMax = val
		self:InvalidateScaleMatrix()
	end

	function META:SetCageMin(val)
		self.CageMin = val
		self:InvalidateScaleMatrix()
	end

	function META:SetCageMax(val)
		self.CageMax = val
		self:InvalidateScaleMatrix()
	end

	function META:GetCageMin()
		if self.entity.bounding_box then
			return self.entity.bounding_box:GetCorrectedMin()
		end
		return self.CageMin
	end

	function META:GetCageMax()
		if self.entity.bounding_box then
			return self.entity.bounding_box:GetCorrectedMax()
		end
		return self.CageMax
	end

	function META:InvalidateScaleMatrix()
		if self.entity.bounding_box then
			self.entity.bounding_box:Invalidate()
		end

		local tr = Matrix()
		---self.CageScaleMin = Vector(1,1,1)

		do
			local min = self.CageScaleMin
			local max = self.CageScaleMax


			tr:Translate(self:GetCageMax())
			tr:Scale(max)
			tr:Translate(-self:GetCageMax())


			tr:Translate(self:GetCageMin())
			tr:Scale(Vector(
				((max.x + min.x-1)/max.x),
				((max.y + min.y-1)/max.y),
				((max.z + min.z-1)/max.z)
			))
			tr:Translate(-self:GetCageMin())
		end

		self.ScaleMatrix = tr
	end

	function META:GetScaleMatrix()

		if not self.ScaleMatrix then
			self:InvalidateScaleMatrix()
		end

		return self.ScaleMatrix
	end

	function META:GetCageCenter()
		if self.entity.bounding_box then
			return self.entity.bounding_box:GetCenter()
		end
		return LerpVector(0.5, self:GetCageMin(), self:GetCageMax())
	end

	function META:GetCageMinMax()
		local center = self:GetCageCenter()
		return self:GetCageMin() - center, self:GetCageMax() - center
	end
end

function META:InvalidateMatrix()
	if self.InvalidMatrix then return end

	self.InvalidMatrix = true
	self._Scale = nil

	for _, child in ipairs(self.entity.node:GetAllChildren()) do
		child.entity.transform._Scale = nil
		child.entity.transform.InvalidMatrix = true
	end
end

function META:GetMatrix()
	if self.InvalidMatrix or not self.cached_matrix then
		self.cached_matrix = self:BuildTRMatrix()
		self.InvalidMatrix = false
	end

	if pac999.DEBUG then
		debugoverlay.Text(self.cached_matrix:GetTranslation(), tostring(self), 0)
		debugoverlay.Cross(self.cached_matrix:GetTranslation(), 2, 0, GREEN, true)

		local min, max = self:GetCageMinMax()

		debugoverlay.BoxAngles(
			self.cached_matrix:GetTranslation(),
			min * self.cached_matrix:GetScale(),
			max * self.cached_matrix:GetScale(),
			self.cached_matrix:GetAngles(),
			0,
			Color(0,255,0,0),
			true
		)
	end

	return self.cached_matrix
end

function META:BuildTRMatrix()
	local tr = self.TRMatrix * Matrix()

	if self.TRScale then
		tr:SetTranslation(tr:GetTranslation() * self.TRScale)
	end

	local parent = self.entity.node.Parent

	if parent then
		parent = parent.entity.transform
		if self.IgnoreParentScale then
			local pm = parent:GetMatrix()*Matrix()
			pm:SetScale(Vector(1,1,1))
			tr = pm * tr
			tr:Scale(self.Scale)
		else
			tr = parent:GetMatrix() * tr
			tr:Scale(self.Scale * parent.Scale)
		end
	end

	---tr:Translate(LerpVector(0.5, self:OBBMins(), self:OBBMaxs()))
	tr:Scale(self.LocalScale)

	return tr
end

function META:SetTRMatrix(m)
	self.TRMatrix = m * Matrix()
	self:InvalidateMatrix()
end

function META:SetWorldMatrix(m)
	local lm = m:GetInverse() * self:GetMatrix()
	self.TRMatrix = self.TRMatrix * lm:GetInverse()
	self:InvalidateMatrix()
end

function META:SetWorldPosition(pos)
	self:SetPosition(self:WorldToLocalPosition(pos))
end

function META:GetUp()
	return self:GetMatrix():GetUp()
end

function META:GetRight()
	return self:GetMatrix():GetRight()
end

function META:GetForward()
	return self:GetMatrix():GetForward()
end

function META:GetBackward()
	return self:GetMatrix():GetForward() * -1
end

function META:GetLeft()
	return self:GetMatrix():GetRight() * -1
end

function META:GetDown()
	return self:GetMatrix():GetUp() * -1
end

function META:SetWorldAngles(pos)
	self:SetAngles(self:WorldToLocalAngles(pos))
end

function META:GetWorldPosition()
	return self:GetMatrix():GetTranslation()
end

function META:GetAngles()
	return self.TRMatrix:GetAngles()
end

function META:GetWorldAngles()
	local m = self:GetMatrix()*Matrix()
	m:SetScale(Vector(1,1,1))
	return m:GetAngles()
end

function META:SetPosition(v)
	self.TRMatrix:SetTranslation(v)
	self:InvalidateMatrix()
end

function META:GetPosition()
	return self.TRMatrix:GetTranslation()
end

function META:SetAngles(a)
	self.TRMatrix:SetAngles(a)
	self:InvalidateMatrix()
end

function META:Rotate(a)
	self.TRMatrix:Rotate(a)
	self:InvalidateMatrix()
end

function META:SetScale(v)
	self.Scale = v
	self:InvalidateMatrix()
end

function META:SetTRScale(v)
	self.TRScale = v
	self:InvalidateMatrix()
end

function META:SetLocalScale(v)
	self.LocalScale = v
	self:InvalidateMatrix()
end

BUILDER:Register()