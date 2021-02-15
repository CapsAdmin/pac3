local function equal(a,b, msg)
	if a ~= b then
		error(tostring(a) .. " != " .. tostring(b) .. ": " .. msg, 2)
	end
end

function test.Run(done)
	local prev = LocalPlayer():GetModel()
	local mdl = "models/combine_helicopter/helicopter_bomb01.mdl"
	local owner = pac.LocalPlayer

	if prev == mdl then
		owner:SetModel(test.RunLuaOnServer("return Entity(" .. LocalPlayer():EntIndex() .. "):GetModel()"))
		prev = LocalPlayer():GetModel()
		assert(prev ~= mdl, "something is wrong!!")
	end

	for _, class in ipairs({"entity", "entity2"}) do
		local root = pac.CreatePart("group")
		local entity = root:CreatePart(class)

		entity:SetModel(mdl)

		equal(owner:GetModel(), mdl, " after "..class..":SetModel")
		root:Remove()
		equal(owner:GetModel(), prev, class.." after root is removed, the model should be reverted")
	end

	RunConsoleCommand("pac_modifier_model", "1")
	repeat yield() until GetConVar("pac_modifier_model"):GetBool()

	pacx.SetModel(owner, mdl, owner)

	equal(test.RunLuaOnServer("return Entity(" .. owner:EntIndex() .. "):GetModel()"), mdl, " server model differs")

	RunConsoleCommand("pac_modifier_model", "0")
	repeat yield() until not GetConVar("pac_modifier_model"):GetBool()

	equal(test.RunLuaOnServer("return Entity(" .. owner:EntIndex() .. "):GetModel()"), prev, " should be reverted")

	pacx.SetModel(owner, nil, owner)

	RunConsoleCommand("pac_modifier_model", "1")
	repeat yield() until GetConVar("pac_modifier_model"):GetBool()

	done()
end


function test.Teardown()
	timer.Remove("pac_test")
end