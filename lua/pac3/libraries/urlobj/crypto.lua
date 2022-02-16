local crypto = {}

crypto.UInt8BlockSize  = 64
crypto.UInt32BlockSize = 16

crypto.KeySize         = crypto.UInt32BlockSize

local bit_band     = bit.band
local bit_bxor     = bit.bxor
local bit_rshift   = bit.rshift
local math_ceil    = math.ceil
local math_floor   = math.floor
local math_random  = math.random
local string_byte  = string.byte
local string_char  = string.char
local string_sub   = string.sub
local table_concat = table.concat

-- byteCharacters [i] is faster than string_char (i)
local byteCharacters1 = {}
local byteCharacters2 = {}
local byteCharacters  = byteCharacters1
for i = 0, 255 do byteCharacters1 [i] = string_char (i) end
for uint80 = 0, 255 do
	for uint81 = 0, 255 do
		byteCharacters2 [uint80 + uint81 * 256] = string_char (uint80, uint81)
	end
end

function crypto.GenerateKey (seed, length)
	length = length or crypto.KeySize

	if isstring (seed) then
		-- LOL ONLY 32 BITS OF ENTROPY
		seed = tonumber (util.CRC (seed))
	end

	if seed then
		math.randomseed (seed)
	end

	return crypto.GenerateRandomUInt32Array (length)
end

-- Encrypts a string
function crypto.EncryptString (inputString, keyArray)
	local inputArray = crypto.StringToUInt32Array (inputString)
	inputArray = crypto.PadUInt32Array (inputArray)

	local outputArray = {}
	outputArray = crypto.GenerateRandomUInt32Array (crypto.UInt32BlockSize, outputArray)

	-- I have no idea either
	local keyArray = crypto.CloneArray (keyArray)
	keyArray = crypto.AppendArray (keyArray, keyArray)
	keyArray = crypto.AppendArray (keyArray, keyArray)
	keyArray = crypto.AppendArray (keyArray, keyArray)
	keyArray = crypto.AppendArray (keyArray, keyArray)
	keyArray = crypto.AppendArray (keyArray, keyArray)
	keyArray = crypto.AppendArray (keyArray, keyArray)

	crypto.XorInt32Arrays (outputArray, 1, keyArray, 1, crypto.UInt32BlockSize, outputArray, 1)

	local inputArrayLength = #inputArray
	local inputEndIndex    = #inputArray

	inputEndIndex = inputEndIndex - ((inputArrayLength / crypto.UInt32BlockSize) % 64) * crypto.UInt32BlockSize

	local inputIndex = 1
	while inputIndex <= inputEndIndex do
		crypto.XorInt32Arrays3 (
			inputArray,  inputIndex,
			outputArray, inputIndex,
			keyArray,    1,
			crypto.UInt32BlockSize * 64,
			outputArray, crypto.UInt32BlockSize + inputIndex
		)

		inputIndex = inputIndex + crypto.UInt32BlockSize * 64
	end

	-- Remainder
	inputEndIndex = #inputArray
	while inputIndex <= inputEndIndex do
		crypto.XorInt32Arrays3 (
			inputArray,  inputIndex,
			outputArray, inputIndex,
			keyArray,    1,
			crypto.UInt32BlockSize,
			outputArray, crypto.UInt32BlockSize + inputIndex
		)

		inputIndex = inputIndex + crypto.UInt32BlockSize
	end

	local outputString = crypto.Int32ArrayToString (outputArray)
	return outputString
end

-- Decrypts a string
function crypto.DecryptString (inputString, keyArray)
	local inputArray = crypto.StringToUInt32Array (inputString)

	local inputIndex = #inputArray - crypto.UInt32BlockSize + 1
	while inputIndex > crypto.UInt32BlockSize do
		crypto.XorInt32Arrays3 (
			inputArray, inputIndex,
			inputArray, inputIndex - crypto.UInt32BlockSize,
			keyArray,   1,
			crypto.UInt32BlockSize,
			inputArray, inputIndex
		)

		inputIndex = inputIndex - crypto.UInt32BlockSize
	end

	crypto.XorInt32Arrays (inputArray, 1, keyArray, 1, crypto.UInt32BlockSize, inputArray, 1)

	inputArray = crypto.UnpadInt32Array (inputArray)
	local outputArray = inputArray

	local outputString = crypto.Int32ArrayToString (outputArray, crypto.UInt32BlockSize + 1)
	return outputString
end

