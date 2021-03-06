local Lerp = Lerp
local tonumber = tonumber
local table_insert = table.insert
local table_remove = table.remove
local math_ceil = math.ceil
local math_abs = math.abs
local math_min = math.min
local render_StartBeam = render.StartBeam
local cam_IgnoreZ = cam.IgnoreZ
local render_EndBeam = render.EndBeam
local render_AddBeam = render.AddBeam
local render_SetMaterial = render.SetMaterial
local Vector = Vector
local RealTime = RealTime

local temp_color = Color(255, 255, 255)

function pac.DrawTrail(self, len, spc, pos, ang, mat, scr,scg,scb,sca, ecr,ecg,ecb,eca, start_size, end_size, stretch)
	self.trail_points = self.trail_points or {}
	local points = self.trail_points

	if pac.drawing_motionblur_alpha then
		local a = pac.drawing_motionblur_alpha
		self.trail_points_motionblur = self.trail_points_motionblur or {}
		self.trail_points_motionblur[a] = self.trail_points_motionblur[a] or {}
		points = self.trail_points_motionblur[a]
	end

	local time = RealTime()

	if not points[1] or points[#points].pos:Distance(pos) > spc then
		table_insert(points, {pos = pos * 1, life_time = time + len})
	end

	local count = #points

	render_SetMaterial(mat)

	render_StartBeam(count)
		for i = #points, 1, -1 do
			local data = points[i]

			local f = (data.life_time - time)/len
			local f2 = f
			f = -f+1

			local coord = (1 / count) * (i - 1)

			temp_color.r = math_min(Lerp(coord, ecr, scr), 255)
			temp_color.g = math_min(Lerp(coord, ecg, scg), 255)
			temp_color.b = math_min(Lerp(coord, ecb, scb), 255)
			temp_color.a = math_min(Lerp(coord, eca, sca), 255)

			render_AddBeam(data.pos, (f * start_size) + (f2 * end_size), coord * stretch, temp_color)

			if f >= 1 then
				table_remove(points, i)
			end
		end
	render_EndBeam()

	if self.CenterAttraction ~= 0 then
		local attraction = FrameTime() * self.CenterAttraction
		local center = Vector(0,0,0)
		for _, data in ipairs(points) do
			center:Zero()
			for _, data in ipairs(points) do
				center:Add(data.pos)
			end
			center:Mul(1 / #points)
			center:Sub(data.pos)
			center:Mul(attraction)

			data.pos:Add(center)
		end
	end

	if not self.Gravity:IsZero() then
		local gravity = self.Gravity * FrameTime()
		gravity:Rotate(ang)
		for _, data in ipairs(points) do
			data.pos:Add(gravity)
		end
	end
end

local PART = {}

PART.FriendlyName = "trail"
PART.ClassName = "trail2"
PART.Icon = 'icon16/arrow_undo.png'
PART.Group = 'effects'
PART.ProperColorRange = true

pac.StartStorableVars()
	pac.GetSet(PART, "Duration", 1)
	pac.GetSet(PART, "Spacing", 0.25)
	pac.GetSet(PART, "StartSize", 3)
	pac.GetSet(PART, "EndSize", 0)
	pac.GetSet(PART, "StartColor", Vector(1, 1, 1), {editor_panel = "color2"})
	pac.GetSet(PART, "EndColor", Vector(1, 1, 1), {editor_panel = "color2"})
	pac.GetSet(PART, "StartAlpha", 1)
	pac.GetSet(PART, "EndAlpha", 0)
	pac.GetSet(PART, "Stretch", 1)
	pac.GetSet(PART, "CenterAttraction", 0)
	pac.GetSet(PART, "Gravity", Vector(0,0,0))
	pac.GetSet(PART, "IgnoreZ", false)
	pac.GetSet(PART, "TrailPath", "trails/laser", {editor_panel = "material"})
	pac.GetSet(PART, "Translucent", true)
pac.EndStorableVars()

function PART:GetNiceName()
	local str = pac.PrettifyName("/" .. self:GetTrailPath())
	local matched = str and str:match(".+/(.+)")
	return matched and matched:gsub("%..+", "") or "error"
end

PART.LastAdd = 0

function PART:Initialize()
	self:SetTrailPath(self.TrailPath)
end

function PART:SetTrailPath(var)
	self.TrailPath = var
	self:SetMaterial(var)
end

function PART:SetMaterial(var)
	var = var or ""

	if not pac.Handleurltex(self, var, function(mat)
		self.Materialm = mat
		self:MakeMaterialUnlit()
	end) then
		if type(var) == "string" then
			self.Materialm = pac.Material(var, self)
			self:CallEvent("material_changed")
		elseif type(var) == "IMaterial" then
			self.Materialm = var
			self:CallEvent("material_changed")
		end
		self:MakeMaterialUnlit()
	end
end

function PART:MakeMaterialUnlit()
	if not self.Materialm then return end

	local shader = self.Materialm:GetShader()
	if shader == "VertexLitGeneric" or shader == "Cable" or shader == "LightmappedGeneric" then
		self.Materialm = pac.MakeMaterialUnlitGeneric(self.Materialm, self.Id)
	end
end

function PART:OnShow()
	self.points = {}
end

function PART:OnHide()
	self.points = {}
end

function PART:OnDraw(owner, pos, ang)
	local mat = self.material_override and self.material_override[0][1] and self.material_override[0][1]:GetRawMaterial() or self.Materialm
	if not mat then return end
	pac.DrawTrail(
		self,
		math.min(self.Duration, 10),
		self.Spacing + (self.StartSize/10),
		pos,
		ang,
		mat,

		self.StartColor.x*255, self.StartColor.y*255, self.StartColor.z*255,self.StartAlpha*255,
		self.EndColor.x*255, self.EndColor.y*255, self.EndColor.z*255,self.EndAlpha*255,

		self.StartSize,
		self.EndSize,
		1/self.Stretch
	)
end

pac.RegisterPart(PART)