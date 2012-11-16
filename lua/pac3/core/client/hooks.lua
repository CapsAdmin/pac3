function pac.OnEntityCreated(ent)
	if ent:IsValid() then
		for key, part in pairs(pac.GetParts()) do
			part:CheckOwner(ent)
		end
	end
end
pac.AddHook("OnEntityCreated")

function pac.EntityRemoved(ent)
	timer.Simple(0.1, function()
		if ent:IsValid() then
			for key, part in pairs(pac.GetParts()) do
				part:CheckOwner(ent)
			end
		end
	end)
end
pac.AddHook("EntityRemoved")

net.Receive("pac_submit", function()
	local tbl = net.ReadTable()
	pac.CreatePart(tbl.ent):SetTable(tbl.part)
end)

net.Receive("pac_effect_precached", function()
	local name = net.ReadString()
	pac.CallHook("EffectPrecached", name)
end)