local render_EnableClipping = render.EnableClipping
local render_PushCustomClipPlane = render.PushCustomClipPlane
local LocalToWorld = LocalToWorld
local IsEntity = IsEntity

local BUILDER, PART = pac.PartTemplate("base_drawable")

PART.FriendlyName = "clip"
PART.ClassName = "clip2"
PART.Groups = {'model', 'modifiers'}
PART.Icon = 'icon16/cut.png'

function PART:OnParent(part)
	if not part.AddModifier then return end
	part:AddModifier(self)


	-- this is only really for halos..
	local ent = self:GetOwner()

	if ent:IsValid() then
		function ent.pacDrawModel(ent)
			self:PreOnDraw()
			ent:DrawModel()
			self:PostOnDraw()
		end
	end
end

function PART:OnUnParent(part)
	if not part:IsValid() then return end
	if not part.RemoveModifier then return end

	part:RemoveModifier(self)
end

do
	local bclip

	function PART:PreOnDraw()
		bclip = render_EnableClipping(true)

		-- this fixes clip planes lagging behind when parented to a bone on a model part
		local owner = self:GetParentOwner()
		if owner:IsValid() and owner.PACPart then
			pac.SetupBones(owner)
		end

		local pos, ang = LocalToWorld(self.Position + self.PositionOffset, self:CalcAngles(self.Angles + self.AngleOffset), self:GetBonePosition())
		local normal = ang:Forward()

		render_PushCustomClipPlane(normal, normal:Dot(pos))
	end

	local render_PopCustomClipPlane = render.PopCustomClipPlane

	function PART:PostOnDraw()
		render_PopCustomClipPlane()

		render_EnableClipping(bclip)
	end
end

BUILDER:Register()