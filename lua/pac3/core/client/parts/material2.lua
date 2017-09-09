local shader_params = include("pac3/libraries/shader_params.lua")

local temp = CreateMaterial("pac3_dummy_mat", "vertexlitgeneric", {})


local function add_matrix(META, key, friendly_name, description, udata)
	key = key or friendly_name

	local position_key = friendly_name .. "Position"
	local scale_key = friendly_name .. "Scale"
	local angle_key = friendly_name .. "Angle"
	local angle_center_key = friendly_name .. "AngleCenter"

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

		self:GetRawMaterial():SetMatrix(shader_key, self.matrix)
	end

	META["Set" .. scale_key] = function(self, vec)
		self[scale_key] = vec
		setup_matrix(self)

		self:GetRawMaterial():SetMatrix(shader_key, self.matrix)
	end

	META["Set" .. angle_key] = function(self, num)
		self[angle_key] = num
		setup_matrix(self)

		self.rotation_angle.y = self[angle_key]*360

		self:GetRawMaterial():SetMatrix(shader_key, self.matrix)
	end

	META["Set" .. angle_center_key] = function(self, vec)
		self[angle_center_key] = vec
		setup_matrix(self)

		self:GetRawMaterial():SetMatrix(shader_key, self.matrix)
	end

end

local fixup = {
	"selfillum",
	"flashlight",
	"alphatest",
	"rimlight",
	"emissiveblend",
}

local material_flags = {
	debug = bit.lshift(1, 0),
	no_debug_override = bit.lshift(1, 1),
	no_draw = bit.lshift(1, 2),
	use_in_fillrate_mode = bit.lshift(1, 3),
	vertexcolor = bit.lshift(1, 4),
	vertexalpha = bit.lshift(1, 5),
	selfillum = bit.lshift(1, 6),
	additive = bit.lshift(1, 7),
	alphatest = bit.lshift(1, 8),
	multipass = bit.lshift(1, 9),
	znearer = bit.lshift(1, 10),
	model = bit.lshift(1, 11),
	flat = bit.lshift(1, 12),
	nocull = bit.lshift(1, 13),
	nofog = bit.lshift(1, 14),
	ignorez = bit.lshift(1, 15),
	decal = bit.lshift(1, 16),
	envmapsphere = bit.lshift(1, 17),
	noalphamod = bit.lshift(1, 18),
	envmapcameraspace = bit.lshift(1, 19),
	basealphaenvmapmask = bit.lshift(1, 20),
	translucent = bit.lshift(1, 21),
	normalmapalphaenvmapmask = bit.lshift(1, 22),
	needs_software_skinning = bit.lshift(1, 23),
	opaquetexture = bit.lshift(1, 24),
	envmapmode = bit.lshift(1, 25),
	suppress_decals = bit.lshift(1, 26),
	halflambert = bit.lshift(1, 27),
	wireframe = bit.lshift(1, 28),
	allowalphatocoverage = bit.lshift(1, 29),
	ignore_alpha_modulation = bit.lshift(1, 30),
}

local function TableToFlags(flags, valid_flags)
	if type(flags) == "string" then
		flags = {flags}
	end

	local out = 0

	for k, v in pairs(flags) do
		if v then
			local flag = valid_flags[v] or valid_flags[k]
			if not flag then
				error("invalid flag", 2)
			end

			out = bit.bor(out, tonumber(flag))
		end
	end

	return out
end

