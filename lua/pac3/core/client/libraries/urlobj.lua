local urlobj = pac.urlobj or {}
urlobj.Cache = urlobj.Cache or {}

-- parser made by animorten
-- modified slightly by capsadmin

-- THIS ASSUMES FACE DATA COMES AFTER VERTEX DATA

local table_insert = table.insert
local tonumber = tonumber

function urlobj.ParseObj(data)
	local positions = {}
	local texcoords = {}
	local normals = {}
	local output = {}

	for i in data:gmatch("(.-)\n") do
		local parts = i:gsub(" +", " "):Trim():Split(" ")

		if parts[1] == "v" and #parts >= 4 then
			table_insert(positions, Vector(parts[2], parts[3], parts[4]))
		elseif parts[1] == "vt" and #parts >= 3 then
			table_insert(texcoords, tonumber(parts[2]))
			table_insert(texcoords, tonumber(1 - parts[3]))
		elseif parts[1] == "vn" and #parts >= 4 then
			table_insert(normals, Vector(parts[2], parts[3], parts[4]))
		elseif parts[1] == "f" and #parts > 3 then
			local first, previous

			for i = 2, #parts do
				local current = parts[i]:Split("/")

				if i >= 4 then
					local v1, v2, v3 = {}, {}, {}

					v1.pos = positions[tonumber(first[1])]
					v2.pos = positions[tonumber(current[1])]
					v3.pos = positions[tonumber(previous[1])]

					if #normals > 0 then
						v1.normal = normals[tonumber(first[3])]
						v2.normal = normals[tonumber(current[3])]
						v3.normal = normals[tonumber(previous[3])]
					end
					
					if #texcoords > 0 then
						local offset = 0--8/1024
						v1.u = texcoords[1 + (tonumber(first[2]) - 1) * 2 + 0] + offset
						v1.v = texcoords[1 + (tonumber(first[2]) - 1) * 2 + 1] + offset
						
						v2.u = texcoords[1 + (tonumber(current[2]) - 1) * 2 + 0] + offset
						v2.v = texcoords[1 + (tonumber(current[2]) - 1) * 2 + 1] + offset
						
						v3.u = texcoords[1 + (tonumber(previous[2]) - 1) * 2 + 0] + offset
						v3.v = texcoords[1 + (tonumber(previous[2]) - 1) * 2 + 1] + offset
					end
					
					table_insert(output, v1)
					table_insert(output, v2)
					table_insert(output, v3)
				elseif i == 2 then
					first = current
				end

				previous = current
			end
		end
	end
	
	return output
end

function urlobj.CreateObj(str, mesh_only)	
	local ok, res = pcall(urlobj.ParseObj, str)
	
	if not ok then
		MsgN("pac3 model parse error %q ", res)
		return
	end
	
	local mesh = Mesh()
	mesh:BuildFromTriangles(res)
	
	if mesh_only then
		return mesh
	else
		local ent = ClientsideModel("error.mdl")
		
		AccessorFunc(ent, "MeshModel", "MeshModel")
		AccessorFunc(ent, "MeshMaterial", "MeshMaterial")
		
		ent.MeshModel = mesh
		
		function ent:RenderOverride()
			local matrix = Matrix()
		
			matrix:SetAngles(self:GetAngles())
			matrix:SetTranslation(self:GetPos())
			matrix:Scale(self.pac_model_scale)
		
			
			if self.MeshMaterial then 
				render_SetMaterial(self.MeshMaterial)	
			end
			
			cam.PushModelMatrix(matrix)
				self.MeshModel:Draw()
			cam.PopModelMatrix()
		end
		
		return ent, mesh
	end
end


function urlobj.GetObjFromURL(url, callback, mesh_only, skip_cache)
	if not skip_cache and urlobj.Cache[url] then
		callback(urlobj.Cache[url])
		return
	end

	pac.dprint("requesting model %q", url)

	local id = "urlobj_download_" .. url .. tostring(callback)
	hook.Add("Think", id, function()
		if pac.urlmat and pac.urlmat.Busy then
			return
		end
		
		if not skip_cache and urlobj.Cache[url] then
			callback(urlobj.Cache[url])
			hook.Remove("Think", id)
			return
		end
	
		http.Fetch(url, function(str)	
			pac.dprint("loaded model %q", url)
			
			local obj = urlobj.CreateObj(str, mesh_only)
			
			urlobj.Cache[url] = obj
			
			callback(obj)
		end)
	
		hook.Remove("Think", id)
	end)
end

pac.urlobj = urlobj