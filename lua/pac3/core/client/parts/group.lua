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

function PART:OnEvent(typ, ply, vehicle)
	if typ == "vehicle_changed" then
		if not self:HasParent() and self.OwnerName == "active vehicle" then
			self:CheckOwner()
		end
	end
end

BUILDER:Register()