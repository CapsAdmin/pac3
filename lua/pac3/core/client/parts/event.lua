include("pac3/core/client/part_pool.lua")
--include("pac3/editor/client/parts.lua")

local FrameTime = FrameTime
local CurTime = CurTime
local NULL = NULL
local Vector = Vector
local util = util
local SysTime = SysTime


local BUILDER, PART = pac.PartTemplate("base")

PART.ClassName = "event"

PART.ThinkTime = 0
PART.AlwaysThink = true
PART.Icon = 'icon16/clock.png'

BUILDER:StartStorableVars()
	BUILDER:GetSet("Event", "", {enums = function(part)
		local output = {}

		for i, event in pairs(part.Events) do
			if not event.IsAvailable or event:IsAvailable(part) then
				output[i] = event
			end
		end

		return output
	end})
	BUILDER:GetSet("Operator", "find simple", {enums = function(part) local tbl = {} for i,v in ipairs(part.Operators) do tbl[v] = v end return tbl end})
	BUILDER:GetSet("Arguments", "", {hidden = false})
	BUILDER:GetSet("Invert", true)
	BUILDER:GetSet("RootOwner", true)
	BUILDER:GetSet("AffectChildrenOnly", false)
	BUILDER:GetSet("ZeroEyePitch", false)
	BUILDER:GetSetPart("TargetPart", {editor_friendly = "ExternalOriginPart"})
	BUILDER:GetSetPart("DestinationPart", {editor_friendly = "TargetedPart"})
BUILDER:EndStorableVars()

local registered_command_event_series = {}

function PART:register_command_event(str,b)
	local ply = self:GetPlayerOwner()

	local event = str
	local flush = b

	local num = tonumber(string.sub(event, string.find(event,"[%d]+$") or 0)) or 0

	if string.find(event,"[%d]+$") then
		event = string.gsub(event,"[%d]+$","")
	end
	ply.pac_command_event_sequencebases = ply.pac_command_event_sequencebases or {}

	if flush then
		ply.pac_command_event_sequencebases[event] = nil
		return
	end

	if ply.pac_command_event_sequencebases[event] and string.find(str,"[%d]+$") then
		ply.pac_command_event_sequencebases[event].max = math.max(ply.pac_command_event_sequencebases[event].max,num)
	else
		ply.pac_command_event_sequencebases[event] = {name = event, min = 1, max = num}
	end

end

function PART:fix_event_operator()
	--check if exists
	--check class
	--check current operator
	--PrintTable(PART.Events[self.Event])
	if PART.Events[self.Event] then
		local event_type = PART.Events[self.Event].operator_type
		if event_type == "number" then
			if self.Operator == "find" or self.Operator == "find simple" then
				self.Operator = PART.Events[self.Event].preferred_operator --which depends, it's usually above but we'll have cases where it's best to have below, or equal
				self:SetInfo("The operator was automatically changed to work with this event type, which handles numbers")
			end

		elseif event_type == "string" then
			if self.Operator ~= "find" and self.Operator ~= "find simple" and self.Operator ~= "equal" then
				self.Operator = PART.Events[self.Event].preferred_operator --find simple
				self:SetInfo("The operator was automatically changed to work with this event type, which handles strings (text)")
			end
		elseif event_type == "mixed" then
			self:SetInfo("This event is mixed, which means it might have different behaviour with numeric operators or string operators. Some of these are that way because they're using different sources of data at once (e.g. addons' weapons can use different formats for fire modes), and we want to catch the most valid uses possible to fit what the event says")
			--do nothing but still warn about it being a special complex event
		elseif event_type == "none" then
			--do nothing
		end
	end
end

function PART:GetEventTutorialText()
	if PART.Events[self.Event] then
		return PART.Events[self.Event].tutorial_explanation or "no tutorial entry was added, probably because this event is self-explanatory"
	else
		return "invalid event"
	end
end

function PART:AttachEditorPopup(str)

	local info_string = str or "no information available"
	local verbosity = ""
	if self.Event ~= "" then
		info_string = self:GetEventTutorialText()
		--if verbosity == "reference tutorial" or verbosity == "beginner tutorial" then
		--end
	end
	str = info_string or str
	self:SetupEditorPopup(str, true)
end

function PART:SetEvent(event)
	local reset = (self.Arguments == "") or
	(self.Arguments ~= "" and self.Event ~= "" and self.Event ~= event)

	local owner = self:GetPlayerOwner()

	if owner == pac.LocalPlayer then
		if event == "command" then owner.pac_command_events = owner.pac_command_events or {} end
		if not self.Events[event] then --invalid event? try a command event
			if GetConVar("pac_copilot_auto_setup_command_events"):GetBool() then
				timer.Simple(0.2, function()
					if not self.pace_properties or self ~= pace.current_part then return end
					--now we'll use event as a command name
					self:SetEvent("command")
					self.pace_properties["Event"]:SetValue("command")
					self:SetArguments(event .. "@@0")
					self.pace_properties["Arguments"]:SetValue(event .. "@@0@@0")
					pace.PopulateProperties(self)
				end)
				return
			end
		end
	end

	self.Event = event
	self:SetWarning()
	self:SetInfo()

	--foolproofing: fix the operator to match the event's type, and fix arguments as needed
	self:fix_event_operator()
	self:fix_args()

	if owner == pac.LocalPlayer then
		pace.changed_event = self --a reference to make it refresh the popup label panel
		pace.changed_event_time = CurTime()

		if self == pace.current_part and GetConVar("pac_copilot_make_popup_when_selecting_event"):GetBool() then self:AttachEditorPopup() end --don't flood the popup system with superfluous requests when loading an outfit

		self:GetDynamicProperties(reset)
		if not GetConVar("pac_editor_remember_divider_height"):GetBool() and IsValid(pace.Editor) then pace.Editor.div:SetTopHeight(ScrH() - 520) end

	end
end

function PART:Initialize()
	if self:GetPlayerOwner() == LocalPlayer() then
		timer.Simple(0.2, function()
			if self.Event == "command" then
				local cmd, time, hide = self:GetParsedArgumentsForObject(self.Events.command)
				self:register_command_event(cmd, true)
				timer.Simple(0.2, function()
					self:register_command_event(cmd, false)
				end)
			end
		end)
	end

end

local function get_default(typ)
	if typ == "string" then
		return ""
	elseif typ == "number" then
		return 0
	elseif typ == "boolean" then
		return false
	end
end

local function string_to_type(typ, val)
	if typ == "number" then
		return tonumber(val) or 0
	elseif typ == "boolean" then
		return tobool(val) or false
	end
	return val
end

local function cast(typ, val)
	if val == nil then
		val = get_default(typ)
	end

	return string_to_type(typ, val)
end

function PART:GetDynamicProperties(reset_to_default)
	local data = self.Events[self.Event]
	if not data then return end

	local tbl = {}
	for pos, arg in ipairs(data:GetArguments()) do
		local key, typ, udata = unpack(arg)
		udata = udata or {}
		udata.group = udata.group or "arguments"

		tbl[key] = {
			key = key,
			get = function()
				local args = {self:GetParsedArguments(data)}
				return cast(typ, args[pos])
			end,
			set = function(val)
				local args = {self:GetParsedArguments(data)}
				args[pos] = val
				self:ParseArguments(unpack(args))
			end,
			udata = udata,
		}

		local arg = tbl[key]
		if arg.get() == nil or reset_to_default then
			if udata.default then
				arg.set(udata.default)
			else
				arg.set(nil)
			end
		end
	end

	return tbl
end

local function convert_angles(self, ang)
	if self.ZeroEyePitch then
		ang.p = 0
	end

	return ang
end

local function calc_velocity(part)
	if not part.GetWorldPosition then
		return vector_origin
	end

	local diff = part:GetWorldPosition() - (part.last_pos or Vector(0, 0, 0))
	part.last_pos = part:GetWorldPosition()

	part.last_vel_smooth = part.last_vel_smooth or Vector(0, 0, 0)
	part.last_vel_smooth = part.last_vel_smooth + (part:GetWorldPosition() - part.last_vel_smooth) * FrameTime() * 4

	return part.last_vel_smooth
end

local function try_viewmodel(ent)
	return ent == pac.LocalViewModel and pac.LocalPlayer or ent
end

local function get_owner(self)
	if self.RootOwner then
		return try_viewmodel(self:GetRootPart():GetOwner())
	else
		return try_viewmodel(self:GetOwner())
	end
end

local movetypes = {}

for k,v in pairs(_G) do
	if isstring(k) and isnumber(v) and k:sub(0,9) == "MOVETYPE_" then
		movetypes[v] = k:sub(10):lower()
	end
end

local grounds_enums = {
	["MAT_ANTLION"] = "65",
	["MAT_BLOODYFLESH"] = "66",
	["MAT_CONCRETE"] = "67",
	["MAT_DIRT"] = "68",
	["MAT_EGGSHELL"] = "69",
	["MAT_FLESH"] = "70",
	["MAT_GRATE"] = "71",
	["MAT_ALIENFLESH"] = "72",
	["MAT_CLIP"] = "73",
	["MAT_SNOW"] = "74",
	["MAT_PLASTIC"] = "76",
	["MAT_METAL"] = "77",
	["MAT_SAND"] = "78",
	["MAT_FOLIAGE"] = "79",
	["MAT_COMPUTER"] = "80",
	["MAT_SLOSH"] = "83",
	["MAT_TILE"] = "84",
	["MAT_GRASS"] = "85",
	["MAT_VENT"] = "86",
	["MAT_WOOD"] = "87",
	["MAT_DEFAULT"] = "88",
	["MAT_GLASS"] = "89",
	["MAT_WARPSHIELD"] = "90"
}

local grounds_enums_reverse = {
	["65"] = "antlion",
	["66"] = "bloody flesh",
	["67"] = "concrete",
	["68"] = "dirt",
	["69"] = "egg shell",
	["70"] = "flesh",
	["71"] = "grate",
	["72"] = "alien flesh",
	["73"] = "clip",
	["74"] = "snow",
	["76"] = "plastic",
	["77"] = "metal",
	["78"] = "sand",
	["79"] = "foliage",
	["80"] = "computer",
	["83"] = "slosh",
	["84"] = "tile",
	["85"] = "grass",
	["86"] = "vent",
	["87"] = "wood",
	["88"] = "default",
	["89"] = "glass",
	["90"] = "warp shield"
}

local animation_event_enums = {
	"attack primary",
	"swim",
	"flinch rightleg",
	"flinch leftarm",
	"flinch head",
	"cancel",
	"attack secondary",
	"flinch rightarm",
	"jump",
	"snap yaw",
	"attack grenade",
	"custom",
	"cancel reload",
	"reload loop",
	"custom gesture sequence",
	"custom sequence",
	"spawn",
	"doublejump",
	"flinch leftleg",
	"flinch chest",
	"die",
	"reload end",
	"reload",
	"custom gesture"
}



