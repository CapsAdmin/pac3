local BUILDER, PART = pac.PartTemplate("base")

PART.ClassName = "faceposer"

PART.FriendlyName = "face poser"
PART.Icon = 'icon16/monkey.png'
PART.Group = 'entity'

BUILDER:StartStorableVars()
	:GetSet("FlexWeights", "", {editor_panel = "flex_weights"})
	:GetSet("Scale", 1)
:EndStorableVars()

function PART:GetNiceName()
	return "face pose"
end

function PART:GetWeightMap()
	local data = self:GetFlexWeights()

	if data ~= self.last_data then
		self.weight_map = util.JSONToTable(data) or {}
		self.last_data = data
	end

	return self.weight_map
end

function PART:UpdateFlex()
	local ent = self:GetOwner()
	if not ent:IsValid() then return end

	ent:SetFlexScale(self.Scale)

	for name, weight in pairs(self:GetWeightMap()) do
		local id = ent:GetFlexIDByName(name)
		ent:SetFlexWeight(id, ent:GetFlexWeight(id) + weight)
	end
end

function PART:BuildBonePositions()
	self:UpdateFlex()
end

function PART:OnShow(from_rendering)
	self:UpdateFlex()
end

function PART:OnHide()
	self:UpdateFlex()
end

function PART:OnRemove()
	self:UpdateFlex()
end

BUILDER:Register()
