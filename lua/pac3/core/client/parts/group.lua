local PART = {}

PART.ClassName = "group"
PART.NonPhysical = true
PART.Icon = 'icon16/world.png'

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