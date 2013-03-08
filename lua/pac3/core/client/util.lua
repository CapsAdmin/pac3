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

function pac.dprint(fmt, ...)
	if pac.debug then
		MsgN("\n")	
		MsgN(">>>PAC3>>>")
		MsgN(fmt:format(...))
		if pac.debug_trace then
			MsgN("==TRACE==")
			debug.Trace()
			MsgN("==TRACE==")
		end
		MsgN("<<<PAC3<<<")
		MsgN("\n")
	end
end

function pac.IsValidEntity(var)
	return IsEntity(var) and var:IsValid()
end

function pac.GetValidEntity(var)
	return pac.IsValidEntity(var) and var
end

function pac.MakeNull(tbl)
	if tbl then
		for k,v in pairs(tbl) do tbl[k] = nil end
		setmetatable(tbl, pac.NULLMeta)
	end
end

pac.EntityType = 2

function pac.CreateEntity(model, type)
	type = type or pac.EntityType or 1

	local ent = NULL

	if type == 1 then

		ent = ClientsideModel(model)

	elseif type == 2 then

		ent = ents.CreateClientProp()
		ent:SetModel(model)

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

	return ent
end


do -- hook helpers
	pac.Errors = {}

	function pac.AddHook(str, func)
		func = func or pac[str]
		hook.Add(str, "pac_" .. str, function(...)
			local args = {pcall(func, ...)}
			if not args[1] then
				ErrorNoHalt("[pac3]" .. str .. " : " .. args[2] .. "\n")
				--pac.RemoveHook(str)
				table.insert(pac.Errors, args[2])
			end
			table.remove(args, 1)
			return unpack(args)
		end)
	end

	function pac.RemoveHook(str)
		if hook.GetTable()[str] and hook.GetTable()[str]["pac_" .. str] then
			hook.Remove(str, "pac_" .. str)
		end
	end

	function pac.CallHook(str, ...)
		return hook.Call("pac_" .. str, GAMEMODE, ...)
	end
end

do -- get set and editor vars
	pac.VariableOrder = {}
	
	local __store = false

	function pac.StartStorableVars()
		__store = true
	end

	function pac.EndStorableVars()
		__store = false
	end

	function pac.GetSet(tbl, key, ...)
		table.insert(pac.VariableOrder, key)
		
		pac.class.GetSet(tbl, key, ...)

		if __store then
			tbl.StorableVars = tbl.StorableVars or {}
			tbl.StorableVars[key] = key
		end
	end

	function pac.IsSet(tbl, key, ...)
		table.insert(pac.VariableOrder, key)
		pac.class.IsSet(tbl, key, ...)

		if __store then
			tbl.StorableVars = tbl.StorableVars or {}
			tbl.StorableVars[key] = key
		end
	end
	
	function pac.SetupPartName(PART, key)
		table.insert(pac.VariableOrder, key)
		
		PART.PartNameResolvers = PART.PartNameResolvers or {}
		
		local part_key = key
		local part_uid_key = part_key .. "UID"
		local part_set_key = "Set" .. part_key
		
		local name_key = key.."Name"
		local name_set_key = "Set" .. name_key
		
		local last_key = "last_" .. name_key:lower()
		local try_key = "try_" .. name_key:lower()
		
		local name_find_count_key = name_key:lower() .. "_try_count"
		
		pac.EndStorableVars()
			pac.GetSet(PART, part_key, pac.NULL)
		pac.StartStorableVars()
		
		pac.GetSet(PART, name_key, "")
		pac.GetSet(PART, part_uid_key,"")
					
		PART.ResolvePartNames = PART.ResolvePartNames or function(self)
			for key, func in pairs(self.PartNameResolvers) do
				func(self)
			end
		end		
				
		PART["Resolve" .. name_key] = function(self)
			PART.PartNameResolvers[part_key](self)
		end
		
		PART.PartNameResolvers[part_key] = function(self)
	
			if 
				(self[part_uid_key] == "" and (self[name_find_count_key] or 0) < 3)or
				self[part_uid_key] and 
				self[part_uid_key] ~= self[last_key] and 
				(not self[part_key]:IsValid() or self[try_key])
			then
				for key, part in pairs(pac.GetParts()) do
					if 
						part ~= self and 
						self[part_key] ~= part and 
						part:GetPlayerOwner() == self:GetPlayerOwner() and 
						part.UniqueID == self[part_uid_key] 
					then
						self[name_set_key](self, part)
						break
					end
				end

				if not self.supress_part_name_find then					
					for key, part in pairs(pac.GetParts()) do
						if 
							part ~= self and 
							self[part_key] ~= part and 
							part:GetPlayerOwner() == self:GetPlayerOwner() and 
							self[name_key] == part.Name
						then
							self[name_set_key](self, part)
							break
						end
					end
					
					self[name_find_count_key] = (self[name_find_count_key] or 0) + 1
				end
				
				self[last_key] = self[part_uid_key] 
				self[try_key] = false
			end
		end
		
		PART[name_set_key] = function(self, var)
			self[name_find_count_key] = 0
			
			if type(var) == "string" then
				self[name_key] = var
				self[try_key] = true
				
				if self.supress_part_name_find then
					PART.PartNameResolvers[part_key](self)
				end
			else
				--self[part_uid_key] = nil
				--self[part_key] = pac.NULL
							
				self[name_key] = var:GetName()
				self[part_uid_key] = var.UniqueID
				self[part_set_key](self, var)
			end
		end			
	end
end

function pac.Material(str, part)
	for key, part in pairs(pac.GetParts()) do
		if str == part:GetName() and part.GetRawMaterial then
			return part:GetRawMaterial()
		end
	end
	
	return Material(str)
end

function pac.Handleurltex(part, url, callback)
	if url and pac.urltex and url:find("http") then	
		local skip_cache = url:sub(1,1) == "_"
		url = url:gsub("https://", "http://")
		url = url:match("http[s]-://.+/.-%.%a+")
		if url then
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
				skip_cache
			)
			return true
		end
	end	
end

local mat
local Matrix = Matrix

function pac.SetModelScale(ent, scale, size)
	if not ent:IsValid() then return end
	if ent.pac_bone_scaling then return end

	if scale then
		mat = Matrix()
		mat:Scale(scale)
		ent:EnableMatrix("RenderMultiply", mat)
		ent.pac_model_scale = scale
	end
	
	if size then
		ent:SetModelScale(size == 1 and 1.000001 or size, 0)
	end
	
	if not scale and not size then
		ent:DisableMatrix("RenderMultiply")
	end
end

-- no need to rematch the same pattern
pac.PatternCache = {{}}

function pac.StringFind(a, b, simple, case_sensitive)
	if not a or not b then return end
	
	if simple and not case_sensitive then
		a = a:lower()
		b = b:lower()
	end
		
	pac.PatternCache[a] = pac.PatternCache[a] or {}
		
	if pac.PatternCache[a][b] ~= nil then
		return pac.PatternCache[a][b]
	end
		
	if simple and a:find(b, nil, true) or not simple and a:find(b) then
		pac.PatternCache[a][b] = true
		return true
	else
		pac.PatternCache[a][b] = false
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
	if ply:IsPlayer() and ply ~= pac.LocalPlayer then
		return ply:UniqueID() .. " " .. name
	end
	
	if not ply:IsPlayer() and ply:IsValid() then	
		return pac.CallHook("HandlePartName", ply, name) or (ply:EntIndex() .. " " .. name)
	end

	return name
end
