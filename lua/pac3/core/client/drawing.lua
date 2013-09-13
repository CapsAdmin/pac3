jit.on(true, true)

local FrameNumber = FrameNumber
local RealTime = RealTime
local GetConVarNumber = GetConVarNumber
local pac = pac

pac.drawn_entities = pac.drawn_entities or {}
local pairs = pairs

pac.LocalPlayer = LocalPlayer()
pac.RealTime = 0
pac.FrameNumber = 0

local sort = function(a, b)
	if a and b then 
		if a.DrawOrder and b.DrawOrder then
			return a.DrawOrder < b.DrawOrder
		end
		
		if a.part and b.part and a.part.DrawOrder and b.part.DrawOrder then
			return a.part.DrawOrder < b.part.DrawOrder
		end
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
local collectgarbage = collectgarbage
local SysTime = SysTime
local util_TimerCycle = util.TimerCycle

local render_time = math.huge
local max_render_time_cvar = CreateClientConVar("pac_max_render_time", 0)
local max_render_time = 0

local TIME = math.huge
local GARBAGE = math.huge

pac.profile_info = {}
pac.profile = true

function pac.GetProfileTimes(ent)	
	local data = pac.profile_info[ent:EntIndex()]
	
	if data then
		local out = {events = {}}
		out.times_rendered = data.times_ran
		
		
		for type, data in pairs(data.types) do
			out.events[type] = {
				average_garbage = data.total_garbage / out.times_rendered,
				average_ms = data.total_render_time / out.times_rendered,
			}
		end
		
		return out
	end
end

local function hide_parts(ent)
	if ent.pac_parts and ent.pac_drawing == true then
		for key, part in pairs(ent.pac_parts) do
			part:CallRecursive("OnHide", false, true)
		end
		pac.ResetBones(ent)
	end

	ent.pac_drawing = false
end

function pac.RenderOverride(ent, type, draw_only)
	
	if pac.profile then
		TIME = util_TimerCycle()
		GARBAGE = collectgarbage("count")
	end
	
	if max_render_time > 0 and ent ~= pac.LocalPlayer then
		render_time = SysTime()
		
		if ent.pac_render_time_stop and ent.pac_render_time_stop > render_time then
			return
		end
	end

	
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
					if not draw_only then 
						think(part) 
					end			

					if part.OwnerName == "viewmodel" and type ~= "viewmodel" then
						continue
					end
					
					if part.OwnerName ~= "viewmodel" and type == "viewmodel" then
						continue
					end

					part:Draw("OnDraw", nil, nil, type)
				end
			else
				ent.pac_parts[key] = nil
				sortparts(ent.pac_parts)
			end
		end
	end

	if pac.profile then
		TIME = util_TimerCycle()
		GARBAGE = collectgarbage("count") - GARBAGE
		
		local id = ent:EntIndex()
		pac.profile_info[id] = pac.profile_info[id] or {types = {}, times_ran = 0}
		pac.profile_info[id].times_ran = pac.profile_info[id].times_ran + 1		

		pac.profile_info[id].types[type] = pac.profile_info[id].types[type] or {}
		
		local data = pac.profile_info[id].types[type]
		
		data.total_render_time = (data.total_render_time or 0) + TIME
		data.total_garbage = (data.total_garbage or 0) + GARBAGE
	end	
		
	if max_render_time > 0 and ent ~= pac.LocalPlayer then	
		ent.pac_render_times = ent.pac_render_times or {}
		
		local last = ent.pac_render_times[type] or 0
		
		render_time = (SysTime() - render_time) * 1000
		last = last + ((render_time - last) * FrameTime())
		ent.pac_render_times[type] = last
		
		if last > max_render_time then
			ent.pac_render_time_stop = SysTime() + 2 + (math.random() * 2)
			
			hide_parts(ent)
		end
	end
	
	render_SetColorModulation(1,1,1)
	render_SetBlend(1)
	
	render_MaterialOverride()
	render_ModelMaterialOverride()
