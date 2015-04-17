local PART = {}

PART.ClassName = "flex"
PART.NonPhysical = true

pac.StartStorableVars()
	pac.GetSet(PART, "Flex", "")
	pac.GetSet(PART, "Weight", 0)
	pac.GetSet(PART, "RootOwner", true)
	pac.GetSet(PART, "DefaultOnHide", true)
pac.EndStorableVars()

function PART:GetNiceName()
	return self:GetFlexName() or "no flex"
end

function PART:GetFlexName()
	local name
	local owner = self:GetOwner(self.RootOwner)
	if not owner:IsValid() then return end
	local flex = self:ResolveFlex(self:GetFlex())
	if flex ~= -1 and (owner:GetFlexNum() > 0) then name = owner:GetFlexName(flex) end
	return name
end

function PART:Initialize()
	local owner = self:GetOwner(self.RootOwner)
	if not owner:IsValid() then return end
	
	if pac.TouchFlexes then pac.TouchFlexes(owner) end
	
	local t = {}
	for i=1,owner:GetFlexNum() do t[owner:GetFlexName(i)] = i end
	self.FlexList = t
end

function PART:UpdateFlex(flex,weight)
	flex = self:ResolveFlex(flex)
	local owner = self:GetOwner(self.RootOwner)
	if not owner:IsValid() then return end
	if not owner.GetFlexNum then return end
	if not (owner:GetFlexNum() > 0) then return end
	
	local count = owner:GetFlexNum()
	if flex % 1 ~= 0 then flex = math.floor(flex) end --if not integer then make integer
	if flex > count then flex = count end

	if flex < 0 then return end
	
	owner:SetFlexWeight(flex,weight)
end

function PART:ResolveFlex(str)
		
	local internal_flex = tonumber(str)
	
	if internal_flex == nil then --they entered a string
		if str == "" then internal_flex = -1
		else internal_flex = self.FlexList[str] or -1
		end
	end
	
	return internal_flex
end

function PART:SetFlex(flex)
	local oldflex = self.Flex
	self:UpdateFlex(oldflex, 0)
	
	self.Flex = flex
	
	self:UpdateFlex(flex, self:GetWeight())
	
	self:SetName(self:GetNiceName())
end

function PART:SetWeight(weight)
	self.Weight = weight
	
	self:UpdateFlex(self:GetFlex(), weight)
end

function PART:OnShow()
	self:UpdateFlex(self:GetFlex(), self:GetWeight())
end

function PART:OnHide(force)
	if self.DefaultOnHide or force then
		self:UpdateFlex(self:GetFlex(), 0)
	end
end

function PART:OnRemove() 
	self:OnHide(true)
end

function PART:Clear()
	self:RemoveChildren()
	self:UpdateFlex(self:GetFlex(), 0)
end

pac.RegisterPart(PART)

hook.Add("pac_EditorPostConfig","flex",function()
	pace.PartTree.entity.flex = true
	pace.PartIcons.flex = "icon16/emoticon_smile.png"
end)
