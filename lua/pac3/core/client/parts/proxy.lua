local BUILDER, PART = pac.PartTemplate("base")

PART.ClassName = "proxy"

PART.ThinkTime = 0
PART.Group = 'modifiers'
PART.Icon = 'icon16/calculator.png'

BUILDER:StartStorableVars()

	BUILDER:SetPropertyGroup("generic")
		BUILDER:GetSet("VariableName", "", {enums = function(part)
			local part = part:GetTarget()
			if not part:IsValid() then return end
			local tbl = {}
			for _, info in pairs(part:GetProperties()) do
				if info.key == "UniqueID" then goto CONTINUE end

				local T = type(info.get())
				if T == "number" or T == "Vector" or T == "Angle" or T == "boolean" then
					tbl[info.key] = info.key
				end
				::CONTINUE::
			end

			return tbl
		end})

		BUILDER:GetSet("RootOwner", false)
		BUILDER:GetSetPart("TargetPart")
		BUILDER:GetSetPart("OutputTargetPart", {hide_in_editor = true})
		BUILDER:GetSet("AffectChildren", false)
		BUILDER:GetSet("Expression", "")

	BUILDER:SetPropertyGroup("easy setup")
		BUILDER:GetSet("Input", "time", {enums = function(part) return part.Inputs end})
		BUILDER:GetSet("Function", "sin", {enums = function(part) return part.Functions end})
		BUILDER:GetSet("Axis", "")
		BUILDER:GetSet("Min", 0)
		BUILDER:GetSet("Max", 1)
		BUILDER:GetSet("Offset", 0)
		BUILDER:GetSet("InputMultiplier", 1)
		BUILDER:GetSet("InputDivider", 1)
		BUILDER:GetSet("Pow", 1)

	BUILDER:SetPropertyGroup("behavior")
		BUILDER:GetSet("Additive", false)
		BUILDER:GetSet("PlayerAngles", false)
		BUILDER:GetSet("ZeroEyePitch", false)
		BUILDER:GetSet("ResetVelocitiesOnHide", true)
		BUILDER:GetSet("VelocityRoughness", 10)

BUILDER:EndStorableVars()

-- redirect
function PART:SetOutputTargetPart(part)
	if not part:IsValid() then return end
	self.SetOutputTargetPartUID = ""
	self:SetTargetPart(part)
end

function PART:GetPhysicalTarget()
	local part = self:GetTargetPart()

	if part:IsValid() then
		return part
	end

	local parent = self:GetParent()

	while not parent.GetWorldPosition or parent:GetWorldPosition():IsZero() do
		if not parent.Parent:IsValid() then break end
		parent = parent.Parent
	end

	if not parent.GetWorldPosition then
		local owner = parent:GetOwner()
		if owner:IsValid() then
			return owner
		end
	end

	return parent
end

function PART:GetTarget()
	local part = self:GetTargetPart()

	if part:IsValid() then
		return part
	end

	return self:GetParent()
end

function PART:SetVariableName(str)
	self.VariableName = str
end

function PART:GetNiceName()
	if self:GetVariableName() == "" then
		return self.ClassName
	end

	local target

	if self.AffectChildren then
		target = "children"
	else
		local part = self:GetTarget()
		if part:IsValid() then
			target = part:GetName()
		end
	end

	local axis = self:GetAxis()
	if axis ~= "" then
		axis = "." .. axis
	end

	return (target or "?") .. "." .. pac.PrettifyName(self:GetVariableName()) .. axis .. " = " .. (self.debug_var or "?")
end

function PART:Initialize()
	self.vec_additive = {}
	self.next_vel_calc = 0
end

PART.Functions =
{
	none = function(n) return n end,
	sin = math.sin,
	cos = math.cos,
	tan = math.tan,
	abs = math.abs,
	mod = function(n, s) return n%s.Max end,
	sgn = function(n) return n>0 and 1 or n<0 and -1 or 0 end,
}

local FrameTime = FrameTime

function PART:CalcVelocity()
	self.last_vel = self.last_vel or Vector()
	self.last_vel_smooth = self.last_vel_smooth or self.last_vel or Vector()

	self.last_vel_smooth = (self.last_vel_smooth + (self.last_vel - self.last_vel_smooth) * FrameTime() * math.max(self.VelocityRoughness, 0.1))
end