end

pac.firstperson_parts = pac.firstperson_parts or {}

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
			
			if part.ShowInFirstperson and part:GetOwner() == pac.LocalPlayer then
				table.insert(pac.firstperson_parts, {ent = ent, part = part})
				sortparts(pac.firstperson_parts)
			end
		end
		
		pac.profile_info[ent:EntIndex()] = nil
	end
end

function pac.UnhookEntityRender(ent, part)	
	if part then
		if ent.pac_parts then
			for k,v in pairs(ent.pac_parts) do
				if v == part then
					ent.pac_parts[k] = nil
					sortparts(ent.pac_parts)
				end
			end
		end
	else
		pac.drawn_entities[ent:EntIndex()] = nil		
		ent.pac_parts = nil
	end
	
	pac.profile_info[ent:EntIndex()] = nil
end


local util_PixelVisible = util.PixelVisible
local cvar_distance = CreateClientConVar("pac_draw_distance", "500")

pac.EyePos = vector_origin
function pac.RenderScene(pos, ang)
	pac.EyePos = pos
	pac.EyeAng = ang
end
pac.AddHook("RenderScene")

-- hacky optimization
-- allows only the last draw call
local cvar_framesuppress = CreateClientConVar("pac_suppress_frames", "1")

-- this needs to be called when before drawing things like minimaps and pac_suppress_frames is on
function pac.SkipRendering(b)
	pac.skip_rendering = b
end

-- this is if you want to force it
function pac.ForceRendering(b)
	pac.force_rendering = b
end

local function setup_suppress()
	local last_framenumber = 0
	local current_frame = 0
	local current_frame_count = 0
	
	return function()
		if pac.force_rendering then
			return false
		end
	
		if pac.skip_rendering then 
			return true
		end
		
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

pac.SetupSuppress = setup_suppress
-- hacky optimization

local draw_dist = 0
local sv_draw_dist = 0
local radius = 0
local dst = 0

--local garbage = 0

local should_suppress = setup_suppress()
function pac.PostDrawOpaqueRenderables(bool1, bool2, ...)				
	if should_suppress() then return end
	
	--garbage = collectgarbage("count")
	
	-- commonly used variables		
	max_render_time = max_render_time_cvar:GetFloat()
	pac.RealTime = RealTime()
	pac.FrameNumber = FrameNumber()

	draw_dist = cvar_distance:GetInt()
	sv_draw_dist = GetConVarNumber("pac_sv_draw_distance")
	radius = 0
	
	if draw_dist == 0 then
		draw_dist = 32768
	end
	
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
				ent.IsPACWorldEntity or
				(ent == pac.LocalPlayer and ent:ShouldDrawLocalPlayer()) or
				
				ent ~= pac.LocalPlayer and 
				(					
					(util_PixelVisible(ent:EyePos(), radius, ent.pac_pixvis) ~= 0 or (dst < radius * 1.25)) and 
					(
						(sv_draw_dist ~= 0 and (sv_draw_dist == -1 or dst < sv_draw_dist)) or
						(ent.pac_draw_distance and (ent.pac_draw_distance <= 0 or ent.pac_draw_distance < dst)) or
						(dst < draw_dist)
					)
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
				hide_parts(ent)
			end
		else	
			pac.drawn_entities[key] = nil
		end
	end
	
	for key, data in pairs(pac.firstperson_parts) do
		if data.part:IsValid() and data.ent:IsValid() and data.part.ShowInFirstperson then
			if not data.ent:ShouldDrawLocalPlayer() then
				pac.RenderOverride(data.ent, "opaque")
			end
		else
			pac.firstperson_parts[key] = nil
			sortparts(pac.firstperson_parts)
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
	
	--collectgarbage("step", 512)
	--print(collectgarbage("count") - garbage)
	
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
	
	if pac.next_frame_funcs then
		for k, v in pairs(pac.next_frame_funcs) do
			v()
			pac.next_frame_funcs[k] = nil
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