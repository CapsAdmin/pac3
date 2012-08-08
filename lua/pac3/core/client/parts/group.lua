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
		pac.GetSet(self, "EditorExpand", false)
	pac.EndStorableVars()
	
	-- hacks
	timer.Simple(0.1, function() 
		if not self:IsValid() then return end
		
		if self.OwnerName == "" then
			self:SetOwnerName("self")
		else
			self:CheckOwner() 
		end
	end) 
end

function PART:OnChildAdd(part) 
	local owner = self:GetOwner()
	if owner:IsValid() and owner.pac_parts then
		owner.pac_parts[part.Id] = part
	end
end

pac.RegisterPart(PART)