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
	:GetSet("FlexWeights", "", {hidden = true})
	:GetSet("Scale", 1)
	:GetSet("Additive", false)
:EndStorableVars()


-- Make the internal flex names be more presentable, TODO: handle numbers
local function PrettifyName( name )
	name = name:Replace( "_", " " )

	-- Try to split text into words, where words would start with single uppercase character
	local newParts = {}
	for id, str in pairs( string.Explode( " ", name ) ) do
		local wordStart = 1
		for i = 2, str:len() do
			local c = str[ i ]
			if ( c:upper() == c ) then
				local toAdd = str:sub(wordStart, i - 1)
				if ( toAdd:upper() == toAdd ) then continue end
				table.insert( newParts, toAdd )
				wordStart = i
			end

		end

		table.insert( newParts, str:sub(wordStart, str:len()))
	end

	-- Uppercase all first characters
	for id, str in pairs( newParts ) do
		if ( str:len() < 2 ) then continue end
		newParts[ id ] = str:Left( 1 ):upper() .. str:sub( 2 )
	end

	return table.concat( newParts, " " )
end


function PART:GetDynamicProperties()
	local ent = self:GetOwner()
	if not ent:IsValid() then return end
	if ent.GetFlexNum and ent:GetFlexNum() and ent:GetFlexNum() == 0 then return end

	local tbl = {}

	for i = 0, ent:GetFlexNum() - 1 do
		local name = ent:GetFlexName(i)

		tbl[name] = {
			key = name,
			sort_key = -i,
			get = function()
				local weight_map = util.JSONToTable(self:GetFlexWeights()) or {}

				return weight_map[name] or 0
			end,
			set = function(val)
				local weight_map = util.JSONToTable(self:GetFlexWeights()) or {}

				weight_map[name] = tonumber(val) or 0

				self:SetFlexWeights(util.TableToJSON(weight_map))
			end,
			udata = {
				editor_friendly = PrettifyName(name),
				group = "flexes",
				editor_sensitivity = 0.1,
				editor_onchange = function(self, num)
					local min, max = ent:GetFlexBounds(i)

					return math.Clamp(num, min, max)
				end,
			},
		}
	end

	return tbl
end

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
	ent.pac_touching_flexes = ent.pac_touching_flexes or {}

	for name, weight in pairs(self:GetWeightMap()) do
		local id = ent:GetFlexIDByName(name)
		if id then
			if self.Additive then
				weight = ent:GetFlexWeight(id) + weight
			end
			ent:SetFlexWeight(id, weight)
			ent.pac_touching_flexes[id] = pac.RealTime + 0.1
		end
	end
end

function PART:OnThink()
	local ent = self:GetOwner()
	if not ent:IsPlayer() then
		self:UpdateFlex()
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

BUILDER:Register()
