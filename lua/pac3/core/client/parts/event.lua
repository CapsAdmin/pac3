local PART = {}

PART.ClassName = "event"
PART.NonPhysical = true
PART.ThinkTime = 0

pac.StartStorableVars()
	pac.GetSet(PART, "Event", "")
	pac.GetSet(PART, "Operator", "find simple")
	pac.GetSet(PART, "Arguments", "")
	pac.GetSet(PART, "Invert", false)
	pac.GetSet(PART, "RootOwner", true)
pac.EndStorableVars()

function PART:GetNiceName()
	local str = self:GetEvent()
	
	if self:GetArguments() ~= "" then
		str = str .. " " .. self:GetOperator() .. " \"".. self:GetArguments():gsub(";", " or ") .. "\""
	end
	
	return pac.PrettifyName(str)
end

local function calc_velocity(part)
	local diff = part.cached_pos - (part.last_pos or Vector(0, 0, 0))
	part.last_pos = part.cached_pos

	part.last_vel_smooth = part.last_vel_smooth or Vector(0, 0, 0)
	part.last_vel_smooth = (part.last_vel_smooth + (diff - part.last_vel_smooth) * FrameTime() * 4)
	
	return part.last_vel_smooth
end

local function try_viewmodel(ent)
	return ent == pac.LocalPlayer:GetViewModel() and pac.LocalPlayer or ent
end

