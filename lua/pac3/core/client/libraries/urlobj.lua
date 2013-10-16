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


jit.on(parse)
jit.flush(parse)

local i = 0 

function urlobj.ParseObj(data, generate_normals, callback, dbgprint)
	local co = coroutine.create(function()
		debug.sethook()

		local positions = {}
		local texcoords = {}
		local normals = {}
		
		local output = {}
		
		local lines = {}
		
		local i = 1
		for line in data:gmatch("(.-)\n") do
			local parts = line:gsub("%s+", " "):Trim():Split(" ")

			table_insert(lines, parts)
			coroutine.yield(false, "inserting lines", i)
			i = i + 1
		end
	
		local vert_count = #lines
	
		for i, parts in pairs(lines) do		
			if parts[1] == "v" and #parts >= 4 then
				table_insert(positions, Vector(tonumber(parts[2]), tonumber(parts[3]), tonumber(parts[4])))
			elseif parts[1] == "vt" and #parts >= 3 then
				table_insert(texcoords, {u = tonumber(parts[2])%1, v = tonumber(1-parts[3])%1})
			elseif not generate_normals and parts[1] == "vn" and #parts >= 4 then
				table_insert(normals, Vector(tonumber(parts[2]), tonumber(parts[3]), tonumber(parts[4])):GetNormalized())
			end
			
			coroutine.yield(false, "parsing lines", (i/vert_count))
		end
				
		for i, parts in pairs(lines) do
			if parts[1] == "f" and #parts > 3 then
				local first, previous

				for i = 2, #parts do
					local current = parts[i]:Split("/")

					if i == 2 then
						first = current
					end
					
					if i >= 4 then
						local v1, v2, v3 = {}, {}, {}

						v1.pos_index = tonumber(first[1])
						v2.pos_index = tonumber(current[1])
						v3.pos_index = tonumber(previous[1])
						
						v1.pos = positions[tonumber(first[1])]
						v2.pos = positions[tonumber(current[1])]
						v3.pos = positions[tonumber(previous[1])]
						
						if #texcoords > 0 then
							v1.u = texcoords[tonumber(first[2])].u
							v1.v = texcoords[tonumber(first[2])].v
							
							v2.u = texcoords[tonumber(current[2])].u
							v2.v = texcoords[tonumber(current[2])].v
							
							v3.u = texcoords[tonumber(previous[2])].u
							v3.v = texcoords[tonumber(previous[2])].v
						end
						
						if #normals > 0 then
							v1.normal = normals[tonumber(first[3])]
							v2.normal = normals[tonumber(current[3])]
							v3.normal = normals[tonumber(previous[3])]
						end				
						
						table_insert(output, v1)
						table_insert(output, v2)
						table_insert(output, v3)
					end

					previous = current
				end
			end
			
			coroutine.yield(false, "solving indices", i/vert_count)
		end
		
		if generate_normals then
			local vertex_normals = {}
			local count = #output/3
			for i = 1, count do
				local a, b, c = output[1+(i-1)*3+0], output[1+(i-1)*3+1], output[1+(i-1)*3+2] 
				local normal = (c.pos - a.pos):Cross(b.pos - a.pos):GetNormalized()

				vertex_normals[a.pos_index] = vertex_normals[a.pos_index] or Vector()
				vertex_normals[a.pos_index] = (vertex_normals[a.pos_index] + normal)

				vertex_normals[b.pos_index] = vertex_normals[b.pos_index] or Vector()
				vertex_normals[b.pos_index] = (vertex_normals[b.pos_index] + normal)

				vertex_normals[c.pos_index] = vertex_normals[c.pos_index] or Vector()
				vertex_normals[c.pos_index] = (vertex_normals[c.pos_index] + normal)
				coroutine.yield(false, "generating normals", i/count)
			end
			
			local default_normal = Vector(0, 0, -1)

			local count = #output
			for i = 1, count do
				local n = vertex_normals[output[i].pos_index] or default_normal
				n:Normalize()
				normals[i] = n
				output[i].normal = n
				coroutine.yield(false, "smoothing normals", i/count)
			end
		end
		
		callback(output)
		coroutine.yield(true)
	end)

	local last_why
	local id = "pac_parse_obj_" .. i
	
	hook.Add("Think", id, function()
		for i = 1, 512 do
			local dead, done, why, msg = coroutine.resume(co)
			if done then
				if dead == false and done then
					if dbgprint then dbgprint(done) end
					hook.Remove("Think", id)
				end
				return true
			else
				if dbgprint and last_why ~= why and msg then
					if why == "inserting lines" then
						dbgprint(why .. " " .. msg, 2)
					else
						dbgprint(why .. " " .. math.round(msg*100) .. " %", 2)
					end
					
					last_why = why
				end
			end
		end
	end)
	
	i = i + 1
end

function urlobj.CreateObj(obj_str, merge_models, hack)	
	local mesh = Mesh()
	
	urlobj.ParseObj(obj_str, true, function(data)
		mesh:BuildFromTriangles(data)
	end)
	
	return {mesh}
end

local enable = CreateClientConVar("pac_enable_urlobj", "1", true)

function urlobj.GetObjFromURL(url, callback, skip_cache, merge_models, hack)
	if not enable:GetBool() then return end

	url = url:gsub("https://", "http://")

	if url:lower():find("pastebin.com") then
		url = url:gsub(".com/", ".com/raw.php?i=")
	end
	
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
		urlobj.Queue[url] = {callback = callback, tries = 0, merge_models = merge_models, hack = hack}
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
		local url, data = next(urlobj.Queue)
		if not data.Downloading then
			pac.dprint("requesting model download %q", url)
			
			data.Downloading = pac.RealTime + 15

			http.Fetch(url, function(obj_str)	
				pac.dprint("downloaded model %q %s", url, string.NiceSize(#obj_str))
				
				pac.dprint("%s", obj_str)

				local obj = urlobj.CreateObj(obj_str, data.merge_models, data.hack)
				
				urlobj.Cache[url] = obj
				urlobj.Queue[url] = nil

				data.callback(obj)
			end)
		end
		urlobj.Busy = true
	else
		urlobj.Busy = false
	end
end

timer.Create("urlobj_queue", 0.1, 0, urlobj.Think)

pac.urlobj = urlobj