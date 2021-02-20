local BUILDER, PART = pac.PartTemplate("base")

PART.ClassName = "group"

PART.Icon = 'icon16/world.png'
PART.Description = "right click to add parts"

BUILDER:StartStorableVars()
	BUILDER:GetSet("Duplicate", false)
BUILDER:EndStorableVars()

function PART:GetNiceName()
	return #self:GetChildrenList() .. " children"
end

function PART:SetOwnerName(name)
	if name == "" then
		name = "self"
	end

	self.OwnerName = name

	self:CheckOwner()
end

function PART:OnVehicleChanged(ply, vehicle)
	if not self:HasParent() and self.OwnerName == "active vehicle" then
		self:CheckOwner()
	end
end

BUILDER:Register()