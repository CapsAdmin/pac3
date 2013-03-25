local urlobj = pac.urlobj or {}
urlobj.Queue = {}--urlobj.Queue or {}
urlobj.Cache = {}--urlobj.Cache or {}

concommand.Add("pac_urlobj_clear_cache", function()
	urlobj.Cache = {}
	urlobj.Queue = {}
end)

-- parser made by animorten
-- modified slightly by capsadmin

local table_insert = table.insert
local tonumber = tonumber

function urlobj.ParseObj(data)
	debug.sethook()

	local positions = {}
	local texcoords = {}
	local normals = {}
	local indices = {}
	local output = {}

	if pac.debug then
		debug.Trace()
	end
	pac.dprint("parsing model")
	
	local lines = {}
		
	local i = 1
	for line in data:gmatch("(.-)\n") do
		local parts = line:gsub("%s+", " "):Trim():Split(" ")
		parts.line = line
		parts.line_num = i
		table.insert(lines, parts)
		i=i+1
	end
		
	for _, parts in pairs(lines) do		
		if parts[1] == "v" and #parts >= 4 then
			table_insert(positions, Vector(parts[2], parts[3], parts[4]))
		elseif parts[1] == "vt" and #parts >= 3 then
			table_insert(texcoords, tonumber(parts[2]))
			table_insert(texcoords, tonumber(1 - parts[3]))
		elseif parts[1] == "vn" and #parts >= 4 then
			table_insert(normals, Vector(parts[2], parts[3], parts[4]))
		elseif parts[1] == "f" and #parts > 3 then
			table_insert(indices, {parts[2]:Split("/"), parts[3]:Split("/"), parts[4]:Split("/")})
		else
			--PrintTable(parts)
		end
	end
		
	for _, vtx in pairs(indices) do
		local v1, v2, v3 = {}, {}, {}

		v1.pos = positions[tonumber(vtx[1][1])]
		v2.pos = positions[tonumber(vtx[2][1])]
		v3.pos = positions[tonumber(vtx[3][1])]
		
		if #texcoords > 0 then
			v1.u = texcoords[1 + (tonumber(vtx[1][2]) - 1) * 2 + 0]
			v1.v = texcoords[1 + (tonumber(vtx[1][2]) - 1) * 2 + 1]
			
			v2.u = texcoords[1 + (tonumber(vtx[2][2]) - 1) * 2 + 0]
			v2.v = texcoords[1 + (tonumber(vtx[2][2]) - 1) * 2 + 1]
			
			v3.u = texcoords[1 + (tonumber(vtx[3][2]) - 1) * 2 + 0]
			v3.v = texcoords[1 + (tonumber(vtx[3][2]) - 1) * 2 + 1]
		end
		
		if #normals > 0 then
			v1.normal = normals[tonumber(vtx[1][3])]
			v2.normal = normals[tonumber(vtx[2][3])]
			v3.normal = normals[tonumber(vtx[3][3])]
		end
		
		table_insert(output, v1)
		table_insert(output, v2)
		table_insert(output, v3)
	end
		
	for key, val in pairs(output) do
		val.u = val.u%1
		val.v = val.v%1
	end

	local temp = {}

	for key, val in pairs(output) do
		temp[key] = {pos = val.pos * 1, normal = val.normal * 1, u = val.u, v = val.v}
	end

	return temp
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
		urlobj.Queue[url] = {callback = callback, tries = 0}
	end
end

function urlobj.Think()
	if pac.urltex and pac.urltex.Busy then return end

	for url, data in pairs(urlobj.Queue)  do
		if data.Downloading and data.Downloading < pac.RealTime then 
			pac.dprint("model download timed out for the %s time %q", data.tries, url)
			if data.tries > 3 then
				urlobj.Queue[url] = nil
				pac.dprint("model download timed out for good %q", url)
			else
				data.Downloading = false
			end
			data.tries = data.tries + 1
		return end
	end
	
	if table.Count(urlobj.Queue) > 0 then
		for url, data in pairs(urlobj.Queue) do
			if not data.Downloading then
				pac.dprint("requesting model download %q", url)
				
				data.Downloading = pac.RealTime + 15

				http.Fetch(url, function(obj_str)	
					pac.dprint("downloaded model %q %s", url, string.NiceSize(#obj_str))
					
					pac.dprint("%s", obj_str)

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