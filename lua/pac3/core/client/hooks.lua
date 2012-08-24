pac.drawn_entities = pac.drawn_entities or {}
local pairs = pairs
local render_ResetModelLighting = render.ResetModelLighting
local time = 0

local function think(part)
	if part.ThinkTime == 0 then
		part:Think()
	elseif not part.last_think or part.last_think < time then
		part:Think()
		part.last_think = time + (part.ThinkTime or 0.1)
	end
	
	for _, part in pairs(part.Children) do
		think(part)
	end
end

function pac.RenderOverride(ent)
	if not ent.pac_parts then
		pac.UnhookEntityRender(ent)
	else
		ent:InvalidateBoneCache()
		ent:SetupBones()
			for key, part in pairs(ent.pac_parts) do
				if part:IsValid() then
					if not part:HasParent() then
						think(part)
						part:Draw("OnDraw")
					end
				else
					ent.pac_parts[key] = nil
				end
			end	
	end
end

function pac.HookEntityRender(ent, part)
	if part:IsValid() and not part:HasParent() then	
		pac.dprint("hooking render on %s to draw part %s", tostring(ent), tostring(part))
		
		if not ent.pac_parts then
			ent.pac_parts = {}
		end
		
		ent.pac_parts[part.Id] = part
		
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

pac.EyePos = vector_origin
function pac.RenderScene(pos)
	pac.EyePos = pos
end
pac.AddHook("RenderScene")

function pac.PostDrawTranslucentRenderables()
	if not cvar_enable:GetBool() then return end
		
	time = RealTime()
	local draw_dist = cvar_distance:GetInt()
	local local_player = LocalPlayer() 
	local radius = 0
	
	for key, ent in pairs(pac.drawn_entities) do
		if ent:IsValid() then
			ent.pac_pixvis = ent.pac_pixvis or util.GetPixelVisibleHandle()
			local dst = ent:EyePos():Distance(pac.EyePos)
			radius = ent:BoundingRadius() * 3
			if 
				(ent == local_player and ent:ShouldDrawLocalPlayer()) or
				
				ent ~= local_player and 
				(					
					util_PixelVisible(ent:EyePos(), radius, ent.pac_pixvis) ~= 0 and 
					(draw_dist <= 0 or dst < draw_dist) or
					(dst < radius or dst < 200)
				)
			then
				pac.RenderOverride(ent)
			end
		else	
			pac.drawn_entities[key] = nil
		end
	end
	
	pac.CheckParts()
end
pac.AddHook("PostDrawTranslucentRenderables")

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

if VERSION >= 150 then
	net.Receive("pac_submit", function()
		local tbl = net.ReadTable()
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