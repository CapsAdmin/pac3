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
					if isnumber(part) then continue end
					if part:IsValid() then
						_part = part
						ProtectedCall(nuke_part)
					end
				end

				ent.pac_animation_sequences = nil
			end

			if istable(ent.pac_bone_parts) then
				for part in next, ent.pac_bone_parts do
					if isnumber(part) then continue end
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
		id = isstring(id) and "pac_" .. id or id

		if not DLib and not ULib then
			priority = nil
		end
		if pac.IsEnabled() then
			hook.Add(event_name, id, func, priority)
		end
		pac.added_hooks[event_name .. tostring(id)] = {event_name = event_name, id = id, func = func, priority = priority}
	end

	function pac.RemoveHook(event_name, id)
		id = "pac_" .. tostring(id)

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
			if ispanel(data.id) and not IsValid(data.id) then -- Panels can be NULL and are (probably) already removed
				pac.added_hooks[data.event_name .. tostring(data.id)] = nil
			else
				hook.Add(data.event_name, data.id, data.func, data.priority)
			end
		end
	end

	function pac.DisableAddedHooks()
		for _, data in pairs(pac.added_hooks) do
			if ispanel(data.id) and not IsValid(data.id) then -- Panels can be NULL and are already removed
				pac.added_hooks[data.event_name .. tostring(data.id)] = nil
			else
				hook.Remove(data.event_name, data.id)
			end
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
		pac.FixUrl(url, "image"),

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


