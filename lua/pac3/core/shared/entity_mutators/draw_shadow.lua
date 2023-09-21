local MUTATOR = {} 
  
MUTATOR.ClassName = "draw_shadow" 

function MUTATOR:WriteArguments(enum) 
	net.WriteBool(enum, 8) 
end 
 
function MUTATOR:ReadArguments() 
	return net.ReadBool() 
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