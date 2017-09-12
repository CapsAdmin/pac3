local Vector = Vector
local Matrix = Matrix
local isstring = isstring

function pac.CopyMaterial(mat, shader)
	local copy = CreateMaterial(pac.uid("pac_copymat_") .. tostring({}), shader or mat:GetShader())
	for k,v in pairs(mat:GetKeyValues()) do
		local t = type(v)

		if t == "Vector" then
			copy:SetVector(k, v)
		elseif t == "number" then
			copy:SetFloat(k, v)
		elseif t == "Matrix" then
			copy:SetMatrix(k, v)
		elseif t == "ITexture" then
			copy:SetTexture(k, v)
		elseif t == "string" then
			copy:SetString(k, v)
		end
	end
	return copy
end

function pac.MakeMaterialUnlitGeneric(mat, id)
	local tex_path = mat:GetString("$basetexture")

	if tex_path then
		local params = {}

		params["$basetexture"] = tex_path
		params["$vertexcolor"] = 1
		params["$vertexalpha"] = 1

		return CreateMaterial(pac.uid("pac_fixmat_") .. id, "UnlitGeneric", params)
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

	function pac.RunNextFrame(id, func)
		pac.next_frame_funcs[id] = func
	end
end

do --dev util
	function pac.RemoveAllPACEntities()
		for _, ent in pairs(ents.GetAll()) do
			if ent.pac_parts then
				pac.UnhookEntityRender(ent)
				--ent:Remove()
			end

			if ent.IsPACEntity then
				ent:Remove()
			end
		end
	end

	function pac.Panic()
		pac.RemoveAllParts()
		pac.RemoveAllPACEntities()
		pac.Parts = {}
	end

	pac.convarcache = {}
	function pac.CreateClientConVarFast(cvar,initial,save,t,server)

		local cached = pac.convarcache[cvar]
		if cached then return cached[1],cached[2] end

		local val
		local c = CreateClientConVar(cvar,initial,save,server)
		--Msg("[FCVar] ",cvar,": ")

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

	local sv_allowcslua = GetConVar('sv_allowcslua')

	function pac.Restart()
		local editor_was_open
		local prev_parts = {}
		local pacLocal = _G.pac

		if pace and pace.Editor and pace.Editor:IsValid() then
			editor_was_open = true

			for key, part in pairs(pac.GetParts(true)) do
				if not part:HasParent() and part.show_in_editor ~= false then
					table.insert(prev_parts, part:ToTable())
				end
			end
		end

		if pac and pac.Disable then
			pacLocal.Message("removing all traces of pac3 from lua")
			pac.Disable()
			pac.Panic()

			if pace and pace.Editor then
				editor_was_open = pace.Editor:IsValid()
				pace.Panic()
			end

			for _, ent in pairs(ents.GetAll()) do
				for k in pairs(ent:GetTable()) do
					if k:sub(0, 4) == "pac_" then
						ent[k] = nil
					end
				end
			end

			for hook_name, hooks in pairs(hook.GetTable()) do
				for id, func in pairs(hooks) do
					if isstring(id) and (id:StartWith("pace_") or id:StartWith("pac_") or id:StartWith("pac3_") or id:StartWith("pacx_")) then
						hook.Remove(hook_name, id)
					end
				end
			end

			timer.Remove("pac_gc")
			timer.Remove("pac_render_times")
			timer.Remove("urlobj_download_queue")

			_G.pac = nil
			_G.pace = nil

			collectgarbage()
		end

		local loadingHit = false

		if sv_allowcslua:GetBool() then
			pacLocal.Message("pac_restart: sv_allowcslua is on, looking for PAC3 addon..")

			local _, dirs = file.Find("addons/*", "MOD")
			for _, dir in ipairs(dirs) do
				if file.Exists("addons/" .. dir .. "/lua/autorun/pac_editor_init.lua", "MOD") then
					pacLocal.Message("found PAC3 in garrysmod/addons/" .. dir)
					local old_include = _G.include

					local function include(path, ...)
						local new_path = path
						if not file.Exists("addons/" .. dir .. "/lua/" .. path, "MOD") then
							local src = debug.getinfo(2).source
							local lua_dir = src:sub(2):match("(.+/)")
							if lua_dir:StartWith("addons/" .. dir) then
								lua_dir = lua_dir:match("addons/.-/lua/(.+)")
							end
							new_path = lua_dir .. path
						end

						if file.Exists("addons/" .. dir .. "/lua/" .. new_path, "MOD") then
							local str = file.Read("addons/" .. dir .. "/lua/" .. new_path, "MOD")
							if str then
								local func = CompileString(str, "addons/" .. dir .. "/lua/" .. new_path)
								if type(func) == "function" then
									local res = {pcall(func, ...)}

									if res[1] then
										return unpack(res, 2)
									end

									pacLocal.Message("pac_restart: pcall error: " .. res[2])
								else
									pacLocal.Message("pac_restart: compile string error: " .. func)
								end
							end
						end

						pacLocal.Message("pac_restart: couldn't include " .. new_path .. " reverting to normal include")

						return old_include(path, ...)
					end

					_G.include = include

					for _, path in ipairs((file.Find("autorun/pac_*", "LUA"))) do
						if path:EndsWith("_init.lua") and path ~= "pac_init.lua" then
							pacLocal.Message("pac_restart: including autorun/" .. path .. "...")

							local ok, err = pcall(function()
								include("autorun/" .. path)
							end)

							if not ok then
								pacLocal.Message("pac_restart: error when reloading pac " .. err)
							end
						end
					end

					_G.include = old_include

					loadingHit = true
					break
				end
			end
		end

		if not loadingHit then
			pacLocal.Message("sv_allowcslua is not enabled or unable to find PAC3 in addons/, loading PAC3 again from server lua")

			for _, path in ipairs((file.Find("autorun/pac*", "LUA"))) do
				if path:EndsWith("_init.lua") and path ~= "pac_init.lua" then
					include("autorun/" .. path)
				end
			end
		end

		if editor_was_open then
			pace.OpenEditor()
		end

		pac.Enable()

		if prev_parts[1] then
			pace.LoadPartsFromTable(prev_parts, true)
		end

		pacLocal.Message("pac_restart: done")
	end

	concommand.Add("pac_restart", pac.Restart)
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

