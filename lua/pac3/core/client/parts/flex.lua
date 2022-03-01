local BUILDER, PART = pac.PartTemplate("base")

PART.ClassName = "flex"

PART.Icon = 'icon16/emoticon_smile.png'
PART.Group = 'entity'

local function get_owner(self)
	if self.RootOwner then
		return self:GetRootPart():GetOwner()
	end

	return self:GetOwner()
end

BUILDER:StartStorableVars()
	BUILDER:GetSet("Flex", "", {
		enums = function(part)
			local tbl = {}

			for _, v in pairs(pac.GetFlexMap(get_owner(part))) do
				tbl[v.name] = v.name
			end

			return tbl
		end
	})

	BUILDER:GetSet("Weight", 0)
	BUILDER:GetSet("RootOwner", false, { description = "Target the local player instead of the part's parent" })
	BUILDER:GetSet("DefaultOnHide", true)
BUILDER:EndStorableVars()

function PART:GetNiceName()
	return self:GetFlex() ~= "" and self:GetFlex() or "no flex"
end

function PART:GetFlexID()
	local ent = get_owner(self)
	if not ent:IsValid() or not ent.GetFlexNum or ent:GetFlexNum() == 0 then return end

	local flex_map = pac.GetFlexMap(ent)
	local flex = flex_map[self.Flex:lower()]

	return flex and flex.i, ent
end

function PART:OnBuildBonePositions()
	local id, ent = self:GetFlexID()
	if not id then return end
	-- flexes are additive
	ent:SetFlexWeight(id, ent:GetFlexWeight(id) + self.Weight)
end

BUILDER:Register()
