local camera = pac999.camera
local utility = pac999.utility
local models = pac999.models

local BUILDER, META = pac999.entity.ComponentTemplate("input", {"transform", "bounding_box"})

BUILDER:StartStorableVars()
	:GetSet("IgnoreZ", false)
	:GetSet("HitNormal", Vector(0, 0, 0))
	:GetSet("HitPosition", Vector(0, 0, 0))
:EndStorableVars()

function META:SetPointerOver(b)
	if self.Hovered ~= b then
		self.Hovered = b
		self.entity:FireEvent("Pointer", self.Hovered, self.Grabbed)
	end
end

function META:SetPointerDown(b)
	if self.Grabbed ~= b then
		self.Grabbed = b
		self.entity:FireEvent("Pointer", self.Hovered, self.Grabbed)
	end
end

function META:CameraRayIntersect()
	local hit_pos, normal, fraction = camera.IntersectRayWithOBB(
		self.entity.transform:GetWorldPosition(),
		self.entity.transform:GetWorldAngles(),
		self.entity.bounding_box:GetMin(),
		self.entity.bounding_box:GetMax()
	)

	if hit_pos then
		if not self.entity.model then
			return hit_pos, normal, fraction
		end

		local mesh = models.GetMeshInfo(self.entity.model:GetModel())

		if not mesh then
			return hit_pos, normal, fraction
		end

		local world_matrix = self.entity:GetWorldMatrix()
		local eye_pos = camera.GetViewMatrix():GetTranslation()
		local ray = camera.GetViewRay()

		if self.entity.bounding_box.angle_offset then
			local tr = world_matrix:GetTranslation()
			world_matrix:SetTranslation(Vector(0,0,0))
			world_matrix:Rotate(self.entity.bounding_box.angle_offset)
			world_matrix:SetTranslation(tr)
		end

		for _, data in ipairs(mesh.data) do
			for i = 1, #data.triangles, 3 do
				local dist = utility.TriangleIntersect(
					eye_pos,
					ray,
					world_matrix,
					data.triangles[i + 2].pos,
					data.triangles[i + 1].pos,
					data.triangles[i + 0].pos
				)

				if dist then
					return hit_pos, normal, fraction
				end
			end
		end
	end
end

BUILDER:Register()