local math_huge = math.huge
local math_frexp = math.frexp
local math_ldexp = math.ldexp
local math_floor = math.floor
local math_min = math.min
local math_max = math.max
local bit_rshift = bit.rshift

--- StringStream type
-- @name StringStream
-- @class type
-- @libtbl ss_methods

local ss_methods = {}
local ss_meta = {
	__index = ss_methods,
	__metatable = "StringStream",
	__tostring = function(self)
		return string.format("Stringstream [%u,%u]", self:tell(), self:size())
	end
}
local ss_methods_big = setmetatable({},{__index=ss_methods})
local ss_meta_big = {
	__index = ss_methods_big,
	__metatable = "StringStream",
	__tostring = function(self)
		return string.format("Stringstream [%u,%u]", self:tell(), self:size())
	end
}

local function StringStream(stream, i, endian)
	local ret = setmetatable({
		index = 1,
		subindex = 1
	}, ss_meta)

	if stream~=nil then
		assert(isstring(stream), "stream must be a string")
		ret:write(stream)
		if i~=nil then
			assert(isnumber(i), "i must be a number")
			ret:seek(i)
		else
			ret:seek(1)
		end
	end
	if endian~=nil then
		assert(isstring(endian), "endian must be a string")
		ret:setEndian(endian)
	end

	return ret
end

--Credit https://stackoverflow.com/users/903234/rpfeltz
--Bugfixes and IEEE754Double credit to me
local function PackIEEE754Float(number)
	if number == 0 then
		return 0x00, 0x00, 0x00, 0x00
	elseif number == math_huge then
		return 0x00, 0x00, 0x80, 0x7F
	elseif number == -math_huge then
		return 0x00, 0x00, 0x80, 0xFF
	elseif number ~= number then
		return 0x00, 0x00, 0xC0, 0xFF
	else
		local sign = 0x00
		if number < 0 then
			sign = 0x80
			number = -number
		end
		local mantissa, exponent = math_frexp(number)
		exponent = exponent + 0x7F
		if exponent <= 0 then
			mantissa = math_ldexp(mantissa, exponent - 1)
			exponent = 0
		elseif exponent > 0 then
			if exponent >= 0xFF then
				return 0x00, 0x00, 0x80, sign + 0x7F
			elseif exponent == 1 then
				exponent = 0
			else
				mantissa = mantissa * 2 - 1
				exponent = exponent - 1
			end
		end
		mantissa = math_floor(math_ldexp(mantissa, 23) + 0.5)
		return mantissa % 0x100,
				bit_rshift(mantissa, 8) % 0x100,
				(exponent % 2) * 0x80 + bit_rshift(mantissa, 16),
				sign + bit_rshift(exponent, 1)
	end
end
local function UnpackIEEE754Float(b4, b3, b2, b1)
	local exponent = (b1 % 0x80) * 0x02 + bit_rshift(b2, 7)
	local mantissa = math_ldexp(((b2 % 0x80) * 0x100 + b3) * 0x100 + b4, -23)
	if exponent == 0xFF then
		if mantissa > 0 then
			return 0 / 0
		else
			if b1 >= 0x80 then
				return -math_huge
			else
				return math_huge
			end
		end
	elseif exponent > 0 then
		mantissa = mantissa + 1
	else
		exponent = exponent + 1
	end
	if b1 >= 0x80 then
		mantissa = -mantissa
	end
	return math_ldexp(mantissa, exponent - 0x7F)
