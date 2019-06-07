local resource = {}
local luadata = include("luadata.lua")

local function llog(...)
	print("[resource] ", ...)
end

local function wlog(...)
	print("[resource warning] ", ...)
end

local function R(path)
	if file.Exists(path, "DATA") then
		return path
	end
end

local function utility_CreateCallbackThing(cache)
	cache = cache or {}
	local self = {}

	function self:check(path, callback, extra)
		if cache[path] then
			if cache[path].extra_callbacks then
				for key, old in pairs(cache[path].extra_callbacks) do
					local callback = extra[key]
					if callback then
						cache[path].extra_callbacks[key] = function(...)
							old(...)
							callback(...)
						end
					end

				end
			end

			if cache[path].callback then
				if type(cache[path].callback) ~= 'table' then cache[path].callback = {cache[path].callback} end
				table.insert(cache[path].callback, callback)
				return true
			end
		end
	end

	function self:start(path, callback, extra)
		if type(callback) ~= 'table' then callback = {callback} end
		cache[path] = {callback = table.Copy(callback), extra_callbacks = table.Copy(extra or {})}
	end

	function self:callextra(path, key, out)
		if not cache[path] or not cache[path].extra_callbacks[key] then return end
		return cache[path].extra_callbacks[key](out)
	end

	function self:stop(path, out, ...)
		if not cache[path] then return end

		if type(cache[path].callback) == 'table' then
			for i, func in ipairs(cache[path].callback) do
				func(out, ...)
			end
		elseif cache[path].callback then
			cache[path].callback(out, ...)
		end

		cache[path] = out
	end

	function self:get(path)
		return cache[path]
	end

	function self:uncache(path)
		cache[path] = nil
	end

	return self
end

local DOWNLOAD_FOLDER = "pac3_cache/downloads/"
local etags_file = "pac3_cache/resource_etags.txt"

file.CreateDir(DOWNLOAD_FOLDER)

local function rename_file(a, b)
	local str_a = file.Read(a, "DATA")
	file.Delete(a, "DATA")
	file.Write(b, str_a)

	return true
end

local function download(from, to, callback, on_fail, on_header, check_etag, etag_path_override, need_extension)
	if check_etag then
		local data = luadata.ReadFile(etags_file)
		local etag = data[etag_path_override or from]

		--llog("checking if ", etag_path_override or from, " has been modified. etag is: ", etag)

		HTTP({
			method = "HEAD",
			url = from,
			success = function(code, body, header)
				local res = header.ETag or header["Last-Modified"]

				if not res then return end

				if res ~= etag then
					if etag then
						llog(from, ": etag has changed ", res)
					else
						llog(from, ": no previous etag stored", res)
					end
					download(from, to, callback, on_fail, on_header, nil, etag_path_override, need_extension)
				else
					--llog(from, ": etag is the same")
					check_etag()
				end
			end,
		})

		return
	end

	local file

	local allowed = {
		[".txt"] = true,
		[".jpg"] = true,
		[".png"] = true,
		[".vtf"] = true,
		[".dat"] = true,
	}

	return pac.HTTPGet(
		from,
		function(body, len, header)
			do
				if need_extension then
					local ext = header["Content-Type"] and (header["Content-Type"]:match(".-/(.-);") or header["Content-Type"]:match(".-/(.+)")) or "dat"
					if ext == "jpeg" then ext = "jpg" end

					if body:StartWith("VTF") then
						ext = "vtf"
					end

					if allowed["." .. ext] then
						to = to .. "." .. ext
					else
						to = to .. ".dat"
					end
				end

				local file_, err = _G.file.Open(DOWNLOAD_FOLDER .. to .. "_temp.dat", "wb", "DATA")
				file = file_

				if not file then
					llog("resource download error: ", err)
					on_fail()
					return false
				end

				local etag = header.ETag or header["Last-Modified"]

				if etag then
					local data = luadata.ReadFile(etags_file) or {}
					data[etag_path_override or from] = etag
					luadata.WriteFile(etags_file)
				end

				on_header(header)
			end

			file:Write(body)
			file:Close()


			local full_path = DOWNLOAD_FOLDER .. to .. "_temp.dat"
			if full_path then
				local ok, err = rename_file(full_path, full_path:gsub("(.+)_temp%.dat", "%1"))

				if not ok then
					llog("unable to rename %q: %s", full_path, err)
					on_fail()
					return
				end

				local full_path = R(DOWNLOAD_FOLDER .. to)

				if full_path then
					resource.BuildCacheFolderList(full_path:match(".+/(.+)"))

					callback(full_path)

					--llog("finished donwnloading ", from)
				else
					wlog("resource download error: %q not found!", DOWNLOAD_FOLDER .. to)
					on_fail()
				end
			else
				wlog("resource download error: %q not found!", DOWNLOAD_FOLDER .. to)
				on_fail()
			end
		end,
		function(...)
			on_fail(...)
		end
	)
