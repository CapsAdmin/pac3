local utility = pac999.utility

local white_mat = CreateMaterial("pac999_white_" .. math.random(), "VertexLitGeneric", {

	["$bumpmap"] = "effects/flat_normal",
	--["$halflambert"] = 1,

	["$phong"] = "1",
	["$phongboost"] = "0.01" ,
	["$phongfresnelranges"] = "[2 5 10]",
	["$phongexponent"] = "0.5",


	["$basetexture"] = "color/white",
	--["$model"] = "1",
	["$nocull"] = "1",
	--["$translucent"] = "0",
	--["$vertexcolor"] = "1",
	--["$vertexalpha"] = "1",
})

local RED = Color(255, 80, 80)
local GREEN = Color(80, 255, 80)
local BLUE = Color(80,80,255)
local YELLOW = Color(255,255,80)

local BUILDER, META = pac999.entity.ComponentTemplate("gizmo")

local function create_grab(self, mdl, pos, on_grab, on_grab2)
	local ent = pac999.scene.AddNode(self.entity)
	ent:SetIgnoreZ(true)
	ent:RemoveComponent("gizmo")
	ent:SetModel(mdl)
	ent:SetPosition( pos)
	ent:SetMaterial(white_mat)
	ent:SetAlpha(1)
	ent:SetIgnoreParentScale(true)
	ent:AddEvent("Update", function()
		ent:SetWorldPosition(self.entity:GetWorldCenter())
		ent:SetPosition(pos)
	end)

	if on_grab then
		ent:AddEvent("Pointer", function(component, hovered, grabbed)
			if grabbed then
				local cb = on_grab(ent)
				if cb then
					ent:AddEvent("Update", cb, ent)
				end
			else
				ent:RemoveEvent("Update", ent)
			end
			if on_grab2 then
				on_grab2(ent, grabbed)
			end
		end)
	end

	table.insert(self.grab_entities, ent)

	return ent
end

function META:Start()
	self.grab_entities = {}
end

local dist = 70
local thickness = 0.5

function META:SetupViewTranslation()
	local ent = create_grab(
		self,
		"models/XQM/Rails/gumball_1.mdl",
		Vector(0,0,0),
		function()
			local m = pac999.camera.GetViewMatrix():GetInverse() * self.entity.transform:GetMatrix()

			return function()
				self.entity.transform:SetWorldMatrix(pac999.camera.GetViewMatrix() * m)
			end
		end
	)

	ent:SetColor(YELLOW)
	ent:SetLocalScale(Vector(1,1,1)*0.5)

	ent:AddEvent("Update", function()
		ent:SetWorldPosition(self.entity:GetWorldCenter())
	end)
end

function META:StartGrab(axis, center)

	self.grab_matrix = self.entity.transform:GetMatrix() * Matrix()
	center = center or self.grab_matrix:GetTranslation()
	self.old_scale = self.grab_matrix:GetScale()
	self.grab_matrix:SetScale(Vector(1,1,1))
	self.grab_transform = self.entity.transform:GetTRMatrix() * Matrix()
	self.grab_translation = self.grab_transform:GetTranslation()


	self.center_pos = util.IntersectRayWithPlane(
		pac999.camera.GetViewMatrix():GetTranslation(),
		pac999.camera.GetViewRay(),
		center,
		self.grab_matrix[axis](self.grab_matrix)
	)

	if not self.center_pos then return end

	return self.grab_matrix, self.center_pos
end

function META:GetGrabPlanePosition(axis, center)
	center = center or self.grab_matrix:GetTranslation()

	local plane_pos = util.IntersectRayWithPlane(
		pac999.camera.GetViewMatrix():GetTranslation(),
		pac999.camera.GetViewRay(),
		center,
		self.grab_matrix[axis](self.grab_matrix)
	)

	return plane_pos
end

function META:SetWorldMatrix(m, b)
	if self.old_scale then
		--m:SetScale(self.old_scale)
		--self.grab_matrix:SetScale(self.old_scale)
	end

	self.entity.transform:SetTRMatrix(m * self.grab_matrix:GetInverse() * self.grab_transform)

	if self.old_scale then
		--self.grab_matrix:SetScale(Vector(1,1,1))
	end
