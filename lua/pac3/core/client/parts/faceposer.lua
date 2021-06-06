local PART = {}

PART.ClassName = "faceposer"
PART.FriendlyName = "face poser"
PART.NonPhysical = true
PART.Icon = 'icon16/monkey.png'
PART.Group = 'entity'

pac.StartStorableVars()
	pac.GetSet(PART, "FlexWeights", "", {editor_panel = "flex_weights"})
	pac.GetSet(PART, "Scale", 1)
pac.EndStorableVars()

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
		if id then
			ent:SetFlexWeight(id, ent:GetFlexWeight(id) + weight)
		end
	end
end

function PART:OnBuildBonePositions()
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

pac.RegisterPart(PART)