function pac.CalcEntityCRC(ent)
	local pos = ent:GetPos()
	local ang = ent:GetAngles()
	local mdl = ent:GetModel():lower():gsub("\\", "/")
	local x,y,z = math.Round(pos.x/10)*10, math.Round(pos.y/10)*10, math.Round(pos.z/10)*10
	local p,_y,r = math.Round(ang.p/10)*10, math.Round(ang.y/10)*10, math.Round(ang.r/10)*10

	local crc = x .. y .. z .. p .. _y .. r .. mdl

	return util.CRC(crc)
end

function pac.MakeNull(tbl)
	if tbl then
		for k in pairs(tbl) do
			tbl[k] = nil
		end
		setmetatable(tbl, getmetatable(pac.NULL))
	end
end

do
	local pac_error_mdl = CreateClientConVar("pac_error_mdl","1",true,false,"0 = default error, 1=custom error model, models/yourmodel.mdl")
	local tc

	function pac.FilterInvalidModel(mdl, fallback)
		if util.IsValidModel(mdl) or (not mdl) or (mdl == "") then
			return mdl
		end

		-- IsValidModel doesn't always return true... this is expensive though :(
		if file.Exists(mdl , "GAME") then
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
			return mdl
		elseif util.IsValidModel(str) then
			return str
		end

		if tc == nil then
			if util.IsValidModel("models/props_junk/PopCan01a.mdl") then
				tc = "models/props_junk/PopCan01a.mdl"
			else
				tc = "models/props_junk/popcan01a.mdl"
			end
		end

		return tc
	end
end

local pac_debug_clmdl = CreateClientConVar("pac_debug_clmdl","0",true)
function pac.CreateEntity(model, for_obj)
	model = pac.FilterInvalidModel(model)

	local ent

	if for_obj then
		ent = ClientsideModel(model)
	else
		ent = pac_debug_clmdl:GetBool() and ClientsideModel(model) or ents.CreateClientProp(model)
	end

	if not ent:IsValid() then
		pac.Message("Failed to create entity!")
	end

	--[[if type == 1 then

		ent = ClientsideModel(model)

	elseif type == 2 then

		ent = ents.CreateClientProp(model) -- doesn't render properly

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
	end]]

	return ent
