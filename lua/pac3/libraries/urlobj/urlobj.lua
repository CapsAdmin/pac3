pac.urlobj = pac.urlobj or {}
local urlobj = pac.urlobj

urlobj.DataCache  = pac.CreateCache("objcache")

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

	for _, part in pairs(pac.GetParts()) do
		if part.ClassName == "model" then
			part:SetModel(part:GetModel())
		end
	end
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
end

function urlobj.GetObjFromURL(url, forceReload, generateNormals, callback, statusCallback)
	if not pac_enable_urlobj:GetBool() then return end

	url = pac.FixupURL(url)

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
	if statusCallback then urlobj.Queue[url]:AddStatusCallback(statusCallback) end
end

local thinkThreads = {}
local PARSING_THERSOLD = CreateConVar('pac_parse_runtime', '0.01', {FCVAR_ARCHIVE}, 'Maximal parse runtime in seconds')
local PARSE_CHECK_LINES = 50

local function Think()
	local PARSING_THERSOLD = PARSING_THERSOLD:GetFloat()

	for i, threadData in ipairs(thinkThreads) do
		if i ~= 1 then
			threadData.statusCallback(false, 'Queued for processing')
		end
	end

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

hook.Add('Think', 'pac_parse_obj', Think)

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
	local inContinuation    = false
	local continuationLines = nil
	for line in string_gmatch (data, "(.-)\n") do
		local passOne, passTwo = string_sub(line, #line), string_sub(line, #line - 1)
		if passOne == '\\' then
			line = string_sub (line, 1, -2)
			if inContinuation then
				continuationLines[#continuationLines + 1] = line
			else
				inContinuation    = true
				continuationLines = { line }
			end
		elseif passTwo == '\\\r' then
			line = string_sub (line, 1, -3)
			if inContinuation then
				continuationLines[#continuationLines + 1] = line
			else
				inContinuation    = true
				continuationLines = { line }
			end
		else
			if inContinuation then
				continuationLines[#continuationLines + 1] = line
				lines[#lines + 1] = table_concat (continuationLines)
				inContinuation    = false
				continuationLines = nil
			else
				lines[#lines + 1] = line
			end
		end

		if i % PARSE_CHECK_LINES == 0 then
			coroutine_yield(false, "Preprocessing lines", i)
		end

		i = i + 1
	end

	if inContinuation then
		continuationLines[#continuationLines + 1] = line
		lines[#lines + 1] = table.concat (continuationLines)
		inContinuation    = false
		continuationLines = nil
	end

	local lineCount = #lines
	local inverseLineCount = 1 / lineCount
	local i = 1
	while i <= lineCount do
		local processedLine = false

		-- Positions: v %f %f %f [%f]
		while i <= lineCount do
			local line = lines[i]
			local x, y, z = string_match(line, "^ *v *(-?[0-9.]+) *(-?[0-9.]+) *(-?[0-9.]+)")
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
			local u, v = string_match(line, "^ *vt *(-?[0-9.]+) *(-?[0-9.]+)")
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
			local nx, ny, nz = string_match(line, "^ *vn *(-?[0-9.]+) *(-?[0-9.]+) *(-?[0-9.]+)")
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
			if not string_match(line, "^%s*f%s+") then break end

			processedLine = true
			line = string_match (line, "^%s*(.-)[#%s]*$")

			-- Explode line
			local parts = {}
			for part in string_gmatch(line, "[^%s]+") do
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

				pac.dprint("model download timed out for good %q", url)
			else
				-- Reattempt download
				queueItem:BeginDownload()
			end
			return
		end
	end

	-- Start download of next item in queue
	if next(urlobj.DownloadQueue) then
		local url, queueItem = next(urlobj.DownloadQueue)
		if not queueItem:IsDownloading() then
			queueItem:BeginDownload()

			queueItem:AddDownloadCallback(
				function()
					urlobj.DownloadQueue[url] = nil
					urlobj.DownloadQueueCount = urlobj.DownloadQueueCount - 1
				end
			)

			pac.dprint("requesting model download %q", url)
		end
	end

	urlobj.Busy = next (urlobj.Queue) ~= nil
end

timer.Create("urlobj_download_queue", 0.1, 0, urlobj.DownloadQueueThink)