function PART:GetVelocity(part)
	local pos

	if part.GetWorldPosition then
		pos = part:GetWorldPosition()
	else
		if IsEntity(part) then
			pos = part:GetPos()
		elseif part:GetOwner():IsValid() then
			pos = part:GetOwner():GetPos()
		end
	end

	local time = pac.RealTime

	if self.next_vel_calc < time then
		self.next_vel_calc = time + 0.1
		self.last_vel = (self.last_pos or pos) - pos
		self.last_pos = pos
	end

	return self.last_vel_smooth / 5
end

function PART:CalcEyeAngles(ent)
	local ang = self.PlayerAngles and ent:GetAngles() or ent:EyeAngles()

	if self.ZeroEyePitch then
		ang.p = 0
	end

	return ang
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

PART.Inputs = {}

PART.Inputs.property = function(self, property_name, field)

	local part = self.TargetEntity:IsValid() and self.TargetEntity or self:GetParent()

	if part:IsValid() and part.GetProperty and property_name then
		local v = part:GetProperty(property_name)

		local T = type(v)

		if T == "Vector" or T == "Angle" then
			if field and v[field] then
				return v[field]
			else
				return v[1],v[2],v[3]
			end
		elseif T == "boolean" then
			return v and 1 or 0
		elseif T == "number" then
			return v
		end
	end

	return 0
end

PART.Inputs.owner_position = function(self)
	local owner = get_owner(self)

	if owner:IsValid() then
		local pos = owner:GetPos()

		return pos.x, pos.y, pos.z
	end

	return 0,0,0
end

PART.Inputs.owner_position_x = function(self)
	local owner = get_owner(self)

	if owner:IsValid() then
		local pos = owner:GetPos()

		return pos.x
	end

	return 0
end

PART.Inputs.owner_position_y = function(self)
	local owner = get_owner(self)

	if owner:IsValid() then
		local pos = owner:GetPos()

		return pos.y
	end

	return 0
end

PART.Inputs.owner_position_z = function(self)
	local owner = get_owner(self)

	if owner:IsValid() then
		local pos = owner:GetPos()

		return pos.z
	end

	return 0
end

PART.Inputs.owner_fov = function(self)
	local owner = get_owner(self)

	if owner:IsValid() and owner.GetFOV then
		return owner:GetFOV()
	end

	return 0
end

PART.Inputs.visible = function(self, radius)
	local part = self:GetPhysicalTarget()
	if not part.GetWorldPosition then return 0 end
	part.proxy_pixvis = part.proxy_pixvis or util.GetPixelVisibleHandle()
	return util.PixelVisible(part:GetWorldPosition(), radius or 16, part.proxy_pixvis) or 0
end

PART.Inputs.time = RealTime
PART.Inputs.synced_time = CurTime
PART.Inputs.systime = SysTime
PART.Inputs.stime = SysTime
PART.Inputs.frametime = FrameTime
PART.Inputs.ftime = FrameTime
PART.Inputs.framenumber = FrameNumber
PART.Inputs.fnumber = FrameNumber

PART.Inputs.random = function(self, min, max)
	min = min or 0
	max = max or 1
	return min + math.random()*(max-min)
end

PART.Inputs.random_once = function(self, seed, min, max)
	min = min or 0
	max = max or 1

	seed = seed or 0
	self.rand_id = self.rand_id or {}
	if seed then
		self.rand_id[seed] = self.rand_id[seed] or min + math.random()*(max-min)
	else
		self.rand = self.rand or min + math.random()*(max-min)
	end

	return self.rand_id[seed] or self.rand
end

PART.Inputs.lerp = function(self, m, a, b)
	m = tonumber(m) or 0
	a = tonumber(a) or -1
	b = tonumber(b) or 1

	return (b - a) * m + a
end

for ease,f in pairs(math.ease) do
	if string.find(ease,"In") or string.find(ease,"Out") then
		local f2 = function(self, frac, min, max)
			min = min or 0
			max = max or 1
			return min + f(frac)*(max-min)
		end
		PART.Inputs["ease"..ease] = f2
		PART.Inputs["ease_"..ease] = f2
		PART.Inputs[ease] = f2
	end
end

PART.Inputs.timeex = function(s)
	s.time = s.time or pac.RealTime

	return pac.RealTime - s.time
end

PART.Inputs.part_distance = function(self, uid1, uid2)
	if not uid1 or not uid2 then return 0 end

	local PartA = pac.GetPartFromUniqueID(pac.Hash(pac.LocalPlayer), uid1)
	if not PartA:IsValid() then PartA = pac.FindPartByName(pac.Hash(pac.LocalPlayer), uid1, self) end

	local PartB = pac.GetPartFromUniqueID(pac.Hash(pac.LocalPlayer), uid2)
	if not PartB:IsValid() then PartB = pac.FindPartByName(pac.Hash(pac.LocalPlayer), uid2, self) end

	if not PartA:IsValid() or not PartB:IsValid() then return 0 end
	return (PartB:GetWorldPosition() - PartA:GetWorldPosition()):Length()