do
	-- CCT: correlated color temperature
	--[[
		credit for pseudocode : Tanner Helland, from equations plotted based on data from Mitchell Charity
		credit for some keywords' reference values : Alcon Lighting, Westinghouse Lighting, XenonPro
	]]
	pac.temperature_color_keywords_categorized = {
		["simplified temperatures"] = {
			{["cold"] = 10000},
			{["cool"] = 6000},
			{["neutral"] = 4300},
			{["warm"] = 2000},
			{["hot"] = 1000},
		},

		["sunlight"] = {
			{["daylight"] = 6200},
			{["sunset"] = 3200},
			{["sky"] = 10000},
			{["horizon"] = 5000},
			{["overcast"] = 5000},
		},

		["astronomical references"] = {
			{["white dwarf"] = 20000},
			{["sun"] = 5800},
			{["red giant"] = 5000},
			{["neutron star"] = 40000},
		},

		["human spaces"] ={
			{["home"] = 2700},
			{["home workspace"] = 4000},
			{["executive"] = 3500},
			{["surgical"] = 5000},
			{["industrial"] = 7000},
			{["office"] = 4000},
			{["warehouse"] = 5000},
		},

		["variations of white"] = {
			{["true white"] = 6600},
			{["bright white"] = 5300},
			{["neutral white"] = 4000},
			{["cool white"] = 7000},
			{["soft white"] = 3000},
			{["warm white"] = 2700},
		},

		["technologies"] = {
			{["LCD"] = 9000},
			{["CRT"] = 7000},
			{["xenon"] = 6200},
			{["fluorescent"] = 4200},
			{["halogen"] = 3000},
			{["incandescent"] = 2500},
			{["candle"] = 1800},
			{["match"] = 1700},
			{["fire"] = 1500},
			{["heat"] = 1000},
		}
	}

	--extra keywords
	pac.temperature_color_keywords = {
		["white"] = 6600,
		["yellow"] = 4300,
		["golden yellow"] = 3000,
		["red"] = 900,
		["orange"] = 1400,
		["gold"] = 4000,
		["golden"] = 4000,
		["blue"] = 10000,
		["ice blue"] = 10000,
		["alpine white"] = 6000,

		["candlelight"] = 1800,
		["candle light"] = 1800,
		["candle flame"] = 1800,
		["lcd"] = 9000,
		["crt"] = 7000,
		["cathode"] = 7000,
		["cathode ray"] = 7000,
		["flame"] = 2000,

		["library"] = 2700,
		["friendly"] = 2700,
		["cozy"] = 2700,
		["inviting"] = 2700,
		["relaxing"] = 2500,
		["bedroom"] = 2700,
		["kitchen"] = 2800,
		["relax"] = 2500,
		["welcoming"] = 3000,
		["soft"] = 3500,

		["sharp"] = 4100,
		["focus"] = 4100,
		["alert"] = 4100,
		["neutral"] = 4500,
		["clean"] = 4000,
		["bright"] = 5000,
		["crisp"] = 4100,
		["harsh"] = 7000,
		["intense"] = 7000,
		["stasis"] = 10000,

		["hospital"] = 4000,
		["kitchen"] = 4000,
		["scientific"] = 6000,
		["laboratory"] = 6000,
		["lab"] = 6000,
		["stadium"] = 5000,
		["showroom"] = 5000,

		["task lighting"] = 4000,
		["security lighting"] = 5000,
		["overhead lighting"] = 3000,
		["vanity"] = 3000,
		["chandelier"] = 2700,
		["table lamp"] = 2700,
		["floor lamp"] = 2700,
		["fog light"] = 3200,
		["fog lights"] = 3200,
		["car headlights"] = 5000,
		["headlights"] = 5000,
	}

	for category,tbl in pairs(pac.temperature_color_keywords_categorized) do
		for i,tbl2 in ipairs(tbl) do
			local k,v = next(tbl2)
			pac.temperature_color_keywords[k] = v
		end
	end

	local function convert_temperature(kelvins)
		kelvins = kelvins / 100
		local r = 0
		if kelvins < 66 then
			r = 255
		else
			r = kelvins - 60
			r = math.Clamp(329.698727446 * (r ^ -0.1332047592),0,255)
		end

		local g = 0
		if kelvins <= 66 then
			g = kelvins
			g = math.Clamp(99.4708025861 * math.log(g) - 161.1195681661, 0, 255)
		else
			g = kelvins - 60
			g = 288.1221695283 * (g ^ -0.0755148492)
			g = math.Clamp(g, 0, 255)
		end

		local b = 0
		if kelvins >= 66 then
			b = 255
		else
			if kelvins <= 19 then
				b = 0
			else
				b = kelvins - 10
				b = math.Clamp(138.5177312231 * math.log(b) - 305.0447927307, 0, 255)
			end
		end
		return Color(r,g,b)
	end

	function pac.TemperatureToColor(kelvins)
		if not kelvins then return nil end
		if isstring(kelvins) then
			kelvins = string.lower(kelvins)
			if isnumber(tonumber(kelvins)) then
				return convert_temperature(tonumber(kelvins)), tonumber(kelvins)
			elseif pac.temperature_color_keywords[kelvins] then
				return convert_temperature(pac.temperature_color_keywords[kelvins]), pac.temperature_color_keywords[kelvins]
			elseif kelvins == "help" then
				pac.Message("Temperature to Color:")
				print("categorized list, slightly compressed so the combo box can be a bit more compact:")
				PrintTable(pac.temperature_color_keywords_categorized)
				print("=================")
				print("combined list:")
				PrintTable(pac.temperature_color_keywords)
				return nil
			end
		elseif isnumber(kelvins) then
			return convert_temperature(kelvins), kelvins
		end
		return nil
	end

	local collapsed_categories = {}
	function pac.OpenTemperatureToColorMenu(part, key, callback)
		pace.color_temperature_active_temp = 0
		if not part then part = pace.current_part end
		if not key then
			key = "Color"
			if part and part.ClassName == "material_3d" or part.ClassName == "material_2d" then
				key = "color2"
			end
		end
		if not callback then
			callback = function(str)
				local color, temp = pac.TemperatureToColor(str)
				if temp ~= nil then pace.color_temperature_active_temp = temp end
				local vec = color
				if part.ProperColorRange then
					vec = Vector(color.r/255,color.g/255,color.b/255)
				else
					vec = Vector(color.r,color.g,color.b)
				end
				part:SetProperty(key, vec)
			end
		end
		local frame = vgui.Create("DFrame")
		frame:SetSize(600, 200)
		frame:Center() frame:MakePopup()
		frame:SetTitle("Correlated Color Temperature Explorer")

		local pnl = vgui.Create("DPanel", frame)
		pnl:Dock(FILL)

		local combo = vgui.Create("DComboBox", pnl)
		combo:SetSortItems(false)
		combo:SetSize(300,20) combo:SetText("select references")
		combo:SetPos(0, 10)

		local text = vgui.Create("DTextEntry", pnl)
		text:SetSize(300,20) text:SetPlaceholderText("Temperature or keyword")
		text:SetPos(300, 10)

		local function add_category(key)
			local tbl = pac.temperature_color_keywords_categorized[key]
			combo:AddSpacer()
			combo:AddChoice(key, "collapse " .. key)
			combo:AddSpacer()
			if collapsed_categories[key] then return end
			for i,tbl2 in ipairs(tbl) do
				local k,v = next(tbl2)
				combo:AddChoice(k, v)
			end
			combo:AddChoice("")
		end
		--I want this order
		add_category("simplified temperatures")
		add_category("variations of white")
		add_category("human spaces")
		add_category("sunlight")
		add_category("technologies")
		add_category("astronomical references")
		
		local last_str = ""
		function text:OnEnter(str)
			if last_str ~= str then
				if str ~= nil and str ~= "" then
					callback(str)
				end
			end
			last_str = str
		end
		
		function combo:OnSelect(index, op_text, data)
			if data == nil then return end
			if string.StartsWith(data, "collapse ") then
				collapsed_categories[string.gsub(data, "collapse ", "")] = not collapsed_categories[string.gsub(data, "collapse ", "")]
				combo:Clear()
				add_category("simplified temperatures")
				add_category("variations of white")
				add_category("human spaces")
				add_category("sunlight")
				add_category("technologies")
				add_category("astronomical references")
				timer.Simple(0, function() combo:OpenMenu() end)
				return
			end
			text:OnEnter(data)
			text:SetText(op_text .. ": " .. data .. "K")
		end

		local strip = vgui.Create("DPanel", frame)
		strip:SetSize(500,50) strip:SetPos(50, 80)
		local strip_sub = vgui.Create("DLabel", frame)
		strip_sub:SetFont("TargetID")
		strip_sub:SetSize(500,15) strip_sub:SetPos(50, 80 + 5 + 50)
		strip_sub:SetTextColor(frame:GetSkin().Colours.Category.Line.Text)
		strip_sub:SetText("Hover over the strip...")
		local precalculated_pixel_tempcolors = {}
		for i=1,500 do
			precalculated_pixel_tempcolors[i] = pac.TemperatureToColor(math.Remap(i, 1, 500, 1000, 15000))
		end
		strip.Paint = function(w,h)
			for i=1,500 do
				local clr = precalculated_pixel_tempcolors[i]
				surface.SetDrawColor(clr)
				surface.DrawRect(i-1,0,1,h)
			end
			if CurTime() * 4 % 2 > 1 then
				surface.SetDrawColor(Color(0,0,0))
			else
				surface.SetDrawColor(Color(255,255,255))
			end
			surface.DrawRect(math.Remap(pace.color_temperature_active_temp,1000,15000,1,500),0,1,h)
		end
		strip.Think = function()
			local x,y = strip:ScreenToLocal(input.GetCursorPos())
			local kelvin = math.floor(math.Remap(x, 1, 500, 1000, 15000))
			if strip:IsHovered() and precalculated_pixel_tempcolors[x] ~= nil then
				pace.color_temperature_active_temp = kelvin
				strip_sub:SetText(kelvin .. "K : " .. tostring(precalculated_pixel_tempcolors[x]) .. " - Click to apply")
				strip_sub:SetTextColor(precalculated_pixel_tempcolors[x])
				if input.IsMouseDown(MOUSE_LEFT) then
					text:SetValue(kelvin)
					text:OnEnter(kelvin)
				end
			end
		end
	end
end
