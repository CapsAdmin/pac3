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

	done()
end