local function FlagsToTable(flags, valid_flags)

	if not flags then return valid_flags.default_valid_flag end

	local out = {}

	for k, v in pairs(valid_flags) do
		if bit.band(flags, v) > 0 then
			out[k] = true
		end
	end

	return out
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
		local friendly = info.friendly or key
		local group = friendly:match("^(%u.-)%u") or friendly

		for _, str in ipairs(fixup) do
			if friendly:lower():StartWith(str) then
				group = str
				break
			end
		end

		if group:lower() ~= "no" then
			group = group:lower()
			group_count[group] = (group_count[group] or 0) + 1
			groups[key] = group
		end
	end

	local sorted_params = {}
	for k, v in pairs(params) do
		if not k:find("frame") then
			table.insert(sorted_params, {k = k, v = v})
		end
	end
	table.sort(sorted_params, function(a, b) return a.k:lower() < b.k:lower() end)

	for _, v in ipairs(sorted_params) do
		local key, info =  v.k, v.v
		if groups[key] and group_count[groups[key]] > 1 then
			pac.SetPropertyGroup(groups[key])
		elseif info.is_flag then
			pac.SetPropertyGroup("flags")
		end

		local property_name = info.friendly or key
		local friendly_name = property_name
		if groups[key] and groups[key] ~= "generic" and groups[key] and group_count[groups[key]] > 1 then
			friendly_name = friendly_name:sub(#groups[key] + 1)
			if friendly_name == "" then
				friendly_name = property_name
			end
		end

		if info.type == "matrix" then
			add_matrix(PART, property_name, friendly_name:gsub("Transform", ""), info.description)
		elseif info.type == "texture" then
			pac.GetSet(PART, property_name, info.default or "", {editor_panel = "textures", editor_friendly = friendly_name, description = info.description, shader_param_info = info})
			local key = "$" .. key

			PART["Set" .. property_name] = function(self, val)
				self[property_name] = val

				if not pac.Handleurltex(self, val, function(_, tex)
					self:GetRawMaterial():SetTexture(key, tex)
				end) then

					if val == "" then
						self:GetRawMaterial():SetUndefined(key)
					else
						self:GetRawMaterial():SetTexture(key, val)
					end
				end
			end
		else
			local def
			local editor_sensitivity
			if (info.type == "integer" or info.type == "float") and not info.is_flag then
				def = temp:GetInt("$" .. key) or tonumber(info.default)
			elseif info.type == "vec4" then
				local r,g,b,a = unpack(temp:GetString("$" .. key):sub(3, -3):Split(" "))
				def = Color(tonumber(r), tonumber(g), tonumber(b), tonumber(a))
			elseif info.type == "vec3" or info.type == "color" then
				def = temp:GetVector("$" .. key)
				if def == Vector(0, 0, 0) then
					def = Vector(info.default:sub(2, -2))

					if def == Vector(0, 0, 0) then
						def = Vector(info.default:sub(1, -1))

						if def == Vector(0, 0, 0) then
							def = tonumber(info.default)
						end
					end
				end

				if type(def) == "number" then
					def = Vector(def, def, def)
				end

				editor_sensitivity = 0.25
			elseif info.type == "bool" or info.is_flag then
				def = temp:GetInt("$" .. key) == 1
			end

			pac.GetSet(PART, property_name, def, {editor_friendly = friendly_name, enums = info.enums, description = info.description, editor_sensitivity = editor_sensitivity})

			local flag_key = key:lower()
			local key = "$" .. key

			if type(def) == "number" then
				PART["Set" .. property_name] = function(self, val)
					self[property_name] = val
					local mat = self:GetRawMaterial()
					mat:SetFloat(key, val)
					if info.recompute then
						mat:Recompute()
					end
				end
			elseif type(def) == "boolean" then
				if info.is_flag then
					PART["Set" .. property_name] = function(self, val)
						self[property_name] = val

						local mat = self:GetRawMaterial()

						local tbl = FlagsToTable(mat:GetInt("$flags"), material_flags)
						tbl[flag_key] = val
						mat:SetInt("$flags", TableToFlags(tbl, material_flags))

						if info.recompute then mat:Recompute() end
					end
				else
					PART["Set" .. property_name] = function(self, val)
						self[property_name] = val
						local mat = self:GetRawMaterial()
						mat:SetInt(key, val and 1 or 0)
						if info.recompute then mat:Recompute() end
					end
				end
			elseif type(def) == "Vector" then
				PART["Set" .. property_name] = function(self, val)
					self[property_name] = val
					local mat = self:GetRawMaterial()
					mat:SetVector(key, val)
				end
			elseif IsColor(def) then
				PART["Set" .. property_name] = function(self, val)
					self[property_name] = val
					local mat = self:GetRawMaterial()
					mat:SetString(key, ("[%f %f %f %f]"):format(val.r, val.g, val.b, val.a))
					if info.recompute then mat:Recompute() end
				end
			end
		end

		pac.SetPropertyGroup()
	end

	pac.EndStorableVars()

	function PART:GetRawMaterial()
		if not self.Materialm then
			local mat = CreateMaterial(tostring({}), shader_name, {})
			self.Materialm = mat

			for k,v in pairs(self:GetVars()) do
				self["Set" .. k](self, v)
			end
		end

		return self.Materialm
	end

	function PART:OnParent(parent)
		parent.MaterialOverride = self:GetRawMaterial()
	end

	function PART:OnRemove()
		local mat = self:GetRawMaterial()

		for key, part in pairs(pac.GetParts()) do
			if part.MaterialOverride == mat then
				part.MaterialOverride = nil
			end
		end
	end

	function PART:OnUnParent(parent)
		if parent.MaterialOverride == self:GetRawMaterial() then
			parent.MaterialOverride = nil
		end
	end

	function PART:OnHide()
		local parent = self:GetParent()
		if parent:IsValid() then
			if parent.MaterialOverride == self:GetRawMaterial() then
				parent.MaterialOverride = nil
			end
		end
	end

	function PART:OnShow()
		local parent = self:GetParent()
		if parent:IsValid() then
			parent.MaterialOverride = self:GetRawMaterial()
		end
	end

	pac.RegisterPart(PART)
end