local physprop_enums = {}
local physprop_indices = {}
for i=0,500,1 do
	local name = util.GetSurfacePropName(i)
	if name ~= "" then
		physprop_enums[name] = name
		physprop_indices[name] = i
	end
end



local BUILDER, PART = pac.PartTemplate("base")

PART.ThinkTime = 0
PART.ClassName = "physics"

PART.Group = 'model'
PART.Icon = 'icon16/shape_handles.png'

BUILDER:StartStorableVars()

	BUILDER:SetPropertyGroup("Behavior")
		:GetSet("SelfCollision", false)
		:GetSet("Gravity", true)
		:GetSet("Collisions", true)
		:GetSet("ConstrainSphere", 0)
		:GetSet("Pushable", false, {description = "Whether the physics object should be pushed back by nearby players and props within its radius."})
		:GetSet("ThinkDelay", 1)

	BUILDER:SetPropertyGroup("Follow")
		:GetSet("Follow", false, {description = "Whether the physics object should follow via SetPos. But it might clip in the world! seconds to arrive will be used for deciding the speed"})
		:GetSet("PushFollow", false, {description = "Whether the physics object should try to follow via AddVelocity, to prevent phasing through walls. But it might get stuck in a corner!\n"..
													"seconds to arrive, along with the extra distance if it's beyond the constrain sphere, will be used for deciding the speed"})
		:GetSet("SecondsToArrive", 0.1)
		:GetSet("MaxSpeed", 10000)
		:GetSet("MaxAngular", 3600)
		:GetSet("MaxSpeedDamp", 1000)
		:GetSet("MaxAngularDamp", 1000)
		:GetSet("DampFactor", 1)
	BUILDER:SetPropertyGroup("Speeds")

		:GetSet("ConstantVelocity", Vector(0,0,0))

	BUILDER:SetPropertyGroup("Shape")
		:GetSet("BoxScale",Vector(1,1,1))
		:GetSet("Box", true)
		:GetSet("Radius", 1)
		:GetSet("SurfaceProperties", "default", {enums = physprop_enums})
		:GetSet("Preview", false)
		:GetSet("Mass", 100)

	BUILDER:SetPropertyGroup("InitialVelocity")
		:GetSet("AddOwnerSpeed", false)
		:GetSet("InitialVelocityVector", Vector(0,0,0))
		:GetSetPart("InitialVelocityPart")
		:GetSet("OverrideInitialPosition", false, {description = "Whether the initial velocity part should be used as an initial position, otherwise it'll just be for the initial velocity's angle"})

	
BUILDER:EndStorableVars()

local function IsInvalidParent(self)
	return self.Parent.ClassName ~= "model" and self.Parent.ClassName ~= "model2"
end

PART.phys = NULL

function PART:SetBox(b)
	self.Box = b
	self:SetRadius(self.Radius)
end

function PART:SetCollisions(b)
	self.Collisions = b

	if self.phys:IsValid() then
		self.phys:EnableCollisions(b)
	end
end

function PART:SetMass(n)
	self.Mass = n

	if self.phys:IsValid() then
		self.phys:SetMass(math.Clamp(n, 0.001, 50000))
	end
end

function PART:MeshDraw()
	if not IsValid(self.phys) then return end

	local mesh = (self.phys):GetMesh()
	local drawmesh = Mesh()

	if mesh == nil or not self.Box then
		render.DrawWireframeSphere( self.phys:GetPos(), self.Radius, 10, 10, Color( 255, 255, 255 ) )
	else
		drawmesh:BuildFromTriangles(mesh)

		render.SetMaterial( Material( "models/wireframe" ) )
		local mat = Matrix()
		mat:Translate(self.phys:GetPos())
		mat:Rotate(self.phys:GetAngles())
		cam.PushModelMatrix( mat )
		drawmesh:Draw()
		cam.PopModelMatrix()
	end
end

