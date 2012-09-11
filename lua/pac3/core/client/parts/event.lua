local PART = {}

PART.ClassName = "event"
PART.NonPhysical = true
PART.ThinkTime = 0

pac.StartStorableVars()
	pac.GetSet(PART, "Event", "")
	pac.GetSet(PART, "Arguments", "")
	pac.GetSet(PART, "Operator", "find simple")
	pac.GetSet(PART, "Invert", false)
	pac.GetSet(PART, "RootOwner", false)
pac.EndStorableVars()

PART.Events = 
{
	speed = 
	{
		arguments = {{speed = "number"}},
		callback = function(self, ent, num)
			return self:NumberOperator(ent:GetVelocity():Length(), num)
		end,
	},
	
	is_under_water = 
	{
		arguments = {{speed = "number"}},
		callback = function(self, ent, num) 
			return self:NumberOperator(ent:WaterLevel(), num)
		end,
	},
	
	is_flashlight_on = 
	{ 
		
		callback = function(self, ent)
			return ent.FlashlightIsOn and ent:FlashlightIsOn()
		end,
	},
	
	is_on_ground = 
	{ 
		
		callback = function(self, ent)
			return ent.IsOnGround and ent:IsOnGround()
		end,
	},
	
	is_voice_chatting =
	{ 
		
		callback = function(self, ent)
			return ent.IsSpeaking and ent:IsSpeaking()
		end,
	},
	
	ammo = 
	{
		arguments = {{primary = "boolean"}, {amount = "number"}},
		callback = function(self, ent, primary, amount)
			local ent = ent.GetActiveWeapon and ent:GetActiveWeapon() or NULL
			if ent:IsValid() then
				return self:NumberOperator(primary and ent:Clip1() or ent:Clip2(), amount)
			end
		end,
	},
	
	vehicle_class =
	{
		arguments = {{find = "string"}},
		callback = function(self, ent, find)
			local ent = ent.GetVehicle and ent:GetVehicle() or NULL
			if ent:IsValid() then
				return self:StringOperator(ent:GetClass(), find)
			end
		end,
	},
	
	entity_class =
	{
		arguments = {{find = "string"}},
		callback = function(self, ent, find)
			return self:StringOperator(ent:GetClass(), find)
		end,
	},
	
	weapon_class =
	{
		arguments = {{find = "string"}, {hide = "boolean"}},
		callback = function(self, ent, find, hide)
			local ent = ent.GetActiveWeapon and ent:GetActiveWeapon() or NULL
			if ent:IsValid() then
				if self:StringOperator(ent:GetClass(), find) then
					pac.HideWeapon(ent, hide)
					return true
				end
			end
		end,
	},	
	
	has_weapon =
	{
		arguments = {{find = "string"}},
		callback = function(self, ent, find)
			local tbl = ent.GetWeapons and ent:GetWeapons()
			if tbl then
				for key, val in pairs(tbl) do
					val = val:GetClass()
					if self:StringOperator(val, find) then
						return true
					end
				end
			end
		end,
	},
	
	model_name =
	{
		arguments = {{find = "string"}},
		callback = function(self, ent, find)
			return self:StringOperator(ent:GetModel(), find)
		end,
	},
	
	sequence_name =
	{
		arguments = {{find = "string"}},
		callback = function(self, ent, find)
			return self:StringOperator(ent:GetSequenceName(ent:GetSequence()), find)
		end,
	},
	
	timer =
	{
		arguments = {{interval = "number"}, {offset = "number"}},
		callback = function(self, ent, interval, offset)
			interval = interval or 1
			offset = offset or 0
			
			return (CurTime() + offset)%interval > (interval / 2)
		end,
	},
	
	animation_event =
	{
		arguments = {{find = "string"}, {time = "number"}},
		callback = function(self, ent, find, time)
			time = time or 0.1
			
			local data = ent.pac_anim_event 
			
			if data and self:StringOperator(data.name, find) and data.time + time > RealTime() then
				return true
			end			
		end,
	},

	command =
	{
		arguments = {{find = "string"}, {time = "number"}},
		callback = function(self, ent, find, time)
			time = time or 0.1
			
			local data = ent.pac_command_event 
			
			if data and self:StringOperator(data.name, find) and data.time + time > RealTime() then
				return true
			end			
		end,
	},
	
	say =
	{
		arguments = {{find = "string"}, {time = "number"}, {owner = "boolean"}},
		callback = function(self, ent, find, time, owner)
			time = time or 0.1
			
			if owner then
				owner = self:GetOwner(true)
				if owner:IsValid() then
					local data = owner.pac_say_event 
					
					if data and self:StringOperator(data.str, find) and data.time + time > RealTime() then
						return true
					end
				end
			else
				for key, ply in pairs(player.GetAll()) do
					local data = ent.pac_say_event 
					
					if data and self:StringOperator(data.str, find) and data.time + time > RealTime() then
						return true
					end			
				end
			end
		end,
	},
}

