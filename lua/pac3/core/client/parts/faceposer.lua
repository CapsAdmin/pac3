local BUILDER, PART = pac.PartTemplate("base")

PART.ClassName = "faceposer"

PART.FriendlyName = "face poser"
PART.Icon = 'icon16/monkey.png'
PART.Group = 'entity'


BUILDER:StartStorableVars()
	:GetSet("Preset", "", {enums = function(part)
		local ent = part:GetOwner()
		if not ent:IsValid() then return end

		local maps = {}

		local toolgun = {}
		for i = 0, 255 do
			local name = ent:GetFlexName(i)
			if name then
				toolgun[name] = GetConVar("faceposer_flex" .. i):GetFloat()
			end
		end

		maps.toolgun = util.TableToJSON({
			scale = GetConVar("faceposer_scale"):GetFloat(),
			weight_map = util.TableToJSON(toolgun),
		})

		for preset_name, map in pairs(presets.GetTable( "face" )) do
			local preset = {}
			for key, weight in pairs(map) do
				local i = tonumber(key:match("faceposer_flex(%d+)"))
				if i then
					local name = ent:GetFlexName(i)
					if name then
						preset[name] = tonumber(weight)
					end
				end
			end

			maps[preset_name] = util.TableToJSON({
				scale = tonumber(map.faceposer_scale),
				weight_map = util.TableToJSON(preset),
			})
		end

		return maps
	end})
	:GetSet("FlexWeights", "", {editor_panel = "flex_weights"})
	:GetSet("Scale", 1)
:EndStorableVars()

function PART:SetPreset(json)
	local preset = util.JSONToTable(json)
	if preset then
		self:SetFlexWeights(preset.weight_map)
		self:SetScale(preset.scale)
	end
	self.Preset = ""
end

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
