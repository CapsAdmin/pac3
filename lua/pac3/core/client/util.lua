local Vector = Vector
local Matrix = Matrix
local isstring = isstring

do -- table copy
	local lookup_table

	local function copy(obj, skip_meta)
		local t = type(obj)

		if t == "number" or t == "string" or t == "function" or t == "boolean" then
			return obj
		end

		if t == "Vector" or t == "Angle" then
			return obj * 1
		elseif lookup_table[obj] then
			return lookup_table[obj]
		elseif t == "table" then
			local new_table = {}

			lookup_table[obj] = new_table

			for key, val in pairs(obj) do
				new_table[copy(key, skip_meta)] = copy(val, skip_meta)
			end

			return skip_meta and new_table or setmetatable(new_table, getmetatable(obj))
		end

		return obj
	end

	function pac.CopyValue(obj, skip_meta)
		lookup_table = {}
		return copy(obj, skip_meta)
	end
end


function pac.MakeMaterialUnlitGeneric(mat, id)
	local tex_path = mat:GetString("$basetexture")

	if tex_path then
		local params = {}

		params["$basetexture"] = tex_path
		params["$vertexcolor"] = 1
		params["$vertexalpha"] = 1

		return pac.CreateMaterial(pac.uid("pac_fixmat_") .. id, "UnlitGeneric", params)
	end

	return mat
end

do
	local inf, ninf = math.huge, -math.huge

	function pac.IsNumberValid(num)
		return
			num and
			num ~= inf and
			num ~= ninf and
			(num >= 0 or num <= 0)
	end
end

do
	pac.next_frame_funcs = pac.next_frame_funcs or {}
	pac.next_frame_funcs_simple = pac.next_frame_funcs_simple or {}

	function pac.RunNextFrame(id, func)
		pac.next_frame_funcs[id] = func
	end

	function pac.RunNextFrameSimple(func)
		table.insert(pac.next_frame_funcs_simple, func)
	end
end

do --dev util
	function pac.RemoveAllPACEntities()
		for _, ent in pairs(ents.GetAll()) do
			pac.UnhookEntityRender(ent)

			if ent.IsPACEntity then
				ent:Remove()
			end
		end
	end

	local _part

	local function nuke_part()
		_part:Remove()
	end

	function pac.Panic()
		pac.RemoveAllParts()
		pac.RemoveAllPACEntities()

		for i, ent in ipairs(ents.GetAll()) do
			ent.pac_ignored = nil
			ent.pac_ignored_data = nil
			ent.pac_drawing = nil
			ent.pac_shouldnotdraw = nil
			ent.pac_onuse_only = nil
			ent.pac_onuse_only_check = nil
			ent.pac_ignored_callbacks = nil

			if ent.pac_bones_once then
				pac.ResetBones(ent)
				ent.pac_bones_once = nil
			end

			if istable(ent.pac_animation_sequences) then
				for part in next, ent.pac_animation_sequences do
					if part:IsValid() then
						_part = part
						ProtectedCall(nuke_part)
					end
				end

				ent.pac_animation_sequences = nil
			end

			if istable(ent.pac_bone_parts) then
				for part in next, ent.pac_bone_parts do
					if part:IsValid() then
						_part = part
						ProtectedCall(nuke_part)
					end
				end

				ent.pac_bone_parts = nil
			end

			ent.pac_animation_stack = nil
		end
	end

	pac.convarcache = {}
	function pac.CreateClientConVarFast(cvar,initial,save,t,server)

		local cached = pac.convarcache[cvar]
		if cached then return cached[1],cached[2] end

		local val
		local c = CreateClientConVar(cvar,initial,save,server)

		local ConVarChanged

		if t == "string" or t == "str" then
			ConVarChanged = function( cvar, old, new )
				val = new
			end
		elseif t == "boolean" or t == "bool" then
			ConVarChanged = function( cvar, old, new )
				if new == "0" then
					val = false
				elseif new == "1" then
					val = true
				else
					val = (tonumber(new) or 0)>=1
				end
			end

		elseif t == "number" or t == "num" then
			ConVarChanged = function( cvar, old, new )
				val= tonumber( new ) or 0
			end

		elseif t == "integer" or t == "int" then
			ConVarChanged = function( cvar, old, new )
				val= math.floor(tonumber( new ) or 0)
			end
		end

		if not ConVarChanged then error("Invalid type: " .. tostring(t)) end
		cvars.AddChangeCallback(cvar, ConVarChanged)
		ConVarChanged(cvar, nil, c:GetString())

		local function GetConVarValue() return val end

		pac.convarcache[cvar]={GetConVarValue,c}
		return GetConVarValue,c
	end
end