end

PART.Inputs.event_alternative = function(self, uid1, num1, num2)
	if not uid1 then return 0 end

	local PartA = pac.GetPartFromUniqueID(pac.Hash(pac.LocalPlayer), uid1)
	if not PartA:IsValid() then PartA = pac.FindPartByName(pac.Hash(pac.LocalPlayer), uid1, self) end

	if PartA.ClassName == "event" then
		if PartA.event_triggered then return num1 or 0
		else return num2 or 0 end
	else return -1 end
	return 0
end

PART.Inputs.number_operator_alternative = function(self, comp1, op, comp2, num1, num2)
	if not (comp1 and op and comp2 and num1 and num2) then return -1 end
	if not (isnumber(comp1) and isnumber(comp2) and isnumber(num1) and isnumber(num2)) then return -1 end
	local b = true
	if op == "=" or op == "==" or op == "equal" then
		b = comp1 == comp2
	elseif op == ">" or op == "above" or op == "greater" or op == "greater than" then
		b = comp1 > comp2
	elseif op == ">=" or op == "above or equal" or op == "greater or equal" or op == "greater than or equal" then
		b = comp1 >= comp2
	elseif op == "<" or op == "below" or op == "less" or op == "less than" then
		b = comp1 < comp2
	elseif op == "<=" or op == "below or equal" or op == "less or equal" or op == "less than or equal" then
		b = comp1 <= comp2
	elseif op == "~=" or op == "~=" or op == "not equal" then
		b = comp1 ~= comp2
	end
	if b then return num1 or 0 else return num2 or 0 end
end

do
	local function get_pos(self)
		local part = self:GetPhysicalTarget()
		if not part:IsValid() then return end

		local pos
		if part.GetWorldPosition then
			pos = part:GetWorldPosition()
		else
			local owner = get_owner(part)
			if not owner:IsValid() then return end
			pos = owner:GetPos()
		end

		return pos
	end

	PART.Inputs.eye_position_distance = function(self)
		local pos = get_pos(self)
		if not pos then return 0 end

		return pos:Distance(pac.EyePos)
	end

	PART.Inputs.eye_angle_distance = function(self)
		local pos = get_pos(self)
		if not pos then return 0 end

		return math.Clamp(math.abs(pac.EyeAng:Forward():DotProduct((pos - pac.EyePos):GetNormalized())) - 0.5, 0, 1)
	end

end

PART.Inputs.aim_length = function(self)
	local owner = get_owner(self)
	if not owner:IsValid() then return 0 end

	local res = util.QuickTrace(owner:EyePos(), self:CalcEyeAngles(owner):Forward() * 16000, {owner, owner:GetParent()})

	return res.StartPos:Distance(res.HitPos)
end

PART.Inputs.aim_length_fraction = function(self)
	local owner = get_owner(self)
	if not owner:IsValid() then return 0 end

	local res = util.QuickTrace(owner:EyePos(), self:CalcEyeAngles(owner):Forward() * 16000, {owner, owner:GetParent()})

	return res.Fraction
end

do
	local function get_eye_angle(self, field)
		local owner = get_owner(self)

		if not owner:IsValid() then return 0 end
		local n = self:CalcEyeAngles(owner)[field]

		if field == "p" then
			return -(1 + math.NormalizeAngle(n) / 89) / 2 + 1
		end

		return math.NormalizeAngle(n)/90
	end

	PART.Inputs.owner_eye_angle_pitch = function(self) return get_eye_angle(self, "p") end
	PART.Inputs.owner_eye_angle_yaw = function(self) return get_eye_angle(self, "y") end
	PART.Inputs.owner_eye_angle_roll = function(self) return get_eye_angle(self, "r") end
end

do
	local function get_scale(self, field)
		local owner = get_owner(self)

		if not owner:IsValid() then return 1 end

		return owner.pac_model_scale and owner.pac_model_scale[field] or (owner.GetModelScale and owner:GetModelScale()) or 1
	end
	PART.Inputs.owner_scale_x = function(self) return get_scale(self, "x") end
	PART.Inputs.owner_scale_y = function(self) return get_scale(self, "y") end
	PART.Inputs.owner_scale_z = function(self) return get_scale(self, "z") end
end

