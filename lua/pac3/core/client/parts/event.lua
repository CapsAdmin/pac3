local LocalPlayer = LocalPlayer
local FrameTime = FrameTime

local PART = {}

PART.ClassName = "event"
PART.NonPhysical = true
PART.ThinkTime = 0
PART.AlwaysThink = true

pac.StartStorableVars()
	pac.GetSet(PART, "Event", "")
	pac.GetSet(PART, "Operator", "find simple")
	pac.GetSet(PART, "Arguments", "")
	pac.GetSet(PART, "Invert", false)
	pac.GetSet(PART, "RootOwner", true)
	pac.GetSet(PART, "AffectChildrenOnly", false)
	pac.SetupPartName(PART, "TargetPart")
pac.EndStorableVars()

local function calc_velocity(part)
	local diff = part.cached_pos - (part.last_pos or Vector(0, 0, 0))
	part.last_pos = part.cached_pos

	part.last_vel_smooth = part.last_vel_smooth or Vector(0, 0, 0)
	part.last_vel_smooth = part.last_vel_smooth + (diff - part.last_vel_smooth) * FrameTime() * 4

	return part.last_vel_smooth
end

local function try_viewmodel(ent)
	return ent == pac.LocalPlayer:GetViewModel() and pac.LocalPlayer or ent
end

local movetypes = {}

for k,v in pairs(_G) do
	if type(k) == "string" and type(v) == "number" and k:sub(0,9) == "MOVETYPE_" then
		movetypes[v] = k:sub(10):lower()
	end
end

