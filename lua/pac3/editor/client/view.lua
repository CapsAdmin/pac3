
local L = pace.LanguageString

local acsfnc = function(key, def)
	pace["View" .. key] = def
	pace["SetView" .. key] = function(val) pace["View" .. key] = val end
	pace["GetView" .. key] = function() return pace["View" .. key] or def end
end

acsfnc("Entity", NULL)
acsfnc("Pos", Vector(5,5,5))
acsfnc("Angles", Angle(0,0,0))
acsfnc("FOV", 75)

function pace.GoTo(obj, mode, extra, alt_move)
	if not obj then return end
	if mode == "view" and (obj.GetWorldPosition or isentity(obj)) then

		extra = extra or {radius = 75} --if no 3rd arg, assume a basic 75 distance
		extra.radius = extra.radius or 75 --if the table is wrong, force insert a default 75 distance
		if alt_move ~= nil then --repeated hits = reverse? or come back?
			if alt_move == true then
				extra.radius = -extra.radius
			elseif alt_move == false then
				
			end
		end
		local obj_pos
		local angfunc
		if obj.GetWorldPosition then
			obj_pos = obj:GetWorldPosition()
		elseif isentity(obj) then
			obj_pos = obj:GetPos() + obj:OBBCenter()
		end
		pace.ViewAngles = (pace.ViewPos - obj_pos):Angle()
		if extra.axis then
			local vec
			local sgn = extra.radius > 0 and 1 or -1
			if obj.GetWorldPosition then
				if extra.axis == "x" then
					vec = obj:GetWorldAngles():Forward()
				elseif extra.axis == "y" then
					vec = obj:GetWorldAngles():Right()
				elseif extra.axis == "z" then
					vec = obj:GetWorldAngles():Up()
				elseif extra.axis == "world_x" then
					vec = Vector(1,0,0)
				elseif extra.axis == "world_y" then
					vec = Vector(0,1,0)
				elseif extra.axis == "world_z" then
					vec = Vector(0,0,1)
				end
			elseif isentity(obj) then
				local ang = obj:GetAngles()
				ang.p = 0
				if extra.axis == "x" then
					vec = ang:Forward()
				elseif extra.axis == "y" then
					vec = ang:Right()
				elseif extra.axis == "z" then
					vec = ang:Up()
				elseif extra.axis == "world_x" then
					vec = Vector(1,0,0)
				elseif extra.axis == "world_y" then
					vec = Vector(0,1,0)
				elseif extra.axis == "world_z" then
					vec = Vector(0,0,1)
				end
			end
			vec = sgn * vec
			local viewpos = obj_pos - vec * math.abs(extra.radius)
			pace.ViewPos = viewpos
			pace.ViewAngles = (obj_pos - viewpos):Angle()
			pace.ViewAngles:Normalize()
			return
		end
		pace.ViewAngles:Normalize()
		pace.ViewPos = obj_pos + (obj_pos - pace.ViewPos):GetNormalized() * (extra.radius or 75)
	elseif mode == "treenode" and (obj.pace_tree_node or ispanel(obj)) then
		local part
		if obj.pace_tree_node then part = obj elseif ispanel(obj) then part = obj.part end
		local parent = part:GetParent()
		while IsValid(parent) and (parent:GetParent() ~= parent) do
			parent.pace_tree_node:SetExpanded(true)
			parent = parent:GetParent()
			if parent:IsValid() then
				parent.pace_tree_node:SetExpanded(true)
			end
		end
		if part.pace_tree_node then
			pace.tree:ScrollToChild(part.pace_tree_node)
		end
	elseif mode == "property" then
		pace.FlashProperty(obj, extra or "Name")
	end
end

pace.camera_forward_bind = CreateClientConVar("pac_editor_camera_forward_bind", "w", true)
pace.camera_back_bind = CreateClientConVar("pac_editor_camera_back_bind", "s", true)
pace.camera_moveleft_bind = CreateClientConVar("pac_editor_camera_moveleft_bind", "a", true)
pace.camera_moveright_bind = CreateClientConVar("pac_editor_camera_moveright_bind", "d", true)
pace.camera_up_bind = CreateClientConVar("pac_editor_camera_up_bind", "space", true)
pace.camera_down_bind = CreateClientConVar("pac_editor_camera_down_bind", "", true)
pace.camera_slow_bind = CreateClientConVar("pac_editor_camera_slow_bind", "ctrl", true)
pace.camera_speed_bind = CreateClientConVar("pac_editor_camera_speed_bind", "shift", true)

pace.max_fov = 100
pace.camera_roll_drag_bind = CreateClientConVar("pac_editor_camera_roll_bind", "", true)
pace.roll_snapping = CreateClientConVar("pac_camera_roll_snap", "0", true)

pace.camera_orthographic_cvar = CreateClientConVar("pac_camera_orthographic", "0", true)
pace.camera_orthographic = pace.camera_orthographic_cvar:GetBool()
pace.viewlock_mode = ""

