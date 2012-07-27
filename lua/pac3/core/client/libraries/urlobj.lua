local urlobj = pac.urlobj or {}

function urlobj.ParseObj(str)
	local vertices, normals, texcoords, faces = {}, {}, {}, {}

	for line in str:gmatch("(.-)\n") do
		local parts = string.Explode(" ", line)
		if #parts < 1 then continue end

		if parts[1] == "v" then
			table.insert(vertices, Vector(tonumber(parts[2]), tonumber(parts[3]), tonumber(parts[4])))
		elseif parts[1] == "vn" then
			table.insert(normals, Vector(tonumber(parts[2]), tonumber(parts[3]), tonumber(parts[4])))
		elseif parts[1] == "vt" then
			table.insert(texcoords, {tonumber(parts[2]), 1 - tonumber(parts[3])})
		elseif parts[1] == "f" then
			local face = {}

			for i = 2, #parts do
				local indices = {}

				for k, v in ipairs(string.Explode("/", parts[i])) do
					indices[k] = tonumber(v)
				end

				face[i - 1] = indices
			end

			table.insert(faces, face)
		end
	end

	local data = {}

	local first_pos, previous_pos = 0, 0
	local first_nor, previous_nor = 0, 0
	local first_tex, previous_tex = 0, 0

	for face_index, face in ipairs(faces) do
		for k, v in ipairs(face) do
			local pos, normal, tex = v[1], v[2], v[3]

			if k == 1 then
				first_pos = pos
				first_nor = normal
				first_tex = tex
			elseif k > 2 then
				table.insert(
					data, 
					{
						pos = vertices[first_pos], 
						normal = normals[first_nor], 
						u = texcoords[first_tex] and texcoords[first_tex][1], 
						v = texcoords[first_tex] and texcoords[first_tex][2]
					}
				)
				table.insert(
					data, 
					{
						pos = vertices[pos], 
						normal = normals[normal], 
						u = texcoords[tex] and texcoords[tex][1], 
						v = texcoords[tex] and texcoords[tex][2]
					}
				)
				table.insert(
					data, 
					{
						pos = vertices[previous_pos], 
						normal = normals[previous_nor], 
						u = texcoords[previous_tex] and texcoords[previous_tex][1], 
						v = texcoords[previous_tex] and texcoords[previous_tex][2]
					}
				)
			end

			previous_pos = pos
			previous_nor = normal
			previous_tex = tex
		end
	end

	return data
end

function urlobj.GetObjFromURL(url, callback, mesh_only)
	pac.dprint("requesting model %q", url)
	
	http.Get(url, "", function(str)
		pac.dprint("loaded model %q", url)
		
		local ok, res = pcall(urlobj.ParseObj, str)
		
		if not ok then
			pac.dprint("model parse error %q ", res)
			
			callback(ok, res)
			return
		end
		
		local mesh = NewMesh()
		mesh:BuildFromTriangles(res)
		
		if mesh_only then
			callback(mesh)	
		else
			local ent = ClientsideModel("error.mdl")
			
			AccesssorFunc(ent, "MeshModel", "MeshModel")
			AccesssorFunc(ent, "MeshMaterial", "MeshMaterial")
			
			ent.MeshModel = mesh
			
			function ent:RenderOverride()
				local matrix = Matrix()
			
				matrix:SetAngle(self:GetAngles())
				matrix:SetTranslation(self:GetPos())
				matrix:Scale(self:GetModelScale())
				
				if self.MeshMaterial then 
					render_SetMaterial(self.MeshMaterial)	
				end
				
				cam.PushModelMatrix(matrix)
					self.MeshModel:Draw()
				cam.PopModelMatrix()
			end
			
			callback(ent, mesh)
		end
	end)
end

pac.urlobj = urlobj