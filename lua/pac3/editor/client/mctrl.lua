pace.mctrl = {}
local mctrl = pace.mctrl

mctrl.AXIS_X = 1
mctrl.AXIS_Y = 2
mctrl.AXIS_Z = 3
mctrl.AXIS_VIEW = 4
mctrl.MODE_MOVE = 1
mctrl.MODE_ROTATE = 2
mctrl.MODE_SCALE = 3

local AXIS_X, AXIS_Y, AXIS_Z, AXIS_VIEW = mctrl.AXIS_X, mctrl.AXIS_Y, mctrl.AXIS_Z, mctrl.AXIS_VIEW
local MODE_MOVE, MODE_ROTATE, MODE_SCALE = mctrl.MODE_MOVE, mctrl.MODE_ROTATE, mctrl.MODE_SCALE

mctrl.radius_scale = 1.1
mctrl.grab_dist = 15
mctrl.angle_pos = 0.5
mctrl.scale_pos = 0.25

do -- pace
	mctrl.target = pac.NULL

	function mctrl.SetTarget(part)
		part = part or pac.NULL
		if not part:IsValid() then
			mctrl.target = pac.NULL
			return
		end

		if (part.NonPhysical and part.ClassName ~= 'group') or part.HideGizmo then
			mctrl.target = pac.NULL
		else
			mctrl.target = part
		end
	end

	function mctrl.GetTarget()
		return mctrl.target:IsValid() and not mctrl.target:IsHidden() and mctrl.target or pac.NULL
	end

	function mctrl.GetAxes(ang)
		return ang:Forward(),
			ang:Right() *-1,
			ang:Up()
	end

	function mctrl.GetTargetPos()
		local part = mctrl.GetTarget()

		if part:IsValid() then
			if part.ClassName ~= 'group' then
				return part:GetDrawPosition()
			elseif part.centrePos then
				return part.centrePos + part.centrePosMV, part.centreAngle
			else
				return part.centrePos, part.centreAngle
			end
		end
	end

	function mctrl.GetBonePos()
		local part = mctrl.GetTarget()

		if part:IsValid() then
			if part.ClassName ~= 'group' then
				return part:GetBonePosition()
			else
				return part.centrePos, Angle(0, 0, 0)
			end
		end
	end

	function mctrl.GetTargetPosition(pos, ang)
		local wpos, wang = mctrl.GetBonePos()
		if wpos and wang then
			return WorldToLocal(pos, ang, wpos, wang)
		end
	end

	function mctrl.GetCameraOrigin()
		return pace.GetViewPos()
	end

	function mctrl.GetCameraFOV()
		if pace.editing_viewmodel or pace.editing_hands then
			return LocalPlayer():GetActiveWeapon().ViewModelFOV or 55
		end

		return pace.GetViewFOV()
	end

	function mctrl.GetCameraAngles()
		return pace.GetViewAngles()
	end

	function mctrl.GetMousePos()
		return gui.MousePos()
	end

	function mctrl.VecToScreen(vec)
		local x,y,vis = pace.VectorToLPCameraScreen(
			(vec - EyePos()):GetNormalized(),
			ScrW(),
			ScrH(),
			EyeAngles(),
			math.rad(mctrl.GetCameraFOV())
		)
		return {x=x-1,y=y-1, visible = vis == 1}
	end

	function mctrl.ScreenToVec(x,y)
		local vec = pace.LPCameraScreenToVector(
			x,
			y,
			ScrW(),
			ScrH(),
			EyeAngles(),
			math.rad(mctrl.GetCameraFOV())
		)

		return vec
	end

	function mctrl.GetCalculatedScale()
		local part = pace.current_part

		if pace.editing_viewmodel or pace.editing_hands then
			return 5
		end

		if part.ClassName == "clip" then
			part = part.Parent
		end

		if part.ClassName == "camera" then
			return 30
		end

		if part.ClassName == "group" then
			return 45
		end

		if not part:IsValid() then return 3 end

		local dist = (part.cached_pos:Distance(pace.GetViewPos()) / 50)

		if dist > 1 then
			dist = 1 / dist
		end

		return 5 * math.rad(pace.GetViewFOV()) / dist
	end

	local cvar_pos_grid = CreateClientConVar("pac_grid_pos_size", "4")
	local groupOriginalValues

	function mctrl.OnMove(part, pos)
		if input.IsKeyDown(KEY_LCONTROL) then
			local num = cvar_pos_grid:GetInt("pac_grid_pos_size")
			pos.x = math.Round(pos.x/num) * num
			pos.y = math.Round(pos.y/num) * num
			pos.z = math.Round(pos.z/num) * num
		end

		if part.ClassName ~= 'group' then
			pace.Call("VariableChanged", part, "Position", pos, 0.25)

			timer.Create("pace_refresh_properties", 0.1, 1, function()
				pace.PopulateProperties(part)
			end)
		else
			local undo = {}
			local diffVector = part.centrePosMV - pos
			diffVector.y = -diffVector.y
			part.centrePosMV = pos
			diffVector:Rotate(Angle(-180, -pac.LocalPlayer:EyeAngles().y, 0))

			for i, child in ipairs(part:GetChildren()) do
				if child.GetAngles and child.GetPosition then
					if not groupOriginalValues then
						groupOriginalValues = {}

						for i, child in ipairs(part:GetChildren()) do
							if child.GetAngles and child.GetPosition then
								groupOriginalValues[i] = Vector(child:GetPosition())
							end
						end
					end

					-- too complex, putting comments
					-- getting part's bone position to use as one point of local coordinate system
					local bpos, bang = child:GetBonePosition()
					-- getting our groun calculated position
					local gpos, gang = mctrl.GetTargetPos()
					-- translating GROUP position to be relative to BONE's position
					local lbpos, lbang = WorldToLocal(gpos, gang, bpos, bang)
					-- now we have diff vector and angles between group position and part's bone position
					-- let's get relative position of our part to group
					local pos, ang = Vector(child:GetPosition()), Angle(child:GetAngles())
					local lpos, lang = WorldToLocal(pos, ang, lbpos, lbang)
					-- we finally got our position and angles! now rotate
					lpos = lpos + diffVector
					-- rotated, restore local positions to be relative to GROUP's LOCAL position (stack up)
					local fpos, fang = LocalToWorld(lpos, lang, lbpos, lbang)

					table.insert(undo, {
						child,
						Vector(groupOriginalValues[i]),
						Vector(fpos),
					})

					pace.Call("VariableChanged", child, "Position", fpos, false)
				end
			end

			if #undo ~= 0 then
				timer.Create('pac3_apply_undo_func', 0.25, 1, function()
					groupOriginalValues = nil
					pace.AddUndo(nil, function()
						for i, data in ipairs(undo) do
							pace.Call("VariableChanged", data[1], "Position", data[2], false)
						end
					end, function()
						for i, data in ipairs(undo) do
							pace.Call("VariableChanged", data[1], "Position", data[3], false)
						end
					end)
				end)
			end
		end
	end

	local cvar_ang_grid = CreateClientConVar("pac_grid_ang_size", "45")

	function mctrl.OnRotate(part, ang)
		if input.IsKeyDown(KEY_LCONTROL) then
			local num = cvar_ang_grid:GetInt("pac_grid_ang_size")
			ang.p = math.Round(ang.p/num) * num
			ang.y = math.Round(ang.y/num) * num
			ang.r = math.Round(ang.r/num) * num
		end

		if part.ClassName ~= 'group' then
			pace.Call("VariableChanged", part, "Angles", ang, 0.25)

			timer.Create("pace_refresh_properties", 0.1, 1, function()
				pace.PopulateProperties(part)
			end)
		else
			local undo = {}
			local diffAngle = part.centreAngle - ang
			part.centreAngle = ang

			for i, child in ipairs(part:GetChildren()) do
				if child.GetAngles and child.GetPosition then
					if not groupOriginalValues then
						groupOriginalValues = {}

						for i, child in ipairs(part:GetChildren()) do
							if child.GetAngles and child.GetPosition then
								groupOriginalValues[i] = {Vector(child:GetPosition()), Angle(child:GetAngles())}
							end
						end
					end

					-- too complex, putting comments
					-- getting part's bone position to use as one point of local coordinate system
					local bpos, bang = child:GetBonePosition()
					-- getting our groun calculated position
					local gpos, gang = mctrl.GetTargetPos()
					-- translating GROUP position to be relative to BONE's position
					local lbpos, lbang = WorldToLocal(gpos, gang, bpos, bang)
					-- now we have diff vector and angles between group position and part's bone position
					-- let's get relative position of our part to group
					local pos, ang = Vector(child:GetPosition()), Angle(child:GetAngles())
					local lpos, lang = WorldToLocal(pos, ang, lbpos, lbang)
					-- we finally got our position and angles! now rotate
					lpos:Rotate(-diffAngle)
					lang = lang + diffAngle
					-- rotated, restore local positions to be relative to GROUP's LOCAL position (stack up)
					local fpos, fang = LocalToWorld(lpos, lang, lbpos, lbang)

					table.insert(undo, {
						child,
						Angle(groupOriginalValues[i][2]),
						Vector(groupOriginalValues[i][1]),
						Angle(fang),
						Vector(fpos),
					})

					pace.Call("VariableChanged", child, "Angles", fang, false)
					pace.Call("VariableChanged", child, "Position", fpos, false)
				end
			end

			if #undo ~= 0 then
				timer.Create('pac3_apply_undo_func', 0.25, 1, function()
					groupOriginalValues = nil
					pace.AddUndo(nil, function()
						for i, data in ipairs(undo) do
							pace.Call("VariableChanged", data[1], "Angles", data[2], false)
							pace.Call("VariableChanged", data[1], "Position", data[3], false)
						end
					end, function()
						for i, data in ipairs(undo) do
							pace.Call("VariableChanged", data[1], "Angles", data[4], false)
							pace.Call("VariableChanged", data[1], "Position", data[5], false)
						end
					end)
				end)
			end
		end
	end