function PART:SetPreview(b)
	self.Preview = b
	if self.Preview then
		hook.Add("PostDrawTranslucentRenderables", "pac_physics_preview"..self.UniqueID, function()
			self:MeshDraw()
		end)
	else
		hook.Remove("PostDrawTranslucentRenderables", "pac_physics_preview"..self.UniqueID)
	end
end

function PART:SetRadius(n)
	self.Radius = n

	if IsInvalidParent(self) then return end

	local ent = self.Parent:GetOwner()

	if n <= 0 then n = ent:BoundingRadius()/2 end

	ent:SetNoDraw(false)

	if self.Box then
		ent:PhysicsInitBox(self.BoxScale * -n, self.BoxScale * n, self.SurfaceProperties)
	else
		ent:PhysicsInitSphere(n, self.SurfaceProperties)
	end

	self.phys = ent:GetPhysicsObject()

	if self.Gravity ~= nil then
		self.phys:EnableGravity(self.Gravity)
	end
end

function PART:SetSurfaceProperties(str)
	self.SurfaceProperties = str
	self:SetRadius(self.Radius) --refresh the physics
end

function PART:GetSurfacePropsTable() --to view info over in the properties
	return util.GetSurfaceData(physprop_indices[self.SurfaceProperties])
end

function PART:SetBoxScale(vec)
	self.BoxScale = vec
	self:SetRadius(self.Radius) --refresh the physics
end

function PART:SetGravity(b)
	self.Gravity = b

	if self.phys:IsValid() then
		self.phys:EnableGravity(b)
	end
end

function PART:SetSelfCollision(b)
	self.SelfCollision = b

	if IsInvalidParent(self) then return end

	local ent = self.Parent:GetOwner()

	if b then
		ent:SetCollisionGroup(COLLISION_GROUP_NONE)
	else
		ent:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
	end
end

local params = {}

function PART:OnThink()

	if self.Parent.GetWorldPosition then
		if self.disabled then
			self:Enable()
		end
	else
		if not self.disabled then
			self:Disable()
		end
	end


	local phys = self.phys

	if phys:IsValid() then
		phys:Wake()

		if self.Follow or self.PushFollow then
			if not self.PushFollow then
				params.pos = self.Parent:GetWorldPosition()
				params.angle  = self.Parent:GetWorldAngles()

				params.secondstoarrive = math.max(self.SecondsToArrive, 0.0001)
				params.maxangular = self.MaxAngular
				params.maxangulardamp = self.MaxAngularDamp
				params.maxspeed = self.MaxSpeed
				params.maxspeeddamp = self.MaxSpeedDamp
				params.dampfactor = self.DampFactor

				params.teleportdistance = 0

				phys:ComputeShadowControl(params)
			end
			
			-- this is nicer i think
			if self.ConstrainSphere ~= 0 and phys:GetPos():Distance(self.Parent:GetWorldPosition()) > self.ConstrainSphere then
				if not self.PushFollow then
					phys:SetPos(self.Parent:GetWorldPosition() + (self.Parent:GetWorldPosition() - phys:GetPos()):GetNormalized() * -self.ConstrainSphere)
				--new push mode
				else
					local vec = (self.Parent:GetWorldPosition() - phys:GetPos())
					local current_dist = vec:Length()
					local extra_dist = current_dist - self.ConstrainSphere
					phys:AddVelocity(0.5 * vec:GetNormalized() * extra_dist / math.Clamp(self.SecondsToArrive,0.05,10))
				end
			end
		else
			if self.ConstrainSphere ~= 0 then
				local offset = self.Parent:GetWorldPosition() - phys:GetPos()

				if offset:Length() > self.ConstrainSphere then
					phys:SetPos(self.Parent:GetWorldPosition() - offset:GetNormalized() * self.ConstrainSphere)
					phys:SetVelocity(Vector())
				end
			end
		end
	end
end

function PART:OnParent(part)
	timer.Simple(0, function() self:Enable() end)
end

function PART:OnUnParent(part)
	timer.Simple(0, function() self:Disable() end)
