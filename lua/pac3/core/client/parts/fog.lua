local MATERIAL_FOG_NONE = MATERIAL_FOG_NONE
local MATERIAL_FOG_LINEAR = MATERIAL_FOG_LINEAR
local MATERIAL_FOG_LINEAR_BELOW_FOG_Z = MATERIAL_FOG_LINEAR_BELOW_FOG_Z
local render_FogStart = render.FogStart
local render_FogEnd = render.FogEnd
local render_FogMaxDensity = render.FogMaxDensity
local render_SetFogZ = render.SetFogZ
local render_FogMode = render.FogMode

local PART = {}

PART.ClassName = "fog"
PART.NonPhysical = true
PART.Group = 'modifiers'
PART.Icon = 'icon16/weather_clouds.png'

pac.StartStorableVars()
	pac.GetSet(PART, "Color", Vector(255, 255, 255), {editor_panel = "color"})
	pac.GetSet(PART, "Start", 0)
	pac.GetSet(PART, "End", 10)
	pac.GetSet(PART, "Alpha", 1, {editor_sensitivity = 0.25, editor_clamp = {0, 1}})
	--pac.GetSet(PART, "AffectChildren", false)
	pac.GetSet(PART, "Height", 0)
pac.EndStorableVars()

function PART:GetNiceName()
	local h = pac.ColorToNames(self:GetColor())

	return h .. " fog"
end

function PART:SetColor(v)
	self.Color = v

	self.clr = {v.r, v.g, v.b}
end

function PART:OnParent(part)
	part:AddModifier(self)
end

function PART:OnUnParent(part)
	if not part:IsValid() then return end
	part:RemoveModifier(self)
end

function PART:PreOnDraw()
	render_FogStart(self.Start * 100)
	render_FogEnd(self.End * 100)
	render_FogMaxDensity(self.Alpha)
	if self.clr then render.FogColor(unpack(self.clr)) end

	if self.Height > 0 then
		render_FogMode(MATERIAL_FOG_LINEAR_BELOW_FOG_Z)
		render_SetFogZ(self.cached_pos.z + self.Height * 10)
	else
		render_FogMode(MATERIAL_FOG_LINEAR)
	end
end


function PART:PostOnDraw()
	render.FogMode(MATERIAL_FOG_NONE)
end

pac.RegisterPart(PART)