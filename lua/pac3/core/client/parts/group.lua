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
		self:SetOwnerName("self") 
	end) 
end

pac.RegisterPart(PART)