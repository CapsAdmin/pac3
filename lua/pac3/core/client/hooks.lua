function pac.OnEntityCreated(ent)
	if ent:IsValid() then
		for key, part in pairs(pac.GetParts()) do
			part:CheckOwner(ent)
		end
	end
end
pac.AddHook("OnEntityCreated")

function pac.EntityRemoved(ent)
	if ent:IsValid() then
		for key, part in pairs(pac.GetParts()) do
			part:CheckOwner(ent)
		end
	end
end
pac.AddHook("EntityRemoved")

function pac.EntityBuildBonePositions(ent)	
	if not cvar_enable:GetBool() then return end

	for key, part in pairs(pac.GetParts()) do
		if (ent == part:GetOwner() or ent == part.Entity) and not part:IsHiddenEx() then
			part:OnBuildBonePositions(ent)
		end
	end
end
pac.AddHook("EntityBuildBonePositions")

net.Receive("pac_submit", function()
	local tbl = net.ReadTable()
	pac.CreatePart(tbl.ent):SetTable(tbl.part)
end)

net.Receive("pac_effect_precached", function()
	local name = net.ReadString()
	pac.CallHook("EffectPrecached", name)
end)