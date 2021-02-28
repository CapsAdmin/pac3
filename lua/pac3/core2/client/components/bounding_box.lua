local utility = pac999.utility
local camera = pac999.camera

local BUILDER, META = pac999.entity.ComponentTemplate("bounding_box", {"transform", "node"})

BUILDER:StartStorableVars()
	:GetSet("Min", Vector(-1, -1, -1))
	:GetSet("Max", Vector(1, 1, 1))
	:GetSet("CorrectedMin", META.Min * 1)
	:GetSet("CorrectedMax", META.Max * 1)
	:GetSet("BoundingRadius", 0)
	:GetSet("Center", Vector())
	:GetSet("AngleOffset", Angle())
:EndStorableVars()

function META:GetCameraZSort()
	local eye = camera.eye_pos

	if not self.zsort or eye ~= camera.last_eye then
		self.zsort = self:NearestPoint(eye):Distance(eye)
		camera.last_eye = eye
	end

	return self.zsort
end

do
	function META:Invalidate()
		local min = self.Min * 1
		local max = self.Max * 1

		if self.AngleOffset ~= Angle(0,0,0) then
			min:Rotate(self.AngleOffset)
			max:Rotate(self.AngleOffset)
		end

		self.CorrectedMin = Vector(math.min(min.x, max.x), math.min(min.y, max.y), math.min(min.z, max.z))
		self.CorrectedMax = Vector(math.max(min.x, max.x), math.max(min.y, max.y), math.max(min.z, max.z))

		self.Center = LerpVector(0.5, self.CorrectedMin, self.CorrectedMax)

		local x = math.abs(self.CorrectedMin.x) + math.abs(self.CorrectedMax.x)
		local y = math.abs(self.CorrectedMin.y) + math.abs(self.CorrectedMax.y)
		local z = math.abs(self.CorrectedMin.z) + math.abs(self.CorrectedMax.z)

		self.CorrectedMin = -Vector(x,y,z)/2
		self.CorrectedMax = Vector(x,y,z)/2

		self.BoundingRadius = self.CorrectedMin:Distance(self.CorrectedMax)/2
	end

	function META:SetMin(vec)
		self.Min = vec
		self:Invalidate()
	end

	function META:SetMax(vec)
		self.Max = vec
		self:Invalidate()
	end

	function META:SetAngleOffset(ang)
		self.AngleOffset = ang
		self:Invalidate()
	end

	function META:GetWorldMin2()
		local v = self.entity:GetMin()*1
		v:Rotate(self.entity:GetWorldAngles())
		v = v + self.entity:GetWorldPosition()
		return v
	end

	function META:GetWorldMax2()
		local v = self.entity:GetMax()*1
		v:Rotate(self.entity:GetWorldAngles())
		v = v + self.entity:GetWorldPosition()
		return v
	end

	function META:GetWorldCenter()
		return LerpVector(0.5, self:GetWorldMin2(), self:GetWorldMax2())
	end
end

function META:NearestPoint(point)
	local pos = self.entity:GetWorldCenter()
	local ang = self.entity:GetWorldAngles()

	local min = self:GetWorldMin2()
	local max = self:GetWorldMax2()

	local pos = LerpVector(0.5, min, max)

	local m = self.entity:GetMatrix()*Matrix()
	m:SetTranslation(pos)

	local lmat = Matrix()
	lmat:SetTranslation(min)

	min = (m:GetInverse() * lmat):GetTranslation()

	local lmat = Matrix()
	lmat:SetTranslation(max)
	max = (m:GetInverse() * lmat):GetTranslation()


	local dir = pos - point

	local hit_pos, hit_normal, c = util.IntersectRayWithOBB(
		point,
		dir,
		pos,
		ang,
		min,
		max
	)

	if pac999.DEBUG then
		debugoverlay.Sphere(min, 4, 0, Color(0,255,255), true)
		debugoverlay.Sphere(max, 4, 0, Color(0,255,255), true)

		debugoverlay.BoxAngles(
			pos,
			min,
			max,
			ang,
			0,
			Color(255,0,255, 10), true
		)


		debugoverlay.Cross(point, 10,0)

		if hit_pos then
			debugoverlay.Line(point, hit_pos, 0, Color(0,0,255,255))
			debugoverlay.Line(hit_pos, point + dir, 0, Color(0,255,0,10),true)
		else
			debugoverlay.Line(point, point + dir, 0, Color(255,0,0,255),true)
		end
	end

	return hit_pos or point
end

function META:GetMin()
	return self.entity.bounding_box:GetWorldMin() - self.entity.transform:GetWorldPosition()
end

function META:GetMax()
	return self.entity.bounding_box:GetWorldMax() - self.entity.transform:GetWorldPosition()
end

function META:GetWorldMin()
	local min = self:GetCorrectedMin()
	local m = self.entity.transform:GetMatrix()
	local scale = self.entity.transform:GetScaleMatrix()

	local tr = Matrix()
	tr:SetTranslation((min - self:GetCenter()) * scale:GetScale())
	tr = tr * m

	return tr:GetTranslation()
end

-- TODO: rotation doesn't work properly
function META:GetWorldMax()
	local max = self:GetCorrectedMax()
	local m = self.entity.transform:GetMatrix()
	local scale = self.entity.transform:GetScaleMatrix()

	local tr = Matrix()
	tr:SetTranslation((max - self:GetCenter()) * scale:GetScale())
	tr = tr * m

	--print(utility.TransformVector(m, max + scale:GetTranslation() * m:GetScale()), tr:GetTranslation())

	return tr:GetTranslation()
end

BUILDER:Register()