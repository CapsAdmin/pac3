local BUILDER, PART = pac.PartTemplate("base")

PART.ClassName = "flex"

PART.Icon = 'icon16/emoticon_smile.png'
PART.Group = 'entity'

BUILDER:StartStorableVars()
	BUILDER:GetSet("Flex", "", {
		enums = function(part)
			local tbl = {}

			for _, v in pairs(part:GetFlexMap()) do
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
		return self:GetRootPart():GetOwner()
	end

	return self:GetOwner()
end

function PART:GetNiceName()
	return self:GetFlex() ~= "" and self:GetFlex() or "no flex"
end

function PART:GetFlexMap()
	local ent = get_owner(self)

	if self.last_owner ~= ent then
		self.last_owner = ent
		self.cached_flex_map = nil
	end

	if self.cached_flex_map then
		return self.cached_flex_map
	end

	local out = {}

	if self.last_owner ~= ent then
		self.last_owner = ent
		self.cached_flex_map = nil
	end

	if self.cached_flex_map then
		return self.cached_flex_map
	end

	local out = {}

	if ent:IsValid() and ent.GetFlexNum and ent:GetFlexNum() > 0 then
		for i = 0, ent:GetFlexNum() - 1 do
			local name = ent:GetFlexName(i)
			out[name:lower()] = {i = i, name = name}
		end
	end

	self.cached_flex_map = out

	return out
end

function PART:UpdateFlex()
	local ent = get_owner(self)
	if not ent:IsValid() or not ent.GetFlexNum or ent:GetFlexNum() == 0 then return end

	local name = self.Flex:lower()
	local weight = self.Weight

	local flex_map = self:GetFlexMap()

	if not flex_map[name] then
		return
	end

	local id = flex_map[name].i

	ent:SetFlexWeight(id, ent:GetFlexWeight(id) + weight)
end

function PART:OnBuildBonePositions()
	self:UpdateFlex()
end

function PART:SetFlex(num)
	self.Flex = num
	self:UpdateFlex()
end

function PART:SetWeight(num)
	self.Weight = num
	self:UpdateFlex()
end

function PART:OnShow(from_rendering)
	--if from_rendering then return end

	self:UpdateFlex()
end

function PART:OnHide()
	if self.DefaultOnHide then
		self:UpdateFlex()
	end
end

function PART:OnRemove()
	self:UpdateFlex()
end

BUILDER:Register()
