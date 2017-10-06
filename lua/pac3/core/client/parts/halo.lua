local Color = Color
local Vector = Vector

local PART = {}

PART.ClassName = "halo"
PART.NonPhysical = true
PART.ThinkTime = 0
PART.Group = {'effects', 'model'}
PART.Icon = 'icon16/shading.png'

pac.StartStorableVars()
	pac.SetPropertyGroup()
		pac.GetSet(PART, "BlurX", 2)
		pac.GetSet(PART, "BlurY", 2)
		pac.GetSet(PART, "Amount", 1)
		pac.GetSet(PART, "IgnoreZ", false)
		pac.GetSet(PART, "SphericalSize", 1)
		pac.GetSet(PART, "Shape", 1)
		pac.GetSet(PART, "AffectChildren", false)

	pac.SetPropertyGroup(PART, "appearance")
		pac.GetSet(PART, "Color", Vector(255, 255, 255), {editor_panel = "color"})
		pac.GetSet(PART, "Passes", 1)
		pac.GetSet(PART, "Additive", true) -- haaaa
pac.EndStorableVars()

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

pac.RegisterPart(PART)