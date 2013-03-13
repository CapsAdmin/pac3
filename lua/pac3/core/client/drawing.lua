local pac = pac

pac.drawn_entities = pac.drawn_entities or {}
local pairs = pairs

pac.LocalPlayer = NULL
pac.RealTime = 0
pac.FrameNumber = 0

local sort = function(a, b)
	if a and b and a.DrawOrder and b.DrawOrder then
		return a.DrawOrder < b.DrawOrder
	end
end
	
local function sortparts(parts)
	table.sort(parts, sort)
end

local function think(part)
	if part.ThinkTime == 0 then
		if part.last_think ~= pac.FrameNumber then 
			part:Think()
			part.last_think = pac.FrameNumber
		end
	elseif not part.last_think or part.last_think < pac.RealTime then
		part:Think()
		part.last_think = pac.RealTime + (part.ThinkTime or 0.1)
	end
	
	for _, part in pairs(part.Children) do
		think(part)
	end
end

local function buildbones(part)
	part:BuildBonePositions()
	
	for _, part in pairs(part.Children) do
		buildbones(part)
	end
end

local render_SetColorModulation = render.SetColorModulation
local render_SetBlend = render.SetBlend
local render_ModelMaterialOverride = render.ModelMaterialOverride
local render_MaterialOverride = render.MaterialOverride

function pac.RenderOverride(ent, type, draw_only)
	if not ent.pac_parts then
		pac.UnhookEntityRender(ent)
	else
		if not draw_only then
		
			pac.ResetBones(ent)
			
			-- bones MUST be setup before drawing or else unexpected/random results might happen
			for key, part in pairs(ent.pac_parts) do
				if part:IsValid() then
					if not part:HasParent() then
						buildbones(part)
					end
				else
					ent.pac_parts[key] = nil
					sortparts(ent.pac_parts)
				end
			end
		end
		
		for key, part in pairs(ent.pac_parts) do
			if part:IsValid() then		
				if not part:HasParent() then
					if not draw_only then think(part) end									
					
					if part.OwnerName == "viewmodel" then
						if type ~= "viewmodel" then continue end
						
						local owner = part:GetOwner()
						if owner:GetOwner() ~= pac.LocalPlayer then
							continue
						end
					elseif type == "viewmodel" then continue end
					
					part:Draw("OnDraw", nil, nil, type)
				end
			else
				ent.pac_parts[key] = nil
				sortparts(ent.pac_parts)
			end
		end
	end
	
	render_SetColorModulation(1,1,1)
	render_SetBlend(1)
	
	render_MaterialOverride()
	render_ModelMaterialOverride()
end

function pac.HookEntityRender(ent, part)
	if ent:IsValid() and part:IsValid() and not part:HasParent() then	
		pac.dprint("hooking render on %s to draw part %s", tostring(ent), tostring(part))
		
		if not ent.pac_parts then
			ent.pac_parts = {}
		end
		
		-- umm
		-- it sometimes say ent.pac_parts is nil
		-- why?
		if ent.pac_parts then
			table.insert(ent.pac_parts, part)
		
			pac.drawn_entities[ent:EntIndex()] = ent
			sortparts(ent.pac_parts)
		end
	end
end

function pac.UnhookEntityRender(ent)	
	pac.drawn_entities[ent:EntIndex()] = nil

	ent.pac_parts = nil
end


local util_PixelVisible = util.PixelVisible
local cvar_enable = CreateClientConVar("pac_enable", "1")
local cvar_distance = CreateClientConVar("pac_draw_distance", "500")

pac.EyePos = vector_origin
function pac.RenderScene(pos, ang)
	pac.EyePos = pos
	pac.EyeAng = ang
end
pac.AddHook("RenderScene")

local draw_dist
local radius

local dst

-- hacky optimization
-- allows only the last draw call
local cvar_framesuppress = CreateClientConVar("pac_suppress_frames", "1")

local function setup_suppress()
	local last_framenumber = 0
	local current_frame = 0
	local current_frame_count = 0
	
	return function()
		if cvar_framesuppress:GetBool() then
			local frame_number = FrameNumber()
			
			if frame_number == last_framenumber then
				current_frame = current_frame + 1
			else
				last_framenumber = frame_number
							
				if current_frame_count ~= current_frame then
					current_frame_count = current_frame
				end
				
				current_frame = 1
			end
					
			return current_frame < current_frame_count
		end
	end