function pace.OrthographicView(b)
	if b == nil then b = not pace.camera_orthographic end
	pace.camera_orthographic = b
	pace.camera_orthographic_cvar:SetBool(tobool(b or false))
	if pace.Editor and pace.Editor.zoomslider then
		if pace.camera_orthographic then
			timer.Simple(1, function() pace.FlashNotification("Switched to orthographic mode") end)
			pace.Editor.zoomslider:SetText("Ortho. Width")
			pace.Editor.zoomslider:SetValue(50)
			pace.Editor.ortho_nearz:Show()
			pace.Editor.ortho_farz:Show()
		else
			timer.Simple(1, function() pace.FlashNotification("Switched to normal FOV mode") end)
			pace.Editor.zoomslider:SetText("Camera FOV")
			pace.Editor.zoomslider:SetValue(75)
			pace.Editor.ortho_nearz:Hide()
			pace.Editor.ortho_farz:Hide()
		end
		pace.RefreshZoomBounds(pace.Editor.zoomslider)
	end
end

cvars.AddChangeCallback("pac_camera_orthographic", function(name, old, new)
	pace.OrthographicView(tobool(new))
end, "pac_update_ortho")

pace.camera_movement_binds = {
	["forward"] = pace.camera_forward_bind,
	["back"] = pace.camera_back_bind,
	["moveleft"] = pace.camera_moveleft_bind,
	["moveright"] = pace.camera_moveright_bind,
	["up"] = pace.camera_up_bind,
	["down"] = pace.camera_down_bind,
	["slow"] = pace.camera_slow_bind,
	["speed"] = pace.camera_speed_bind,
	["roll_drag"] = pace.camera_roll_drag_bind
}

function pace.GetViewEntity()
	return pace.ViewEntity:IsValid() and pace.ViewEntity or pac.LocalPlayer
end

function pace.ResetView()
	if pace.Focused then
		local ent = pace.GetViewEntity()

		if not ent:IsValid() then
			local _, part = next(pac.GetLocalParts())
			if part then
				ent = part:GetOwner()
			end
		end

		if ent:IsValid() then
			local fwd = ent.EyeAngles and ent:EyeAngles() or ent:GetAngles()

			-- Source Engine local angles fix
			if ent == pac.LocalPlayer and ent:GetVehicle():IsValid() then
				local ang = ent:GetVehicle():GetAngles()
				fwd = fwd + ang
			end

			fwd = fwd:Forward()
			fwd.z = 0
			pace.ViewPos = ent:EyePos() + fwd * 128
			pace.ViewAngles = (ent:EyePos() - pace.ViewPos):Angle()
			pace.ViewAngles:Normalize()
		end
	end
end

function pace.SetZoom(fov, smooth)
	if smooth then
		if pace.camera_orthographic then
			pace.ViewFOV = Lerp(FrameTime()*10, pace.ViewFOV, math.Clamp(fov,-10000,10000))
			return
		end
		pace.ViewFOV = Lerp(FrameTime()*10, pace.ViewFOV, math.Clamp(fov,1,pace.max_fov))
	else
		if pace.camera_orthographic then
			pace.ViewFOV = math.Clamp(fov,-10000,10000)
			return
		end
		pace.ViewFOV = math.Clamp(fov,1,pace.max_fov)
	end
end

function pace.ResetZoom()
	pace.zoom_reset = 75
end
 
local worldPanel = vgui.GetWorldPanel();
function worldPanel.OnMouseWheeled( self, scrollDelta )
	if IsValid(pace.Editor) then
		local zoom_usewheel = GetConVar( "pac_zoom_mousewheel" )

		if zoom_usewheel:GetInt() == 1 then
			local speed = 10

			if input.IsKeyDown(KEY_LSHIFT) then
				speed = 50
			end

			if input.IsKeyDown(KEY_LCONTROL) then
				speed = 1
			end

			if vgui.GetHoveredPanel() == worldPanel then
				pace.Editor.zoomslider:SetValue(pace.ViewFOV - (scrollDelta * speed))
			end
		end
	end
end

local held_ang = Angle(0,0,0)
local held_mpos = Vector(0,0,0)
local mcode, hoveredPanelCursor, isHoldingMovement

function pace.GUIMousePressed(mc)
	if pace.mctrl.GUIMousePressed(mc) then return end

	if mc == MOUSE_LEFT and not pace.editing_viewmodel then
		held_ang = pace.ViewAngles * 1
		held_ang:Normalize()
		held_mpos = Vector(input.GetCursorPos())
	end

	if mc == MOUSE_RIGHT then
		pace.Call("OpenMenu")
	end

	hoveredPanelCursor = vgui.GetHoveredPanel()

	if IsValid(hoveredPanelCursor) then
		hoveredPanelCursor:SetCursor('sizeall')
	end

	mcode = mc
	isHoldingMovement = true
