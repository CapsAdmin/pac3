local PART = {}

PART.ClassName = "group"
PART.HideGizmo = true

function PART:Initialize()
	self.StorableVars = {}
	
	pac.StartStorableVars()
		pac.GetSet(self, "Name", "")
		pac.GetSet(self, "Description", "")
		pac.GetSet(self, "Hide", false)
		pac.GetSet(self, "WeaponClass", "")
		pac.GetSet(self, "HideWeaponClass", false)
	pac.EndStorableVars()
end

pac.RegisterPart(PART)