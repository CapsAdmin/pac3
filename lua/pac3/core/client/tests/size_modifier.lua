local function equal(a,b, msg, level)
	level = level or 0
	if a ~= b then
		error(tostring(a) .. " != " .. tostring(b) .. ": " .. msg, 2 + level)
	end
end

local function check_shared(owner, what, expect)
	equal(test.RunLuaOnServer("return Entity(" .. owner:EntIndex() .. "):"..what.."()"), expect, " server mismatch with client", 1)
end

function test.Run(done)
	local owner = pac.LocalPlayer

	for _, class in ipairs({"entity", "entity2"}) do
		local root = pac.CreatePart("group")
		local entity = root:CreatePart(class)

		entity:SetSize(0.5)

		-- the owner is not valid right away, when the owner is valid, the changes are applied
		repeat yield() until entity:GetOwner():IsValid()

		equal(owner:GetModelScale(), 0.5, "after :SetSize")
		root:Remove()
		equal(owner:GetModelScale(), 1, "should revert after root is removed")
	end

	check_shared(owner, "GetCurrentViewOffset", Vector(0,0,64))

	RunConsoleCommand("pac_modifier_size", "1")
	repeat yield() until GetConVar("pac_modifier_size"):GetBool()

	pac.emut.MutateEntity(owner, "size", owner, 0.5)
	repeat yield() until owner:GetModelScale() == 0.5

	check_shared(owner, "GetCurrentViewOffset", Vector(0,0,32))

	equal(test.RunLuaOnServer("return Entity(" .. owner:EntIndex() .. "):GetModelScale()"), 0.5, " server mismatch with client")

	pac.emut.MutateEntity(owner, "size", owner, 1)

	repeat yield() until owner:GetModelScale() == 1
	check_shared(owner, "GetCurrentViewOffset", Vector(0,0,64))

	RunConsoleCommand("pac_modifier_size", "0")
	repeat yield() until not GetConVar("pac_modifier_size"):GetBool()

	pac.emut.MutateEntity(owner, "size", owner, 2)

	repeat yield() until owner:GetModelScale() == 1
	check_shared(owner, "GetCurrentViewOffset", Vector(0,0,64))

	pac.emut.RestoreMutations(owner, "size", owner)

	RunConsoleCommand("pac_modifier_size", "1")
	repeat yield() until GetConVar("pac_modifier_size"):GetBool()

	repeat yield() until owner:GetModelScale() == 1

	check_shared(owner, "GetCurrentViewOffset", Vector(0,0,64))
	check_shared(owner, "GetViewOffsetDucked", Vector(0,0,28))
	check_shared(owner, "GetStepSize", 18)

	done()
end