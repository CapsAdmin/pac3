E2Lib.RegisterExtension("pac", true)

util.AddNetworkString("pac_e2_setkeyvalue_str")
e2function void pacSetKeyValue(entity owner, string global_id, string key, string value)
	net.Start("pac_e2_setkeyvalue_str")
		net.WriteEntity(self.player)
		net.WriteEntity(owner)
		net.WriteString(global_id)
		net.WriteString(key)

		net.WriteString(value)
	net.Broadcast()
end

util.AddNetworkString("pac_e2_setkeyvalue_num")
e2function void pacSetKeyValue(entity owner, string global_id, string key, number value)
	net.Start("pac_e2_setkeyvalue_num")
		net.WriteEntity(self.player)
		net.WriteEntity(owner)
		net.WriteString(global_id)
		net.WriteString(key)

		net.WriteFloat(value)
	net.Broadcast()
end

util.AddNetworkString("pac_e2_setkeyvalue_vec")
e2function void pacSetKeyValue(entity owner, string global_id, string key, vector value)
	net.Start("pac_e2_setkeyvalue_vec")
		net.WriteEntity(self.player)
		net.WriteEntity(owner)
		net.WriteString(global_id)
		net.WriteString(key)

		net.WriteVector(Vector(value[1], value[2], value[3]))
	net.Broadcast()
end

util.AddNetworkString("pac_e2_setkeyvalue_ang")
e2function void pacSetKeyValue(entity owner, string global_id, string key, angle value)
	net.Start("pac_e2_setkeyvalue_ang")
		net.WriteEntity(self.player)
		net.WriteEntity(owner)
		net.WriteString(global_id)
		net.WriteString(key)

		net.WriteAngle(Angle(value[1], value[2], value[3]))
	net.Broadcast()
end