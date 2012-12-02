local function real_isvalid(s) return (pcall(s["GetPos"], s)) end

-- why does this hook get called with NULL entities?
function pac.OnEntityCreated(ent)
	if ent:IsValid() and ent:GetOwner():IsPlayer() and real_isvalid(ent) then
		for key, part in pairs(pac.GetParts()) do
			if not part:HasParent() then
				part:CheckOwner(ent)
			end
		end
	end
end
pac.AddHook("OnEntityCreated")

function pac.EntityRemoved(ent)
	if ent:IsValid() and ent:GetOwner():IsPlayer()and real_isvalid(ent)  then
		for key, part in pairs(pac.GetParts()) do
			if not part:HasParent() then
				part:CheckOwner(ent)
			end
		end
	end
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