end

--
-- Math functions
--
local function dot(x1, y1, x2, y2)
	return (x1 * x2 + y1 * y2)
end

local function line_plane_intersection(p, n, lp, ln)
	local d = p:Dot(n)
	local t = d - lp:Dot(n) / ln:Dot(n)
	if t < 0 then return end
	return lp + ln * t
end

-- Mctrl functions

function mctrl.LinePlaneIntersection(pos, normal, x, y)
	return
		line_plane_intersection(
			Vector(0, 0, 0),
			normal,
			mctrl.GetCameraOrigin() - pos,
			mctrl.ScreenToVec(x, y)
		)
end

function mctrl.PointToAxis(pos, axis, x, y)
	local origin = mctrl.VecToScreen(pos)
	local point = mctrl.VecToScreen(pos + axis * 10)

	local a = math.atan2(point.y - origin.y, point.x - origin.x)
	local d = dot(math.cos(a), math.sin(a), point.x - x, point.y - y)

	return
		point.x + math.cos(a) * -d,
		point.y + math.sin(a) * -d
end

function mctrl.CalculateMovement(axis, x, y, offset)
	local target = mctrl.GetTarget()

	if target:IsValid() then
		local pos, ang = mctrl.GetTargetPos()

		if pos and ang then
			local forward, right, up = mctrl.GetAxes(ang)

			if axis == AXIS_X then
				local x, y = mctrl.PointToAxis(pos, forward, x, y)
				local localpos = mctrl.LinePlaneIntersection(pos, right, x, y)

				return localpos and (mctrl.GetTargetPosition(pos + localpos:Dot(forward)*forward - forward*offset, ang))
			elseif axis == AXIS_Y then
				local x, y = mctrl.PointToAxis(pos, right, x, y)
				local localpos = mctrl.LinePlaneIntersection(pos, forward, x, y)

				return localpos and (mctrl.GetTargetPosition(pos + localpos:Dot(right)*right - right*offset, ang))
			elseif axis == AXIS_Z then
				local x, y = mctrl.PointToAxis(pos, up, x, y)
				local localpos = mctrl.LinePlaneIntersection(pos, forward, x, y) or mctrl.LinePlaneIntersection(pos, right, x, y)

				return localpos and (mctrl.GetTargetPosition(pos + localpos:Dot(up)*up - up*offset, ang))
			elseif axis == AXIS_VIEW then
				local camnormal = mctrl.GetCameraAngles():Forward()
				local localpos = mctrl.LinePlaneIntersection(pos, camnormal, x, y)

				return localpos and (mctrl.GetTargetPosition(pos + localpos, ang))
			end
		end
	end
