
function test.Run(done)
	local function find_part_in_entities(part)
		for k,v in pairs(ents.GetAll()) do
			if v.PACPart == part then
				return v.PACPart
			end
		end
	end

	for _, part in pairs(pac.GetLocalParts()) do
		part:Remove()
	end

	assert(table.Count(pac.GetLocalParts()) == 0)

	local part = pac.CreatePart("group")
	local model = part:CreatePart("model")
	assert(table.Count(pac.GetLocalParts()) == 2)

	model:SetModel("models/props_combine/breenchair.mdl")

	assert(find_part_in_entities(model) == model)

	assert(model:GetOwner():GetModel() == model:GetOwner():GetModel())

	model:Remove()

	assert(table.Count(pac.GetLocalParts()) == 1)

	part:Remove()

	assert(table.Count(pac.GetLocalParts()) == 0)

	done()
end