end

function pace.GUIMouseReleased(mc)
	isHoldingMovement = false

	if IsValid(hoveredPanelCursor) then
		hoveredPanelCursor:SetCursor('arrow')
		hoveredPanelCursor = nil
	end

	if pace.mctrl.GUIMouseReleased(mc) then return end

	if pace.editing_viewmodel or pace.editing_hands then return end

	mcode = nil
end

local function set_mouse_pos(x, y)
	input.SetCursorPos(x, y)
	held_ang = pace.ViewAngles * 1
	held_mpos = Vector(x, y)
	return held_mpos * 1
end

local WORLD_ORIGIN = Vector(0, 0, 0)

local function MovementBindDown(name)
	return input.IsButtonDown(input.GetKeyCode(pace.camera_movement_binds[name]:GetString()))
end

local follow_entity_ang = CreateClientConVar("pac_camera_follow_entity_ang", "0", true)
local follow_entity_ang_side = CreateClientConVar("pac_camera_follow_entity_ang_use_side", "0", true)
local delta_y = 0
local previous_delta_y = 0


local rolling = false
local initial_roll = 0
local initial_roll_x = 0
local current_x = 0
local roll_x = 0
local start_x = 0
local previous_roll = 0
local roll_x_delta = 0
local roll_release_time = 0


