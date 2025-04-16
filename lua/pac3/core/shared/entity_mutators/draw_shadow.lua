local MUTATOR = {}

MUTATOR.ClassName = "draw_shadow"

function MUTATOR:WriteArguments(b)
	net.WriteBool(b)
end

function MUTATOR:ReadArguments()
	return net.ReadBool()
end

if SERVER then
	function MUTATOR:StoreState()
		return self.Entity.pac_emut_draw_shadow
	end

	function MUTATOR:Mutate(b)
		self.Entity:DrawShadow(b)
		self.Entity.pac_emut_draw_shadow = b
	end
end

pac.emut.Register(MUTATOR)