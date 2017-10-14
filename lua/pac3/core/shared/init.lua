include("util.lua")
include("pac3/libraries/sh_boneanimlib.lua")

include("footsteps_fix.lua")

function pac.SimpleFetch(url, cb, failcb, printError)
	if not url or url:len() < 4 then return end

	if printError == nil then
		printError = true
	end

	url = pac.FixupURL(url)

	http.Fetch(
		url,

		function(data, len, headers, code)
			if code ~= 200 then
				if printError then
					pac.Message('URL ', url, ' failed to download: server returned ', code)
				end

				if failcb then
					failcb(code, data, len, headers)
				end

				return
			end

			cb(data, len, headers)
		end,

		function(err)
			if printError then
				pac.Message('URL ', url, ' failed to download: stream error ', err)
			end

			if failcb then
				failcb(err)
			end
		end
	)
end

CreateConVar("pac_sv_draw_distance", 0, bit.bor(FCVAR_REPLICATED, FCVAR_ARCHIVE))
CreateConVar("pac_sv_hide_outfit_on_death", 0, bit.bor(FCVAR_REPLICATED, FCVAR_ARCHIVE))
