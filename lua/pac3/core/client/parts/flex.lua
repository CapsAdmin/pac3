local BUILDER, PART = pac.PartTemplate("base")

PART.ClassName = "flex"

PART.Icon = 'icon16/emoticon_smile.png'
PART.Group = 'entity'

BUILDER:StartStorableVars()
	BUILDER:GetSet("Flex", "", {
		enums = function(part)
			local tbl = {}

			for _, v in pairs(pac.GetFlexMap(part:GetOwner())) do
				tbl[v.name] = v.name
			end

			return tbl
		end
	})

	BUILDER:GetSet("Weight", 0)
	BUILDER:GetSet("Additive", false)
	BUILDER:GetSet("RootOwner", false, { hide_in_editor = true })
BUILDER:EndStorableVars()

function PART:SetRootOwner(b)
	self:SetRootOwnerDeprecated(b)
end

function PART:GetNiceName()
	return self:GetFlex() ~= "" and self:GetFlex() or "no flex"
end

function PART:GetFlexID()
	local ent = self:GetOwner()
	if not ent:IsValid() or not ent.GetFlexNum or ent:GetFlexNum() == 0 then return end

	local flex_map = pac.GetFlexMap(ent)
	local flex = flex_map[self.Flex:lower()]

	return flex and flex.i, ent
end

function PART:OnBuildBonePositions()
	local id, ent = self:GetFlexID()
	if not id then return end
	local weight = self.Weight
	if self.Additive then
		weight = weight + ent:GetFlexWeight(id)
	end
	ent:SetFlexWeight(id, weight)
	ent.pac_touching_flexes = ent.pac_touching_flexes or {}
	ent.pac_touching_flexes[id] = pac.RealTime + 0.1
end

BUILDER:Register()
