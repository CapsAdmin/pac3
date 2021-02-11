function test.Run(done)
	local prev = LocalPlayer():GetModel()

	local root = pac.CreatePart("group")
	local entity = root:CreatePart("entity2")

	local mdl = "models/combine_helicopter/helicopter_bomb01.mdl"
	entity:SetModel(mdl)

	local owner = root:GetOwner()

	assert(owner:GetModel() == mdl)
	root:Remove()
	assert(owner:GetModel() == prev)

	RunConsoleCommand("pac_modifier_model", "1")

	pacx.SetModelOnServer(owner, mdl)
	test.RunLuaOnServer("return Entity(" .. owner:EntIndex() .. "):GetModel()", function(server_mdl)
		assert(server_mdl == mdl)

		RunConsoleCommand("pac_modifier_model", "0")

		test.RunLuaOnServer("return Entity(" .. owner:EntIndex() .. "):GetModel()", function(server_mdl)
			assert(server_mdl == prev)
			pacx.SetModelOnServer(owner)
			RunConsoleCommand("pac_modifier_model", "1")
			done()
		end)
	end)
end


function test.Teardown()
	timer.Remove("pac_test")
end