end

function META:SetupTranslation()
	local dist = 8
	local thickness = 1.5
	local model = "models/hunter/misc/cone1x1.mdl"

	local function build_callback(axis, axis2)
		return function(component)
			local m, center_pos = self:StartGrab(axis)

			if not m then return end

			return function()

				local plane_pos = self:GetGrabPlanePosition(axis)

				if not plane_pos then return end

				local m = m * Matrix()
				local dir = m[axis2](m)
				m:SetTranslation(m:GetTranslation() + dir * (plane_pos - center_pos):Dot(dir))

				self:SetWorldMatrix(m)
			end
		end,
		function(ent, grabbed)
			local axis = axis2
			local key = "visual_move_axis_" .. axis
			if self[key] then
				self[key]:Remove()
				self[key] = nil
			end


			if grabbed then
				local visual = pac999.scene.AddNode(self.entity)
				visual:SetIgnoreZ(true)
				visual:RemoveComponent("gizmo")
				visual:RemoveComponent("input")
				visual:SetModel("models/hunter/blocks/cube025x025x025.mdl")
				visual:SetMaterial(white_mat)
				visual:SetColor(color_white)
				visual:SetAlpha(1)
				visual:SetLocalScale(Vector(thickness/25,thickness/25,32000))
				visual:SetWorldPosition(self.entity:GetWorldCenter())
				local a

				if axis == "GetRight" then
					a = Angle(0,0,90)
					visual:SetColor(GREEN)
				elseif axis == "GetUp" then
					a = Angle(0,0,0)
					visual:SetColor(BLUE)
				elseif axis == "GetForward" then
					a = Angle(90,0,0)
					visual:SetColor(RED)
				end
				visual:SetAngles(a)

				self[key] = visual
			end

		end
	end

	local function add_grabbable(gizmo_color, axis, axis2, axis3)
		local m = self.entity:GetWorldMatrix()
		local dir = m[axis2](m)*dist
		local wpos = self.entity:GetWorldPosition()

		local function update(ent, dir)
			local box_pos = self.entity:NearestPoint(self.entity:GetWorldCenter() + dir * 1000)

			if not box_pos then return end

			ent:SetWorldPosition(box_pos + (box_pos - self.entity:GetWorldCenter()):GetNormalized() * 15)

			ent.transform:GetMatrix()
		end

		do
			local ent = create_grab(self, model, vector_origin, build_callback(axis, axis2))
			ent:SetLocalScale(Vector(1,1,1)*0.25)
			ent:SetWorldPosition(self.entity:NearestPoint(wpos + dir) + dir)
			ent:SetAngles(ent:GetPosition():AngleEx(Vector(0,0,1)) + Angle(90,0,0))
			ent:SetColor(gizmo_color)
			ent:SetWorldPosition(ent:GetWorldPosition() + ent:GetUp() * ent:GetBoundingRadius()*2)

			ent:AddEvent("Update", function(ent)
				local m = self.entity.transform:GetMatrix()

				update(ent, m[axis2](m))
			end)
		end

		do
			local ent = create_grab(self, model, vector_origin, build_callback(axis, axis2))
			ent:SetLocalScale(Vector(1,1,1)*0.25)
			ent:SetWorldPosition(self.entity:NearestPoint(wpos - dir) - dir)
			local ang =
			ent:SetAngles(ent:GetPosition():AngleEx(Vector(0,0,1)) + Angle(90,0,0))
			ent:SetColor(gizmo_color)
			ent:SetWorldPosition(ent:GetWorldPosition() + ent:GetUp() * ent:GetBoundingRadius()*2.15)
			ent:AddEvent("Update", function(ent)
				local m = self.entity.transform:GetMatrix()

				update(ent, m[axis2](m)*-1)
			end)
		end

		return ent
	end

	add_grabbable(RED, "GetRight", "GetForward", "GetRight")
	add_grabbable(GREEN, "GetForward", "GetRight", "GetUp")
	add_grabbable(BLUE, "GetRight", "GetUp", "GetForward")
end

