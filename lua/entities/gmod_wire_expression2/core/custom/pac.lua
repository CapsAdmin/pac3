E2Lib.RegisterExtension("pac", true)

util.AddNetworkString("pac_e2_setkeyvalue_str")
util.AddNetworkString("pac_e2_setkeyvalue_num")
util.AddNetworkString("pac_e2_setkeyvalue_vec")
util.AddNetworkString("pac_e2_setkeyvalue_ang")

local enabledConvar = CreateConVar("pac_e2_ratelimit_enable", "1", {FCVAR_ARCHIVE}, "If the e2 ratelimit should be enabled.", 0, 1)
local rate = CreateConVar("pac_e2_ratelimit_refill", "0.025", {FCVAR_ARCHIVE}, "The speed at which the ratelimit buffer refills.", 0, 1000)
local buffer = CreateConVar("pac_e2_ratelimit_buffer", "300", {FCVAR_ARCHIVE}, "How large the ratelimit buffer should be.", 0, 1000)

local function canRunFunction(self)
	if not enabledConvar:GetBool() then return true end

	local allowed = pac.RatelimitPlayer(self.player, "e2_extension", buffer:GetInt(), rate:GetInt())
	if not allowed then
		E2Lib.raiseException("pac3 e2 ratelimit exceeded")
		return false
	end
	return true
end

e2function void pacSetKeyValue(entity owner, string global_id, string key, string value)
	if not canRunFunction(self) then return end
	net.Start("pac_e2_setkeyvalue_str")
		net.WriteEntity(self.player)
		net.WriteEntity(owner)
		net.WriteString(global_id)
		net.WriteString(key)

		net.WriteString(value)
	net.Broadcast()
end

e2function void pacSetKeyValue(entity owner, string global_id, string key, number value)
	if not canRunFunction(self) then return end
	net.Start("pac_e2_setkeyvalue_num")
		net.WriteEntity(self.player)
		net.WriteEntity(owner)
		net.WriteString(global_id)
		net.WriteString(key)

		net.WriteFloat(value)
	net.Broadcast()
end

e2function void pacSetKeyValue(entity owner, string global_id, string key, vector value)
	if not canRunFunction(self) then return end
	net.Start("pac_e2_setkeyvalue_vec")
		net.WriteEntity(self.player)
		net.WriteEntity(owner)
		net.WriteString(global_id)
		net.WriteString(key)

		net.WriteVector(Vector(value[1], value[2], value[3]))
	net.Broadcast()
end

e2function void pacSetKeyValue(entity owner, string global_id, string key, angle value)
	if not canRunFunction(self) then return end
	net.Start("pac_e2_setkeyvalue_ang")
		net.WriteEntity(self.player)
		net.WriteEntity(owner)
		net.WriteString(global_id)
		net.WriteString(key)

		net.WriteAngle(Angle(value[1], value[2], value[3]))
	net.Broadcast()
end