end
local function PackIEEE754Double(number)
	if number == 0 then
		return 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	elseif number == math_huge then
		return 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xF0, 0x7F
	elseif number == -math_huge then
		return 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xF0, 0xFF
	elseif number ~= number then
		return 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xF8, 0xFF
	else
		local sign = 0x00
		if number < 0 then
			sign = 0x80
			number = -number
		end
		local mantissa, exponent = math_frexp(number)
		exponent = exponent + 0x3FF
		if exponent <= 0 then
			mantissa = math_ldexp(mantissa, exponent - 1)
			exponent = 0
		elseif exponent > 0 then
			if exponent >= 0x7FF then
				return 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xF0, sign + 0x7F
			elseif exponent == 1 then
				exponent = 0
			else
				mantissa = mantissa * 2 - 1
				exponent = exponent - 1
			end
		end
		mantissa = math_floor(math_ldexp(mantissa, 52) + 0.5)
		return mantissa % 0x100,
				math_floor(mantissa / 0x100) % 0x100,  --can only rshift up to 32 bit numbers. mantissa is too big
				math_floor(mantissa / 0x10000) % 0x100,
				math_floor(mantissa / 0x1000000) % 0x100,
				math_floor(mantissa / 0x100000000) % 0x100,
				math_floor(mantissa / 0x10000000000) % 0x100,
				(exponent % 0x10) * 0x10 + math_floor(mantissa / 0x1000000000000),
				sign + bit_rshift(exponent, 4)
	end
end
local function UnpackIEEE754Double(b8, b7, b6, b5, b4, b3, b2, b1)
	local exponent = (b1 % 0x80) * 0x10 + bit_rshift(b2, 4)
	local mantissa = math_ldexp(((((((b2 % 0x10) * 0x100 + b3) * 0x100 + b4) * 0x100 + b5) * 0x100 + b6) * 0x100 + b7) * 0x100 + b8, -52)
	if exponent == 0x7FF then
		if mantissa > 0 then
			return 0 / 0
		else
			if b1 >= 0x80 then
				return -math_huge
			else
				return math_huge
			end
		end
	elseif exponent > 0 then
		mantissa = mantissa + 1
	else
		exponent = exponent + 1
	end
	if b1 >= 0x80 then
		mantissa = -mantissa
	end
	return math_ldexp(mantissa, exponent - 0x3FF)
end

--- Sets the endianness of the string stream
--@param endian The endianness of number types. "big" or "little" (default "little")
function ss_methods:setEndian(endian)
	if endian == "little" then
		debug.setmetatable(self, ss_meta)
	elseif endian == "big" then
		debug.setmetatable(self, ss_meta_big)
	else
		error("Invalid endian specified", 2)
	end
end

