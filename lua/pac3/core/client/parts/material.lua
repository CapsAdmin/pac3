local shader_params = include("pac3/libraries/shader_params.lua")

local mat_hdr_level = GetConVar("mat_hdr_level")

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
	if isstring(flags) then
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
	eyerefract = "eye refract",
}

for shader_name, groups in pairs(shader_params.shaders) do
	for group_name, base_group in pairs(shader_params.base) do
		if groups[group_name] then
			for k,v in pairs(base_group) do
				if not groups[group_name][k] then
					groups[group_name][k] = v
				end
			end
		else
			groups[group_name] = base_group
		end
	end
end

for shader_name, groups in pairs(shader_params.shaders) do
	local temp = CreateMaterial(tostring({}), shader_name, {})

	local BUILDER, PART = pac.PartTemplate("base")

	PART.ClassName = "material_" .. (shader_name_translate[shader_name] or shader_name)
	PART.Description = shader_name

	PART.ProperColorRange = true

	if shader_name == "vertexlitgeneric" then
		PART.FriendlyName = "material"
		PART.Group = {'modifiers', 'model', 'entity'}
	else
		PART.FriendlyName = "material " .. shader_name
		PART.Group = "advanced"
	end

	PART.Icon = "icon16/paintcan.png"

	BUILDER:StartStorableVars()

	BUILDER:SetPropertyGroup("generic")

	-- move this to tools or something
	BUILDER:GetSet("LoadVmt", "", {editor_panel = "material"})
	function PART:SetLoadVmt(path)
		if not path or path == "" then return end

		local str = file.Read("materials/" .. path .. ".vmt", "GAME")

		if not str then return end

		local vmt = util.KeyValuesToTable(str)
		local shader = str:match("^(.-)%{"):gsub("%p", ""):Trim()


		for k,v in pairs(self:GetVars()) do
			local param = PART.ShaderParams[k]
			if param and param.default ~= nil then
				self["Set" .. k](self, param.default)
			end
			if param and param.type == "texture" then
				self["Set" .. k](self, "")
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
				local info = PART.ShaderParams[k]

				if isstring(v) then
					if v:find("[", nil, true) then
						v = Vector(v:gsub("[%[%]]", ""):gsub("%s+", " "):Trim())

						if isnumber(info.default) then
							v = v.x
						end
					elseif v:find("{", nil, true) then
						v = Vector(v:gsub("[%{%}]", ""):gsub("%s+", " "):Trim())

						if info.type == "color" then
							v = v / 255
						end
					end
				end

				if isnumber(v) then
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

	BUILDER:GetSet("MaterialOverride", "all", {enums = function(self, str)

		local materials = {}

		if pace.current_part:GetOwner():IsValid() then
			materials = pace.current_part:GetOwner():GetMaterials()
		end

		table.insert(materials, "all")

		local tbl = {}

		for _, v in ipairs(materials) do
			v = v:match(".+/(.+)") or v
			tbl[v] = v:lower()
		end

		return tbl
	end})

	local function update_submaterial(self, remove, parent)
		pac.RunNextFrameSimple(function()
			if not IsValid(self) and not remove then return end
			local name = self:GetName()

			for _, part in ipairs(self:GetRootPart():GetChildrenList()) do
				if part.GetMaterials then
					for _, path in ipairs(part.Materials:Split(";")) do
						if path == name then
							part:SetMaterials(part.Materials)
							break
						end
					end
				end
			end

			local str = self.MaterialOverride
			parent = parent or self:GetParent()

			local num = 0

			if parent:IsValid() then
				if tonumber(str) then
					num = tonumber(str)
				elseif str ~= "all" and parent:GetOwner():IsValid() then
					for i, v in ipairs(parent:GetOwner():GetMaterials()) do
						if (v:match(".+/(.+)") or v):lower() == str:lower() then
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

		end)
	end

	function PART:Initialize()
		self.translation_vector = Vector()
		self.rotation_angle = Angle(0, 0, 0)
	end


	function PART:GetNiceName()
		local path = ""

		if shader_name == "refract" then
			path = self:Getnormalmap()
		elseif shader_name == "eyerefract" then
			path = self:Getiris()
		else
			path = self:Getbasetexture()
		end

		path = path:gsub("%%(..)", function(char)
			local num = tonumber("0x" .. char)
			if num then
				return string.char(num)
			end
		end)

		local name = ("/".. path):match(".+/(.-)%.") or ("/".. path):match(".+/(.+)")
		local nice_name = (pac.PrettifyName(name) or "no texture") .. " | " .. shader_name

		return nice_name
	end

	function PART:SetMaterialOverride(num)
		self.MaterialOverride = num

		update_submaterial(self)
	end

	function PART:OnThink()
		if self:GetOwner():IsValid() then
			local materials = self:GetOwner():GetMaterials()
			if materials and #materials ~= self.last_material_count then
				update_submaterial(self)
				self.last_material_count = #materials
			end
		end
	end

	PART.ShaderParams = {}
	PART.TransformVars = {}

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
				BUILDER:SetPropertyGroup("flags")
			else
				BUILDER:SetPropertyGroup(group)
			end

			if info.default == nil then
				if info.type == "vec3" then
					info.default = Vector(0,0,0)
				elseif info.type == "color" then
					info.default = Vector(1,1,1)
				elseif info.type == "float" then
					info.default = 0
				elseif info.type == "vec2" then
					info.default = Vector(0, 0)
				end
			end

			local property_name = key

			local description = (info.description or "") .. " ($" .. key .. ")"

			if info.type == "matrix" then
				local position_key = property_name .. "Position"
				local scale_key = property_name .. "Scale"
				local angle_key = property_name .. "Angle"
				local angle_center_key = property_name .. "AngleCenter"

				local friendly_name = info.friendly:gsub("Transform", "")
				BUILDER:GetSet(position_key, Vector(0, 0, 0), {editor_friendly = friendly_name .. "Position", description = description})
				BUILDER:GetSet(scale_key, Vector(1, 1, 1), {editor_friendly = friendly_name .. "Scale", description = description})
				BUILDER:GetSet(angle_key, 0, {editor_panel = "number", editor_friendly = friendly_name .. "Angle", description = description})
				BUILDER:GetSet(angle_center_key, Vector(0.5, 0.5, 0), {editor_friendly = friendly_name .. "AngleCenter", description = description})

				PART.TransformVars[position_key] = true
				PART.TransformVars[scale_key] = true
				PART.TransformVars[angle_key] = true
				PART.TransformVars[angle_center_key] = true

				local shader_key = "$" .. key

				local function setup_matrix(self)
					self.matrix = self.matrix or Matrix()

					self.matrix:Identity()
					self.matrix:Translate(self.translation_vector)

					self.matrix:Translate(self[angle_center_key])
					self.matrix:Rotate(self.rotation_angle)
					self.matrix:Translate(-self[angle_center_key])

					self.matrix:SetScale(self[scale_key])
				end

				PART["Set" .. position_key] = function(self, vec)
					self[position_key] = vec


					self.translation_vector.x = self[position_key].x
					self.translation_vector.y = self[position_key].y

					setup_matrix(self)

					self:GetRawMaterial():SetMatrix(shader_key, self.matrix)
				end

				PART["Set" .. scale_key] = function(self, vec)
					self[scale_key] = vec
					setup_matrix(self)

					self:GetRawMaterial():SetMatrix(shader_key, self.matrix)
				end

				PART["Set" .. angle_key] = function(self, num)
					self[angle_key] = num

					self.rotation_angle.y = self[angle_key]*360

					setup_matrix(self)

					self:GetRawMaterial():SetMatrix(shader_key, self.matrix)
				end

				PART["Set" .. angle_center_key] = function(self, vec)
					self[angle_center_key] = vec

					setup_matrix(self)

					self:GetRawMaterial():SetMatrix(shader_key, self.matrix)
				end
			elseif info.type == "texture" then
				local getnohdr = "Get" .. property_name .. "NoHDR"

				if info.partial_hdr then
					BUILDER:GetSet(property_name .. "NoHDR", false, {
						editor_friendly = info.friendly .. " No HDR",
						description = "Disables bound param when HDR is enabled",
					})
				end

				info.default = info.default or ""

				BUILDER:GetSet(property_name, info.default, {
					editor_panel = "textures",
					editor_friendly = info.friendly,
					description = description,
					shader_param_info = info,
				})

				local key = "$" .. key

				PART["Set" .. property_name .. "NoHDR"] = function(self, val)
					self[property_name .. "NoHDR"] = val
					PART["Set" .. property_name](self, self[property_name])
				end

				PART["Set" .. property_name] = function(self, val)
					self[property_name] = val

					if val == "" or info.partial_hdr and mat_hdr_level:GetInt() > 0 and self[getnohdr](self) then
						self:GetRawMaterial():SetUndefined(key)
						self:GetRawMaterial():Recompute()
					else
						if not pac.resource.DownloadTexture(val, function(tex, frames)
							if frames then
								self.vtf_frame_limit = self.vtf_frame_limit or {}
								self.vtf_frame_limit[property_name] = frames
							end
							self:GetRawMaterial():SetTexture(key, tex)
						end, self:GetPlayerOwner()) then
							self:GetRawMaterial():SetTexture(key, val)

							local texture = self:GetRawMaterial():GetTexture(key)

							if texture then
								self.vtf_frame_limit = self.vtf_frame_limit or {}
								self.vtf_frame_limit[property_name] = texture:GetNumAnimationFrames()
							end
						end
					end
				end
			else
				BUILDER:GetSet(property_name, info.default, {
					editor_friendly = info.friendly,
					enums = info.enums,
					description = description,
					editor_sensitivity = (info.type == "vec3" or info.type == "color") and 0.25 or nil,
					editor_panel = (info.type == "color" and "color2") or (property_name == "model" and "boolean") or nil,
					editor_round = info.type == "integer",
				})

				local flag_key = key
				local key = "$" .. key

				if isnumber(info.default) then
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
							if self.vtf_frame_limit and info.linked and self.vtf_frame_limit[info.linked] then
								self:GetRawMaterial():SetInt(key, math.abs(val)%self.vtf_frame_limit[info.linked])
							else
								self:GetRawMaterial():SetInt(key, val)
							end
						end
					end
				elseif isbool(info.default) then
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
							if isvector(val) then
								val = (val == Vector(1,1,1)) and true or false
							end

							self[property_name] = val
							local mat = self:GetRawMaterial()

							mat:SetInt(key, val and 1 or 0)
							if info.recompute then mat:Recompute() end
						end
					end
				elseif isvector(info.default) or info.type == "vec3" or info.type == "vec2" then
					PART["Set" .. property_name] = function(self, val)
						if isstring(val) then val = Vector() end
						self[property_name] = val
						local mat = self:GetRawMaterial()
						mat:SetVector(key, val)
						if info.recompute then mat:Recompute() end
					end
				elseif info.type == "vec4" then
					-- need vec4 type
					PART["Set" .. property_name] = function(self, val)

						local x,y,z,w
						if isstring(val) then
							x,y,z,w = unpack(val:Split(" "))
							x = tonumber(x) or 0
							y = tonumber(y) or 0
							z = tonumber(z) or 0
							w = tonumber(w) or 0
						elseif isvector(val) then
							x,y,z = val.x, val.y, val.z
							w = 0
						else
							x, y, z, w = 0, 0, 0, 0
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

	BUILDER:EndStorableVars()

	function PART:GetRawMaterial()
		if not self.Materialm then
			self.material_name = tostring({})
			local mat = pac.CreateMaterial(self.material_name, shader_name, {})
			self.Materialm = mat

			for k,v in pairs(self:GetVars()) do
				if PART.ShaderParams[k] and PART.ShaderParams[k].default ~= nil then
					self["Set" .. k](self, v)
				end
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

	BUILDER:Register()
end