
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
        return obj:UniqueID()
    elseif t == "Entity" then
        return obj:EntIndex()
    else
        error("NYI " .. t)
    end
end