end

function mctrl.CalculateScale(axis, x, y, offset)
	local target = mctrl.GetTarget()
	if target:IsValid() then
		local pos, ang = mctrl.GetTargetPos()
		if pos and ang then
			local forward, right, up = mctrl.GetAxes(ang)
			offset = -offset + offset + (mctrl.scale_pos * mctrl.GetCalculatedScale())
			if axis == AXIS_X then
				local x, y = mctrl.PointToAxis(pos, forward, x, y)
				local localpos = mctrl.LinePlaneIntersection(pos, right, x, y)

				return localpos and (mctrl.GetTargetPosition(pos + localpos:Dot(forward)*forward - forward*offset, ang)), AXIS_X
			elseif axis == AXIS_Y then
				local x, y = mctrl.PointToAxis(pos, right, x, y)
				local localpos = mctrl.LinePlaneIntersection(pos, forward, x, y)

				return localpos and (mctrl.GetTargetPosition(pos + localpos:Dot(right)*right - right*offset, ang)), AXIS_Y
			elseif axis == AXIS_Z then
				local x, y = mctrl.PointToAxis(pos, up, x, y)
				local localpos = mctrl.LinePlaneIntersection(pos, forward, x, y) or mctrl.LinePlaneIntersection(pos, right, x, y)

				return localpos and (mctrl.GetTargetPosition(pos + localpos:Dot(up)*up - up*offset, ang)), AXIS_Z
			end
		end
	end
