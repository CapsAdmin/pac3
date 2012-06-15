--PAC_RENDER_METHOD_PLAYER = true

if PAC_RENDER_METHOD_PLAYER then
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
else
	function pac.PrePlayerDraw(ply)
		if not ply:IsPlayer() then return end
		
		for key, part in pairs(pac.GetParts()) do
			if 
				not part.Screenspace and
				part.PrePlayerDraw and
				not part:IsHidden() and
				part:GetOwner() == ply 
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
				part.PostPlayerDraw and 
				not part:IsHidden() and
				part:GetOwner() == ply 
			then
				part:Draw("OnDrawz")
			end
		end
	end
	pac.AddHook("PostPlayerDraw")

	function pac.PostDrawTranslucentRenderables()
		for key, part in pairs(pac.GetParts()) do
			if 
				not part:IsHidden() and
				not part:HasParent() 
			then
				local owner = part:GetOwner()
				if owner ~= LocalPlayer() or LocalPlayer():ShouldDrawLocalPlayer() then
					if not owner:IsPlayer() then 
						part:Draw("PreDraw")
					end
					part:Draw("OnDraw")
				end
			end
		end
	end
	pac.AddHook("PostDrawTranslucentRenderables")

	function pac.RenderScreenspaceEffect()
		for key, part in pairs(pac.GetParts()) do
			if 
				part.Screenspace and
				not part:IsHidden() and
				not part:HasParent() 
			then
				local owner = part:GetOwner()
				if owner ~= LocalPlayer() or LocalPlayer():ShouldDrawLocalPlayer() then
					part:Draw("OnDraw")
				end
			end
		end
	end
	pac.AddHook("RenderScreenspaceEffect")
end

function pac.Tick()
	pac.CallPartHook("Think")
end
pac.AddHook("Tick")

function pac.OnEntityCreated(ent)
	if ent:IsValid() then
		for key, part in pairs(pac.GetParts(true)) do
			part:CheckOwner(ent)
		end
	end
end
pac.AddHook("OnEntityCreated")

function pac.EntityRemoved(ent)
	if ent:IsValid() then
		for key, part in pairs(pac.GetParts(true)) do
			part:CheckOwner(ent)
		end
	end
end
pac.AddHook("EntityRemoved")

function pac.EntityBuildBonePositions(ent)	
	for key, part in pairs(pac.GetParts()) do
		if not part:IsHiddenEx() and part.BuildBonePositions and part:GetOwner() == ent then
			part:BuildBonePositions(ent)
		end
	end
end
pac.AddHook("EntityBuildBonePositions")

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