function META:SetupRotation()
	local disc = "models/hunter/tubes/tube4x4x025d.mdl"
	local dist = dist*0.5/1.25
	local visual_size = 0.28
	local scale = 0.25

	-- TODO: figure out why we need to fixup the local angles

	-- not sure why we have to do this
	-- if not, the entire model inverts when it
	-- reaches 180 deg around the rotation

	local function build_callback(axis, fixup_callback, invert)

		local function local_matrix(m, dir)
			local lrot = Matrix()
			lrot:Rotate(dir:Angle())
			lrot = m:GetInverse() * lrot
			local temp_ang = lrot:GetAngles()
			fixup_callback(temp_ang)
			lrot = Matrix()
			lrot:SetAngles(temp_ang)
			return lrot
		end

		invert = invert or 1
		return function(ent)
			local m, center_pos = self:StartGrab(axis)

			if not m then return end

			local centerw = self.entity:GetWorldCenter()
			local old_tr = m:GetTranslation()
			local center = utility.TransformVector(m:GetInverse(), centerw)

			local local_start_rotation = local_matrix(m, (center_pos - m:GetTranslation())*invert)

			return function()
				local plane_pos = self:GetGrabPlanePosition(axis)

				if not plane_pos then return end

				debugoverlay.Sphere(plane_pos, 4, 0, RED, Color(255,0,0,255), true)

				local local_drag_rotation = local_matrix(m, (plane_pos - m:GetTranslation())*invert)


				local m = m * Matrix()

				local ang = (local_start_rotation:GetInverse() * local_drag_rotation):GetAngles()

				if input.IsKeyDown(KEY_LSHIFT) then
					if axis == "GetRight" then
						ang.p = math.Round(ang.p / 45) * 45
					end

					if axis == "GetUp" then
						ang.y = math.Round(ang.y / 45) * 45
					end

					if axis == "GetForward" then
						ang.r = math.Round(ang.r / 45) * 45
					end
				end

				local rot = Matrix()
				rot:Rotate(ang)
				local ang = (m * rot):GetAngles()
				m:Translate(center)
				m:SetAngles(ang)

				m = m * self.grab_matrix:GetInverse() * self.grab_transform
				m:Translate(-center)
				self.entity.transform:SetTRMatrix(m)
			end
		end
	end

	local function add_grabbable(axis, axis2, gizmo_color, fixup_callback)
		local disc = "models/props_phx/construct/glass/glass_curve360x2.mdl"

		local m = self.entity:GetWorldMatrix()
		local dir = m[axis2](m) * dist
		local wpos = self.entity:GetWorldPosition()

		do
			local ent = create_grab(self, disc, vector_origin, build_callback(axis, fixup_callback, 1))
			--ent:SetWorldPosition(self.entity:NearestPoint(wpos + dir) + dir)

			if axis == "GetRight" then
				ent:SetAngles(Angle(45,180,90))
			elseif axis == "GetUp" then
				ent:SetAngles(Angle(0,90 -45,0))
			elseif axis == "GetForward" then
				ent:SetAngles(Angle(90 +45,90,90))
			end

			ent:SetLocalScale(Vector(1,1,0.0125) * 0.02 * self.entity:GetBoundingRadius())

			ent:SetColor(gizmo_color)

			ent:AddEvent("Update", function()
				ent:SetWorldPosition(self.entity:GetWorldCenter())
				local s = self.entity:GetScaleMatrix():GetScale()
				local l = math.max(s.x, s.y, s.z)/3
				ent:SetLocalScale(Vector(1,1,0.0125) * 0.02 * self.entity:GetBoundingRadius() * l)
				--ent:SetPosition(vect)
			end)
		end
	end

	add_grabbable("GetRight", "GetForward", RED, function(local_angles)
		local_angles.r = -local_angles.y
	end)

	add_grabbable("GetUp", "GetRight", GREEN, function(local_angles)
		local_angles.r = -local_angles.p
		local_angles.y = local_angles.y - 90
	end)

	add_grabbable("GetForward", "GetUp", BLUE, function(local_angles)
		-- this one is realy weird
		local p = local_angles.p

		if local_angles.y > 0 then
			p = -p + 180
		end

		local_angles.r = -90 + p
		local_angles.p = 180
		local_angles.y = 180
	end)
end

