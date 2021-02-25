local models = {}

do
	local cache = {}

	function models.GetMeshInfo(mdl)
		if not cache[mdl] then
			local data = util.GetModelMeshes(mdl, 0, 0)

			local angle_offset = Angle()
			local temp = ClientsideModel(mdl)
			temp:DrawModel()
			local m = temp:GetBoneMatrix(0)
			if m then
				--m = m:GetInverse()

				angle_offset = m:GetAngles()
				angle_offset.r = 0
			end
			temp:Remove()

			local minx,miny,minz = 0,0,0
			local maxx,maxy,maxz = 0,0,0

			for _, data in ipairs(data) do
				for _, vertex in ipairs(data.triangles) do
					if vertex.pos.x < minx then minx = vertex.pos.x end
					if vertex.pos.y < miny then miny = vertex.pos.y end
					if vertex.pos.z < minz then minz = vertex.pos.z end

					if vertex.pos.x > maxx then maxx = vertex.pos.x end
					if vertex.pos.y > maxy then maxy = vertex.pos.y end
					if vertex.pos.z > maxz then maxz = vertex.pos.z end
				end
			end

			cache[mdl] = {
				data = data,
				min = Vector(minx, miny, minz),
				max = Vector(maxx, maxy, maxz),
				angle_offset = angle_offset,
			}
		end

		return cache[mdl]
	end
end

do
	local box_mesh = Mesh()
	mesh.Begin(box_mesh, MATERIAL_QUADS, 6)
		mesh.Quad(
			Vector(-1, -1, -1),
			Vector(-1, 1, -1),
			Vector(-1, 1, 1),
			Vector(-1, -1, 1)
		)
		mesh.Quad(
			Vector(1, -1, -1),
			Vector(-1, -1, -1),
			Vector(-1, -1, 1),
			Vector(1, -1, 1)
		)
		mesh.Quad(
			Vector(1, 1, -1),
			Vector(1, -1, -1),
			Vector(1, -1, 1),
			Vector(1, 1, 1)
		)
		mesh.Quad(
			Vector(-1, 1, -1),
			Vector(1, 1, -1),
			Vector(1, 1, 1),
			Vector(-1, 1, 1)
		)
		mesh.Quad(
			Vector(1, -1, 1),
			Vector(-1, -1, 1),
			Vector(-1, 1, 1),
			Vector(1, 1, 1)
		)
		mesh.Quad(
			Vector(1, 1, -1),
			Vector(-1, 1, -1),
			Vector(-1, -1, -1),
			Vector(1, -1, -1)
		)
	mesh.End()

	function models.GetBoxMesh()
		return box_mesh
	end
end

do
	pac999_temp_model = pac999_temp_model or ClientsideModel("error.mdl")
	pac999_temp_model:SetNoDraw(true)
	local temp_model = pac999_temp_model

	function models.DrawModel(path, matrix, material)
		temp_model:SetModel(path)
		render.MaterialOverride(material)

		temp_model:EnableMatrix("RenderMultiply", matrix)
		temp_model:SetupBones()
		temp_model:DrawModel()

		render.MaterialOverride()
	end
end

return models