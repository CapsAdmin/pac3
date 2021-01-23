local PART = {}

PART.ThinkTime = 0
PART.ClassName = "physics"
PART.NonPhysical = true
PART.Group = 'model'
PART.Icon = 'icon16/shape_handles.png'

pac.StartStorableVars()
	pac.GetSet(PART, "Box", true)
	pac.GetSet(PART, "Radius", 1)
	pac.GetSet(PART, "SelfCollision", false)
	pac.GetSet(PART, "Gravity", true)
	pac.GetSet(PART, "Collisions", true)
	pac.GetSet(PART, "Mass", 100)

	pac.GetSet(PART, "Follow", false)

	pac.GetSet(PART, "SecondsToArrive", 0.1)

	pac.GetSet(PART, "MaxSpeed", 10000)
	pac.GetSet(PART, "MaxAngular", 3600)

	pac.GetSet(PART, "MaxSpeedDamp", 1000)
	pac.GetSet(PART, "MaxAngularDamp", 1000)
	pac.GetSet(PART, "DampFactor", 1)

	pac.GetSet(PART, "ConstrainSphere", 0)
pac.EndStorableVars()

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

function PART:SetRadius(n)
	self.Radius = n

	if IsInvalidParent(self) then return end

	local ent = self.Parent:GetEntity()

	if n <= 0 then n = ent:BoundingRadius()/2 end

	ent:SetNoDraw(false)

	if self.Box then
		ent:PhysicsInitBox(Vector(1,1,1) * -n, Vector(1,1,1) * n)
	else
		ent:PhysicsInitSphere(n)
	end

	self.phys = ent:GetPhysicsObject()

	if self.Gravity ~= nil then
		self.phys:EnableGravity(self.Gravity)
	end
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

	local ent = self.Parent:GetEntity()

	if b then
		ent:SetCollisionGroup(COLLISION_GROUP_NONE)
	else
		ent:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
	end
end

local params = {}

function PART:OnThink()

	local phys = self.phys

	if phys:IsValid() then
		phys:Wake()

		if self.Follow then
			params.pos = self.Parent.cached_pos
			params.angle  = self.Parent.cached_ang

			params.secondstoarrive = math.max(self.SecondsToArrive, 0.0001)
			params.maxangular = self.MaxAngular
			params.maxangulardamp = self.MaxAngularDamp
			params.maxspeed = self.MaxSpeed
			params.maxspeeddamp = self.MaxSpeedDamp
			params.dampfactor = self.DampFactor

			params.teleportdistance = 0

			phys:ComputeShadowControl(params)


			-- this is nicer i think
			if self.ConstrainSphere ~= 0 and phys:GetPos():Distance(self.Parent.cached_pos) > self.ConstrainSphere then
				phys:SetPos(self.Parent.cached_pos + (self.Parent.cached_pos - phys:GetPos()):GetNormalized() * -self.ConstrainSphere)
			end
		else
			if self.ConstrainSphere ~= 0 then
				local offset = self.Parent.cached_pos - phys:GetPos()

				if offset:Length() > self.ConstrainSphere then
					phys:SetPos(self.Parent.cached_pos - offset:GetNormalized() * self.ConstrainSphere)
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
	timer.Simple(0, function() self:Disable() end)
end

function PART:Enable()
	if IsInvalidParent(self) then return end

	local part = self:GetParent()

	part.skip_orient = true

	local ent = part:GetEntity()
	ent:SetNoDraw(false)

	self:SetRadius(self.Radius)

	for key, val in pairs(self.StorableVars) do
		if self.BaseClass.StorableVars[key] then goto CONTINUE end
		self["Set" .. key](self, self[key])
		::CONTINUE::
	end
end

function PART:Disable()
	if IsInvalidParent(self) then return end

	local part = self:GetParent()

	local ent = part:GetEntity()
	if ent:IsValid() then
		-- SetNoDraw does not care of validity but PhysicsInit does?
		ent:SetNoDraw(true)
		ent:PhysicsInit(SOLID_NONE)
	end
	part.skip_orient = false
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

pac.RegisterPart(PART)