-- outfit owner
PART.Inputs.owner_velocity_length = function(self)
	local owner = get_owner(self)
	if not owner:IsValid() then return 0 end

	return self:GetVelocity(owner):Length()
end

do
	local function get_velocity(self, field)
		local owner = get_owner(self)
		if not owner:IsValid() then return 0 end

		local dir = self:CalcEyeAngles(owner)
		return dir[field](dir):Dot(self:GetVelocity(owner))
	end

	PART.Inputs.owner_velocity_forward = function(self) return get_velocity(self, "Forward") end
	PART.Inputs.owner_velocity_right = function(self) return get_velocity(self, "Right") end
	PART.Inputs.owner_velocity_up = function(self) return get_velocity(self, "Up") end
end

do -- velocity world
	local function get_velocity(self)
		local owner = get_owner(self)
		if not owner:IsValid() then return 0 end

		return self:GetVelocity(owner)
	end

	PART.Inputs.owner_velocity_world_forward = function(self) return get_velocity(self)[1] end
	PART.Inputs.owner_velocity_world_right = function(self) return get_velocity(self)[2] end
	PART.Inputs.owner_velocity_world_up = function(self) return get_velocity(self)[3] end
end

-- outfit owner vel increase
PART.Inputs.owner_velocity_length_increase = function(self)
	local owner = get_owner(self)
	if not owner:IsValid() then return 0 end

	local vel = self:GetVelocity(owner):Length()
	self.ov_length_i = (self.ov_length_i or 0) + vel * FrameTime()
	return self.ov_length_i
end

do
	PART.Inputs.owner_velocity_forward_increase = function(self)
		local owner = get_owner(self)
		if not owner:IsValid() then return 0 end

		local vel = self:CalcEyeAngles(owner):Forward():Dot(self:GetVelocity(owner))
		self.ov_forward_i = (self.ov_forward_i or 0) + vel * FrameTime()
		return self.ov_forward_i
	end
	PART.Inputs.owner_velocity_right_increase = function(self)
		local owner = get_owner(self)
		if not owner:IsValid() then return 0 end

		local vel = self:CalcEyeAngles(owner):Right():Dot(self:GetVelocity(owner))
		self.ov_right_i = (self.ov_right_i or 0) + vel * FrameTime()
		return self.ov_right_i
	end
	PART.Inputs.owner_velocity_up_increase = function(self)
		local owner = get_owner(self)
		if not owner:IsValid() then return 0 end

		local vel = self:CalcEyeAngles(owner):Up():Dot(self:GetVelocity(owner))
		self.ov_up_i = (self.ov_up_i or 0) + vel * FrameTime()
		return self.ov_up_i
	end
end

do --
	PART.Inputs.owner_velocity_world_forward_increase = function(self)
		local owner = get_owner(self)
		if not owner:IsValid() then return 0 end

		local vel = self:GetVelocity(owner)[1]
		self.ov_wforward_i = (self.ov_wforward_i or 0) + vel * FrameTime()
		return self.ov_wforward_i
	end
	PART.Inputs.owner_velocity_world_right_increase = function(self)
		local owner = get_owner(self)
		if not owner:IsValid() then return 0 end

		local vel = self:GetVelocity(owner)[2]
		self.ov_wright_i = (self.ov_wright_i or 0) + vel * FrameTime()
		return self.ov_wright_i
	end
	PART.Inputs.owner_velocity_world_up_increase = function(self)
		local owner = get_owner(self)
		if not owner:IsValid() then return 0 end

		local vel = self:GetVelocity(owner)[3]
		self.ov_wup_i = (self.ov_wup_i or 0) + vel * FrameTime()
		return self.ov_wup_i
	end
end

do -- velocity
	PART.Inputs.parent_velocity_length = function(self)
		return self:GetVelocity(self:GetPhysicalTarget()):Length()
	end

	local function get_velocity(self)
		local part = self:GetPhysicalTarget()
		local ang

		if part.GetWorldAngles then
			ang = part:GetWorldAngles()
		elseif part.GetAngles then
			ang = part:GetAngles()
		end

		return ang and self:GetVelocity(part), ang
	end

	PART.Inputs.parent_velocity_forward = function(self)
		local vel, ang = get_velocity(self)
		if not vel then return 0 end

		return -ang:Forward():Dot(vel)
	end
	PART.Inputs.parent_velocity_right = function(self)
		local vel, ang = get_velocity(self)
		if not vel then return 0 end

		return ang:Right():Dot(vel)
	end
	PART.Inputs.parent_velocity_up = function(self)
		local vel, ang = get_velocity(self)
		if not vel then return 0 end

		return ang:Up():Dot(vel)
	end
