pac.urlobj = pac.urlobj or {}
local urlobj = pac.urlobj

urlobj.DataCache  = pac.CreateCache("objcache")

concommand.Add("pac_urlobj_clear_disk", function()
	urlobj.DataCache:Clear()
	pac.Message('Disk cache cleared')
end, nil, 'Clears obj file cache on disk')

local SIMULATENOUS_DOWNLOADS = CreateConVar('pac_objdl_streams', '4', {FCVAR_ARCHIVE}, 'OBJ files download streams')
local CURRENTLY_DOWNLOADING = 0

urlobj.Cache              = {}
urlobj.CacheCount         = 0

urlobj.Queue              = {}
urlobj.QueueCount         = 0

urlobj.DownloadQueue      = {}
urlobj.DownloadQueueCount = 0

local pac_enable_urlobj = CreateClientConVar("pac_enable_urlobj", "1", true)

concommand.Add("pac_urlobj_clear_cache",
	function ()
		urlobj.ClearCache()
		urlobj.ClearQueue()
	end
)

function urlobj.Reload()
	urlobj.ClearCache()
end

function urlobj.ClearCache()
	urlobj.Cache      = {}
	urlobj.CacheCount = 0
end

function urlobj.ClearQueue()
	urlobj.Queue      = {}
	urlobj.QueueCount = 0

	urlobj.DownloadQueue      = {}
	urlobj.DownloadQueueCount = 0
	CURRENTLY_DOWNLOADING = 0
end

function urlobj.GetObjFromURL(url, forceReload, generateNormals, callback, statusCallback)
	if not pac_enable_urlobj:GetBool() then return end

	-- if it's already downloaded just return it
	if callback and not forceReload and urlobj.Cache[url] then
		callback(urlobj.Cache[url])
		return
	end

	-- Add item to queue
	if not urlobj.Queue[url] then
		local queueItem = urlobj.CreateQueueItem(url)

		urlobj.Queue[url] = queueItem
		urlobj.QueueCount = urlobj.QueueCount + 1

		urlobj.DownloadQueue[url] = queueItem
		urlobj.DownloadQueueCount = urlobj.DownloadQueueCount + 1

		queueItem:BeginCacheRetrieval()

		queueItem:AddStatusCallback(
			function(finished, statusMessage)
				if not finished then return end

				urlobj.Queue[url] = nil
				urlobj.QueueCount = urlobj.QueueCount - 1

				urlobj.Cache[url] = queueItem:GetModel()
				urlobj.CacheCount = urlobj.CacheCount + 1
			end
		)
	end

	-- Add callbacks
	if callback       then urlobj.Queue[url]:AddCallback      (callback      ) end
	if statusCallback then
		urlobj.Queue[url]:AddStatusCallback(function(isFinished, mStatus)
			statusCallback(isFinished, mStatus ~= '' and mStatus or 'Queued for processing')
		end)
	end
end

local thinkThreads = {}
local PARSING_THERSOLD = CreateConVar('pac_obj_runtime', '0.002', {FCVAR_ARCHIVE}, 'Maximal parse runtime in seconds')
local PARSE_CHECK_LINES = 30

local function Think()
	local PARSING_THERSOLD = PARSING_THERSOLD:GetFloat()

	for i, threadData in ipairs(thinkThreads) do
		local statusCallback, co = threadData.statusCallback, threadData.co
		local t0 = SysTime ()
		local success, finished, statusMessage, msg
		while SysTime () - t0 < PARSING_THERSOLD do
			success, finished, statusMessage, msg = coroutine.resume(co)

			if not success then break end
			if finished    then break end
		end

		if not success then
			table.remove(thinkThreads, i)
			error(finished)
			statusCallback(true, "Decoding error")
		elseif finished then
			statusCallback(true, "Finished")
			table.remove(thinkThreads, i)
		else
			if statusMessage == "Preprocessing lines" then
				statusCallback(false, statusMessage .. " " .. msg)
			elseif msg then
				statusCallback(false, statusMessage .. " " .. math.Round(msg*100) .. " %")
			else
				statusCallback(false, statusMessage)
			end
		end

		break
	end
end

pac.AddHook('Think', 'parse_obj', Think)

