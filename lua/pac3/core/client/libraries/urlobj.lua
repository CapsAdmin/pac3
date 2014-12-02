pac.urlobj = pac.urlobj or {}
local urlobj = pac.urlobj

urlobj.Cache      = {}
urlobj.CacheCount = 0

urlobj.Queue      = {}
urlobj.QueueCount = 0

concommand.Add("pac_urlobj_clear_cache",
	function ()
		urlobj.Cache = {}
		urlobj.CacheCount = 0
		
		urlobj.Queue = {}
		urlobj.QueueCount = 0
	end
)

local pac_enable_urlobj = CreateClientConVar("pac_enable_urlobj", "1", true)

function urlobj.GetObjFromURL(url, forceReload, generateNormals, callback, statusCallback)
	if not pac_enable_urlobj:GetBool() then return end
	
	-- Rewrite URL
	-- pastebin.com/([a-zA-Z0-9]*) to pastebin.com/raw.php?i=%1
	-- github.com/(.*)/(.*)/blob/ to github.com/%1/%2/raw/
	url = string.gsub (url, "^https://", "http://")
	url = string.gsub (url, "pastebin.com/([a-zA-Z0-9]*)$", "pastebin.com/raw.php?i=%1")
	url = string.gsub (url, "github.com/([a-zA-Z0-9_]+)/([a-zA-Z0-9_]+)/blob/", "github.com/%1/%2/raw/")
	
	-- if it's already downloaded just return it
	if callback and not forceReload and urlobj.Cache[url] then
		callback(urlobj.Cache[url])
		return
	end
	
	-- Add item to queue
	if not urlobj.Queue[url] then
		local queueItem = 
		{
			DownloadAttemptCount = 0,
			DownloadTimeoutTime = 0,
			IsDownloading = false,
			
			GenerateNormals = generateNormals,
			CallbackSet = {},
			StatusCallbackSet = {},
			
			Callback = nil,
			StatusCallback = nil
		}
		urlobj.Queue[url] = queueItem
		urlobj.QueueCount = urlobj.QueueCount + 1
		
		queueItem.Callback = function (...)
			for callback, _ in pairs (queueItem.CallbackSet) do
				callback (...)
				
				-- Release reference
				queueItem.CallbackSet [callback] = nil
			end
		end
		
		queueItem.StatusCallback = function (...)
			for statusCallback, _ in pairs (queueItem.StatusCallbackSet) do
				statusCallback (...)
			end
		end
	end
	
	-- Add callbacks
	if callback       then urlobj.Queue[url].CallbackSet      [callback      ] = true end
	if statusCallback then urlobj.Queue[url].StatusCallbackSet[statusCallback] = true end
end

-- ===========================================================================
-- Everything below is internal and should only be called by code in this file
-- ===========================================================================

-- parser made by animorten
-- modified slightly by capsadmin

local ipairs        = ipairs
local pairs         = pairs
local tonumber      = tonumber

local Vector        = Vector

local string_gmatch = string.gmatch
local string_gsub   = string.gsub
local string_match  = string.match
local string_Split  = string.Split
local string_Trim   = string.Trim
local table_insert  = table.insert

