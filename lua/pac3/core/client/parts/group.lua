local PART = {}

PART.ClassName = "group"
PART.HideGizmo = true

function PART:Initialize()
	self.StorableVars = {}
	
	pac.StartStorableVars()
		pac.GetSet(self, "Name", "")
		pac.GetSet(self, "Description", "")
		pac.GetSet(self, "OwnerName", "")
		pac.GetSet(self, "ParentName", "")
		pac.GetSet(self, "Hide", false)
	pac.EndStorableVars()
	
	-- hacks
	timer.Simple(0.1, function() 
		if self.OwnerName == "" then
			self:SetOwnerName("self")
		else
			self:CheckOwner() 
		end
	end) 
end

pac.RegisterPart(PART)