end

do -- scale
	local function get_scale(self, field)
		local part = self:GetPhysicalTarget()
		if not part:IsValid() then return 1 end

		return part.Scale and part.Scale[field]*part.Size or 1
	end
	PART.Inputs.parent_scale_x = function(self) return get_scale(self, "x") end
	PART.Inputs.parent_scale_y = function(self) return get_scale(self, "y") end
	PART.Inputs.parent_scale_z = function(self) return get_scale(self, "z") end
end

PART.Inputs.pose_parameter = function(self, name)
	if not name then return 0 end
	local owner = get_owner(self)
	if owner:IsValid() and owner.GetPoseParameter then return owner:GetPoseParameter(name) end

	return 0
end

PART.Inputs.pose_parameter_true = function(self, name)
	if not name then return 0 end
	local owner = get_owner(self)
	if owner:IsValid() then
		local min, max = owner:GetPoseParameterRange(owner:LookupPoseParameter(name))
		return min + (max - min)*(owner:GetPoseParameter(name))
	end
	return 0
end

PART.Inputs.command = function(self, name)
	local ply = self:GetPlayerOwner()
	if ply.pac_proxy_events then
		local data
		if not name then data = ply.pac_proxy_events[self.Name]
		else data = ply.pac_proxy_events[name] end

		if data then
			data.x = data.x or 0
			data.y = data.y or 0
			data.z = data.z or 0
			return data.x, data.y, data.z
		end
	end

	return 0, 0, 0
end

PART.Inputs.voice_volume = function(self)
	local ply = self:GetPlayerOwner()
	if not IsValid(ply) then return 0 end
	return ply:VoiceVolume()
end

PART.Inputs.voice_volume_scale = function(self)
	local ply = self:GetPlayerOwner()
	return ply:GetVoiceVolumeScale()
end

do -- light amount
	local ColorToHSV = ColorToHSV
	local render = render
	local function get_color(self, field)
		local part = self:GetPhysicalTarget()
		if not part:IsValid() then return 0 end
		if not part.GetWorldPosition then return 0 end
		local v = field and render.GetLightColor(part:GetWorldPosition()):ToColor()[field] or render.GetLightColor(part:GetWorldPosition()):ToColor()

		if part.ProperColorRange then
			if field then return v / 255 else return v['r']/255, v['g']/255, v['b']/255 end
		end

		if field then return v else return v['r'], v['g'], v['b'] end
	end

	PART.Inputs.light_amount = function(self) return get_color(self) end
	PART.Inputs.light_amount_r = function(self) return get_color(self, "r") end
	PART.Inputs.light_amount_g = function(self) return get_color(self, "g") end
	PART.Inputs.light_amount_b = function(self) return get_color(self, "b") end

	PART.Inputs.light_value = function(self)
		local part = self:GetPhysicalTarget()
		if not part:IsValid() then return 0 end
		if not part.GetWorldPosition then return 0 end

		local h, s, v = ColorToHSV(render.GetLightColor(part:GetWorldPosition()):ToColor())
		return v
	end
end

do -- ambient light
	local render = render
	local function get_color(self, field)
		local part = self:GetTarget()
		if not part:IsValid() then return 0 end

		local v = field and render.GetAmbientLightColor():ToColor()[field] or render.GetAmbientLightColor():ToColor()

		if part.ProperColorRange then
			if field then return v / 255 else return v['r']/255, v['g']/255, v['b']/255 end
		end

		if field then return v else return v['r'], v['g'], v['b'] end
	end

	PART.Inputs.ambient_light = function(self) return get_color(self) end
	PART.Inputs.ambient_light_r = function(self) return get_color(self, "r") end
	PART.Inputs.ambient_light_g = function(self) return get_color(self, "g") end
	PART.Inputs.ambient_light_b = function(self) return get_color(self, "b") end
end

do -- health and armor
	PART.Inputs.owner_health = function(self)
		local owner = self:GetPlayerOwner()
		if not owner:IsValid() then return 0 end

		return owner:Health()
	end
	PART.Inputs.owner_max_health = function(self)
		local owner = self:GetPlayerOwner()
		if not owner:IsValid() then return 0 end

		return owner:GetMaxHealth()
	end
	PART.Inputs.owner_health_fraction = function(self)
		local owner = self:GetPlayerOwner()
		if not owner:IsValid() then return 0 end

		return owner:Health() / owner:GetMaxHealth()
	end

	PART.Inputs.owner_armor = function(self)
		local owner = self:GetPlayerOwner()
		if not owner:IsValid() then return 0 end

		return owner:Armor()
	end
	PART.Inputs.owner_max_armor = function(self)
		local owner = self:GetPlayerOwner()
		if not owner:IsValid() then return 0 end

		return owner:GetMaxArmor()
	end
	PART.Inputs.owner_armor_fraction = function(self)
		local owner = self:GetPlayerOwner()
		if not owner:IsValid() then return 0 end

		return owner:Armor() / owner:GetMaxArmor()
	end
