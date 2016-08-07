local PART = {}

PART.ClassName = "clip"

function PART:OnParent(part)
	part:AddModifier(self)

	-- this is only really for halos..
	if IsEntity(part.Entity) and part.Entity:IsValid() then
		function part.Entity.pacDrawModel(ent)
			self:PreOnDraw()
			ent:DrawModel()
			self:PostOnDraw()
		end
	end
end

function PART:OnUnParent(part)
	if not part:IsValid() then return end
	part:RemoveModifier(self)
end

local render_EnableClipping = render.EnableClipping
local render_PushCustomClipPlane = render.PushCustomClipPlane
local LocalToWorld = LocalToWorld
local bclip

function PART:PreOnDraw()
	bclip = render_EnableClipping(true)

	local pos, ang = LocalToWorld(self.Position, self:CalcAngles(self.Angles), self:GetBonePosition())
	local normal = ang:Forward()

	render_PushCustomClipPlane(normal, normal:Dot(pos + normal))
end

local render_PopCustomClipPlane = render.PopCustomClipPlane

function PART:PostOnDraw()
	render_PopCustomClipPlane()

	render_EnableClipping(bclip)
end

pac.RegisterPart(PART)