--!lc util.DecalEx(Material("sprites/key_0"), this:IsValid() and this or Entity(0), there + trace.Normal, -trace.HitNormal, Color(255,255,255,255), 0.5,0.5)

local PART = {}

PART.ClassName = "decal"

pac.StartStorableVars()
	pac.GetSet(PART, "Color", Vector(255, 255, 255))
	--pac.GetSet(PART, "Width", 1)
	--pac.GetSet(PART, "Height", 1)
	pac.GetSet(PART, "Alpha", 1)
	pac.GetSet(PART, "Material", "")
	pac.GetSet(PART, "IgnoreOwner", true)
pac.EndStorableVars()

function PART:SetMaterial(var)
	self.Material = var
	if not pac.Handleurltex(self, var) then
		self.Materialm = pac.Material(var, self)
		self:CallEvent("material_changed")
	end
end

function PART:OnShow()
	local pos, ang = self:GetDrawPosition()
	self.cached_pos = pos
	self.cached_ang = ang
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

pac.RegisterPart(PART)