end


do -- hook helpers
	local added_hooks = pac.added_hooks or {}

	function pac.AddHook(str, func)
		func = func or pac[str]

		local id = "pac_" .. str

		hook.Add(str, id, func)

		added_hooks[str] = {func = func, event = str, id = id}
	end

	function pac.RemoveHook(str)
		local data = added_hooks[str]

		hook.Remove(data.event, data.id)
	end

	function pac.CallHook(str, ...)
		return hook.Run("pac_" .. str, ...)
	end

	pac.added_hooks = added_hooks
end

do -- get set and editor vars
	pac.VariableOrder = pac.VariableOrder or {}
	pac.GroupOrder = pac.GroupOrder or {}
	pac.PropertyUserdata = pac.PropertyUserdata or {}
	pac.PropertyUserdata['base'] = pac.PropertyUserdata['base'] or {}

	local function insert_key(tbl, key)
		for _, k in ipairs(tbl) do
			if k == key then
				return
			end
		end

		table.insert(tbl, key)
	end

	local __store = false

	function pac.StartStorableVars()
		__store = true
		__group = nil
	end

	function pac.EndStorableVars()
		__store = false
		__group = nil
	end

	local __group = nil

	function pac.SetPropertyGroup(name)
		__group = name
		insert_key(pac.GroupOrder, name)
	end

	function pac.GetSet(tbl, key, def, udata)
		insert_key(pac.VariableOrder, key)

		pac.class.GetSet(tbl, key, def)

		if udata then
			pac.PropertyUserdata[tbl.ClassName] = pac.PropertyUserdata[tbl.ClassName] or {}
			pac.PropertyUserdata[tbl.ClassName][key] = pac.PropertyUserdata[tbl.ClassName][key] or {}
			table.Merge(pac.PropertyUserdata[tbl.ClassName][key], udata)
		end

		if __store then
			tbl.StorableVars = tbl.StorableVars or {}
			tbl.StorableVars[key] = key
		end

		if __group then
			pac.PropertyUserdata[tbl.ClassName] = pac.PropertyUserdata[tbl.ClassName] or {}
			pac.PropertyUserdata[tbl.ClassName][key] = pac.PropertyUserdata[tbl.ClassName][key] or {}
			pac.PropertyUserdata[tbl.ClassName][key].group = __group
		end
	end

	function pac.IsSet(tbl, key, ...)
		insert_key(key)
		pac.class.IsSet(tbl, key, ...)

		if __store then
			tbl.StorableVars = tbl.StorableVars or {}
			tbl.StorableVars[key] = key
		end
	end

	function pac.SetupPartName(PART, key, udata)
		PART.PartNameResolvers = PART.PartNameResolvers or {}

		local part_key = key
		local part_set_key = "Set" .. part_key

		local uid_key = part_key .. "UID"
		local name_key = key .. "Name"
		local name_set_key = "Set" .. name_key

		local last_uid_key = "last_" .. uid_key:lower()
		local try_key = "try_" .. name_key:lower()

		local name_find_count_key = name_key:lower() .. "_try_count"

		-- these keys are ignored when table is set. it's kind of a hack..
		PART.IngoreSetKeys = PART.IgnoreSetKeys or {}
		PART.IngoreSetKeys[name_key] = true

		pac.EndStorableVars()
			pac.GetSet(PART, part_key, pac.NULL)
		pac.StartStorableVars()

		pac.GetSet(PART, name_key, "", udata or {editor_panel = "part"})
		pac.GetSet(PART, uid_key, "", {hidden = true})

		PART.ResolvePartNames = PART.ResolvePartNames or function(self, force)
			for _, func in pairs(self.PartNameResolvers) do
				func(self, force)
			end
		end

		PART["Resolve" .. name_key] = function(self, force)
			PART.PartNameResolvers[part_key](self, force)
		end

		PART.PartNameResolvers[part_key] = function(self, force)
			if self[uid_key] == "" and self[name_key] == "" then return end

			if force or self[try_key] or self[uid_key] ~= "" and not IsValid(self[part_key]) then
				local part = pac.GetPartFromUniqueID(self.owner_id, self[uid_key])

				if IsValid(part) and part ~= self and self[part_key] ~= part then
					self[name_set_key](self, part)
					self[last_uid_key] = self[uid_key]
				elseif self[try_key] and not self.supress_part_name_find then -- match by name instead
					for _, part in pairs(pac.GetParts()) do
						if
							part ~= self and
							self[part_key] ~= part and
							part:GetPlayerOwner() == self:GetPlayerOwner() and
							part:GetName() == self[name_key]
						then
							self[name_set_key](self, part)
							break
						end

						self[last_uid_key] = self[uid_key]
					end

					self[try_key] = false
				end
			end
		end

		PART[name_set_key] = function(self, var)
			self[name_find_count_key] = 0

			if type(var) == "string" then
				self[name_key] = var

				if var == "" then
					self[uid_key] = ""
					self[part_key] = pac.NULL
					return
				else
					self[try_key] = true
				end

				timer.Simple(0, function() PART.PartNameResolvers[part_key](self) end)
			else
				self[name_key] = var.Name and var.Name ~= '' and var.Name or var:GetName()
				self[uid_key] = var.UniqueID
				self[part_set_key](self, var)
			end
		end
	end

	function pac.RemoveProperty(PART, key)
		pac.class.RemoveField(PART, key)
		if pac.PropertyUserdata[PART.ClassName] then
			pac.PropertyUserdata[PART.ClassName][key] = nil
		end
		if PART.StorableVars then
			PART.StorableVars[key] = nil
		end
	end

	function pac.GetPropertyUserdata(obj, key)
		if pac.PropertyUserdata[obj.ClassName] and pac.PropertyUserdata[obj.ClassName][key] then
			return pac.PropertyUserdata[obj.ClassName][key]
		end

		if pac.PropertyUserdata.base and pac.PropertyUserdata.base[key] then
			return pac.PropertyUserdata.base[key]
		end

		return {}
	end