PART.Events = {}
PART.OldEvents = {

	random = {
		operator_type = "number", preferred_operator = "above",
		arguments = {{compare = "number"}},
		callback = function(self, ent, compare)
			return self:NumberOperator(math.random(), compare)
		end,
	},

	randint = {
		operator_type = "number", preferred_operator = "above",
		arguments = {{compare = "number"}, {min = "number"}, {max = "number"}},
		callback = function(self, ent, compare, min, max)
			min = min or 0
			max = max or 1
			if min > max then return 0 end
			return self:NumberOperator(math.random(min,max), compare)
		end,
	},

	random_timer = {
		operator_type = "none",
		tutorial_explanation = "random_timer picks a number between min and max, waits this amount of seconds,\nthen activates for the amount of seconds from holdtime.\nafter this is over, it picks a new random number and starts waiting again",
		arguments = {{min = "number"}, {max = "number"}, {holdtime = "number"}},
		callback = function(self, ent, min, max, holdtime)

			holdtime = holdtime or 0.1
			min = min or 0
			max = max or 1

			if min > max then return false end

			if self.RndTime == nil then
				self.RndTime = 0
			end

			if not self.SetRandom then
				self.RndTime = CurTime() + math.random(min,max)
				self.SetRandom = true
			elseif self.SetRandom then

				if CurTime() > self.RndTime then
					if CurTime() < self.RndTime + holdtime then
						return true
					end

					self.SetRandom = false
					return false
				end

			end

			return false
		end,
	},

	timerx = {
		operator_type = "number", preferred_operator = "above",
		tutorial_explanation = "timerx is a stopwatch that counts time since it's shown (hiding and re-showing is an important resetting condition).\nit takes that time and compares it with the duration defined in seconds.\nmeaning it can show things after(above) a delay or until(below) a certain amount of time passes",
		arguments = {{seconds = "number"}, {reset_on_hide = "boolean"}, {synced_time = "boolean"}},
		userdata = {
			{default = 0, timerx_property = "seconds"},
			{default = true, timerx_property = "reset_on_hide"}
		},
		nice = function(self, ent, seconds)
			return "timerx: " .. ("%.2f"):format(self.number or 0, 2) .. " " .. self:GetOperator() .. " " .. seconds .. " seconds?"
		end,
		callback = function(self, ent, seconds, reset_on_hide, synced_time)

			local time = synced_time and CurTime() or RealTime()

			self.time = self.time or time
			self.timerx_reset = reset_on_hide

			if self.AffectChildrenOnly and self:IsHiddenBySomethingElse() then
				return false
			end
			self.number = time - self.time

			return self:NumberOperator(self.number, seconds)
		end,
	},

	timersys = {
		operator_type = "number", preferred_operator = "above",
		tutorial_explanation = "like timerx, timersys is a stopwatch that counts time (it uses SysTime()) since it's shown (hiding and re-showing is an important resetting condition).\nit takes that time and compares it with the duration defined in seconds.\nmeaning it can show things after(above) a delay or until(below) a certain amount of time passes",
		arguments = {{seconds = "number"}, {reset_on_hide = "boolean"}},

		callback = function(self, ent, seconds, reset_on_hide)

			local time = SysTime()

			self.time = self.time or time
			self.timerx_reset = reset_on_hide

			if self.AffectChildrenOnly and self:IsHiddenBySomethingElse() then
				return false
			end
			return self:NumberOperator(time - self.time, seconds)
		end,
	},

	map_name = {
		operator_type = "string", preferred_operator = "find simple",
		arguments = {{find = "string"}},
		callback = function(self, ent, find)
			return self:StringOperator(game.GetMap(), find)
		end,
	},

	fov = {
		operator_type = "number", preferred_operator = "above",
		arguments = {{fov = "number"}},
		callback = function(self, ent, fov)
			ent = try_viewmodel(ent)

			if ent.GetFOV then
				return self:NumberOperator(ent:GetFOV(), fov)
			end

			return 0
		end,
	},
	health_lost = {
		operator_type = "number", preferred_operator = "above",
		arguments = {{amount = "number"}},
		callback = function(self, ent, amount)

			ent = try_viewmodel(ent)

			if ent.Health then

				local dmg = self.pac_lastdamage or 0

				if self.dmgCD == nil then
					self.dmgCD = 0
				end

				if not self.pac_wasdmg then

					local dmgDone = dmg - ent:Health()
					self.pac_lastdamage = ent:Health()

					if dmgDone == 0 then return false end

					if self:NumberOperator(dmgDone,amount) then
						self.pac_wasdmg = true
						self.dmgCD = pac.RealTime + 0.2
					end

				else

					if self.pac_wasdmg and pac.RealTime > self.dmgCD then
						self.pac_wasdmg = false
					end

				end

				return self.pac_wasdmg
			end

			return false
		end,
	},

	holdtype = {
		operator_type = "string", preferred_operator = "find simple",
		arguments = {{find = "string"}},
		callback = function(self, ent, find)
			ent = try_viewmodel(ent)
			local wep = ent.GetActiveWeapon and ent:GetActiveWeapon() or NULL
			if wep:IsValid() and self:StringOperator(wep:GetHoldType(), find) then
				return true
			end
		end,
		nice = function(self, ent, find)
			local str = "holdtype ["..self.Operator.. " " .. find .. "] | "
			local wep = ent.GetActiveWeapon and ent:GetActiveWeapon() or NULL
			if wep:IsValid() then
				str = str .. wep:GetHoldType()
			end
			return str
		end
	},

	is_crouching = {
		operator_type = "none",
		callback = function(self, ent)
			ent = try_viewmodel(ent)
			return ent.Crouching and ent:Crouching()
		end,
	},

	is_typing = {
		operator_type = "none",
		callback = function(self, ent)
			ent = self:GetPlayerOwner()
			return ent.IsTyping and ent:IsTyping()
		end,
	},

	using_physgun = {
		operator_type = "none",
		callback = function(self, ent)
			ent = self:GetPlayerOwner()
			local pac_drawphysgun_event_part = ent.pac_drawphysgun_event_part
			if not pac_drawphysgun_event_part then
				pac_drawphysgun_event_part = {}
				ent.pac_drawphysgun_event_part = pac_drawphysgun_event_part
			end
			pac_drawphysgun_event_part[self] = true
			return ent.pac_drawphysgun_event ~= nil
		end,
	},

	eyetrace_entity_class = {
		operator_type = "string", preferred_operator = "find simple",
		tutorial_explanation = "this compares the class of the entity you point to with the one(s) written in class",
		arguments = {{class = "string"}},
		callback = function(self, ent, find)
			if ent.GetEyeTrace then
				ent = ent:GetEyeTrace().Entity
				if not IsValid(ent) then return false end
				if self:StringOperator(ent:GetClass(), find) then
					return true
				end
			end
		end,
	},

	owner_health = {
		operator_type = "number", preferred_operator = "above",
		arguments = {{health = "number"}},
		callback = function(self, ent, num)

			ent = try_viewmodel(ent)
			if ent.Health then
				return self:NumberOperator(ent:Health(), num)
			end

			return 0
		end,
	},
	owner_max_health = {
		operator_type = "number", preferred_operator = "above",
		arguments = {{health = "number"}},
		callback = function(self, ent, num)

			ent = try_viewmodel(ent)
			if ent.GetMaxHealth then
				return self:NumberOperator(ent:GetMaxHealth(), num)
			end

			return 0
		end,
	},
	owner_alive = {
		operator_type = "none",
		callback = function(self, ent)
			ent = try_viewmodel(ent)
			if ent.Alive then
				return ent:Alive()
			end
			return 0
		end,
	},
	owner_armor = {
		operator_type = "number", preferred_operator = "above",
		arguments = {{armor = "number"}},
		callback = function(self, ent, num)

			ent = try_viewmodel(ent)
			if ent.Armor then
				return self:NumberOperator(ent:Armor(), num)
			end

			return 0
		end,
	},

	owner_scale_x = {
		operator_type = "number", preferred_operator = "above",
		arguments = {{scale = "number"}},
		callback = function(self, ent, num)

			ent = try_viewmodel(ent)
			return self:NumberOperator(ent.pac_model_scale and ent.pac_model_scale.x or (ent.GetModelScale and ent:GetModelScale()) or 1, num)
		end,
	},
	owner_scale_y = {
		operator_type = "number", preferred_operator = "above",
		arguments = {{scale = "number"}},
		callback = function(self, ent, num)

			ent = try_viewmodel(ent)
			return self:NumberOperator(ent.pac_model_scale and ent.pac_model_scale.y or (ent.GetModelScale and ent:GetModelScale()) or 1, num)
		end,
	},
	owner_scale_z = {
		operator_type = "number", preferred_operator = "above",
		arguments = {{scale = "number"}},
		callback = function(self, ent, num)

			ent = try_viewmodel(ent)
			return self:NumberOperator(ent.pac_model_scale and ent.pac_model_scale.z or (ent.GetModelScale and ent:GetModelScale()) or 1, num)
		end,
	},

	pose_parameter = {
		operator_type = "number", preferred_operator = "above",
		tutorial_explanation = "pose parameters are values used in models for body movement and animation.\nthis event searches a pose parameter and compares its normalized (0-1 range) value with the number defined in num",
		arguments = {{name = "string"}, {num = "number"}},
		callback = function(self, ent, name, num)
			ent = try_viewmodel(ent)
			return self:NumberOperator(ent:GetPoseParameter(name), num)
		end,
	},

	pose_parameter_true = {
		operator_type = "number", preferred_operator = "above",
		tutorial_explanation = "pose parameters are values used in models for body movement and animation.\nthis event searches a pose parameter and compares its true (as opposed to normalized into the 0-1 range) value with number defined in num",
		arguments = {{name = "string"}, {num = "number"}},
		callback = function(self, ent, name, num)
			ent = try_viewmodel(ent)
			if ent:IsValid() then
				local min,max = ent:GetPoseParameterRange(ent:LookupPoseParameter(name))
				if not min or not max then return 0 end
				local actual_value = min + (max - min)*(ent:GetPoseParameter(name))
				return self:NumberOperator(actual_value, num)
			end
		end,
	},

	speed = {
		operator_type = "number", preferred_operator = "equal",
		arguments = {{speed = "number"}},
		callback = function(self, ent, num)
			ent = try_viewmodel(ent)
			return self:NumberOperator(ent:GetVelocity():Length(), num)
		end,
	},

	is_under_water = {
		operator_type = "number", preferred_operator = "above",
		tutorial_explanation = "is_under_water activates when you're under a certain level of water.\nas you get deeper, the number is higher.\n0 is dry\n1 is slightly submerged (at least to the feet)\n2 is mostly submerged (at least to the waist)\n3 is completely submerged",
		arguments = {{level = "number"}},
		callback = function(self, ent, num)
			ent = try_viewmodel(ent)
			return self:NumberOperator(ent:WaterLevel(), num)
		end,
	},

	is_on_fire = {
		operator_type = "none",
		callback = function(self, ent)
			ent = try_viewmodel(ent)
			return ent:IsOnFire()
		end,
	},

	client_spawned = {
		operator_type = "number", preferred_operator = "below",
		tutorial_explanation = "client_spawned supposedly activates for some time after you spawn",

		arguments = {{time = "number"}},
		callback = function(self, ent, time)
			time = time or 0.1
			ent = try_viewmodel(ent)
			if ent.pac_playerspawn then
				return self:NumberOperator(pac.RealTime, ent.pac_playerspawn + time)
			end
			return false
		end,
	},

	is_client = {
		operator_type = "none",
		tutorial_explanation = "is_client activates when the group owner entity is your player or viewmodel, rather than another entity like a prop",
		callback = function(self, ent)
			ent = try_viewmodel(ent)
			return self:GetPlayerOwner() == ent
		end,
	},

	viewed_by_owner = {
		operator_type = "none",
		tutorial = "viewed_by_owner shows for only you. uninvert to show only to other players",
		callback = function(self, ent)
			return self:GetPlayerOwner() == pac.LocalPlayer
		end,
	},

	seen_by_player = {
		operator_type = "none",
		tutorial = "looked_at_by_player activates when a player is looking at you, determined by whether a box around you touches the direct eyeangle line",
		arguments = {{extra_radius = "number"}, {require_line_of_sight = "boolean"}},
		userdata = {{editor_panel = "seen_by_player"}},
		callback = function(self, ent, extra_radius, require_line_of_sight)
			extra_radius = extra_radius or 0
			self.nextcheck = self.nextcheck or CurTime() + 0.1
			if CurTime() > self.nextcheck then
				for _,v in ipairs(player.GetAll()) do
					if v == ent then continue end
					local eyetrace = v:GetEyeTrace()

					if util.IntersectRayWithOBB(eyetrace.StartPos, eyetrace.HitPos - eyetrace.StartPos, LocalPlayer():GetPos() + LocalPlayer():OBBCenter(), Angle(0,0,0), Vector(-extra_radius,-extra_radius,-extra_radius), Vector(extra_radius,extra_radius,extra_radius)) then
						self.trace_success = true
						self.trace_success_ply = v
						self.nextcheck = CurTime() + 0.1
						goto CHECKOUT
					end
					if eyetrace.Entity == ent then
						self.trace_success = true
						self.trace_success_ply = v
						self.nextcheck = CurTime() + 0.1
						goto CHECKOUT
					end
				end
				self.trace_success = false
				self.nextcheck = CurTime() + 0.1
			end
			::CHECKOUT::
			if require_line_of_sight then
				return self.trace_success
					and self.trace_success_ply:IsLineOfSightClear(ent) --check world LOS
					and ((util.QuickTrace(self.trace_success_ply:EyePos(), ent:EyePos() - self.trace_success_ply:EyePos(), self.trace_success_ply).Entity == ent)
						or (util.QuickTrace(self.trace_success_ply:EyePos(), ent:GetPos() + ent:OBBCenter() - self.trace_success_ply:EyePos(), self.trace_success_ply).Entity == ent))
			else
				return self.trace_success
			end
		end,
	},

	is_flashlight_on = {
		operator_type = "none",
		callback = function(self, ent)
			ent = try_viewmodel(ent)
			return ent.FlashlightIsOn and ent:FlashlightIsOn()
		end,
	},

	collide = {
		operator_type = "none",
		callback = function(self, ent)
			ent.pac_event_collide_callback = ent.pac_event_collide_callback or ent:AddCallback("PhysicsCollide", function(ent, data)
				ent.pac_event_collision_data = data
			end)

			if ent.pac_event_collision_data then
				local data = ent.pac_event_collision_data
				ent.pac_event_collision_data = nil
				return true
			end

			return false
		end,
	},

	ranger = {
		operator_type = "number", preferred_operator = "below",
		tutorial_explanation = "ranger looks in a line to see if something is in front (red arrow) of its host's (parent) model;\ndetected things could be found before(below) or beyond(above) the distance defined in compare;\nthe event will only look as far as the distance defined in distance",
		arguments = {{distance = "number"}, {compare = "number"}, {npcs_and_players_only = "boolean"}},
		userdata = {
			{default = 15, editor_panel = "ranger", ranger_property = "distance"},
			{default = 5, editor_panel = "ranger", ranger_property = "compare"}
		},
		callback = function(self, ent, distance, compare, npcs_and_players_only)

			local parent = self:GetParentEx()

			if parent:IsValid() and parent.GetWorldPosition then
				self:SetWarning()
				distance = distance or 1
				compare = compare or 0

				local res = util.TraceLine({
					start = parent:GetWorldPosition(),
					endpos = parent:GetWorldPosition() + parent:GetWorldAngles():Forward() * distance,
					filter = ent,
				})

				if npcs_and_players_only and (not res.Entity:IsPlayer() and not res.Entity:IsNPC()) then
					return false
				end

				return self:NumberOperator(res.Fraction * distance, compare)
			else
				local classname = parent:GetNiceName()
				local name = parent:GetName()
				self:SetWarning(("ranger doesn't work on [%s] %s"):format(classname, classname ~= name and "(" .. name .. ")" or ""))
			end
		end,
		nice = function(self, ent, distance, compare, npcs_and_players_only)
			local str = "ranger: [" .. self.Operator .. " " .. compare .. "]"
			return str
		end
	},

	ground_surface = {
		operator_type = "mixed",
		tutorial_explanation = "ground_surface checks what ground you're standing on, and activates if it matches among the IDs written in surfaces.\nMatch multiple with ;",
		arguments = {{exclude_noclip = "boolean"}, {surfaces = "string"}},
		userdata = {{}, {enums = function()
			--grounds_enums =
			return
			{
				["MAT_ANTLION"] = "65",
				["MAT_BLOODYFLESH"] = "66",
				["MAT_CONCRETE"] = "67",
				["MAT_DIRT"] = "68",
				["MAT_EGGSHELL"] = "69",
				["MAT_FLESH"] = "70",
				["MAT_GRATE"] = "71",
				["MAT_ALIENFLESH"] = "72",
				["MAT_CLIP"] = "73",
				["MAT_SNOW"] = "74",
				["MAT_PLASTIC"] = "76",
				["MAT_METAL"] = "77",
				["MAT_SAND"] = "78",
				["MAT_FOLIAGE"] = "79",
				["MAT_COMPUTER"] = "80",
				["MAT_SLOSH"] = "83",
				["MAT_TILE"] = "84",
				["MAT_GRASS"] = "85",
				["MAT_VENT"] = "86",
				["MAT_WOOD"] = "87",
				["MAT_DEFAULT"] = "88",
				["MAT_GLASS"] = "89",
				["MAT_WARPSHIELD"] = "90"
			} end}},
		nice =  function(self, ent, exclude_noclip, surfaces)
			local grounds_enums_reverse = {
				["65"] = "antlion",
				["66"] = "bloody flesh",
				["67"] = "concrete",
				["68"] = "dirt",
				["69"] = "egg shell",
				["70"] = "flesh",
				["71"] = "grate",
				["72"] = "alien flesh",
				["73"] = "clip",
				["74"] = "snow",
				["76"] = "plastic",
				["77"] = "metal",
				["78"] = "sand",
				["79"] = "foliage",
				["80"] = "computer",
				["83"] = "slosh",
				["84"] = "tile",
				["85"] = "grass",
				["86"] = "vent",
				["87"] = "wood",
				["88"] = "default",
				["89"] = "glass",
				["90"] = "warp shield"
			}
			surfaces = surfaces or ""
			local str = "ground surface: "
			for i,v in ipairs(string.Split(surfaces,";")) do
				local element = grounds_enums_reverse[v] or ""
				str = str .. element
				if i ~= #string.Split(surfaces,";") then
					str = str .. ", "
				end
			end
			return str
		end,
		callback = function(self, ent, exclude_noclip, surfaces, down)
			surfaces = surfaces or ""
			if exclude_noclip and ent:GetMoveType() == MOVETYPE_NOCLIP then return false end
			local trace = util.TraceLine( {
				start = self:GetRootPart():GetOwner():GetPos() + Vector( 0, 0, 10),
				endpos = self:GetRootPart():GetOwner():GetPos() + Vector( 0, 0, -30 ),
				filter = function(ent)
					if ent == self:GetRootPart():GetOwner() or ent == self:GetPlayerOwner() then return false end
				end
			})
			local found = false
			if trace.Hit then
				local surfs = string.Split(surfaces,";")
				for _,surf in pairs(surfs) do
					if surf == tostring(trace.MatType) then found = true end
				end
			end
			return found
		end
	},

	is_on_ground = {
		arguments = {{exclude_noclip = "boolean"}},
		callback = function(self, ent, exclude_noclip)
			ent = try_viewmodel(ent)
			if exclude_noclip and ent:GetMoveType() == MOVETYPE_NOCLIP then return false end
			--return ent.IsOnGround and ent:IsOnGround()

			local rad = ent:BoundingRadius() / 2
			local times = 2

			for x = -times, times do
				for y = -times, times do
					local xy = Vector(x/times,y/times,0) * rad
					local res = util.TraceLine({
						start = ent:GetPos() + xy + Vector(0,0,2.5),
						endpos = ent:GetPos() + xy/1.25 + Vector(0,0,-10),
						--mins = ent:OBBMins(),
						--maxs = ent:OBBMaxs(),
						filter = ent,
						--mask = MASK_SOLID_BRUSHONLY,
					})
					if res.Hit and math.abs(res.HitNormal.z) > 0.70 then return true end
				end
			end

			return false
		end,
	},

	--this one uses util.TraceHull
	is_touching = {
		operator_type = "none",
		tutorial_explanation = "is_touching checks in a box (util.TraceHull) around the host model to see if there's something inside it.\nusually it's the parent model or root owner entity,\nbut you can force it to use the nearest pac3 model as an owner,to override the old root owner setting,\nin case of issues when stacking this event inside other events",
		arguments = {{extra_radius = "number"}, {nearest_model = "boolean"}},
		userdata = {{editor_panel = "is_touching", is_touching_property = "extra_radius", default = 0}, {default = 0}},
		callback = function(self, ent, extra_radius, nearest_model)
			if nearest_model then ent = self:GetOwner() end
			if not IsValid(ent) then return false end
			extra_radius = extra_radius or 0

			local radius =  ent:BoundingRadius()

			if radius == 0 and IsValid(ent.pac_projectile) then
				radius = ent.pac_projectile:GetRadius()
			end

			radius = math.max(radius + extra_radius + 1, 1)

			local mins = Vector(-1,-1,-1)
			local maxs = Vector(1,1,1)
			local startpos = ent:WorldSpaceCenter()
			mins = mins * radius
			maxs = maxs * radius


			local tr = util.TraceHull( {
				start = startpos,
				endpos = startpos,
				maxs = maxs,
				mins = mins,
				filter = {ent, self:GetRootPart():GetOwner()}
			})

			return tr.Hit
		end,
		nice = function(self, ent, extra_radius, nearest_model)
			if nearest_model then ent = self:GetOwner() end
			if not IsValid(ent) then return "" end
			local radius = ent:BoundingRadius()

			if radius == 0 and IsValid(ent.pac_projectile) then
				radius = ent.pac_projectile:GetRadius()
			end

			radius = math.Round(math.max(radius + extra_radius + 1, 1))

			local str = self.Event .. " [radius: " .. radius .. "]"
			return str
		end,
	},
	--this one uses ents.FindInBox
	is_touching_filter = {
		operator_type = "none",
		tutorial_explanation = "is_touching_filter checks in a box (ents.FindInBox) around the host model to see if there's something inside it, but you can selectively exclude living things (NPCs or players) from being detected.\nusually the center is the parent model or root owner entity,\nbut you can force it to use the nearest pac3 model as an owner to override the old root owner setting,\nin case of issues when stacking this event inside others",
		arguments = {{extra_radius = "number"}, {no_npc = "boolean"}, {no_players = "boolean"}, {nearest_model = "boolean"}},
		userdata = {{editor_panel = "is_touching", is_touching_property = "extra_radius", default = 0}, {default = false}, {default = false}, {default = false}},
		callback = function(self, ent, extra_radius, no_npc, no_players, nearest_model)
			if nearest_model then ent = self:GetOwner() end
			if not IsValid(ent) then return false end
			extra_radius = extra_radius or 0
			no_npc = no_npc or false
			no_players = no_players or false
			nearest_model = nearest_model or false

			local radius =  ent:BoundingRadius()

			if radius == 0 and IsValid(ent.pac_projectile) then
				radius = ent.pac_projectile:GetRadius()
			end

			radius = math.max(radius + extra_radius + 1, 1)

			local mins = Vector(-1,-1,-1)
			local maxs = Vector(1,1,1)
			local startpos = ent:WorldSpaceCenter()
			mins = startpos + mins * radius
			maxs = startpos + maxs * radius

			local b = false
			local ents_hits = ents.FindInBox(mins, maxs)
			for _,ent2 in pairs(ents_hits) do
				if (ent2 ~= ent and ent2 ~= self:GetRootPart():GetOwner()) and
					(ent2:IsNPC() or ent2:IsPlayer()) and
					not ( (no_npc and ent2:IsNPC()) or (no_players and ent2:IsPlayer()) )
				then b = true end
			end

			return b
		end,
		nice = function(self, ent, extra_radius, no_npc, no_players, nearest_model)
			if nearest_model then ent = self:GetOwner() end
			if not IsValid(ent) then return "" end
			local radius = ent:BoundingRadius()

			if radius == 0 and IsValid(ent.pac_projectile) then
				radius = ent.pac_projectile:GetRadius()
			end

			radius = math.Round(math.max(radius + extra_radius + 1, 1))

			local str = self.Event .. " [radius: " .. radius .. "]"
			if no_npc or no_players then str = str .. " | " end
			if no_npc then str = str .. "no_npc " end
			if no_players then str = str .. "no_players " end
			return str
		end
	},
	--this one uses ents.FindInBox
	is_touching_life = {
		operator_type = "none",
		tutorial_explanation = "is_touching_life checks in a stretchable box (ents.FindInBox) around the host model to see if there's something inside it.\nusually the center is the parent model or root owner entity,\nbut you can force it to use the nearest pac3 model as an owner to override the old root owner setting,\nin case of issues when stacking this event inside others",

		arguments = {{extra_radius = "number"}, {x_stretch = "number"}, {y_stretch = "number"}, {z_stretch = "number"}, {no_npc = "boolean"}, {no_players = "boolean"}, {nearest_model = "boolean"}},
		userdata = {{editor_panel = "is_touching", default = 0}, {x = "x_stretch", default = 1}, {y = "y_stretch", default = 1}, {z = "z_stretch", default = 1}, {default = false}, {default = false}, {default = false}},
		callback = function(self, ent, extra_radius, x_stretch, y_stretch, z_stretch, no_npc, no_players, nearest_model)

			if nearest_model then ent = self:GetOwner() end
			if not IsValid(ent) then return false end
			extra_radius = extra_radius or 0
			no_npc = no_npc or false
			no_players = no_players or false
			x_stretch = x_stretch or 1
			y_stretch = y_stretch or 1
			z_stretch = z_stretch or 1
			nearest_model = nearest_model or false

			local radius =  ent:BoundingRadius()

			if radius == 0 and IsValid(ent.pac_projectile) then
				radius = ent.pac_projectile:GetRadius()
			end

			radius = math.max(radius + extra_radius + 1, 1)

			local mins = Vector(-x_stretch,-y_stretch,-z_stretch)
			local maxs = Vector(x_stretch,y_stretch,z_stretch)
			local startpos = ent:WorldSpaceCenter()
			mins = startpos + mins * radius
			maxs = startpos + maxs * radius

			local ents_hits = ents.FindInBox(mins, maxs)
			local b = false
			for _,ent2 in pairs(ents_hits) do
				if IsValid(ent2) and (ent2 ~= ent and ent2 ~= self:GetRootPart():GetOwner()) and
				(ent2:IsNPC() or ent2:IsPlayer())

				then
					b = true
					if ent2:IsNPC() and no_npc then
						b = false
					elseif ent2:IsPlayer() and no_players then
						b = false
					end
					if b then return b end
				end
			end

			return b
		end,
		nice = function(self, ent, extra_radius, x_stretch, y_stretch, z_stretch, no_npc, no_players, nearest_model)

			if nearest_model then ent = self:GetOwner() end
			if not IsValid(ent) then return "" end
			local radius = ent:BoundingRadius()

			if radius == 0 and IsValid(ent.pac_projectile) then
				radius = ent.pac_projectile:GetRadius()
			end

			radius = math.Round(math.max(radius + extra_radius + 1, 1))

			local str = self.Event .. " [radius: " .. radius .. ", stretch: " .. x_stretch .. "*" .. y_stretch .. "*" .. z_stretch .. "]"
			if no_npc or no_players then str = str .. " | " end
			if no_npc then str = str .. "no_npc " end
			if no_players then str = str .. "no_players " end
			return str
		end,
	},
	--this one uses util.TraceHull
	is_touching_scalable = {
		operator_type = "none",
		tutorial_explanation = "is_touching_life checks in a stretchable box (util.TraceHull) around the host model to see if there's something inside it.\nusually the center is the parent model or root owner entity,\nbut you can force it to use the nearest pac3 model as an owner to override the old root owner setting,\nin case of issues when stacking this event inside others",

		arguments = {{extra_radius = "number"}, {x_stretch = "number"}, {y_stretch = "number"}, {z_stretch = "number"}, {nearest_model = "boolean"}},
		userdata = {{editor_panel = "is_touching", default = 0}, {x = "x_stretch", default = 1}, {y = "y_stretch", default = 1}, {z = "z_stretch", default = 1}, {default = false}},
		callback = function(self, ent, extra_radius, x_stretch, y_stretch, z_stretch, nearest_model)
			if nearest_model then ent = self:GetOwner() end
			if not IsValid(ent) then return false end
			extra_radius = extra_radius or 15
			x_stretch = x_stretch or 1
			y_stretch = y_stretch or 1
			z_stretch = z_stretch or 1
			nearest_model = nearest_model or false

			local mins = Vector(-x_stretch,-y_stretch,-z_stretch)
			local maxs = Vector(x_stretch,y_stretch,z_stretch)
			local startpos = ent:WorldSpaceCenter()

			radius = math.max(extra_radius, 1)
			mins = mins * radius
			maxs = maxs * radius

			local tr = util.TraceHull( {
				start = startpos,
				endpos = startpos,
				maxs = maxs,
				mins = mins,
				filter = {self:GetRootPart():GetOwner(),ent}
			} )
			return tr.Hit
		end,
		nice = function(self, ent, extra_radius, x_stretch, y_stretch, z_stretch, nearest_model)
			if nearest_model then ent = self:GetOwner() end
			if not IsValid(ent) then return "" end
			local radius = ent:BoundingRadius()

			if radius == 0 and IsValid(ent.pac_projectile) then
				radius = ent.pac_projectile:GetRadius()
			end

			radius = math.Round(math.max(radius + extra_radius + 1, 1))

			local str = self.Event .. " [radius: " .. radius .. ", stretch: " .. x_stretch .. "*" .. y_stretch .. "*" .. z_stretch .. "]"
			return str
		end,
	},

	is_explicit = {
		operator_type = "none",
		tutorial_explanation = "is_explicit activates for viewers who want to hide explicit content with pac_hide_disturbing.\nyou can make special censoring effects for them, for example",

		callback = function(self, ent)
			return GetConVar("pac_hide_disturbing"):GetBool()
		end
	},

	is_in_noclip = {
		operator_type = "none",
		callback = function(self, ent)
			ent = try_viewmodel(ent)
			return ent:GetMoveType() == MOVETYPE_NOCLIP and (not ent.GetVehicle or not ent:GetVehicle():IsValid())
		end,
	},

	is_voice_chatting = {
		operator_type = "none",
		callback = function(self, ent)
			ent = try_viewmodel(ent)
			return ent.IsSpeaking and ent:IsSpeaking()
		end,
	},

	ammo = {
		operator_type = "number", preferred_operator = "above",
		arguments = {{primary = "boolean"}, {amount = "number"}},
		userdata = {{editor_onchange = function(part, num) return math.Round(num) end}},
		callback = function(self, ent, primary, amount)
			ent = try_viewmodel(ent)
			ent = ent.GetActiveWeapon and ent:GetActiveWeapon() or ent

			if ent:IsValid() then
				return self:NumberOperator(ent.Clip1 and (primary and ent:Clip1() or ent:Clip2()) or 0, amount)
			end
		end,
	},
	total_ammo = {
		operator_type = "number", preferred_operator = "above",
		arguments = {{ammo_id = "string"}, {amount = "number"}},
		callback = function(self, ent, ammo_id, amount)
			if ent.GetAmmoCount then
				ammo_id = tonumber(ammo_id) or ammo_id:lower()
				if ammo_id == "primary" then
					local wep = ent.GetActiveWeapon and ent:GetActiveWeapon() or NULL
					return self:NumberOperator(wep:IsValid() and ent:GetAmmoCount(wep:GetPrimaryAmmoType()) or 0, amount)
				elseif ammo_id == "secondary" then
					local wep = ent.GetActiveWeapon and ent:GetActiveWeapon() or NULL
					return self:NumberOperator(wep:IsValid() and ent:GetAmmoCount(wep:GetSecondaryAmmoType()) or 0, amount)
				else
					return self:NumberOperator(ent:GetAmmoCount(ammo_id), amount)
				end
			end
		end,
	},

	clipsize = {
		operator_type = "number", preferred_operator = "above",
		arguments = {{primary = "boolean"}, {amount = "number"}},
		callback = function(self, ent, primary, amount)
			ent = try_viewmodel(ent)
			ent = ent.GetActiveWeapon and ent:GetActiveWeapon() or ent

			if ent:IsValid() then
				return self:NumberOperator(ent.GetMaxClip1 and (primary and ent:GetMaxClip1() or ent:GetMaxClip2()) or 0, amount)
			end
		end,
	},

	vehicle_class = {
		operator_type = "string", preferred_operator = "find simple",
		arguments = {{find = "string"}},
		callback = function(self, ent, find)
			ent = try_viewmodel(ent)
			ent = ent.GetVehicle and ent:GetVehicle() or NULL

			if ent:IsValid() then
				return self:StringOperator(ent:GetClass(), find)
			end
		end,
	},

	vehicle_model = {
		operator_type = "string", preferred_operator = "find simple",
		arguments = {{find = "string"}},
		callback = function(self, ent, find)
			ent = try_viewmodel(ent)
			ent = ent.GetVehicle and ent:GetVehicle() or NULL

			if ent:IsValid() and ent:GetModel() then
				return self:StringOperator(ent:GetModel():lower(), find)
			end
		end,
	},

	driver_name = {
		operator_type = "string", preferred_operator = "find simple",
		arguments = {{find = "string"}},
		callback = function(self, ent, find)
			ent = ent.GetDriver and ent:GetDriver() or NULL

			if ent:IsValid() then
				return self:StringOperator(ent:GetName(), find)
			end
		end,
	},

	entity_class = {
		operator_type = "string", preferred_operator = "find simple",
		arguments = {{find = "string"}},
		callback = function(self, ent, find)
			return self:StringOperator(ent:GetClass(), find)
		end,
	},

	weapon_class = {
		operator_type = "string", preferred_operator = "find simple",
		arguments = {{find = "string"}, {hide = "boolean"}},
		callback = function(self, ent, find, hide)
			ent = try_viewmodel(ent)

			local wep = ent.GetActiveWeapon and ent:GetActiveWeapon() or NULL

			if wep:IsValid() then
				local class_name = wep:GetClass()
				local found = self:StringOperator(class_name, find)

				if class_name == "hands" and not found then
					found = self:StringOperator("none", find)
				end

				if found then
					wep:SetNoDraw(hide)
					wep.pac_weapon_class = true
					return true
				end
			end
		end,
	},

	has_weapon = {
		operator_type = "string", preferred_operator = "find simple",
		arguments = {{find = "string"}},
		callback = function(self, ent, find)
			ent = try_viewmodel(ent)
			local tbl = ent.GetWeapons and ent:GetWeapons()
			if tbl then
				for _, val in pairs(tbl) do
					val = val:GetClass()
					if self:StringOperator(val, find) then
						return true
					end
				end
			end
		end,
	},

	model_name = {
		operator_type = "string", preferred_operator = "find simple",
		arguments = {{find = "string"}},
		callback = function(self, ent, find)
			return self:StringOperator(ent:GetModel(), find)
		end,
	},

	sequence_name = {
		operator_type = "string", preferred_operator = "find simple",
		arguments = {{find = "string"}},
		nice = function(self, ent, find)
			local anim = find
			if find == "" then anim = "<empty string>" end
			local str = self.Event .. " ["..self.Operator.. " " .. anim .. "] | "
			local seq = self.sequence_name or "invalid sequence"
			return str .. seq
		end,
		callback = function(self, ent, find)
			ent = get_owner(self)

			self.sequence_name = ent:GetSequenceName(ent:GetSequence())

			return self:StringOperator(self.sequence_name, find)
		end,
	},

	timer = {
		operator_type = "none",
		arguments = {{interval = "number"}, {offset = "number"}},
		callback = function(self, ent, interval, offset)
			interval = interval or 1
			offset = offset or 0

			if interval == 0 or interval < FrameTime() then
				self.timer_hack = not self.timer_hack
				return self.timer_hack
			end

			return (CurTime() + offset) % interval > (interval / 2)
		end,
	},

	animation_event = {
		operator_type = "string", preferred_operator = "find simple",
		arguments = {{find = "string"}, {time = "number"}, {try_stop_gesture = "boolean"}},
		userdata = {{default = "attack primary", enums = function()
			local tbl = {}
			for i,v in pairs(animation_event_enums) do
				tbl[i] = v
			end
			return tbl
		end}, {default = 0.5}},
		nice = function(self, ent, find, time)
			find = find or ""
			time = time or 0
			local anim = self.anim_name or ""
			local str = self.Event .. " ["..self.Operator.. " \"" .. find .. "\" : " .. time .. " seconds] | "
			return str .. anim
		end,
		callback = function(self, ent, find, time, try_stop_gesture)
			time = time or 0.1

			ent = get_owner(self)

			local data = ent.pac_anim_event
			local b = false

			if data and (self:StringOperator(data.name, find) and (time == 0 or data.time + time > pac.RealTime)) then
				data.reset = false
				b = true
				if try_stop_gesture then
					if string.find(find, "attack grenade") then
						ent:AnimResetGestureSlot( GESTURE_SLOT_GRENADE )
					elseif string.find(find, "attack") or string.find(find, "reload") then
						ent:AnimResetGestureSlot( GESTURE_SLOT_ATTACK_AND_RELOAD )
					elseif string.find(find, "flinch") then
						ent:AnimResetGestureSlot( GESTURE_SLOT_FLINCH )
					end
				end
			end

			if b then
				self.anim_name = data.name
			else
				self.anim_name = nil
			end

			return b
		end,
	},

	fire_bullets = {
		operator_type = "string", preferred_operator = "find simple",
		tutorial_explanation = "fire_bullets supposedly checks what types of bullets you're firing",
		arguments = {{find_ammo = "string"}, {time = "number"}},
		callback = function(self, ent, find, time)
			time = time or 0.1

			ent = try_viewmodel(ent)

			local data = ent.pac_fire_bullets
			local b = false

			if data and (self:StringOperator(data.name, find_ammo) and (time == 0 or data.time + time > pac.RealTime)) then
				data.reset = false
				b = true
			end

			return b
		end,
	},

	emit_sound = {
		operator_type = "string", preferred_operator = "find simple",
		arguments = {{find_sound = "string"}, {time = "number"}, {mute = "boolean"}},
		callback = function(self, ent, find, time, mute)
			time = time or 0.1

			ent = try_viewmodel(ent)

			local data = ent.pac_emit_sound
			local b = false

			if data and (self:StringOperator(data.name, find) and (time == 0 or data.time + time > pac.RealTime)) then
				data.reset = false
				b = true
				if mute then
					data.mute_me = true
				end
			end

			return b
		end,
	},

	command = {
		operator_type = "string", preferred_operator = "equal",
		tutorial_explanation = "the command event reads your pac_event states.\nthe pac_event command can turn on (1), off (0) or toggle (2) a state that has a name.\nfor example, \"pac_event myhat 2\" can be used with a myhat command event to put the hat on or off\n\nwith this event, you read the states that contain this find name\n(equal being an exact match; find and find simple allowing to detect from different states having a part of the name)\n\nthe final result is to activate if:\n\tA) there's one active, or \n\tB) there's one recently turned off not too long ago",
		arguments = {{find = "string"}, {time = "number"}, {hide_in_eventwheel = "boolean"}},
		userdata = {
			{default = "change_me", editor_friendly = "CommandName", enums = function()
				local output = {}
				local parts = pac.GetLocalParts()

				for i, part in pairs(parts) do
					if part.ClassName == "command" then
						local str = part.String
						if string.find(str,"pac_event") then
							for s in string.gmatch(str, "pac_event%s[%w_]+") do
								local name_substring = string.gsub(s,"pac_event%s","")
								output[name_substring] = name_substring
							end
						end

					elseif part.ClassName == "event" and part.Event == "command" then
						local cmd, time, hide = part:GetParsedArgumentsForObject(part.Events.command)
						output[cmd] = cmd
					end
				end

				return output
			end},
			{default = 0, editor_friendly = "EventDuration"},
			{default = false, group = "event wheel", editor_friendly = "HideInEventWheel"}
		},
		nice = function(self, ent, find, time)
			find = find or "?"
			time = time or "?"
			return "command: [" .. self.Operator .. " " .. find .."] | " .. "duration: " .. time
		end,
		callback = function(self, ent, find, time)

			time = time or 0

			local ply = self:GetPlayerOwner()

			local events = ply.pac_command_events

			if events then
				local found = nil
				for _, data in pairs(events) do
					if self:StringOperator(data.name, find) then
						if data.on > 0 then
							found = data.on == 1
						elseif data.time + time > pac.RealTime then
							found = true
						end
					end
				end
				return found
			end
		end,
	},

	say = {
		operator_type = "string", preferred_operator = "find simple",
		tutorial_explanation = "say looks at the chat to find if a certain thing has been said some time ago",
		arguments = {{find = "string"}, {time = "number"}, {all_players = "boolean"}},
		callback = function(self, ent, find, time, all_players)
			time = time or 0.1

			ent = try_viewmodel(ent)

			if all_players then
				for _, ply in ipairs(player.GetAll()) do
					local data = ply.pac_say_event

					if data and self:StringOperator(data.str, find) and data.time + time > pac.RealTime then
						return true
					end
				end
			else
				local owner = self:GetRootPart():GetOwner()
				if owner:IsValid() then
					local data = owner.pac_say_event

					if data and self:StringOperator(data.str, find) and data.time + time > pac.RealTime then
						return true
					end
				end
			end
		end,
	},

	-- outfit owner
	owner_velocity_length = {
		operator_type = "number", preferred_operator = "above",
		arguments = {{speed = "number"}},
		callback = function(self, ent, speed)
			local parent = self:GetParentEx()
			ent = try_viewmodel(ent)

			if parent:IsValid() and ent:IsValid() then
				return self:NumberOperator(get_owner(parent):GetVelocity():Length(), speed)
			end

			return 0
		end,
	},
	owner_velocity_forward = {
		operator_type = "number", preferred_operator = "above",
		arguments = {{speed = "number"}},
		callback = function(self, ent, speed)
			ent = try_viewmodel(ent)

			if ent:IsValid() then
				return self:NumberOperator(convert_angles(self, ent:EyeAngles()):Forward():Dot(ent:GetVelocity()), speed)
			end

			return 0
		end,
	},
	owner_velocity_right = {
		operator_type = "number", preferred_operator = "above",
		arguments = {{speed = "number"}},
		callback = function(self, ent, speed)
			ent = try_viewmodel(ent)

			if ent:IsValid() then
				return self:NumberOperator(convert_angles(self, ent:EyeAngles()):Right():Dot(ent:GetVelocity()), speed)
			end

			return 0
		end,
	},
	owner_velocity_up = {
		operator_type = "number", preferred_operator = "above",
		arguments = {{speed = "number"}},
		callback = function(self, ent, speed)
			ent = try_viewmodel(ent)

			if ent:IsValid() then
				return self:NumberOperator(convert_angles(self, ent:EyeAngles()):Up():Dot(ent:GetVelocity()), speed)
			end

			return 0
		end,
	},
	owner_velocity_world_forward = {
		operator_type = "number", preferred_operator = "above",
		arguments = {{speed = "number"}},
		callback = function(self, ent, speed)
			ent = try_viewmodel(ent)

			if owner:IsValid() then
				return self:NumberOperator(ent:GetVelocity()[1], speed)
			end

			return 0
		end,
	},
	owner_velocity_world_right = {
		operator_type = "number", preferred_operator = "above",
		arguments = {{speed = "number"}},
		callback = function(self, ent, speed)
			ent = try_viewmodel(ent)

			if ent:IsValid() then
				return self:NumberOperator(ent:GetVelocity()[2], speed)
			end

			return 0
		end,
	},
	owner_velocity_world_up = {
		operator_type = "number", preferred_operator = "above",
		arguments = {{speed = "number"}},
		callback = function(self, ent, speed)
			ent = try_viewmodel(ent)

			if ent:IsValid() then
				return self:NumberOperator(ent:GetVelocity()[3], speed)
			end

			return 0
		end,
	},

	-- parent part
	parent_velocity_length = {
		operator_type = "number", preferred_operator = "above",
		arguments = {{speed = "number"}},
		callback = function(self, ent, speed)
			local parent = self:GetParentEx()

			if not self.TargetPart:IsValid() and parent:HasParent() then
				parent = parent:GetParent()
			end

			if parent:IsValid() then
				return self:NumberOperator(calc_velocity(parent):Length(), speed)
			end

			return 0
		end,
	},
	parent_velocity_forward = {
		operator_type = "number", preferred_operator = "above",
		arguments = {{speed = "number"}},
		callback = function(self, ent, speed)
			local parent = self:GetParentEx()

			if not self.TargetPart:IsValid() and parent:HasParent() then
				parent = parent:GetParent()
			end

			if parent:IsValid() and parent.GetWorldAngles then
				return self:NumberOperator(parent:GetWorldAngles():Forward():Dot(calc_velocity(parent)), speed)
			end

			return 0
		end,
	},
	parent_velocity_right = {
		operator_type = "number", preferred_operator = "above",
		arguments = {{speed = "number"}},
		callback = function(self, ent, speed)
			local parent = self:GetParentEx()

			if not self.TargetPart:IsValid() and parent:HasParent() then
				parent = parent:GetParent()
			end

			if parent:IsValid() and parent.GetWorldAngles then
				return self:NumberOperator(parent:GetWorldAngles():Right():Dot(calc_velocity(parent)), speed)
			end

			return 0
		end,
	},
	parent_velocity_up = {
		operator_type = "number", preferred_operator = "above",
		arguments = {{speed = "number"}},
		callback = function(self, ent, speed)
			local parent = self:GetParentEx()

			if not self.TargetPart:IsValid() and  parent:HasParent() then
				parent = parent:GetParent()
			end

			if parent:IsValid() and parent.GetWorldAngles then
				return self:NumberOperator(parent:GetWorldAngles():Up():Dot(calc_velocity(parent)), speed)
			end

			return 0
		end,
	},

	parent_scale_x = {
		operator_type = "number", preferred_operator = "above",
		arguments = {{scale = "number"}},
		callback = function(self, ent, num)
			local parent = self:GetParentEx()

			if not self.TargetPart:IsValid() and parent:HasParent() then
				parent = parent:GetParent()
			end

			if parent:IsValid() then
				return self:NumberOperator((parent.Type == "part" and parent.Scale and parent.Scale.x * parent.Size) or (parent.pac_model_scale and parent.pac_model_scale.x) or (parent.GetModelScale and parent:GetModelScale()) or 1, num)
			end

			return 1
		end,
	},
	parent_scale_y = {
		operator_type = "number", preferred_operator = "above",
		arguments = {{scale = "number"}},
		callback = function(self, ent, num)
			local parent = self:GetParentEx()

			if not self.TargetPart:IsValid() and parent:HasParent() then
				parent = parent:GetParent()
			end

			if parent:IsValid() then
				return self:NumberOperator((parent.Type == "part" and parent.Scale and parent.Scale.y * parent.Size) or (parent.pac_model_scale and parent.pac_model_scale.y) or (parent.GetModelScale and parent:GetModelScale()) or 1, num)
			end

			return 1
		end,
	},
	parent_scale_z = {
		operator_type = "number", preferred_operator = "above",
		arguments = {{scale = "number"}},
		callback = function(self, ent, num)
			local parent = self:GetParentEx()

			if not self.TargetPart:IsValid() and parent:HasParent() then
				parent = parent:GetParent()
			end

			if parent:IsValid() then
				return self:NumberOperator((parent.Type == "part" and parent.Scale and parent.Scale.z * parent.Size) or (parent.pac_model_scale and parent.pac_model_scale.z) or (parent.GetModelScale and parent:GetModelScale()) or 1, num)
			end

			return 1
		end,
	},

	gravitygun_punt = {
		operator_type = "number", preferred_operator = "above",
		arguments = {{time = "number"}},
		callback = function(self, ent, time)
			time = time or 0.1

			ent = try_viewmodel(ent)

			local punted = ent.pac_gravgun_punt

			if punted then
				return self:NumberOperator(pac.RealTime, punted + time)
			end
		end,
	},

	movetype = {
		operator_type = "string", preferred_operator = "find simple",
		arguments = {{find = "string"}},
		callback = function(self, ent, find)
			local mt = ent:GetMoveType()
			if movetypes[mt] then
				return self:StringOperator(movetypes[mt], find)
			end
		end,
	},

	dot_forward = {
		operator_type = "number", preferred_operator = "above",
		tutorial_explanation = "the dot product is a mathematical operation on vectors (angles / arrows / directions).\n\nfor reference, vectors angled 0 degrees apart have dot of 1, 45 degrees is around 0.707 (half of the square root of 2), 90 degrees is 0,\nand when you go beyond that it goes negative the same way (145 degrees: dot = -0.707, 180 degrees: dot = -1).\n\ndot_forward takes the viewer's eye angles and the root owner's FORWARD component of eye angles;\nmakes the dot product and compares it with the number defined in normal.\nfor example, dot_forward below 0.707 should make something visible if you don't look beyond 45 degrees of the direction of the owner's forward eye angles",
		arguments = {{normal = "number"}},
		callback = function(self, ent, normal)

			local owner = self:GetRootPart():GetOwner()

			if owner:IsValid() then
				local ang = owner:EyeAngles()
				ang.p = 0
				return self:NumberOperator(pac.EyeAng:Forward():Dot(ang:Forward()), normal)
			end

			return 0
		end,
	},

	dot_right = {
		operator_type = "number", preferred_operator = "above",
		tutorial_explanation = "the dot product is a mathematical operation on vectors (angles / arrows / directions).\n\nfor reference, vectors angled 0 degrees apart have dot of 1, 45 degrees is around 0.707 (half of the square root of 2), 90 degrees is 0,\nand when you go beyond that it goes negative the same way (145 degrees: dot = -0.707, 180 degrees: dot = -1).\n\ndot_right takes the viewer's eye angles and the root owner's RIGHT component of eye angles;\nmakes the dot product and compares it with the number defined in normal.\nfor example, dot_right below 0.707 should make something visible if you don't look beyond 45 degrees of the direction of the owner's side",

		arguments = {{normal = "number"}},
		callback = function(self, ent, normal)

			local owner = self:GetRootPart():GetOwner()

			if owner:IsValid() then
				local ang = owner:EyeAngles()
				ang.p = 0
				return self:NumberOperator(pac.EyeAng:Right():Dot(ang:Forward()), normal)
			end

			return 0
		end,
	},

	flat_dot_forward = {
		operator_type = "number", preferred_operator = "above",
		tutorial_explanation = "the dot product is a mathematical operation on vectors (angles / arrows / directions).\n\nfor reference, vectors angled 0 degrees apart have dot of 1, 45 degrees is around 0.707 (half of the square root of 2), 90 degrees is 0,\nand when you go beyond that it goes negative the same way (145 degrees: dot = -0.707, 180 degrees: dot = -1).\n\ndot_forward takes the viewer's eye angles and the root owner's FORWARD component of eye angles;\nmakes the dot product and compares it with the number defined in normal.\nfor example, dot_forward below 0.707 should make something visible if you don't look beyond 45 degrees of the direction of the owner's forward eye angles.\nflat means it's projecting onto a 2D plane, so if you're looking down it won't make a difference",

		arguments = {{normal = "number"}},
		callback = function(self, ent, normal)
			local owner = self:GetRootPart():GetOwner()

			if owner:IsValid() then
				local ang = owner:EyeAngles()
				ang.p = 0
				ang.r = 0
				local dir = pac.EyePos - owner:EyePos()
				dir[3] = 0
				dir:Normalize()
				return self:NumberOperator(dir:Dot(ang:Forward()), normal)
			end

			return 0
		end
	},

	flat_dot_right = {
		operator_type = "number", preferred_operator = "above",
		tutorial_explanation = "the dot product is a mathematical operation on vectors (angles / arrows / directions).\n\nfor reference, vectors angled 0 degrees apart have dot of 1, 45 degrees is around 0.707 (half of the square root of 2), 90 degrees is 0,\nand when you go beyond that it goes negative the same way (145 degrees: dot = -0.707, 180 degrees: dot = -1).\n\ndot_right takes the viewer's eye angles and the root owner's RIGHT component of eye angles;\nmakes the dot product and compares it with the number defined in normal.\nfor example, dot_right below 0.707 should make something visible if you don't look beyond 45 degrees of the direction of the owner's side.\nflat means it's projecting onto a 2D plane, so if you're looking down it won't make a difference",

		arguments = {{normal = "number"}},
		callback = function(self, ent, normal)
			local owner = self:GetRootPart():GetOwner()

			if owner:IsValid() then
				local ang = owner:EyeAngles()
				ang.p = 0
				ang.r = 0
				local dir = pac.EyePos - owner:EyePos()
				dir[3] = 0
				dir:Normalize()
				return self:NumberOperator(dir:Dot(ang:Right()), normal)
			end

			return 0
		end
	},

	is_sitting = {
		operator_type = "none",
		callback = function(self, ent)
			if not ent:IsPlayer() then return false end
			local vehicle = ent:GetVehicle()
			if ent.GetSitting then return ent:GetSitting() end --sit anywhere script
			return IsValid(vehicle) and vehicle:GetModel() ~= "models/vehicles/prisoner_pod_inner.mdl" --no prison pod!
		end
	},

	is_driving = {
		operator_type = "none",
		callback = function(self, ent)
			if not ent:IsPlayer() then return false end
			local vehicle = ent:GetVehicle()

			if IsValid(vehicle) then --vehicle entity exists
				if IsValid(vehicle:GetParent()) then --some vehicle seats have a parent
					--print(vehicle:GetParent().PassengerSeats)

					if vehicle:GetParent():GetClass() == "gmod_sent_vehicle_fphysics_base" and ent.IsDrivingSimfphys then --try simfphys
						return ent:IsDrivingSimfphys() and ent:GetVehicle() == ent:GetSimfphys():GetDriverSeat() --in simfphys vehicle and seat is the driver seat
					elseif vehicle:GetParent().BaseClass.ClassName == "wac_hc_base" then --try with WAC aircraft too
						--print(vehicle:GetParent().BaseClass.ClassName, #vehicle:GetParent().Seats)
						--PrintTable(vehicle:GetParent().Seats[1])
						return vehicle == vehicle.wac_seatswitcher.seats[1] --first seat
					end
				elseif vehicle:GetClass() == "prop_vehicle_prisoner_pod" then --we don't want bare seats or prisoner pod
					if vehicle.HandleAnimation == true and not isfunction(vehicle.HandleAnimation) and vehicle:GetModel() ~= "models/vehicles/prisoner_pod_inner.mdl" then --exclude prisoner pod and narrow down to SCars
						return true
					end
					return false
				else --assume that most other classes than prop_vehicle_prisoner_pod are drivable vehicles
					return true
				end
			end
			return false
		end
	},

	is_passenger = {
		operator_type = "none",
		callback = function(self, ent)
			if not ent:IsPlayer() then return false end
			local vehicle = ent:GetVehicle()

			if IsValid(vehicle) then --vehicle entity exists
				if IsValid(vehicle:GetParent()) then --some vehicle seats have a parent
					if vehicle:GetParent():GetClass() == "gmod_sent_vehicle_fphysics_base" and ent.IsDrivingSimfphys then --try simfphys
						return ent:IsDrivingSimfphys() and ent:GetVehicle() ~= ent:GetSimfphys():GetDriverSeat() --in simfphys vehicle and seat is the driver seat
					elseif vehicle:GetParent().BaseClass.ClassName == "wac_hc_base" then --try with WAC aircraft too
						return vehicle ~= vehicle.wac_seatswitcher.seats[1] --first seat
					end
				elseif vehicle:GetClass() == "prop_vehicle_prisoner_pod" then --we can count bare seats and prisoner pods as passengers
					return true
				else --assume that most other classes than prop_vehicle_prisoner_pod are drivable vehicles, but they're also probably single seaters so...
					return false
				end
			end
			return false
		end
	},

	weapon_iron_sight = {
		operator_type = "none",
		callback = function(self, ent)
			if not IsValid(ent) or ent:Health() < 1 then return false end
			if not ent.GetActiveWeapon then return false end
			if not IsValid(ent:GetActiveWeapon()) then return false end
			local wep = ent:GetActiveWeapon()
			if wep.IsFAS2Weapon then
				return wep.dt.Status == FAS_STAT_ADS
			end

			if wep.GetIronSights then return wep:GetIronSights() end
			if wep.Sighted then return wep:GetActiveSights() end --arccw
			return false
		end
	},

	weapon_firemode = {
		operator_type = "mixed",
		arguments = {{name_or_id = "string"}},
		callback = function(self, ent, name_or_id)
			name_or_id = string.lower(name_or_id)
			if not IsValid(ent) or ent:Health() < 1 then return false end
			if not ent.GetActiveWeapon then return false end
			if not IsValid(ent:GetActiveWeapon()) then return false end
			local wep = ent:GetActiveWeapon()

			if wep.ArcCW then
				if wep.Firemodes[wep:GetFireMode()] then --some use a Firemodes table
					if wep.Firemodes[wep:GetFireMode()].PrintName then
						return
						self:StringOperator(name_or_id, wep.Firemodes[wep:GetFireMode()].PrintName)
						or self:StringOperator(name_or_id, wep:GetFiremodeName())
						or self:NumberOperator(wep:GetFireMode(), tonumber(name_or_id))
					end
				elseif wep.Primary then
					if wep.Primary.Automatic ~= nil then
						if wep.Primary.Automatic == true then
							return name_or_id == "automatic" or name_or_id == "auto"
						else
							return name_or_id == "semi-automatic" or name_or_id == "semi-auto" or name_or_id == "single"
						end
					end
					self:StringOperator(name_or_id, wep:GetFiremodeName())
				end
				return self:StringOperator(name_or_id, wep:GetFiremodeName()) or self:NumberOperator(wep:GetFireMode(), tonumber(name_or_id))
			end

			if wep.IsFAS2Weapon then
				if not wep.FireMode then return name_or_id == "" or name_or_id == "nil" or name_or_id == "null" or name_or_id == "none"
				else return self:StringOperator(wep.FireMode, name_or_id) end
			end

			if wep.GetFireModeName then --TFA base is an arbitrary number and name (language-specific)
				return self:StringOperator(string.lower(wep:GetFireModeName()), name_or_id) or self:NumberOperator(wep:GetFireMode(), tonumber(name_or_id))
			end

			if wep.Primary then
				if wep.Primary.Automatic ~= nil then --M9K is a boolean
					if wep.Primary.Automatic == true then
						return name_or_id == "automatic" or name_or_id == "auto" or name_or_id == "1"
					else
						return name_or_id == "semi-automatic" or name_or_id == "semi-auto" or name_or_id == "single" or name_or_id == "0"
					end
				end
			end


			return false
		end,
		nice = function(self, ent, name_or_id)
			if not IsValid(ent) then return end
			if not ent.GetActiveWeapon then return false end
			if not IsValid(ent:GetActiveWeapon()) then return "invalid weapon" end
			wep = ent:GetActiveWeapon()
			local str = "weapon_firemode ["..self.Operator.. " " .. name_or_id .. "] | "

			if wep.IsFAS2Weapon then

				if wep.FireMode then
					str = str .. wep.FireMode .. " | options : "
					for i,v in ipairs(wep.FireModes) do
						str = str .. "(" .. v .. " = " .. i.. "), "
					end
				else str = str .. "<none>" end
				return str
			end

			if wep.ArcCW then
				if not IsValid(wep) then return "no active weapon" end
				if wep.GetFiremodeName then
					str = str .. wep:GetFiremodeName() .. " | options : "
					for i,v in ipairs(wep.Firemodes) do
						if v.PrintName then
							str = str .. "(" .. i .. " = " .. v.PrintName .. "), "
						end
					end
					if wep.Primary.Automatic then
						str = str .. "(" .. "Automatic" .. "), "
					end
				end
				return str
			end

			if wep.GetFireModeName then --TFA base or arccw
				if not IsValid(wep) then return "no active weapon" end
				if wep.GetFireModeName then
					str = str .. wep:GetFireModeName() .. " | options : "
					for i,v in ipairs(wep:GetStatL("FireModes")) do
						str = str .. "(" .. v .. " = " .. i.. "), "
					end
				end
				return str
			end

			if wep.Primary then --M9K
				if wep.Primary.Automatic ~= nil then
					if wep.Primary.Automatic then
						str = str .. "automatic"
					else
						str = str .. "semi-auto"
					end
				end
				str = str .. " | options : 1/auto/automatic, 0/single/semi-auto/semi-automatic"
				return str
			end


			return str
		end
	},

	weapon_safety = {
		operator_type = "none",
		callback = function(self, ent)
			if not ent or not IsValid(ent) then return false end
			if not ent.GetActiveWeapon then return false end
			if not IsValid(ent:GetActiveWeapon()) then return false end
			local wep = ent:GetActiveWeapon()
			if wep.IsSafety then
				return wep:IsSafety()
			end
			if wep.ArcCW then
				return wep:GetFiremodeName() == "Safety"
			end

			return false
		end
	},

	damage_zone_hit = {
		operator_type = "number", preferred_operator = "above",
		arguments = {{time = "number"}, {damage = "number"}, {uid = "string"}},
		userdata = {{default = 1}, {default = 0}, {enums = function(part)
			local output = {}
			local parts = pac.GetLocalParts()

			for i, part in pairs(parts) do
				if part.ClassName == "damage_zone" then
					output["[UID:" .. string.sub(i,1,16) .. "...] " .. part:GetName() .. "; in " .. part:GetParent().ClassName  .. " " .. part:GetParent():GetName()] = part.UniqueID
				end
			end

			return output
		end}},
		callback = function(self, ent, time, damage, uid)
			uid = uid or ""
			uid = string.gsub(uid, "\"", "")
			local valid_uid, err = pcall(pac.GetPartFromUniqueID, pac.Hash(ent), uid)
			if uid == "" then
				for _,part in pairs(pac.GetLocalParts()) do
					if part.ClassName == "damage_zone" then
						if part.dmgzone_hit_done and self:NumberOperator(part.Damage, damage) then
							if part.dmgzone_hit_done + time > CurTime() then
								return true
							end
						end
					end
				end
			elseif not valid_uid and err then
				self:SetError("invalid part Unique ID\n"..err)
			elseif valid_uid then
				local part = pac.GetPartFromUniqueID(pac.Hash(ent), uid)
				if part.ClassName == "damage_zone" then
					if part.dmgzone_hit_done and self:NumberOperator(part.Damage, damage) then
						if part.dmgzone_hit_done + time > CurTime() then
							return true
						end
					end
					self:SetError()
				else
					self:SetError("You set a UID that's not a damage zone!")
				end
			end
			return false
		end,
	},

	damage_zone_kill = {
		operator_type = "mixed", preferred_operator = "above",
		arguments = {{time = "number"}, {uid = "string"}},
		userdata = {{default = 1}, {enums = function(part)
			local output = {}
			local parts = pac.GetLocalParts()

			for i, part in pairs(parts) do
				if part.ClassName == "damage_zone" then
					output["[UID:" .. string.sub(i,1,16) .. "...] " .. part:GetName() .. "; in " .. part:GetParent().ClassName  .. " " .. part:GetParent():GetName()] = part.UniqueID
				end
			end

			return output
		end}},
		callback = function(self, ent, time, uid)
			uid = uid or ""
			uid = string.gsub(uid, "\"", "")
			local valid_uid, err = pcall(pac.GetPartFromUniqueID, pac.Hash(ent), uid)
			if uid == "" then
				for _,part in pairs(pac.GetLocalParts()) do
					if part.ClassName == "damage_zone" then
						if part.dmgzone_kill_done then
							if part.dmgzone_kill_done + time > CurTime() then
								return true
							end
						end
					end
				end
			elseif not valid_uid and err then
				self:SetError("invalid part Unique ID\n"..err)
			elseif valid_uid then
				local part = pac.GetPartFromUniqueID(pac.Hash(ent), uid)
				if part.ClassName == "damage_zone" then
					if part.dmgzone_kill_done then
						if part.dmgzone_kill_done + time > CurTime() then
							return true
						end
					end
					self:SetError()
				else
					self:SetError("You set a UID that's not a damage zone!")
				end
			end
			return false
		end,
	},

	lockpart_grabbed = {
		operator_type = "none",
		callback = function(self, ent)
			return ent.IsGrabbed and ent.IsGrabbedByUID
		end
	},

	lockpart_grabbing = {
		operator_type = "none",
		arguments = {{uid = "string"}},
		userdata = {{enums = function(part)
			local output = {}
			local parts = pac.GetLocalParts()

			for i, part in pairs(parts) do
				if part.ClassName == "lock" then
					output["[UID:" .. string.sub(i,1,16) .. "...] " .. part:GetName() .. "; in " .. part:GetParent().ClassName  .. " " .. part:GetParent():GetName()] = part.UniqueID
				end
			end

			return output
		end}},
		callback = function(self, ent, uid)
			uid = uid or ""
			uid = string.gsub(uid, "\"", "")
			local valid_uid, err = pcall(pac.GetPartFromUniqueID, pac.Hash(ent), uid)
			if uid == "" then
				for _,part in pairs(pac.GetLocalParts()) do
					if part.ClassName == "lock" then
						if part.grabbing then
							return IsValid(part.target_ent)
						end
					end
				end
			elseif not valid_uid and err then
				self:SetError("invalid part Unique ID\n"..err)
			elseif valid_uid then
				local part = pac.GetPartFromUniqueID(pac.Hash(ent), uid)
				if part.ClassName == "lock" then
					if part.grabbing then
						return IsValid(part.target_ent)
					end
					self:SetError()
				else
					self:SetError("You set a UID that's not a lock part!")
				end
			end
			return false
		end
	},

	--[[
		ent.pac_healthbars_layertotals = ent.pac_healthbars_layertotals or {}
		ent.pac_healthbars_uidtotals = ent.pac_healthbars_uidtotals or {}
		ent.pac_healthbars_total = 0
	]]
	healthmod_bar_total = {
		operator_type = "number", preferred_operator = "above",
		arguments = {{HpValue = "number"}},
		userdata = {{default = 0}},
		callback = function(self, ent, HpValue)
			if ent.pac_healthbars and ent.pac_healthbars_total then
				return self:NumberOperator(ent.pac_healthbars_total, HpValue)
			end
			return false
		end,
		nice = function(self, ent, HpValue)
			local str = "healthmod_bar_total : [" .. self.Operator .. " " .. HpValue .. "]"
			if ent.pac_healthbars_total then
				str = str .. " | " .. ent.pac_healthbars_total
			end
			return str
		end
	},

	healthmod_bar_layertotal = {
		operator_type = "number", preferred_operator = "above",
		arguments = {{HpValue = "number"}, {layer = "number"}},
		userdata = {{default = 0}, {default = 0}},
		callback = function(self, ent, HpValue, layer)
			if ent.pac_healthbars and ent.pac_healthbars_layertotals then
				if ent.pac_healthbars_layertotals[layer] then
					return self:NumberOperator(ent.pac_healthbars_layertotals[layer], HpValue)
				end

			end
			return false
		end,
		nice = function(self, ent, HpValue, layer)
			local str = "healthmod_layer_total at layer " .. layer .. " : [" .. self.Operator .. " " .. HpValue .. "]"
			if ent.pac_healthbars_layertotals then
				if ent.pac_healthbars_layertotals[layer] then
					str = str .. " | " .. ent.pac_healthbars_layertotals[layer]
				else
					str = str .. " | not found"
				end

			else
				str = str .. " | not found"
			end
			return str
		end
	},

	healthmod_bar_uidvalue = {
		operator_type = "number", preferred_operator = "above",
		arguments = {{HpValue = "number"}, {part_uid = "string"}},
		userdata = {{default = 0}, {enums = function(part)
			local output = {}
			local parts = pac.GetLocalParts()

			for i, part in pairs(parts) do
				if part.ClassName == "health_modifier" then
					output["[UID:" .. string.sub(i,1,16) .. "...] " .. part:GetName() .. "; in " .. part:GetParent().ClassName  .. " " .. part:GetParent():GetName()] = part.UniqueID
				end
			end

			return output
		end}},
		callback = function(self, ent, HpValue, part_uid)
			part_uid = part_uid or ""
			part_uid = string.gsub(part_uid, "\"", "")
			if ent.pac_healthbars and ent.pac_healthbars_uidtotals then
				if ent.pac_healthbars_uidtotals[part_uid] then
					return self:NumberOperator(ent.pac_healthbars_uidtotals[part_uid], HpValue)
				end
			end
			return false
		end,
		nice = function(self, ent, HpValue, part_uid)
			local str = "healthmod_bar_uidvalue : [" .. self.Operator .. " " .. HpValue .. "]"
			if ent.pac_healthbars_uidtotals then
				if ent.pac_healthbars_uidtotals[part_uid] then
					str = str .. " | " .. ent.pac_healthbars_uidtotals[part_uid]
				else
					str = str .. " | nothing for UID "..part_uid
				end
			else
				str = str .. " | nothing for UID "..part_uid
			end
			return str
		end
	},

}


do

	--[[local base_input_enums_names = {
		["IN_ATTACK"] = 1,
		["IN_JUMP"] = 2,
		["IN_DUCK"] = 4,
		["IN_FORWARD"] = 8,
		["IN_BACK"] = 16,
		["IN_USE"] = 32,
		["IN_CANCEL"]	= 64,
		["IN_LEFT"] = 128,
		["IN_RIGHT"] = 256,
		["IN_MOVELEFT"] = 512,
		["IN_MOVERIGHT"] = 1024,
		["IN_ATTACK2"] = 2048,
		["IN_RUN"] = 4096,
		["IN_RELOAD"] = 8192,
		["IN_ALT1"] = 16384,
		["IN_ALT2"] = 32768,
		["IN_SCORE"] = 65536,
		["IN_SPEED"] = 131072,
		["IN_WALK"] = 262144,
		["IN_ZOOM"] = 524288,
		["IN_WEAPON1"] = 1048576,
		["IN_WEAPON2"] = 2097152,
		["IN_BULLRUSH"] = 4194304,
		["IN_GRENADE1"] = 8388608,
		["IN_GRENADE2"] = 16777216
	}
	local input_aliases = {}

	for name,value in pairs(base_input_enums_names) do
		local alternative0 = string.lower(name)
		local alternative1 = string.Replace(string.lower(name),"in_","")
		local alternative2 = "+"..alternative1
		input_aliases[name] = value
		input_aliases[alternative0] = value
		input_aliases[alternative1] = value
		input_aliases[alternative2] = value
	end]]


	local enums = {}
	local enums2 = {}
	for key, val in pairs(_G) do
		if isstring(key) and isnumber(val) then
			if key:sub(0,4) == "KEY_" and not key:find("_LAST$") and not key:find("_FIRST$")  and not key:find("_COUNT$")  then
				enums[val] = key:sub(5):lower()
				enums2[enums[val]] = val
			elseif (key:sub(0,6) == "MOUSE_" or key:sub(0,9) == "JOYSTICK_") and not key:find("_LAST$") and not key:find("_FIRST$")  and not key:find("_COUNT$")  then
				enums[val] = key:lower()
				enums2[enums[val]] = val
			end
		end
	end

	pac.key_enums = enums

--@note button broadcast

	--TODO: Rate limit!!!
	net.Receive("pac.BroadcastPlayerButton", function()
		local ply = net.ReadEntity()

		if not ply:IsValid() then return end

		if ply == pac.LocalPlayer and (pace and pace.IsFocused() or gui.IsConsoleVisible()) then return end

		local key = net.ReadUInt(8)
		local down = net.ReadBool()

		if not pac.key_enums then --rebuild the enums
			local enums = {}
			local enums2 = {}
			for key, val in pairs(_G) do
				if isstring(key) and isnumber(val) then
					if key:sub(0,4) == "KEY_" and not key:find("_LAST$") and not key:find("_FIRST$")  and not key:find("_COUNT$")  then
						enums[val] = key:sub(5):lower()
						enums2[enums[val]] = val
					elseif (key:sub(0,6) == "MOUSE_" or key:sub(0,9) == "JOYSTICK_") and not key:find("_LAST$") and not key:find("_FIRST$")  and not key:find("_COUNT$")  then
						enums[val] = key:lower()
						enums2[enums[val]] = val
					end
				end
			end

			pac.key_enums = enums
		end

		key = pac.key_enums[key] or key

		ply.pac_buttons = ply.pac_buttons or {}
		ply.pac_buttons[key] = down


		ply.pac_broadcasted_buttons_lastpressed = ply.pac_broadcasted_buttons_lastpressed or {}
		if down then
			ply.pac_broadcasted_buttons_lastpressed[key] = SysTime()
		end

		--outsource the part pool operations
		pac.UpdateButtonEvents(ply, key, down)


	end)

	PART.OldEvents.button = {
		operator_type = "none",
		arguments = {{button = "string"}, {holdtime = "number"}, {toggle = "boolean"}},
		userdata = {{enums = function()
			return enums
		end, default = "mouse_left"}, {default = 0}, {default = false}},
		nice = function(self, ent, button)
			local ply = self:GetPlayerOwner()

			local active = {}
			if ply.pac_buttons then
				for k,v in pairs(ply.pac_buttons) do
					if v then
						table.insert(active, "\"" .. tostring(k) .. "\"")
					end
				end
			end
			active = table.concat(active, " or ")

			if active == "" then
				active = "-"
			end

			return self:GetOperator() .. " \"" .. button .. "\"" .. " in (" .. active .. ")"
		end,
		callback = function(self, ent, button, holdtime, toggle)

			local holdtime = holdtime or 0
			local toggle = toggle or false

			self.togglestate = self.togglestate or false
			self.holdtime = holdtime
			self.toggle = toggle

			self.toggleimpulsekey = self.toggleimpulsekey or {}

			if self.toggleimpulsekey[button] then
				self.togglestate = not self.togglestate
				self.toggleimpulsekey[button] = false
			end

			--print(button, "hold" ,self.holdtime)
			local ply = self:GetPlayerOwner()
			self.pac_broadcasted_buttons_holduntil = self.pac_broadcasted_buttons_holduntil or {}


			if ply == pac.LocalPlayer then

				ply.pac_broadcast_buttons = ply.pac_broadcast_buttons or {}

				if not ply.pac_broadcast_buttons[button] then
					local val = enums2[button:lower()]
					if val then
						net.Start("pac.AllowPlayerButtons")
						net.WriteUInt(val, 8)
						net.SendToServer()
					end
					ply.pac_broadcast_buttons[button] = true
				end

				--print(button, ply.pac_broadcasted_buttons_holduntil[button], ply.pac_broadcast_buttons[button])
				--PrintTable(ply.pac_broadcast_buttons)
				--PrintTable(self.pac_broadcasted_buttons_holduntil)
			end

			local buttons = ply.pac_buttons

			self.pac_broadcasted_buttons_holduntil[button] = self.pac_broadcasted_buttons_holduntil[button] or SysTime()
			--print(button, self.toggle, self.togglestate)
			--print(button,"until",self.pac_broadcasted_buttons_holduntil[button])
			if buttons then
				--print("trying to compare " .. SysTime() .. " > " .. self.pac_broadcasted_buttons_holduntil[button] - 0.05)
				if self.toggle then
					return self.togglestate
				elseif self.holdtime > 0 then
					return SysTime() < self.pac_broadcasted_buttons_holduntil[button]
				else
					return buttons[button]
				end

			end
		end,
	}

end

do
	local eventMeta = {}

	eventMeta.__name = 'undefined'
	AccessorFunc(eventMeta, '__name', 'Name')
	AccessorFunc(eventMeta, '__name', 'EventName')
	AccessorFunc(eventMeta, '__name', 'Nick')

	function eventMeta:IsValid(event)
		return true
	end

	function eventMeta:IsAvailable(eventPart)
		return true
	end

	function eventMeta:GetArguments()
		self.__registeredArguments = self.__registeredArguments or {}
		return self.__registeredArguments
	end

	function eventMeta:AppendArgument(keyName, keyType, userdata)
		self.__registeredArguments = self.__registeredArguments or {}
		if not keyType then
			error('No Type of argument was specified!')
		end

		if keyType ~= 'number' and keyType ~= 'string' and keyType ~= 'boolean' then
			error('Invalid Type of argument was passed. Valids are number, string or boolean')
		end

		for i, data in ipairs(self.__registeredArguments) do
			if data[1] == keyName then
				error('Argument with key ' .. keyName .. ' already exists!')
			end
		end

		self.__registeredArguments = self.__registeredArguments or {}
		table.insert(self.__registeredArguments, {keyName, keyType, userdata})
	end

	function eventMeta:PopArgument(keyName)
		for i, data in ipairs(self.__registeredArguments) do
			if data[1] == keyName then
				return true, i, table.remove(self.__registeredArguments, i)
			end
		end

		return false
	end

	eventMeta.RemoveArgument = eventMeta.PopArgument
	eventMeta.SpliceArgument = eventMeta.PopArgument

	function eventMeta:GetClass()
		return self.__classname
	end

	function eventMeta:Think(event, ent, ...)
		return false
	end

	function eventMeta:GetNiceName(part, ent)
		if self.extra_nice_name then
			return self.extra_nice_name(part, ent, part:GetParsedArgumentsForObject(self))
		end

		local str = part:GetEvent()

		if part:GetArguments() ~= "" then
			local args = part:GetArguments():gsub(";", " or ")

			if not tonumber(args) then
				args = [["]] .. args .. [["]]
			end
			str = str .. " " .. part:GetOperator() .. " " .. args
		end

		return pac.PrettifyName(str)
	end

	local eventMetaTable = {
		__index = function(self, key)
			if key == '__class' or key == '__classname' then
				return rawget(getmetatable(self), '__classname')
			end

			if rawget(self, key) ~= nil then
				return rawget(self, key)
			end

			return eventMeta[key]
		end,

		__call = function(self)
			local newObj = pac.CreateEvent(self:GetClass())

			for k, v in pairs(self) do
				if not istable(v) then
					newObj[k] = v
				else
					newObj[k] = table.Copy(v)
				end
			end

			return newObj
		end,

		-- __newindex = function(self, key, val)
		--  rawset(self, key, val)
		-- end
	}

	function pac.GetEventMetatable()
		return eventMeta
	end

	function pac.CreateEvent(nClassName, defArguments)
		if not nClassName then error('No classname was specified!') end

		local newObj = setmetatable({}, {
			__index = eventMetaTable.__index,
			__call = eventMetaTable.__call,
			__classname = nClassName
		})

		newObj.__registeredArguments = {}
		newObj:SetName(nClassName)

		if defArguments then
			for i, data in pairs(defArguments) do
				newObj:AppendArgument(data[1], data[2], data[3])
			end
		end

		return newObj
	end

	function pac.RegisterEvent(nRegister)
		local classname = nRegister:GetClass()

		if PART.Events[classname] then
			pac.Message('WARN: Registering event with already existing classname!: '.. classname)
		end

		PART.Events[classname] = nRegister
	end

	for classname, data in pairs(PART.OldEvents) do
		local arguments = data.arguments
		local think = data.callback
		local eventObject = pac.CreateEvent(classname)

		if arguments then
			for i, data2 in ipairs(arguments) do
				local key, Type = next(data2)
				eventObject:AppendArgument(key, Type, data.userdata and data.userdata[i] or nil)
			end
		end

		eventObject.extra_nice_name = data.nice

		local operator_type = data.operator_type
		local preferred_operator = data.preferred_operator
		local tutorial_explanation = data.tutorial_explanation
		eventObject.operator_type = operator_type
		eventObject.preferred_operator = preferred_operator
		eventObject.tutorial_explanation = tutorial_explanation

		function eventObject:Think(event, ent, ...)
			return think(event, ent, ...)
		end

		pac.RegisterEvent(eventObject)
	end

	timer.Simple(0, function() -- After all addons has loaded
		hook.Call('PAC3RegisterEvents', nil, pac.CreateEvent, pac.RegisterEvent)
	end)
end

-- custom animation event
do
	local animations = pac.animations
	local event = {
		operator_type = "none",
		tutorial_explanation = "selecting a custom animation part via UID,\nthis event activates whenever the linked custom animation is currently playing somewhere between the frames specified",
		name = "custom_animation_frame",
		nice = function(self, ent, animation)
			if animation == "" then self:SetWarning("no animation selected") return "no animation" end
			local part = pac.GetLocalPart(animation)
			if not IsValid(part) then self:SetError("invalid animation selected") return "invalid animation" end
			self:SetWarning()
			return part:GetName()
		end,
		args = {
			{"animation", "string", {editor_panel = "custom_animation_frame"}},
			{"frame_start", "number", {
				editor_onchange = function(self, num)
					local anim = pace.current_part:GetProperty("animation")
					if anim ~= "" then
						local part = pac.GetLocalPart(anim)
						-- GetAnimationDuration only works while editor is active for some reason
						local data = util.JSONToTable(part:GetData())
						return math.Clamp(math.ceil(num), 1, #data.FrameData)
					end
				end
			}},
			{"frame_end", "number", {
				editor_onchange = function(self, num)
					local anim = pace.current_part:GetProperty("animation")
					local start = pace.current_part:GetProperty("frame_start")
					if anim ~= "" then
						local part = pac.GetLocalPart(anim)
						-- GetAnimationDuration only works while editor is active for some reason
						local data = util.JSONToTable(part:GetData())
						return math.Clamp(math.ceil(num), start, #data.FrameData)
					end
				end
			}},
			--{"framedelta", "number", {editor_clamp = {0,1}, editor_sensitivity = 0.15}}
		},
		available = function(self, eventPart)
			return next(animations.registered) and true or false
		end,
		func = function (self, eventPart, ent, animation, frame_start, frame_end)
			local frame_start = frame_start or 1
			local frame_end = frame_end or 1
			if not animation or animation == "" then return end
			if not IsValid(ent) then return end
			if not next(animations.playing) then return end
			for i,v in ipairs(animations.playing) do
				if v == ent then
					local part = pac.GetPartFromUniqueID(pac.Hash(ent), animation)
					if not IsValid(part) then return end
					if part.ClassName ~= "custom_animation" then return end
					local frame, delta = animations.GetEntityAnimationFrame(ent, part:GetAnimID())
					if not frame or not delta then return end -- different animation part is playing
					return frame >= frame_start and frame <= frame_end
				end
			end
		end
	}

	local eventObject = pac.CreateEvent(event.name, event.args)
	eventObject.Think = event.func
	eventObject.IsAvailable = event.available
	eventObject.extra_nice_name = event.nice

	data = event

	local operator_type = data.operator_type
	local preferred_operator = data.preferred_operator
	local tutorial_explanation = data.tutorial_explanation
	eventObject.operator_type = operator_type
	eventObject.preferred_operator = preferred_operator
	eventObject.tutorial_explanation = tutorial_explanation

	pac.RegisterEvent(eventObject)
end

-- DarkRP default events
do
	local plyMeta = FindMetaTable('Player')
	local gamemode = engine.ActiveGamemode
	local isDarkRP = function() return gamemode() == 'darkrp' end

	local events = {
		{
			name = 'is_arrested',
			args = {},
			available = function() return plyMeta.isArrested ~= nil end,
			func = function(self, eventPart, ent)
				ent = try_viewmodel(ent)
				return ent.isArrested and ent:isArrested() or false
			end
		},

		{
			name = 'is_wanted',
			args = {},
			available = function() return plyMeta.isWanted ~= nil end,
			func = function(self, eventPart, ent)
				ent = try_viewmodel(ent)
				return ent.isWanted and ent:isWanted() or false
			end
		},

		{
			name = 'is_police',
			args = {},
			available = function() return plyMeta.isCP ~= nil end,
			func = function(self, eventPart, ent)
				ent = try_viewmodel(ent)
				return ent.isCP and ent:isCP() or false
			end
		},

		{
			name = 'wanted_reason',
			args = {{'find', 'string'}},
			available = function() return plyMeta.getWantedReason ~= nil and plyMeta.isWanted ~= nil end,
			func = function(self, eventPart, ent, find)
				ent = try_viewmodel(ent)
				return eventPart:StringOperator(ent.isWanted and ent.getWantedReason and ent:isWanted() and ent:getWantedReason() or '', find)
			end
		},

		{
			name = 'is_cook',
			args = {},
			available = function() return plyMeta.isCook ~= nil end,
			func = function(self, eventPart, ent)
				ent = try_viewmodel(ent)
				return ent.isCook and ent:isCook() or false
			end
		},

		{
			name = 'is_hitman',
			args = {},
			available = function() return plyMeta.isHitman ~= nil end,
			func = function(self, eventPart, ent)
				ent = try_viewmodel(ent)
				return ent.isHitman and ent:isHitman() or false
			end
		},

		{
			name = 'has_hit',
			args = {},
			available = function() return plyMeta.hasHit ~= nil end,
			func = function(self, eventPart, ent)
				ent = try_viewmodel(ent)
				return ent.hasHit and ent:hasHit() or false
			end
		},

		{
			name = 'hit_price',
			args = {{'amount', 'number'}},
			available = function() return plyMeta.getHitPrice ~= nil end,
			func = function(self, eventPart, ent, amount)
				ent = try_viewmodel(ent)
				return eventPart:NumberOperator(ent.getHitPrice and ent:getHitPrice() or 0, amount)
			end
		},
	}

	for k, v in ipairs(events) do
		local available = v.available
		local eventObject = pac.CreateEvent(v.name, v.args)
		eventObject.Think = v.func

		function eventObject:IsAvailable()
			return isDarkRP() and available()
		end

		local operator_type = v.operator_type
		local preferred_operator = v.preferred_operator
		local tutorial_explanation = v.tutorial_explanation
		eventObject.operator_type = operator_type
		eventObject.preferred_operator = preferred_operator
		eventObject.tutorial_explanation = tutorial_explanation

		pac.RegisterEvent(eventObject)
	end
end

function PART:GetParentEx()
	local parent = self:GetTargetPart()

	if parent:IsValid() then
		return parent
	end

	return self:GetParent()
end

function PART:GetNiceName()
	local event_name = self:GetEvent()

	if not PART.Events[event_name] then return "unknown event" end

	return PART.Events[event_name]:GetNiceName(self, get_owner(self))
end

local function is_hidden_by_something_else(part, ignored_part)
	if part.active_events_ref_count > 0 and not part.active_events[ignored_part] then
		return true
	end

	return part.Hide
end

function PART:IsHiddenBySomethingElse(only_self)
	if is_hidden_by_something_else(self, self) then
		return true
	end

	if only_self then return false end

	for _, parent in ipairs(self:GetParentList()) do
		if is_hidden_by_something_else(parent, self) then
			return true
		end
	end

	return false
end

local function should_trigger(self, ent, eventObject)
	if not eventObject:IsAvailable(self) then
		return true
	end

	local b = false
	if eventObject.ParseArguments then
		b = eventObject:Think(self, ent, eventObject:ParseArguments(self)) or false
	else
		b = eventObject:Think(self, ent, self:GetParsedArgumentsForObject(eventObject)) or false
	end

	if self.Invert then
		b = not b
	end

	if is_hidden_by_something_else(self, self) then
		b = self.Invert
	end

	self.is_active = b

	return b
end

PART.last_event_triggered = false

function PART:fix_args()
	local args = string.Split(self.Arguments, "@@")
	if self.Events[self.Event] then
		if self.Events[self.Event].__registeredArguments then
			--PrintTable(self.Events[self.Event].__registeredArguments)
			if #self.Events[self.Event].__registeredArguments ~= #args then
				for argn,arg in ipairs(self.Events[self.Event].__registeredArguments) do
					if not args[argn] or args[argn] == "" then
						local added_arg = "0"
						if arg[2] == "boolean" then
							if arg[3] then
								if arg[3].default then added_arg = "1"
								else added_arg = "0" end
							end
						else
							if arg[3] then
								if arg[3].default then
									added_arg = tostring(arg[3].default)
								end
							end
						end
						args[argn] = added_arg
					end
				end
				self.Arguments = table.concat(args, "@@")
			end
		end
	end
end

function PART:OnThink()
	self.nextactivationrefresh = self.nextactivationrefresh or CurTime()
	if not self.singleactivatestate and self.nextactivationrefresh < CurTime() then
		self.singleactivatestate = true
	end

	local ent = get_owner(self)
	if not ent:IsValid() then return end

	local data = PART.Events[self.Event]

	if not data then return end

	self:fix_args()
	self:TriggerEvent(should_trigger(self, ent, data))

	if pace and pace.IsActive() and self.Name == "" then
		if self.pace_properties and self.pace_properties["Name"] and self.pace_properties["Name"]:IsValid() then
			self.pace_properties["Name"]:SetText(self:GetNiceName())
		end
	end

end

function PART:SetAffectChildrenOnly(b)
	if b == nil then return end

	if self.AffectChildrenOnly ~= nil and self.AffectChildrenOnly ~= b then
		--print("changing")
		local ent = get_owner(self)
		local data = PART.Events[self.Event]

		if ent:IsValid() and data then
			local b = should_trigger(self, ent, data)
			if self.AffectChildrenOnly then
				local parent = self:GetParent()
				if parent:IsValid() then
					parent:SetEventTrigger(self, b)

					for _, child in ipairs(self:GetChildren()) do
						if child.active_events[self] then
							child.active_events[self] = nil
							child.active_events_ref_count = child.active_events_ref_count - 1
							child:CallRecursive("CalcShowHide", false)
						end
					end
				end

			else
				for _, child in ipairs(self:GetChildren()) do
					child:SetEventTrigger(self, b)
				end
				if self:GetParent():IsValid() then
					local parent = self:GetParent()
					if parent.active_events[self] then
						parent.active_events[self] = nil
						parent.active_events_ref_count = parent.active_events_ref_count - 1
						parent:CallRecursive("CalcShowHide", false)
					end
				end

			end
		end
	end
	self.AffectChildrenOnly = b

end

function PART:OnRemove()
	if not self.AffectChildrenOnly then
		local parent = self:GetParent()
		if parent:IsValid() then
			parent.active_events[self] = nil
			parent.active_events_ref_count = parent.active_events_ref_count - 1
			parent:CalcShowHide()
		end
	end
	if IsValid(self.DestinationPart) then
		self.DestinationPart.active_events[self] = nil
		self.DestinationPart.active_events_ref_count = self.DestinationPart.active_events_ref_count - 1
		self.DestinationPart:CalcShowHide()
	end
end

function PART:TriggerEvent(b)
	self.event_triggered = b -- event_triggered is just used for the editor

	if self.AffectChildrenOnly then
		for _, child in ipairs(self:GetChildren()) do
			child:SetEventTrigger(self, b)
		end
	else
		local parent = self:GetParent()
		if parent:IsValid() then
			parent:SetEventTrigger(self, b)
		end
	end
	if IsValid(self.DestinationPart) then --target part. the proper one.
		if IsValid(self.previousdestinationpart) then
			if self.DestinationPart ~= self.previousdestinationpart then --once we change the destination part we need to reset the old one
				self.previousdestinationpart:SetEventTrigger(self, false)
			end
		end

		(self.DestinationPart):SetEventTrigger(self, b)
		self.previousdestinationpart = (self.DestinationPart)
	elseif IsValid(self.previousdestinationpart) then
		if self.DestinationPart ~= self.previousdestinationpart then --once we change the destination part we need to reset the old one
			self.previousdestinationpart:SetEventTrigger(self, false)
		end
	end
end

PART.Operators = {
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

function PART:GetParsedArguments(eventObject)
	if not eventObject then return end

	if eventObject.ParseArguments then
		return eventObject:ParseArguments(self)
	end

	return self:GetParsedArgumentsForObject(eventObject)
end

function PART:GetParsedArgumentsForObject(eventObject)
	if not eventObject then return end

	local line = self.Arguments
	local hash = line .. tostring(eventObject)

	if pac.EventArgumentCache[hash] then
		return unpack(pac.EventArgumentCache[hash])
	end

	local args = line:Split("@@")

	for i, argData in pairs(eventObject:GetArguments()) do
		local typ = argData[2]

		if args[i] ~= nil then
			if typ == "boolean" then
				args[i] = tonumber(args[i]) ~= 0
			elseif typ == "number" then
				args[i] = tonumber(args[i]) or 0
			elseif typ == "string" then
				args[i] = tostring(args[i]) or ""
			end
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
		return CompareBTable(a, args, function(x, y) return x == y end)
	elseif self.Operator == "not equal" then
		return CompareBTable(a, args, function(x, y) return x ~= y end)
	elseif self.Operator == "find" then
		return CompareBTable(a, args, pac.StringFind)
	elseif self.Operator == "find simple" then
		return CompareBTable(a, args, pac.StringFind, true)
	elseif self.Operator == "changed" then
		if a ~= self.changed_last_a then
			self.changed_last_a = a

			return true
		end
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



function PART:OnHide()
	if self.timerx_reset then
		self.time = nil
		self.number = 0
	end

	if self.Event == "weapon_class" then
		local ent = self:GetOwner()
		if ent:IsValid() then
			ent = ent.GetActiveWeapon and ent:GetActiveWeapon() or NULL
			if ent:IsValid() then
				ent.pac_weapon_class = nil
				ent:SetNoDraw(false)
			end
		end
	end
end

function PART:OnShow()
	if self.timerx_reset then
		self.time = nil
		self.number = 0
	end
	self.showtime = CurTime()
	self.singleactivatestate = true
end

function PART:OnAnimationEvent(ent)
	if self.Event == "animation_event" then
		self:GetParent():CallRecursive("Think")
	end
end

function PART:OnFireBullets()
	if self.Event == "fire_bullets" then
		self:GetParent():CallRecursive("Think")
	end
end

function PART:OnEmitSound(ent)
	if self.Event == "emit_sound" then
		self:GetParent():CallRecursive("Think")

		if ent.pac_emit_sound.mute_me then
			return false
		end
	end
end

BUILDER:Register()

do
	local enums = {}

	for key, val in pairs(_G) do
		if isstring(key) and key:find("PLAYERANIMEVENT_", nil, true) then
			enums[val] = key:gsub("PLAYERANIMEVENT_", ""):gsub("_", " "):lower()
		end
	end

	pac.AddHook("DoAnimationEvent", "animation_events", function(ply, event, data)
		-- update all parts once so OnShow and OnHide are updated properly for animation events
		if ply.pac_has_parts then
			ply.pac_anim_event = {name = enums[event], time = pac.RealTime, reset = true}

			pac.CallRecursiveOnAllParts("OnAnimationEvent")
		end
	end)
end


pac.AddHook("EntityEmitSound", "emit_sound", function(data)
	if pac.playing_sound then return end
	local ent = data.Entity

	if not ent:IsValid() or not ent.pac_has_parts then return end

	ent.pac_emit_sound = {name = data.SoundName, time = pac.RealTime, reset = true, mute_me = ent.pac_emit_sound and ent.pac_emit_sound.mute_me or false}

	if pac.CallRecursiveOnAllParts("OnEmitSound", ent) == false then
		return false
	end

	if ent.pac_mute_sounds then
		return false
	end
end)

pac.AddHook("EntityFireBullets", "firebullets", function(ent, data)
	if not ent:IsValid() or not ent.pac_has_parts then return end
	ent.pac_fire_bullets = {name = data.AmmoType, time = pac.RealTime, reset = true}

	pac.CallRecursiveOnAllParts("OnFireBullets")

	if ent.pac_hide_bullets then
		return false
	end
end)

--for regaining focus on cameras from first person, hacky thing to not loop through localparts every time
--only if the received command name matches that of a camera's linked command event
--we won't be finding from substrings
pac.camera_linked_command_events = {}
local initially_check_camera_linked_command_events = true

net.Receive("pac_event", function(umr)
	local ply = net.ReadEntity()
	local str = net.ReadString()
	local on = net.ReadInt(8)

	-- ^ resets all other events
	if str:find("^", 0, true) then
		ply.pac_command_events = {}
	end

	if ply:IsValid() then
		ply.pac_command_events = ply.pac_command_events or {}
		ply.pac_command_events[str] = {name = str, time = pac.RealTime, on = on}
		if pac.LocalPlayer == ply then
			if pac.camera_linked_command_events[str] then --if this might be related to a camera
				pac.TryToAwakenDormantCameras()
			elseif initially_check_camera_linked_command_events then --if it's not known, check only once for initialize this might be related to a camera
				pac.TryToAwakenDormantCameras(true)
				initially_check_camera_linked_command_events = false
			end
		end
	end
end)

concommand.Add("pac_wipe_events", function(ply)
	ply.pac_command_events = nil
	ply.pac_command_event_sequencebases = nil
	pac.camera_linked_command_events = {}
end)
concommand.Add("pac_print_events", function(ply)
	ply.pac_command_events = ply.pac_command_events or {}
	PrintTable(ply.pac_command_events)
end)

concommand.Add("pac_event_sequenced", function(ply, cmd, args)

	if not args[1] then return end

	local event = args[1]
	local action = args[2] or "+"
	local sequence_number = 0
	local set_target = args[3] or 1
	local found = false

	ply.pac_command_events = ply.pac_command_events or {}
	ply.pac_command_events[event..1] = ply.pac_command_events[event..1] or {name = event..1, time = 0, on = 1}

	ply.pac_command_event_sequencebases = ply.pac_command_event_sequencebases or {}

	if not ply.pac_command_event_sequencebases[event] then
		ply.pac_command_event_sequencebases[event] = {name = event, min = 1, max = 1}
	end

	local target_number = 1
	local min = 1
	local max = ply.pac_command_event_sequencebases[event].max

	for i=1,100,1 do
		if ply.pac_command_events[event..i] then
			if ply.pac_command_events[event..i].on == 1 then
				if sequence_number == 0 then sequence_number = i end
				found = true
			end
		--elseif ply.pac_command_events[event..i] == nil then
			ply.pac_command_events[event..i] = {name = event..i, time = 0, on = 0}
		end
	end

	if found then
		if action == "+" or action == "forward" or action == "add" or action == "sequence+" or action == "advance" then

			ply.pac_command_events[event..sequence_number] = {name = event..sequence_number, time = pac.RealTime, on = 0}
			if sequence_number == max then
				target_number = min
			else target_number = sequence_number + 1 end

			pac.Message("sequencing event series: " .. event .. "\n\t" .. sequence_number .. "->" .. target_number .. " / " .. max, "action: "..action)
			ply.pac_command_events[event..target_number] = {name = event..target_number, time = pac.RealTime, on = 1}

			RunConsoleCommand("pac_event", event..sequence_number, "0")
			RunConsoleCommand("pac_event", event..target_number, "1")


		elseif action == "-" or action == "backward" or action == "sub" or action == "sequence-" then

			ply.pac_command_events[event..sequence_number] = {name = event..sequence_number, time = pac.RealTime, on = 0}
			if sequence_number == min then
				target_number = max
			else target_number = sequence_number - 1 end

			print("sequencing event series: " .. event .. "\n\t" .. sequence_number .. "->" .. target_number .. " / " .. max, "action: "..action)
			ply.pac_command_events[event..target_number] = {name = event..target_number, time = pac.RealTime, on = 1}

			RunConsoleCommand("pac_event", event..sequence_number, "0")
			RunConsoleCommand("pac_event", event..target_number, "1")

		elseif action == "set" then
			print("sequencing event series: " .. event .. "\n\t" .. sequence_number .. "->" .. set_target .. " / " .. max)

			sequence_number = set_target or 1
			for i=1,100,1 do
				ply.pac_command_events[event..i] = nil
			end
			ply.pac_command_events[event..sequence_number] = {name = event..sequence_number, time = pac.RealTime, on = 1}
			target_number = set_target
			net.Start("pac_event_set_sequence")
			net.WriteString(event)
			net.WriteUInt(sequence_number,8)
			net.SendToServer()
		end
	end
end)


pac.AddHook("OnPlayerChat", "say_event", function(ply, str)
	if ply:IsValid() then
		ply.pac_say_event = {str = str, time = pac.RealTime}
	end
end)

pac.AddHook("GravGunOnPickedUp", "gravgun_event", function(ply, ent)
	if ply:IsValid() then
		ply.pac_gravgun_ent = ent
	end
end)

pac.AddHook("GravGunOnDropped", "gravgun_event", function(ply, ent)
	if ply:IsValid() then
		ply.pac_gravgun_ent = ent
	end
end)
-- ####

pac.AddHook("GravGunPunt", "gravgun_event", function(ply, ent)
	if ply:IsValid() then
		ply.pac_gravgun_ent = ent
		ply.pac_gravgun_punt = pac.RealTime
	end
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
--]]

local eventwheel_visibility_rule = CreateConVar("pac_eventwheel_visibility_rule" , "0", FCVAR_ARCHIVE,
"Different ways to filter your command events for the wheel.\n"..
"-1 ignores hide flags completely\n"..
"0 will hide a command if at least one event of one name has the \"hide in event wheel\" flag\n"..
"1 will hide a command only if ALL events of one name have the \"hide in event wheel\" flag\n"..
"2 will hide a command as soon as one event of a name is being hidden\n"..
"3 will hide a command only if ALL events of a name are being hidden\n"..
"4 will only show commands containing the following substrings, separated by spaces\n"..
"-4 will hide commands containing the following substrings, separated by spaces")

local eventwheel_style = CreateConVar("pac_eventwheel_style", "0", FCVAR_ARCHIVE, "The style of the eventwheel.\n0 is the default legacy style with one circle\n1 is the new style with colors, using one circle for the color and one circle for the activation indicator\n2 is an alternative style using a smaller indicator circle on the corner of the circle")
local eventlist_style = CreateConVar("pac_eventlist_style", "0", FCVAR_ARCHIVE, "The style of the eventwheel list alternative.\n0 is like the default eventwheel legacy style with one indicator for the activation\n1 is the new style with colors, using one rectangle for the color and one rectangle for the activation indicator\n2 is an alternative style using a smaller indicator on the corner")
local show_customize_button = CreateConVar("pac_eventwheel_show_customize_button", "1", FCVAR_ARCHIVE, "Whether to show the Customize button with the event wheel.")

local eventwheel_font = CreateConVar("pac_eventwheel_font", "DermaDefault", FCVAR_ARCHIVE, "pac3 eventwheel font. try pac_font_<size> such as pac_font_20 or pac_font_bold30. the pac fonts go up to 34")
local eventwheel_clickable = CreateConVar("pac_eventwheel_clickmode", "0", FCVAR_ARCHIVE, "The activation modes for pac3 event wheel.\n-1 : not clickable, but activate on menu close\n0 : clickable, and activate on menu close\n1 : clickable, but doesn't activate on menu close")
local eventlist_clickable = CreateConVar("pac_eventlist_clickmode", "0", FCVAR_ARCHIVE, "The activation modes for pac3 event wheel list alternative.\n-1 : not clickable, but activate a hovered event on menu close\n0 : clickable, and activate a hovered event on menu close\n1 : clickable, but doesn't do anything on menu close")

local event_list_font = CreateConVar("pac_eventlist_font", "DermaDefault", FCVAR_ARCHIVE, "The font for the eventwheel's rectangle list counterpart. It will also scale the rectangles' height.\nMight not work if the font is missing")


-- Custom event selector wheel
do

	local function get_events()
		pace.command_colors = pace.command_colors or {}
		local available = {}
		local names = {}
		local args = string.Split(eventwheel_visibility_rule:GetString(), " ")
		local uncolored_events = {}

		for k,v in pairs(pac.GetLocalParts()) do
			if v.ClassName == "event" then
				local e = v:GetEvent()
				if e == "command" then
					local cmd, time, hide = v:GetParsedArgumentsForObject(v.Events.command)
					local this_event_hidden = v:IsHiddenBySomethingElse(false)


					if not names[cmd] then
						--wheel_hidden is the hide_in_eventwheel box
						--possible_hidden is part hidden
						names[cmd] = {
							name = cmd, event = v,

							wheel_hidden = hide,
							all_wheel_hidden = hide,

							possible_hidden = this_event_hidden,
							all_possible_hidden = this_event_hidden,
						}
					else
						--if already exists, we need to check counter examples for whether all members are hidden or hide_in_eventwheel

						if not hide then
							names[cmd].all_wheel_hidden = false
						end

						if not this_event_hidden then
							names[cmd].all_possible_hidden = false
						end

						if not names[cmd].wheel_hidden and hide then
							names[cmd].wheel_hidden = true
						end

						if not names[cmd].possible_hidden and this_event_hidden then
							names[cmd].possible_hidden = true
						end


					end

					available[cmd] = {type = e, time = time, trigger = cmd}
				end
			end
		end
		for cmd,v in pairs(names) do
			uncolored_events[cmd] = not pace.command_colors[cmd]
			local remove = false

			if args[1] == "-1" then --skip
				remove = false
			elseif args[1] == "0" then --one hide_in_eventwheel
				if v.wheel_hidden then
					remove = true
				end
			elseif args[1] == "1" then --all hide_in_eventwheel
				if v.all_wheel_hidden then
					remove = true
				end
			elseif args[1] == "2" then --one hidden
				if v.possible_hidden then
					remove = true
				end
			elseif args[1] == "3" then --all hidden
				if v.all_possible_hidden then
					remove = true
				end
			elseif args[2] then
				if #args > 1 then --args contains many strings
					local match = false

					for i=2, #args, 1 do
						local str = args[i]
						if string.find(cmd, str) then
							match = true
						end
					end

					if args[1] == "4" and not match then
						remove = true
					elseif args[1] == "-4" and match then
						remove = true
					end

				else --why would you use the 4 or -4 mode if you didn't set keywords??
					remove = false
				end
			end

			if remove then
				available[cmd] = nil
			end
		end

		local list = {}


		local colors = {}

		for name,colstr in pairs(pace.command_colors) do
			colors[colstr] = colors[colstr] or {}
			colors[colstr][name] = available[name]
		end


		for col,tbl in pairs(colors) do

			local sublist = {}
			for k,v in pairs(tbl) do
				table.insert(sublist,available[k])
			end

			table.sort(sublist, function(a, b) return a.trigger < b.trigger end)

			for i,v in pairs(sublist) do
				table.insert(list,v)
			end
		end

		local uncolored_sublist = {}

		for k,v in pairs(available) do
			if uncolored_events[k] then
				table.insert(uncolored_sublist,available[k])
			end
		end

		table.sort(uncolored_sublist, function(a, b) return a.trigger < b.trigger end)

		for k,v in ipairs(uncolored_sublist) do
			table.insert(list, v)
		end

		--[[legacy behavior

			for k,v in pairs(available) do
				if k == names[k].name then
					v.trigger = k
					table.insert(list, v)
				end
			end

			table.sort(list, function(a, b) return a.trigger > b.trigger end)
		]]

		return list
	end

	local selectorBg = Material("sgm/playercircle")
	local selected
	local clicking = false
	local open_btn


	local clickable = eventwheel_clickable:GetInt() == 0 or eventwheel_clickable:GetInt() == 1
	local close_click = eventwheel_clickable:GetInt() == -1 or eventwheel_clickable:GetInt() == 0

	local clickable2 = eventlist_clickable:GetInt() == 0 or eventlist_clickable:GetInt() == 1
	local close_click2 = eventlist_clickable:GetInt() == -1 or eventlist_clickable:GetInt() == 0

	function pac.openEventSelectionWheel()
		if not IsValid(open_btn) then open_btn = vgui.Create("DButton") end
		open_btn:SetSize(80,30)
		open_btn:SetText("Customize")
		open_btn:SetPos(ScrW() - 80,0)

		function open_btn:DoClick()

			if (pace.command_event_menu_opened == nil) then
				pace.ConfigureEventWheelMenu()
			elseif IsValid(pace.command_event_menu_opened) then
				pace.command_event_menu_opened:Remove()
			end

		end

		if show_customize_button:GetBool() then
			open_btn:Show()
		else
			open_btn:Hide()
		end
		pace.command_colors = pace.command_colors or {}
		clickable = eventwheel_clickable:GetInt() == 0 or eventwheel_clickable:GetInt() == 1
		close_click = eventwheel_clickable:GetInt() == -1 or eventwheel_clickable:GetInt() == 0

		gui.EnableScreenClicker(true)

		local scrw, scrh = ScrW(), ScrH()
		local scrw2, scrh2 = scrw*0.5, scrh*0.5
		local color_red = Color(255,0,0)
		local R = 48

		local events = get_events()
		local nevents = #events

		-- Theta size of each wedge
		local thetadiff = math.pi*2 / nevents
		-- Used to compare the dot product
		local coslimit = math.cos(thetadiff * 0.5)
		-- Keeps the circles R units from each others' center
		local radius
		if nevents < 3 then
			radius = R
		else
			radius = R/math.cos((nevents - 2)*math.pi*0.5/nevents)
		end

		-- Scale down to keep from going out of the screen
		local gScale
		if radius+R > scrh2 then
			gScale = scrh2 / (radius+R)
		else
			gScale = 1
		end

		local selections = {}
		for k, v in ipairs(events) do
			local theta = (k-1)*thetadiff
			selections[k] = {
				grow = 0,
				name = v.trigger,
				event = v,
				x = math.sin(theta),
				y = -math.cos(theta),
			}
		end

		local function draw_circle(self, x, y)
			local dot = self.x*x + self.y*y
			local grow
			if dot > coslimit then
				selected = self
				grow = 0.1
			else
				grow = 0
			end
			self.grow = self.grow*0.9 + grow -- Framerate will affect this effect's speed but oh well

			local scale = gScale*(1 + self.grow*0.2)
			local m = Matrix()
			m:SetTranslation(Vector(scrw2, scrh2, 0))
			m:Scale(Vector(scale, scale, scale))
			cam.PushModelMatrix(m)

			local x, y = self.x*radius, self.y*radius


			local ply = pac.LocalPlayer
			local data = ply.pac_command_events and ply.pac_command_events[self.event.trigger] and ply.pac_command_events[self.event.trigger]


			local d1 = 64 --indicator


			local d2 = 50 --color
			local indicator_color
			if data then
				local is_oneshot = self.event.time and self.event.time > 0

				if is_oneshot then
					local f = (pac.RealTime - data.time) / self.event.time
					local s = Lerp(math.Clamp(f,0,1), 1, 0)
					local v = Lerp(math.Clamp(f,0,1), 0.55, 0.15)
					indicator_color = HSVToColor(210,s,v)

				else
					if data.on == 1 then
						indicator_color = HSVToColor(210,1,0.55)
					else
						indicator_color = HSVToColor(210,0,0.15)
					end
				end
			else
				indicator_color = HSVToColor(210,0,0.15)
			end

			if eventwheel_style:GetInt() == 0 then
				d2 = 96
				surface.SetDrawColor(indicator_color)
				surface.DrawTexturedRect(x-(d2/2), y-(d2/2), d2, d2)
			elseif eventwheel_style:GetInt() == 1 then
				if pace.command_colors[self.name] then
					local col_str_tbl = string.Split(pace.command_colors[self.name]," ")
					surface.SetDrawColor(tonumber(col_str_tbl[1]),tonumber(col_str_tbl[2]),tonumber(col_str_tbl[3]))
				else
					surface.SetDrawColor(HSVToColor(210,0,0.15))
				end

				d1 = 100 --color
				d2 = 50 --indicator

				surface.DrawTexturedRect(x-(d1/2), y-(d1/2), d1, d1)

				surface.SetDrawColor(indicator_color)
				surface.DrawTexturedRect(x-(d2/2), y-(d2/2), d2, d2)

				draw.RoundedBox(0,x-40,y-8,80,16,Color(0,0,0))

			elseif eventwheel_style:GetInt() == 2 then
				if pace.command_colors[self.name] then
					local col_str_tbl = string.Split(pace.command_colors[self.name]," ")
					surface.SetDrawColor(tonumber(col_str_tbl[1]),tonumber(col_str_tbl[2]),tonumber(col_str_tbl[3]))
				else
					surface.SetDrawColor(HSVToColor(210,0,0.15))
				end

				d1 = 96 --color
				d2 = 40 --indicator

				surface.DrawTexturedRect(x-(d1/2), y-(d1/2), d1, d1)
				surface.SetDrawColor(indicator_color)
				surface.DrawTexturedRect(x-1.2*d2, y-1.2*d2, d2, d2)
			end

			draw.SimpleText(self.name, eventwheel_font:GetString(), x, y, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

			cam.PopModelMatrix()
		end

		pac.AddHook("HUDPaint","custom_event_selector",function()
			-- Right clicking cancels
			if input.IsButtonDown(MOUSE_RIGHT) and not IsValid(pace.command_event_menu_opened) then pac.closeEventSelectionWheel(true) return end
			if input.IsButtonDown(MOUSE_LEFT) and not pace.command_event_menu_opened and not open_btn:IsHovered() and clickable then

				if not clicking and selected then
					if not selected.event.time then
						RunConsoleCommand("pac_event", selected.event.trigger, "toggle")
					elseif selected.event.time > 0 then
						RunConsoleCommand("pac_event", selected.event.trigger)
					else
						local ply = pac.LocalPlayer

						if ply.pac_command_events and ply.pac_command_events[selected.event.trigger] and ply.pac_command_events[selected.event.trigger].on == 1 then
							RunConsoleCommand("pac_event", selected.event.trigger, "0")
						else
							RunConsoleCommand("pac_event", selected.event.trigger, "1")
						end
					end
				end
				clicking = true
			else clicking = false end
			-- Normalize mouse vector from center of screen
			local x, y = input.GetCursorPos()
			x = x - scrw2
			y = y - scrh2
			if x==0 and y==0 then x = 1 y = 0 else
				local l = math.sqrt(x^2+y^2)
				x = x/l
				y = y/l
			end

			DisableClipping(true)
			render.PushFilterMag(TEXFILTER.ANISOTROPIC)
			render.PushFilterMin(TEXFILTER.ANISOTROPIC)

			surface.SetMaterial(selectorBg)

			draw.SimpleText("Right click to cancel", "DermaDefault", scrw2, scrh2+radius+R, color_red, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
			for _, v in ipairs(selections) do draw_circle(v, x, y) end

			render.PopFilterMag()
			render.PopFilterMin()
			DisableClipping(false)
		end)
		pace.event_wheel_opened = true
	end

	function pac.closeEventSelectionWheel(cancel)

		if IsValid(pace.command_event_menu_opened) then return end
		open_btn:Hide()
		gui.EnableScreenClicker(false)
		pac.RemoveHook("HUDPaint","custom_event_selector")

		if selected and cancel ~= true and close_click then
			if not selected.event.time then
				RunConsoleCommand("pac_event", selected.event.trigger, "toggle")
			elseif selected.event.time > 0 then
				RunConsoleCommand("pac_event", selected.event.trigger)
			else
				local ply = pac.LocalPlayer

				if ply.pac_command_events and ply.pac_command_events[selected.event.trigger] and ply.pac_command_events[selected.event.trigger].on == 1 then
					RunConsoleCommand("pac_event", selected.event.trigger, "0")
				else
					RunConsoleCommand("pac_event", selected.event.trigger, "1")
				end
			end
		end
		selected = nil
		pace.event_wheel_opened = false
	end

	local panels = {}
	function pac.openEventSelectionList()
		if not IsValid(open_btn) then open_btn = vgui.Create("DButton") end
		open_btn:SetSize(80,30)
		open_btn:SetText("Customize")
		open_btn:SetPos(ScrW() - 80,0)

		function open_btn:DoClick()

			if (pace.command_event_menu_opened == nil) then
				pace.ConfigureEventWheelMenu()
			elseif IsValid(pace.command_event_menu_opened) then
				pace.command_event_menu_opened:Remove()
			end

		end

		if show_customize_button:GetBool() then
			open_btn:Show()
		else
			open_btn:Hide()
		end
		pace.command_colors = pace.command_colors or {}
		clickable2 = eventlist_clickable:GetInt() == 0 or eventlist_clickable:GetInt() == 1
		close_click2 = eventlist_clickable:GetInt() == -1 or eventlist_clickable:GetInt() == 0

		local base_fontsize = tonumber(string.match(event_list_font:GetString(),"%d*$")) or 12
		local height = 2*base_fontsize + 8
		panels = panels or {}
		if not table.IsEmpty(panels) then
			for i, v in pairs(panels) do
				v:Remove()
			end
		end
		local selections = {}
		local events = get_events()
		for i, v in ipairs(events) do


			local list_element = vgui.Create("DPanel")

			panels[i] = list_element
			list_element:SetSize(250,height)
			list_element.event = v

			selections[i] = {
				grow = 0,
				name = v.trigger,
				event = v,
				pnl = list_element
			}
			function list_element:Paint() end
			function list_element:DoCommand()
				if not selected.event.time then
					RunConsoleCommand("pac_event", selected.event.trigger, "toggle")
				elseif selected.event.time > 0 then
					RunConsoleCommand("pac_event", selected.event.trigger)
				else
					local ply = pac.LocalPlayer

					if ply.pac_command_events and ply.pac_command_events[selected.event.trigger] and ply.pac_command_events[selected.event.trigger].on == 1 then
						RunConsoleCommand("pac_event", selected.event.trigger, "0")
					else
						RunConsoleCommand("pac_event", selected.event.trigger, "1")
					end
				end
			end
			function list_element:Think()
				if input.IsKeyDown(KEY_LCONTROL) and input.IsKeyDown(KEY_G) then
					self:Remove()
				end
				if self:IsHovered() then
					selected = self
					if input.IsMouseDown(MOUSE_LEFT) and not self.was_clicked and not IsValid(pace.command_event_menu_opened) and not open_btn:IsHovered() and clickable2 then
						self.was_clicked = true
						self:DoCommand()
					elseif not input.IsMouseDown(MOUSE_LEFT) then self.was_clicked = false end
				end
			end

		end

		gui.EnableScreenClicker(true)

		pac.AddHook("HUDPaint","custom_event_selector_list",function()
			local base_fontsize = tonumber(string.match(event_list_font:GetString(),"%d*$")) or 12
			local height = 2*base_fontsize + 8
			-- Right clicking cancels
			if input.IsButtonDown(MOUSE_RIGHT) and not IsValid(pace.command_event_menu_opened) then pac.closeEventSelectionList(true) return end

			DisableClipping(true)
			render.PushFilterMag(TEXFILTER.ANISOTROPIC)
			render.PushFilterMin(TEXFILTER.ANISOTROPIC)
			draw.SimpleText("Right click to cancel", "DermaDefault", ScrW()/2, ScrH()/2, color_red, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
			local x = 0
			local y = 0
			for i, v in ipairs(selections) do
				if IsValid(v.pnl) then

					if y + height > ScrH() then
						y = 0
						x = x + 200
					end
					local list_element = v.pnl
					list_element:SetPos(x,y)
					list_element:SetSize(250,height)

					local ply = pac.LocalPlayer
					local data = ply.pac_command_events and ply.pac_command_events[list_element.event.trigger]
					local indicator_color

					if data then
						local is_oneshot = list_element.event.time and list_element.event.time > 0

						if is_oneshot then
							local f = (pac.RealTime - data.time) / list_element.event.time
							local s = Lerp(math.Clamp(f,0,1), 1, 0)
							local v = Lerp(math.Clamp(f,0,1), 0.55, 0.15)

							indicator_color = HSVToColor(210,s,v)
						else
							if data.on == 1 then
								indicator_color = HSVToColor(210,1,0.55)
							else
								indicator_color = HSVToColor(210,0,0.15)
							end
						end
					else
						indicator_color = HSVToColor(210,0,0.15)
					end

					local main_color = HSVToColor(210,0,0.15)
					if pace.command_colors[v.name] then
						local col_str_tbl = string.Split(pace.command_colors[v.name]," ")
						main_color = Color(tonumber(col_str_tbl[1]),tonumber(col_str_tbl[2]),tonumber(col_str_tbl[3]))
					end

					local hue, sat, lightness_value = ColorToHSL(main_color)


					if eventlist_style:GetInt() == 0 then
						surface.SetDrawColor(indicator_color)
						surface.DrawRect(x,y,200,height)
						surface.SetDrawColor(0,0,0)
						surface.DrawOutlinedRect(x,y,200,height,2)
					elseif eventlist_style:GetInt() == 1 then
						if pace.command_colors[v.name] then
							local col_str_tbl = string.Split(pace.command_colors[v.name]," ")
							surface.SetDrawColor(tonumber(col_str_tbl[1]),tonumber(col_str_tbl[2]),tonumber(col_str_tbl[3]))
						else
							surface.SetDrawColor(HSVToColor(210,0,0.15))
						end
						surface.DrawRect(x,y,200,height)

						surface.SetDrawColor(indicator_color)
						surface.DrawRect(x + 200/6,y + height/6,200 * 0.666,height * 0.666,2)
						surface.SetDrawColor(0,0,0)
						surface.DrawOutlinedRect(x,y,200,height,2)

					elseif eventlist_style:GetInt() == 2 then
						surface.DrawOutlinedRect(x,y,200,height,2)
						if pace.command_colors[v.name] then
							local col_str_tbl = string.Split(pace.command_colors[v.name]," ")
							surface.SetDrawColor(tonumber(col_str_tbl[1]),tonumber(col_str_tbl[2]),tonumber(col_str_tbl[3]))
						else
							surface.SetDrawColor(HSVToColor(210,0,0.15))
						end
						surface.DrawRect(x,y,200,height)

						surface.SetDrawColor(indicator_color)
						surface.DrawRect(x + 150,y,50,height/2,2)
						surface.SetDrawColor(0,0,0)
						surface.DrawOutlinedRect(x + 150,y,50,height/2,2)
						surface.DrawOutlinedRect(x,y,200,height,2)
					end

					local text_color = Color(255,255,255)
					if lightness_value > 0.5 and eventlist_style:GetInt() ~= 0 then
						text_color = Color(0,0,0)
					end
					draw.SimpleText(v.name,event_list_font:GetString(),x + 4,y + 4, text_color, TEXT_ALIGN_LEFT)
					y = y + height

				end

			end

			render.PopFilterMag()
			render.PopFilterMin()
			DisableClipping(false)

		end)

		pace.event_wheel_list_opened = true
	end

	function pac.closeEventSelectionList(cancel)
		if IsValid(pace.command_event_menu_opened) then return end
		open_btn:Hide()
		gui.EnableScreenClicker(false)
		pac.RemoveHook("HUDPaint","custom_event_selector_list")

		if IsValid(selected) and close_click2 and cancel ~= true then
			if selected:IsHovered() then
				selected:DoCommand()
			end
		end
		for i,v  in pairs(panels) do v:Remove() end
		selected = nil
		pace.event_wheel_list_opened = false
	end


	concommand.Add("+pac_events", pac.openEventSelectionWheel)
	concommand.Add("-pac_events", pac.closeEventSelectionWheel)

	concommand.Add("+pac_events_list", pac.openEventSelectionList)
	concommand.Add("-pac_events_list", pac.closeEventSelectionList)

end


net.Receive("pac_update_healthbars", function()
	local ent = net.ReadEntity()
	local tbl = net.ReadTable()

	if not IsValid(ent) then return end

	ent.pac_healthbars = tbl

	ent.pac_healthbars_layertotals = ent.pac_healthbars_layertotals or {}
	ent.pac_healthbars_uidtotals = ent.pac_healthbars_uidtotals or {}
	ent.pac_healthbars_total = 0

	for layer=15,0,-1 do --go progressively inward in the layers
		ent.pac_healthbars_layertotals[layer] = 0
		if tbl[layer] then
			for uid,value in pairs(tbl[layer]) do --check the healthbars by uid
				ent.pac_healthbars_uidtotals[uid] = value
				ent.pac_healthbars_layertotals[layer] = ent.pac_healthbars_layertotals[layer] + value
				ent.pac_healthbars_total = ent.pac_healthbars_total + value
				local part = pac.GetPartFromUniqueID(pac.Hash(ent), uid)
				if IsValid(part) and part.UpdateHPBars then part:UpdateHPBars() end
			end
		else
			ent.pac_healthbars_layertotals[layer] = nil
		end
	end

end)
