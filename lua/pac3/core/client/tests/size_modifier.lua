function test.Run(done)
	local root = pac.CreatePart("group")
	local entity = root:CreatePart("entity2")

	entity:SetSize(0.5)

	local owner = root:GetOwner()
	assert(owner:GetModelScale() == 0.5)
	root:Remove()
	assert(owner:GetModelScale() == 1)

	RunConsoleCommand("pac_modifier_size", "1")

	pacx.SetEntitySizeOnServer(owner, 0.5)

	repeat yield() until owner:GetModelScale() == 0.5

	assert(test.RunLuaOnServer("return Entity(" .. owner:EntIndex() .. "):GetModelScale()") == 0.5)

	pacx.SetEntitySizeOnServer(owner, 1)

	repeat yield() until owner:GetModelScale() == 1

	RunConsoleCommand("pac_modifier_size", "0")
	pacx.SetEntitySizeOnServer(owner, 2)

	repeat yield() until owner:GetModelScale() == 1

	pacx.SetEntitySizeOnServer(owner)

	done()
end