local pitch_limit = 90
local function CalcDrag()
	if not pace.properties or not pace.properties.search then return end

	if
		pace.BusyWithProperties:IsValid() or
		(pace.ActiveSpecialPanel:IsValid() and not pace.ActiveSpecialPanel.ignore_saferemovespecialpanel) or
		pace.editing_viewmodel or
		pace.editing_hands or
		pace.properties.search:HasFocus()
	then return end

	local focus = vgui.GetKeyboardFocus()
	if focus and focus:IsValid() and focus:GetName():lower():find('textentry') then return end

	if not system.HasFocus() then
		held_mpos = Vector(input.GetCursorPos())
	end

	local ftime = FrameTime() * 50
	local mult = 5

	if MovementBindDown("slow") then
		mult = 0.1
	end

	local origin
	local part = pace.current_part or NULL

	if not part:IsValid() then return end

	local owner = part:GetRootPart():GetOwner()
	if not owner:IsValid() then
		owner = pac.LocalPlayer
	end

	origin = owner:GetPos()
	if owner == pac.WorldEntity then
		if part:HasChildren() then
			for key, child in ipairs(part:GetChildren()) do
				if child.GetDrawPosition then
					part = child
					break
				end
			end
		end
	end

	if part.GetDrawPosition then
		origin = part:GetDrawPosition()
	end

	if not origin or origin == WORLD_ORIGIN then
		origin = pac.LocalPlayer:GetPos()
	end

	mult = mult * math.min(origin:Distance(pace.ViewPos) / 200, 3)

	if MovementBindDown("speed") then
		mult = mult + 5
	end

	if MovementBindDown("roll_drag") then
		local current_x,current_y = input.GetCursorPos()
		if not rolling then
			start_x,_ = input.GetCursorPos()
			rolling = true
			initial_roll = previous_roll
		else
			local wrapping = false
			local x,_ = input.GetCursorPos()
			if x >= ScrW()-1 then
				input.SetCursorPos(2,current_y)
				current_x = 2
				start_x = start_x - ScrW() + 2
				wrapping = true
			end
			if x <= 1 then
				wrapping = true
				input.SetCursorPos(ScrW()-2,current_y)
				current_x = ScrW() - 2
				start_x = start_x + ScrW() - 2
				wrapping = true
			end

			local snap = pace.roll_snapping:GetFloat()
			roll_x_delta = x - start_x --current delta (modify)
			if not wrapping then
				pace.view_roll = (180 + math.Round(200 * (initial_roll + x - start_x) / ScrW(),2)) % 360 - 180
				pace.FlashNotification("view roll : " .. pace.view_roll .. " degrees (Ctrl to snap by " .. snap .. " degrees)")
			end

			if snap ~= 0 and input.IsButtonDown(KEY_LCONTROL) and pace.view_roll ~= nil then
				pace.view_roll = math.Round(pace.view_roll / snap,0) * snap
				pace.FlashNotification("view roll : " .. pace.view_roll .. " (snapped to nearest " .. snap .. " degrees)")
			end
			--will be applied post
		end
	elseif rolling then
		local x,_ = input.GetCursorPos()
		previous_roll = initial_roll + roll_x_delta
		if math.abs(start_x - x) < 5 then
			pace.FlashNotification("view roll reset")
			pace.view_roll = nil
			previous_roll = 0 initial_roll = 0 start_x = 0 roll_x_delta = 0
		end
		rolling = false
	end

	if not pace.IsSelecting then
		if mcode == MOUSE_LEFT then
			pace.dragging = true
			local mpos = Vector(input.GetCursorPos())

			if mpos.x >= ScrW() - 1 then
				mpos = set_mouse_pos(1, gui.MouseY())
			elseif mpos.x < 1 then
				mpos = set_mouse_pos(ScrW() - 2, gui.MouseY())
			end

			local overflows = false
			if mpos.y >= ScrH() - 1 then
				mpos = set_mouse_pos(gui.MouseX(), 1)
				overflows = 1
			elseif mpos.y < 1 then
				mpos = set_mouse_pos(gui.MouseX(), ScrH() - 2)
				overflows = -1
			end

			local delta = (held_mpos - mpos) / 5 * math.rad(pace.ViewFOV)
			pace.ViewAngles.p = math.Clamp(held_ang.p - delta.y, -pitch_limit, pitch_limit)
			pace.ViewAngles.y = held_ang.y + delta.x
			if pace.viewlock and pace.viewlock_mode == "zero pitch" then
				delta_y = (held_ang.p - delta.y)
				if (previous_delta_y ~= delta_y) and (not overflows) then
					pace.ViewPos = pace.ViewPos + Vector(0,0,delta_y - previous_delta_y) * pace.viewlock_distance / 300
				elseif overflows then
					pace.ViewPos = pace.ViewPos + Vector(0,0,overflows) * pace.viewlock_distance / 300
				end
				previous_delta_y = (held_ang.p - delta.y)
			end
		else
			previous_delta_y = 0
			delta_y = 0
			pace.dragging = false
		end
	end

	local viewlock_direct = (pace.viewlock and not pace.dragging) and (pace.viewlock_mode == "direct")
	if pace.delaymovement < RealTime() then
		if MovementBindDown("forward") then
			pace.ViewPos = pace.ViewPos + pace.ViewAngles:Forward() * mult * ftime
			if pace.viewlock or follow_entity_ang:GetBool() then
				pace.viewlock_distance = pace.viewlock_distance - mult * ftime
			end
		elseif MovementBindDown("back") then
			pace.ViewPos = pace.ViewPos - pace.ViewAngles:Forward() * mult * ftime
			if pace.viewlock or follow_entity_ang:GetBool()then
				pace.viewlock_distance = pace.viewlock_distance + mult * ftime
			end
		end

		if  MovementBindDown("moveright") then
			pace.ViewPos = pace.ViewPos + pace.ViewAngles:Right() * mult * ftime
		elseif  MovementBindDown("moveleft") then
			pace.ViewPos = pace.ViewPos - pace.ViewAngles:Right() * mult * ftime
		end

		if  MovementBindDown("up") then
			if not IsValid(pace.timeline.frame) then
				if viewlock_direct then
					local up = pace.ViewAngles:Up()
					mult = mult * up.z
				end
				pace.ViewPos = pace.ViewPos + pace.ViewAngles:Up() * mult * ftime
			end
		elseif  MovementBindDown("down") then
			if not IsValid(pace.timeline.frame) then
				if viewlock_direct then
					local up = pace.ViewAngles:Up()
					mult = mult * up.z
				end
				pace.ViewPos = pace.ViewPos - pace.ViewAngles:Up() * mult * ftime
			end
		end
		if viewlock_direct and pace.viewlock_mode ~= "frame of reference" then
			local distance = pace.viewlock_distance or 75
			pace.ViewAngles = (pace.viewlock_pos - pace.ViewPos):Angle()

			local newpos = pace.viewlock_pos - distance * pace.ViewAngles:Forward()
			pace.ViewPos = newpos
		end
	end

end

local follow_entity = CreateClientConVar("pac_camera_follow_entity", "0", true)
local enable_editor_view = CreateClientConVar("pac_enable_editor_view", "1", true)
cvars.AddChangeCallback("pac_enable_editor_view", function(name, old, new)
	if new == "1" then
		pace.EnableView(true)
	else
		pace.CameraPartSwapView()
		pac.RemoveHook("CalcView", "editor")
	end
end, "pace_update_editor_view")

local lastEntityPos
pace.view_reversed = 1
pace.viewlock_distance = 75

