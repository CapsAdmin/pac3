local MATERIAL_FOG_NONE = MATERIAL_FOG_NONE
local MATERIAL_FOG_LINEAR = MATERIAL_FOG_LINEAR
local MATERIAL_FOG_LINEAR_BELOW_FOG_Z = MATERIAL_FOG_LINEAR_BELOW_FOG_Z
local render_FogStart = render.FogStart
local render_FogEnd = render.FogEnd
local render_FogMaxDensity = render.FogMaxDensity
local render_SetFogZ = render.SetFogZ
local render_FogMode = render.FogMode

local BUILDER, PART = pac.PartTemplate("base_drawable")

PART.ClassName = "fog"

PART.Group = 'modifiers'
PART.Icon = 'icon16/weather_clouds.png'

BUILDER:StartStorableVars()
	BUILDER:GetSet("Color", Vector(255, 255, 255), {editor_panel = "color"})
	BUILDER:GetSet("Start", 0)
	BUILDER:GetSet("End", 10)
	BUILDER:GetSet("Alpha", 1, {editor_sensitivity = 0.25, editor_clamp = {0, 1}})
	--BUILDER:GetSet("AffectChildren", false)
	BUILDER:GetSet("Height", 0)
BUILDER:EndStorableVars()

function PART:GetNiceName()
	local h = pac.ColorToNames(self:GetColor())

	return h .. " fog"
end

function PART:SetColor(v)
	self.Color = v

	self.clr = {v.r, v.g, v.b}
end

function PART:OnParent(part)
	if part.AddModifier then
		part:AddModifier(self)
	end
end

function PART:OnUnParent(part)
	if not part:IsValid() then return end
	if part.RemoveModifier then
		part:RemoveModifier(self)
	end
end

function PART:PreOnDraw()
	render_FogStart(self.Start * 100)
	render_FogEnd(self.End * 100)
	render_FogMaxDensity(self.Alpha)
	if self.clr then render.FogColor(self.clr[1], self.clr[2], self.clr[3]) end

	if self.Height > 0 then
		render_FogMode(MATERIAL_FOG_LINEAR_BELOW_FOG_Z)
		render_SetFogZ(self:GetWorldPosition().z + self.Height * 10)
	else
		render_FogMode(MATERIAL_FOG_LINEAR)
	end
end


function PART:PostOnDraw()
	render.FogMode(MATERIAL_FOG_NONE)
end

BUILDER:Register()