
local CL_LIMIT, CL_LIMIT_OVERRIDE, CL_NO_CLENGTH

if CLIENT then
	CL_LIMIT = CreateConVar("pac_webcontent_limit", "-1", {FCVAR_ARCHIVE}, "webcontent limit, -1 = unlimited, 1024 = 1mb")
	CL_NO_CLENGTH = CreateConVar("pac_webcontent_allow_no_content_length", "0", {FCVAR_ARCHIVE}, "allow downloads with no content length")
	CL_LIMIT_OVERRIDE = CreateConVar("pac_webcontent_limit_force", "0", {FCVAR_ARCHIVE}, "Override serverside setting")
end

local SV_LIMIT = CreateConVar("sv_pac_webcontent_limit", "-1", CLIENT and {FCVAR_REPLICATED} or {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "webcontent limit, -1 = unlimited, 1024 = 1mb")
local SV_NO_CLENGTH = CreateConVar("sv_pac_webcontent_allow_no_content_length", "-1", CLIENT and {FCVAR_REPLICATED} or {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "allow downloads with no content length")

local function get(url, cb, failcb)
	return HTTP({
		method = "GET",
		url = url,
		success = function(code, data, headers)
			if code ~= 200 then
				failcb("server returned code " .. code, code == 401 or code == 404 or code == 503 or code == 501)
				return
			end

			cb(data, #data, headers)
		end,
		failed = function(err)
			failcb(err)
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
		failcb("url length is less than 4 (" .. url .. ")", true)
		return
	end

	url = pac.FixUrl(url)

	local limit = SV_LIMIT:GetInt()

	if CLIENT and (CL_LIMIT_OVERRIDE:GetBool() or limit == -1) then
		limit = CL_LIMIT:GetInt()
	end

	if limit == -1 then
		return get(url, cb, failcb)
	else
		return HTTP({
			method = "HEAD",
			url = url,
			headers = {
				["Accept-Encoding"] = "none"
			},
			success = function(code, data, headers)
				local length

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
						get(url, cb, failcb)
					else
						failcb("download is too big (" .. string.NiceSize(length) .. ")", true)
					end
				else
					local allow_no_contentlength = SV_NO_CLENGTH:GetInt()

					if CLIENT and (CL_LIMIT_OVERRIDE:GetBool() or allow_no_contentlength < 0) then
						allow_no_contentlength = CL_NO_CLENGTH:GetInt()
					end

					if allow_no_contentlength > 0 then
						get(url, cb, failcb)
					else
						failcb("unknown file size when allow_no_contentlength is " .. allow_no_contentlength, true)
					end
				end
			end,
			failed = function(err)
				failcb(err)
			end
		})
	end
end
