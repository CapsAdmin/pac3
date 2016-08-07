local PART = {}

PART.ClassName = "fog"
PART.NonPhysical = true

pac.StartStorableVars()
	pac.GetSet(PART, "Color", Vector(255, 255, 255))
	pac.GetSet(PART, "Start", 0)
	pac.GetSet(PART, "End", 10)
	pac.GetSet(PART, "Alpha", 1)
	--pac.GetSet(PART, "AffectChildren", false)
	pac.GetSet(PART, "Height", 0)
pac.EndStorableVars()

function PART:GetNiceName()
	local h,s,v = pac.ColorToNames(self:GetColor())

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

function PART:PreOnDraw(owner, pos)
	render.FogStart(self.Start*100)
	render.FogEnd(self.End*100)
	render.FogMaxDensity(self.Alpha)
	if self.clr then render.FogColor(unpack(self.clr)) end

	if self.Height > 0 then
		render.FogMode(MATERIAL_FOG_LINEAR_BELOW_FOG_Z)
		render.SetFogZ(self.cached_pos.z + self.Height * 10)
	else
		render.FogMode(MATERIAL_FOG_LINEAR)
	end
end


function PART:PostOnDraw()
	render.FogMode(MATERIAL_FOG_NONE)
end

pac.RegisterPart(PART)