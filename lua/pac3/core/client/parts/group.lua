local PART = {}

PART.ClassName = "group"
PART.NonPhysical = true

pac.StartStorableVars()
	pac.GetSet(PART, "Duplicate", false)
pac.EndStorableVars()

function PART:SetOwnerName(name)
	if name == "" then
		name = "self"
	end

	self.OwnerName = name

	self:CheckOwner()
end

pac.RegisterPart(PART)