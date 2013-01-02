local urlobj = pac.urlobj or {}
urlobj.Queue = urlobj.Queue or {}
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

	if pac.debug then
		debug.Trace()
	end
	pac.dprint("parsing model")
	
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
						v1.u = texcoords[1 + (tonumber(first[2]) - 1) * 2 + 0]%1
						v1.v = texcoords[1 + (tonumber(first[2]) - 1) * 2 + 1]%1
						
						v2.u = texcoords[1 + (tonumber(current[2]) - 1) * 2 + 0]%1
						v2.v = texcoords[1 + (tonumber(current[2]) - 1) * 2 + 1]%1
						
						v3.u = texcoords[1 + (tonumber(previous[2]) - 1) * 2 + 0]%1
						v3.v = texcoords[1 + (tonumber(previous[2]) - 1) * 2 + 1]%1
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

function urlobj.CreateObj(obj_str)	
	local ok, res = pcall(urlobj.ParseObj, obj_str)
	
	if not ok then
		MsgN("pac3 obj parse error %q ", res)
		return
	end
	
	local mesh = Mesh()
	mesh:BuildFromTriangles(res)
		
	return mesh
end

local enable = CreateConVar("pac_enable_urlobj", "1")

function urlobj.GetObjFromURL(url, callback, skip_cache)
	if not enable:GetBool() then return end

	-- if it's already downloaded just return it
	if callback and not skip_cache and urlobj.Cache[url] then
		callback(urlobj.Cache[url])
		return
	end
	
	-- if it's already being downloaded, append the callback to the current download
	if urlobj.Queue[url] then
		local old = urlobj.Queue[url].callback
		urlobj.Queue[url].callback = function(...)	
			callback(...)
			old(...)
		end
	else
		urlobj.Queue[url] = {callback = callback}
	end
end

function urlobj.Think()
	if pac.urltex and pac.urltex.Busy then return end

	if table.Count(urlobj.Queue) > 0 then
		for url, data in pairs(urlobj.Queue) do
			if not data.Downloading then
				pac.dprint("requesting model download %q", url)
				
				data.Downloading = true

				http.Fetch(url, function(obj_str)	
					pac.dprint("downloaded model %q", url)

					local obj = urlobj.CreateObj(obj_str)
					
					urlobj.Cache[url] = obj
					urlobj.Queue[url] = nil

					data.callback(obj)
				end)
			end
		end
		urlobj.Busy = true
	else
		urlobj.Busy = false
	end
end

timer.Create("urlobj_queue", 0.1, 0, urlobj.Think)

pac.urlobj = urlobj