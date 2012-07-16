pac.drawn_entities = {}

local function draw(ent, part, event)
	for key, part in pairs(ent.pac_parts) do
		-- dont' draw children, they are handled by part:Draw()
		if part:IsValid() and not part:HasParent() then 
			part:Draw(event)
		else
			ent.pac_parts[key] = nil
		end
	end	
end

local render_ResetModelLighting = render.ResetModelLighting
local RENDERMODE_NONE = RENDERMODE_NONE

local FrameNumber = FrameNumber
local cvar = CreateClientConVar("pac_experimental_optimization", "0")
local frame_number = 0

function pac.RenderOverride(ent)
	frame_number = FrameNumber()
	
	if cvar:GetBool() and ent.pac_frame_number ~= frame_number then
		if not ent.pac_parts then
			pac.UnhookEntityRender(ent)
		else
			if ent:IsPlayer() then
				ent:SetRenderMode(RENDERMODE_NONE)
			end
			
			ent:InvalidateBoneCache()
			draw(ent, part, "PreDraw")
			--ent:DrawModel()
			ent:InvalidateBoneCache()
			draw(ent, part, "OnDraw")
			ent:InvalidateBoneCache()
		end
	end
	
	ent.pac_frame_number = frame_number
end

function pac.HookEntityRender(ent, part)
	if part:IsValid() and not part:HasParent() then	
		pac.dprint("hooking render on %s to draw part %s", tostring(ent), tostring(part))
		
		if not ent.pac_parts then
			ent.pac_parts = {[part.Id] = part}
		else
			ent.pac_parts[part.Id] = part
		end
		
		pac.drawn_entities[ent:EntIndex()] = ent
	end
end

function pac.UnhookEntityRender(ent)	
	pac.drawn_entities[ent:EntIndex()] = nil
		
	if ent:IsPlayer() then
		ent:SetRenderMode(RENDERMODE_NORMAL)
	end
	
	ent.pac_parts = nil
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

local pac = pac

function pac.PostDrawTranslucentRenderables()
	for key, ent in pairs(pac.drawn_entities) do
		if ent:IsValid() then
			if ent ~= LocalPlayer() or ent:ShouldDrawLocalPlayer() then
				pac.RenderOverride(ent)
			end
		else	
			pac.drawn_entities[key] = nil
		end
	end
end
pac.AddHook("PostDrawTranslucentRenderables")


function pac.Think()
	pac.CheckParts()
	pac.CallPartHook("Think")
end
pac.AddHook("Think")

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
		if part:GetOwner() == ent and not part:IsHiddenEx() then
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