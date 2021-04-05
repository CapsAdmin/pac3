
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
        return obj:SteamID64()
    elseif t == "Entity" then
        return tostring(obj:EntIndex())
    else
        error("NYI " .. t)
    end
end

function pac.ReverseHash(str, t)
    if t == "Player" then
        return player.GetBySteamID64(str)
    elseif t == "Entity" then
        return ents.GetByIndex(tonumber(str))
    else
        error("NYI " .. t)
    end
end