do
	local hue =
	{
		"red",
		"orange",
		"yellow",
		"green",
		"turquoise",
		"blue",
		"purple",
		"magenta",
	}

	local sat =
	{
		"pale",
		"",
		"strong",
	}

	local val =
	{
		"dark",
		"",
		"bright"
	}

	function pac.HSVToNames(h,s,v)
		return
			hue[math.Round((1+(h/360)*#hue))] or hue[1],
			sat[math.ceil(s*#sat)] or sat[1],
			val[math.ceil(v*#val)] or val[1]
	end

	function pac.ColorToNames(c)
		if c.r == 255 and c.g == 255 and c.b == 255 then return "white", "", "bright" end
		if c.r == 0 and c.g == 0 and c.b == 0 then return "black", "", "bright" end
		return pac.HSVToNames(ColorToHSV(Color(c.r, c.g, c.b)))
	end


	function pac.PrettifyName(str)
		if not str then return end
		str = str:lower()
		str = str:gsub("_", " ")
		return str
	end

end

do
	local pac_error_mdl = CreateClientConVar("pac_error_mdl","1",true,false,"0 = default error, 1=custom error model, models/yourmodel.mdl")
	local tc
	local invalidCache = {}

	function pac.FilterInvalidModel(mdl, fallback)
		if not isstring(mdl) then
			mdl = ""
		end

		if util.IsValidModel(mdl) then
			invalidCache[mdl] = nil
			return mdl
		end

		mdl = mdl:lower():Trim()

		if mdl == "" then
			return "models/error.mdl"
		end

		if invalidCache[mdl] then
			return invalidCache[mdl]
		end

		-- IsValidModel doesn't always return true... this is expensive though :(
		if string.GetExtensionFromFilename(mdl) == "mdl" and file.Exists(mdl, "GAME") then
			return mdl
		end

		if fallback and fallback:len() > 0 and (util.IsValidModel(fallback) or file.Exists(fallback , "GAME")) then
			return fallback
		end

		pac.Message("Invalid model - ", mdl)

		local str = pac_error_mdl:GetString()

		if str == "1" or str == "" then
			--passthrough
		elseif str == "0" then
			invalidCache[mdl] = mdl
			return mdl
		elseif util.IsValidModel(str) then
			invalidCache[mdl] = str
			return str
		end

		if tc == nil then
			if util.IsValidModel("models/props_junk/PopCan01a.mdl") then
				tc = "models/props_junk/PopCan01a.mdl"
			else
				tc = "models/props_junk/popcan01a.mdl"
			end
		end

		invalidCache[mdl] = tc
		return tc
	end
end

local pac_debug_clmdl = CreateClientConVar("pac_debug_clmdl", "0", true)
RunConsoleCommand("pac_debug_clmdl", "0")

local matsalt = '_' .. (os.time() - 0x40000000)

function pac.CreateMaterial(name, ...)
	return CreateMaterial(name .. matsalt, ...)
end

function pac.CreateEntity(model)
	model = pac.FilterInvalidModel(model, fallback)

	local ent = NULL

	local type = pac_debug_clmdl:GetInt()
	if type == 0 then
		ent = ClientsideModel(model) or ent
	elseif type == 1 then
		local rag = ClientsideRagdoll(model) or NULL
		if not rag:IsValid() then
			ent = ClientsideModel(model) or ent
		else
			ent = rag
		end
	elseif type == 2 then
		ent = ents.CreateClientProp(model) or ent -- doesn't render properly
		if ent:IsValid() then
			ent:PhysicsDestroy()
		end
	elseif type == 3 then

		effects.Register(
			{
				Init = function(self, p)
					self:SetModel(model)
					ent = self
				end,

				Think = function()
					return true
				end,

				Render = function(self)
					if self.Draw then self:Draw() else self:DrawModel() end
				end
			},

			"pac_model"
		)

		util.Effect("pac_model", EffectData())
	end

	if not ent:IsValid() then
		pac.Message("Failed to create entity with model: ", model)
	end

	return ent
end


do -- hook helpers
	pac.added_hooks = pac.added_hooks or {}

	function pac.AddHook(event_name, id, func, priority)
		id = "pac_" .. id

		if not DLib and not ULib then
			priority = nil
		end

		if pac.IsEnabled() then
			hook.Add(event_name, id, func, priority)
		end

		pac.added_hooks[event_name .. id] = {event_name = event_name, id = id, func = func, priority = priority}
	end

	function pac.RemoveHook(event_name, id)
		id = "pac_" .. id

		local data = pac.added_hooks[event_name .. id]

		if data then
			hook.Remove(data.event_name, data.id)

			pac.added_hooks[event_name .. id] = nil
		end
	end

	function pac.CallHook(str, ...)
		return hook.Run("pac_" .. str, ...)
	end

	function pac.EnableAddedHooks()
		for _, data in pairs(pac.added_hooks) do
			hook.Add(data.event_name, data.id, data.func, data.priority)
		end
	end

	function pac.DisableAddedHooks()
		for _, data in pairs(pac.added_hooks) do
			hook.Remove(data.event_name, data.id)
		end
	end
end

function pac.Material(str, part)
	if str == "" then return end

	local ply_owner = part:GetPlayerOwner()

	return pac.GetPropertyFromName("GetRawMaterial", str, ply_owner) or Material(str)
end

do
	--TODO: Table keeping id -> idx mapping
	local idx = math.random(0x1000)
	function pac.uid(id)
		idx = idx + 1
		if idx>=2^53 then
			ErrorNoHalt("?????BUG???? Pac UIDs exhausted\n")
			idx = 0
		end

		return ("%s%d"):format(id, idx)
	end
end

function pac.Handleurltex(part, url, callback, shader, additionalData)
	if not url or not pac.urltex or not url:find("http") then return false end
	local skip_cache = url:sub(1,1) == "_"

	if not url:match("https?://.+/%S*") then return false end

	pac.urltex.GetMaterialFromURL(
		pac.FixUrl(url),

		function(mat, tex)
			if not part:IsValid() then return end

			if callback then
				callback(mat, tex)
			else
				part.Materialm = mat
				part:CallRecursive("OnMaterialChanged")
			end

			pac.dprint("set custom material texture %q to %s", url, part:GetName())
		end,

		skip_cache,
		shader,
		nil,
		nil,
		additionalData
	)
	return true
end

local mat

for _, ent in pairs(ents.GetAll()) do
	ent.pac_can_legacy_scale = nil
end

function pac.LegacyScale(ent)
	local mat0 = ent:GetBoneMatrix(0)
	if mat0 then
		local mat = Matrix()
		mat:Scale(ent.pac_model_scale)
		ent:SetBoneMatrix(0, mat0 * mat)
		ent.pac_can_legacy_scale = true
	end
end

function pac.SetModelScale(ent, scale, size, legacy_scale)
	if not ent:IsValid() then return end

	if scale and size then
		ent.pac_model_scale = scale * size
	end

	if scale and not size then
		ent.pac_model_scale = scale
	end

	if not scale and size then
		ent.pac_model_scale = Vector(size, size, size)
	end

	if legacy_scale and (ent.pac_can_legacy_scale == nil or ent.pac_can_legacy_scale == true) then
		ent.pac_matrixhack = true

		if not ent.pac_follow_bones_function then
			ent.pac_follow_bones_function = pac.build_bone_callback
			ent:AddCallback("BuildBonePositions", function(ent) pac.build_bone_callback(ent) end)
		end

		ent:DisableMatrix("RenderMultiply")
	else
		ent.pac_matrixhack = false

		if scale then
			mat = Matrix()

			local x,y,z = scale.x, scale.y, scale.z
			--local x,y,z = ent.pac_model_scale.x, ent.pac_model_scale.y, ent.pac_model_scale.z

			mat:Scale(Vector(x,y,z))
			if mat:IsIdentity() then
				ent:DisableMatrix("RenderMultiply")
			else
				ent:EnableMatrix("RenderMultiply", mat)
			end
		end

		if size then
			if ent.pac_enable_ik then
				ent:SetIK(true)
				ent:SetModelScale(1, 0)
			else
				ent:SetIK(false)
				ent:SetModelScale(size == 1 and 1.000001 or size, 0)
			end
		end

		if not scale and not size then
			ent:DisableMatrix("RenderMultiply")
		end

	end
end

-- no need to rematch the same pattern
local pattern_cache = {{}}

function pac.StringFind(a, b, simple, case_sensitive)
	if not a or not b then return end

	if simple and not case_sensitive then
		a = a:lower()
		b = b:lower()
	end

	pattern_cache[a] = pattern_cache[a] or {}

	if pattern_cache[a][b] ~= nil then
		return pattern_cache[a][b]
	end

	if simple and a:find(b, nil, true) or not simple and a:find(b) then
		pattern_cache[a][b] = true
		return true
	else
		pattern_cache[a][b] = false
		return false
	end
end

function pac.TogglePartDrawing(ent, b)
	if b then
		ent.pac_drawing = false
		pac.ShowEntityParts(ent)
		ent.pac_shouldnotdraw = false
	else
		ent.pac_drawing = true
		pac.HideEntityParts(ent)
		ent.pac_shouldnotdraw = true
	end
end

-- disable pop/push flashlight modes (used for stability in 2D context)
function pac.FlashlightDisable(b)
	pac.flashlight_disabled = b
end