-- Pads an array in place
function crypto.PadUInt8Array (array)
	local targetLength = math_ceil (#array / crypto.UInt8BlockSize) * crypto.UInt8BlockSize
	if targetLength == #array then
		targetLength = targetLength + crypto.UInt8BlockSize
	end

	array [#array + 1] = 0xFF
	for i = #array + 1, targetLength do
		array [i] = 0x00
	end

	array.n = #array

	return array
end

-- Pads an array in place
function crypto.PadUInt32Array (array)
	if array.n % 4 == 0 then
		array [#array + 1] = 0x000000FF
	elseif array.n % 4 == 1 then
		array [#array] = array [#array] + 0x0000FF00
	elseif array.n % 4 == 2 then
		array [#array] = array [#array] + 0x00FF0000
	elseif array.n % 4 == 3 then
		array [#array] = array [#array] + 0xFF000000
	end

	local targetLength = math_ceil (#array / crypto.UInt32BlockSize) * crypto.UInt32BlockSize
	for i = #array + 1, targetLength do
		array [i] = 0x00000000
	end

	array.n = #array * 4

	return array
end

-- Unpads an array in place
function crypto.UnpadUInt8Array (array)
	for i = #array, 1, -1 do
		if array [i] ~= 0x00 then break end

		array [i] = nil
	end

	if array [#array] == 0xFF then
		array [#array] = nil
	end

	array.n = #array

	return array
end

-- Unpads an array in place
function crypto.UnpadUInt32Array (array)
	return crypto.UnpadInt32Array (array)
end

-- Unpads an array in place
function crypto.UnpadInt32Array (array)
	for i = #array, 1, -1 do
		if array [i] ~= 0x00000000 then break end

		array [i] = nil
	end

	array.n = #array * 4

	if array [#array] < 0 then
		array [#array] = array [#array] + 4294967296
	end

	if array [#array] - 0xFF000000 >= 0 then
		array [#array] = array [#array] - 0xFF000000
		array.n = array.n - 1
	elseif array [#array] - 0x00FF0000 >= 0 then
		array [#array] = array [#array] - 0x00FF0000
		array.n = array.n - 2
	elseif array [#array] - 0x0000FF00 >= 0 then
		array [#array] = array [#array] - 0x0000FF00
		array.n = array.n - 3
	elseif array [#array] - 0x000000FF >= 0 then
		array [#array] = nil
		array.n = array.n - 4
	end

	return array
end

-- Array operations
-- Generates a random array of uint8s
function crypto.GenerateRandomUInt8Array (length, out)
	out = out or {}

	for i = 1, length do
		out [#out + 1] = math_random (0, 0xFF)
	end

	return out
end

-- Generates a random array of uint32s
function crypto.GenerateRandomUInt32Array (length, out)
	out = out or {}

	for i = 1, length do
		out [#out + 1] = math_random (0, 0xFFFFFFFF)
	end

	return out
end

-- Appends an array in place
function crypto.AppendArray (array, array1)
	local array1Length = #array1

	for i = 1, array1Length do
		array [#array + 1] = array1 [i]
	end

	return array
end

-- Clones an array
function crypto.CloneArray (array, out)
	out = out or {}

	for i = 1, #array do
		out [i] = array [i]
	end

	return out
end

-- Truncates an array in place
function crypto.TruncateArray (array, endIndex)
	for i = endIndex + 1, #array do
		array [i] = nil
	end

	return array
end

-- Xors an array with another
function crypto.XorArrays (array1, array1StartIndex, array2, array2StartIndex, length, out, outStartIndex)
	return crypto.XorArrays2 (array1, array1StartIndex, array2, array2StartIndex, length, out, outStartIndex)
end

function crypto.XorArrays2 (array1, array1StartIndex, array2, array2StartIndex, length, out, outStartIndex)
	out = out or {}

	array1StartIndex = array1StartIndex or 1
	array2StartIndex = array2StartIndex or 1
	outStartIndex    = outStartIndex    or 1

	local array2Index = array2StartIndex
	local outputIndex = outStartIndex
	local array1EndIndex = array1StartIndex + length - 1
	for array1Index = array1StartIndex, array1EndIndex do
		out [outputIndex] = bit_bxor (array1 [array1Index], array2 [array2Index])

		array2Index = array2Index + 1
		outputIndex = outputIndex + 1
	end

	return out
end

function crypto.XorArrays3 (array1, array1StartIndex, array2, array2StartIndex, array3, array3StartIndex, length, out, outStartIndex)
	out = out or {}

	array1StartIndex = array1StartIndex or 1
	array2StartIndex = array2StartIndex or 1
	array3StartIndex = array3StartIndex or 1
	outStartIndex    = outStartIndex    or 1

	local array2Index = array2StartIndex
	local array3Index = array3StartIndex
	local outputIndex = outStartIndex
	local array1EndIndex = array1StartIndex + length - 1
	for array1Index = array1StartIndex, array1EndIndex do
		out [outputIndex] = bit_bxor (array1 [array1Index], array2 [array2Index], array3 [array3Index])

		array2Index = array2Index + 1
		array3Index = array3Index + 1
		outputIndex = outputIndex + 1
	end

	return out
end

-- Xors an array with another
function crypto.XorUInt8Arrays (array1, array1StartIndex, array2, array2StartIndex, length, out, outStartIndex)
	return crypto.XorArrays2 (array1, array1StartIndex, array2, array2StartIndex, length, out, outStartIndex)
end

function crypto.XorUInt8Arrays2 (array1, array1StartIndex, array2, array2StartIndex, length, out, outStartIndex)
	return crypto.XorArrays2 (array1, array1StartIndex, array2, array2StartIndex, length, out, outStartIndex)
end

function crypto.XorUInt8Arrays3 (array1, array1StartIndex, array2, array2StartIndex, array3, array3StartIndex, length, out, outStartIndex)
	return crypto.XorArrays3 (array1, array1StartIndex, array2, array2StartIndex, array3, array3StartIndex, length, out, outStartIndex)
end

-- Xors an array with another
function crypto.XorInt32Arrays (array1, array1StartIndex, array2, array2StartIndex, length, out, outStartIndex)
	return crypto.XorArrays2 (array1, array1StartIndex, array2, array2StartIndex, length, out, outStartIndex)
end

function crypto.XorInt32Arrays2 (array1, array1StartIndex, array2, array2StartIndex, length, out, outStartIndex)
	return crypto.XorArrays2 (array1, array1StartIndex, array2, array2StartIndex, length, out, outStartIndex)
end

function crypto.XorInt32Arrays3 (array1, array1StartIndex, array2, array2StartIndex, array3, array3StartIndex, length, out, outStartIndex)
	return crypto.XorArrays3 (array1, array1StartIndex, array2, array2StartIndex, array3, array3StartIndex, length, out, outStartIndex)
end

-- Converts a string to an array of uint8s
function crypto.StringToUInt8Array (str, out)
	out = out or {}
	out.n = #str

	-- ARE WE FAST YET?
	for i = 1, #str, 64 do
		out [i +  0], out [i +  1], out [i +  2], out [i +  3],
		out [i +  4], out [i +  5], out [i +  6], out [i +  7],
		out [i +  8], out [i +  9], out [i + 10], out [i + 11],
		out [i + 12], out [i + 13], out [i + 14], out [i + 15],
		out [i + 16], out [i + 17], out [i + 18], out [i + 19],
		out [i + 20], out [i + 21], out [i + 22], out [i + 23],
		out [i + 24], out [i + 25], out [i + 26], out [i + 27],
		out [i + 28], out [i + 29], out [i + 30], out [i + 31],
		out [i + 32], out [i + 33], out [i + 34], out [i + 35],
		out [i + 36], out [i + 37], out [i + 38], out [i + 39],
		out [i + 40], out [i + 41], out [i + 42], out [i + 43],
		out [i + 44], out [i + 45], out [i + 46], out [i + 47],
		out [i + 48], out [i + 49], out [i + 50], out [i + 51],
		out [i + 52], out [i + 53], out [i + 54], out [i + 55],
		out [i + 56], out [i + 57], out [i + 58], out [i + 59],
		out [i + 60], out [i + 61], out [i + 62], out [i + 63]  = string_byte (str, i, i + 63)
	end

	out = crypto.TruncateArray (out, #str)

	return out
end

-- Converts an array of uint8s to a string destructively
function crypto.UInt8ArrayToString (array, startIndex)
	startIndex = startIndex or 1

	-- Process pairs of uint8s
	local length = #array - startIndex + 1
	local endIndex = #array
	if length % 2 == 1 then endIndex = endIndex - 1 end

	local j = startIndex
	for i = startIndex, endIndex, 2 do
		array [j] = byteCharacters2 [array [i] + array [i + 1] * 256]
		j = j + 1
	end

	-- Process remaining uint8 if there is one
	if length % 2 == 1 then
		array [j] = byteCharacters [array [#array]]
		j = j + 1
	end

	return table_concat (array, nil, startIndex, j - 1)
end

local oneOver64 = 1 / 64
-- Converts a string to an array of uint32s
function crypto.StringToUInt32Array (str, out)
	out = out or {}
	out.n = #str

	local fullChunkCount = math_floor (#str * oneOver64)
	local fullChunkCountMinusOne = fullChunkCount - 1
	for i = 0, fullChunkCountMinusOne do
		local uint80,  uint81,  uint82,  uint83,
		      uint84,  uint85,  uint86,  uint87,
		      uint88,  uint89,  uint810, uint811,
		      uint812, uint813, uint814, uint815,
		      uint816, uint817, uint818, uint819,
		      uint820, uint821, uint822, uint823,
		      uint824, uint825, uint826, uint827,
		      uint828, uint829, uint830, uint831,
		      uint832, uint833, uint834, uint835,
		      uint836, uint837, uint838, uint839,
		      uint840, uint841, uint842, uint843,
		      uint844, uint845, uint846, uint847,
		      uint848, uint849, uint850, uint851,
		      uint852, uint853, uint854, uint855,
		      uint856, uint857, uint858, uint859,
		      uint860, uint861, uint862, uint863  = string_byte (str, i * 64 + 1, i * 64 + 64)

		out [i * 16 +  1] = uint80  + uint81  * 256 + uint82  * 65536 + uint83  * 16777216
		out [i * 16 +  2] = uint84  + uint85  * 256 + uint86  * 65536 + uint87  * 16777216
		out [i * 16 +  3] = uint88  + uint89  * 256 + uint810 * 65536 + uint811 * 16777216
		out [i * 16 +  4] = uint812 + uint813 * 256 + uint814 * 65536 + uint815 * 16777216
		out [i * 16 +  5] = uint816 + uint817 * 256 + uint818 * 65536 + uint819 * 16777216
		out [i * 16 +  6] = uint820 + uint821 * 256 + uint822 * 65536 + uint823 * 16777216
		out [i * 16 +  7] = uint824 + uint825 * 256 + uint826 * 65536 + uint827 * 16777216
		out [i * 16 +  8] = uint828 + uint829 * 256 + uint830 * 65536 + uint831 * 16777216
		out [i * 16 +  9] = uint832 + uint833 * 256 + uint834 * 65536 + uint835 * 16777216
		out [i * 16 + 10] = uint836 + uint837 * 256 + uint838 * 65536 + uint839 * 16777216
		out [i * 16 + 11] = uint840 + uint841 * 256 + uint842 * 65536 + uint843 * 16777216
		out [i * 16 + 12] = uint844 + uint845 * 256 + uint846 * 65536 + uint847 * 16777216
		out [i * 16 + 13] = uint848 + uint849 * 256 + uint850 * 65536 + uint851 * 16777216
		out [i * 16 + 14] = uint852 + uint853 * 256 + uint854 * 65536 + uint855 * 16777216
		out [i * 16 + 15] = uint856 + uint857 * 256 + uint858 * 65536 + uint859 * 16777216
		out [i * 16 + 16] = uint860 + uint861 * 256 + uint862 * 65536 + uint863 * 16777216
	end

	if #str % 64 ~= 0 then
		local startIndex = #str - #str % 64 + 1
		for i = startIndex, #str, 4 do
			local uint80, uint81, uint82, uint83 = string_byte (str, i, i + 3)
			uint80, uint81, uint82, uint83 = uint80 or 0, uint81 or 0, uint82 or 0, uint83 or 0
			out [#out + 1] = uint80 + uint81 * 256 + uint82 * 65536 + uint83 * 16777216
		end
	end

	out = crypto.TruncateArray (out, math_ceil (#str * 0.25))

	return out
end

-- Converts an array of int32s to a string
local bit = bit
local oneOver65536 = 1 / 65536
function crypto.Int32ArrayToString (array, startIndex)
	startIndex = startIndex or 1

	local length = (array.n or (#array * 4)) - (startIndex - 1) * 4

	local t = {}
	for i = startIndex, #array do
		local uint32 = array [i]
		local uint80 = uint32 % 256   uint32 = uint32 - uint80
		local uint81 = uint32 % 65536 uint32 = uint32 - uint81 uint32 = uint32 * oneOver65536
		local uint82 = uint32 % 256   uint32 = uint32 - uint82
		local uint83 = uint32 % 65536

		t [#t + 1] = byteCharacters2 [uint80 + uint81]
		t [#t + 1] = byteCharacters2 [uint82 + uint83]
	end

	if length % 4 == 1 then
		t [#t] = nil
		t [#t] = string_sub (t [#t], 1, 1)
	elseif length % 4 == 2 then
		t [#t] = nil
	elseif length % 4 == 3 then
		t [#t] = string_sub (t [#t], 1, 1)
	end

	return table_concat (t)
end

-- Converts an array of uint32s to a string
function crypto.UInt32ArrayToString (array, startIndex)
	return crypto.Int32ArrayToString (array, startIndex)
end

return crypto