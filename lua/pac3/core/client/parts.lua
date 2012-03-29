local class = pac.class

pac.ActiveParts = {}

function pac.CreatePart(name)
	local part = class.Create("part", name)

	part:Initialize()

	table.insert(pac.ActiveParts, part)

	part:SetName("part " .. #pac.ActiveParts)

	pac.CallHook("OnPartCreated", part)

	return part
end

function pac.RegisterPart(META, name)
	if not META.Base then
		class.InsertIntoBaseField(META, "base")
	end
	class.Register(META, "part", name)
end

function pac.GetRegisteredParts()
	return class.GetAll("part")
end

function pac.GetPart(name)
	return class.Get("part", name)
end

function pac.GetAllParts()
	return pac.ActiveParts
end

function pac.RemoveAllParts()
	for key, part in pairs(pac.ActiveParts) do
		part:Remove()
	end
	pac.ActiveParts = {}
end

function pac.CallPartHook(name, ...)
	for key, outfit in pairs(pac.Outfits) do
		for key, part in pairs(outfit:GetParts()) do
			if part[name] then
				part[name](part, ...)
			end
		end
	end
end