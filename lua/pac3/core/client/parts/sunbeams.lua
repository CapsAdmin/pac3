do return end
local PART = {}

PART.ClassName = "trail"

pac.StartStorableVars()
	pac.GetSet(PART, "Length", 100)
	pac.GetSet(PART, "StartSize", 3)
	pac.GetSet(PART, "Color", Vector(255, 255, 255))
	pac.GetSet(PART, "Alpha", 1)
	pac.GetSet(PART, "TrailPath", "trails/laser")
pac.EndStorableVars()

function PART:SetColor(v)
	self.ColorC = self.ColorC or Color(255, 255, 255, 255)
	
	self.ColorC.r = v.r
	self.ColorC.g = v.g
	self.ColorC.b = v.b
end

function PART:SetAlpha(n)
	self.ColorC = self.ColorC or Color(255, 255, 255, 255)
	
	self.ColorC.a = n * 255
end

function PART:Initialize()
	self:SetTrailPath(self.TrailPath)
end

function PART:SetTrailPath(var)
	self:SetMaterial(var)
	self:SetTooltip(var)
end

function PART:SetMaterial(var)
	if type(var) == "string" then
		self.Trail = Material(var)
	elseif type(var) == "IMaterial" then
		self.Trail = var
	end

	self.TrailPath = var
end

function PART:OnDraw(owner, pos, ang)
	if self.Trail then
		self.traildata = self.traildata or {}
		self.traildata.points = self.traildata.points or {}

		table.insert(self.traildata.points, pos)
		if #self.traildata.points > self.Length then 
			table.remove(self.traildata.points, #self.traildata.points - self.Length) 
		end
		render.SetMaterial(self.Trail)
		render.StartBeam(#self.traildata.points-1)
			for k,v in pairs(self.traildata.points) do
				width = k / (self.Length / self.StartSize)
				render.AddBeam(v, width, width, self.Color)
			end
		render.EndBeam()
	end
end

function PART:OnRestore(data)
	self:SetMaterial(data.TrailPath)
end

pac.RegisterPart(PART)