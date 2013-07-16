local PART = {}

PART.ClassName = "light"

pac.StartStorableVars()
	pac.GetSet(PART, "Brightness", 1)
	pac.GetSet(PART, "Size", 5)	
	pac.GetSet(PART, "Style", 0)	
	pac.GetSet(PART, "Color", Vector(255, 255, 255))
pac.EndStorableVars()

function PART:GetNiceName()
	local hue, sat, val = pac.ColorToNames(self:GetColor())
	return hue .. " light"
end

local DynamicLight = DynamicLight

pac.dynamic_lights = pac.dynamic_lights or {}

function PART:OnDraw(owner, pos, ang)
	local id = tonumber(self.UniqueID)
	self.Params = self.Params or pac.dynamic_lights[id] or DynamicLight(id)
	if not pac.dynamic_lights[id] then
		pac.dynamic_lights[id] = self.Params
	end
	local params = self.Params
	if params then
		params.Pos = pos
		
		params.MinLight = self.Brightness
		params.Size = self.Size
		params.Style = self.Style
		
		params.r = self.Color.r
		params.g = self.Color.g
		params.b = self.Color.b		
		
		-- 100000000 constant is better than calling pac.RealTime
		params.DieTime = 1000000000000 -- pac.RealTime
	end
end

function PART:OnHide()
	local p = self.Params 
	if p then
		p.DieTime = 0
		p.Size = 0
		p.MinLight = 0
		p.Pos = Vector()
	end
end

PART.OnRemove = OnHide

pac.RegisterPart(PART)