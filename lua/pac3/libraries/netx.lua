
local netx = setmetatable({}, {__index = net})

local TYPES_BITS = 4

local TYPE_STRING = 0
local TYPE_NUMBER = 1
local TYPE_ANGLE = 2
local TYPE_VECTOR = 3
local TYPE_BOOL = 4
local TYPE_COLOR = 5
local TYPE_TABLE = 6
local TYPE_ENTITY = 7
local TYPE_NUMBER_UID = 8
local TYPE_FLOAT = 9

local readTable

-- 1.9974 engineers is enough
local function net_ReadVector()
	return Vector(net.ReadFloat(), net.ReadFloat(), net.ReadFloat())
end

local function net_WriteVector(vec)
	net.WriteFloat(vec.x)
	net.WriteFloat(vec.y)
	net.WriteFloat(vec.z)
end

local function net_ReadAngle()
	return Angle(net.ReadFloat(), net.ReadFloat(), net.ReadFloat())
end

local function net_WriteAngle(ang)
	net.WriteFloat(ang.p)
	net.WriteFloat(ang.y)
	net.WriteFloat(ang.r)
end

local function readTyped()
	local tp = net.ReadUInt(TYPES_BITS)

	if tp == TYPE_STRING then
		return net.ReadString()
	elseif tp == TYPE_NUMBER_UID then
		return tostring(net.ReadUInt(32))
	elseif tp == TYPE_NUMBER then
		return net.ReadInt(32)
	elseif tp == TYPE_FLOAT then
		return net.ReadFloat()
	elseif tp == TYPE_ANGLE then
		return net_ReadAngle()
	elseif tp == TYPE_VECTOR then
		return net_ReadVector()
	elseif tp == TYPE_BOOL then
		return net.ReadBool()
	elseif tp == TYPE_COLOR then
		return net.ReadColor()
	elseif tp == TYPE_ENTITY then
		return net.ReadEntity()
	elseif tp == TYPE_TABLE then
		return readTable()
	else
		error('Cannot read type - type is ' .. tp .. '!')
	end
end

local function writeTyped(val, key)
	local tp = type(val)

	if tp == 'string' then
		local tryuid = tonumber(val)

		if tryuid and tryuid > 0 and tryuid < 2 ^ 32 and math.floor(tryuid) == tryuid and tostring(tryuid) == val then
			net.WriteUInt(TYPE_NUMBER_UID, TYPES_BITS)
			net.WriteUInt(tryuid, 32)
		else
			net.WriteUInt(TYPE_STRING, TYPES_BITS)
			net.WriteString(val)
		end
	elseif tp == 'number' then
		if val % 1 == 0 then
			net.WriteUInt(TYPE_NUMBER, TYPES_BITS)
			net.WriteInt(val, 32)
		else
			net.WriteUInt(TYPE_FLOAT, TYPES_BITS)
			net.WriteFloat(val)
		end
	elseif tp == 'Angle' then
		net.WriteUInt(TYPE_ANGLE, TYPES_BITS)
		net_WriteAngle(val)
	elseif tp == 'Vector' then
		net.WriteUInt(TYPE_VECTOR, TYPES_BITS)
		net_WriteVector(val)
	elseif tp == 'boolean' then
		net.WriteUInt(TYPE_BOOL, TYPES_BITS)
		net.WriteBool(val)
	elseif tp == 'table' then
		net.WriteUInt(TYPE_COLOR, TYPES_BITS)
		net.WriteColor(val)
	elseif tp == 'Entity' or tp == 'Player' or tp == 'NPC' or tp == 'NextBot' or tp == 'Vehicle' then
		net.WriteUInt(TYPE_ENTITY, TYPES_BITS)
		net.WriteEntity(val)
	else
		error('Unknown type - ' .. tp .. ' (index is ' .. (key or 'unknown') .. ')')
	end
end

local tostring = tostring
local CRC = util.CRC

local function writeTable(tab)
	net.WriteUInt(table.Count(tab), 8)
	local keys = {}

	for key, value in pairs(tab) do
		local i = key

		if type(i) == 'string' then
			i = tonumber(i) or tonumber(CRC(i))
		end

		if keys[i] == nil then
			keys[i] = true
			net.WriteUInt(i, 32)

			if type(value) == 'table' then
				if value.r and value.g and value.b and value.a then
					writeTyped(value, key)
				else
					net.WriteUInt(TYPE_TABLE, TYPES_BITS)
					writeTable(value)
				end
			else
				writeTyped(value, key)
			end
		end
	end
end

local readmeta = {
	__index = function(self, key)
		local val = rawget(self, key)

		if val ~= nil then
			return val
		end

		return rawget(self, CRC(key))
	end,

	__newindex = function(self, key, value)
		local crc = CRC(key)
		local crc2 = tonumber(crc)

		if rawget(self, crc) ~= nil then
			rawset(self, crc, nil)
		end

		if rawget(self, crc2) ~= nil then
			rawset(self, crc2, nil)
		end

		rawset(self, key, value)
	end
}

function netx.SimulateTableReceive(tableIn)
	for index, value in pairs(tableIn) do
		if type(value) == 'table' then
			netx.SimulateTableReceive(value)
		end

		local i2 = index
		local i = tostring(i2)

		if CLIENT then
			i = pac.ExtractNetworkID(i) or i
		end

		local num = tonumber(i)

		if num and num >= 1 and num % 1 == 0 and num <= 255 then
			tableIn[num] = value
		--else
		--	tableIn[i] = value
		end
	end

	setmetatable(tableIn, readmeta)

	return tableIn
end

function readTable(tab)
	local output = {}
	local amount = net.ReadUInt(8)

	for i = 1, amount do
		local i2 = net.ReadUInt(32)
		local i = tostring(i2)
		local val = readTyped()

		if CLIENT then
			i = pac.ExtractNetworkID(i) or i
		end

		local num = tonumber(i)

		if num and num >= 1 and num % 1 == 0 and num <= 255 then
			output[num] = val
		else
			output[i] = val
		end
	end

	return setmetatable(output, readmeta)
end

function netx.SerializeTable(data)
	local written1 = net.BytesWritten()

	writeTable(data)

	if DLib and DLib.netModule and net.CompressOngoing then
		net.CompressOngoing()
	end

	local written2 = net.BytesWritten()

	if written2 >= 65536 then
		return nil, "table too big"
	end

	return written2 - written1
end

function netx.DeserializeTable()
	return readTable()
end

return netx