end
-- hacky optimization

local last_enable

local should_suppress = setup_suppress()
function pac.PostDrawOpaqueRenderables(bool1, bool2, ...)	
	-- commonly used variables		
	pac.LocalPlayer = LocalPlayer() 
	
	if not cvar_enable:GetBool() then
		if last_enable ~= cvar_enable:GetBool() then
			for key, ent in pairs(pac.drawn_entities) do
				if ent:IsValid() then
					if ent.pac_parts and ent.pac_drawing == true then
						for key, part in pairs(ent.pac_parts) do
							part:CallRecursive("OnHide")
						end
						pac.ResetBones(ent)
					end
					ent.pac_drawing = false
				else
					pac.drawn_entities[key] = nil
				end
			end
			last_enable = cvar_enable:GetBool()
		end
	return else
		last_enable = nil
	end
	
	if should_suppress() then return end
	
	-- commonly used variables		
	pac.RealTime = RealTime()
	pac.FrameNumber = FrameNumber()

	draw_dist = cvar_distance:GetInt()
	radius = 0
	
	for key, ent in pairs(pac.drawn_entities) do
		if ent:IsValid() then
			ent.pac_pixvis = ent.pac_pixvis or util.GetPixelVisibleHandle()
			dst = ent:EyePos():Distance(pac.EyePos)
			radius = ent:BoundingRadius() * 3 * (ent:GetModelScale() or 1)
			
			if ent:IsPlayer() and radius < 32 then
				radius = 128
			end
			
			if not ent:IsPlayer() and not ent:IsNPC() then
				radius = radius * 4
			end
				
			if 				
				(ent == pac.LocalPlayer and ent:ShouldDrawLocalPlayer()) or
				
				ent ~= pac.LocalPlayer and 
				(					
					util_PixelVisible(ent:EyePos(), radius, ent.pac_pixvis) ~= 0 and 
					(ent.pac_draw_distance and (ent.pac_draw_distance <= 0 or ent.pac_draw_distance < dst)) or
					(draw_dist <= 0 or dst < draw_dist) or
					(dst < radius or dst < 200)
				)
			then
				if ent.pac_parts and ent.pac_drawing == false then
					for key, part in pairs(ent.pac_parts) do
						part:CallRecursive("OnShow", false, true)
					end
				end
			
				pac.RenderOverride(ent, "opaque")
				ent.pac_drawing = true
			else
				if ent.pac_parts and ent.pac_drawing == true then
					for key, part in pairs(ent.pac_parts) do
						part:CallRecursive("OnHide", false, true)
					end
					pac.ResetBones(ent)
				end
			
				ent.pac_drawing = false
			end
		else	
			pac.drawn_entities[key] = nil
		end
	end
	
	pac.CheckParts()
end
pac.AddHook("PostDrawOpaqueRenderables")

local should_suppress = setup_suppress()
function pac.PostDrawTranslucentRenderables()
	if should_suppress() then return end

	for key, ent in pairs(pac.drawn_entities) do
		if ent:IsValid() then
			if ent.pac_drawing and ent.pac_parts then
				pac.RenderOverride(ent, "translucent", true)
			end
		else
			pac.drawn_entities[key] = nil
		end
	end
end
pac.AddHook("PostDrawTranslucentRenderables")

local should_suppress = setup_suppress()
function pac.Think()
	if should_suppress() then return end
	
	for key, ent in pairs(pac.drawn_entities) do
		if ent:IsValid() then
			if ent.pac_drawing and ent:IsPlayer() then
			
				ent.pac_traceres = ent:GetEyeTraceNoCursor()
				ent.pac_hitpos = ent.pac_traceres.HitPos
				
			end
		else
			pac.drawn_entities[key] = nil
		end
	end
end
pac.AddHook("Think")

local should_suppress = setup_suppress()
function pac.PostDrawViewModel()
	--if should_suppress() then return end

	for key, ent in pairs(pac.drawn_entities) do
		if ent:IsValid() then
			if ent.pac_drawing and ent.pac_parts then
				pac.RenderOverride(ent, "viewmodel", true)
			end
		else
			pac.drawn_entities[key] = nil
		end
	end
end

pac.AddHook("PostDrawViewModel")