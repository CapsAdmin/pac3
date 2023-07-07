local crypto = include("pac3/libraries/urlobj/crypto.lua")

local CACHE = {}

local function CreateCache(cacheId)
	local cache = {}
	setmetatable(cache, { __index = CACHE })

	cache:Initialize(cacheId)

	return cache
end

function CACHE:Initialize(cacheId)
	self.Version = 3 -- Update this if the crypto library changes

	self.Path    = "pac3_cache/" .. string.lower(cacheId)

	file.CreateDir(self.Path)
end

function CACHE:AddItem(itemId, data)
	local hash = self:GetItemIdHash(itemId)
	local path = self.Path .. "/" .. hash .. ".txt"
	local key  = self:GetItemIdEncryptionKey(itemId)

	-- Version
	local f = file.Open(path, "wb", "DATA")
	if not f then return end
	f:WriteLong(self.Version)

	-- Header
	local compressedItemId = util.Compress(itemId)
	local entryItemId = crypto.EncryptString(compressedItemId, key)
	f:WriteLong(#entryItemId)
	f:Write(entryItemId, #entryItemId)

	-- Data
	local compressedData = util.Compress(data)
	data = crypto.EncryptString(compressedData, key)
	f:WriteLong(#data)
	f:Write(data, #data)

	f:Close()
end

function CACHE:Clear()
	for _, fileName in ipairs(file.Find(self.Path .. "/*", "DATA")) do
		file.Delete(self.Path .. "/" .. fileName)
	end
end

function CACHE:ClearBefore(time)
	for _, fileName in ipairs(file.Find(self.Path .. "/*", "DATA")) do
		if file.Time(self.Path .. "/" .. fileName, "DATA") < time then
			file.Delete(self.Path .. "/" .. fileName)
		end
	end
end

function CACHE:ContainsItem(itemId)
	return self:GetItem(itemId) ~= nil
end

function CACHE:GetItem(itemId)
	local hash = self:GetItemIdHash(itemId)
	local path = self.Path .. "/" .. hash .. ".txt"

	if not file.Exists(path, "DATA") then return nil end

	local f = file.Open(path, "rb", "DATA")
	if not f then return nil end

	local key = self:GetItemIdEncryptionKey(itemId)

	-- Version
	local version = f:ReadLong()
	if version ~= self.Version then
		f:Close()
		return nil
	end

	-- Header
	local entryItemIdLength = f:ReadLong()
	local entryItemId = crypto.DecryptString(f:Read(entryItemIdLength), key)
	entryItemId = util.Decompress(entryItemId)

	if itemId ~= entryItemId then
		f:Close()
		return nil
	end

	-- Data
	local dataLength = f:ReadLong()
	local data       = f:Read(dataLength, key)

	f:Close()

	data = crypto.DecryptString(data, key)
	data = util.Decompress(data)

	return data
end

function CACHE:GetItemIdEncryptionKey(itemId)
	return crypto.GenerateKey(string.reverse(itemId))
end

function CACHE:GetItemIdHash(itemId)
	return string.format("%08x", tonumber(util.CRC(itemId)))
end

return CreateCache
