function test.Run(done)
	local root = pac.CreatePart("group")

	for class_name in pairs(pac.GetRegisteredParts()) do
		root:CreatePart(class_name)
	end

	timer.Simple(0.5, function()
		root:Remove()
		done()
	end)
end