function pace.CalcView(ply, pos, ang, fov)
	if not pace.IsActive() then pace.EnableView(false) return end
	if pace.editing_viewmodel or pace.editing_hands then
		pace.ViewPos = pos
		pace.ViewAngles = ang
		pace.ViewFOV = fov
	return end

	if follow_entity:GetBool() then
		local ent = pace.GetViewEntity()
		local pos = ent:GetPos()
		lastEntityPos = lastEntityPos or pos
		pace.ViewPos = pace.ViewPos + pos - lastEntityPos
		lastEntityPos = pos
	else
		lastEntityPos = nil
	end

	if follow_entity_ang:GetBool() then
		local ent = pace.GetViewEntity()
		local ang = ent:GetAngles()
		if follow_entity_ang_side:GetBool() then ang = ang:Right():Angle() end
		local pos = ent:GetPos() + ent:OBBCenter()
		pace.viewlock = nil
		pace.viewlock_pos = pos
		pace.viewlock_pos_deltaZ = pace.viewlock_pos
		pace.viewlock_distance = pace.viewlock_distance or 75
		if pace.viewlock_distance > 10 then
			pace.ViewAngles = (pace.view_reversed * ang:Forward()):Angle()
			local newpos = pos - pace.viewlock_distance*pace.ViewAngles:Forward()
			pace.ViewPos = newpos
		else
			pace.view_reversed = -pace.view_reversed --this will flip between front-facing and back-facing
			pace.viewlock_distance = 75 --but for that to happen we need to move the imposed position forward
			pace.delaymovement = RealTime() + 0.5
			pace.ViewPos = pace.ViewPos + 75*pace.ViewAngles:Forward()
		end
	end

	local pos, ang, fov = pac.CallHook("EditorCalcView", pace.ViewPos, pace.ViewAngles, pace.ViewFOV)

	if pace.viewlock then
		local pitch = pace.ViewAngles.p
		local viewlock_pos
		if isvector(pace.viewlock) then
			viewlock_pos = pace.viewlock
		elseif isentity(pace.viewlock) then
			viewlock_pos = pace.viewlock:GetPos() + pace.viewlock:OBBCenter()
		elseif pace.viewlock.GetWorldPosition then
			viewlock_pos = pace.viewlock:GetWorldPosition()
		end

		pace.viewlock_pos = viewlock_pos
		ang = ang or pace.ViewAngles
		pos = pos or pace.ViewPos
		local deltaZ = Vector(0,0,pace.ViewPos.z - viewlock_pos.z)
		pace.viewlock_pos_deltaZ = pace.viewlock_pos + deltaZ
		

		if pace.viewlock_distance < 10 then
			pace.view_reversed = -pace.view_reversed --this will flip between front-facing and back-facing
			pace.viewlock_distance = 75 --but for that to happen we need to move the imposed position forward
			pos = pace.ViewPos - 75*pace.ViewAngles:Forward()
		end

		if pace.viewlock_mode == "free pitch" then
			pitch_limit = 90
			viewlock_pos = viewlock_pos + deltaZ
			local distance = pace.viewlock_distance or viewlock_pos:Distance(pace.ViewPos)
			if not pace.dragging then
				ang = (-pace.ViewPos + viewlock_pos):Angle()
				ang:Normalize()
				pos = viewlock_pos - pace.view_reversed * distance * ang:Forward()
			else
				ang = (-pace.ViewPos + viewlock_pos):Angle()
				ang:Normalize()
			end

			ang.p = pitch
		elseif pace.viewlock_mode == "zero pitch" then
			viewlock_pos = viewlock_pos + deltaZ
			local distance = pace.viewlock_distance or viewlock_pos:Distance(pace.ViewPos)
			if not pace.dragging then
				ang = (-pace.ViewPos + viewlock_pos):Angle()
				ang:Normalize()
				pos = viewlock_pos - pace.view_reversed * distance * ang:Forward()
			else
				ang = (-pace.ViewPos + viewlock_pos):Angle()
				ang:Normalize()
			end

			ang.p = 0
		elseif pace.viewlock_mode == "direct" then
			pitch_limit = 89.9
			local distance = pace.viewlock_distance or viewlock_pos:Distance(pace.ViewPos)
			local newpos
			if pace.dragging then
				newpos = viewlock_pos - distance * pace.ViewAngles:Forward()
				pos = newpos
				ang = (-newpos + pace.viewlock_pos):Angle()
				ang:Normalize()
				pace.ViewAngles = ang
			else
				newpos = viewlock_pos + pace.view_reversed * distance * pace.ViewAngles:Forward()
				ang = (-pace.ViewPos + newpos):Angle()
				ang:Normalize()
			end
		elseif pace.viewlock_mode == "frame of reference" then
			pitch_limit = 90
			viewlock_pos = viewlock_pos + deltaZ
			local distance = pace.viewlock_distance or viewlock_pos:Distance(pace.ViewPos)
			if pace.viewlock and pace.viewlock.GetDrawPosition then
				local _pos, _ang = pace.viewlock:GetDrawPosition()
				local mat = Matrix()
				mat:Rotate(_ang)
				if pace.viewlock_axis == "x" then
					--mat:Scale(Vector(-1,1,1))
				elseif pace.viewlock_axis == "y" then
					mat:Rotate(Angle(0,90,0))
				elseif pace.viewlock_axis == "z" then
					mat:Rotate(Angle(90,0,0))
				end
				mat:Scale(Vector(pace.view_reversed,1,1))
				ang = mat:GetAngles()
				ang.r = pace.view_reversed*ang.r
				pos = _pos - distance * ang:Forward()
			end
		elseif pace.viewlock_mode == "disable" then
			pitch_limit = 90
			pace.viewlock = nil
		end
		--we apply the reversion only once, so reset here
		if pace.view_reversed == -1 and (pace.viewlock_mode ~= "frame of reference") then
			pace.view_reversed = 1
		end
	else
		pitch_limit = 90
	end

	if pos then
		pace.ViewPos = pos
	end

	if ang then
		pace.ViewAngles = ang
	end

	if fov then
		pace.ViewFOV = fov
	end
	
	local viewang_final = Angle(pace.ViewAngles)

	if pace.view_roll then
		pace.ViewAngles_postRoll = Angle(viewang_final)
		pace.ViewAngles_postRoll:RotateAroundAxis(pace.ViewAngles:Forward(), pace.view_roll)
		viewang_final = pace.ViewAngles_postRoll
	end


	--[[
	local entpos = pace.GetViewEntity():WorldSpaceCenter()
	local diff = pace.ViewPos - entpos
	local MAX_CAMERA_DISTANCE = 300
	local backtrace = util.QuickTrace(entpos, diff*50000, ply)
	local final_dist = math.min(diff:Length(), MAX_CAMERA_DISTANCE, (backtrace.HitPos - entpos):Length() - 10)
	pace.ViewPos = entpos + diff:GetNormalized() * final_dist
	]]

	if not pace.camera_orthographic then
		return
		{
			origin = pace.ViewPos,
			angles = viewang_final,
			fov = pace.ViewFOV
		}
	else
		local orthoborder = pace.Editor.zoomslider:GetValue() / 1000
		return
		{
			origin = pace.ViewPos,
			angles = viewang_final,
			fov = pace.ViewFOV,
			ortho = {
				left = -orthoborder * ScrW(),
				right = orthoborder * ScrW(),
				top = -orthoborder * ScrH(),
				bottom = orthoborder * ScrH()
			},
			znear = pace.Editor.ortho_nearz:GetValue(),
			zfar = pace.Editor.ortho_farz:GetValue()
		}
	end
	
