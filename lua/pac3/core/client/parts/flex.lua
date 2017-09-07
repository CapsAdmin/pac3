local PART = {}

PART.ClassName = "flex"
PART.NonPhysical = true
PART.Icon = 'icon16/emoticon_smile.png'
PART.Group = 'entity'

pac.StartStorableVars()
	pac.GetSet(PART, "Flex", "", {
		enums = function(part)
			local tbl = {}

			for _, v in pairs(part:GetFlexList()) do
				tbl[v.name] = v.name
			end

			return tbl
		end
	})

	pac.GetSet(PART, "Weight", 0)
	pac.GetSet(PART, "RootOwner", true)
	pac.GetSet(PART, "DefaultOnHide", true)
pac.EndStorableVars()

function PART:GetNiceName()
	return self:GetFlex() ~= "" and self:GetFlex() or "no flex"
end

function PART:GetFlexList()
	local out = {}

	local ent = self:GetOwner(self.RootOwner)

	if ent:IsValid() and ent.GetFlexNum and ent:GetFlexNum() > 0 then
		for i = 0, ent:GetFlexNum() - 1 do
			local name = ent:GetFlexName(i)
			out[name:lower()] = {i = i, name = name}
		end
	end

	return out
end

function PART:UpdateFlex(flex, weight)
	local ent = self:GetOwner(self.RootOwner)

	if ent:IsValid() and ent.GetFlexNum and ent:GetFlexNum() > 0 then
		ent.pac_flex_list = ent.pac_flex_list or self:GetFlexList()

		flex = flex or self.Flex
		weight = weight or self.Weight

		flex = flex:lower()
		flex = ent.pac_flex_list[flex] and ent.pac_flex_list[flex].i or tonumber(flex)

		if type(flex) == "number" then
			ent:SetFlexWeight(flex, weight)
		end
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
	local ent = self:GetOwner(self.RootOwner)

	if ent:IsValid() then
		pac.TouchFlexes(ent)
		self:UpdateFlex()
	end
end

function PART:OnHide(force)
	if self.DefaultOnHide or force then
		self:UpdateFlex(nil, 0)
	end
end

function PART:OnRemove()
	self:OnHide(true)
end

function PART:Clear()
	self:RemoveChildren()
	self:UpdateFlex(nil, 0)
end

pac.RegisterPart(PART)
