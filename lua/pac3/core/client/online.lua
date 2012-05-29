local function SteamIDToCommunityID(id)
	if id == "BOT" or id == "STEAM_ID_PENDING" or id == "UNKNOWN" then
		return 0
	end

	local parts = id:Split(":")
	local a, b = parts[2], parts[3]

	return tostring("7656119" .. 7960265728 + a + (b*2))
end

function pac.GetSteamPartURL(steamid, callback)
	if IsEntity(steamid) and steamid.SteamID then
		steamid = steamid:SteamID()
	end

	local url = ("http://steamcommunity.com/profiles/%s/?xml=1"):format(SteamIDToCommunityID(steamid))

	http.Get(url, "", function(str)
		callback(str:match("<summary>.-%[pac3%](.-)%[/pac3%].-</summary>"))
	end)
end

function pac.GetSteamPart(steamid, callback)
	pac.GetSteamPartURL(steamid, function(url)
		if url then
			http.Get(url, "", function(str)
				callback(glon.decode(str))
			end)
		end
	end)
end

function pac.LoadPartFromProfile(ply)
	pac.GetSteamPart(ply, function(tbl)
		if ply:IsPlayer() then
			pac.SetSubmittedPart(ply, tbl)
		end
	end)
end