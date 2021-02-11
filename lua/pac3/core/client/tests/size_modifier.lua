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
	local stage = 1

	timer.Create("pac_test", 0, 0, function()

		if stage == 1 then
			if owner:GetModelScale() == 0.5 then
				stage = 1.5

				test.RunLuaOnServer("return Entity(" .. owner:EntIndex() .. "):GetModelScale()", function(server_size)
					assert(server_size == 0.5)
					stage = 2
					pacx.SetEntitySizeOnServer(owner, 1)
				end)
			end
		elseif stage == 2 then
			if owner:GetModelScale() == 1 then
				stage = 3
				RunConsoleCommand("pac_modifier_size", "0")
				pacx.SetEntitySizeOnServer(owner, 2)
			end
		elseif stage == 3 then
			if owner:GetModelScale() == 1 then
				RunConsoleCommand("pac_modifier_size", "1")
				pacx.SetEntitySizeOnServer(owner, 1)
				done()
			end
		end
	end)
end

function test.Teardown()
	timer.Remove("pac_test")
end