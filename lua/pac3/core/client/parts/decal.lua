--!lc util.DecalEx(Material("sprites/key_0"), this:IsValid() and this or Entity(0), there + trace.Normal, -trace.HitNormal, Color(255,255,255,255), 0.5,0.5)

local BUILDER, PART = pac.PartTemplate("base_movable")

PART.ClassName = "decal"
PART.Group = 'effects'
PART.Icon = 'icon16/paintbrush.png'

BUILDER:StartStorableVars()
	BUILDER:GetSet("Color", Vector(255, 255, 255), {editor_panel = "color"})
	--BUILDER:GetSet("Width", 1)
	--BUILDER:GetSet("Height", 1)
	BUILDER:GetSet("Alpha", 1, {editor_sensitivity = 0.25, editor_clamp = {0, 1}})
	BUILDER:GetSet("Material", "")
	BUILDER:GetSet("IgnoreOwner", true)
BUILDER:EndStorableVars()

function PART:SetMaterial(var)
	self.Material = var
	if not pac.Handleurltex(self, var) then
		self.Materialm = pac.Material(var, self)
		self:CallRecursive("OnMaterialChanged")
	end
end

function PART:OnShow()
	local pos, ang = self:GetDrawPosition()
	if self.Materialm then
		local filter
		if self.IgnoreOwner then
			filter = ents.FindInSphere(pos, 100)
		end
		local data = util.TraceLine({start = pos, endpos = pos + (ang:Forward() * 1000), filter = filter})

		if data.Hit then

			util.DecalEx(
				self.Materialm,
				data.Entity:IsValid() and data.Entity or Entity(0),
				data.HitPos + data.Normal,
				-data.HitNormal,
				Color(self.Color.x, self.Color.y, self.Color.z, self.Alpha*255),
				1, 1 -- they don't do anything?
			)
		end
	end
end

BUILDER:Register()