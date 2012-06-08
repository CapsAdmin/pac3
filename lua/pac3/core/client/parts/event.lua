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
	
	primary_ammo_equals = function(owner, self)
		local num = tonumber(self.Arguments) or 0
		local wep = owner.GetActiveWeapon and owner:GetActiveWeapon() or NULL
		if wep:IsValid() and wep:Clip1() == num then
			return true
		end
	end,
	
	secondary_ammo_equals = function(owner, self)
		local num = tonumber(self.Arguments) or 0
		local wep = owner.GetActiveWeapon and owner:GetActiveWeapon() or NULL
		if wep:IsValid() and wep:Clip2() == num then
			return true
		end
	end,
	
	primary_ammo_above = function(owner, self)
		local num = tonumber(self.Arguments) or 0
		local wep = owner.GetActiveWeapon and owner:GetActiveWeapon() or NULL
		if wep:IsValid() and wep:Clip1() > num then
			return true
		end	
	end,
	
	secondary_ammo_above = function(owner, self)
		local num = tonumber(self.Arguments) or 0
		local wep = owner.GetActiveWeapon and owner:GetActiveWeapon() or NULL
		if wep:IsValid() and wep:Clip2() > num then
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
	
	in_vehicle = function(owner, self)
		local ent = owner:GetVehicle()
		if ent:IsValid() then
		
			if self.Arguments ~= "" then
				local class = ent:GetClass()
				if pac.PatternCache[class..self.Arguments] or class:find(self.Arguments) then
					pac.PatternCache[class..self.Arguments] = true
					return true
				end
				
				return false
			end

			return true
		end
	end,
	
	model_equals = function(owner, self)
		return owner:GetModel() == self.Arguments
	end,
	
	model_find = function(owner, self)
		if self.Arguments ~= "" then
			local str = owner:GetModel()
			if pac.PatternCache[str..self.Arguments] or str:find(self.Arguments) then
				pac.PatternCache[str..self.Arguments] = true
				return true
			end
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
				if self:IsHidden() then
					parent.EventHide = self.Invert
				elseif self.Invert then
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