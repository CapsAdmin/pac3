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

function pac.GetProfilingData(ent)	
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
	if ent.pac_parts and ent.pac_drawing then
		for key, part in pairs(ent.pac_parts) do
			part:CallRecursive("OnHide", true)
			part:SetKeyValueRecursive("last_hidden", nil)
			part:SetKeyValueRecursive("shown_from_rendering", false)
			part:SetKeyValueRecursive("draw_hidden", true)
		end
		
		pac.ResetBones(ent)		
		ent.pac_drawing = false
	end
end

local function show_parts(ent)
	if ent.pac_parts and (not ent.pac_drawing) and (not ent.shouldnotdraw) and (not ent.pacignored) then
		for key, part in pairs(ent.pac_parts) do
			part:CallRecursive("OnHide")
			part:SetKeyValueRecursive("last_hidden", nil)
			part:SetKeyValueRecursive("shown_from_rendering", true)
			part:SetKeyValueRecursive("draw_hidden", false)
		end
		
		pac.ResetBones(ent)
		ent.pac_drawing = true
	end
end

local function toggle_drawing_parts(ent, b)
	if b then
		ent.pac_drawing = false
		show_parts(ent)
		ent.shouldnotdraw = false
	else
		ent.pac_drawing = true
		hide_parts(ent)
		ent.shouldnotdraw = true
	end
end

pac.HideEntityParts = hide_parts
pac.ShowEntityParts = show_parts
pac.TogglePartDrawing = toggle_drawing_parts

local function render_override(ent, type, draw_only)
	
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

pac.Errors = {}

function pac.RenderOverride(ent, type, draw_only)
	local ok, err = pcall(render_override, ent, type, draw_only)
	if not ok then
		print("pac3 failed to render ", tostring(ent), ":")
		print(err)
		
		if ent == pac.LocalPlayer then
			chat.AddText("your pac3 outfit failed to render!")
			chat.AddText(err)
			chat.AddText("hiding your outfit to prevent further errors")
		end
		
		ent.pac_error = err
		table.insert(pac.Errors, err)
		hide_parts(ent)
	else
		ent.pac_error = nil
	end
end

pac.firstperson_parts = pac.firstperson_parts or {}

function pac.HookEntityRender(ent, part)		
	if not ent.pac_parts then
		ent.pac_parts = {}
	end
	
	if ent.pac_parts[part] then
		return 
	end
	
	pac.dprint("hooking render on %s to draw part %s", tostring(ent), tostring(part))
	
	ent.pac_parts[part] = part
	pac.drawn_entities[ent:EntIndex()] = ent	
	pac.profile_info[ent:EntIndex()] = nil	
end

function pac.UnhookEntityRender(ent, part)

	if part and ent.pac_parts then
		ent.pac_parts[part] = nil
	end
	
	if ent.pac_parts and not next(ent.pac_parts) then
		pac.drawn_entities[ent:EntIndex()] = nil
		ent.pac_parts = nil
	end
	
	pac.profile_info[ent:EntIndex()] = nil
end

function pac.IgnorePlayer(ply)
	toggle_drawing_parts(ply, false)
	ply.pacignored = true
end

function pac.UnIgnorePlayer(ply)
	toggle_drawing_parts(ply, true)
	ply.pacignored = false
end

local util_PixelVisible = util.PixelVisible
local cvar_distance = CreateClientConVar("pac_draw_distance", "500")
local cvar_fovoverride = CreateClientConVar("pac_override_fov", "0")

pac.EyePos = vector_origin
function pac.RenderScene(pos, ang)
	pac.EyePos = pos
	pac.EyeAng = ang
end
pac.AddHook("RenderScene")

function pac.PostPlayerDraw(ply)
	ply.pac_last_drawn = pac.RealTime
end
pac.AddHook("PostPlayerDraw")

-- hacky optimization
-- allows only the last draw call
local cvar_framesuppress = CreateClientConVar("pac_suppress_frames", 1, false, false)
RunConsoleCommand("pac_suppress_frames", "1") -- this should almost never be off..

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
	fovoverride = cvar_fovoverride:GetInt()
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
				draw_dist == -1 or
				ent.IsPACWorldEntity or
				(ent == pac.LocalPlayer and ent:ShouldDrawLocalPlayer() or (ent.pac_camera and ent.pac_camera:IsValid())) or
				ent ~= pac.LocalPlayer and 
				(					
					((util_PixelVisible(ent:EyePos(), radius, ent.pac_pixvis) ~= 0 or fovoverride ~= 0) or (dst < radius * 1.25)) and 
					(
						(sv_draw_dist ~= 0 and (sv_draw_dist == -1 or dst < sv_draw_dist)) or
						(ent.pac_draw_distance and (ent.pac_draw_distance <= 0 or ent.pac_draw_distance < dst)) or
						(dst < draw_dist)
					)
				)
			then 
				ent.pac_model = ent:GetModel() -- used for cached functions
					
				show_parts(ent)
				
				pac.RenderOverride(ent, "opaque")
			else
				hide_parts(ent)
			end
		else	
			pac.drawn_entities[key] = nil
		end
	end
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

function pac.Think()	
	for key, ent in pairs(pac.drawn_entities) do
		if ent:IsValid() then
			if ent.pac_drawing and ent:IsPlayer() then
			
				ent.pac_traceres = util.QuickTrace(ent:EyePos(), ent:GetAimVector()*32000, {ent, ent:GetVehicle(), ent:GetOwner()})
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