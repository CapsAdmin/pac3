local render_EnableClipping = render.EnableClipping
local render_PushCustomClipPlane = render.PushCustomClipPlane
local LocalToWorld = LocalToWorld
local IsEntity = IsEntity

local PART = {}

PART.ClassName = "clip"
PART.Groups = {'model', 'modifiers'}
PART.Icon = 'icon16/cut.png'

pac.SetPropertyGroup(PART, "generic")
	pac.PropertyOrder(PART, "Name")
	pac.PropertyOrder(PART, "Hide")
	pac.PropertyOrder(PART, "ParentName")

pac.RemoveProperty(PART, "IgnoreZ")
pac.RemoveProperty(PART, "BlendMode")
pac.RemoveProperty(PART, "NoTextureFiltering")


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

do
	local bclip

	function PART:PreOnDraw()
		bclip = render_EnableClipping(true)

		local pos, ang = LocalToWorld(self.Position + self.PositionOffset, self:CalcAngles(self.Angles + self.AngleOffset), self:GetBonePosition())
		local normal = ang:Forward()

		render_PushCustomClipPlane(normal, normal:Dot(pos + normal))
	end

	local render_PopCustomClipPlane = render.PopCustomClipPlane

	function PART:PostOnDraw()
		render_PopCustomClipPlane()

		render_EnableClipping(bclip)
	end
end

pac.RegisterPart(PART)