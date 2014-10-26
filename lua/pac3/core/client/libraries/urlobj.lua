local urlobj = pac.urlobj or {}
pac.urlobj = urlobj

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

local i = 0 

function urlobj.ParseObj(data, generate_normals, callback, statusCallback)
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

	local id = "pac_parse_obj_" .. i
	
	hook.Add("Think", id, function()
		for i = 1, 512 do
			local dead, done, why, msg = coroutine.resume(co)
			if done then
				if dead == false and done then
					if statusCallback then statusCallback(done, true) end
					hook.Remove("Think", id)
				end
				return true
			else
				if statusCallback and msg then
					if why == "inserting lines" then
						statusCallback(why .. " " .. msg, false)
					else
						statusCallback(why .. " " .. math.Round(msg*100) .. " %", false)
					end
				end
			end
		end
	end)
	
	i = i + 1
end

function urlobj.CreateObj(obj_str, generate_normals, statusCallback)	
	local mesh = Mesh()
	
	urlobj.ParseObj(obj_str, generate_normals, function(data)
		mesh:BuildFromTriangles(data)
	end, statusCallback)
	
	return {mesh}
end

local pac_enable_urlobj = CreateClientConVar("pac_enable_urlobj", "1", true)

function urlobj.GetObjFromURL(url, skip_cache, generate_normals, callback, statusCallback)
	statusCallback = statusCallback or function (status, finished) end
	
	if not pac_enable_urlobj:GetBool() then return end
	
	-- Rewrite URL
	-- pastebin.com/([a-zA-Z0-9]*) to pastebin.com/raw.php?i=%1
	-- github.com/(.*)/(.*)/blob/ to github.com/%1/%2/raw/
	url = string.gsub (url, "^https://", "^http://")
	url = string.gsub (url, "pastebin.com/([a-zA-Z0-9]*)$", "pastebin.com/raw.php?i=%1")
	url = string.gsub (url, "github.com/([a-zA-Z0-9_]+)/([a-zA-Z0-9_]+)/blob/", "github.com/%1/%2/raw/")
	
	-- if it's already downloaded just return it
	if callback and not skip_cache and urlobj.Cache[url] then
		callback(urlobj.Cache[url])
		return
	end
	
	-- Add item to queue
	if not urlobj.Queue[url] then
		local queueItem = 
		{
			downloadAttemptCount = 0,
			generate_normals = generate_normals,
			callbackSet = {},
			statusCallbackSet = {},
			
			callback = nil,
			statusCallback = nil
		}
		urlobj.Queue[url] = queueItem
		
		queueItem.callback = function (...)
			for callback, _ in pairs (queueItem.callbackSet) do
				callback (...)
			end
			
			-- Release reference (!!)
			queueItem.callbackSet = nil
		end
		
		queueItem.statusCallback = function (...)
			for statusCallback, _ in pairs (queueItem.statusCallbackSet) do
				statusCallback (...)
			end
		end
	end
	
	-- Add callbacks
	if callback       then urlobj.Queue[url].callbacks[callback      ] = true end
	if statusCallback then urlobj.Queue[url].callbacks[statusCallback] = true end
end

local queue_count = 0

function urlobj.Think()
	if pac.urltex and pac.urltex.Busy then return end

	for url, data in pairs(urlobj.Queue)  do
		if not data.Downloading and data.statusCallback then
			data.statusCallback("queued (" .. queue_count .. " left)", false)
		end
	
		if data.Downloading and data.Downloading < pac.RealTime then 
			pac.dprint("model download timed out for the %s time %q", data.downloadAttemptCount, url)
			if data.downloadAttemptCount > 3 then
				urlobj.Queue[url] = nil
				pac.dprint("model download timed out for good %q", url)
			else
				data.Downloading = false
			end
			data.downloadAttemptCount = data.downloadAttemptCount + 1
			return
		end
	end
	
	queue_count = table.Count(urlobj.Queue)
	
	if queue_count > 0 then
		local url, data = next(urlobj.Queue)
		if not data.Downloading then
			if data.statusCallback then data.statusCallback("downloading", false) end
			pac.dprint("requesting model download %q", url)
			
			data.Downloading = pac.RealTime + 15

			pac.SimpleFetch(url, function(obj_str)	
				pac.dprint("downloaded model %q %s", url, string.NiceSize(#obj_str))
				
				pac.dprint("%s", obj_str)

				local obj = urlobj.CreateObj(obj_str, data.generate_normals, data.statusCallback)
				
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
