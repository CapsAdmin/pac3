function pac.OnEntityCreated(ent)
	if ent:IsValid() and ent:GetOwner():IsPlayer() then
		for key, part in pairs(pac.GetParts()) do
			if not part:HasParent() then
				part:CheckOwner(ent)
			end
		end
	end
end
pac.AddHook("OnEntityCreated")

function pac.EntityRemoved(ent)
	if ent:IsValid() and ent:GetOwner():IsPlayer() then
		for key, part in pairs(pac.GetParts()) do
			if not part:HasParent() then
				part:CheckOwner(ent)
			end
		end
	end
end
pac.AddHook("EntityRemoved")

timer.Create("pac_gc", 2, 0, function()
	for key, part in pairs(pac.GetParts()) do	
		if not part:GetPlayerOwner():IsValid() then
			part:Remove()
		end
	end
end)

net.Receive("pac_submit", function()
	local tbl = net.ReadTable()
	pac.CreatePart(tbl.ent):SetTable(tbl.part)
end)

net.Receive("pac_effect_precached", function()
	local name = net.ReadString()
	pac.CallHook("EffectPrecached", name)
end)