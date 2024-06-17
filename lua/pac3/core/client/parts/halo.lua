local Color = Color
local Vector = Vector
local table_insert = table.insert

local BUILDER, PART = pac.PartTemplate("base")

PART.ClassName = "halo"

PART.ThinkTime = 0
PART.Group = {"effects", "model"}
PART.Icon = "icon16/shading.png"

BUILDER:StartStorableVars()
	BUILDER:SetPropertyGroup("generic")
	BUILDER:SetPropertyGroup("appearance")
		BUILDER:GetSet("BlurX", 2)
		BUILDER:GetSet("BlurY", 2)
		BUILDER:GetSet("Amount", 1)
		BUILDER:GetSet("Passes", 1)
		BUILDER:GetSet("SphericalSize", 1)
		BUILDER:GetSet("Shape", 1)
		BUILDER:GetSet("Color", Vector(255, 255, 255), {editor_panel = "color"})
		BUILDER:GetSet("Additive", true)
		BUILDER:GetSet("IgnoreZ", false)
		BUILDER:GetSet("AffectChildren", false)
		BUILDER:GetSet("AffectTargetChildren", false)
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

function PART:SetColor(v)
	self.ColorC = self.ColorC or Color(255, 255, 255, 255)

	self.ColorC.r = v.r
	self.ColorC.g = v.g
	self.ColorC.b = v.b

	self.Color = v
end

function PART:GetTarget()
	local parent = self:GetTargetEntity()

	if parent:IsValid() then
		return parent
	end

	return self:GetParent()
end

function PART:OnThink()
	local tbl = {}

	local ent = self:GetOwner()
	if ent:IsValid() then
		tbl[1] = ent
	end

	local target = self:GetTarget()

	local children

	if self.AffectTargetChildren and target:IsValid() then
		children = target:GetChildrenList()
		for i = 1, #children do
			local part = children[i]
			local ent = part:GetOwner()

			if ent:IsValid() and not part:IsHiddenCached() then
				table_insert(tbl, ent)
			end
		end
	end

	if self.AffectChildren then
		children = self:GetChildrenList()
		for i = 1, #children do
			local part = children[i]
			local ent = part:GetOwner()

			if ent:IsValid() and not part:IsHiddenCached() then
				table_insert(tbl, ent)
			end
		end
	end

	if not self.ColorC then
		self.ColorC = Color(self.Color.r, self.Color.g, self.Color.b)
	end

	pac.haloex.Add(tbl, self.ColorC, self.BlurX, self.BlurY, self.Passes, self.Additive, self.IgnoreZ, self.Amount, self.SphericalSize, self.Shape)
end

BUILDER:Register()