PART.Events = {}
PART.OldEvents =
{
	random =
	{
		arguments = {{compare = "number"}},
		callback = function(self, ent, compare)
			return self:NumberOperator(math.random(), compare)
		end,
	},
	randint =
	{
		arguments = {{compare = "number"}, {min = "number"}, {max = "number"}},
		callback = function(self, ent, compare, min, max)
			min = min or 0
			max = max or 1
			if min > max then return 0 end
			return self:NumberOperator(math.random(min,max), compare)
		end,
	},
	random_timer =
	{
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
	timerx =
	{
		arguments = {{seconds = "number"}, {reset_on_hide = "boolean"}, {synced_time = "boolean"}},

		callback = function(self, ent, seconds, reset_on_hide, synced_time)
			local time = synced_time and CurTime() or RealTime()

			self.time = self.time or time
			self.timerx_reset = reset_on_hide

			return self:NumberOperator(time - self.time, seconds)
		end,
	},
	map_name =
	{
		arguments = {{find = "string"}},
		callback = function(self, ent, find)
			return self:StringOperator(game.GetMap(), find)
		end,
	},

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

				local dmg = self.pac_lastdamage or 0

				if self.dmgCD == nil then
					self.dmgCD = 0
				end


				if not self.pac_wasdmg then

					local dmgDone = dmg - ent:Health()
					self.pac_lastdamage = ent:Health()

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

	holdtype =
	{
		arguments = {{find = "string"}},
		callback = function(self, ent, find)
			ent = try_viewmodel(ent)
			local wep = ent.GetActiveWeapon and ent:GetActiveWeapon() or NULL
			if wep:IsValid() and self:StringOperator(wep:GetHoldType(), find) then
				return true
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

	is_typing =
	{
		callback = function(self, ent)
			ent = self:GetPlayerOwner()
			return ent.IsTyping and ent:IsTyping()
		end,
	},

	eyetrace_entity_class =
	{
		arguments = {{class = "string"}},
		callback = function(self, ent, find)
			if ent.GetEyeTrace then
				ent = ent:GetEyeTrace().Entity
				if ent:IsValid() and self:StringOperator(ent:GetClass(), find) then
					return true
				end
			end
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
	owner_max_health =
	{
		arguments = {{health = "number"}},
		callback = function(self, ent, num)
			ent = try_viewmodel(ent)
			if ent:IsValid() and ent.GetMaxHealth then
				return self:NumberOperator(ent:GetMaxHealth(), num)
			end

			return 0
		end,
	},
	owner_alive =
	{
		callback = function(self, ent)
			ent = try_viewmodel(ent)
			if ent:IsValid() and ent.Alive then
				return ent:Alive()
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

	owner_scale_x =
	{
		arguments = {{scale = "number"}},
		callback = function(self, ent, num)
			ent = try_viewmodel(ent)

			if ent:IsValid() then
				return self:NumberOperator(ent.pac_model_scale and ent.pac_model_scale.x or (ent.GetModelScale and ent:GetModelScale()) or 1, num)
			end

			return 1
		end,
	},
	owner_scale_y =
	{
		arguments = {{scale = "number"}},
		callback = function(self, ent, num)
			ent = try_viewmodel(ent)

			if ent:IsValid() then
				return self:NumberOperator(ent.pac_model_scale and ent.pac_model_scale.y or (ent.GetModelScale and ent:GetModelScale()) or 1, num)
			end

			return 1
		end,
	},
	owner_scale_z =
	{
		arguments = {{scale = "number"}},
		callback = function(self, ent, num)
			ent = try_viewmodel(ent)

			if ent:IsValid() then
				return self:NumberOperator(ent.pac_model_scale and ent.pac_model_scale.z or (ent.GetModelScale and ent:GetModelScale()) or 1, num)
			end

			return 1
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
		arguments = {{level = "number"}},
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

	ranger =
	{
		arguments = {{compare = "number"}, {distance = "number"}},
		callback = function(self, ent, compare, distance)
			local parent = self:GetParentEx()

			if parent:IsValid() then
				distance = distance or 1
				compare = compare or 0

				local res = util.TraceLine({
					start = parent.cached_pos,
					endpos = parent.cached_pos + parent.cached_ang:Forward() * distance,
					filter = ent,
				})

				return self:NumberOperator(res.Fraction * distance, compare)
			end
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
			ent = ent.GetActiveWeapon and ent:GetActiveWeapon() or ent

			if ent:IsValid() then
				return self:NumberOperator(ent.Clip1 and (primary and ent:Clip1() or ent:Clip2()) or 0, amount)
			end
		end,
	},
	total_ammo =
	{
		arguments = {{ammo_id = "string"}, {amount = "number"}},
		callback = function(self, ent, ammo_id, amount)
			ent = try_viewmodel(ent)

			ammo_id = tonumber(ammo_id) or ammo_id:lower()

			if ent:IsValid() and ent.GetAmmoCount then
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
	clipsize =
	{
		arguments = {{primary = "boolean"}, {amount = "number"}},
		callback = function(self, ent, primary, amount)
			ent = try_viewmodel(ent)
			ent = ent.GetActiveWeapon and ent:GetActiveWeapon() or ent

			if ent:IsValid() then
				return self:NumberOperator(ent.GetMaxClip1 and (primary and ent:GetMaxClip1() or ent:GetMaxClip2()) or 0, amount)
			end
		end,
	},

	vehicle_class =
	{
		arguments = {{find = "string"}},
		callback = function(self, ent, find)
			ent = try_viewmodel(ent)
			ent = ent.GetVehicle and ent:GetVehicle() or NULL

			if ent:IsValid() then
				return self:StringOperator(ent:GetClass(), find)
			end
		end,
	},

	vehicle_model =
	{
		arguments = {{find = "string"}},
		callback = function(self, ent, find)
			ent = try_viewmodel(ent)
			ent = ent.GetVehicle and ent:GetVehicle() or NULL

			if ent:IsValid() and ent:GetModel() then
				return self:StringOperator(ent:GetModel():lower(), find)
			end
		end,
	},

	driver_name =
	{
		arguments = {{find = "string"}},
		callback = function(self, ent, find)
			ent = ent.GetDriver and ent:GetDriver() or NULL

			if ent:IsValid() then
				return self:StringOperator(ent:GetName(), find)
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
				local class_name = wep:GetClass()
				local found = self:StringOperator(class_name, find)

				if class_name == "hands" and not found then
					found = self:StringOperator("none", find)
				end

				if found then
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
				for _, val in pairs(tbl) do
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

			if interval == 0 or interval < FrameTime() then
				self.timer_hack = not self.timer_hack
				return self.timer_hack
			end

			return (CurTime() + offset) % interval > (interval / 2)
		end,
	},

	animation_event =
	{
		arguments = {{find = "string"}, {time = "number"}},
		callback = function(self, ent, find, time)
			time = time or 0.1

			ent = try_viewmodel(ent)

			local data = ent.pac_anim_event
			local b = false

			if data and (self:StringOperator(data.name, find) and (time == 0 or data.time + time > pac.RealTime)) then
				data.reset = false
				b = true
			end

			return b
		end,
	},

	fire_bullets =
	{
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

	emit_sound =
	{
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

	command =
	{
		arguments = {{find = "string"}, {time = "number"}},
		callback = function(self, ent, find, time)
			time = time or 0.1

			local ply = self:GetPlayerOwner()

			local events = ply.pac_command_events

			if events then
				for _, data in pairs(events) do
					if self:StringOperator(data.name, find) then
						if data.on > 0 then
							return data.on == 1
						end

						if data.time + time > pac.RealTime then
							return true
						end
					end
				end
			end
		end,
	},

	say =
	{
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
				local owner = self:GetOwner(true)
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
	owner_velocity_length =
	{
		arguments = {{speed = "number"}},
		callback = function(self, ent, speed)
			local owner = self:GetOwner(self.RootOwner)
			local parent = self:GetParentEx()

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

			owner = try_viewmodel(owner)

			if owner:IsValid() then
				return self:NumberOperator(owner:EyeAngles():Forward():Dot(owner:GetVelocity()), speed)
			end

			return 0
		end,
	},
	owner_velocity_right =
	{
		arguments = {{speed = "number"}},
		callback = function(self, ent, speed)
			local owner = self:GetOwner(self.RootOwner)

			owner = try_viewmodel(owner)

			if owner:IsValid() then
				return self:NumberOperator(owner:EyeAngles():Right():Dot(owner:GetVelocity()), speed)
			end

			return 0
		end,
	},
	owner_velocity_up =
	{
		arguments = {{speed = "number"}},
		callback = function(self, ent, speed)
			local owner = self:GetOwner(self.RootOwner)

			owner = try_viewmodel(owner)

			if owner:IsValid() then
				return self:NumberOperator(owner:EyeAngles():Up():Dot(owner:GetVelocity()), speed)
			end

			return 0
		end,
	},

	-- parent part
	parent_velocity_length =
	{
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
	parent_velocity_forward =
	{
		arguments = {{speed = "number"}},
		callback = function(self, ent, speed)
			local parent = self:GetParentEx()

			if not self.TargetPart:IsValid() and parent:HasParent() then
				parent = parent:GetParent()
			end

			if parent:IsValid() then
				return self:NumberOperator(parent.cached_ang:Forward():Dot(calc_velocity(parent)), speed)
			end

			return 0
		end,
	},
	parent_velocity_right =
	{
		arguments = {{speed = "number"}},
		callback = function(self, ent, speed)
			local parent = self:GetParentEx()

			if not self.TargetPart:IsValid() and parent:HasParent() then
				parent = parent:GetParent()
			end

			if parent:IsValid() then
				return self:NumberOperator(parent.cached_ang:Right():Dot(calc_velocity(parent)), speed)
			end

			return 0
		end,
	},
	parent_velocity_up =
	{
		arguments = {{speed = "number"}},
		callback = function(self, ent, speed)
			local parent = self:GetParentEx()

			if not self.TargetPart:IsValid() and  parent:HasParent() then
				parent = parent:GetParent()
			end

			if parent:IsValid() then
				return self:NumberOperator(parent.cached_ang:Up():Dot(calc_velocity(parent)), speed)
			end

			return 0
		end,
	},

	parent_scale_x =
	{
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
	parent_scale_y =
	{
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
	parent_scale_z =
	{
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

	movetype =
	{
		arguments = {{find = "string"}},
		callback = function(self, ent, find)
			local mt = ent:GetMoveType()
			if movetypes[mt] then
				return self:StringOperator(movetypes[mt], find)
			end
		end,
	},

	dot_forward =
	{
		arguments = {{normal = "number"}},
		callback = function(self, ent, normal)

			local owner = self:GetOwner(true)

			if owner:IsValid() then
				local ang = owner:EyeAngles()
				ang.p = 0
				return self:NumberOperator(pac.EyeAng:Forward():Dot(ang:Forward()), normal)
			end

			return 0
		end,
	},

	dot_right =
	{
		arguments = {{normal = "number"}},
		callback = function(self, ent, normal)

			local owner = self:GetOwner(true)

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
		if type(key) == "string" and type(val) == "number" then
			if key:sub(0,4) == "KEY_" and not key:find("_LAST$") and not key:find("_FIRST$")  and not key:find("_COUNT$")  then
				enums[val] = key:sub(5):lower()
				enums2[enums[val]] = val
			elseif (key:sub(0,6) == "MOUSE_" or key:sub(0,9) == "JOYSTICK_") and not key:find("_LAST$") and not key:find("_FIRST$")  and not key:find("_COUNT$")  then
				--if enums[val] then
					--print("conflict",val,key,'-',enums[val])
				--else
					enums[val] = key:lower()
					enums2[enums[val]] = val
				--end
			end
		end
	end

	pac.key_enums = enums

	--TODO: Rate limit!!!
	net.Receive("pac.net.BroadcastPlayerButton", function()
		local ply = net.ReadEntity()

		if ply:IsValid() then
			local key = net.ReadUInt(8)
			local down = net.ReadBool()

			key = pac.key_enums[key] or key

			ply.pac_buttons = ply.pac_buttons or {}
			ply.pac_buttons[key] = down
		end
	end)

	PART.OldEvents.button =
	{
		arguments = {{button = "string"}},
		callback = function(self, ent, button)
			local ply = self:GetPlayerOwner()

			if ply == pac.LocalPlayer then
				ply.pac_broadcast_buttons = ply.pac_broadcast_buttons or {}
				if not ply.pac_broadcast_buttons[button] then
					local val = enums2[button:lower()]
					if val then
						net.Start("pac.net.AllowPlayerButtons")
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

	function eventMeta:IsAvaliable(eventPart)
		return true
	end

	function eventMeta:GetArguments()
		self.__registeredArguments = self.__registeredArguments or {}
		return self.__registeredArguments
	end

	function eventMeta:GetArgumentsForParse()
		return self.__registeredArgumentsParse
	end

	function eventMeta:AppendArgument(keyName, keyType)
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
		table.insert(self.__registeredArguments, {keyName, keyType})
		table.insert(self.__registeredArgumentsParse, {[keyName] = keyType})
	end

	function eventMeta:PopArgument(keyName)
		for i, data in ipairs(self.__registeredArguments) do
			if data[1] == keyName then
				return true, i, table.remove(self.__registeredArguments, i), table.remove(self.__registeredArgumentsParse, i)
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
				if type(v) ~= 'table' then
					newObj[k] = v
				else
					newObj[k] = table.Copy(v)
				end
			end

			return newObj
		end,

		-- __newindex = function(self, key, val)
		-- 	rawset(self, key, val)
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
		newObj.__registeredArgumentsParse = {}
		newObj:SetName(nClassName)

		if defArguments then
			for i, data in pairs(defArguments) do
				newObj:AppendArgument(data[1], data[2])
			end
		end

		return newObj
	end

	function pac.RegisterEvent(nRegister)
		local classname = nRegister:GetClass()
		
		if PART.Events[classname] then
			print('[PAC3] WARN: Registering event with already existing classname!: '.. classname)
		end

		PART.Events[classname] = nRegister
	end

	for classname, data in pairs(PART.OldEvents) do
		local arguments = data.arguments
		local think = data.callback
		local eventObject = pac.CreateEvent(classname)

		if arguments then
			for i, data2 in ipairs(arguments) do
				for key, Type in pairs(data2) do
					eventObject:AppendArgument(key, Type)
				end
			end
		end

		function eventObject:Think(event, ent, ...)
			return think(event, ent, ...)
		end

		pac.RegisterEvent(eventObject)
	end

	timer.Simple(0, function() -- After all addons has loaded
		hook.Call('PAC3RegisterEvents', nil, pac.CreateEvent, pac.RegisterEvent)
	end)
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
			avaliable = function() return plyMeta.isArrested ~= nil end,
			func = function(self, eventPart, ent)
				ent = try_viewmodel(ent)
				return ent.isArrested and ent:isArrested() or false
			end
		},

		{
			name = 'is_wanted',
			args = {},
			avaliable = function() return plyMeta.isWanted ~= nil end,
			func = function(self, eventPart, ent)
				ent = try_viewmodel(ent)
				return ent.isWanted and ent:isWanted() or false
			end
		},

		{
			name = 'is_police',
			args = {},
			avaliable = function() return plyMeta.isCP ~= nil end,
			func = function(self, eventPart, ent)
				ent = try_viewmodel(ent)
				return ent.isCP and ent:isCP() or false
			end
		},

		{
			name = 'wanted_reason',
			args = {{'find', 'string'}},
			avaliable = function() return plyMeta.getWantedReason ~= nil and plyMeta.isWanted ~= nil end,
			func = function(self, eventPart, ent, find)
				ent = try_viewmodel(ent)
				return eventPart:StringOperator(ent.isWanted and ent.getWantedReason and ent:isWanted() and ent:getWantedReason() or '', find)
			end
		},

		{
			name = 'is_cook',
			args = {},
			avaliable = function() return plyMeta.isCook ~= nil end,
			func = function(self, eventPart, ent)
				ent = try_viewmodel(ent)
				return ent.isCook and ent:isCook() or false
			end
		},

		{
			name = 'is_hitman',
			args = {},
			avaliable = function() return plyMeta.isHitman ~= nil end,
			func = function(self, eventPart, ent)
				ent = try_viewmodel(ent)
				return ent.isHitman and ent:isHitman() or false
			end
		},

		{
			name = 'has_hit',
			args = {},
			avaliable = function() return plyMeta.hasHit ~= nil end,
			func = function(self, eventPart, ent)
				ent = try_viewmodel(ent)
				return ent.hasHit and ent:hasHit() or false
			end
		},

		{
			name = 'hit_price',
			args = {{'amount', 'number'}},
			avaliable = function() return plyMeta.getHitPrice ~= nil end,
			func = function(self, eventPart, ent, amount)
				ent = try_viewmodel(ent)
				return eventPart:NumberOperator(ent.getHitPrice and ent:getHitPrice() or 0, amount)
			end
		},
	}

	for k, v in ipairs(events) do
		local avaliable = v.avaliable
		local eventObject = pac.CreateEvent(v.name, v.args)
		eventObject.Think = v.func

		function eventObject:IsAvaliable()
			return isDarkRP() and avaliable()
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
	local str = self:GetEvent()

	if self:GetArguments() ~= "" then
		local args = self:GetArguments():gsub(";", " or ")

		if not tonumber(args) then
			args = [["]] .. args .. [["]]
		end
		str = str .. " " .. self:GetOperator() .. args
	end

	return pac.PrettifyName(str)
end

function PART:OnRemove()
	if self.AffectChildrenOnly then
		for _, child in ipairs(self:GetChildren()) do
			child:SetEventHide(false)
		end
	else
		local parent = self:GetParent()

		if parent:IsValid() then
			parent:SetEventHide(false)
		end
	end
end

local function should_hide(self, ent, eventObject)
	if not eventObject:IsAvaliable(self) then
		return true
	end

	local b = false

	if self.hidden or self.event_hidden then
		b = self.Invert
	else
		if eventObject.ParseArguments then
			b = eventObject:Think(self, ent, eventObject:ParseArguments(self)) or false
		else
			b = eventObject:Think(self, ent, self:GetParsedArgumentsForObject(eventObject)) or false
		end

		if self.Invert then
			b = not b
		end
	end

	return b
end

function PART:OnThink()
	local ent = self:GetOwner(self.RootOwner)

	if ent:IsValid() then
		local data = self.Events[self.Event]

		if data then

			if self.AffectChildrenOnly then
				local b = should_hide(self, ent, data)

				for _, child in ipairs(self:GetChildren()) do
					child:SetEventHide(b)
				end

				-- this is just used for the editor..
				self.event_triggered = b

				if self.last_event_triggered ~= self.event_triggered then
					if not self.suppress_event_think then
						self.suppress_event_think = true
						self:CallRecursive("CalcShowHide")
						self.suppress_event_think = nil
					end
					self.last_event_triggered = self.event_triggered
				end
			else
				local parent = self:GetParent()

				if parent:IsValid() then
					local b = should_hide(self, ent, data)

					parent:SetEventHide(b)

					-- this is just used for the editor..
					self.event_triggered = b

					if self.last_event_triggered ~= self.event_triggered then
						if not self.suppress_event_think then
							self.suppress_event_think = true
							parent:CallRecursive("CalcShowHide")
							self.suppress_event_think = nil
						end
						self.last_event_triggered = self.event_triggered
					end
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
		local typ = select(2, next(arg))
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
		if not args[i] then
			break
		elseif typ == "boolean" then
			args[i] = tonumber(args[i]) ~= 0
		elseif typ == "number" then
			args[i] = tonumber(args[i]) or 0
		elseif typ == "string" then
			args[i] = tostring(args[i]) or ""
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
	end

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
end

pac.RegisterPart(PART)

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

do
	local enums = {}

	for key, val in pairs(_G) do
		if type(key) == "string" and key:find("PLAYERANIMEVENT_", nil, true) then
			enums[val] = key:gsub("PLAYERANIMEVENT_", ""):gsub("_", " "):lower()
		end
	end

	pac.AddHook("DoAnimationEvent", function(ply, event, data)
		-- update all parts once so OnShow and OnHide are updated properly for animation events
		if ply.pac_parts then
			ply.pac_anim_event = {name = enums[event], time = pac.RealTime, reset = true}

			for _, v in pairs(pac.GetPartsFromUniqueID(ply:UniqueID())) do
				if v.ClassName == "event" and v.Event == "animation_event" then
					v:GetParent():CallRecursive("Think")
				end
			end
		end
	end)

end

pac.AddHook("EntityEmitSound", function(data)
	if pac.playing_sound then return end
	local ent = data.Entity

	if not ent:IsValid() or not ent.pac_parts then return end

	ent.pac_emit_sound = {name = data.SoundName, time = pac.RealTime, reset = true, mute_me = ent.pac_emit_sound and ent.pac_emit_sound.mute_me or false}

	for _, v in pairs(pac.GetPartsFromUniqueID(ent:IsPlayer() and ent:UniqueID() or ent:EntIndex())) do
		if v.ClassName == "event" and v.Event == "emit_sound" then
			v:GetParent():CallRecursive("Think")

			if ent.pac_emit_sound.mute_me then
				return false
			end
		end
	end

	if ent.pac_mute_sounds then
		return false
	end
end)

pac.AddHook("EntityFireBullets", function(ent, data)
	if not ent:IsValid() or not ent.pac_parts then return end
	ent.pac_fire_bullets = {name = data.AmmoType, time = pac.RealTime, reset = true}

	for _, v in pairs(pac.GetPartsFromUniqueID(ent:IsPlayer() and ent:UniqueID() or ent:EntIndex())) do
		if v.ClassName == "event" and v.Event == "fire_bullets" then
			v:GetParent():CallRecursive("Think")
		end
	end

	if ent.pac_hide_bullets then
		return false
	end
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
-- ####

pac.AddHook("GravGunPunt", function(ply, ent)
	ply.pac_gravgun_ent = ent
	ply.pac_gravgun_punt = pac.RealTime
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