--- Writes the given string and advances the buffer pointer.
--@param data A string of data to write
function ss_methods:write(data)
	if self.index > #self then -- Most often case
		self[self.index] = data
		self.index = self.index + 1
		self.subindex = 1
	else
		local i = 1
		local length = #data
		while length > 0 do
			if self.index > #self then -- End of buffer
				self[self.index] = string.sub(data, i)
				self.index = self.index + 1
				self.subindex = 1
				break
			else
				local cur = self[self.index]
				local sublength = math_min(#cur - self.subindex + 1, length)
				self[self.index] = string.sub(cur,1,self.subindex-1) .. string.sub(data,i,i+sublength-1) .. string.sub(cur,self.subindex+sublength)
				length = length - sublength
				i = i + sublength
				if length > 0 then
					self.index = self.index + 1
					self.subindex = 1
				else
					self.subindex = self.subindex + sublength
				end
			end
		end
	end
end

--- Reads the specified number of bytes from the buffer and advances the buffer pointer.
--@param length How many bytes to read
--@return A string containing the bytes
function ss_methods:read(length)
	local ret = {}
	while length > 0 do
		local cur = self[self.index]
		if cur then
			if self.subindex == 1 and length >= #cur then
				ret[#ret+1] = cur
				self.index = self.index + 1
				length = length - #cur
			else
				local sublength = math_min(#cur - self.subindex + 1, length)
				ret[#ret+1] = string.sub(cur, self.subindex, self.subindex + sublength - 1)
				length = length - sublength
				if length > 0 then
					self.index = self.index + 1
					self.subindex = 1
				else
					self.subindex = self.subindex + sublength
				end
			end
		else
			break
		end
	end
	return table.concat(ret)
end

--- Sets internal pointer to i. The position will be clamped to [1, buffersize+1]
--@param i The position
function ss_methods:seek(pos)
	if pos < 1 then error("Index must be 1 or greater", 2) end
	self.index = #self+1
	self.subindex = 1

	local length = 0
	for i, v in ipairs(self) do
		length = length + #v
		if length >= pos then
			self.index = i
			self.subindex = pos - (length - #v)
			break
		end
	end
end

--- Move the internal pointer by amount i
--@param length The offset
function ss_methods:skip(length)
	while length>0 do
		local cur = self[self.index]
		if cur then
			local sublength = math_min(#cur - self.subindex + 1, length)
			length = length - sublength
			self.subindex = self.subindex + sublength
			if self.subindex>#cur then
				self.index = self.index + 1
				self.subindex = 1
			end
		else
			self.index = #self.index + 1
			self.subindex = 1
			break
		end
	end
	while length<0 do
		local cur = self[self.index]
		if cur then
			local sublength = math_max(-self.subindex, length)
			length = length - sublength
			self.subindex = self.subindex + sublength
			if self.subindex<1 then
				self.index = self.index - 1
				self.subindex = self[self.index] and #self[self.index] or 1
			end
		else
			self.index = 1
			self.subindex = 1
			break
		end
	end
end

--- Returns the internal position of the byte reader.
--@return The buffer position
function ss_methods:tell()
	local length = 0
	for i=1, self.index-1 do
		length = length + #self[i]
	end
	return length + self.subindex
end

--- Tells the size of the byte stream.
--@return The buffer size
function ss_methods:size()
	local length = 0
	for i, v in ipairs(self) do
		length = length + #v
	end
	return length
end

--- Reads an unsigned 8-bit (one byte) integer from the byte stream and advances the buffer pointer.
--@return The uint8 at this position
function ss_methods:readUInt8()
	return string.byte(self:read(1))
end
function ss_methods_big:readUInt8()
	return string.byte(self:read(1))
end

--- Reads an unsigned 16 bit (two byte) integer from the byte stream and advances the buffer pointer.
--@return The uint16 at this position
function ss_methods:readUInt16()
	local a,b = string.byte(self:read(2), 1, 2)
	return b * 0x100 + a
end
function ss_methods_big:readUInt16()
	local a,b = string.byte(self:read(2), 1, 2)
	return a * 0x100 + b
end

--- Reads an unsigned 32 bit (four byte) integer from the byte stream and advances the buffer pointer.
--@return The uint32 at this position
function ss_methods:readUInt32()
	local a,b,c,d = string.byte(self:read(4), 1, 4)
	return d * 0x1000000 + c * 0x10000 + b * 0x100 + a
end
function ss_methods_big:readUInt32()
	local a,b,c,d = string.byte(self:read(4), 1, 4)
	return a * 0x1000000 + b * 0x10000 + c * 0x100 + d
end

--- Reads a signed 8-bit (one byte) integer from the byte stream and advances the buffer pointer.
--@return The int8 at this position
function ss_methods:readInt8()
	local x = self:readUInt8()
	if x>=0x80 then x = x - 0x100 end
	return x
end

--- Reads a signed 16-bit (two byte) integer from the byte stream and advances the buffer pointer.
--@return The int16 at this position
function ss_methods:readInt16()
	local x = self:readUInt16()
	if x>=0x8000 then x = x - 0x10000 end
	return x
end

--- Reads a signed 32-bit (four byte) integer from the byte stream and advances the buffer pointer.
--@return The int32 at this position
function ss_methods:readInt32()
	local x = self:readUInt32()
	if x>=0x80000000 then x = x - 0x100000000 end
	return x
end

--- Reads a 4 byte IEEE754 float from the byte stream and advances the buffer pointer.
--@return The float32 at this position
function ss_methods:readFloat()
	return UnpackIEEE754Float(string.byte(self:read(4), 1, 4))
end
function ss_methods_big:readFloat()
	local a,b,c,d = string.byte(self:read(4), 1, 4)
	return UnpackIEEE754Float(d, c, b, a)
end

--- Reads a 8 byte IEEE754 double from the byte stream and advances the buffer pointer.
--@return The double at this position
function ss_methods:readDouble()
	return UnpackIEEE754Double(string.byte(self:read(8), 1, 8))
end
function ss_methods_big:readDouble()
	local a,b,c,d,e,f,g,h = string.byte(self:read(8), 1, 8)
	return UnpackIEEE754Double(h, g, f, e, d, c, b, a)
end

--- Reads until the given byte and advances the buffer pointer.
--@param byte The byte to read until (in number form)
--@return The string of bytes read
function ss_methods:readUntil(byte)
	byte = string.char(byte)
	local ret = {}
	for i=self.index, #self do
		local cur = self[self.index]
		local find = string.find(cur, byte, self.subindex, true)
		if find then
			ret[#ret+1] = string.sub(cur, self.subindex, find)
			self.subindex = find+1
			if self.subindex > #cur then
				self.index = self.index + 1
				self.subindex = 1
			end
			break
		else
			if self.subindex == 1 then
				ret[#ret+1] = cur
			else
				ret[#ret+1] = string.sub(cur, self.subindex)
			end
			self.index = self.index + 1
			self.subindex = 1
		end
	end
	return table.concat(ret)
end

--- returns a null terminated string, reads until "\x00" and advances the buffer pointer.
--@return The string of bytes read
function ss_methods:readString()
	local s = self:readUntil(0)
	return string.sub(s, 1, #s-1)
end

--- Writes a byte to the buffer and advances the buffer pointer.
--@param x An int8 to write
function ss_methods:writeInt8(x)
	if x==math_huge or x==-math_huge or x~=x then error("Can't convert error float to integer!", 2) end
	if x < 0 then x = x + 0x100 end
	self:write(string.char(x%0x100))
end

--- Writes a short to the buffer and advances the buffer pointer.
--@param x An int16 to write
function ss_methods:writeInt16(x)
	if x==math_huge or x==-math_huge or x~=x then error("Can't convert error float to integer!", 2) end
	if x < 0 then x = x + 0x10000 end
	self:write(string.char(x%0x100, bit_rshift(x, 8)%0x100))
end
function ss_methods_big:writeInt16(x)
	if x==math_huge or x==-math_huge or x~=x then error("Can't convert error float to integer!", 2) end
	if x < 0 then x = x + 0x10000 end
	self:write(bit_rshift(x, 8)%0x100, string.char(x%0x100))
end

--- Writes an int to the buffer and advances the buffer pointer.
--@param x An int32 to write
function ss_methods:writeInt32(x)
	if x==math_huge or x==-math_huge or x~=x then error("Can't convert error float to integer!", 2) end
	if x < 0 then x = x + 0x100000000 end
	self:write(string.char(x%0x100, bit_rshift(x, 8)%0x100, bit_rshift(x, 16)%0x100, bit_rshift(x, 24)%0x100))
end
function ss_methods_big:writeInt32(x)
	if x==math_huge or x==-math_huge or x~=x then error("Can't convert error float to integer!", 2) end
	if x < 0 then x = x + 0x100000000 end
	self:write(string.char(bit_rshift(x, 24)%0x100, bit_rshift(x, 16)%0x100, bit_rshift(x, 8)%0x100), x%0x100)
end

--- Writes a 4 byte IEEE754 float to the byte stream and advances the buffer pointer.
--@param x The float to write
function ss_methods:writeFloat(x)
	self:write(string.char(PackIEEE754Float(x)))
end
function ss_methods_big:writeFloat(x)
	local a,b,c,d = PackIEEE754Float(x)
	self:write(string.char(d,c,b,a))
end

--- Writes a 8 byte IEEE754 double to the byte stream and advances the buffer pointer.
--@param x The double to write
function ss_methods:writeDouble(x)
	self:write(string.char(PackIEEE754Double(x)))
end
function ss_methods_big:writeDouble(x)
	local a,b,c,d,e,f,g,h = PackIEEE754Double(x)
	self:write(string.char(h,g,f,e,d,c,b,a))
end

--- Writes a string to the buffer putting a null at the end and advances the buffer pointer.
--@param string The string of bytes to write
function ss_methods:writeString(string)
	self:write(string)
	self:write("\0")
end

--- Returns the buffer as a string
--@return The buffer as a string
function ss_methods:getString()
	return table.concat(self)
end

do
	do
		function ss_methods:writeBool(b)
			self:writeInt8(b and 1 or 0)
		end

		function ss_methods:readBool()
			return self:readInt8() == 1
		end
	end

	do
		function ss_methods:writeVector(val)
			self:writeDouble(val.x)
			self:writeDouble(val.y)
			self:writeDouble(val.z)
		end

		function ss_methods:readVector()
			local x = self:readDouble()
			local y = self:readDouble()
			local z = self:readDouble()

			return Vector(x,y,z)
		end
	end

	do
		function ss_methods:writeAngle(val)
			self:writeDouble(val.p)
			self:writeDouble(val.y)
			self:writeDouble(val.r)
		end

		function ss_methods:readAngle()
			local x = self:readDouble()
			local y = self:readDouble()
			local z = self:readDouble()

			return Angle(x,y,z)
		end
	end

	do
		function ss_methods:writeColor(val)
			self:writeDouble(val.r)
			self:writeDouble(val.g)
			self:writeDouble(val.b)
			self:writeDouble(val.a)
		end

		function ss_methods:readColor()
			local r = self:readDouble()
			local g = self:readDouble()
			local b = self:readDouble()
			local a = self:readDouble()

			return Color(r,g,b,a)
		end
	end

	do
		function ss_methods:writeEntity(val)
			self:writeInt32(val:EntIndex())
		end

		function ss_methods:readEntity()
			return Entity(self:readInt32())
		end
	end

	function ss_methods:writeTable(tab)
		for k, v in pairs( tab ) do
			self:writeType( k )
			self:writeType( v )
		end

		self:writeType( nil )
	end

	function ss_methods:readTable()
		local tab = {}

		while true do
			local k = self:readType()
			if k == nil then
				return tab
			end

			tab[k] = self:readType()
		end
	end

	local write_functions = {
		[TYPE_NIL] = function(s, t, v) s:writeInt8( t ) end,
		[TYPE_STRING] = function(s, t, v) s:writeInt8( t ) s:writeString( v ) end,
		[TYPE_NUMBER] = function(s, t, v) s:writeInt8( t ) s:writeDouble( v ) end,
		[TYPE_TABLE] = function(s, t, v) s:writeInt8( t ) s:writeTable( v ) end,
		[TYPE_BOOL] = function(s, t, v) s:writeInt8( t ) s:writeBool( v ) end,
		[TYPE_VECTOR] = function(s, t, v) s:writeInt8( t ) s:writeVector( v ) end,
		[TYPE_ANGLE] = function(s, t, v) s:writeInt8( t ) s:writeAngle( v ) end,
		[TYPE_COLOR] = function(s, t, v) s:writeInt8( t ) s:writeColor( v ) end,
		[TYPE_ENTITY] = function(s, t, v) s:writeInt8( t ) s:writeEntity( v ) end,

	}

	function ss_methods:writeType( v )
		local typeid = nil

		if IsColor(v) then
			typeid = TYPE_COLOR
		else
			typeid = TypeID(v)
		end

		local func = write_functions[typeid]

		if func then
			return func(self, typeid, v)
		end

		error("StringStream:writeType: Couldn't write " .. type(v) .. " (type " .. typeid .. ")")
	end

	local read_functions = {
		[TYPE_NIL] = function(s) return nil end,
		[TYPE_STRING] = function(s) return s:readString() end,
		[TYPE_NUMBER] = function(s) return s:readDouble() end,
		[TYPE_TABLE] = function(s) return s:readTable() end,
		[TYPE_BOOL] = function(s) return s:readBool() end,
		[TYPE_VECTOR] = function(s) return s:readVector() end,
		[TYPE_ANGLE] = function(s) return s:readAngle() end,
		[TYPE_COLOR] = function(s) return s:readColor() end,
		[TYPE_ENTITY] = function(s) return s:readEntity() end,
	}

	function ss_methods:readType( typeid )
		typeid = typeid or self:readUInt8(8)

		local func = read_functions[typeid]

		if func then
			return func(self)
		end

		error("StringStream:readType: Couldn't read type " .. tostring(typeid))
	end
end

return StringStream
