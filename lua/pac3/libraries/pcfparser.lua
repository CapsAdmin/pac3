local pac = pac

local pcfparser = {}

-- DMX binary attribute type IDs (from source engine dmserializerbinary.cpp)
-- AT_UNKNOWN = 0 is unused in valid files
local TYPE_NAMES = {
	[0] = "unknown",
	[1] = "element",
	[2] = "int",
	[3] = "float",
	[4] = "bool",
	[5] = "string",
	[6] = "binary",
	[7] = "time",
	[8] = "color",
	[9] = "vector2",
	[10] = "vector3",
	[11] = "vector4",
	[12] = "qangle",
	[13] = "quaternion",
	[14] = "matrix",
	[15] = "element_array",
	[16] = "int_array",
	[17] = "float_array",
	[18] = "bool_array",
	[19] = "string_array",
	[20] = "binary_array",
	[21] = "time_array",
	[22] = "color_array",
	[23] = "vector2_array",
	[24] = "vector3_array",
	[25] = "vector4_array",
	[26] = "qangle_array",
	[27] = "quaternion_array",
	[28] = "matrix_array",
}

local FIXED_SIZES = {
	element = 4, int = 4, float = 4, bool = 1,
	time = 4, color = 4, vector2 = 8, vector3 = 12,
	vector4 = 16, qangle = 12, quaternion = 16, matrix = 64,
}

local function ReadNullTerminated(stream)
	local ret = {}
	for i = 1, 2048 do
		local b = stream:readUInt8()
		if not b or b == 0 then break end
		ret[i] = string.char(b)
	end
	return table.concat(ret)
end

local function SkipValue(stream, typeName, version)
	local fixed = FIXED_SIZES[typeName]
	if fixed then
		stream:skip(fixed)
		return
	end

	if typeName == "string" then
		if version <= 3 then
			ReadNullTerminated(stream)
		elseif version == 4 then
			stream:skip(2)
		else
			stream:skip(4)
		end
	elseif typeName == "binary" then
		local count = stream:readUInt32()
		if count and count > 0 then stream:skip(count) end
	elseif typeName and typeName:sub(-6) == "_array" then
		local baseType = typeName:sub(1, -7)
		local count = stream:readUInt32()
		if not count or count > 100000 then return end
		if baseType == "string" then
			for i = 1, count do
				ReadNullTerminated(stream)
			end
		elseif baseType == "binary" then
			for i = 1, count do
				local len = stream:readUInt32()
				if len and len > 0 then stream:skip(len) end
			end
		else
			local fsize = FIXED_SIZES[baseType]
			if fsize then
				stream:skip(fsize * count)
			end
		end
	end
end

local function SkipAttribute(stream, version)
	if version <= 4 then
		stream:skip(2)
	else
		stream:skip(4)
	end

	local typeByte = stream:readUInt8()
	local typeName = TYPE_NAMES[typeByte]
	if typeName then
		SkipValue(stream, typeName, version)
		return true
	end
	return false
end

function pcfparser.ReadEffectNames(filepath)
	local f = file.Open(filepath, "rb", "GAME")
	if not f then return {} end

	local data = f:Read()
	f:Close()

	if not data or #data < 32 then return {} end

	local stream = pac.StringStream(data, 1)

	local readLen = math.min(256, #data)
	local headerBuf = stream:read(readLen)
	stream:seek(1)

	local headerStart = headerBuf:find("dmx encoding", 1, true)
	if not headerStart then return {} end
	local headerEnd = headerBuf:find(" -->", headerStart, true)
	if not headerEnd then return {} end

	local encType, encVer = headerBuf:match("dmx encoding (%w+) (%d+)", headerStart)
	if not encType or encType ~= "binary" then return {} end

	local version = tonumber(encVer)
	if not version or version < 2 or version > 5 then return {} end

	stream:seek(headerEnd + 6)

	local nStrings
	if version <= 3 then
		nStrings = stream:readUInt16()
	else
		nStrings = stream:readUInt32()
	end
	if not nStrings or nStrings > 100000 then return {} end

	local stringDict = {}
	for i = 0, nStrings - 1 do
		stringDict[i] = ReadNullTerminated(stream)
	end

	local nElements = stream:readUInt32()
	if not nElements or nElements > 100000 then return {} end

	local elements = {}
	for i = 0, nElements - 1 do
		local typeIdx, name
		if version <= 3 then
			typeIdx = stream:readUInt16()
			name = ReadNullTerminated(stream)
		elseif version == 4 then
			typeIdx = stream:readUInt16()
			name = stringDict[stream:readUInt16()] or ""
		else
			typeIdx = stream:readUInt32()
			name = stringDict[stream:readUInt32()] or ""
		end
		stream:skip(16)

		elements[i] = {
			type = stringDict[typeIdx] or "",
			name = name,
		}
	end

	local effectNames = {}

	for i = 0, nElements - 1 do
		local attribCount = stream:readUInt32()
		if not attribCount or attribCount > 10000 then break end

		if i == 0 then
			for j = 1, attribCount do
				local nameIdx
				if version <= 4 then
					nameIdx = stream:readUInt16()
				else
					nameIdx = stream:readUInt32()
				end
				if not nameIdx then break end
				local attrName = stringDict[nameIdx] or ""
				local typeByte = stream:readUInt8()
				if not typeByte then break end
				local typeName = TYPE_NAMES[typeByte]

				if attrName == "particleSystemDefinitions" and (typeName == "element_array" or typeName == "int_array") then
					local count = stream:readUInt32()
					for k = 1, count do
						local elemIdx = stream:readInt32()
						local elem = elements[elemIdx]
						if elem and elem.type == "DmeParticleSystemDefinition" then
							local eName = elem.name
							if eName and eName ~= "" then
								effectNames[string.lower(eName)] = eName
							end
						end
					end
				else
					if typeName then
						SkipValue(stream, typeName, version)
					else
						break
					end
				end
			end
		else
			for j = 1, attribCount do
				if not SkipAttribute(stream, version) then break end
			end
		end
	end

	return effectNames
end

return pcfparser
