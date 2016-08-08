local PART = {}

PART.ClassName = "group"
PART.NonPhysical = true

pac.StartStorableVars()
	pac.GetSet(PART, "Duplicate", false)
--	pac.GetSet(PART, "ShowInFirstperson", false)
pac.EndStorableVars()

function PART:Initialize()
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

pac.RegisterPart(PART)