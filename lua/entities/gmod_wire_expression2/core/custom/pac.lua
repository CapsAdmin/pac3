E2Lib.RegisterExtension("pac", true)

util.AddNetworkString("pac_e2_setkeyvalue")

local enabledConvar = CreateConVar("pac_e2_ratelimit_enable", "1", FCVAR_ARCHIVE, "If the e2 ratelimit should be enabled.", 0, 1)
local rate = CreateConVar("pac_e2_ratelimit_refill", "0.025", FCVAR_ARCHIVE, "The amount at which the ratelimit buffer refills per second.", 0, 1000)
local buffer = CreateConVar("pac_e2_ratelimit_buffer", "300", FCVAR_ARCHIVE, "How many PAC E2 operations are allowed before the rate limit is hit.", 0, 1000)
local bytes = CreateConVar("pac_e2_bytelimit", "2048", FCVAR_ARCHIVE, "Limit number of bytes sent per second for PAC E2 messages.", 0, 65532)

local byteLimits = WireLib.RegisterPlayerTable()
local function canRunFunction(self, g, k, v)
	local byteLimit = byteLimits[self.player]
	local ct = CurTime()
	if not byteLimit then
		byteLimit = { ct + 1, 0 }
		byteLimits[self.player] = byteLimit
	end

	local lim = #g + #k + #v
	if ct < byteLimit[1] then
		lim = lim + byteLimit[2]
	else
		byteLimit[1] = ct + 1
	end
	byteLimit[2] = lim

	if lim >= bytes:GetInt() then return self:throw("pac3 e2 byte limit exceeded", false) end

	if not enabledConvar:GetBool() then return true end

	local allowed = pac.RatelimitPlayer(self.player, "e2_extension", buffer:GetInt(), rate:GetFloat())
	if not allowed then
		return self:throw("pac3 e2 ratelimit exceeded", false)
	end
	return true
end

--- Domain-specific type IDs for networking E2 keyvalues
---@alias pac.E2.NetID
---| 0 # String
---| 1 # Number
---| 2 # Vector
---| 3 # Angle

e2function void pacSetKeyValue(entity owner, string global_id, string key, string value)
	if not canRunFunction(self, global_id, key, value) then return end
	net.Start("pac_e2_setkeyvalue", true)
		net.WriteEntity(self.player)
		net.WriteEntity(owner)
		net.WriteString(global_id)
		net.WriteString(key)
		net.WriteUInt(0, 2)
		net.WriteString(value)
	net.Broadcast()
end

e2function void pacSetKeyValue(entity owner, string global_id, string key, number value)
	if not canRunFunction(self, global_id, key, "nmbr") then return end -- Workaround because I don't want to add cases for each type, 4 bytes
	net.Start("pac_e2_setkeyvalue", true)
		net.WriteEntity(self.player)
		net.WriteEntity(owner)
		net.WriteString(global_id)
		net.WriteString(key)
		net.WriteUInt(1, 2)
		net.WriteFloat(value)
	net.Broadcast()
end

e2function void pacSetKeyValue(entity owner, string global_id, string key, vector value)
	if not canRunFunction(self, global_id, key, "vctrvctrvctr") then return end -- 4 bytes, 3 times
	net.Start("pac_e2_setkeyvalue", true)
		net.WriteEntity(self.player)
		net.WriteEntity(owner)
		net.WriteString(global_id)
		net.WriteString(key)
		net.WriteUInt(2, 2)
		net.WriteVector(value)
	net.Broadcast()
end

e2function void pacSetKeyValue(entity owner, string global_id, string key, angle value)
	if not canRunFunction(self, global_id, key, "vctrvctrvctr") then return end
	net.Start("pac_e2_setkeyvalue", true)
		net.WriteEntity(self.player)
		net.WriteEntity(owner)
		net.WriteString(global_id)
		net.WriteString(key)
		net.WriteUInt(3, 2)
		net.WriteAngle(value)
	net.Broadcast()
end
