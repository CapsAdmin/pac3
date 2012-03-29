function pac.PostPlayerDraw(ply)
	if not ply:IsPlayer() then return end
	for key, outfit in pairs(pac.GetOutfits()) do
		if outfit:GetOwner() == ply then
			outfit:Draw("PostPlayerDraw")
		end
	end
end
pac.AddHook("PostPlayerDraw")

function pac.PostDrawTranslucentRenderables()
	for key, outfit in pairs(pac.GetOutfits()) do
		outfit:Draw("PostDrawTranslucentRenderables")
	end
end
pac.AddHook("PostDrawTranslucentRenderables")

function pac.RenderScreenspaceEffect()
	for key, outfit in pairs(pac.GetOutfits()) do
		outfit:Draw("RenderScreenspaceEffect")
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
			pac.LoadOutfitFromProfile(ply)
		end
	end)
end
pac.AddHook("OnEntityCreated")

function pac.EntityRemoved(ent)
	for key, outfit in pairs(pac.GetOutfits()) do
		if outfit:GetOwner() == ent then
			outfit:Remove()
			pac.Outfits[key] = nil
		end
	end
end
pac.AddHook("EntityRemoved")

datastream.Hook("pac_submit", function( _, _, _, tbl)
	pac.CreateOutfit(tbl.ent):SetTable(tbl.outfit)
end)