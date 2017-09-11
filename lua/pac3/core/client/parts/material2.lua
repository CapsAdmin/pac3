local shader_params = include("pac3/libraries/shader_params.lua")

local function add_matrix(META, key, friendly_name, description, udata)
	local position_key = key .. "Position"
	local scale_key = key .. "Scale"
	local angle_key = key .. "Angle"
	local angle_center_key = key .. "AngleCenter"

	pac.GetSet(META, position_key, Vector(0, 0, 0), {editor_friendly = friendly_name .. "Position"})
	pac.GetSet(META, scale_key, Vector(1, 1, 1), {editor_friendly = friendly_name .. "Scale"})
	pac.GetSet(META, angle_key, 0, {editor_panel = "number", editor_friendly = friendly_name .. "Angle"})
	pac.GetSet(META, angle_center_key, Vector(0.5, 0.5, 0), {editor_friendly = friendly_name .. "AngleCenter"})

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

		self.translation_vector = self.translation_vector or Vector()

		self.translation_vector.x = self[position_key].x
		self.translation_vector.y = self[position_key].y

		setup_matrix(self)

		self:GetRawMaterial():SetMatrix(shader_key, self.matrix)
	end

	META["Set" .. scale_key] = function(self, vec)
		self[scale_key] = vec
		setup_matrix(self)

		self:GetRawMaterial():SetMatrix(shader_key, self.matrix)
	end

	META["Set" .. angle_key] = function(self, num)
		self[angle_key] = num

		self.rotation_angle.y = self[angle_key]*360

		setup_matrix(self)

		self:GetRawMaterial():SetMatrix(shader_key, self.matrix)
	end

	META["Set" .. angle_center_key] = function(self, vec)
		self[angle_center_key] = vec

		setup_matrix(self)

		self:GetRawMaterial():SetMatrix(shader_key, self.matrix)
	end

end

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

local shader_name_translate = {
	vertexlitgeneric = "3d",
	unlitgeneric = "2d",
}

for shader_name, groups in pairs(shader_params.shaders) do
	for group_name, base_group in pairs(shader_params.base) do
		if groups[group_name] then
			for k,v in pairs(base_group) do
				groups[group_name][k] = v
			end
		else
			groups[group_name] = base_group
		end
	end
end

