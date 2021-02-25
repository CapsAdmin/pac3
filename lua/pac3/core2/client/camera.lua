local camera = {}

function camera.IntersectRayWithOBB(pos, ang, min, max)
	local view = camera.GetViewMatrix()

	local hit_pos, normal, fraction = util.IntersectRayWithOBB(
		view:GetTranslation(),
		view:GetForward() * 32000,
		pos,
		ang,
		min,
		max
	)

	if pac999.DEBUG then
		debugoverlay.BoxAngles(
			pos,
			min,
			max,
			ang,
			0,
			Color(255,0,0, a and 50 or 0), true
		)
	end

	return hit_pos, normal, fraction
end

function camera.GetViewRay()
	local mx,my = gui.MousePos()

	if not vgui.CursorVisible() then
		mx = ScrW()/2
		my = ScrH()/2
	end

	return gui.ScreenToVector(mx, my)
end

function camera.GetViewMatrix()
	local m = Matrix()

	m:SetAngles(camera.GetViewRay():Angle())
	m:SetTranslation(camera.eye_pos)

	return m
end

return camera