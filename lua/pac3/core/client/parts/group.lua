local PART = {}

PART.ClassName = "group"
PART.HideGizmo = true
PART.NeedsParent = false

function PART:Initialize()
	self.StorableVars = {}
	
	pac.StartStorableVars()
		pac.GetSet(self, "Name", "")
		pac.GetSet(self, "Description", "")
		pac.GetSet(self, "OwnerName", "")
		pac.GetSet(self, "ParentName", "")
		pac.GetSet(self, "Hide", false)
	pac.EndStorableVars()
	
	self:SetOwnerName("self")
end

pac.RegisterPart(PART)