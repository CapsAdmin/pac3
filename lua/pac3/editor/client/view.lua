local acsfnc = function(key, def)
	pace["View" .. key] = def
	pace["SetView" .. key] = function(val) pace["View" .. key] = val end
	pace["GetView" .. key] = function() return pace["View" .. key] or def end
end

acsfnc("Entity", NULL)
acsfnc("Pos", Vector(5,5,5))
acsfnc("Angles", Angle(0,0,0))
acsfnc("FOV", 75)

function pace.GetViewEntity()
	return pace.ViewEntity:IsValid() and pace.ViewEntity or LocalPlayer()
end

function pace.ResetView()
	if pace.Focused then
		local ent = pace.GetViewEntity()

		if not ent:IsValid() then
			local _, part = next(pac.GetParts(true))
			if part then
				ent = part:GetOwner()
			end
		end

		if ent:IsValid() then
			local fwd = ent.EyeAngles and ent:EyeAngles():Forward() or ent:GetAngles():Forward()
			fwd.z = 0
			pace.ViewPos = ent:EyePos() + fwd * 128
			pace.ViewAngles = (ent:EyePos() - pace.ViewPos):Angle()
			pace.ViewAngles:Normalize()
		end
	end
end

function pace.OnMouseWheeled(delta)
	local mult = 5

	if input.IsKeyDown(KEY_LCONTROL) then
		mult = 1
	end

	if input.IsKeyDown(KEY_LSHIFT) then
		mult = 10
	end

	delta = delta * mult

	pace.ViewFOV = math.Clamp(pace.ViewFOV - delta, 1, 75)
end

local held_ang = Angle(0,0,0)
local held_mpos = Vector(0,0,0)
local mcode
local hoveredPanelCursor

function pace.GUIMousePressed(mc)
	if pace.mctrl.GUIMousePressed(mc) then return end

	if mc == MOUSE_LEFT and not pace.editing_viewmodel then
		held_ang = pace.ViewAngles * 1
		held_mpos = Vector(gui.MousePos())
	end

	if mc == MOUSE_RIGHT then
		pace.Call("OpenMenu")
	end

	hoveredPanelCursor = vgui.GetHoveredPanel()

	if IsValid(hoveredPanelCursor) then
		hoveredPanelCursor:SetCursor('sizeall')
	end

	mcode = mc
end

function pace.GUIMouseReleased(mc)
	if IsValid(hoveredPanelCursor) then
		hoveredPanelCursor:SetCursor('none')
		hoveredPanelCursor = nil
	end

	if pace.mctrl.GUIMouseReleased(mc) then return end

	if pace.editing_viewmodel then return end

	mcode = nil
end

local function set_mouse_pos(x, y)
	gui.SetMousePos(x, y)
	held_ang = pace.ViewAngles * 1
	held_mpos = Vector(x, y)
	return held_mpos * 1
end

local WORLD_ORIGIN = Vector(0, 0, 0)