end

function pace.ShouldDrawLocalPlayer()
	if not pace.editing_viewmodel and not pace.editing_hands then
		return true
	end
end

local notifText
local notifDisplayTime, notifDisplayTimeFade = 0, 0

function pace.FlashNotification(text, timeToDisplay)
	timeToDisplay = timeToDisplay or math.Clamp(#text / 6, 1, 8)
	notifDisplayTime = RealTime() + timeToDisplay
	notifDisplayTimeFade = RealTime() + timeToDisplay * 1.1
	notifText = text
end

function pace.PostRenderVGUI()
	if not pace.mctrl then return end

	local time = RealTime()

	if notifDisplayTimeFade > time then
		if notifDisplayTime > time then
			surface.SetTextColor(color_white)
		else
			surface.SetTextColor(255, 255, 255, 255 * (notifDisplayTimeFade - RealTime()) / (notifDisplayTimeFade - notifDisplayTime))
		end

		surface.SetFont('Trebuchet18')
		local w = surface.GetTextSize(notifText)
		surface.SetTextPos(ScrW() / 2 - w / 2, 30)
		surface.DrawText(notifText)
	end

	if not isHoldingMovement then return end

	if pace.mctrl.LastThinkCall ~= FrameNumber() then
		surface.SetFont('Trebuchet18')
		surface.SetTextColor(color_white)
		local text = L'You are currently holding the camera, movement is disabled'
		local w = surface.GetTextSize(text)
		surface.SetTextPos(ScrW() / 2 - w / 2, 10)
		surface.DrawText(text)
	end
end

function pace.EnableView(b)
	if b then
		pac.AddHook("GUIMousePressed", "editor", pace.GUIMousePressed)
		pac.AddHook("GUIMouseReleased", "editor", pace.GUIMouseReleased)
		pac.AddHook("ShouldDrawLocalPlayer", "editor", pace.ShouldDrawLocalPlayer, DLib and -4 or ULib and -1 or nil)
		if enable_editor_view:GetBool() then
			pac.AddHook("CalcView", "editor", pace.CalcView, DLib and -4 or ULib and -1 or nil)
			pac.RemoveHook("CalcView", "camera_part")
			pac.active_camera = nil
		else
			if pac.HasRemainingCameraPart() then pace.CameraPartSwapView() end
			pac.RemoveHook("CalcView", "editor")
		end
		pac.AddHook("HUDPaint", "editor", pace.HUDPaint)
		pac.AddHook("HUDShouldDraw", "editor", pace.HUDShouldDraw)
		pac.AddHook("PostRenderVGUI", "editor", pace.PostRenderVGUI)
		pace.Focused = true
		pace.ResetView()
	else
		lastEntityPos = nil
		pac.RemoveHook("GUIMousePressed", "editor")
		pac.RemoveHook("GUIMouseReleased", "editor")
		pac.RemoveHook("ShouldDrawLocalPlayer", "editor")
		pac.RemoveHook("CalcView", "editor")
		pac.AddHook("CalcView", "camera_part", pac.HandleCameraPart)
		pac.RemoveHook("HUDPaint", "editor")
		pac.RemoveHook("HUDShouldDraw", "editor")
		pac.RemoveHook("PostRenderVGUI", "editor")
		pace.SetTPose(false)
	end
end

function pace.ManuallySelectCamera(obj, doselect)
	if obj and doselect then
		obj:CameraTakePriority(true)
		pace.CameraPartSwapView(true)
		pac.active_camera_manual = obj
	elseif not doselect then
		for i,v in pairs(pac.GetLocalParts()) do
			if v.ClassName == "camera" then
				if not v:IsHidden() and v ~= obj then
					v:CameraTakePriority(true)
					pace.CameraPartSwapView(true)
					pac.active_camera_manual = v
					return
				end
			end
		end
		pac.active_camera_manual = nil
	else
		for i,v in pairs(pac.GetLocalParts()) do
			if v.ClassName == "camera" then
				if not v:IsHidden() then
					v:CameraTakePriority(true)
					pace.CameraPartSwapView(true)
					pac.active_camera_manual = v
					return
				end
			end
		end
	end
end

function pace.CameraPartSwapView(force_pac_camera)
	local pac_camera_parts_should_override = not enable_editor_view:GetBool() or not pace.Editor:IsValid() or pac.HasRemainingCameraPart()

	if pace.Editor:IsValid() and enable_editor_view:GetBool() and not force_pac_camera then pac_camera_parts_should_override = false end

	if pac.HandleCameraPart() == nil then --no cameras
		if not pace.ShouldDrawLocalPlayer() then
			pace.EnableView(false)
		end
		pac.RemoveHook("CalcView", "camera_part")
	elseif pac_camera_parts_should_override then --cameras
		pac.AddHook("CalcView", "camera_part", pac.HandleCameraPart)
		pac.RemoveHook("CalcView", "editor")
	else
		pace.EnableView(enable_editor_view:GetBool())
		--[[if not GetConVar("pac_copilot_force_preview_cameras"):GetBool() then
			
		else
			pace.EnableView(false)
		end]]
	end


	return pac.active_camera
end

local function CalcAnimationFix(ent)
	if ent.SetEyeAngles then
		ent:SetEyeAngles(Angle(0,0,0))
	end
end

local reset_pose_params =
{
	"body_rot_z",
	"spine_rot_z",
	"head_rot_z",
	"head_rot_y",
	"head_rot_x",
	"walking",
	"running",
	"swimming",
	"rhand",
	"lhand",
	"rfoot",
	"lfoot",
	"move_yaw",
	"aim_yaw",
	"aim_pitch",
	"breathing",
	"vertical_velocity",
	"vehicle_steer",
	"body_yaw",
	"spine_yaw",
	"head_yaw",
	"head_pitch",
	"head_roll",
}

function pace.GetTPose()
	return pace.tposed
end

function pace.SetViewPart(part, reset_campos)
	pace.SetViewEntity(part:GetRootPart():GetOwner())

	if reset_campos then
		pace.ResetView()
	end
end

function pace.HUDPaint()
	if mcode and not input.IsMouseDown(mcode) then
		mcode = nil
	end

	local ent = pace.GetViewEntity()

	if pace.IsFocused() then
		CalcDrag()

		if ent:IsValid() then
			pace.Call("Draw", ScrW(), ScrH())
		end
	end
end

function pace.HUDShouldDraw(typ)
	if
		typ == "CHudEPOE" or
		(typ == "CHudCrosshair" and (pace.editing_viewmodel or pace.editing_hands))
	then
		return false
	end
end

function pace.OnToggleFocus(show_editor)
	if pace.Focused then
		pace.KillFocus(show_editor)
	else
		pace.GainFocus(show_editor)
	end
end

function pace.SetTPose(b)
	local ply = pac.LocalPlayer

	if b then
		ply.pace_tpose_last_sequence = ply:GetSequence()
		ply.pace_tpose_last_layer_sequence = {}
		for i = 0, 16 do
			ply.pace_tpose_last_layer_sequence[i] = ply:GetLayerSequence(i)
		end

		local function reset_angles(ply)
			local ang = ply:EyeAngles()
			ang.p = 0
			ply:SetEyeAngles(ang)
			ply:SetRenderAngles(ang)
			ply:SetAngles(ang)
		end

		local function get_ref_anim(ply)
			local id = ply:LookupSequence("reference")
			local id2 = ply:LookupSequence("ragdoll")
			return id ~= -1 and id or id2 ~= -1 and id2 or 0
		end

		pac.AddHook("PrePlayerDraw", "pace_tpose", function(ply)
			if ply ~= pac.LocalPlayer then return end

			for i = 0, 16 do
				ply:SetLayerSequence(i, 0)
			end

			ply:SetSequence(get_ref_anim(ply))
			reset_angles(ply)
		end)

		pac.AddHook("UpdateAnimation", "pace_tpose", function()
			local ply = pac.LocalPlayer
			ply:ClearPoseParameters()
			reset_angles(ply)

			for i = 0, ply:GetNumPoseParameters() - 1 do
				local name = ply:GetPoseParameterName(i)
				if name then
					ply:SetPoseParameter(name, 0)
				end
			end
		end)

		pac.AddHook("CalcMainActivity", "pace_tpose", function(ply)
			if ply == pac.LocalPlayer then
				for i = 0, 16 do
					ply:SetLayerSequence(i, 0)
				end

				local act = get_ref_anim(ply)

				return act, act
			end
		end)
	else
		pac.RemoveHook("PrePlayerDraw", "pace_tpose")
		pac.RemoveHook("UpdateAnimation", "pace_tpose")
		pac.RemoveHook("CalcMainActivity", "pace_tpose")

		if ply.pace_tpose_last_sequence then
			ply:SetSequence(ply.pace_tpose_last_sequence)
			ply.pace_tpose_last_sequence = nil
		end

		if ply.pace_tpose_last_layer_sequence then
			for i, seq in ipairs(ply.pace_tpose_last_layer_sequence) do
				ply:SetLayerSequence(i, seq)
			end

			ply.pace_tpose_last_layer_sequence = nil
		end
	end

	pace.tposed = b
end

pace.SetTPose(pace.tposed)

function pace.ToggleCameraFollow()
	local c = GetConVar("pac_camera_follow_entity")
	RunConsoleCommand("pac_camera_follow_entity", c:GetBool() and "0" or "1")
end

function pace.GetBreathing()
	return pace.breathing
end
function pace.ResetEyeAngles(pitch_only)
	local ent = pace.GetViewEntity()
	if ent:IsValid() then
		if ent:IsPlayer() then

			RunConsoleCommand("+forward")
			timer.Simple(0, function()
				RunConsoleCommand("-forward")
				timer.Simple(0.1, function()
					RunConsoleCommand("+back")
					timer.Simple(0.015, function()
						RunConsoleCommand("-back")
					end)
				end)
			end)

			if not pitch_only then
				ent:SetEyeAngles(Angle(0, 0, 0))
			else
				local ang = ent:EyeAngles()
				ang.p = 0
				ent:SetEyeAngles(ang)
			end
		else
			ent:SetAngles(Angle(0, 0, 0))
		end

		pac.SetupBones(ent)
	end
end

function pace.PopupMiniFOVSlider()
	zoom_persistent = GetConVar("pac_zoom_persistent")
	zoom_smooth = GetConVar("pac_zoom_smooth")
	local zoomframe = vgui.Create( "DPanel" )
	local x,y = input.GetCursorPos()
	zoomframe:SetPos(x - 90,y - 10)
	zoomframe:SetSize( 180, 20 )

	zoomframe.zoomslider = vgui.Create("DNumSlider", zoomframe)
	zoomframe.zoomslider:DockPadding(4,0,0,0)
	zoomframe.zoomslider:SetSize(200, 20)
	zoomframe.zoomslider:SetDecimals( 0 )
	zoomframe.zoomslider:SetText("Camera FOV")
	if pace.camera_orthographic then
		zoomframe.zoomslider:SetText("Ortho. Width")
	end
	pace.RefreshZoomBounds(zoomframe.zoomslider)
	zoomframe.zoomslider:SetDark(true)
	zoomframe.zoomslider:SetDefaultValue( 75 )

	zoomframe.zoomslider:SetValue( pace.ViewFOV )

	function zoomframe:Think(...)
		pace.ViewFOV = zoomframe.zoomslider:GetValue()
		if zoom_smooth:GetInt() == 1 then
			pace.SetZoom(zoomframe.zoomslider:GetValue(),true)
		else
			pace.SetZoom(zoomframe.zoomslider:GetValue(),false)
		end
	end

	local hook_id = "pac_tools_menu"..util.SHA256(tostring(zoomframe))

	pac.AddHook("VGUIMousePressed", hook_id, function(pnl, code)
		pace.OverridingFOVSlider = true --to link the values with the original panel in the pac editor panel
		if not IsValid(zoomframe) then
			pac.RemoveHook("VGUIMousePressed", hook_id)
			return
		end
		if code == MOUSE_LEFT or code == MOUSE_RIGHT then
			if not zoomframe:IsOurChild(pnl) then
				if zoomframe.zoomslider then zoomframe.zoomslider:Remove() end
				zoomframe:Remove()
				pac.RemoveHook("VGUIMousePressed", hook_id)
				pace.OverridingFOVSlider = false
			end
		end
	end)

end