for shader_name, groups in pairs(shader_params.shaders) do
	local temp = CreateMaterial(tostring({}), shader_name, {})

	local PART = {}

	PART.ClassName = "material_" .. (shader_name_translate[shader_name] or shader_name)
	PART.Description = shader_name
	PART.NonPhysical = true
	PART.Group = "pac4"
	PART.Icon = "icon16/paintcan.png"

	pac.StartStorableVars()

	pac.SetPropertyGroup("generic")

	-- move this to tools or something
	pac.GetSet(PART, "LoadVmt", "", {editor_panel = "material"})
	function PART:SetLoadVmt(path)
		if not path or path == "" then return end

		local str = file.Read("materials/" .. path .. ".vmt", "GAME")
		local vmt = util.KeyValuesToTable(str)
		local shader = str:match("^(.-)%{"):gsub("%p", ""):Trim()


		for k,v in pairs(self:GetVars()) do
			if PART.ShaderParams[k] and PART.ShaderParams[k].default ~= nil then
				self["Set" .. k](self, PART.ShaderParams[k].default)
			end
		end
		print(str)
		print("======")
		PrintTable(vmt)
		print("======")

		for k,v in pairs(vmt) do
			if k:StartWith("$") then k = k:sub(2) end

			local func = self["Set" .. k]
			if func then
				local t = type(v)
				local info = PART.ShaderParams[k]

				if type(v) == "string" then
					if v:find("[", nil, true) then
						v = Vector(v:gsub("[%[%]]", ""):gsub("%s+", " "):Trim())

						if type(info.default) == "number" then
							v = v.x
						end
					end
				end

				if type(v) == "number" then
					if info.type == "bool" or info.is_flag then
						v = v == 1
					end
				end

				func(self, v)
			else
				pac.Message("cannot convert material parameter " .. k)
			end
		end
	end

	pac.GetSet(PART, "MaterialOverride", "all", {enums = function(self, str)

		local materials = {}

		if pace.current_part:HasParent() and pace.current_part:GetParent().GetEntity and pace.current_part:GetParent():GetEntity():IsValid() then
			materials = pace.current_part:GetParent():GetEntity():GetMaterials()
		end

		table.insert(materials, "all")

		return materials
	end})

	local function update_submaterial(self, remove, parent)
		local str = self.MaterialOverride
		parent = parent or self:GetParent()

		local num = 0

		if parent:IsValid() then
			if tonumber(str) then
				num = tonumber(str)
			elseif str ~= "all" and parent.GetEntity and parent:GetEntity():IsValid() then
				for i, v in ipairs(parent:GetEntity():GetMaterials()) do
					if v == str then
						num = i
						break
					end
				end
			end

			parent.material_override = parent.material_override or {}
			parent.material_override[num] = parent.material_override[num] or {}

			for _, stack in pairs(parent.material_override) do
				for i, v in ipairs(stack) do
					if v == self then
						table.remove(stack, i)
						break
					end
				end
			end

			if not remove then
				table.insert(parent.material_override[num], self)
			end
		end
	end

	function PART:SetMaterialOverride(num)
		self.MaterialOverride = num

		update_submaterial(self)
	end

	PART.ShaderParams = {}

	local sorted_groups = {}
	for k, v in pairs(groups) do
		table.insert(sorted_groups, {k = k, v = v})
	end
	table.sort(sorted_groups, function(a, b) return a.k:lower() < b.k:lower() end)

	for _, v in ipairs(sorted_groups) do
		local group, params =  v.k, v.v

		local sorted_params = {}
		for k, v in pairs(params) do
			table.insert(sorted_params, {k = k, v = v})
		end
		table.sort(sorted_params, function(a, b) return a.k:lower() < b.k:lower() end)

		for _, v in ipairs(sorted_params) do
			local key, info = v.k, v.v

			PART.ShaderParams[key] = info

			if info.is_flag and group == "generic" then
				pac.SetPropertyGroup("flags")
			else
				pac.SetPropertyGroup(group)
			end

			local property_name = key

			if info.type == "matrix" then
				add_matrix(PART, property_name, info.friendly:gsub("Transform", ""), info.description)
			elseif info.type == "texture" then
				info.default = info.default or ""
				pac.GetSet(PART, property_name, info.default, {
					editor_panel = "textures",
					editor_friendly = info.friendly,
					description = info.description,
					shader_param_info = info
				})

				local key = "$" .. key

				PART["Set" .. property_name] = function(self, val)
					self[property_name] = val

					if val == "" then
						self:GetRawMaterial():SetUndefined(key)
						self:GetRawMaterial():Recompute()

					else
						if not pac.resource.DownloadTexture(val, function(tex, frames)
							if frames then
								self.vtf_frame_limit = self.vtf_frame_limit or {}
								self.vtf_frame_limit[property_name] = frames
							end
							self:GetRawMaterial():SetTexture(key, tex)
						end) then
							self:GetRawMaterial():SetTexture(key, val)
						end
					end
				end
			else
				pac.GetSet(PART, property_name, info.default, {
					editor_friendly = info.friendly,
					enums = info.enums,
					description = info.description,
					editor_sensitivity = (info.type == "vec3" or info.type == "color") and 0.25 or nil,
					editor_panel = (info.type == "color" and "color2") or (property_name == "model" and "boolean") or nil,
				})

				local flag_key = key
				local key = "$" .. key

				if type(info.default) == "number" then
					PART["Set" .. property_name] = function(self, val)
						self[property_name] = val
						local mat = self:GetRawMaterial()
						mat:SetFloat(key, val)
						if info.recompute then
							mat:Recompute()
						end
					end
					if property_name:lower():find("frame") then
						PART["Set" .. property_name] = function(self, val)
							self[property_name] = val
							if self.vtf_frame_limit and self.vtf_frame_limit[property_name] then
								self:GetRawMaterial():SetInt(key, math.abs(val)%self.vtf_frame_limit[property_name])
							end
						end
					end
				elseif type(info.default) == "boolean" then
					if info.is_flag then
						PART["Set" .. property_name] = function(self, val)
							self[property_name] = val

							local mat = self:GetRawMaterial()

							local tbl = FlagsToTable(mat:GetInt("$flags"), material_flags)
							tbl[flag_key] = val
							mat:SetInt("$flags", TableToFlags(tbl, material_flags))

							mat:Recompute()
						end
					else
						PART["Set" .. property_name] = function(self, val)
							self[property_name] = val
							local mat = self:GetRawMaterial()
							mat:SetInt(key, val and 1 or 0)
							if info.recompute then mat:Recompute() end
						end
					end
				elseif type(info.default) == "Vector" then
					PART["Set" .. property_name] = function(self, val)
						self[property_name] = val
						local mat = self:GetRawMaterial()
						mat:SetVector(key, val)
					end
				elseif info.type == "vec2" then
					-- need vec2 type
					PART["Set" .. property_name] = function(self, val)
						local x,y
						if type(val) == "string" then
							x,y = unpack(val:Split(" "))
							x = tonumber(x) or 0
							y = tonumber(y) or 0
						else
							x,y = val.x, val.y
						end

						self[property_name] = ("%f %f"):format(x, y)
						local mat = self:GetRawMaterial()
						mat:SetString(key, ("[%f %f]"):format(x,y))

						if info.recompute then mat:Recompute() end
					end
				elseif info.type == "vec4" then
					-- need vec4 type
					PART["Set" .. property_name] = function(self, val)

						local x,y,z,w
						if type(val) == "string" then
							x,y,z,w = unpack(val:Split(" "))
							x = tonumber(x) or 0
							y = tonumber(y) or 0
							z = tonumber(z) or 0
							w = tonumber(w) or 0
						else
							x,y,z = val.x, val.y, val.z
							w = 0
						end

						self[property_name] = ("%f %f %f %f"):format(x, y, z, w)
						local mat = self:GetRawMaterial()
						mat:SetString(key, ("[%f %f %f %f]"):format(x,y,z,w))

						if info.recompute then mat:Recompute() end
					end
				end
			end
		end
	end

	pac.EndStorableVars()

	function PART:GetRawMaterial()
		if not self.Materialm then
			self.material_name = tostring({})
			local mat = CreateMaterial(self.material_name, shader_name, {})
			self.Materialm = mat

			for k,v in pairs(self:GetVars()) do
				self["Set" .. k](self, v)
			end
		end

		return self.Materialm
	end

	function PART:OnParent(parent)
		update_submaterial(self)
	end

	function PART:OnRemove()
		update_submaterial(self, true)
	end

	function PART:OnUnParent(parent)
		update_submaterial(self, true, parent)
	end

	function PART:OnHide()
		update_submaterial(self, true)
	end

	function PART:OnShow()
		update_submaterial(self)
	end

	pac.RegisterPart(PART)
end