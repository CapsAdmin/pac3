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
	return pace.ViewEntity or LocalPlayer()
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
			pace.ViewPos = ent:EyePos() + Vector(50, 0, 0)
			pace.ViewAngles = (ent:EyePos() - pace.ViewPos):Angle()
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

function pac.GUIMousePressed(mc)
	if pace.mctrl.GUIMousePressed(mc) then return end

	if mc == MOUSE_LEFT then
		held_ang = pace.ViewAngles*1
		held_mpos = Vector(gui.MousePos())
	end

	if mc == MOUSE_RIGHT then
		pace.Call("OpenMenu")
	end

	mcode = mc
end

function pac.GUIMouseReleased(mc)
	if pace.mctrl.GUIMouseReleased(mc) then return end
	
	mcode = nil
end

local function CalcDrag()
	if pace.BusyWithProperties then return end
	
	local ftime = FrameTime() * 50
	local mult = 1
	
	if input.IsKeyDown(KEY_LCONTROL) then
		mult = 0.1
	end

	if input.IsKeyDown(KEY_LSHIFT) then
		mult = 5
	end
	
	if input.IsKeyDown(KEY_UP) then
		pace.OnMouseWheeled(0.25)
	elseif input.IsKeyDown(KEY_DOWN) then
		pace.OnMouseWheeled(-0.25)
	end
		
	if mcode == MOUSE_LEFT then
		local delta = (held_mpos - Vector(gui.MousePos())) / 5 * math.rad(pace.ViewFOV)
		pace.ViewAngles.p = math.Clamp(held_ang.p - delta.y, -90, 90)
		pace.ViewAngles.y = held_ang.y + delta.x
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
	
	if input.IsKeyDown(KEY_LALT) then
		pace.ViewPos = pace.ViewPos + pace.ViewAngles:Up() * -mult * ftime
	end
end

function pac.CalcView()
	if pace.editing_viewmodel then
		local ent = LocalPlayer():GetViewModel()
		if ent:IsValid() then
			ent:SetPos(pace.ViewPos)
			ent:SetAngles(pace.ViewAngles)
			ent:SetRenderOrigin(pace.ViewPos)
			ent:SetRenderAngles(pace.ViewAngles)
			ent:SetupBones()
		end
	end
	return
	{
		origin = pace.ViewPos,
		angles = pace.ViewAngles,
		fov =  pace.editing_viewmodel and pace.ViewFOV + 10 or pace.ViewFOV,
	}
end

function pac.ShouldDrawLocalPlayer()
	if pace.editing_viewmodel then
	return end
	return true
end

function pace.EnableView(b)
	if b then
		pac.AddHook("GUIMousePressed")
		pac.AddHook("GUIMouseReleased")
		pac.AddHook("ShouldDrawLocalPlayer")
		pac.AddHook("CalcView")
		pac.AddHook("HUDPaint")
		pace.Focused = true
		pace.ResetView()
	else
		pac.RemoveHook("GUIMousePressed")
		pac.RemoveHook("GUIMouseReleased")
		pac.RemoveHook("ShouldDrawLocalPlayer")
		pac.RemoveHook("CalcView")
		pac.RemoveHook("HUDPaint")
		pace.SetTPose(false)
		pace.SetBreathing(false)
		
		local ent = LocalPlayer():GetViewModel()
		if ent:IsValid() then
			ent:SetRenderOrigin(nil)
			ent:SetRenderAngles(nil)
			ent:SetupBones()
		end
	end
end

local function CalcAnimationFix(ent)
	if ent.SetEyeAngles then
		ent:SetEyeAngles(Angle(0,0,0))
		ent:SetupBones()
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

function pace.SetTPose(b)
	if b then
		pac.AddHook("CalcMainActivity", function(ply) 
			if ply == LocalPlayer() then
				return 
					ply:LookupSequence("ragdoll"), 
					ply:LookupSequence("ragdoll") 
			end
		end)
	else
		pac.RemoveHook("CalcMainActivity")
	end
	
	pace.tposed = b
end

function pace.SetBreathing(b)
	if b then
		pac.AddHook("UpdateAnimation", function(ply) 
			if ply == LocalPlayer() then
				for k,v in pairs(reset_pose_params) do 
					ply:SetPoseParameter(v, 0) 
				end 
				ply:ClearPoseParameters()
			end
		end)
	else
		pac.RemoveHook("UpdateAnimation")
	end
	
	pace.breathing = b
end

function pace.GetBreathing()
	return pace.breathing
end

function pac.HUDPaint()
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