end

function mctrl.CalculateRotation(axis, x, y)
	local target = mctrl.GetTarget()
	if target:IsValid() then
		local pos, ang = mctrl.GetTargetPos()
		if pos and ang then
			local forward, right, up = mctrl.GetAxes(ang)

			if axis == AXIS_X then
				local localpos = mctrl.LinePlaneIntersection(pos, right, x, y)
				if localpos then
					local diffang = (pos - (localpos + pos)):Angle()
					diffang:RotateAroundAxis(right, 180)

					local _, localang = WorldToLocal(vector_origin, diffang, vector_origin, ang)
					local _, newang = LocalToWorld(vector_origin, Angle(math.NormalizeAngle(localang.p + localang.y), 0, 0), vector_origin, ang)

					return select(2, mctrl.GetTargetPosition(vector_origin, newang))
				end
			elseif axis == AXIS_Y then
				local localpos = mctrl.LinePlaneIntersection(pos, up, x, y)
				if localpos then
					local diffang = (pos - (localpos + pos)):Angle()
					diffang:RotateAroundAxis(up, 90)

					local _, localang = WorldToLocal(vector_origin, diffang, vector_origin, ang)
					local _, newang = LocalToWorld(vector_origin, Angle(0, math.NormalizeAngle(localang.p + localang.y), 0), vector_origin, ang)

					return select(2, mctrl.GetTargetPosition(vector_origin, newang))
				end
			elseif axis == AXIS_Z then
				local localpos = mctrl.LinePlaneIntersection(pos, forward, x, y)
				if localpos then
					local diffang = (pos - (localpos + pos)):Angle()
					diffang:RotateAroundAxis(forward, -90)

					local _, localang = WorldToLocal(vector_origin, diffang, vector_origin, ang)
					local _, newang = LocalToWorld(vector_origin, Angle(0, 0, math.NormalizeAngle(localang.p)), vector_origin, ang)

					return select(2, mctrl.GetTargetPosition(vector_origin, newang))
				end
			end
		end
	end
end

function mctrl.Move(axis, x, y, offset)
	local target = mctrl.GetTarget()

	if target:IsValid() then
		local pos = mctrl.CalculateMovement(axis, x, y, offset)

		if pos then
			mctrl.OnMove(target, pos)
		end
	end
end

function mctrl.Scale(axis, x, y, offset)
	local target = mctrl.GetTarget()
	if target:IsValid() then
		local scale, axis = mctrl.CalculateScale(axis, x, y, offset)
		if scale then
			mctrl.OnScale(target, scale, axis)
		end
	end
end

function mctrl.Rotate(axis, x, y)
	local target = mctrl.GetTarget()
	if target:IsValid() then
		local ang = mctrl.CalculateRotation(axis, x, y)
		if ang then
			mctrl.OnRotate(target, ang)
		end
	end
end

mctrl.grab = {mode = nil, axis = nil}

