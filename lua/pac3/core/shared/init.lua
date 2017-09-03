include("pac3/libraries/sh_boneanimlib.lua")

include("footsteps_fix.lua")

function pac.SimpleFetch(url,cb,failcb)
	if not url or url:len()<4 then return end

	url = pac.FixupURL(url)

	http.Fetch(url,
	function(data,len,headers,code)
		if code~=200 then
			Msg"[PAC] Url "print(string.format("failed loading %s (server returned %s)",url,tostring(code)))
			if failcb then
				failcb(code,data,len,headers)
			end
			return
		end
		cb(data,len,headers)
	end,
	function(err)
		Msg"[PAC] Url "print(string.format("failed loading %s (%s)",url,tostring(err)))
		if failcb then
			failcb(err)
		end
	end)
end

CreateConVar("pac_sv_draw_distance", 0, bit.bor(FCVAR_REPLICATED, FCVAR_ARCHIVE))
CreateConVar("pac_sv_hide_outfit_on_death", 0, bit.bor(FCVAR_REPLICATED, FCVAR_ARCHIVE))
