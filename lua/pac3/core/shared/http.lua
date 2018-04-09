CreateConVar("pac_webcontent_limit", "-1", {FCVAR_ARCHIVE}, "webcontent limit, -1 = unlimited, 1024 = 1mb")
CreateConVar("pac_webcontent_allow_no_content_length", "0", {FCVAR_ARCHIVE}, "allow downloads with no content length")

CreateConVar("sv_pac_webcontent_limit", "-1", {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "webcontent limit, -1 = unlimited, 1024 = 1mb")
CreateConVar("sv_pac_webcontent_allow_no_content_length", "-1", {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "allow downloads with no content length")

local function get(url, cb, failcb)
	return HTTP({
		method = "GET",
		url = url,
		success = function(code, data, headers)
			if code ~= 200 then
				failcb("server returned code " .. code, code == 401 or code == 404 or code == 503 or code == 501)
				return
			end

			cb(data, len, headers)
		end,
		failed = function(err)
			failcb(err)
		end
	})
end

function pac.HTTPGet(url, cb, failcb)
	if not url or url:len() < 4 then
		failcb("url length is less than 4 (" .. url .. ")", true)
		return
	end

	url = url:Trim()

	if url:find("dropbox", 1, true) then
		url = url:gsub([[^http%://dl%.dropboxusercontent%.com/]], [[https://dl.dropboxusercontent.com/]])
		url = url:gsub([[^https?://dl.dropbox.com/]], [[https://www.dropbox.com/]])
		url = url:gsub([[^https?://www.dropbox.com/s/(.+)%?dl%=[01]$]], [[https://dl.dropboxusercontent.com/s/%1]])
		url = url:gsub([[^https?://www.dropbox.com/s/(.+)$]], [[https://dl.dropboxusercontent.com/s/%1]])
	elseif url:find("drive.google.com", 1, true) and not url:find("export=download", 1, true) then
		local id = url:match("https://drive.google.com/file/d/(.-)/") or url:match("https://drive.google.com/file/d/(.-)$")
		if id then
			url = "https://drive.google.com/uc?export=download&id=" .. id
		end
	end

	url = url:gsub([[^http%://onedrive%.live%.com/redir?]],[[https://onedrive.live.com/download?]])
	url = url:gsub("pastebin.com/([a-zA-Z0-9]*)$", "pastebin.com/raw.php?i=%1")
	url = url:gsub("github.com/([a-zA-Z0-9_]+)/([a-zA-Z0-9_]+)/blob/", "github.com/%1/%2/raw/")

	local limit = GetConVarNumber("pac_webcontent_limit")
	local sv_limit = GetConVarNumber("sv_pac_webcontent_limit")

	if sv_limit ~= -1 then
		limit = sv_limit
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
				local len = headers["Content-Length"]
				if len then
					len = tonumber(len)
					if len <= (limit * 1024) then
						get(url, cb, failcb)
					else
						failcb("download is too big ("..string.NiceSize(len)..")", true)
					end
				else
					local allow_no_contentlength = GetConVarNumber("pac_webcontent_allow_no_content_length")
					local sv_allow_no_contentlength = GetConVarNumber("sv_pac_webcontent_allow_no_content_length")

					if sv_allow_no_contentlength ~= -1 then
						allow_no_contentlength = sv_allow_no_contentlength
					end

					if allow_no_contentlength == 1 then
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

pac.HTTPGet("https://docs.google.com/uc?export=download&id=0B4QDw71zow0ZZG41emxaTjZfdEk", print, print)