local Color = Color
local Vector = Vector

local BUILDER, PART = pac.PartTemplate("base_drawable")

PART.ClassName = "halo"

PART.ThinkTime = 0
PART.Group = {'effects', 'model'}
PART.Icon = 'icon16/shading.png'

BUILDER:StartStorableVars()
	BUILDER:SetPropertyGroup()
		BUILDER:GetSet("BlurX", 2)
		BUILDER:GetSet("BlurY", 2)
		BUILDER:GetSet("Amount", 1)
		BUILDER:GetSet("IgnoreZ", false)
		BUILDER:GetSet("SphericalSize", 1)
		BUILDER:GetSet("Shape", 1)
		BUILDER:GetSet("AffectChildren", false)

	BUILDER:SetPropertyGroup("appearance")
		BUILDER:GetSet("Color", Vector(255, 255, 255), {editor_panel = "color"})
		BUILDER:GetSet("Passes", 1)
		BUILDER:GetSet("Additive", true) -- haaaa
BUILDER:EndStorableVars()

function PART:GetNiceName()
	local h = pac.ColorToNames(self:GetColor())

	return h .. " halo"
end

function PART:SetShape(n)
	self.Shape = math.Clamp(n, 0, 1)
end

function PART:SetPasses(n)
	self.Passes = math.min(n, 50)
end

function PART:OnThink()
	local parent = self:GetParent()

	if parent.is_model_part and parent.Entity:IsValid() then
		local tbl = {parent.Entity}

		if self.AffectChildren then
			for _, part in ipairs(parent:GetChildren()) do
				if part.is_model_part and part.Entity:IsValid() and not part:IsHidden() then
					table.insert(tbl, part.Entity)
				end
			end
		end

		pac.haloex.Add(tbl, Color(self.Color.r, self.Color.g, self.Color.b), self.BlurX, self.BlurY, self.Passes, self.Additive, self.IgnoreZ, self.Amount, self.SphericalSize, self.Shape)
	end
end

BUILDER:Register()