end

local cb = utility_CreateCallbackThing()
local ohno = false

function resource.Download(path, callback, on_fail, crc, check_etag)
	on_fail = on_fail or function(reason) llog(path, ": ", reason) end

	local url
	local existing_path
	local need_extension

	if path:find("^.-://") then
		local redownload = false

		if path:StartWith("_") then
			path = path:sub(2)
			redownload = true
		end

		if not resource.url_cache_lookup then
			resource.BuildCacheFolderList()
		end

		url = path
		local crc = (crc or util.CRC(path))

		if not redownload and resource.url_cache_lookup[crc] then
			path = resource.url_cache_lookup[crc]
			existing_path = R(DOWNLOAD_FOLDER .. path)
			need_extension = false
		else
			path = crc
			existing_path = false
			need_extension = true
		end
	end

	if not existing_path then
		check_etag = nil
	end

	if not ohno then
		local old = callback
		callback = function(path)
			if old then old(path) end
		end
	end

	if existing_path and not check_etag then
		ohno = true

		if type(callback) == 'function' then
			callback(existing_path)
		elseif type(callback) == 'table' then
			for i, func in ipairs(callback) do
				func(existing_path)
			end
		end

		ohno = false
		return true
	end

	if check_etag then
		check_etag = function()
			if ohno then return end
			ohno = true
			cb:callextra(path, "check_etag", existing_path)
			ohno = false
			cb:stop(path, existing_path)
			cb:uncache(path)
		end
	end

	if cb:check(path, callback, {on_fail = on_fail, check_etag = check_etag}) then return true end

	cb:start(path, callback, {on_fail = on_fail, check_etag = check_etag})

	if url then
		if not check_etag then
			-- llog("downloading ", url)
		end

		download(
			url,
			path,
			function(...)
				cb:stop(path, ...)
				cb:uncache(path)
			end,
			function(...)
				cb:callextra(path, "on_fail", ... or path .. " not found")
				cb:uncache(path)
			end,
			function(header)
				-- check file crc stuff here/
				return true
			end,
			check_etag,
			nil,
			need_extension
		)

		return true
	end
end

function resource.BuildCacheFolderList(file_name)
	if not resource.url_cache_lookup then
		local tbl = {}
		for _, file_name in ipairs((file.Find(DOWNLOAD_FOLDER, "DATA"))) do
			local name = file_name:match("(%d)%.")
			if name then
				tbl[name] = file_name
			else
				llog("bad file in downloads/cache folder: ", file_name)
				file.Delete(DOWNLOAD_FOLDER .. file_name)
			end
		end
		resource.url_cache_lookup = tbl
	end

	if file_name then
		resource.url_cache_lookup[file_name:match("(.-)%.")] = file_name
	end
end

function resource.ClearDownloads()
	local dirs = {}

	for _, path in ipairs((vfs.Find(DOWNLOAD_FOLDER))) do
		file.Delete(DOWNLOAD_FOLDER .. path)
	end

	resource.BuildCacheFolderList()
end

function resource.CheckDownloadedFiles()
	local files = luadata.ReadFile(etags_file)
	local count = table.Count(files)

	llog("checking " .. count .. " files for updates..")

	local i = 0

	for path, etag in pairs(files) do
		resource.Download(path, function() i = i + 1 if i == count then llog("done checking for file updates") end end, llog, nil, true)
	end
end

if CLIENT then

	local memory = {}

	timer.Create("pac3_resource_gc", 0.25, 0, function()
		for k,v in pairs(memory) do
			if not v.ply:IsValid() then
				memory[k] = nil
				file.Delete(v.path)
			end
		end
	end)

	pac.AddHook("ShutDown", "resource_gc", function()
		for _, name in ipairs((file.Find(DOWNLOAD_FOLDER .. "*", "DATA"))) do
			file.Delete(DOWNLOAD_FOLDER .. name)
		end
	end)

	function resource.DownloadTexture(url, callback, ply)
		if not url:find("^.-://") then return end

		return resource.Download(
			url,
			function(path)
				local frames
				local mat

				if path:EndsWith(".vtf") then
					local f = file.Open(path, "rb", "DATA")
					f:Seek(24)
					frames = f:ReadShort()
					f:Close()

					mat = CreateMaterial(tostring({}), "VertexLitGeneric", {})
					mat:SetTexture("$basetexture", "../data/" .. path)
				else
					mat = Material("../data/" .. path, "mips smooth noclamp")
				end

				local tex = mat:GetTexture("$basetexture")
				if tex then
					callback(tex, frames)

					memory[url] = {ply = ply, path = path}
				elseif ply == pac.LocalPlayer then
					pac.Message(Color(255, 50, 50), "$basetexture from ", url, " is nil")
				end
			end,
			function()

			end
		)
	end
end

return resource