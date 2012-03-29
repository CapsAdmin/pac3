pac.Outfits = {}

function pac.GetOutfits()
	for key, outfit in ipairs(pac.Outfits) do
		if not outfit:IsValid() then
			table.remove(pac.Outfits, key)
		end
	end
	return pac.Outfits
end

function pac.CreateOutfit(owner)
	local outfit = setmetatable({}, table.Copy(pac.OutfitMeta))
	outfit.outfits_index = table.insert(pac.Outfits, outfit)

	if owner then
		outfit:SetOwner(owner)
	end

	outfit:SetName("outfit " .. #pac.GetOutfits())

	pac.CallHook("OnOutfitCreated", outfit)

	return outfit
end

function pac.RemoveOutfit(target)
	for key, outfit in ipairs(pac.Outfits) do
		if outfit == target then
			table.remove(pac.Outfits, key)
			return true
		end
	end
	return false
end

function pac.RemoveOutfitByName(name)
	for key, outfit in ipairs(pac.GetOutfits()) do
		if outfit.Name == name then
			outfit:Remove()
			return true
		end
	end
	return false
end