local GRAB_AND_CLONE = CreateClientConVar('pac_grab_clone', '1', true, false, 'Holding shift when moving or rotating a part creates its clone')

function mctrl.GUIMousePressed(mc)
	if mc ~= MOUSE_LEFT then return end
	local target = mctrl.GetTarget()
	if not target:IsValid() then return end
	local x, y = mctrl.GetMousePos()
	local pos, ang = mctrl.GetTargetPos()
	if not pos or not ang then return end
	local forward, right, up = mctrl.GetAxes(ang)
	local r = mctrl.GetCalculatedScale()

	-- Movement
	local axis
	local dist = mctrl.grab_dist

	for i, v in pairs
		{
			[AXIS_X] = mctrl.VecToScreen(pos + forward * r),
			[AXIS_Y] = mctrl.VecToScreen(pos + right * r),
			[AXIS_Z] = mctrl.VecToScreen(pos + up * r),
			[AXIS_VIEW] = mctrl.VecToScreen(pos)
		}
	do
		local d = math.sqrt((v.x - x)^2 + (v.y - y)^2)
		if d <= dist then
			axis = i
			dist = d
		end
	end

	if axis then
		mctrl.grab.mode = MODE_MOVE
		mctrl.grab.axis = axis

		if GRAB_AND_CLONE:GetBool() and input.IsShiftDown() then
			local copy = target:Clone()
			copy:SetParent(copy:GetParent())
			pace.AddUndoPartCreation(copy)
		end

		return true
	end

	--[[ Scale
	local axis
	local dist = mctrl.grab_dist

	for i, v in pairs
		{
			[AXIS_X] = mctrl.VecToScreen(pos + forward * r * mctrl.scale_pos),
			[AXIS_Y] = mctrl.VecToScreen(pos + right * r * mctrl.scale_pos),
			[AXIS_Z] = mctrl.VecToScreen(pos + up * r * mctrl.scale_pos)
		}
	do
		local d = math.sqrt((v.x - x)^2 + (v.y - y)^2)
		if d <= dist then
			axis = i
			dist = d
		end
	end

	if axis then
		mctrl.grab.mode = MODE_SCALE
		mctrl.grab.axis = axis
		return true
	end]]

	-- Rotation
	local axis
	local dist = mctrl.grab_dist
	for i, v in pairs
		{
			[AXIS_X] = mctrl.VecToScreen(pos + forward * r * mctrl.angle_pos),
			[AXIS_Y] = mctrl.VecToScreen(pos + right * r * mctrl.angle_pos),
			[AXIS_Z] = mctrl.VecToScreen(pos + up * r * mctrl.angle_pos)
		}
	do
		local d = math.sqrt((v.x - x)^2 + (v.y - y)^2)
		if d <= dist then
			axis = i
			dist = d
		end
	end

	if axis then
		mctrl.grab.mode = MODE_ROTATE
		mctrl.grab.axis = axis

		if GRAB_AND_CLONE:GetBool() and input.IsShiftDown() then
			local copy = target:Clone()
			copy:SetParent(copy:GetParent())
			pace.AddUndoPartCreation(copy)
		end

		return true
	end
end

function mctrl.GUIMouseReleased(mc)
	if mc == MOUSE_LEFT then
		mctrl.grab.mode = nil
		mctrl.grab.axis = nil
	end
end

local white = surface.GetTextureID("gui/center_gradient.vtf")

local function DrawLineEx(x1,y1, x2,y2, w, skip_tex)
	w = w or 1
	if not skip_tex then surface.SetTexture(white) end

	local dx,dy = x1-x2, y1-y2
	local ang = math.atan2(dx, dy)
	local dst = math.sqrt((dx * dx) + (dy * dy))

	x1 = x1 - dx * 0.5
	y1 = y1 - dy * 0.5

	surface.DrawTexturedRectRotated(x1, y1, w, dst, math.deg(ang))
end

local function DrawLine(x,y, a,b)
	DrawLineEx(x,y, a,b, 3)
end

local function DrawOutlinedRect(x,y, w,h)
	surface.DrawOutlinedRect(x,y, w,h)
	surface.DrawOutlinedRect(x+1,y+1, w-2,h-2)
end

