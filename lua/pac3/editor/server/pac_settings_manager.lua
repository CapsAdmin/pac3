
util.AddNetworkString("pac_send_sv_cvar")

net.Receive("pac_send_sv_cvar", function(len,ply)
	if ply == Entity(1) or ply:IsAdmin() then print("authenticated") else return end
	local cmd = net.ReadString()
	local val = net.ReadString()
	--if cmd == "" then
		
	--end
	GetConVar(cmd):SetString(val)
	print("[PAC3]: Admin "..ply:GetName().." set "..cmd.." to "..val)
end)
