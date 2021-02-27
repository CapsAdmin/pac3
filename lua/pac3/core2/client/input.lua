local input = {}

function input.IsGrabbing()
	return _G.input.IsMouseDown(MOUSE_LEFT)
end

local function sort_by_camera_distance(a, b)
	return a.entity.bounding_box:GetCameraZSort() < b.entity.bounding_box:GetCameraZSort()
end

function input.Update()
	local inputs = {}

	for _, v in ipairs(pac999.entity.GetAllComponents("input")) do
		table.insert(inputs, v)
	end

	table.sort(inputs, sort_by_camera_distance)

	for i,v in ipairs(inputs) do
		if v.IgnoreZ then
			table.remove(inputs, i)
			table.insert(inputs, 1, v)
		end
	end

	if input.grabbed then
		local obj = input.grabbed
		if not input.IsGrabbing() then
			obj:SetPointerDown(false)
			input.grabbed = nil
		end

		obj:SetPointerOver(true)
		obj.entity:FireEvent("PointerHover")

		return
	end

	for _, obj in ipairs(inputs) do
		local hit_pos, normal, fraction = obj:CameraRayIntersect()

		for _, obj2 in ipairs(inputs) do
			if obj2 ~= obj then
				obj2:SetPointerOver(false)
			end
		end
		if hit_pos then

			--obj:FireEvent("MouseOver", hit_pos, normal, fraction)
			obj:SetHitPosition(hit_pos)
			obj:SetHitNormal(normal)
			obj:SetPointerOver(true)
			obj:SetPointerDown(input.IsGrabbing())
			obj.entity:FireEvent("PointerHover")

			if input.IsGrabbing() then
				input.grabbed = obj
			end

			break
		end
	end
end

pac999.camera.eye_pos = EyePos()
pac999.camera.eye_ang = EyeAngles()
pac999.camera.eye_fov = 90

function input.Init()
	pac999.AddHook("RenderScene", function(pos, ang, fov)
		pac999.camera.eye_pos = pos
		pac999.camera.eye_ang = ang
		pac999.camera.eye_fov = fov
		cam.PushModelMatrix(Matrix())
		pac999.input.Update()
		cam.PopModelMatrix()
	end)
end

return input