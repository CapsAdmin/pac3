local function draw(ent, part, event)
	for key, part in pairs(ent.pac_parts) do
		if part:IsValid() then 
			part:Draw(event)
		else
			ent.pac_parts[key] = nil
		end
	end	
end

function pac.HookEntityRender(ent, part)
	if part:IsValid() and not part:HasParent() then	
		if not ent.pac_parts then
			ent.pac_parts = {[part.Id] = part}
		else
			ent.pac_parts[part.Id] = part
		end

		if 
			ent.pac_old_RenderOverride == nil or
			ent.pac_overriden_RenderOverride and 
			ent.RenderOverride ~= ent.pac_overriden_RenderOverride 
		then
			if ent.RenderOverride then
				local old_RenderOverride = ent.RenderOverride
				
				function ent:RenderOverride(...)
					if not self.pac_parts then
						pac.UnhookEntityRender(self)
					else
						self:InvalidateBoneCache()
						draw(self, part, "PreDraw")			
						old_RenderOverride(self, ...)
						draw(self, part, "OnDraw")
						self:InvalidateBoneCache()
					end		
				end
				
				ent.pac_overriden_RenderOverride = ent.RenderOverride
				ent.pac_old_RenderOverride = old_RenderOverride
			else 			
				function ent:RenderOverride()
					if not self.pac_parts then
						pac.UnhookEntityRender(self)
					else
						self:InvalidateBoneCache()
						draw(self, part, "PreDraw")			
						self:DrawModel()
						draw(self, part, "OnDraw")
						self:InvalidateBoneCache()
					end						
				end
				
				ent.pac_overriden_RenderOverride = ent.RenderOverride
				ent.pac_old_RenderOverride = false
			end
		end
	end
end

function pac.UnhookEntityRender(ent)	
	if ent.pac_old_RenderOverride then
		ent.RenderOverride = ent.pac_old_RenderOverrid
	elseif ent.pac_old_RenderOverride == false then
		ent.RenderOverride = nil
	end

	ent.pac_overriden_RenderOverride = nil
	ent.pac_old_RenderOverride = nil
	ent.pac_parts = nil
	--print("unhooked ", ent)
end

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
--pac.AddHook("RenderScreenspaceEffect")

function pac.Tick()
	pac.CallPartHook("Think")
	
	for key, part in pairs(pac.ActiveParts) do
		if not part:IsValid() then
			pac.ActiveParts[key] = nil
			pac.MakeNull(part)
		end
	end
end
pac.AddHook("Tick")

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
	for key, part in pairs(pac.GetParts()) do
		if part.pac3_bonebuild_ref == ent then
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