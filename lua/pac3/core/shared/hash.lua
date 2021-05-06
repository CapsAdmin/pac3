
-- DLib implementation of SHA256
-- adapatation to be class-less
-- supposed to reflect reference implementation
-- of SHA2 family on ANSI C Language
local bor = bit.bor
local tobit = bit.tobit
local band = bit.band
local bxor = bit.bxor
local rshift = bit.rshift
local bnot = bit.bnot
local lshift = bit.lshift
local string = string
local string_byte = string.byte
local string_sub = string.sub
local math_floor = math.floor

local ROTL = bit.rol
local ROTR = bit.ror

local function overflow(a)
	if a < 0 then
		return a + 4294967296
	end

	return a % 4294967296
end

local function CH(x, y, z)
	return bxor(band(x, y), band(bnot(x), z))
end

local function MAJ(x, y, z)
	return bxor(band(x, y), band(x, z), band(y, z))
end

local function BSIG0(x)
	return bxor(ROTR(x, 2), ROTR(x, 13), ROTR(x, 22))
end

local function BSIG1(x)
	return bxor(ROTR(x, 6), ROTR(x, 11), ROTR(x, 25))
end

local function SSIG0(x)
	return bxor(ROTR(x, 7), ROTR(x, 18), rshift(x, 3))
end

local function SSIG1(x)
	return bxor(ROTR(x, 17), ROTR(x, 19), rshift(x, 10))
end

local W = {}
local bytes = {}

local K = {
	0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5,
	0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
	0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
	0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
	0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc,
	0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
	0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7,
	0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
	0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
	0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
	0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3,
	0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
	0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5,
	0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
	0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
	0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
}

local function string_hash(str)
	local H0 = 0x6A09E667
	local H1 = 0xBB67AE85
	local H2 = 0x3C6EF372
	local H3 = 0xA54FF53A
	local H4 = 0x510E527F
	local H5 = 0x9B05688C
	local H6 = 0x1F83D9AB
	local H7 = 0x5BE0CD19

	local length = #str
	local mod = length % 64

	if mod < 56 then
		-- append 128, then 0
		str = str .. '\x80' .. string.rep('\x00', 55 - mod)
	else
		-- too long
		str = str ..
			'\x80' ..
			string.rep('\x00', 119 - mod)
	end

	local realLength = length * 8
	local modLen = realLength % 4294967296
	local div = (realLength - modLen) / 4294967296

	str = str .. string.char(
		band(rshift(div, 24), 0xFF),
		band(rshift(div, 16), 0xFF),
		band(rshift(div, 8), 0xFF),
		band(rshift(div, 0), 0xFF),

		band(rshift(modLen, 24), 0xFF),
		band(rshift(modLen, 16), 0xFF),
		band(rshift(modLen, 8), 0xFF),
		band(rshift(modLen, 0), 0xFF)
	)

	-- 512 bit block
	for i = 1, math_floor(#str / 64) do
		local init = (i - 1) * 64 - 4

		for t = 1, 16 do
			-- LITTLE-ENDIAN blocks!
			local a, b, c, d = string_byte(str, init + t * 4 + 1, init + t * 4 + 4)

			W[t] = bor(
				d,
				lshift(c, 8),
				lshift(b, 16),
				lshift(a, 24)
			)
		end

		-- prepare
		for t = 17, 64 do
			W[t] = SSIG1(W[t - 2]) + W[t - 7] + SSIG0(W[t - 15]) + W[t - 16]
		end

		-- working variables
		local a, b, c, d, e, f, g, h =
			H0,
			H1,
			H2,
			H3,
			H4,
			H5,
			H6,
			H7

		for t = 1, 64 do
			local T1 =
				h +
				BSIG1(e) +
				CH(e, f, g) +
				K[t] +
				W[t]

			h, g, f, e, d, c, b, a = g, f, e, d + T1, c, b, a, T1 + BSIG0(a) + MAJ(a, b, c)
		end

		-- compute intermediate hash value
		H0 = tobit(a + H0)
		H1 = tobit(b + H1)
		H2 = tobit(c + H2)
		H3 = tobit(d + H3)
		H4 = tobit(e + H4)
		H5 = tobit(f + H5)
		H6 = tobit(g + H6)
		H7 = tobit(h + H7)
	end

	return string.format('%08x%08x%08x%08x%08x%08x%08x%08x',
		overflow(H0),
		overflow(H1),
		overflow(H2),
		overflow(H3),
		overflow(H4),
		overflow(H5),
		overflow(H6),
		overflow(H7)
	)
end

--[[
assert(string_hash('a') == DLib.Util.QuickSHA256('a'))
assert(string_hash('aaaa') == DLib.Util.QuickSHA256('aaaa'))
assert(string_hash('aaab') ~= DLib.Util.QuickSHA256('aaaa'))
assert(string_hash(string.rep('aghj', 16)) == DLib.Util.QuickSHA256(string.rep('aghj', 16)))
assert(string_hash(string.rep('aghj', 15) .. 'zzz') == DLib.Util.QuickSHA256(string.rep('aghj', 15) .. 'zzz'))
]]

function pac.Hash(obj)
    local t = type(obj)

    if t == "nil" then
        return string_hash(SysTime() .. ' ' .. os.time() .. ' ' .. RealTime())
    elseif t == "string" then
        return string_hash(obj)
    elseif t == "number" then
        return string_hash(tostring(t))
    elseif t == "table" then
        return string_hash(("%p"):format(obj))
    elseif t == "Player" then
		if game.SinglePlayer() then
			return "SinglePlayer"
		end

		if obj:IsNextBot() then
			return "nextbot " .. tostring(obj:EntIndex())
		end

		if obj:IsBot() then
			return "bot " .. tostring(obj:EntIndex())
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