end

do -- weapon and player color
	local Color = Color
	local function get_color(self, get, field)
		local color = field and get(self)[field] or get(self)
		local part = self:GetTarget()

		if part.ProperColorRange then
			if field then return color else return color[1], color[2], color[3] end
		end

		if field then return color*255 else return color[1]*255, color[2]*255, color[3]*255 end
	end

	do
		local function get_player_color(self)
			local owner = self:GetPlayerOwner()

			if not owner:IsValid() then return Vector(1,1,1) end

			return owner:GetPlayerColor()
		end

		PART.Inputs.player_color = function(self) return get_color(self, get_player_color) end
		PART.Inputs.player_color_r = function(self) return get_color(self, get_player_color, "r") end
		PART.Inputs.player_color_g = function(self) return get_color(self, get_player_color, "g") end
		PART.Inputs.player_color_b = function(self) return get_color(self, get_player_color, "b") end
	end

	do
		local function get_weapon_color(self)
			local owner = self:GetPlayerOwner()

			if not owner:IsValid() then return Vector(1,1,1) end

			return owner:GetWeaponColor()
		end

		PART.Inputs.weapon_color = function(self) return get_color(self, get_weapon_color) end
		PART.Inputs.weapon_color_r = function(self) return get_color(self, get_weapon_color, "r") end
		PART.Inputs.weapon_color_g = function(self) return get_color(self, get_weapon_color, "g") end
		PART.Inputs.weapon_color_b = function(self) return get_color(self, get_weapon_color, "b") end
	end
end

do -- ammo
	local function get_weapon(self)
		local owner = self:GetRootPart():GetOwner()
		if not owner:IsValid() then return 0 end

		if owner.GetActiveWeapon and not owner:IsWeapon() then
			owner = self:GetPlayerOwner()
		end

		if not owner:IsValid() then return 0 end

		return owner.GetActiveWeapon and owner:GetActiveWeapon() or owner, owner
	end

	PART.Inputs.owner_total_ammo = function(self, id)
		local owner = self:GetPlayerOwner()
		id = id and id:lower()

		if not owner:IsValid() then return 0 end

		return (owner.GetAmmoCount and id) and owner:GetAmmoCount(id) or 0
	end

	PART.Inputs.weapon_primary_ammo = function(self)
		local wep = get_weapon(self)

		return wep:IsValid() and wep.Clip1 and wep:Clip1() or 0
	end
	PART.Inputs.weapon_primary_total_ammo = function(self)
		local wep, owner = get_weapon(self)

		return wep:IsValid() and (wep.GetPrimaryAmmoType and owner.GetAmmoCount) and owner:GetAmmoCount(wep:GetPrimaryAmmoType()) or 0
	end
	PART.Inputs.weapon_primary_clipsize = function(self)
		local wep = get_weapon(self)

		return wep:IsValid() and wep.GetMaxClip1 and wep:GetMaxClip1() or 0
	end
	PART.Inputs.weapon_secondary_ammo = function(self)
		local wep = get_weapon(self)

		return wep:IsValid() and wep.Clip2 and wep:Clip2() or 0
	end
	PART.Inputs.weapon_secondary_total_ammo = function(self)
		local wep, owner = get_weapon(self)

		return wep:IsValid() and (wep.GetSecondaryAmmoType and owner.GetAmmoCount) and owner:GetAmmoCount(wep:GetSecondaryAmmoType()) or 0
	end
	PART.Inputs.weapon_secondary_clipsize = function(self)
		local wep = get_weapon(self)

		return wep:IsValid() and wep.GetMaxClip2 and wep:GetMaxClip2() or 0
	end
end

PART.Inputs.hsv_to_color = function(self, h, s, v)

	local part = self:GetTarget()
	if not part:IsValid() then return end

	h = tonumber(h) or 0
	s = tonumber(s) or 1
	v = tonumber(v) or 1

	local c = HSVToColor(h%360, s, v)

	if part.ProperColorRange then
		return c.r/255, c.g/255, c.b/255
	end

	return c.r, c.g, c.b
