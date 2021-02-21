local function equal(a,b, msg)
	if a ~= b then
		error(tostring(a) .. " != " .. tostring(b) .. ": " .. msg .. "\n", 2)
	end
end

function test.Run(done)
	local owner = pac.LocalPlayer
	local prev = owner:GetModel()
	local mdl = "models/combine_helicopter/helicopter_bomb01.mdl"

	if prev == mdl then
		owner:SetModel(test.RunLuaOnServer("return Entity(" .. owner:EntIndex() .. "):GetModel()"))
		prev = owner:GetModel()
		assert(prev ~= mdl, "something is wrong!!")
	end

	for _, class in ipairs({"entity", "entity2"}) do
		local root = pac.CreatePart("group")
		local entity = root:CreatePart(class)

		-- the owner is not valid right away, when the owner is valid, the changes are applied
		repeat yield() until entity:GetOwner():IsValid()

		entity:SetModel(mdl)

		equal(owner:GetModel(), mdl, " after "..class..":SetModel")
		root:Remove()
		equal(owner:GetModel(), prev, " after root is removed, the model should be reverted")
	end

	RunConsoleCommand("pac_modifier_model", "1")
	repeat yield() until GetConVar("pac_modifier_model"):GetBool()

	pac.emut.MutateEntity(owner, "model", owner, mdl)

	equal(test.RunLuaOnServer("return Entity(" .. owner:EntIndex() .. "):GetModel()"), mdl, " server model differs")

	RunConsoleCommand("pac_modifier_model", "0")
	repeat yield() until not GetConVar("pac_modifier_model"):GetBool()

	equal(test.RunLuaOnServer("return Entity(" .. owner:EntIndex() .. "):GetModel()"), prev, " should be reverted")

	pac.emut.RestoreMutations(owner, "model", owner)

	RunConsoleCommand("pac_modifier_model", "1")
	repeat yield() until GetConVar("pac_modifier_model"):GetBool()

	done()
end


function test.Teardown()
	timer.Remove("pac_test")
end