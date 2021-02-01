local PART = {}

PART.ClassName = "script"
PART.NonPhysical = true
PART.ThinkTime = 0
PART.Group = 'advanced'
PART.Icon = 'icon16/page_white_gear.png'

pac.StartStorableVars()
	pac.GetSet(PART, "Code", "")
pac.EndStorableVars()

local blacklist = {
	"do",
	"end",
	"function",
	"repeat",
	"while",
}

local lib =
{
	math = {
		pi = math.pi,
		random = math.random,
		abs = math.abs,
		acos = math.acos,
		asin = math.asin,
		atan = math.atan,
		atan2 = math.atan2,
		ceil = math.ceil,
		cos = math.cos,
		cosh = math.cosh,
		deg = math.deg,
		exp = math.exp,
		floor = math.floor,
		frexp = math.frexp,
		ldexp = math.ldexp,
		log = math.log,
		log10 = math.log10,
		max = math.max,
		min = math.min,
		rad = math.rad,
		sin = math.sin,
		sinh = math.sinh,
		sqrt = math.sqrt,
		tanh = math.tanh,
		tan = math.tan,

		clamp = math.Clamp,
		randomx = math.Rand,
	},

	string = {
		find = string.find,
	}
}


local function translate_xyz(x, y, z, T, def)
	if T == "Vector" then

		def.x = x or def.x
		def.y = y or def.y
		def.z = z or def.z

		return def
	elseif T == "Angle" then

		def.p = x or def.p
		def.y = y or def.y
		def.r = z or def.r

		return def
	elseif T == "number" then
		return tonumber(x) or def -- inf protection here
	elseif T == "string"  then
		return tostring(x)
	end
end

local function translate_value(val, T)
	if T == "Vector" then
		return val.x, val.y, val.z
	elseif T == "Angle" then
		return val.p, val.y, val.r
	elseif T == "number" or T == "string"  then
		return val
	end
end

local function CreateDummies(parts)

	local obj = {
		SetProperty = function(_, key, x, y, z)
			if not key then return end

			for _, v in pairs(parts) do
				if v:IsValid() and v.StorableVars[key] then
					local def = v[key]
					local val = translate_xyz(x ,y, z, type(def), def)

					v["Set" .. key](v, val)
				end
			end
		end,

		EventHide = function(_, b)
			for _, v in pairs(parts) do
				if v:IsValid() then
					v:SetEventHide(not not b, self)
				end
			end
		end,

		EventShow = function(_, b)
			for _, v in pairs(parts) do
				if v:IsValid() then
					v:SetEventHide(not b, self)
				end
			end
		end
	}

	return obj
end

local function CreateDummy(part, store, self)
	if not part or not part:IsValid() then return end
	if part.dummy_part then return part.dummy_part end

	store.parts[part.UniqueID] = {}

	local META =
	{
		SetProperty = function(_, key, x, y, z)
			if key and part.StorableVars[key] then
				local def = part[key]
				local val = translate_xyz(x ,y, z, type(def), def)

				part["Set" .. key](part, val)
			end
		end,

		GetProperty = function(_, key)
			if key and part.StorableVars[key] then
				local val = part["Get" .. key](part)

				if val then
					local x, y, z = translate_value(val, type(val))

					if x then
						return x, y, z
					end
				end
			end
		end,

		EventHide = function(_, b)
			part:SetEventHide(not not b, self)
		end,

		EventShow = function(_, b)
			part:SetEventHide(not b, self)
		end,

		GetChildren = function()
			return CreateDummies(part:GetChildren(), self)
		end,

	}

	local obj = setmetatable(
		{},
		{
			__index = function(_, key)
				if not part:IsValid() then return end

				if store.parts[part.UniqueID][key] then
					return store.parts[part.UniqueID][key]
				end

				return META[key]
			end,

			__newindex = function(_, key, val)
				if not part:IsValid() then return end

				store.parts[part.UniqueID][key] = val
			end,
		}
	)

	part.dummy_part = obj

	return obj
end