function PART:OnThink()
	local ent = self:GetOwner(self.RootOwner)
	
	if ent:IsValid() then
		local data = self.Events[self.Event]
		
		if data then
			local parent = self:GetParent()
			if parent:IsValid() then
				if self:IsHidden() then
					parent:SetEventHide(self.Invert)
				elseif self.Invert then
					parent:SetEventHide(not (data.callback(self, ent, self:GetParsedArguments(data.arguments)) or false) )
				else
					parent:SetEventHide((data.callback(self, ent, self:GetParsedArguments(data.arguments)) or false) )
				end
			end
		end
	end
end

PART.Operators = 
{
	"equal",
	"not equal",
	"above",
	"equal or above",
	"below",
	"equal or below",

	"find",
	"find simple",
	
	"maybe",
}

pac.EventArgumentCache = {}

function PART:ParseArguments(...)
	local str = ""
	local args = {...}
	
	for key, val in ipairs(args) do
		local T = type(val)
		
		if T == "boolean" then
			val = val and "1" or "0"
		elseif T == "string" then
			val = tostring(val) or ""
		elseif T == "number" then
			val = tostring(val) or "0"
		end
		
		if key == #args then
			str = str .. val
		else
			str = str .. val .. "@@"
		end
	end
		
	self.Arguments = str
end

function PART:GetParsedArguments(data)
	if not data then return end

	local line = self.Arguments
	local hash = line .. tostring(data)
	
	if pac.EventArgumentCache[hash] then
		return unpack(pac.EventArgumentCache[hash])
	end

	local args = line:Split("@@")
	
	for pos, arg in ipairs(data) do
		local nam, typ = next(arg)
		if not args[pos] then 
			break
		elseif typ == "boolean" then
			args[pos] = tonumber(args[pos]) ~= 0
		elseif typ == "number" then
			args[pos] = tonumber(args[pos]) or 0
		elseif typ == "string" then
			args[pos] = tostring(args[pos]) or ""
		end
	end
	
	pac.EventArgumentCache[hash] = args
		
	return unpack(args)
end

function PART:StringOperator(a, b)
	if not self.Operator or not a or not b then
		return false
	elseif self.Operator == "equal" then
		return a == b
	elseif self.Operator == "not equal" then
		return a ~= b
	elseif self.Operator == "find" then
		return pac.StringFind(a, b)
	elseif self.Operator == "find simple" then
		return pac.StringFind(a, b, true)
	elseif self.Operator == "maybe" then
		return math.random() > 0.5
	end	
end

function PART:NumberOperator(a, b)
	if not self.Operator or not a or not b then
		return false
	elseif self.Operator == "equal" then
		return a == b
	elseif self.Operator == "not equal" then
		return a ~= b
	elseif self.Operator == "above" then
		return a > b
	elseif self.Operator == "equal or above" then
		return a >= b
	elseif self.Operator == "below" then
		return a < b
	elseif self.Operator == "equal or below" then
		return a <= b
	elseif self.Operator == "maybe" then
		return math.random() > 0.5
	end	
end

pac.RegisterPart(PART)

local enums = {}

for key, val in pairs(_G) do
	if type(key) == "string" and key:find("PLAYERANIMEVENT_", nil, true) then
		enums[val] = key:gsub("PLAYERANIMEVENT_", ""):gsub("_", " "):lower()
	end
end

usermessage.Hook("pac_event", function(umr)
	local ply = umr:ReadEntity()
	local str = umr:ReadString()
	
	if ply:IsValid() then
		ply.pac_command_event = {name = str, time = RealTime()}
	end
end)

pac.AddHook("DoAnimationEvent", function(ply, event, data)
	ply.pac_anim_event = {name = enums[event], time = RealTime()}
end)

pac.AddHook("OnPlayerChat", function(ply, str)
	ply.pac_say_event = {str = str, time = RealTime()}
end)

--[[
attack primary
swim
flinch rightleg
flinch leftarm
flinch head
cancel
attack secondary
flinch rightarm
jump
snap yaw
attack grenade
custom
cancel reload
reload loop
custom gesture sequence
custom sequence
spawn
doublejump
flinch leftleg
flinch chest
die
reload end
reload
custom gesture
]]