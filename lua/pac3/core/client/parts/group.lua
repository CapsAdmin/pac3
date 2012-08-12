local PART = {}

PART.ClassName = "group"
PART.NonPhysical = true

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