
local string_hash = util.CRC

function pac.Hash(obj)
    local t = type(obj)

    if t == "nil" then
        return string_hash(tostring(math.random()))
    elseif t == "string" then
        return string_hash(obj)
    elseif t == "number" then
        return pac.Hash(tostring(t))
    elseif t == "table" then
        return pac.Hash(("%p"):format(obj))
    elseif t == "Player" then
		if game.SinglePlayer() then
			return "SinglePlayer"
		end

		if obj:IsNextBot() then
			return "nextbot " .. tostring(obj:EntIndex())
		end

        return obj:SteamID64()
    elseif IsEntity(obj) then
        return tostring(obj:EntIndex())
    else
        error("NYI " .. t)
    end
end

function pac.ReverseHash(str, t)
    if t == "Player" then
		if game.SinglePlayer() then
			return Entity(1)
		end

		if str:StartWith("nextbot") then
			return pac.ReverseHash(str:sub(9), "Entity")
		end

        return player.GetBySteamID64(str) or NULL
    elseif t == "Entity" then
        return ents.GetByIndex(tonumber(str))
    else
        error("NYI " .. t)
    end
end