PART.Events = 
{	
	fov = 
	{
		arguments = {{fov = "number"}},
		callback = function(self, ent, fov)
			ent = try_viewmodel(ent)
			
			if ent:IsValid() and ent.GetFOV then				
				return self:NumberOperator(ent:GetFOV(), fov)
			end

			return 0
		end,
	},

	health_lost = 
	{
		arguments = {{amount = "number"}},
		callback = function(self, ent, amount)
			ent = try_viewmodel(ent)
			
			if ent:IsValid() and ent.Health then
				local health = ent:Health()
				
				local diff = (ent.pac_last_health or health) - health
							
				ent.pac_last_health = health
				
				return self:NumberOperator(diff, amount)
			end

			return 0
		end,
	},

	holdtype = 
	{
		arguments = {{find = "string"}},
		callback = function(self, ent, find, hide)
			ent = try_viewmodel(ent)
			local ent = ent.GetActiveWeapon and ent:GetActiveWeapon() or NULL
			if ent:IsValid() then			
				if self:StringOperator(ent:GetHoldType(), find) then
					return true
				end
			end
		end,
	},

	is_crouching =
	{
		callback = function(self, ent)
			ent = try_viewmodel(ent)
			return ent.Crouching and ent:Crouching()
		end,
	},
	
	advanced_timer = 
	{
		arguments = {{delay = "number"}, {repeat_times = "number"}},
		callback = function(self, ent, delay, repeat_times)
			if self.timer_finished then return end
			
			delay = delay or 1
			repeat_times = repeat_times or 1
		
			self.timer_repeats = self.timer_repeats or 1
			self.timer_time = self.timer_time or os.clock()
						
			if (os.clock() - self.timer_time) > delay then
					
				if repeat_times == 0 then
					return true
				elseif self.timer_repeats < repeat_times then
					self.timer_time = os.clock()
					self.timer_repeats = self.timer_repeats + 1
					return true
				end
								
				if repeat_times == self.timer_repeats then
					self.timer_finished = true
					self.timer_repeats = 0
					return false
				end
				
				return true
			end
			
			return false
		end,		
	},

	owner_health =
	{	
		arguments = {{health = "number"}},
		callback = function(self, ent, num)
			ent = try_viewmodel(ent)
			if ent:IsValid() and ent.Health then
				return self:NumberOperator(ent:Health(), num)
			end

			return 0
		end,
	},

	owner_armor =
	{	
		arguments = {{armor = "number"}},
		callback = function(self, ent, num)
			ent = try_viewmodel(ent)
			if ent:IsValid() and ent.Armor then
				return self:NumberOperator(ent:Armor(), num)
			end

			return 0
		end,
	},

	speed = 
	{
		arguments = {{speed = "number"}},
		callback = function(self, ent, num)
			ent = try_viewmodel(ent)
			return self:NumberOperator(ent:GetVelocity():Length(), num)
		end,
	},
	
	is_under_water = 
	{
		arguments = {{speed = "number"}},
		callback = function(self, ent, num) 
			ent = try_viewmodel(ent)
			return self:NumberOperator(ent:WaterLevel(), num)
		end,
	},
	
	client_spawned = 
	{
		arguments = {{time = "number"}},
		callback = function(self, ent, time)
			time = time or 0.1
			ent = try_viewmodel(ent)
			if ent.pac_playerspawn and ent.pac_playerspawn + time > pac.RealTime then
				return true
			end			
		end,	
	},
	
	is_client = 
	{ 	
		callback = function(self, ent)
			ent = try_viewmodel(ent)
			return self:GetPlayerOwner() == ent
		end,
	},
	
	is_flashlight_on = 
	{ 		
		callback = function(self, ent)
			ent = try_viewmodel(ent)
			return ent.FlashlightIsOn and ent:FlashlightIsOn()
		end,
	},
	
	is_on_ground = 
	{ 
		arguments = {{exclude_noclip = "boolean"}},
		callback = function(self, ent, exclude_noclip)
			ent = try_viewmodel(ent)
			if exclude_noclip and ent:GetMoveType() == MOVETYPE_NOCLIP then return false end
			--return ent.IsOnGround and ent:IsOnGround()
			
			local res = util.TraceHull({
				start = ent:GetPos(),
				endpos = ent:GetPos() + Vector(0,0,-5),
				mins = ent:OBBMins(),
				maxs = ent:OBBMaxs(),
				filter = ent,
				--mask = MASK_SOLID_BRUSHONLY,
			})
			
			return res.Hit
		end,
	},
	
	is_in_noclip = 
	{ 		
		callback = function(self, ent)
			ent = try_viewmodel(ent)
			return ent:GetMoveType() == MOVETYPE_NOCLIP and (not ent.GetVehicle or not ent:GetVehicle():IsValid())
		end,
	},
	
	is_voice_chatting =
	{ 		
		callback = function(self, ent)
			ent = try_viewmodel(ent)
			return ent.IsSpeaking and ent:IsSpeaking()
		end,
	},
	
	ammo = 
	{
		arguments = {{primary = "boolean"}, {amount = "number"}},
		callback = function(self, ent, primary, amount)
			ent = try_viewmodel(ent)
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
			ent = try_viewmodel(ent)
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
			ent = try_viewmodel(ent)
			
			local wep = ent.GetActiveWeapon and ent:GetActiveWeapon() or NULL
			
			if wep:IsValid() then
				if self:StringOperator(wep:GetClass(), find) then
					if not self:IsHidden() then 
						pac.HideWeapon(wep, hide)
					end
					return true
				end
			end
		end,
	},	
	
	has_weapon =
	{
		arguments = {{find = "string"}},
		callback = function(self, ent, find)
			ent = try_viewmodel(ent)
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
			
			ent = try_viewmodel(ent)
			
			local data = ent.pac_anim_event 
			
			if data and (self:StringOperator(data.name, find) and data.time + time > pac.RealTime) then
				data.reset = false
				return true
			end			
		end,
	},

	command =
	{
		arguments = {{find = "string"}, {time = "number"}},
		callback = function(self, ent, find, time)
			time = time or 0.1
			
			ent = try_viewmodel(ent)
			
			local events = ent.pac_command_events
			
			if events then
				for key, data in pairs(events) do
					if self:StringOperator(data.name, find) and data.time + time > pac.RealTime then
						return true
					end			
				end
			end
		end,
	},
	
	say =
	{
		arguments = {{find = "string"}, {time = "number"}, {owner = "boolean"}},
		callback = function(self, ent, find, time, owner)
			time = time or 0.1
			
			ent = try_viewmodel(ent)
			
			if owner then
				owner = self:GetOwner(true)
				if owner:IsValid() then
					local data = owner.pac_say_event 
					
					if data and self:StringOperator(data.str, find) and data.time + time > pac.RealTime then
						return true
					end
				end
			else
				for key, ply in pairs(player.GetAll()) do
					local data = ent.pac_say_event 
					
					if data and self:StringOperator(data.str, find) and data.time + time > pac.RealTime then
						return true
					end			
				end
			end
		end,
	},
	
	-- outfit owner
	owner_velocity_length = 
	{
		arguments = {{speed = "number"}},
		callback = function(self, ent, speed) 
			local owner = self:GetOwner(self.RootOwner)
			local parent = self:GetParent()
			
			owner = try_viewmodel(owner)
			
			if parent:IsValid() and owner:IsValid() then
				return self:NumberOperator(parent:GetOwner(self.RootOwner):GetVelocity():Length(), speed)
			end
			
			return 0
		end,
	},
	owner_velocity_forward = 
	{
		arguments = {{speed = "number"}},
		callback = function(self, ent, speed) 
			local owner = self:GetOwner(self.RootOwner)
			local parent = self:GetParent()
			
			owner = try_viewmodel(owner)
			
			if parent:IsValid() and owner:IsValid() then
				return self:NumberOperator(owner:EyeAngles():Forward():Dot(calc_velocity(parent)), speed)
			end
			
			return 0
		end,
	},
	owner_velocity_right = 
	{
		arguments = {{speed = "number"}},
		callback = function(self, ent, speed) 
			local owner = self:GetOwner(self.RootOwner)
			local parent = self:GetParent()
			
			owner = try_viewmodel(owner)
			
			if parent:IsValid() and owner:IsValid() then
				return self:NumberOperator(owner:EyeAngles():Right():Dot(calc_velocity(parent)), speed)
			end
			
			return 0
		end,
	},
	owner_velocity_up = 
	{
		arguments = {{speed = "number"}},
		callback = function(self, ent, speed) 
			local owner = self:GetOwner(self.RootOwner)
			local parent = self:GetParent()
			
			owner = try_viewmodel(owner)
			
			if parent:IsValid() and owner:IsValid() then
				return self:NumberOperator(owner:EyeAngles():Up():Dot(calc_velocity(parent)), speed)
			end
			
			return 0
		end,
	},
	
	-- parent part
	parent_velocity_length = 
	{
		arguments = {{speed = "number"}},
		callback = function(self, ent, speed) 
			local parent = self:GetParent()
			
			if parent:HasParent() then
				parent = parent:GetParent()
			end
			
			if parent:IsValid() then
				return self:NumberOperator(calc_velocity(parent):Length(), speed)
			end
			
			return 0
		end,
	},
	parent_velocity_forward = 
	{
		arguments = {{speed = "number"}},
		callback = function(self, ent, speed) 
			local parent = self:GetParent()
			
			if parent:HasParent() then
				parent = parent:GetParent()
			end
			
			if parent:IsValid() then
				return self:NumberOperator( parent.cached_ang:Forward():Dot(calc_velocity(parent)), speed)
			end
			
			return 0
		end,
	},
	parent_velocity_right = 
	{
		arguments = {{speed = "number"}},
		callback = function(self, ent, speed) 
			local parent = self:GetParent()
			
			if parent:HasParent() then
				parent = parent:GetParent()
			end
			
			if parent:IsValid() then
				return self:NumberOperator( parent.cached_ang:Right():Dot(calc_velocity(parent)), speed)
			end
			
			return 0
		end,
	},
	parent_velocity_up = 
	{
		arguments = {{speed = "number"}},
		callback = function(self, ent, speed) 
			local parent = self:GetParent()
			
			if parent:HasParent() then
				parent = parent:GetParent()
			end
			
			if parent:IsValid() then
				return self:NumberOperator( parent.cached_ang:Up():Dot(calc_velocity(parent)), speed)
			end
			
			return 0
		end,
	},
		
	gravitygun_punt =
	{
		arguments = {{time = "number"}},
		callback = function(self, ent, time)
			time = time or 0.1
			
			ent = try_viewmodel(ent)
			
			local punted = ent.pac_gravgun_punt 
			
			if punted and punted + time > pac.RealTime then
				return true
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
				-- this should be the only case where we need this since IsHidden is modified to obey events
				local b
				
				if self.Hide or self.EventHide then --self:IsHidden() then
					b = self.Invert
				else
					b = data.callback(self, ent, self:GetParsedArguments(data.arguments)) or false
					
					if self.Invert then 
						b = not b 
					end
				end
				
				parent:SetEventHide(b, self)
				
				self.event_triggered = not not b
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
	
	for key, val in pairs(args) do
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
	
	for pos, arg in pairs(data) do
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

local cache = {}

local function CompareBTable(a, btbl, func, ...)
	for _, b in pairs(btbl) do
		if func(a, b, ...) then
			return true
		end
	end	
	
	return false
end

function PART:StringOperator(a, b)
	
	local args = cache[b]
	
	if not args then
		args = b:Split(";")
		cache[b] = args
	end
	
	if not self.Operator or not a or not b then
		return false
	elseif self.Operator == "equal" then
		return CompareBTable(a, args, function(a, b) return a == b end)
	elseif self.Operator == "not equal" then
		return CompareBTable(a, args, function(a, b) return a ~= b end)
	elseif self.Operator == "find" then
		return CompareBTable(a, args, pac.StringFind)
	elseif self.Operator == "find simple" then
		return CompareBTable(a, args, pac.StringFind, true)
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

function PART:OnHide(from_event)
	if self.Event == "weapon_class" then
		local ent = self:GetOwner()
		if ent:IsValid() then
			ent = ent.GetActiveWeapon and ent:GetActiveWeapon() or NULL
			if ent:IsValid() then	
				ent.pac_wep_hiding = false
				pac.HideWeapon(ent, false)
			end
		end
	end

end

function PART:OnShow()
	self.timer_finished = false
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
		ply.pac_command_events = ply.pac_command_events or {}
		ply.pac_command_events[str] = {name = str, time = pac.RealTime}
	end
end)

pac.AddHook("DoAnimationEvent", function(ply, event, data)
	ply.pac_anim_event = {name = enums[event], time = pac.RealTime, reset = true}
end)

pac.AddHook("OnPlayerChat", function(ply, str)
	ply.pac_say_event = {str = str, time = pac.RealTime}
end)

pac.AddHook("GravGunOnPickedUp", function(ply, ent)
	ply.pac_gravgun_ent = ent
end)

pac.AddHook("GravGunOnDropped", function(ply, ent)
	ply.pac_gravgun_ent = ent
end)

pac.AddHook("GravGunPunt", function(ply, ent)
	ply.pac_gravgun_ent = ent
	ply.pac_gravgun_punt = pac.RealTime
end)

pac.AddHook("PlayerSpawned", function(ply)
	ply.pac_playerspawn = pac.RealTime
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