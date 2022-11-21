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
	BUILDER:GetSet("Arguments", "", {hidden = true})
	BUILDER:GetSet("Invert", true)
	BUILDER:GetSet("RootOwner", true)
	BUILDER:GetSet("AffectChildrenOnly", false)
	BUILDER:GetSet("ZeroEyePitch", false)
	BUILDER:GetSetPart("TargetPart")
BUILDER:EndStorableVars()

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

function PART:GetDynamicProperties()
	local data = self.Events[self.Event]
	if not data then return end
	self:SetWarning()

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

PART.Events = {}
PART.OldEvents = {
	random = {
		arguments = {{compare = "number"}},
		callback = function(self, ent, compare)
			return self:NumberOperator(math.random(), compare)
		end,
	},

	randint = {
		arguments = {{compare = "number"}, {min = "number"}, {max = "number"}},
		callback = function(self, ent, compare, min, max)
			min = min or 0
			max = max or 1
			if min > max then return 0 end
			return self:NumberOperator(math.random(min,max), compare)
		end,
	},

	random_timer = {
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
		arguments = {{seconds = "number"}, {reset_on_hide = "boolean"}, {synced_time = "boolean"}},
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
		arguments = {{find = "string"}},
		callback = function(self, ent, find)
			return self:StringOperator(game.GetMap(), find)
		end,
	},

	fov = {
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
		arguments = {{find = "string"}},
		callback = function(self, ent, find)
			ent = try_viewmodel(ent)
			local wep = ent.GetActiveWeapon and ent:GetActiveWeapon() or NULL
			if wep:IsValid() and self:StringOperator(wep:GetHoldType(), find) then
				return true
			end
		end,
	},

	is_crouching = {
		callback = function(self, ent)
			ent = try_viewmodel(ent)
			return ent.Crouching and ent:Crouching()
		end,
	},

	is_typing = {
		callback = function(self, ent)
			ent = self:GetPlayerOwner()
			return ent.IsTyping and ent:IsTyping()
		end,
	},

	using_physgun = {
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
		arguments = {{class = "string"}},
		callback = function(self, ent, find)
			if ent.GetEyeTrace then
				ent = ent:GetEyeTrace().Entity
				if self:StringOperator(ent:GetClass(), find) then
					return true
				end
			end
		end,
	},

	owner_health = {
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
		callback = function(self, ent)
			ent = try_viewmodel(ent)
			if ent.Alive then
				return ent:Alive()
			end
			return 0
		end,
	},
	owner_armor = {
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
		arguments = {{scale = "number"}},
		callback = function(self, ent, num)
			ent = try_viewmodel(ent)

				return self:NumberOperator(ent.pac_model_scale and ent.pac_model_scale.x or (ent.GetModelScale and ent:GetModelScale()) or 1, num)
		end,
	},
	owner_scale_y = {
		arguments = {{scale = "number"}},
		callback = function(self, ent, num)
			ent = try_viewmodel(ent)

				return self:NumberOperator(ent.pac_model_scale and ent.pac_model_scale.y or (ent.GetModelScale and ent:GetModelScale()) or 1, num)
		end,
	},
	owner_scale_z = {
		arguments = {{scale = "number"}},
		callback = function(self, ent, num)
			ent = try_viewmodel(ent)

				return self:NumberOperator(ent.pac_model_scale and ent.pac_model_scale.z or (ent.GetModelScale and ent:GetModelScale()) or 1, num)
		end,
	},

	pose_parameter = {
		arguments = {{name = "string"}, {num = "number"}},
		callback = function(self, ent, name, num)
			ent = try_viewmodel(ent)
			return self:NumberOperator(ent:GetPoseParameter(name), num)
		end,
	},

	speed = {
		arguments = {{speed = "number"}},
		callback = function(self, ent, num)
			ent = try_viewmodel(ent)
			return self:NumberOperator(ent:GetVelocity():Length(), num)
		end,
	},

	is_under_water = {
		arguments = {{level = "number"}},
		callback = function(self, ent, num)
			ent = try_viewmodel(ent)
			return self:NumberOperator(ent:WaterLevel(), num)
		end,
	},

	is_on_fire = {
		callback = function(self, ent)
			ent = try_viewmodel(ent)
			return ent:IsOnFire()
		end,
	},

	client_spawned = {
		arguments = {{time = "number"}},
		callback = function(self, ent, time)
			time = time or 0.1
			ent = try_viewmodel(ent)
			if ent.pac_playerspawn and ent.pac_playerspawn + time > pac.RealTime then
				return true
			end
		end,
	},

	is_client = {
		callback = function(self, ent)
			ent = try_viewmodel(ent)
			return self:GetPlayerOwner() == ent
		end,
	},

	is_flashlight_on = {
		callback = function(self, ent)
			ent = try_viewmodel(ent)
			return ent.FlashlightIsOn and ent:FlashlightIsOn()
		end,
	},

	collide = {
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
		arguments = {{distance = "number"}, {compare = "number"}, {npcs_and_players_only = "boolean"}},
		userdata = {{editor_panel = "ranger", ranger_property = "distance"}, {editor_panel = "ranger", ranger_property = "compare"}},
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

	is_touching = {
		arguments = {{extra_radius = "number"}},
		userdata = {{editor_panel = "is_touching", is_touching_property = "extra_radius"}},
		callback = function(self, ent, extra_radius)
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
				filter = ent
			} )
			return tr.Hit
		end,
	},

	is_in_noclip = {
		callback = function(self, ent)
			ent = try_viewmodel(ent)
			return ent:GetMoveType() == MOVETYPE_NOCLIP and (not ent.GetVehicle or not ent:GetVehicle():IsValid())
		end,
	},

	is_voice_chatting = {
		callback = function(self, ent)
			ent = try_viewmodel(ent)
			return ent.IsSpeaking and ent:IsSpeaking()
		end,
	},

	ammo = {
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
		arguments = {{find = "string"}},
		callback = function(self, ent, find)
			ent = ent.GetDriver and ent:GetDriver() or NULL

			if ent:IsValid() then
				return self:StringOperator(ent:GetName(), find)
			end
		end,
	},

	entity_class = {
		arguments = {{find = "string"}},
		callback = function(self, ent, find)
			return self:StringOperator(ent:GetClass(), find)
		end,
	},

	weapon_class = {
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
		arguments = {{find = "string"}},
		callback = function(self, ent, find)
			return self:StringOperator(ent:GetModel(), find)
		end,
	},

	sequence_name = {
		arguments = {{find = "string"}},
		nice = function(self, ent)
			return self.sequence_name or "invalid sequence"
		end,
		callback = function(self, ent, find)
			ent = get_owner(self)

			self.sequence_name = ent:GetSequenceName(ent:GetSequence())

			return self:StringOperator(self.sequence_name, find)
		end,
	},

	timer = {
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
		arguments = {{find = "string"}, {time = "number"}},
		nice = function(self)
			return self.anim_name or ""
		end,
		callback = function(self, ent, find, time)
			time = time or 0.1

			ent = get_owner(self)

			local data = ent.pac_anim_event
			local b = false

			if data and (self:StringOperator(data.name, find) and (time == 0 or data.time + time > pac.RealTime)) then
				data.reset = false
				b = true
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
		arguments = {{find_ammo = "string"}, {time = "number"}},
		callback = function(self, ent, find, time)
			time = time or 0.1

			ent = try_viewmodel(ent)

			local data = ent.pac_fire_bullets
			local b = false

			if data and (self:StringOperator(data.name, find) and (time == 0 or data.time + time > pac.RealTime)) then
				data.reset = false
				b = true
			end

			return b
		end,
	},

	emit_sound = {
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
		arguments = {{find = "string"}, {time = "number"}, {hide_in_eventwheel = "boolean"}},
		callback = function(self, ent, find, time)
			time = time or 0.1

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

	movetype = {
		arguments = {{find = "string"}},
		callback = function(self, ent, find)
			local mt = ent:GetMoveType()
			if movetypes[mt] then
				return self:StringOperator(movetypes[mt], find)
			end
		end,
	},

	dot_forward = {
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
}

do
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

	--TODO: Rate limit!!!
	net.Receive("pac.BroadcastPlayerButton", function()
		local ply = net.ReadEntity()

		if not ply:IsValid() then return end

		if ply == pac.LocalPlayer and (pace and pace.IsFocused() or gui.IsConsoleVisible()) then return end

		local key = net.ReadUInt(8)
		local down = net.ReadBool()

		key = pac.key_enums[key] or key

		ply.pac_buttons = ply.pac_buttons or {}
		ply.pac_buttons[key] = down
	end)

	PART.OldEvents.button = {
		arguments = {{button = "string"}},
		userdata = {{enums = function()
			return enums
		end}},
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
		callback = function(self, ent, button)
			local ply = self:GetPlayerOwner()

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
			end

			local buttons = ply.pac_buttons

			if buttons then
				return buttons[button]
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
		name = "custom_animation_frame",
		nice = function(self, ent, animation)
			if animation == "" then self:SetWarning("no animation selected") return "no animation" end
			local part = pac.GetLocalPart(animation)
			if not IsValid(part) then self:SetError("invalid animation selected") return "invalid animation" end
			self:SetWarning()
			return part:GetName()
		end,
		args = {
			{"animation", "string", {
				enums = function(part)
					local output = {}
					local parts = pac.GetLocalParts()

					for i, part in pairs(parts) do
						if part.ClassName == "custom_animation" then
							output[i] = part
						end
					end

					return output
				end
			}},
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

function PART:OnThink()
	local ent = get_owner(self)
	if not ent:IsValid() then return end

	local data = PART.Events[self.Event]
	if not data then return end

	self:TriggerEvent(should_trigger(self, ent, data))

	if pace and pace.IsActive() and self.Name == "" then
		if self.pace_properties and self.pace_properties["Name"] and self.pace_properties["Name"]:IsValid() then
			self.pace_properties["Name"]:SetText(self:GetNiceName())
		end
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


-- Custom event selector wheel
do
	local function get_events()
		local available = {}

		for k,v in pairs(pac.GetLocalParts()) do
			if v.ClassName == "event" then
				local e = v:GetEvent()
				if e == "command" then
					local cmd, time, hide = v:GetParsedArgumentsForObject(v.Events.command)
					if hide then continue end

					available[cmd] = {type = e, time = time}
				end
			end
		end

		local list = {}
		for k,v in pairs(available) do
			v.trigger = k
			table.insert(list, v)
		end

		table.sort(list, function(a, b) return a.trigger > b.trigger end)

		return list
	end

	local selectorBg = Material("sgm/playercircle")
	local selected

	function pac.openEventSelectionWheel()
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
			if data then
				local is_oneshot = self.event.time and self.event.time > 0

				if is_oneshot then
					local f = (pac.RealTime - data.time) / self.event.time
					local s = Lerp(math.Clamp(f,0,1), 1, 0)
					local v = Lerp(math.Clamp(f,0,1), 0.55, 0.15)
					surface.SetDrawColor(HSVToColor(210,s,v))
				else
					if data.on == 1 then
						surface.SetDrawColor(HSVToColor(210,1,0.55))
					else
						surface.SetDrawColor(HSVToColor(210,0,0.15))
					end
				end
			else
				surface.SetDrawColor(HSVToColor(210,0,0.15))
			end

			surface.DrawTexturedRect(x-48, y-48, 96, 96)
			draw.SimpleText(self.name, "DermaDefault", x, y, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

			cam.PopModelMatrix()
		end

		pac.AddHook("HUDPaint","custom_event_selector",function()
			-- Right clicking cancels
			if input.IsButtonDown(MOUSE_RIGHT) then pac.closeEventSelectionWheel(true) return end

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
	end

	function pac.closeEventSelectionWheel(cancel)
		gui.EnableScreenClicker(false)
		pac.RemoveHook("HUDPaint","custom_event_selector")

		if selected and cancel ~= true then
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
	end

	concommand.Add("+pac_events", pac.openEventSelectionWheel)
	concommand.Add("-pac_events", pac.closeEventSelectionWheel)
end
