jit.on(true) jit.flush()

local ENTITY = FindMetaTable("Entity")

local original = ENTITY.old_rofl_GetTable or ENTITY.GetTable
ENTITY.old_rofl_GetTable = ENTITY.old_rofl_GetTable or original

local cache = {}

function ENTITY:GetTable()
	if not cache[self] then
	 	cache[self] = original(self)
	end

	return cache[self]
end