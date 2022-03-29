
local string_hash = util.SHA256
local is_singleplayer = game.SinglePlayer()
local is_bot = FindMetaTable("Player").IsBot
local steamid64 = FindMetaTable("Player").SteamID64

function pac.Hash(obj)
	local t = type(obj)

	if t == "string" then
		return string_hash(obj)
	elseif t == "Player" then
		if is_singleplayer then
			return "SinglePlayer"
		end

		-- Player(s) can never be next bots (?)
		-- IsNextBot is present in Entity and NextBot metatables (and those functions are different)
		-- but not in Player's one
		if obj:IsNextBot() then
			return "nextbot " .. tostring(obj:EntIndex())
		end

		if is_bot(obj) then
			return "bot " .. tostring(obj:EntIndex())
		end

		local hash = steamid64(obj)
		if not hash then
			if pac.debug then
				ErrorNoHaltWithStack( "FIXME: Did not get a steamid64 for a player object " .. tostring(obj) .. ', valid=' .. tostring(IsValid(obj)) .. ', steamid=' .. tostring(obj:SteamID()) .. '\n' )
			end
			hash = "0"
		end
		return hash
	elseif t == "number" then
		return string_hash(tostring(t))
	elseif t == "table" then
		return string_hash(("%p"):format(obj))
	elseif t == "nil" then
		return string_hash(SysTime() .. ' ' .. os.time() .. ' ' .. RealTime())
	elseif IsEntity(obj) then
		return tostring(obj:EntIndex())
	else
		error("NYI " .. t)
	end
end

function pac.ReverseHash(str, t)
	if t == "Player" then
		if is_singleplayer then
			return Entity(1)
		end

		if str:StartWith("nextbot ") then
			return pac.ReverseHash(str:sub(#"nextbot " + 1), "Entity")
		elseif str:StartWith("bot ") then
			return pac.ReverseHash(str:sub(#"bot " + 1), "Entity")
		end

		return player.GetBySteamID64(str) or NULL
	elseif t == "Entity" then
		return ents.GetByIndex(tonumber(str))
	else
		error("NYI " .. t)
	end
end
