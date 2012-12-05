local PART = {}

PART.ClassName = "trail"

pac.StartStorableVars()
	pac.GetSet(PART, "Length", 100)
	pac.GetSet(PART, "Spacing", 1)
	pac.GetSet(PART, "StartSize", 3)
	pac.GetSet(PART, "EndSize", 0)
	pac.GetSet(PART, "StartColor", Vector(255, 255, 255))
	pac.GetSet(PART, "EndColor", Vector(255, 255, 255))
	pac.GetSet(PART, "StartAlpha", 1)
	pac.GetSet(PART, "EndAlpha", 1)
	pac.GetSet(PART, "Stretch", false)
	pac.GetSet(PART, "TrailPath", "trails/laser")
pac.EndStorableVars()

PART.LastAdd = 0

function PART:Initialize()
	self:SetTrailPath(self.TrailPath)
end

function PART:SetStartColor(v)
	self.StartColorC = self.StartColorC or Color(255, 255, 255, 255)
	
	self.StartColorC.r = v.r
	self.StartColorC.g = v.g
	self.StartColorC.b = v.b
	
	self.StartColor = v
end

function PART:SetEndColor(v)
	self.EndColorC = self.EndColorC or Color(255, 255, 255, 255)
	
	self.EndColorC.r = v.r
	self.EndColorC.g = v.g
	self.EndColorC.b = v.b
	
	self.EndColor = v
end

function PART:SetStartAlpha(n)
	self.StartColorC = self.StartColorC or Color(255, 255, 255, 255)
	
	self.StartColorC.a = n * 255
	
	self.StartAlpha = n
end

function PART:SetEndAlpha(n)
	self.EndColorC = self.EndColorC or Color(255, 255, 255, 255)
	
	self.EndColorC.a = n * 255
	
	self.EndAlpha = n
end

function PART:SetTrailPath(var)
	self:SetMaterial(var)
end

function PART:SetMaterial(var)
	var = var or ""
	
	if not pac.Handleurltex(self, var) then
		if type(var) == "string" then
			self.Materialm = Material(var)
			self:CallEvent("material_changed")
		elseif type(var) == "IMaterial" then
			self.Materialm = var
			self:CallEvent("material_changed")
		end
	end

	self.TrailPath = var
end

function PART:OnAttach()
	self.points = {}
end

function PART:OnDetach()
	self.points = {}
end

local Lerp = Lerp
local RealTime = RealTime
local tonumber = tonumber
local table_insert = table.insert
local table_remove = table.remove
local math_ceil = math.ceil
local math_abs = math.abs
local render_StartBeam = render.StartBeam
local render_EndBeam = render.EndBeam
local render_AddBeam = render.AddBeam
local render_MaterialOverride = render.SetMaterial

function PART:OnDraw(owner, pos, ang)
	if self.Materialm and self.StartColorC and self.EndColorC then
		self.points = self.points or {}
		
		local len = tonumber(self.Length)
		local spc = tonumber(self.Spacing)
		
		if spc == 0 or self.LastAdd < RealTime() then
			table_insert(self.points, pos)
			self.LastAdd = RealTime() + spc / 1000
		end
		
		local count = #self.points
		
		if spc > 0 then
			len = math_ceil(math_abs(len - spc))
		end
				
		render_MaterialOverride(self.Materialm)
		
		local delta = FrameTime() * 5
		
		render_StartBeam(count)
			for k, v in pairs(self.points) do
				width = k / (len / self.StartSize)
				
				local coord = (1/count) * (k - 1)
				local color = Color(255, 255, 255, 255)
				
				color.r = Lerp(coord, self.EndColorC.r, self.StartColorC.r)
				color.g = Lerp(coord, self.EndColorC.g, self.StartColorC.g)
				color.b = Lerp(coord, self.EndColorC.b, self.StartColorC.b)
				color.a = Lerp(coord, self.EndColorC.a, self.StartColorC.a)
								
				render_AddBeam(k == count and pos or v, width + self.EndSize, self.Stretch and coord or width, color)
			end
		render_EndBeam()		
		
		if count >= len then 
			table_remove(self.points, 1) 
		end
	end
end

pac.RegisterPart(PART)