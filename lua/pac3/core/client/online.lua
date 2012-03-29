local function SteamIDToCommunityID(id)
	if id == "BOT" or id == "STEAM_ID_PENDING" or id == "UNKNOWN" then
		return 0
	end

	local parts = id:Split(":")
	local a, b = parts[2], parts[3]

	return tostring("7656119" .. 7960265728 + a + (b*2))
end

function pac.GetSteamOutfitURL(steamid, callback)
	steamid = IsEntity(steamid) and steamid:IsPlayer() and steamid:SteamID() or steamid

	local url = ("http://steamcommunity.com/profiles/%s/?xml=1"):format(SteamIDToCommunityID(steamid))

	http.Get(url, "", function(str)
		callback(str:match("<summary>.-%[pac3%](.-)%[/pac3%].-</summary>"))
	end)
end

function pac.GetSteamOutfit(steamid, callback)
	pac.GetSteamOutfitURL(steamid, function(url)
		if url then
			http.Get(url, "", function(str)
				callback(glon.decode(str))
			end)
		end
	end)
end

function pac.LoadOutfitFromProfile(ply)
	pac.GetSteamOutfit(ply, function(tbl)
		if ply:IsPlayer() then
			pac.SetSubmittedOutfit(ply, tbl)
		end
	end)
end