function pac.PrePlayerDraw(ply)
	if not ply:IsPlayer() then return end
	for key, part in pairs(pac.GetParts()) do
		if 
			not part:IsHidden() and
			not part.Screenspace and 
			not part.Translucent and 
			part:GetOwner() == ply and 
			not part:HasParent() 
		then
			part:Draw("OnDraw")
			part:Draw("PrePlayerDraw")
		end
	end
end
pac.AddHook("PrePlayerDraw")

function pac.PostPlayerDraw(ply)
	if not ply:IsPlayer() then return end
	for key, part in pairs(pac.GetParts()) do
		if 
			not part:IsHidden() and
			not part.Screenspace and 
			not part.Translucent and 
			part:GetOwner() == ply and 
			not part:HasParent() 
		then
			part:Draw("OnDraw")
			part:Draw("PostPlayerDraw")
		end
	end
end
pac.AddHook("PostPlayerDraw")

function pac.PostDrawTranslucentRenderables()
	for key, part in pairs(pac.GetParts()) do
		if 
			not part:IsHidden() and
			(part.Translucent or not part.Screenspace) and 
			not part:GetOwner():IsPlayer() and 
			not part:HasParent() 
		then
			part:Draw("OnDraw")
		end
	end
end
pac.AddHook("PostDrawTranslucentRenderables")

function pac.RenderScreenspaceEffect()
	for key, part in pairs(pac.GetParts()) do
		if 
			not part:IsHidden() and
			(part.Screenspace or not part.Translucent) and
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

function pac.OnEntityCreated(ply)
	timer.Simple(1, function()
		if ply:IsPlayer() then
			--pac.LoadPartFromProfile(ply)
		end
	end)
end
pac.AddHook("OnEntityCreated")

function pac.EntityRemoved(ent)
	for key, part in pairs(pac.GetParts()) do
		if part:IsValid() and part:GetOwner() == ent then
			part:Remove()
		end
	end
end
--pac.AddHook("EntityRemoved")

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