local nextParsingHookId = 0
function urlobj.CreateModelFromObjData(objData, generateNormals, statusCallback)
	local mesh = Mesh()

	local co = coroutine.create (
		function ()
			local meshData = urlobj.ParseObj(objData, generateNormals)
			mesh:BuildFromTriangles (meshData)

			coroutine.yield (true)
		end
	)

	table.insert(thinkThreads, {
		objData = objData,
		generateNormals = generateNormals,
		statusCallback = statusCallback,
		co = co,
		mesh = mesh
	})

	statusCallback(false, 'Queued')

	return { mesh }
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
local string_sub    = string.sub
local string_Split  = string.Split
local string_Trim   = string.Trim
local table_concat  = table.concat
local table_insert  = table.insert

local Vector        = Vector

local facesMapper = '([0-9]+)/?([0-9]*)/?([0-9]*)'
local numberMatch = '(-?[0-9.+-e0-9]+)'
local vMatch = '^ *v *' .. numberMatch .. ' +' .. numberMatch .. ' +' .. numberMatch
local vtMatch = '^ *vt *' .. numberMatch .. ' +' .. numberMatch
local vnMatch = '^ *vn *' .. numberMatch .. ' +' .. numberMatch .. ' +' .. numberMatch
local ASYNC_PROCESSING = CreateConVar('pac_obj_async', '1', {FCVAR_ARCHIVE}, 'Process OBJ files in background')

