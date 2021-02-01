
local CL_LIMIT, CL_LIMIT_OVERRIDE, CL_NO_CLENGTH

if CLIENT then
	CL_LIMIT = CreateConVar("pac_webcontent_limit", "-1", {FCVAR_ARCHIVE}, "webcontent limit, -1 = unlimited, 1024 = 1mb")
	CL_NO_CLENGTH = CreateConVar("pac_webcontent_allow_no_content_length", "0", {FCVAR_ARCHIVE}, "allow downloads with no content length")
	CL_LIMIT_OVERRIDE = CreateConVar("pac_webcontent_limit_force", "0", {FCVAR_ARCHIVE}, "Override serverside setting")
end

local SV_LIMIT = CreateConVar("sv_pac_webcontent_limit", "-1", CLIENT and {FCVAR_REPLICATED} or {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "webcontent limit, -1 = unlimited, 1024 = 1mb")
local SV_NO_CLENGTH = CreateConVar("sv_pac_webcontent_allow_no_content_length", "-1", CLIENT and {FCVAR_REPLICATED} or {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "allow downloads with no content length")

function pac.FixGMODUrl(url)
	-- to avoid "invalid url" errors
	-- gmod does not allow urls containing "10.", "172.16.", "192.168.", "127." or "://localhost"
	-- we escape 10. and 127. can occur (mydomain.com/model10.zip) and assume the server supports
	-- the escaped request
	return url:Replace("10.", "%31%30%2e"):Replace("127.", "%31%32%37%2e")
end

local function http(method, url, headers, cb, failcb)

	url = pac.FixGMODUrl(url)

	return HTTP({
		method = method,
		url = url,
		headers = headers,
		success = function(code, data, headers)
			if code < 400 then
				cb(data, #data, headers)
			else
				local header = {}
				for k,v in pairs(headers) do
					table.insert(header, tostring(k) .. ": " .. tostring(v))
				end

				local err = "server returned code " .. code .. ":\n\n"
				err = err .. "url: "..url.."\n"
				err = err .. "================\n"

				err = err .. "HEADER:\n"
				err = err .. table.concat(header, "\n") .. "\n"

				err = err .. "================\n"

				err = err .. "BODY:\n"
				err = err .. data .. "\n"

				err = err .. "================\n"
				failcb(err, code >= 400)
			end
		end,
		failed = function(err)
			failcb("_G.HTTP error: " .. err)
		end
	})
end

function pac.FixUrl(url)
	url = url:Trim()

	if url:find("dropbox", 1, true) then
		url = url:gsub([[^http%://dl%.dropboxusercontent%.com/]], [[https://dl.dropboxusercontent.com/]])
		url = url:gsub([[^https?://dl.dropbox.com/]], [[https://www.dropbox.com/]])
		url = url:gsub([[^https?://www.dropbox.com/s/(.+)%?dl%=[01]$]], [[https://dl.dropboxusercontent.com/s/%1]])
		url = url:gsub([[^https?://www.dropbox.com/s/(.+)$]], [[https://dl.dropboxusercontent.com/s/%1]])
		return url
	end

	if url:find("drive.google.com", 1, true) and not url:find("export=download", 1, true) then
		local id =
			url:match("https://drive.google.com/file/d/(.-)/") or
			url:match("https://drive.google.com/file/d/(.-)$") or
			url:match("https://drive.google.com/open%?id=(.-)$")

		if id then
			return "https://drive.google.com/uc?export=download&id=" .. id
		end
		return url
	end

	if url:find("gitlab.com", 1, true) then
		return url:gsub("^(https?://.-/.-/.-/)blob", "%1raw")
	end

	url = url:gsub([[^http%://onedrive%.live%.com/redir?]],[[https://onedrive.live.com/download?]])
	url = url:gsub("pastebin.com/([a-zA-Z0-9]*)$", "pastebin.com/raw.php?i=%1")
	url = url:gsub("github.com/([a-zA-Z0-9_]+)/([a-zA-Z0-9_]+)/blob/", "github.com/%1/%2/raw/")

	return url
end

function pac.HTTPGet(url, cb, failcb)
	if not url or url:len() < 4 then
		failcb("url length is less than 4 (" .. tostring(url) .. ")", true)
		return
	end

	url = pac.FixUrl(url)

	local limit = SV_LIMIT:GetInt()

	if CLIENT and (CL_LIMIT_OVERRIDE:GetBool() or limit == -1) then
		limit = CL_LIMIT:GetInt()
	end

	if limit == -1 then
		return http("GET", url, nil, cb, failcb)
	end

	return http("HEAD", url, {["Accept-Encoding"] = "none"}, function(data, data_length, headers)
		-- server have rights to send headers in any case
		for key, value in pairs(headers) do
			if string.lower(key) == "content-length" then
				length = tonumber(value)

				if not length or math.floor(length) ~= length then
					failcb(string.format("malformed server reply with header content-length (got %q, expected valid integer number)", value), true)
					return
				end

				break
			end
		end

		if length then
			if length <= (limit * 1024) then
				http("GET", url, nil, cb, failcb)
			else
				failcb("download is too big (" .. string.NiceSize(length) .. ")", true)
			end
		else
			local allow_no_contentlength = SV_NO_CLENGTH:GetInt()

			if CLIENT and (CL_LIMIT_OVERRIDE:GetBool() or allow_no_contentlength < 0) then
				allow_no_contentlength = CL_NO_CLENGTH:GetInt()
			end

			if allow_no_contentlength > 0 then
				http("GET", url, nil, cb, failcb)
			else
				failcb("unknown file size when allow_no_contentlength is " .. allow_no_contentlength, true)
			end
		end
	end, failcb)
end