local function DrawCircleEx(x, y, rad, res, ...)
	res = res or 16

	local spacing = (res/rad) - 0.1

	for i = 0, res do
		local i1 = ((i+0) / res) * math.pi * 2
		local i2 = ((i+1 + spacing) / res) * math.pi * 2

		DrawLineEx(
			x + math.sin(i1) * rad,
			y + math.cos(i1) * rad,

			x + math.sin(i2) * rad,
			y + math.cos(i2) * rad,
			...
		)
	end
end


function mctrl.LineToBox(origin, point, siz)
	siz = siz or 7
	DrawLine(origin.x, origin.y, point.x, point.y)
	DrawCircleEx(point.x, point.y, siz, 32, 2)
end

function mctrl.RotationLines(pos, dir, dir2, r)
	local pr = mctrl.VecToScreen(pos + dir * r * mctrl.angle_pos)
	local pra = mctrl.VecToScreen(pos + dir * r * (mctrl.angle_pos * 0.9) + dir2*r*0.08)
	local prb = mctrl.VecToScreen(pos + dir * r * (mctrl.angle_pos * 0.9) + dir2*r*-0.08)
	DrawLine(pr.x, pr.y, pra.x, pra.y)
	DrawLine(pr.x, pr.y, prb.x, prb.y)
end

function mctrl.HUDPaint()
	mctrl.LastThinkCall = FrameNumber()
	if pace.IsSelecting then return end

	local target = mctrl.GetTarget()
	if not target then return end

	local pos, ang = mctrl.GetTargetPos()
	if not pos or not ang then return end
	local forward, right, up = mctrl.GetAxes(ang)

	local radius = mctrl.GetCalculatedScale()
	local origin = mctrl.VecToScreen(pos)
	local forward_point = mctrl.VecToScreen(pos + forward * radius)
	local right_point = mctrl.VecToScreen(pos + right * radius)
	local up_point = mctrl.VecToScreen(pos + up * radius)

	if origin.visible or forward_point.visible or right_point.visible or up_point.visible then
		if mctrl.grab.axis == AXIS_X or mctrl.grab.axis == AXIS_VIEW then
			surface.SetDrawColor(255, 200, 0, 255)
		else
			surface.SetDrawColor(255, 80, 80, 255)
		end
		mctrl.LineToBox(origin, forward_point)
		--mctrl.LineToBox(o, mctrl.VecToScreen(pos + forward * r * mctrl.scale_pos), 8)
		mctrl.RotationLines(pos, forward, up, radius)


		if mctrl.grab.axis == AXIS_Y or mctrl.grab.axis == AXIS_VIEW then
			surface.SetDrawColor(255, 200, 0, 255)
		else
			surface.SetDrawColor(80, 255, 80, 255)
		end
		mctrl.LineToBox(origin, right_point)
		--mctrl.LineToBox(o, mctrl.VecToScreen(pos + right * r * mctrl.scale_pos), 8)
		mctrl.RotationLines(pos, right, forward, radius)

		if mctrl.grab.axis == AXIS_Z or mctrl.grab.axis == AXIS_VIEW then
			surface.SetDrawColor(255, 200, 0, 255)
		else
			surface.SetDrawColor(80, 80, 255, 255)
		end
		mctrl.LineToBox(origin, up_point)
		--mctrl.LineToBox(o, mctrl.VecToScreen(pos + up * r * mctrl.scale_pos), 8)
		mctrl.RotationLines(pos, up, right, radius)

		surface.SetDrawColor(255, 200, 0, 255)
		DrawCircleEx(origin.x, origin.y, 4, 32, 2)
	end
end

function mctrl.Think()
	if pace.IsSelecting then return end
	if not mctrl.target:IsValid() then return end
	
	local x, y = mctrl.GetMousePos()
	if mctrl.grab.axis and mctrl.grab.mode == MODE_MOVE then
		mctrl.Move(mctrl.grab.axis, x, y, mctrl.GetCalculatedScale())
	elseif mctrl.grab.axis and mctrl.grab.mode == MODE_SCALE then
		mctrl.Scale(mctrl.grab.axis, x, y, mctrl.GetCalculatedScale())
	elseif mctrl.grab.axis and mctrl.grab.mode == MODE_ROTATE then
		mctrl.Rotate(mctrl.grab.axis, x, y)
	end
end

pac.AddHook("Think", "pace_mctrl_Think", mctrl.Think)

pace.mctrl = mctrl