function urlobj.ParseObj(data, generateNormals)
	local coroutine_yield = coroutine.running () and coroutine.yield or function () end
	if not ASYNC_PROCESSING:GetBool() then
		coroutine_yield = function () end
	end

	local positions  = {}
	local texCoordsU = {}
	local texCoordsV = {}
	local normals    = {}

	local triangleList = {}

	local lines = {}
	local faceLines = {}
	local vLines = {}
	local vtLines = {}
	local vnLines = {}
	local facesPreprocess = {}

	local i = 1
	local inContinuation    = false
	local continuationLines = nil

	local defaultNormal = Vector(0, 0, -1)

	for line in string_gmatch (data, "(.-)\r?\n") do
		if #line > 3 then
			local first = string_sub(line, 1, 1)
			if first ~= '#' and first ~= 'l' and first ~= 'g' and first ~= 'u' then
				if string_sub(line, #line) == '\\' then
					line = string_sub (line, 1, #line - 1)
					if inContinuation then
						continuationLines[#continuationLines + 1] = line
					else
						inContinuation    = true
						continuationLines = { line }
					end
				else
					local currLine

					if inContinuation then
						continuationLines[#continuationLines + 1] = line
						currLine = table_concat (continuationLines)
						first = string_sub(currLine, 1, 1)
						inContinuation    = false
						continuationLines = nil
					else
						currLine = line
					end

					local second = string_sub(currLine, 1, 2)

					if second == 'vt' then
						vtLines[#vtLines + 1] = currLine
					elseif second == 'vn' then
						vnLines[#vnLines + 1] = currLine
					elseif first == 'v' then
						vLines[#vLines + 1] = currLine
					elseif first == 'f' then
						facesPreprocess[#facesPreprocess + 1] = currLine
					else
						lines[#lines + 1] = currLine
					end
				end

				if i % PARSE_CHECK_LINES == 0 then
					coroutine_yield(false, "Preprocessing lines", i)
				end

				i = i + 1
			end
		end
	end

	if inContinuation then
		continuationLines[#continuationLines + 1] = line
		lines[#lines + 1] = table.concat (continuationLines)
		inContinuation    = false
		continuationLines = nil
	end

	coroutine_yield(false, "Preprocessing lines", i)

	local lineCount = #vtLines + #vnLines + #vLines + #facesPreprocess
	local inverseLineCount = 1 / lineCount
	local lineProcessed = 0

	for i, line in ipairs(vLines) do
		local x, y, z = string_match(line, vMatch)

		x, y, z = tonumber(x) or 0, tonumber(y) or 0, tonumber(z) or 0
		positions[#positions + 1] = Vector(x, y, z)

		if i % PARSE_CHECK_LINES == 0 then
			coroutine_yield(false, "Processing vertices", i * inverseLineCount)
		end
	end

	lineProcessed = #vLines

	for i, line in ipairs(vtLines) do
		local u, v = string_match(line, vtMatch)

		u, v = tonumber(u) or 0, tonumber(v) or 0

		local texCoordIndex = #texCoordsU + 1
		texCoordsU[texCoordIndex] =      u  % 1
		texCoordsV[texCoordIndex] = (1 - v) % 1

		if i % PARSE_CHECK_LINES == 0 then
			coroutine_yield(false, "Processing vertices", (i + lineProcessed) * inverseLineCount)
		end
	end

	lineProcessed = #vLines + #vtLines

	if not generateNormals then
		for i, line in ipairs(vnLines) do
			local nx, ny, nz = string_match(line, vnMatch)

			if nx and ny and nz then
				nx, ny, nz = tonumber(nx) or 0, tonumber(ny) or 0, tonumber(nz) or 0 -- possible / by zero

				local inverseLength = 1 / math_sqrt(nx * nx + ny * ny + nz * nz)
				nx, ny, nz = nx * inverseLength, ny * inverseLength, nz * inverseLength

				local normal = Vector(nx, ny, nz)
				normals[#normals + 1] = normal
			end

			if i % PARSE_CHECK_LINES == 0 then
				coroutine_yield(false, "Processing vertices", (i + lineProcessed) * inverseLineCount)
			end
		end
	end

	lineProcessed = #vLines + #vtLines + #vnLines

	for i, line in ipairs(facesPreprocess) do
		local matchLine = string_match(line, "^ *f +(.*)")

		if matchLine then
			-- Explode line
			local parts = {}

			for part in string_gmatch(matchLine, "[^ ]+") do
				parts[#parts + 1] = part
			end

			faceLines[#faceLines + 1] = parts

			if i % PARSE_CHECK_LINES == 0 then
				coroutine_yield(false, "Processing vertices", (i + lineProcessed) * inverseLineCount)
			end
		end
	end

	local lineCount = #lines
	local inverseLineCount = 1 / lineCount
	local i = 1

	while i <= lineCount do
		local processedLine = false

		-- Positions: v %f %f %f [%f]
		while i <= lineCount do
			local line = lines[i]
			local x, y, z = string_match(line, vMatch)
			if not x then break end

			processedLine = true
			x, y, z = tonumber(x) or 0, tonumber(y) or 0, tonumber(z) or 0
			positions[#positions + 1] = Vector(x, y, z)

			if i % PARSE_CHECK_LINES == 0 then
				coroutine_yield(false, "Processing vertices", i * inverseLineCount)
			end

			i = i + 1
		end

		if processedLine then
			coroutine_yield(false, "Processing vertices", i * inverseLineCount)
		end

		-- Texture coordinates: vt %f %f
		while i <= lineCount do
			local line = lines[i]
			local u, v = string_match(line, vtMatch)
			if not u then break end

			processedLine = true
			u, v = tonumber(u) or 0, tonumber(v) or 0

			local texCoordIndex = #texCoordsU + 1
			texCoordsU[texCoordIndex] =      u  % 1
			texCoordsV[texCoordIndex] = (1 - v) % 1

			if i % PARSE_CHECK_LINES == 0 then
				coroutine_yield(false, "Processing vertices", i * inverseLineCount)
			end

			i = i + 1
		end

		if processedLine then
			coroutine_yield(false, "Processing vertices", i * inverseLineCount)
		end

		-- Normals: vn %f %f %f
		while i <= lineCount do
			local line = lines[i]
			local nx, ny, nz = string_match(line, vnMatch)
			if not nx then break end

			processedLine = true

			if not generateNormals then
				nx, ny, nz = tonumber(nx) or 0, tonumber(ny) or 0, tonumber(nz) or 0

				local inverseLength = 1 / math_sqrt(nx * nx + ny * ny + nz * nz)
				nx, ny, nz = nx * inverseLength, ny * inverseLength, nz * inverseLength

				local normal = Vector(nx, ny, nz)
				normals[#normals + 1] = normal
			end

			if i % PARSE_CHECK_LINES == 0 then
				coroutine_yield(false, "Processing vertices", i * inverseLineCount)
			end

			i = i + 1
		end

		if processedLine then
			coroutine_yield(false, "Processing vertices", i * inverseLineCount)
		end

		-- Faces: f %f %f %f+
		while i <= lineCount do
			local line = lines[i]
			local matchLine = string_match(line, "^ *f +(.*)")
			if not matchLine then break end

			processedLine = true

			-- Explode line
			local parts = {}

			for part in string_gmatch(matchLine, "[^ ]+") do
				parts[#parts + 1] = part
			end

			faceLines[#faceLines + 1] = parts

			if i % PARSE_CHECK_LINES == 0 then
				coroutine_yield(false, "Processing vertices", i * inverseLineCount)
			end

			i = i + 1
		end

		if processedLine then
			coroutine_yield(false, "Processing vertices", i * inverseLineCount)
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

		if #parts >= 3 then
			-- are they always integers?
			local v1PositionIndex, v1TexCoordIndex, v1NormalIndex = string_match(parts[1], facesMapper)
			local v3PositionIndex, v3TexCoordIndex, v3NormalIndex = string_match(parts[2], facesMapper)

			v1PositionIndex, v1TexCoordIndex, v1NormalIndex = tonumber(v1PositionIndex), tonumber(v1TexCoordIndex), tonumber(v1NormalIndex)
			v3PositionIndex, v3TexCoordIndex, v3NormalIndex = tonumber(v3PositionIndex), tonumber(v3TexCoordIndex), tonumber(v3NormalIndex)

			for i = 3, #parts do
				local v2PositionIndex, v2TexCoordIndex, v2NormalIndex = string_match(parts[i], facesMapper)
				v2PositionIndex, v2TexCoordIndex, v2NormalIndex = tonumber(v2PositionIndex), tonumber(v2TexCoordIndex), tonumber(v2NormalIndex)

				local v1 = { pos_index = nil, pos = nil, u = nil, v = nil, normal = nil, userdata = nil }
				local v2 = { pos_index = nil, pos = nil, u = nil, v = nil, normal = nil, userdata = nil }
				local v3 = { pos_index = nil, pos = nil, u = nil, v = nil, normal = nil, userdata = nil }

				v1.pos_index = v1PositionIndex
				v2.pos_index = v2PositionIndex
				v3.pos_index = v3PositionIndex

				v1.pos = positions[v1PositionIndex]
				v2.pos = positions[v2PositionIndex]
				v3.pos = positions[v3PositionIndex]

				if #texCoordsU > 0 then
					v1.u = texCoordsU[v1TexCoordIndex] or 0
					v1.v = texCoordsV[v1TexCoordIndex] or 0

					v2.u = texCoordsU[v2TexCoordIndex] or 0
					v2.v = texCoordsV[v2TexCoordIndex] or 0

					v3.u = texCoordsU[v3TexCoordIndex] or 0
					v3.v = texCoordsV[v3TexCoordIndex] or 0
				else
					v1.u, v1.v = 0, 0
					v2.u, v2.v = 0, 0
					v3.u, v3.v = 0, 0
				end

				if #normals > 0 then
					v1.normal = normals[v1NormalIndex]
					v2.normal = normals[v2NormalIndex]
					v3.normal = normals[v3NormalIndex]
				else
					v1.normal = defaultNormal
					v2.normal = defaultNormal
					v3.normal = defaultNormal
				end

				triangleList [#triangleList + 1] = v1
				triangleList [#triangleList + 1] = v2
				triangleList [#triangleList + 1] = v3

				v3PositionIndex, v3TexCoordIndex, v3NormalIndex = v2PositionIndex, v2TexCoordIndex, v2NormalIndex
			end
		end

		if i % PARSE_CHECK_LINES == 0 then
			coroutine_yield(false, "Processing faces", i * inverseFaceLineCount)
		end
	end

	coroutine_yield(false, "Processing faces", faceLineCount)

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

			if i % PARSE_CHECK_LINES == 0 then
				coroutine_yield(false, "Generating normals", i * inverseTriangleCount)
			end
		end

		coroutine_yield(false, "Generating normals", triangleCount)

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

	do
		-- Lengyel, Eric. “Computing Tangent Space Basis Vectors for an Arbitrary Mesh”. Terathon Software, 2001. http://terathon.com/code/tangent.html
		local tan1 = {}
		local tan2 = {}
		local vertexCount = #triangleList

		for i = 1, vertexCount do
			tan1[i] = Vector(0, 0, 0)
			tan2[i] = Vector(0, 0, 0)
		end

		for i = 1, vertexCount - 2, 3 do
			local vert1, vert2, vert3 = triangleList[i], triangleList[i+1], triangleList[i+2]

			local p1, p2, p3 = vert1.pos, vert2.pos, vert3.pos
			local u1, u2, u3 = vert1.u, vert2.u, vert3.u
			local v1, v2, v3 = vert1.v, vert2.v, vert3.v

			local x1 = p2.x - p1.x;
			local x2 = p3.x - p1.x;
			local y1 = p2.y - p1.y;
			local y2 = p3.y - p1.y;
			local z1 = p2.z - p1.z;
			local z2 = p3.z - p1.z;

			local s1 = u2 - u1;
			local s2 = u3 - u1;
			local t1 = v2 - v1;
			local t2 = v3 - v1;

			local r = 1 / (s1 * t2 - s2 * t1)
			local sdir = Vector((t2 * x1 - t1 * x2) * r, (t2 * y1 - t1 * y2) * r, (t2 * z1 - t1 * z2) * r);
			local tdir = Vector((s1 * x2 - s2 * x1) * r, (s1 * y2 - s2 * y1) * r, (s1 * z2 - s2 * z1) * r);

			tan1[i]:Add(sdir)
			tan1[i+1]:Add(sdir)
			tan1[i+2]:Add(sdir)

			tan2[i]:Add(tdir)
			tan2[i+1]:Add(tdir)
			tan2[i+2]:Add(tdir)
		end

		local tangent = {}
		for i = 1, vertexCount do
			local n = triangleList[i].normal
			local t = tan1[i]

			local tan = (t - n * n:Dot(t))
			tan:Normalize()

			local w = (n:Cross(t)):Dot(tan2[i]) < 0 and -1 or 1

			triangleList[i].userdata = {tan[1], tan[2], tan[3], w}
		end
	end

	return triangleList
end

-- Download queuing
function urlobj.DownloadQueueThink()
	if pac.urltex and pac.urltex.Busy then return end

	for url, queueItem in pairs(urlobj.DownloadQueue) do
		if not queueItem:IsDownloading() and
		   not queueItem:IsCacheDecodeFinished () then
			queueItem:SetStatus("Queued for download (" .. urlobj.DownloadQueueCount .. " items in queue)")
		end

		-- Check for download timeout
		if queueItem:IsDownloading() and
		   queueItem:HasDownloadTimedOut() then
			pac.dprint("model download timed out for the %s time %q", queueItem:GetDownloadAttemptCount(), queueItem:GetUrl())

			queueItem:AbortDownload()

			if queueItem:GetDownloadAttemptCount() > 3 then
				-- Give up
				urlobj.Queue[url] = nil
				urlobj.QueueCount = urlobj.QueueCount - 1

				urlobj.DownloadQueue[url] = nil
				urlobj.DownloadQueueCount = urlobj.DownloadQueueCount - 1

				CURRENTLY_DOWNLOADING = CURRENTLY_DOWNLOADING - 1
				pac.dprint("model download timed out for good %q", url)
			else
				-- Reattempt download
				queueItem:BeginDownload()
			end
		end
	end

	urlobj.Busy = next (urlobj.Queue) ~= nil
	if CURRENTLY_DOWNLOADING >= SIMULATENOUS_DOWNLOADS:GetInt() then return end

	-- Start download of next item in queue
	if next(urlobj.DownloadQueue) then
		for url, queueItem in pairs(urlobj.DownloadQueue) do
			if not queueItem:IsDownloading() then
				queueItem:BeginDownload()

				queueItem:AddDownloadCallback(
					function()
						urlobj.DownloadQueue[url] = nil
						urlobj.DownloadQueueCount = urlobj.DownloadQueueCount - 1
						CURRENTLY_DOWNLOADING = CURRENTLY_DOWNLOADING - 1
					end
				)

				CURRENTLY_DOWNLOADING = CURRENTLY_DOWNLOADING + 1
				pac.dprint("requesting model download %q", url)
				if CURRENTLY_DOWNLOADING >= SIMULATENOUS_DOWNLOADS:GetInt() then return end
			end
		end
	end
end

timer.Create("urlobj_download_queue", 0.1, 0, urlobj.DownloadQueueThink)