end

function PART:OnShow()
	timer.Simple(0, function() self:Enable() end)
end

function PART:OnHide()
	if not self.Hide and not self:IsHidden() then
		timer.Simple(0.4, function()
			self:GetRootPart():OnShow()
			self.Parent:OnShow()
			for _,part in pairs(self:GetParent():GetChildrenList()) do
				part:OnShow()
				
			end
		end)
		return
	end
	timer.Simple(0, function() self:Disable() end)

	hook.Remove("PostDrawTranslucentRenderables", "pac_physics_preview"..self.UniqueID)
end

function PART:Enable()
	if IsInvalidParent(self) then return end

	local part = self:GetParent()

	part.skip_orient = true

	local ent = part:GetOwner()
	ent:SetNoDraw(false)

	self:SetRadius(self.Radius)

	for key, val in pairs(self.StorableVars) do
		if pac.registered_parts.base.StorableVars[key] then goto CONTINUE end
		self["Set" .. key](self, self[key])
		::CONTINUE::
	end

	self.disabled = false

	if IsValid(self.InitialVelocityPart) then
		if self.InitialVelocityPart.GetWorldPosition then
			local local_vec, local_ang = self.InitialVelocityPart:GetDrawPosition()
			local local_vec2 = 	self.InitialVelocityVector.x * local_ang:Forward() +
								self.InitialVelocityVector.y * local_ang:Right() +
								self.InitialVelocityVector.z * local_ang:Up()
			self.phys:AddVelocity(local_vec2)
			if self.OverrideInitialPosition then
				self.phys:SetPos(local_vec)
			end
		else
			self.phys:AddVelocity(self.InitialVelocityVector)
		end
	else
		self.phys:AddVelocity(self.InitialVelocityVector)
	end

	if self.AddOwnerSpeed then
		self.phys:AddVelocity(self:GetRootPart():GetOwner():GetVelocity())
	end

	timer.Simple(self.ThinkDelay, function() hook.Add("Tick", "pac_phys_repulsionthink"..self.UniqueID, function()
		if not IsValid(self.phys) then hook.Remove("Tick", "pac_phys_repulsionthink"..self.UniqueID) return end
		self.phys:AddVelocity(self.ConstantVelocity * RealFrameTime())

		if self.Pushable then
			local pushvec = Vector(0,0,0)
			local pos = self.phys:GetPos()
			local ents_tbl = ents.FindInSphere(pos, self.Radius)
			local valid_phys_pushers = 0
			for i,ent in pairs(ents_tbl) do
				if ent.GetPhysicsObject or ent:IsPlayer() then
					if ent:IsPlayer() or ent:GetClass() == "prop_physics" or ent:GetClass() == "prop_ragdoll" then
						valid_phys_pushers = valid_phys_pushers + 1
						pushvec = pushvec + (pos - ent:GetPos()):GetNormalized() * 20
					end
				end
			end
			if valid_phys_pushers > 0 then self.phys:AddVelocity(pushvec / valid_phys_pushers) end
		end
		
		
	end) end)
end

function PART:Disable()
	hook.Remove("Tick", "pac_phys_repulsionthink"..self.UniqueID)
	if IsInvalidParent(self) then return end

	local part = self:GetParent()

	local ent = part:GetOwner()

	if ent:IsValid() then
		-- SetNoDraw does not care of validity but PhysicsInit does?
		ent:SetNoDraw(true)
		ent:PhysicsInit(SOLID_NONE)
	end
	part.skip_orient = false

	self.disabled = true
end

function PART:SetPositionDamping(num)
	self.PositionDamping = num

	if self.phys:IsValid() then
		self.phys:SetDamping(self.PositionDamping, self.AngleDamping)
	end
end

function PART:SetAngleDamping(num)
	self.AngleDamping = num

	if self.phys:IsValid() then
		self.phys:SetDamping(self.PositionDamping, self.AngleDamping)
	end
end

BUILDER:Register()
