pac.drawn_entities = pac.drawn_entities or {}

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

function pac.RenderOverride(ent)
	if not ent.pac_parts then
		pac.UnhookEntityRender(ent)
	else
		ent:InvalidateBoneCache()
		draw(ent, part, "PreDraw")
		--ent:DrawModel()
		ent:InvalidateBoneCache()
		draw(ent, part, "OnDraw")
		ent:InvalidateBoneCache()
	end
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

	ent.pac_parts = nil
end

local pac = pac

local LocalPlayer = LocalPlayer
local util_PixelVisible = util.PixelVisible
local cvar_enable = CreateClientConVar("pac_enable", "1")
local cvar_distance = CreateClientConVar("pac_draw_distance", "0")

local eye_pos = vector_origin
function pac.RenderScene(pos)
	eye_pos = pos
end
pac.AddHook("RenderScene")

function pac.PostDrawTranslucentRenderables()
	if not cvar_enable:GetBool() then return end
	
	local draw_dist = cvar_distance:GetInt()
	local local_player = LocalPlayer() 
	local radius = 0
	
	for key, ent in pairs(pac.drawn_entities) do
		if ent:IsValid() then
			ent.pac_pixvis = ent.pac_pixvis or util.GetPixelVisibleHandle()
			local dst = ent:EyePos():Distance(eye_pos)
			radius = ent:BoundingRadius() * 2
			if 
				(ent == local_player and ent:ShouldDrawLocalPlayer()) or
				
				ent ~= local_player and 
				(					
					util_PixelVisible(ent:EyePos(), radius, ent.pac_pixvis) ~= 0 and 
					(draw_dist <= 0 or dst < draw_dist) or
					dst < radius
				)
			then
				pac.RenderOverride(ent)
			end
		else	
			pac.drawn_entities[key] = nil
		end
	end
end
pac.AddHook("PostDrawTranslucentRenderables")


function pac.Think()
	if not cvar_enable:GetBool() then return end
	
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
	if not cvar_enable:GetBool() then return end
	
	for key, part in pairs(pac.GetParts()) do
		if (part:GetOwner() == ent or ent.pac_part_ref == part) and not part:IsHiddenEx() then
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