end

function pac.Material(str, part)
	if str == "" then return end

	for _, part in pairs(pac.GetParts()) do
		if part.GetRawMaterial and str == part.Name then
			return part:GetRawMaterial()
		end
	end

	return Material(str)
end

do
	--TODO: Table keeping id -> idx mapping
	local idx = 0
	function pac.uid(id)
		idx = idx + 1
		if idx>=2^53 then
			ErrorNoHalt("?????BUG???? Pac UIDs exhausted\n")
			idx = 0
		end

		return ("%s%d"):format(id, idx)
	end
end

function pac.FixupURL(url)
	if url and isstring(url) then
		url = url:Trim()
		if url:find("dropbox",1,true) then
			url = url:gsub([[^http%://dl%.dropboxusercontent%.com/]],[[https://dl.dropboxusercontent.com/]])
			url = url:gsub([[^https?://www.dropbox.com/s/(.+)%?dl%=[01]$]],[[https://dl.dropboxusercontent.com/s/%1]])
			url = url:gsub([[^https?://www.dropbox.com/s/(.+)$]],[[https://dl.dropboxusercontent.com/s/%1]])
		end

		url = url:gsub([[^http%://onedrive%.live%.com/redir?]],[[https://onedrive.live.com/download?]])
		url = url:gsub( "pastebin.com/([a-zA-Z0-9]*)$", "pastebin.com/raw.php?i=%1")
		url = url:gsub( "github.com/([a-zA-Z0-9_]+)/([a-zA-Z0-9_]+)/blob/", "github.com/%1/%2/raw/")
	end
	return url
end

function pac.Handleurltex(part, url, callback, shader, additionalData)
	if url and pac.urltex and url:find("http") then
		local skip_cache = url:sub(1,1) == "_"

		url = url:match("http[s]-://.+/.-%.%a+")

		if url then

			pac.FixupURL(url)

			pac.urltex.GetMaterialFromURL(
				url,
				function(mat, tex)
					if part:IsValid() then
						if callback then
							callback(mat, tex)
						else
							part.Materialm = mat
							part:CallEvent("material_changed")
						end
						pac.dprint("set custom material texture %q to %s", url, part:GetName())
					end
				end,
				skip_cache,
				shader,
				nil,
				nil,
				additionalData
			)
			return true
		end
	end
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
			ent:EnableMatrix("RenderMultiply", mat)
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

function pac.HideWeapon(wep, hide)
	if wep.pac_hide_weapon == true then
		wep:SetNoDraw(true)
		wep.pac_wep_hiding = true
		return
	end
	if hide then
		wep:SetNoDraw(true)
		wep.pac_wep_hiding = true
	else
		if wep.pac_wep_hiding then
			wep:SetNoDraw(false)
			wep.pac_wep_hiding = false
		end
	end
end

-- this function adds the unique id of the owner to the part name to resolve name conflicts
-- hack??

function pac.HandlePartName(ply, name)
	if ply:IsValid() then
		if ply:IsPlayer() and ply ~= pac.LocalPlayer then
			return ply:UniqueID() .. " " .. name
		end

		if not ply:IsPlayer() then
			return pac.CallHook("HandlePartName", ply, name) or (ply:EntIndex() .. " " .. name)
		end
	end

	return name
end

local function int_to_bytes(num,endian,signed)
    if num<0 and not signed then num=-num print"warning, dropping sign from number converting to unsigned" end
    local res={}
    local n = math.ceil(select(2,math.frexp(num))/8) -- number of bytes to be used.
    if signed and num < 0 then
        num = num + 2^n
    end
    for k=n,1,-1 do -- 256 = 2^8 bits per char.
        local mul=2^(8*(k-1))
        res[k]=math.floor(num/mul)
        num=num-res[k]*mul
    end
    assert(num==0)
    if endian == "big" then
        local t={}
        for k=1,n do
            t[k]=res[n-k+1]
        end
        res=t
    end
    return string.char(unpack(res))
end

function pac.DownloadMDL(url, callback, onfail, ply)
	return pac.resource.Download(url, function(path)
		local id = util.CRC(ply:UniqueID() .. url .. file.Read(path) .. os.clock())
		local dir = "pac3/" .. id .. "/"

		local f = file.Open(path, "rb", "DATA")

		local found = false
		local files = {}

		local ok, err = pcall(function()
			for i = 1, 128 do
				local pos = f:Tell()

				local sig = f:ReadLong()

				if sig == 0x02014b50 then break end

				assert(sig == 0x04034b50, "bad zip signature (file is not a zip?)")
				f:Seek(pos+6) assert(f:ReadShort() == 0, "general purpose bitflag is set")
				f:Seek(pos+8) assert(f:ReadShort() == 0, "compression method is not 0 (don't use compression)")
				f:Seek(pos+14) local crc = f:ReadShort()
				f:Seek(pos+18) local size2 = f:ReadLong()
				f:Seek(pos+22) local size = f:ReadLong()
				assert(size == size2, "compression?")
				f:Seek(pos+26) local file_name_length = f:ReadShort()
				local extra_field_length = f:ReadShort()

				local name = f:Read(file_name_length)

				if not name:EndsWith(".vtf") and not name:EndsWith(".vmt") then
					name = name:gsub(".-(%..+)", "model%1"):lower()
				end

				f:Skip(extra_field_length)

				local buffer = f:Read(size)

				if name:EndsWith(".mdl") then
					--local path = buffer:sub(13, 12+64)
					--buffer = buffer:gsub(path, mdl_dir .. "model.mdl")
					found = true
				end

				table.insert(files, {file_name = name, buffer = buffer, crc = crc})
			end
		end)

		if not ok then
			onfail(err)
			return
		end

		if not found then
			for k,v in pairs(files) do
				print(v.file_name, string.NiceSize(#v.buffer))
			end
			onfail("mdl not found in archive")
			return
		end

		do -- hex models
			local found_directories = {}

			for i, data in ipairs(files) do
				if data.file_name:EndsWith(".mdl") then
					file.Write("pac3_cache/temp.dat", data.buffer)

					local f = file.Open("pac3_cache/temp.dat", "rb", "DATA")
					local id = f:Read(4)
					local version = f:ReadLong()
					local checksum = f:ReadLong()
					local name_offset = f:Tell()
					local name = f:Read(64)
					local size_offset = f:Tell()
					local size = f:ReadLong()

					f:Skip(12 * 6) -- skips over all the vec3 stuff

					f:Skip(4) -- flags
					f:Skip(8 * 7)

					local vtf_dir_count = f:ReadLong()
					local vtf_dir_offset = f:ReadLong()

					f:Seek(vtf_dir_offset)

					local done = {}

					for i = 1, vtf_dir_count do
						local offset = f:ReadLong()
						local old_pos = f:Tell()
						if not offset then break end

						f:Seek(offset)

						local chars = {}
						for i = 1, 64 do
							local b = f:ReadByte()
							if not b or b == 0 then break end
							table.insert(chars, string.char(b))
						end

						local dir = table.concat(chars)
						table.insert(found_directories, {offset = offset, dir = dir})

						f:Seek(old_pos)
					end

					f:Close()

					local buffer = file.Read("pac3_cache/temp.dat")
					file.Delete("pac3_cache/temp.dat")

					local newdir = dir
					newdir = newdir:gsub("/", "\\")

					for i,v in ipairs(found_directories) do
						if #newdir < #v.dir then
							newdir = newdir .. ("\0"):rep(#v.dir - #newdir + 1)
						end

						buffer = (buffer:sub(0, v.offset) .. newdir .. buffer:sub(v.offset + #v.dir + 1)):sub(0, size)
					end

					local newname = (dir .. data.file_name:lower()):gsub("/", "\\")

					do
						local newname = newname
						if #newname < #name then
							newname = newname .. ("\0"):rep(#name - #newname)
						end

						buffer = buffer:sub(0, name_offset) .. newname .. buffer:sub(name_offset + #name + 1)
					end

					--buffer = buffer:Replace(name:match("^(.+%.mdl)"), newname)
					--buffer = buffer:sub(0, size_offset) .. int_to_bytes(#buffer) .. buffer:sub(size_offset + 4 - 1)

					data.buffer = buffer
					data.crc = int_to_bytes(tonumber(util.CRC(data.buffer)))
					break
				end
			end


			for i, data in ipairs(files) do
				if not data.file_name:EndsWith(".mdl") then
					if data.file_name:EndsWith(".vmt") then
						local newdir = dir

						data.buffer = data.buffer:lower():gsub("\\", "/")

						for _, info in ipairs(found_directories) do
							data.buffer = data.buffer:gsub(info.dir:gsub("\\", "/"):lower(), newdir)
						end

						data.crc = int_to_bytes(tonumber(util.CRC(data.buffer)))
					end
				end
			end
		end

		local f = file.Open("pac3_cache/downloads/" .. id .. ".dat", "wb", "DATA")

		if not f then
			onfail("unable to open file for writing")
			return
		end

		f:Write("GMAD")
		f:WriteByte(3)
		f:WriteLong(0)f:WriteLong(0)
		f:WriteLong(0)f:WriteLong(0)
		f:WriteByte(0)
		f:Write("name here")f:WriteByte(0)
		f:Write("description here")f:WriteByte(0)
		f:Write("author here")f:WriteByte(0)
		f:WriteLong(1)

		for i, data in ipairs(files) do
			f:WriteLong(i)
			if data.file_name:EndsWith(".vtf") or data.file_name:EndsWith(".vmt") then
				f:Write("materials/" .. dir .. data.file_name:lower())f:WriteByte(0)
			else
				f:Write("models/" .. dir .. data.file_name:lower())f:WriteByte(0)
			end
			f:WriteLong(#data.buffer)f:WriteLong(0)
			f:WriteLong(data.crc)
		end

		f:WriteLong(0)

		for i, data in ipairs(files) do
			f:Write(data.buffer)
		end

		f:Flush()

		local content = file.Read("pac3_cache/downloads/" .. id .. ".dat", "DATA")
		f:Write(util.CRC(content))
		f:Close()

		local ok, tbl = game.MountGMA("data/pac3_cache/downloads/" .. id .. ".dat")

		if not ok then
			onfail("failed to mount gma mdl")
			return
		end

		for k,v in pairs(tbl) do
			if v:EndsWith(".mdl") then
				callback(v)
				file.Delete("pac3_cache/downloads/" .. id .. ".dat")
				break
			end
		end
	end)
end
