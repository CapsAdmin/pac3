function pac.PrePlayerDraw(ply)
	if not ply:IsPlayer() then return end
	
	for key, part in pairs(pac.GetParts()) do
		if 
			not part.Screenspace and 
			not part:IsHidden() and
			part:GetOwner() == ply and 
			not part:HasParent() 
		then
			part:Draw("PreDraw")
		end
	end
end
pac.AddHook("PrePlayerDraw")

function pac.PostPlayerDraw(ply)
	if not ply:IsPlayer() then return end
	
	for key, part in pairs(pac.GetParts()) do
		if 
			not part.Screenspace and 
			not part:IsHidden() and
			part:GetOwner() == ply and 
			not part:HasParent() 
		then
			part:Draw("OnDraw")
		end
	end
end
pac.AddHook("PostPlayerDraw")

function pac.PostDrawTranslucentRenderables()
	for key, part in pairs(pac.GetParts()) do
		if 
			not part:IsHidden() and
			(part.Translucent or not part:GetOwner():IsPlayer()) and
			not part:HasParent() 
		then
			part:Draw("PreDraw")
			part:Draw("OnDraw")
		end
	end
end
pac.AddHook("PostDrawTranslucentRenderables")

function pac.RenderScreenspaceEffect()
	for key, part in pairs(pac.GetParts()) do
		if 
			not part:IsHidden() and
			part.Screenspace and
			not part:HasParent() 
		then
			part:Draw("OnDraw")
		end
	end
end
pac.AddHook("RenderScreenspaceEffect")

function pac.Tick()
	pac.CallPartHook("Think")
end
pac.AddHook("Tick")

function pac.OnEntityCreated(ent)
	if ent:IsValid() then
		for key, part in pairs(pac.GetParts(true)) do
			if part.ClassName == "group" then
				part:CheckOwner(ent)
			end
		end
	end
end
pac.AddHook("OnEntityCreated")

function pac.EntityRemoved(ent)
	if ent:IsValid() then
		for key, part in pairs(pac.GetParts(true)) do
			if part.ClassName == "group" then
				part:CheckOwner(ent)
			end
		end
	end
end
pac.AddHook("EntityRemoved")

if net then
	net.Receive("pac_submit", function()
		local tbl = glon.decode(net.ReadString())
		pac.CreatePart(tbl.ent):SetTable(tbl.part)
	end)
	
	net.Receive("pac_effect_precached", function()
		local name = net.ReadString()
		pac.CallHook("EffectPrecached", name)
	end)
else
	usermessage.Hook("pac_effect_precached", function(umr)
		local name = umr:ReadString()
		pac.CallHook("EffectPrecached", name)
	end)

	datastream.Hook("pac_submit", function( _, _, _, tbl)
		pac.CreatePart(tbl.ent):SetTable(tbl.part)
	end)
end