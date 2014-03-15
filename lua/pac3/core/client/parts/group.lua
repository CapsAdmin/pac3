local PART = {}

PART.ClassName = "group"
PART.NonPhysical = true

pac.StartStorableVars()
	pac.GetSet(PART, "Duplicate", false)
	--pac.GetSet(PART, "ShowInFirstperson", false)
pac.EndStorableVars()

function PART:SetOwnerName(name)
	if name == "" then name = "self" end
	
	self.OwnerName = name
	
	self:CheckOwner()
end

function PART:OnThink()
	if not self:HasParent() then
		local owner = self:GetOwner(true)
				
		if not owner:IsValid() then
			self:CheckOwner()
		end
	end
end

pac.RegisterPart(PART)