function META:SetupScale()
	local visual_size = 0.6
	local scale = 0.5

	local model = "models/hunter/blocks/cube025x025x025.mdl"

	local function build_callback(axis, axis2, reverse)
		return function(component)
			local m = self.entity.transform:GetMatrix() * Matrix()
			m:SetScale(Vector(1,1,1))
			local pos = m:GetTranslation()
			local center_pos = util.IntersectRayWithPlane(
				pac999.camera.GetViewMatrix():GetTranslation() - pos,
				pac999.camera.GetViewRay(),
				vector_origin,
				m[axis](m)
			)

			if not center_pos then return end

			local cage_min_start = reverse and self.entity.transform:GetCageSizeMax()*1 or self.entity.transform:GetCageSizeMin()*1

			return function()

				local plane_pos = util.IntersectRayWithPlane(
					pac999.camera.GetViewMatrix():GetTranslation() - pos,
					pac999.camera.GetViewRay(),
					vector_origin,
					m[axis](m)
				)

				if not plane_pos then return end

				local m = m * Matrix()
				local dir
				local reverse = reverse

				if 	axis2 == "GetForward" then
					if reverse then
						dir = Vector(-1,0,0)
					else
						dir = Vector(1,0,0)
					end
				elseif axis2 == "GetRight" then
					if reverse then
						dir = Vector(0,1,0)
					else
						dir = Vector(0,-1,0)
					end
				elseif axis2 == "GetUp" then
					if reverse then
						dir = Vector(0,0,-1)
					else
						dir = Vector(0,0,1)
					end
				end

				local dist = (plane_pos - center_pos):Dot(m[axis2](m))
				if reverse then
					self.entity.transform:SetCageSizeMax(cage_min_start - (dir * dist))
				else
					self.entity.transform:SetCageSizeMin(cage_min_start + (dir * dist))
				end
			end
		end
	end

	local function add_grabbable(gizmo_angle, gizmo_color, axis, axis2)

		local function update(ent, dir)
			local box_pos = self.entity:NearestPoint(self.entity:GetWorldCenter() + dir * 1000)

			if not box_pos then return end

			ent:SetWorldPosition(box_pos)

			ent.transform:GetMatrix()
		end

		local ent = create_grab(self, model, vector_origin, build_callback(axis, axis2, true))
		ent:SetLocalScale(Vector(1,1,1)*scale)
		ent:SetColor(gizmo_color)
		ent:AddEvent("Update", function(ent)
			local m = self.entity.transform:GetMatrix()
			if axis2 == "GetRight" then
				update(ent, m[axis2](m))
			else
				update(ent, m[axis2](m)*-1)
			end
		end)

		local ent = create_grab(self, model, vector_origin, build_callback(axis, axis2))
		ent:SetLocalScale(Vector(1,1,1)*scale)
		ent:SetColor(gizmo_color)

		ent:AddEvent("Update", function(ent)
			local m = self.entity.transform:GetMatrix()

			if axis2 == "GetRight" then
				update(ent, m[axis2](m) * -1)
			else
				update(ent, m[axis2](m))
			end
		end)

		return ent
	end

	add_grabbable(Angle(90,0,0), RED, "GetRight", "GetForward")
	add_grabbable(Angle(0,0,-90), GREEN, "GetForward", "GetRight")
	add_grabbable(Angle(0,0,0), BLUE, "GetRight", "GetUp")
end

function META:EnableGizmo(b)

	--self.entity.transform:InvalidateMatrix()

	if b then
		self:SetupViewTranslation()
		self:SetupTranslation()
		self:SetupRotation()
		self:SetupScale()
	else
		for k,v in pairs(self.grab_entities) do
			v:Remove()
		end
		self.grab_entities = {}
	end
	self.gizmoenabled = b

	--self.entity.transform:SetWorldPosition(LocalPlayer():EyePos())
end

function META.EVENTS:PointerHover()
	local local_normal = self.entity.input:GetHitNormal()

	if local_normal == Vector(0,0,1) then

	end
end

function META.EVENTS:Pointer(hovered, grabbed)
	if grabbed then
		self:EnableGizmo(not self.gizmoenabled)
	end

end

BUILDER:Register()