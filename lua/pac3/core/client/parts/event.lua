local PART = {}

PART.ClassName = "event"
PART.HideGizmo = true

PART.Events = 
{
	velocity = function(owner, self) 
		local num = tonumber(self.Arguments)
		if num and owner:GetVelocity():Length() > num then
			return true
		end
	end,

	on_fire = net and (function(owner)
		return owner:IsOnFire()
	end) or nil,

	flashlight = function(owner)
		if owner:IsPlayer() and owner:FlashlightIsOn() then
			return true
		end
	end,
	
	voice_chat = function(owner)
		if owner:IsPlayer() and owner:IsSpeaking() then
			return true
		end
	end,

	primary_ammo_empty = function(owner)
		local wep = owner.GetActiveWeapon and owner:GetActiveWeapon() or NULL
		if wep:IsValid() and wep:Clip1() == 0 then
			return true
		end
	end,
	
	secondary_ammo_empty = function(owner)
		local wep = owner.GetActiveWeapon and owner:GetActiveWeapon() or NULL
		if wep:IsValid() and wep:Clip2() == 0 then
			return true
		end
	end,
	
	on_ground = function(owner)
		if owner:IsPlayer() and owner:IsOnGround() then
			return true
		end
	end,
	
	under_water = function(owner, self)
		local num = tonumber(self.Arguments) or 3

		if owner:WaterLevel() > num then
			return true
		end
	end,
}

function PART:GetOwner()
	return self.PlayerOwner 
end

function PART:Think()
	local owner = self:GetOwner()
	
	if owner:IsValid() then
		local func = self.Events[self.Event]
		
		if func then
			local parent = self:GetParent()
			if parent:IsValid() then
				if self.Invert then
					parent.EventHide = not (func(owner, self) or false)
				else
					parent.EventHide = (func(owner, self) or false)
				end
			end
		end
	end
end

function PART:Initialize()
	self.StorableVars = {}
	
	pac.StartStorableVars()
		pac.GetSet(self, "Name", "")
		pac.GetSet(self, "Description", "")
		pac.GetSet(self, "Hide", false)
		pac.GetSet(self, "Event", "")
		pac.GetSet(self, "Arguments", "")
		pac.GetSet(self, "Invert", false)
	pac.EndStorableVars()
end

pac.RegisterPart(PART)