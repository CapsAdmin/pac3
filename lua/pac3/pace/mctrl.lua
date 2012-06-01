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
		if part:IsValid() and part.HideGizmo then
			mctrl.target = pac.NULL
		else
			mctrl.target = part
		end
	end

	function mctrl.GetTarget()
		return mctrl.target
	end

	function mctrl.GetAxes(ang)
		return ang:Forward(),
			ang:Right() *-1,
			ang:Up()
	end

	function mctrl.GetTargetPos()
		local part = mctrl.GetTarget()
		if part:IsValid() then
			return part:GetDrawPosition()
		end
	end

	function mctrl.GetBonePos()
		local part = mctrl.GetTarget()
		if part:IsValid() then
			return part:GetBonePosition()
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

	function mctrl.GetCameraAngles()
		return pace.GetViewAngles()
	end

	function mctrl.GetMousePos()
		return gui.MousePos()
	end

	function mctrl.VecToScreen(vec)
		local x,y,vis = pace.VectorToLPCameraScreen(
			(vec - mctrl.GetCameraOrigin()):Normalize(),
			ScrW(),
			ScrH(),
			mctrl.GetCameraAngles(),
			math.rad(pace.GetViewFOV())
		)
		return {x=x,y=y, visible = vis > 0}
	end

	function mctrl.ScreenToVec(x,y)
		local vec = pace.LPCameraScreenToVector(
			x,
			y,
			ScrW(),
			ScrH(),
			mctrl.GetCameraAngles(),
			math.rad(pace.GetViewFOV())
		)

		return vec
	end

	function mctrl.GetCalculatedScale()
		return 7 * math.rad(pace.GetViewFOV())
	end

	function mctrl.OnMove(part, pos)
		if input.IsKeyDown(KEY_LCONTROL) then
			pos.x = math.Round(pos.x/pace.GridSizePos) * pace.GridSizePos
			pos.y = math.Round(pos.y/pace.GridSizePos) * pace.GridSizePos
			pos.z = math.Round(pos.z/pace.GridSizePos) * pace.GridSizePos
		end
	
		pace.Call("VariableChanged", part, "Position", pos)
		timer.Create("pace_refresh_properties", 0.1, 1, function()
			pace.PopulateProperties(part)
		end)
	end

	function mctrl.OnRotate(part, ang)
		if input.IsKeyDown(KEY_LCONTROL) then
			ang.p = math.Round(ang.p/pace.GridSizeAng) * pace.GridSizeAng
			ang.y = math.Round(ang.y/pace.GridSizeAng) * pace.GridSizeAng
			ang.r = math.Round(ang.r/pace.GridSizeAng) * pace.GridSizeAng
		end
		
		pace.Call("VariableChanged", part, "Angles", ang)
		timer.Create("pace_refresh_properties", 0.1, 1, function()
			pace.PopulateProperties(part)
		end)
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

function mctrl.GUIMousePressed(mc)
	if mc == MOUSE_LEFT then
		local target = mctrl.GetTarget()
		if target:IsValid() then

			local x, y = mctrl.GetMousePos()
			local pos, ang = mctrl.GetTargetPos()
			if pos and ang then
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
					return true
				end
			end
		end
	end
end

function mctrl.GUIMouseReleased(mc)
	if mc == MOUSE_LEFT then
		mctrl.grab.mode = nil
		mctrl.grab.axis = nil
	end
end

function mctrl.LineToBox(origin, point, siz)
	siz = siz or 6
	surface.DrawLine(origin.x, origin.y, point.x, point.y)
	surface.DrawOutlinedRect(point.x - (siz * 0.5), point.y - (siz * 0.5), siz, siz)
end

function mctrl.RotationLines(pos, dir, dir2, r)
	local pr = mctrl.VecToScreen(pos + dir * r * mctrl.angle_pos)
	local pra = mctrl.VecToScreen(pos + dir * r * (mctrl.angle_pos * 0.9) + dir2*r*0.08)
	local prb = mctrl.VecToScreen(pos + dir * r * (mctrl.angle_pos * 0.9) + dir2*r*-0.08)
	surface.DrawLine(pr.x, pr.y, pra.x, pra.y)
	surface.DrawLine(pr.x, pr.y, prb.x, prb.y)
end

function mctrl.HUDPaint()
	local target = mctrl.GetTarget()
	if not target then return end

	local pos, ang = mctrl.GetTargetPos()
	if pos and ang then
		local forward, right, up = mctrl.GetAxes(ang)

		local r = mctrl.GetCalculatedScale()
		local o = mctrl.VecToScreen(pos)
		
		if o.visible then
			if mctrl.grab.axis == AXIS_X or mctrl.grab.axis == AXIS_VIEW then
				surface.SetDrawColor(255, 200, 0, 255)
			else
				surface.SetDrawColor(255, 80, 80, 255)
			end
			mctrl.LineToBox(o, mctrl.VecToScreen(pos + forward * r))
			--mctrl.LineToBox(o, mctrl.VecToScreen(pos + forward * r * mctrl.scale_pos), 8)
			mctrl.RotationLines(pos, forward, up, r)


			if mctrl.grab.axis == AXIS_Y or mctrl.grab.axis == AXIS_VIEW then
				surface.SetDrawColor(255, 200, 0, 255)
			else
				surface.SetDrawColor(80, 255, 80, 255)
			end
			mctrl.LineToBox(o, mctrl.VecToScreen(pos + right * r))
			--mctrl.LineToBox(o, mctrl.VecToScreen(pos + right * r * mctrl.scale_pos), 8)
			mctrl.RotationLines(pos, right, forward, r)

			if mctrl.grab.axis == AXIS_Z or mctrl.grab.axis == AXIS_VIEW then
				surface.SetDrawColor(255, 200, 0, 255)
			else
				surface.SetDrawColor(80, 80, 255, 255)
			end
			mctrl.LineToBox(o, mctrl.VecToScreen(pos + up * r))
			--mctrl.LineToBox(o, mctrl.VecToScreen(pos + up * r * mctrl.scale_pos), 8)
			mctrl.RotationLines(pos, up, right, r)

			surface.SetDrawColor(255, 200, 0, 255)
			surface.DrawOutlinedRect(o.x - 3, o.y - 3, 6, 6)
		end
	end
end

function mctrl.Think()
	local x, y = mctrl.GetMousePos()
	if mctrl.grab.axis and mctrl.grab.mode == MODE_MOVE then
		mctrl.Move(mctrl.grab.axis, x, y, mctrl.GetCalculatedScale())
	elseif mctrl.grab.axis and mctrl.grab.mode == MODE_SCALE then
		mctrl.Scale(mctrl.grab.axis, x, y, mctrl.GetCalculatedScale())
	elseif mctrl.grab.axis and mctrl.grab.mode == MODE_ROTATE then
		mctrl.Rotate(mctrl.grab.axis, x, y)
	end
end

hook.Add("Think", "pace_mctrl_Think", mctrl.Think)

pace.mctrl = mctrl