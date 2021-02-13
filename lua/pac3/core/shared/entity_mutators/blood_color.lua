local MUTATOR = {}

MUTATOR.ClassName = "blood_color"

function MUTATOR:WriteArguments(enum)
	assert(enum >= -1 and enum <= 6, "invalid blood color")
	net.WriteInt(enum, 8)
end

function MUTATOR:ReadArguments()
	return net.ReadInt(8)
end

if SERVER then
	function MUTATOR:StoreState()
		return self.Entity:GetBloodColor()
	end

	function MUTATOR:Mutate(enum)
		self.Entity:SetBloodColor(enum)
	end
end

pac.emut.Register(MUTATOR)