end

do
	PART.Inputs.feedback = function(self)
		if not self.feedback then return 0 end
		return self.feedback[1] or 0
	end

	PART.Inputs.feedback_x = function(self)
		if not self.feedback then return 0 end
		return self.feedback[1] or 0
	end

	PART.Inputs.feedback_y = function(self)
		if not self.feedback then return 0 end
		return self.feedback[2] or 0
	end

	PART.Inputs.feedback_z = function(self)
		if not self.feedback then return 0 end
		return self.feedback[3] or 0
	end
end

PART.Inputs.flat_dot_forward = function(self)
	local part = get_owner(self)

	if part:IsValid() then
		local ang = part:IsPlayer() and part:EyeAngles() or part:GetAngles()
		ang.p = 0
		ang.r = 0
		local dir = pac.EyePos - part:EyePos()
		dir[3] = 0
		dir:Normalize()
		return dir:Dot(ang:Forward())
	end

	return 0
end

PART.Inputs.flat_dot_right = function(self)
	local part = get_owner(self)

	if part:IsValid() then
		local ang = part:IsPlayer() and part:EyeAngles() or part:GetAngles()
		ang.p = 0
		ang.r = 0
		local dir = pac.EyePos - part:EyePos()
		dir[3] = 0
		dir:Normalize()
		return dir:Dot(ang:Right())
	end

	return 0
end

net.Receive("pac_proxy", function()
	local ply = net.ReadEntity()
	local str = net.ReadString()

	local x = net.ReadFloat()
	local y = net.ReadFloat()
	local z = net.ReadFloat()

	if ply:IsValid() then
		ply.pac_proxy_events = ply.pac_proxy_events or {}
		ply.pac_proxy_events[str] = {name = str, x = x, y = y, z = z}
	end
end)

function PART:CheckLastVar(part)
	if self.last_var ~= self.VariableName then
		if self.last_var then
			part:SetProperty(self.VariableName, self.last_var_val)
		end
		self.last_var = self.VariableName
		self.last_var_val = part:GetProperty(self.VariableName)
	end
end

local allowed = {
	number = true,
	Vector = true,
	Angle = true,
	boolean = true,
}

function PART:SetExpression(str)
	self.Expression = str
	self.ExpressionFunc = nil

	if str and str ~= "" then
		local lib = {}

		for name, func in pairs(PART.Inputs) do
			lib[name] = function(...) return func(self, ...) end
		end

		local ok, res = pac.CompileExpression(str, lib)
		if ok then
			self.ExpressionFunc = res
			self.ExpressionError = nil
			self:SetError()
		else
			self.ExpressionFunc = true
			self.ExpressionError = res
			self:SetError(res)
		end
	end
end

function PART:OnHide()
	self.time = nil
	self.rand = nil
	self.rand_id = nil
	self.vec_additive = Vector()

	if self.ResetVelocitiesOnHide then
		self.last_vel = nil
		self.last_pos = nil
		self.last_vel_smooth = nil
	end

	if self.VariableName == "Hide" then
		-- cleanup event triggers on hide
		local part = self:GetTarget()
		if self.AffectChildren then
			for _, part in ipairs(self:GetChildren()) do
				part:SetEventTrigger(self, false)
				part.proxy_hide = nil
			end
		elseif part:IsValid() then
			part:SetEventTrigger(self, false)
			part.proxy_hide = nil
		end
	end
end

function PART:OnShow()
	self.time = nil
	self.rand = nil
	self.rand_id = nil
	self.vec_additive = Vector()
end

local function set(self, part, x, y, z, children)
	local val = part:GetProperty(self.VariableName)
	local T = type(val)

	if allowed[T] then
		if T == "boolean" then
			x = x or val == true and 1 or 0
			local b = tonumber(x) > 0


			-- special case for hide to make it behave like events
			if self.VariableName == "Hide" then

				if part.proxy_hide ~= b then

					-- in case parts start as hidden
					if b == false then
						part:SetKeyValueRecursive("Hide", b)
					end

					-- we want any nested proxies to think twice before they decide to enable themselves
					part:CallRecursiveOnClassName("proxy", "OnThink")

					part:SetEventTrigger(self, b)

					part.proxy_hide = b
				end

				-- don't apply anything to children
				return
			else
				part:SetProperty(self.VariableName, b)
			end
		elseif T == "number" then
			x = x or val
			part:SetProperty(self.VariableName, tonumber(x) or 0)
		else
			if self.Axis ~= "" and val[self.Axis] then
				val = val * 1
				val[self.Axis] = x
			else
				if T == "Angle" then
					val = val * 1
					val.p = x or val.p
					val.y = y or val.y
					val.r = z or val.r
				elseif T == "Vector" then
					val = val * 1
					val.x = x or val.x
					val.y = y or val.y
					val.z = z or val.z
				end
			end

			part:SetProperty(self.VariableName, val)
		end
	end

	if children then
		for _, part in ipairs(part:GetChildren()) do
			set(self, part, x, y, z, true)
		end
	end
