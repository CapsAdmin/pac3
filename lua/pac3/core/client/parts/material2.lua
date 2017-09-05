local shader_params = include("pac3/libraries/shader_params.lua")

local temp = CreateMaterial("pac3_dummy_mat", "vertexlitgeneric", {})


local function add_matrix(META, key)
	local position_key = key .. "Position"
	local scale_key = key .. "Scale"
	local angle_key = key .. "Angle"
	local angle_center_key = key .. "AngleCenter"

	pac.GetSet(META, position_key, Vector(0, 0, 0))
	pac.GetSet(META, scale_key, Vector(1, 1, 1))
	pac.GetSet(META, angle_key, 0)
	pac.GetSet(META, angle_center_key, Vector(0.5, 0.5, 0))

	local shader_key = "$" .. key

	local function setup_matrix(self)
		self.matrix = self.matrix or Matrix()
		self.translation_vector = self.translation_vector or Vector(0, 0, 0)
		self.rotation_angle = self.rotation_angle or Angle(0, 0, 0)

		self.matrix:Identity()
		self.matrix:Translate(self.translation_vector)

		self.matrix:Translate(self[angle_center_key])
		self.matrix:Rotate(self.rotation_angle)
		self.matrix:Translate(-self[angle_center_key])

		self.matrix:SetScale(self[scale_key])
	end

	META["Set" .. position_key] = function(self, vec)
		self[position_key] = vec
		setup_matrix(self)

		self.translation_vector.x = self[position_key].x
		self.translation_vector.y = self[position_key].y

		self.imaterial:SetMatrix(shader_key, self.matrix)
	end

	META["Set" .. scale_key] = function(self, vec)
		self[scale_key] = vec
		setup_matrix(self)

		self.imaterial:SetMatrix(shader_key, self.matrix)
	end

	META["Set" .. angle_key] = function(self, num)
		self[angle_key] = num
		setup_matrix(self)

		self.rotation_angle.y = self[angle_key]*360

		self.imaterial:SetMatrix(shader_key, self.matrix)
	end

	META["Set" .. angle_center_key] = function(self, vec)
		self[angle_center_key] = vec
		setup_matrix(self)

		self.imaterial:SetMatrix(shader_key, self.matrix)
	end

end

for shader_name, params in pairs(shader_params) do
	local PART = {}

	PART.ClassName = "material_" .. shader_name
	PART.NonPhysical = true
	PART.Group = {'modifiers', 'model', 'entity'}
	PART.Icon = 'icon16/paintcan.png'

	pac.StartStorableVars()

	local groups = {}
	local group_count = {}
	for key, info in pairs(params) do
		local friendly = (info.friendly or key):Trim()
		local group = friendly:match("^(%u.-)%u")
		if group then
			group = group:lower()
			group_count[group] = (group_count[group] or 0) + 1
			groups[key] = group
		end
	end

	for key, info in pairs(params) do
		if groups[key] and group_count[groups[key]] > 1 then
			pac.SetPropertyGroup(groups[key])
		elseif info.is_flag then
			pac.SetPropertyGroup("flags")
		end

		local friendly = (info.friendly or key):Trim()

		if info.type == "matrix" then
			add_matrix(PART, friendly)
		elseif info.type == "texture" then
			pac.GetSet(PART, friendly, "")
		else
			local def

			if (info.type == "integer" or info.type == "float") and not info.is_flag then
				def = temp:GetInt("$" .. key) or tonumber(info.default)
			elseif info.type == "vec4" then
				local r,g,b,a = unpack(temp:GetString("$" .. key):sub(3, -3):Split(" "))
				def = Color(tonumber(r), tonumber(g), tonumber(b), tonumber(a))
			elseif info.type == "vec3" or info.type == "color" then
				def = temp:GetVector("$" .. key) or tonumber(info.default) or Vector(info.default:sub(2, -2))
				if type(def) == "number" then
					def = Vector(def, def, def)
				end
			elseif info.type == "bool" or info.is_flag then
				def = temp:GetInt("$" .. key) == 1
			else
				--print(key, info.type)
			end

			pac.GetSet(PART, friendly, def)
		end

		pac.SetPropertyGroup()
	end

	pac.EndStorableVars()

	pac.RegisterPart(PART)
end