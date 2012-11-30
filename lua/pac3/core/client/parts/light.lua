local PART = {}

PART.ClassName = "light"

pac.StartStorableVars()
	pac.GetSet(PART, "Brightness", 1)
	pac.GetSet(PART, "Size", 5)	
	pac.GetSet(PART, "Style", 0)	
	pac.GetSet(PART, "Color", Vector(255, 255, 255))
pac.EndStorableVars()

local DynamicLight = DynamicLight

function PART:OnDraw(owner, pos, ang)
	self.Params = self.Params or DynamicLight(self.Owner:EntIndex() + self.Id)
	local params = self.Params
	if params then
		params.Pos = pos
		
		params.MinLight = self.Brightness
		params.Size = self.Size
		params.Style = self.Style
		
		params.r = self.Color.r
		params.g = self.Color.g
		params.b = self.Color.b		
		
		-- 100000000 constant is better than calling RealTime()
		params.DieTime = 100000000 -- RealTime()
		
		render.ComputeDynamicLighting(pos, ang:Up())
	end
end

function PART:OnHide()
	local p = self.Params 
	if p then
		p.DieTime = 0
	end
end

PART.OnRemove = OnHide

pac.RegisterPart(PART)