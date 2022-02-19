local BUILDER, PART = pac.PartTemplate("base")

PART.ThinkTime = 0
PART.ClassName = "physics"

PART.Group = 'model'
PART.Icon = 'icon16/shape_handles.png'

BUILDER:StartStorableVars()
	BUILDER:GetSet("Box", true)
	BUILDER:GetSet("Radius", 1)
	BUILDER:GetSet("SelfCollision", false)
	BUILDER:GetSet("Gravity", true)
	BUILDER:GetSet("Collisions", true)
	BUILDER:GetSet("Mass", 100)

	BUILDER:GetSet("Follow", false)

	BUILDER:GetSet("SecondsToArrive", 0.1)

	BUILDER:GetSet("MaxSpeed", 10000)
	BUILDER:GetSet("MaxAngular", 3600)

	BUILDER:GetSet("MaxSpeedDamp", 1000)
	BUILDER:GetSet("MaxAngularDamp", 1000)
	BUILDER:GetSet("DampFactor", 1)

	BUILDER:GetSet("ConstrainSphere", 0)
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

function PART:SetRadius(n)
	self.Radius = n

	if IsInvalidParent(self) then return end

	local ent = self.Parent:GetOwner()

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

		if self.Follow then
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


			-- this is nicer i think
			if self.ConstrainSphere ~= 0 and phys:GetPos():Distance(self.Parent:GetWorldPosition()) > self.ConstrainSphere then
				phys:SetPos(self.Parent:GetWorldPosition() + (self.Parent:GetWorldPosition() - phys:GetPos()):GetNormalized() * -self.ConstrainSphere)
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
	timer.Simple(0, function() self:Disable() end)
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
end

function PART:Disable()
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
