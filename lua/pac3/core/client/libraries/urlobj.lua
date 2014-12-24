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

function urlobj.ClearCache()
	urlobj.Cache      = {}
	urlobj.CacheCount = 0
end

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

local math_sqrt     = math.sqrt
local string_gmatch = string.gmatch
local string_gsub   = string.gsub
local string_match  = string.match
local string_Split  = string.Split
local string_Trim   = string.Trim
local table_insert  = table.insert

local Vector        = Vector

function urlobj.ParseObj(data, generateNormals)
	local coroutine_yield = coroutine.running () and coroutine.yield or function () end
	
	local positions  = {}
	local texCoordsU = {}
	local texCoordsV = {}
	local normals    = {}
	
	local triangleList = {}
	
	local lines = {}
	local faceLines = {}
	
	local i = 1
	for line in string_gmatch (data, "(.-)\n") do
		lines[#lines + 1] = line
		coroutine_yield(false, "Preprocessing lines", i)
		i = i + 1
	end
	
	local lineCount = #lines
	local inverseLineCount = 1 / lineCount
	local i = 1
	while i <= lineCount do
		local processedLine = false
		
		-- Positions: v %f %f %f [%f]
		while i <= lineCount do
			local line = lines[i]
			local x, y, z = string_match(line, "^%s*v%s+(%-?%d*%.?%d*e?[+-]?%d*%.?%d*)%s+(%-?%d*%.?%d*e?[+-]?%d*%.?%d*)%s+(%-?%d*%.?%d*e?[+-]?%d*%.?%d*)")
			if not x then break end
			
			processedLine = true
			x, y, z = tonumber(x), tonumber(y), tonumber(z)
			positions[#positions + 1] = Vector(x, y, z)
			
			coroutine_yield(false, "Processing vertices", i * inverseLineCount)
			i = i + 1
		end
		
		-- Texture coordinates: vt %f %f
		while i <= lineCount do
			local line = lines[i]
			local u, v = string_match(line, "^%s*vt%s+(%-?%d*%.?%d*e?[+-]?%d*%.?%d*)%s+(%-?%d*%.?%d*e?[+-]?%d*%.?%d*)")
			if not u then break end
			
			processedLine = true
			u, v = tonumber(u), tonumber(v)
			
			local texCoordIndex = #texCoordsU + 1
			texCoordsU[texCoordIndex] =      u  % 1
			texCoordsV[texCoordIndex] = (1 - v) % 1
			
			coroutine_yield(false, "Processing vertices", i * inverseLineCount)
			i = i + 1
		end
		
		-- Normals: vn %f %f %f
		while i <= lineCount do
			local line = lines[i]
			local nx, ny, nz = string_match(line, "^%s*vn%s+(%-?%d*%.?%d*e?[+-]?%d*%.?%d*)%s+(%-?%d*%.?%d*e?[+-]?%d*%.?%d*)%s+(%-?%d*%.?%d*e?[+-]?%d*%.?%d*)")
			if not nx then break end
			
			processedLine = true
			
			if not generateNormals then
				nx, ny, nz = tonumber(nx), tonumber(ny), tonumber(nz)
				
				local inverseLength = 1 / math_sqrt(nx * nx + ny * ny + nz * nz)
				nx, ny, nz = nx * inverseLength, ny * inverseLength, nz * inverseLength
				
				local normal = Vector(nx, ny, nz)
				normals[#normals + 1] = normal
			end
			
			coroutine_yield(false, "Processing vertices", i * inverseLineCount)
			i = i + 1
		end
		
		-- Faces: f %f %f %f+
		while i <= lineCount do
			local line = lines[i]
			if not string_match(line, "^%s*f%s+") then break end
			
			processedLine = true
			line = string_match (line, "^%s*(.-)[#%s]*$")
			
			-- Explode line
			local parts = {}
			for part in string_gmatch(line, "[^%s]+") do
				parts[#parts + 1] = part
			end
			faceLines[#faceLines + 1] = parts
			
			coroutine_yield(false, "Processing vertices", i * inverseLineCount)
			i = i + 1
		end
		
		-- Something else
		if not processedLine then
			i = i + 1
		end
	end
	
	local faceLineCount = #faceLines
	local inverseFaceLineCount = 1 / faceLineCount
	for i = 1, #faceLines do
		local parts = faceLines [i]
		
		if #parts >= 4 then
			local v1PositionIndex, v1TexCoordIndex, v1NormalIndex = string_match(parts[2], "(%d+)/?(%d*)/?(%d*)")
			local v3PositionIndex, v3TexCoordIndex, v3NormalIndex = string_match(parts[3], "(%d+)/?(%d*)/?(%d*)")
			
			v1PositionIndex, v1TexCoordIndex, v1NormalIndex = tonumber(v1PositionIndex), tonumber(v1TexCoordIndex), tonumber(v1NormalIndex)
			v3PositionIndex, v3TexCoordIndex, v3NormalIndex = tonumber(v3PositionIndex), tonumber(v3TexCoordIndex), tonumber(v3NormalIndex)
			
			for i = 4, #parts do
				local v2PositionIndex, v2TexCoordIndex, v2NormalIndex = string_match(parts[i], "(%d+)/?(%d*)/?(%d*)")
				v2PositionIndex, v2TexCoordIndex, v2NormalIndex = tonumber(v2PositionIndex), tonumber(v2TexCoordIndex), tonumber(v2NormalIndex)
				
				local v1 = { pos_index = nil, pos = nil, u = nil, v = nil, normal = nil }
				local v2 = { pos_index = nil, pos = nil, u = nil, v = nil, normal = nil }
				local v3 = { pos_index = nil, pos = nil, u = nil, v = nil, normal = nil }
				
				v1.pos_index = v1PositionIndex
				v2.pos_index = v2PositionIndex
				v3.pos_index = v3PositionIndex
				
				v1.pos = positions[v1PositionIndex]
				v2.pos = positions[v2PositionIndex]
				v3.pos = positions[v3PositionIndex]
				
				if #texCoordsU > 0 then
					v1.u = texCoordsU[v1TexCoordIndex]
					v1.v = texCoordsV[v1TexCoordIndex]
					
					v2.u = texCoordsU[v2TexCoordIndex]
					v2.v = texCoordsV[v2TexCoordIndex]
					
					v3.u = texCoordsU[v3TexCoordIndex]
					v3.v = texCoordsV[v3TexCoordIndex]
				end
				
				if #normals > 0 then
					v1.normal = normals[v1NormalIndex]
					v2.normal = normals[v2NormalIndex]
					v3.normal = normals[v3NormalIndex]
				end				
				
				triangleList [#triangleList + 1] = v1
				triangleList [#triangleList + 1] = v2
				triangleList [#triangleList + 1] = v3
				
				v3PositionIndex, v3TexCoordIndex, v3NormalIndex = v2PositionIndex, v2TexCoordIndex, v2NormalIndex
			end
		end
		
		coroutine_yield(false, "Processing faces", i * inverseFaceLineCount)
	end
	
	if generateNormals then
		local vertexNormals = {}
		local triangleCount = #triangleList / 3
		local inverseTriangleCount = 1 / triangleCount
		for i = 1, triangleCount do
			local a, b, c = triangleList[1+(i-1)*3+0], triangleList[1+(i-1)*3+1], triangleList[1+(i-1)*3+2] 
			local normal = (c.pos - a.pos):Cross(b.pos - a.pos):GetNormalized()

			vertexNormals[a.pos_index] = vertexNormals[a.pos_index] or Vector()
			vertexNormals[a.pos_index] = (vertexNormals[a.pos_index] + normal)

			vertexNormals[b.pos_index] = vertexNormals[b.pos_index] or Vector()
			vertexNormals[b.pos_index] = (vertexNormals[b.pos_index] + normal)

			vertexNormals[c.pos_index] = vertexNormals[c.pos_index] or Vector()
			vertexNormals[c.pos_index] = (vertexNormals[c.pos_index] + normal)
			coroutine_yield(false, "Generating normals", i * inverseTriangleCount)
		end
		
		local defaultNormal = Vector(0, 0, -1)

		local vertexCount = #triangleList
		local inverseVertexCount = 1 / vertexCount
		for i = 1, vertexCount do
			local normal = vertexNormals[triangleList[i].pos_index] or defaultNormal
			normal:Normalize()
			normals[i] = normal
			triangleList[i].normal = normal
			coroutine_yield(false, "Normalizing normals", i * inverseVertexCount)
		end
	end
	
	return triangleList
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
