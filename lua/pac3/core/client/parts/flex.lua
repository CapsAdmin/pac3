local BUILDER, PART = pac.PartTemplate("base")

PART.ClassName = "flex"

PART.Icon = 'icon16/emoticon_smile.png'
PART.Group = 'entity'

BUILDER:StartStorableVars()
	BUILDER:GetSet("Flex", "", {
		enums = function(part)
			local tbl = {}

			for _, v in pairs(part:GetFlexList()) do
				tbl[v.name] = v.name
			end

			return tbl
		end
	})

	BUILDER:GetSet("Weight", 0)
	BUILDER:GetSet("RootOwner", false, { description = "Target the local player instead of the part's parent" })
	BUILDER:GetSet("DefaultOnHide", true)
BUILDER:EndStorableVars()

local function get_owner(self)
	if self.RootOwner then
		return self:GetRootOwner()
	end

	return self:GetOwner()
end

function PART:GetNiceName()
	return self:GetFlex() ~= "" and self:GetFlex() or "no flex"
end

function PART:GetFlexList()
	local out = {}

	local ent = get_owner(self)

	if ent:IsValid() and ent.GetFlexNum and ent:GetFlexNum() > 0 then
		for i = 0, ent:GetFlexNum() - 1 do
			local name = ent:GetFlexName(i)
			out[name:lower()] = {i = i, name = name}
		end
	end

	return out
end

function PART:UpdateFlex(flex, weight)
	local ent = get_owner(self)
	if not ent:IsValid() or not ent.GetFlexNum or ent:GetFlexNum() == 0 then return end

	if self.flex_ent ~= ent then
		self.flex_ent = ent
		self.pac_flex_list = self:GetFlexList()
	end

	ent.pac_flex_params = ent.pac_flex_params or {}

	flex = flex or self.Flex
	weight = weight or self.Weight

	flex = flex:lower()
	flex = self.pac_flex_list[flex] and self.pac_flex_list[flex].i or tonumber(flex)

	if type(flex) == "number" then
		if weight ~= 0 then
			ent.pac_flex_params[flex] = weight
		else
			ent.pac_flex_params[flex] = nil
			ent:SetFlexWeight(flex, 0)

			if table.Count(ent.pac_flex_params) == 0 then ent.pac_flex_params = nil end
		end
	end

	self.flex_params = ent.pac_flex_params
end

function PART:OnDraw()
	if not IsValid(self.flex_ent) then return end

	for k, v in pairs(self.flex_params) do
		self.flex_ent:SetFlexWeight(k, v)
	end
end

function PART:OnBuildBonePositions()
	if not IsValid(self.flex_ent) then return end
	if not self.flex_params then return end

	for k, v in pairs(self.flex_params) do
		self.flex_ent:SetFlexWeight(k, v)
	end
end

function PART:SetFlex(num)
	self:UpdateFlex(self.Flex, 0)

	self.Flex = num
	self:UpdateFlex()
end

function PART:SetWeight(num)
	self.Weight = num
	self:UpdateFlex()
end

function PART:OnShow()
	local ent = get_owner(self)

	if ent:IsValid() then
		self:UpdateFlex()
	end
end

function PART:OnHide(force)
	if self.DefaultOnHide or force then
		self:UpdateFlex(self.Flex, 0)
	end
end

function PART:OnRemove()
	self:OnHide(true)
end

function PART:Clear()
	self:RemoveChildren()
	self:UpdateFlex(self.Flex, 0)
end

BUILDER:Register()