end

function PART:RunExpression(ExpressionFunc)
	if ExpressionFunc==true then
		return false,self.ExpressionError
	end
	return pcall(ExpressionFunc)
end

function PART:OnThink()
	local part = self:GetTarget()
	if not part:IsValid() then return end
	if part.ClassName == 'woohoo' then return end

	self:CalcVelocity()

	local ExpressionFunc = self.ExpressionFunc

	if not ExpressionFunc then
		self:SetExpression(self.Expression)
		ExpressionFunc = self.ExpressionFunc
	end

	if ExpressionFunc then

		local ok, x,y,z = self:RunExpression(ExpressionFunc)

		if not ok then
			if self:GetPlayerOwner() == pac.LocalPlayer and self.Expression ~= self.LastBadExpression then
				chat.AddText(Color(255,180,180),"============\n[ERR] PAC Proxy error on "..tostring(self)..":\n"..x.."\n============\n")
				self.LastBadExpression = self.Expression
			end
			return
		end

		if x and not isnumber(x) then x = 0 end
		if y and not isnumber(y) then y = 0 end
		if z and not isnumber(z) then z = 0 end


		if self.Additive then
			if x then
				self.vec_additive[1] = (self.vec_additive[1] or 0) + x
				x = self.vec_additive[1]
			end

			if y then
				self.vec_additive[2] = (self.vec_additive[2] or 0) + y
				y = self.vec_additive[2]
			end

			if z then
				self.vec_additive[3] = (self.vec_additive[3] or 0) + z
				z = self.vec_additive[3]
			end
		end

		self.feedback = self.feedback or {}
		self.feedback[1] = x
		self.feedback[2] = y
		self.feedback[3] = z

		if self.AffectChildren then
			for _, part in ipairs(self:GetChildren()) do
				set(self, part, x, y, z, true)
			end
		else
			set(self, part, x, y, z)
		end

		if pace and pace.IsActive() then

			local str = ""

			if x then str = str .. math.Round(x, 3) end
			if y then str = str .. ", " .. math.Round(y, 3) end
			if z then str = str .. ", " .. math.Round(z, 3) end

			local val = part:GetProperty(self.VariableName)
			local T = type(val)

			if T == "boolean" then
				str = tonumber(x) > 0 and "true" or "false"
			elseif T == "Vector" then
				str = "Vector(" .. str .. ")"
			elseif T == "Angle" then
				str = "Angle(" .. str .. ")"
			end

			self.debug_var = str

			if self.Name == "" and pace.current_part == self and self.pace_properties and IsValid(self.pace_properties["Name"]) then
				self.pace_properties["Name"]:SetText(self:GetNiceName())
			end
		end
	else

		local post_function = self.Functions[self.Function]
		local input_function = self.Inputs[self.Input]

		if post_function and input_function then
			local ran, err = pcall( input_function, self )

			if not ran then
				error("proxy function " .. tostring( self.Input ) .. " | " .. tostring( self.Function ) .. " | " .. tostring( self ) .. " failed: " .. err)
			end

			local input_number = err

			if not isnumber(input_number) then
				error("proxy function " .. self.Input .. " does not return a number!")
			end

			local num = self.Min + (self.Max - self.Min) * ((post_function(((input_number / self.InputDivider) + self.Offset) * self.InputMultiplier, self) + 1) / 2) ^ self.Pow

			if self.Additive then
				self.vec_additive[1] = (self.vec_additive[1] or 0) + num
				num = self.vec_additive[1]
			end

			if self.AffectChildren then
				for _, part in ipairs(self:GetChildren()) do
					set(self, part, num, nil, nil, true)
				end
			else
				set(self, part, num)
			end

			if pace and pace.IsActive() then
				self.debug_var = math.Round(num, 3)
			end

			if self.Name == "" and pace.current_part == self and self.pace_properties and IsValid(self.pace_properties["Name"]) then
				self.pace_properties["Name"]:SetText(self:GetNiceName())
			end
		end
	end

end

BUILDER:Register()
