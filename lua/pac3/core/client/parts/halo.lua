local PART = {}

PART.ClassName = "halo"
PART.NonPhysical = true
PART.ThinkTime = 0

pac.StartStorableVars()
	pac.GetSet(PART, "Color", Vector(255, 255, 255))
	pac.GetSet(PART, "BlurX", 2)
	pac.GetSet(PART, "BlurY", 2)
	pac.GetSet(PART, "Passes", 1)
	pac.GetSet(PART, "Additive", true) -- haaaa
	pac.GetSet(PART, "IgnoreZ", false)
	pac.GetSet(PART, "Children", false)
pac.EndStorableVars()

function PART:OnThink()
	local parent = self:GetParent()
	if parent.ClassName == "model" and parent.Entity:IsValid() and not parent:IsHiddenEx() then
		local tbl = {parent.Entity}
		
		if self.Children then
			for key, part in pairs(parent:GetChildren()) do
				if parent.ClassName == "model" and parent.Entity:IsValid() and not parent:IsHiddenEx() then
					table.insert(tbl, parent.Entity)
				end
			end
		end
		
		halo.Add(tbl, Color(self.Color.r, self.Color.g, self.Color.b), self.BlurX, self.BlurY, self.Passes, self.Additive, self.IgnoreZ)
	end
end

pac.RegisterPart(PART)