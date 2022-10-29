-- this is for the test suite, it is technically a lua run backdoor
-- the test suite is a utility for the pac developers to ensure that pac works and don't break
-- after making changes to it

util.AddNetworkString("pac3_test_suite_backdoor_receive_results")
util.AddNetworkString("pac3_test_suite_backdoor")

local enabledConvar = CreateConVar("pac_test_suite_backdoor_enabled", "0", {FCVAR_PROTECTED}, "Should the pac test suite backdoor be enabled, this allows lua access for superadmins.", 0, 1)

net.Receive("pac3_test_suite_backdoor", function(len, ply)
	-- need to be at least super admin
	if not enabledConvar:GetBool() then return end
	if not ply:IsSuperAdmin() then return end

	local id = net.ReadString()
	local lua_code = net.ReadString()


	local func = CompileString(lua_code, "pac3_test_suite_backdoor")

	local res = {func()}

	net.Start("pac3_test_suite_backdoor_receive_results")
		net.WriteString(id)
		net.WriteTable(res)
	net.Send(ply)
end)