local function get_entity(part)
	local ent = part:GetOwner(true)
	return ent == pac.LocalPlayer:GetViewModel() and pac.LocalPlayer or ent
end

function PART:CompileCode()
	local code = self.Code

	for _, word in pairs(blacklist) do
		if code:find("[%p%s]" .. word) or code:find(word .. "[%p%s]") then
			return false, string.format("illegal characters used %q", word)
		end
	end

	local func = CompileString(code, "SCRIPT_ENV", false)

	if type(func) == "string" then
		return false, func
	end

	local store = {globals = {}, parts = {}}

	local extra_lib =
	{
		print = function(...)
			if self:GetPlayerOwner() == LocalPlayer() then
				print(...)

				local str = ""
				local count = select("#", ...)

				for i = 1, count do
					str = str .. tostring(select(i, ...))
					if i ~= count then
						str = str .. ", "
					end
				end

				self.script_printing = str
			end
		end,

		owner = {
			GetFOV = function()
				local ent = get_entity(self)

				if ent:IsValid() then
					return ent:GetFOV()
				end
			end,

			GetHealth = function()
				local ent = get_entity(self)

				if ent:IsValid() then
					return ent:Health()
				end
			end,
		},

		parts = {
			GetParent = function(level)
				level = level or 1
				local parent = self

				for _ = 1, math.Clamp(level, 1, 30) do
					parent = parent:GetParent()
				end

				return CreateDummy(parent, store, self)
			end,

			FindMultiple = function(str)
				local parts = {}

				for _, part in pairs(pac.GetParts()) do
					if
						part:GetPlayerOwner() == self:GetPlayerOwner() and
						pac.StringFind(part:GetName(), str)
					then
						table.insert(parts, part)
					end
				end

				return CreateDummies(parts, self)
			end,

			FindMultipleWithProperty = function()
				local parts = {}

				for key, part in pairs(pac.GetParts()) do
					if
						part:GetPlayerOwner() == self:GetPlayerOwner() and
						part.StorableVars[key] and
						part["Get" .. key] and part["Get" .. key]()
					then
						table.insert(parts, part)
					end
				end

				return CreateDummies(parts, self)
			end,

			Find = function(str)
				for _, part in pairs(pac.GetParts()) do
					if
						part:GetPlayerOwner() == self:GetPlayerOwner() and
						(part.UniqueID == str or part:GetName() == str)
					then
						return CreateDummy(part, store, self)
					end
				end
			end,
		}
	}

	local env = {}

	env.__index = function(_, key)
		if key == "this" or key == "self" then
			return CreateDummy(self, store, self)
		end

		if key == "T" or key == "TIME" then
			return RealTime()
		end

		if key == "CT" or key == "CURTIME" then
			return CurTime()
		end

		if lib[key] then
			return lib[key]
		end

		if extra_lib[key] then
			return extra_lib[key]
		end

		if store[key] then
			return store[key]
		end
	end

	env.__newindex = function(_, key, val)
		store[key] = val
	end

	self.valid_functions = {
		SetProperty = "m",
		GetProperty = "m",
		GetChildren = "m",
		EventHide = "m",
		EventShow = "m",
		self = "e",
		this = "e",
		T = "e",
		TIME = "e",
		CT = "e",
		CURTIME = "e"
	}

	local function scan(tbl)
		for key, val in pairs(tbl) do
			self.valid_functions[key] = val

			if type(val) == "table" then
				scan(val)
			end
		end
	end

	scan(lib)
	scan(extra_lib)

	setfenv(func, setmetatable({}, env))

	return true, func
end

function PART:ShouldHighlight(str)
	return self.valid_functions and self.valid_functions[str]
end

function PART:SetCode(code)
	self.Code = code
	local ok, func = self:CompileCode()

	if ok then
		self.func = func
		self.Error = nil
	else
		self.Error = func
		self.func = nil
	end
end

function PART:OnThink()
	if self.func then
		local ok, err = pcall(self.func)
		if not ok then
			self.Error = err
			self.func = nil
		else
			self.Error = nil
		end
	end
end

concommand.Add("pac_register_script_part", function()
	pac.RegisterPart(PART)
end)