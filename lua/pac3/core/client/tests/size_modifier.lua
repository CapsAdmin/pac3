function test.Run(done)
	local root = pac.CreatePart("group")
	local entity = root:CreatePart("entity2")

	entity:SetSize(0.5)

	local owner = root:GetOwner()
	assert(owner:GetModelScale() == 0.5)
	root:Remove()
	assert(owner:GetModelScale() == 1)

	done()
end