function urlobj.ParseObj(data, generateNormals)
	local coroutine_yield = coroutine.running () and coroutine.yield or function () end
	
	local positions = {}
	local texcoords = {}
	local normals = {}
	
	local output = {}
	
	local lines = {}
	
	local i = 1
	for line in string_gmatch (data, "(.-)\n") do
		line = string_gsub (line, "%s+", " ")
		line = string_gsub (line, "#.*$", "")
		line = string_match (line, "^%s*(.-)%s*$")
		
		local parts = string_Split (line, " ")
		
		table_insert(lines, parts)
		coroutine_yield(false, "Preprocessing lines", i)
		i = i + 1
	end
	
	local vert_count = #lines
	
	for i, parts in pairs(lines) do		
		if parts[1] == "v" and #parts >= 4 then
			table_insert(positions, Vector(tonumber(parts[2]), tonumber(parts[3]), tonumber(parts[4])))
		elseif parts[1] == "vt" and #parts >= 3 then
			table_insert(texcoords, {u = tonumber(parts[2])%1, v = tonumber(1-parts[3])%1})
		elseif not generateNormals and parts[1] == "vn" and #parts >= 4 then
			table_insert(normals, Vector(tonumber(parts[2]), tonumber(parts[3]), tonumber(parts[4])):GetNormalized())
		end
		
		coroutine_yield(false, "Processing vertices", (i/vert_count))
	end
	
	for i, parts in pairs(lines) do
		if parts[1] == "f" and #parts >= 4 then
			local first    = string_Split(parts[2], "/")
			local previous = string_Split(parts[3], "/")
			first    [1], first    [2], first    [3] = tonumber (first    [1]), tonumber (first    [2]), tonumber (first    [3])
			previous [1], previous [2], previous [3] = tonumber (previous [1]), tonumber (previous [2]), tonumber (previous [3])
			
			for i = 4, #parts do
				local current = string_Split(parts[i], "/")
				current [1], current [2], current [3] = tonumber (current [1]), tonumber (current [2]), tonumber (current [3])
				
				local v1 = { pos_index = nil, pos = nil, u = nil, v = nil, normal = nil }
				local v2 = { pos_index = nil, pos = nil, u = nil, v = nil, normal = nil }
				local v3 = { pos_index = nil, pos = nil, u = nil, v = nil, normal = nil }
				
				v1.pos_index = first   [1]
				v2.pos_index = current [1]
				v3.pos_index = previous[1]
				
				v1.pos = positions[first   [1]]
				v2.pos = positions[current [1]]
				v3.pos = positions[previous[1]]
				
				if #texcoords > 0 then
					v1.u = texcoords[first   [2]].u
					v1.v = texcoords[first   [2]].v
					
					v2.u = texcoords[current [2]].u
					v2.v = texcoords[current [2]].v
					
					v3.u = texcoords[previous[2]].u
					v3.v = texcoords[previous[2]].v
				end
				
				if #normals > 0 then
					v1.normal = normals[first   [3]]
					v2.normal = normals[current [3]]
					v3.normal = normals[previous[3]]
				end				
				
				output [#output + 1] = v1
				output [#output + 1] = v2
				output [#output + 1] = v3
				
				previous = current
			end
		end
		
		coroutine_yield(false, "Processing faces", i/vert_count)
	end
	
	if generateNormals then
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
			coroutine_yield(false, "Generating normals", i/count)
		end
		
		local default_normal = Vector(0, 0, -1)

		local count = #output
		for i = 1, count do
			local n = vertex_normals[output[i].pos_index] or default_normal
			n:Normalize()
			normals[i] = n
			output[i].normal = n
			coroutine_yield(false, "Normalizing normals", i/count)
		end
	end
	
	return output
end

local nextParsingHookId = 0 

function urlobj.CreateObj(obj_str, generateNormals, statusCallback)
	statusCallback = statusCallback or function (finished, statusMessage) end
	
	local mesh = Mesh()
	
	local co = coroutine.create (
		function ()
			local meshData = urlobj.ParseObj(obj_str, generateNormals)
			mesh:BuildFromTriangles (meshData)
			
			coroutine.yield (true)
		end
	)
	
	-- Coroutine runner
	local parsingHookId = "pac_parse_obj_" .. nextParsingHookId
	hook.Add("Think", parsingHookId,
		function()
			local t0 = SysTime ()
			local success, finished, statusMessage, msg
			while SysTime () - t0 < 0.002 do
				success, finished, statusMessage, msg = coroutine.resume(co)
				
				if not success then break end
				if finished    then break end
			end
			
			if not success then
				hook.Remove("Think", parsingHookId)
				error (finished)
			elseif finished then
				statusCallback(true, "Finished")
				hook.Remove("Think", parsingHookId)
			else
				if statusMessage == "Preprocessing lines" then
					statusCallback(false, statusMessage .. " " .. msg)
				elseif msg then
					statusCallback(false, statusMessage .. " " .. math.Round(msg*100) .. " %")
				else
					statusCallback(false, statusMessage)
				end
			end
		end
	)
	
	nextParsingHookId = nextParsingHookId + 1
	
	return { mesh }
end

-- Download queuing
function urlobj.DownloadQueueThink()
	if pac.urltex and pac.urltex.Busy then return end
	
	for url, queueItem in pairs(urlobj.Queue) do
		if not queueItem.IsDownloading then
			queueItem.StatusCallback(false, "Queued for download (" .. urlobj.QueueCount .. " items in queue)")
		end
		
		-- Check for download timeout
		if queueItem.IsDownloading and
		   pac.RealTime > queueItem.DownloadTimeoutTime then 
			pac.dprint("model download timed out for the %s time %q", queueItem.DownloadAttemptCount, url)
			
			if queueItem.DownloadAttemptCount > 3 then
				-- Give up
				urlobj.Queue[url] = nil
				urlobj.QueueCount = urlobj.QueueCount - 1
				pac.dprint("model download timed out for good %q", url)
			else
				-- Prime for next attempt
				queueItem.IsDownloading = false
			end
			
			queueItem.DownloadAttemptCount = queueItem.DownloadAttemptCount + 1
			return
		end
	end
	
	-- Start download of next item in queue
	if next(urlobj.Queue) then
		local url, queueItem = next(urlobj.Queue)
		if not queueItem.IsDownloading then
			queueItem.StatusCallback(false, "Downloading")
			
			pac.dprint("requesting model download %q", url)
			
			queueItem.IsDownloading = true
			queueItem.DownloadTimeoutTime = pac.RealTime + 15
			
			pac.SimpleFetch(url,
				function(obj_str)	
					pac.dprint("downloaded model %q %s", url, string.NiceSize(#obj_str))
					
					pac.dprint("%s", obj_str)
					
					local obj = urlobj.CreateObj(obj_str, queueItem.GenerateNormals, queueItem.StatusCallback)
					
					if not urlobj.Cache[url] then
						urlobj.CacheCount = urlobj.CacheCount + 1
					end
					urlobj.Cache[url] = obj
					
					-- Remove from queue
					if urlobj.Queue[url] == queueItem then
						urlobj.Queue[url] = nil
						urlobj.QueueCount = urlobj.QueueCount - 1
					end
					
					queueItem.Callback(obj)
				end
			)
		end
	end
	
	urlobj.Busy = next (urlobj.Queue) ~= nil
end

timer.Create("urlobj_download_queue", 0.1, 0, urlobj.DownloadQueueThink)