local function CalcDrag()
	if
		pace.BusyWithProperties:IsValid() or
		pace.ActiveSpecialPanel:IsValid() or
		pace.editing_viewmodel or
		pace.properties.search:HasFocus()
	then return end

	if not system.HasFocus() then
		held_mpos = Vector(gui.MousePos())
	end

	local ftime = FrameTime() * 50
	local mult = 5

	if input.IsKeyDown(KEY_LCONTROL) or input.IsKeyDown(KEY_RCONTROL) then
		mult = 0.1
	end

	if IsValid(pace.current_part) then
		local origin

		local owner = pace.current_part:GetOwner(true)

		if owner == pac.WorldEntity and owner:IsValid() then
			if pace.current_part:HasChildren() then
				for key, child in ipairs(pace.current_part:GetChildren()) do
					if not child.NonPhysical then
						origin = child:GetDrawPosition()
						if origin == WORLD_ORIGIN then origin = LocalPlayer():GetPos() end
						break
					end
				end
			else
				origin = LocalPlayer():GetPos()
			end

			if not origin then
				origin = LocalPlayer():GetPos()
			end
		else
			if not owner:IsValid() then
				owner = pac.LocalPlayer
			end

			if pace.current_part.NonPhysical then
				origin = owner:GetPos()
			else
				origin = pace.current_part:GetDrawPosition()
			end
		end

		mult = mult * math.min(origin:Distance(pace.ViewPos) / 200, 3)
	else
		mult = mult * math.min(LocalPlayer():GetPos():Distance(pace.ViewPos) / 200, 3)
	end

	if input.IsKeyDown(KEY_LSHIFT) then
		mult = mult + 5
	end

	if input.IsKeyDown(KEY_UP) or input.IsMouseDown(MOUSE_WHEEL_UP) then
		pace.OnMouseWheeled(0.25)
	elseif input.IsKeyDown(KEY_DOWN) or input.IsMouseDown(MOUSE_WHEEL_DOWN) then
		pace.OnMouseWheeled(-0.25)
	end

	if not pace.IsSelecting then
		if mcode == MOUSE_LEFT then
			local mpos = Vector(gui.MousePos())

			if mpos.x >= ScrW() - 1 then
				mpos = set_mouse_pos(1, gui.MouseY())
			elseif mpos.x < 1 then
				mpos = set_mouse_pos(ScrW() - 2, gui.MouseY())
			end

			if mpos.y >= ScrH() - 1 then
				mpos = set_mouse_pos(gui.MouseX(), 1)
			elseif mpos.y < 1 then
				mpos = set_mouse_pos(gui.MouseX(), ScrH() - 2)
			end

			local delta = (held_mpos - mpos) / 5 * math.rad(pace.ViewFOV)
			pace.ViewAngles.p = math.Clamp(held_ang.p - delta.y, -90, 90)
			pace.ViewAngles.y = held_ang.y + delta.x
		end
	end

	if input.IsKeyDown(KEY_W) then
		pace.ViewPos = pace.ViewPos + pace.ViewAngles:Forward() * mult * ftime
	elseif input.IsKeyDown(KEY_S) then
		pace.ViewPos = pace.ViewPos - pace.ViewAngles:Forward() * mult * ftime
	end

	if input.IsKeyDown(KEY_D) then
		pace.ViewPos = pace.ViewPos + pace.ViewAngles:Right() * mult * ftime
	elseif input.IsKeyDown(KEY_A) then
		pace.ViewPos = pace.ViewPos - pace.ViewAngles:Right() * mult * ftime
	end

	if input.IsKeyDown(KEY_SPACE) then
		pace.ViewPos = pace.ViewPos + pace.ViewAngles:Up() * mult * ftime
	end

	--[[if input.IsKeyDown(KEY_LALT) then
		pace.ViewPos = pace.ViewPos + pace.ViewAngles:Up() * -mult * ftime
	end]]
end

local follow_entity = CreateClientConVar("pac_camera_follow_entity", "0", true)
local lastEntityPos

function pace.CalcView(ply, pos, ang, fov)
	if pace.editing_viewmodel then
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

	local pos, ang, fov = pac.CallHook("EditorCalcView", pace.ViewPos, pace.ViewAngles, pace.ViewFOV)

	if pos then
		pace.ViewPos = pos
	end

	if ang then
		pace.ViewAngles = ang
	end

	if fov then
		pace.ViewFOV = fov
	end

	return
	{
		origin = pace.ViewPos,
		angles = pace.ViewAngles,
		fov = pace.ViewFOV,
	}
end

function pace.ShouldDrawLocalPlayer()
	if not pace.editing_viewmodel then
		return true
	end
end

function pace.EnableView(b)
	if b then
		pace.AddHook("GUIMousePressed")
		pace.AddHook("GUIMouseReleased")
		pace.AddHook("ShouldDrawLocalPlayer")
		pace.AddHook("CalcView")
		pace.AddHook("HUDPaint")
		pace.AddHook("HUDShouldDraw")
		pace.Focused = true
		pace.ResetView()
	else
		lastEntityPos = nil
		pace.RemoveHook("GUIMousePressed")
		pace.RemoveHook("GUIMouseReleased")
		pace.RemoveHook("ShouldDrawLocalPlayer")
		pace.RemoveHook("CalcView")
		pace.RemoveHook("HUDPaint")
		pace.RemoveHook("HUDShouldDraw")
		pace.SetTPose(false)
		pace.SetBreathing(false)
	end
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
	pace.SetViewEntity(part:GetOwner(true))

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
		(typ == "CHudCrosshair" and pace.editing_viewmodel)
	then
		return false
	end
end
