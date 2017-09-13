local PART = {}

PART.ClassName = "proxy"
PART.NonPhysical = true
PART.ThinkTime = 0
PART.Group = 'modifiers'
PART.Icon = 'icon16/calculator.png'

pac.StartStorableVars()

	pac.SetPropertyGroup()
		pac.GetSet(PART, "VariableName", "", {enums = function(part)
			local parent = part:GetParent()
			if not parent:IsValid() then return end
			local tbl = {}
			for key, _ in pairs(parent.StorableVars) do
				if key == "UniqueID" then continue end

				local T = type(parent[key])
				if T == "number" or T == "Vector" or T == "Angle" or T == "boolean" then
					tbl[key:gsub("%u", " %1"):lower()] = key
				end
			end

			return tbl
		end})

		pac.GetSet(PART, "RootOwner", false)
		pac.SetupPartName(PART, "TargetPart")
		pac.GetSet(PART, "AffectChildren", false)
		pac.GetSet(PART, "Expression", "")

	pac.SetPropertyGroup("easy setup")
		pac.GetSet(PART, "Input", "time", {enums = function(part) return part.Inputs end})
		pac.GetSet(PART, "Function", "sin", {enums = function(part) return part.Functions end})
		pac.GetSet(PART, "Axis", "")
		pac.GetSet(PART, "Min", 0)
		pac.GetSet(PART, "Max", 1)
		pac.GetSet(PART, "Offset", 0)
		pac.GetSet(PART, "InputMultiplier", 1)
		pac.GetSet(PART, "InputDivider", 1)
		pac.GetSet(PART, "Pow", 1)

	pac.SetPropertyGroup("behavior")
		pac.GetSet(PART, "Additive", false)
		pac.GetSet(PART, "PlayerAngles", false)
		pac.GetSet(PART, "ZeroEyePitch", false)
		pac.GetSet(PART, "ResetVelocitiesOnHide", true)
		pac.GetSet(PART, "VelocityRoughness", 10)

pac.EndStorableVars()

function PART:SetVariableName(str)
	self.VariableName = str

	self.set_key = "Set" .. str
	self.get_key = "Get" .. str
end

function PART:GetParentEx()
	local parent = self:GetTargetPart()

	if parent:IsValid() then
		return parent
	end

	return self:GetParent()
end

function PART:GetNiceName()
	if self:GetVariableName() == "" then
		return self.ClassName
	end

	return pac.PrettifyName(self:GetVariableName()) .. " = " .. (self.debug_var or "?") .. " proxy"
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
	local pos = part.cached_pos

	if not pos or pos == Vector() then
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
	return ent == pac.LocalPlayer:GetViewModel() and pac.LocalPlayer or ent
end

PART.Inputs =
{
	owner_position = function(s, p)
		local owner = s:GetOwner(s.RootOwner)
		owner = try_viewmodel(owner)

		if owner:IsValid() then
			local pos = owner:GetPos()

			return pos.x, pos.y, pos.z
		end

		return 0,0,0
	end,
	owner_fov = function(s, p)
		local owner = s:GetOwner(s.RootOwner)

		owner = try_viewmodel(owner)

		if owner:IsValid() and owner.GetFOV then
			return owner:GetFOV()
		end

		return 0
	end,
	visible = function(s, p, radius)
		p.proxy_pixvis = p.proxy_pixvis or util.GetPixelVisibleHandle()
		return util.PixelVisible(p.cached_pos, radius or 16, p.proxy_pixvis) or 0
	end,
	time = RealTime,
	synced_time = CurTime,
	random = function(s, p)
		return math.random()
	end,
	timeex = function(s, p)
		s.time = s.time or pac.RealTime

		return pac.RealTime - s.time
	end,

	eye_position_distance = function(self, parent)
		local pos = parent.cached_pos

		if parent.NonPhysical then
			local owner = parent:GetOwner(self.RootOwner)
			if owner:IsValid() then
				pos = owner:GetPos()
			end
		end

		return pos:Distance(pac.EyePos)
	end,
	eye_angle_distance = function(self, parent)
		local pos = parent.cached_pos

		if parent.NonPhysical then
			local owner = parent:GetOwner(self.RootOwner)
			if owner:IsValid() then
				pos = owner:GetPos()
			end
		end

		return math.Clamp(math.abs(pac.EyeAng:Forward():DotProduct((pos - pac.EyePos):GetNormalized())) - 0.5, 0, 1)
	end,

	aim_length = function(self, parent)
		local owner = self:GetOwner(self.RootOwner)

		owner = try_viewmodel(owner)

		if owner:IsValid() then
			local res = util.QuickTrace(owner:EyePos(), self:CalcEyeAngles(owner):Forward() * 16000, {owner, owner:GetParent()})

			return res.StartPos:Distance(res.HitPos)
		end

		return 0
	end,
	aim_length_fraction = function(self, parent)
		local owner = self:GetOwner(self.RootOwner)

		owner = try_viewmodel(owner)

		if owner:IsValid() then
			local res = util.QuickTrace(owner:EyePos(), self:CalcEyeAngles(owner):Forward() * 16000, {owner, owner:GetParent()})

			return res.Fraction
		end

		return 0
	end,

	owner_eye_angle_pitch = function(self, parent)
		local owner = self:GetOwner(self.RootOwner)

		owner = try_viewmodel(owner)

		if owner:IsValid() then
			local n = self:CalcEyeAngles(owner).p
			return -(1 + math.NormalizeAngle(n) / 89) / 2 + 1
		end

		return 0
	end,
	owner_eye_angle_yaw = function(self, parent)
		local owner = self:GetOwner(self.RootOwner)

		owner = try_viewmodel(owner)

		if owner:IsValid() then
			local n = self:CalcEyeAngles(owner).y
			return math.NormalizeAngle(n)/90
		end

		return 0
	end,
	owner_eye_angle_roll = function(self, parent)
		local owner = self:GetOwner(self.RootOwner)

		owner = try_viewmodel(owner)

		if owner:IsValid() then
			local n = self:CalcEyeAngles(owner).r
			return math.NormalizeAngle(n)/90
		end

		return 0
	end,

	owner_scale_x = function(self)
		local owner = self:GetOwner(self.RootOwner)

		owner = try_viewmodel(owner)

		if owner:IsValid() then
			return owner.pac_model_scale and owner.pac_model_scale.x or (owner.GetModelScale and owner:GetModelScale()) or 1
		end

		return 1
	end,
	owner_scale_y = function(self)
		local owner = self:GetOwner(self.RootOwner)

		owner = try_viewmodel(owner)

		if owner:IsValid() then
			return owner.pac_model_scale and owner.pac_model_scale.y or (owner.GetModelScale and owner:GetModelScale()) or 1
		end

		return 1
	end,
	owner_scale_z = function(self)
		local owner = self:GetOwner(self.RootOwner)

		owner = try_viewmodel(owner)

		if owner:IsValid() then
			return owner.pac_model_scale and owner.pac_model_scale.z or (owner.GetModelScale and owner:GetModelScale()) or 1
		end

		return 1
	end,

	-- outfit owner
	owner_velocity_length = function(self, parent)
		local owner = self:GetOwner(self.RootOwner)

		owner = try_viewmodel(owner)

		if owner:IsValid() then
			return self:GetVelocity(owner):Length()
		end

		return 0
	end,
	owner_velocity_forward = function(self, parent)
		local owner = self:GetOwner(self.RootOwner)

		owner = try_viewmodel(owner)

		if owner:IsValid() then
			return self:CalcEyeAngles(owner):Forward():Dot(self:GetVelocity(owner))
		end

		return 0
	end,
	owner_velocity_right = function(self, parent)
		local owner = self:GetOwner(self.RootOwner)

		owner = try_viewmodel(owner)

		if owner:IsValid() then
			return self:CalcEyeAngles(owner):Right():Dot(self:GetVelocity(owner))
		end

		return 0
	end,
	owner_velocity_up = function(self, parent)
		local owner = self:GetOwner(self.RootOwner)

		owner = try_viewmodel(owner)

		if owner:IsValid() then
			return self:CalcEyeAngles(owner):Up():Dot(self:GetVelocity(owner))
		end

		return 0
	end,


	-- outfit owner vel increase
	owner_velocity_length_increase = function(self, parent)
		local owner = self:GetOwner(self.RootOwner)

		owner = try_viewmodel(owner)

		if owner:IsValid() then
			local vel = self:GetVelocity(owner):Length()
			self.ov_length_i = (self.ov_length_i or 0) + vel * FrameTime()
			return self.ov_length_i
		end

		return 0
	end,
	owner_velocity_forward_increase = function(self, parent)
		local owner = self:GetOwner(self.RootOwner)

		owner = try_viewmodel(owner)

		if owner:IsValid() then
			local vel = self:CalcEyeAngles(owner):Forward():Dot(self:GetVelocity(owner))
			self.ov_forward_i = (self.ov_forward_i or 0) + vel * FrameTime()
			return self.ov_forward_i
		end

		return 0
	end,
	owner_velocity_right_increase = function(self, parent)
		local owner = self:GetOwner(self.RootOwner)

		owner = try_viewmodel(owner)

		if owner:IsValid() then
			local vel = self:CalcEyeAngles(owner):Right():Dot(self:GetVelocity(owner))
			self.ov_right_i = (self.ov_right_i or 0) + vel * FrameTime()
			return self.ov_right_i
		end

		return 0
	end,
	owner_velocity_up_increase = function(self, parent)
		local owner = self:GetOwner(self.RootOwner)

		owner = try_viewmodel(owner)

		if owner:IsValid() then
			local vel = self:CalcEyeAngles(owner):Up():Dot(self:GetVelocity(owner))
			self.ov_up_i = (self.ov_up_i or 0) + vel * FrameTime()
			return self.ov_up_i
		end

		return 0
	end,

	-- parent part
	parent_velocity_length = function(self, parent)
		if not self.TargetPart:IsValid() then
			repeat
				if not parent.Parent:IsValid() then break end
				parent = parent.Parent
			until not parent.cached_pos:IsZero()
		end

		return self:GetVelocity(parent):Length()
	end,
	parent_velocity_forward = function(self, parent)
		if not self.TargetPart:IsValid() then
			repeat
				if not parent.Parent:IsValid() then break end
				parent = parent.Parent
			until not parent.cached_pos:IsZero()
		end

		return -parent.cached_ang:Forward():Dot(self:GetVelocity(parent))
	end,
	parent_velocity_right = function(self, parent)
		if not self.TargetPart:IsValid() then
			repeat
				if not parent.Parent:IsValid() then break end
				parent = parent.Parent
			until not parent.cached_pos:IsZero()
		end

		return parent.cached_ang:Right():Dot(self:GetVelocity(parent))
	end,
	parent_velocity_up = function(self, parent)
		if not self.TargetPart:IsValid() then
			repeat
				if not parent.Parent:IsValid() then break end
				parent = parent.Parent
			until not parent.cached_pos:IsZero()
		end

		return parent.cached_ang:Up():Dot(self:GetVelocity(parent))
	end,

	parent_scale_x = function(self, parent)
		if not self.TargetPart:IsValid() then
			if parent:HasParent() then
				parent = parent:GetParent()
			end
		end

		if parent:IsValid() then
			return parent.Scale and parent.Scale.x*parent.Size or 1
		end

		return 1
	end,
	parent_scale_y = function(self, parent)
		if not self.TargetPart:IsValid() then
			if parent:HasParent() then
				parent = parent:GetParent()
			end
		end

		if parent:IsValid() then
			return parent.Scale and parent.Scale.y*parent.Size or 1
		end

		return 1
	end,
	parent_scale_z = function(self, parent)
		if not self.TargetPart:IsValid() then
			if parent:HasParent() then
				parent = parent:GetParent()
			end
		end

		if parent:IsValid() then
			return parent.Scale and parent.Scale.z*parent.Size or 1
		end

		return 1
	end,

	command = function(self, index)
		local ply = self:GetPlayerOwner()
		local events = ply.pac_proxy_events

		if events then
			for key, data in pairs(events) do
				if pac.HandlePartName(ply, data.name) == self.Name then

					data.x = data.x or 0
					data.y = data.y or 0
					data.z = data.z or 0

					return data.x, data.y, data.z
				end
			end
		end

		return 0, 0, 0
	end,

	voice_volume = function(self)
		local ply = self:GetPlayerOwner()

		return ply:VoiceVolume()
	end,

	light_amount_r = function(self, parent)
		parent = self:GetParentEx()

		if parent:IsValid() then
			return render.GetLightColor(parent.cached_pos):ToColor().r
		end

		return 0
	end,
	light_amount_g = function(self, parent)
		parent = self:GetParentEx()

		if parent:IsValid() then
			return render.GetLightColor(parent.cached_pos):ToColor().g
		end

		return 0
	end,
	light_amount_b = function(self, parent)
		parent = self:GetParentEx()

		if parent:IsValid() then
			return render.GetLightColor(parent.cached_pos):ToColor().b
		end

		return 0
	end,
	light_value = function(self, parent)
		parent = self:GetParentEx()

		if parent:IsValid() then
			local h, s, v = ColorToHSV(render.GetLightColor(parent.cached_pos):ToColor())
			return v
		end

		return 0
	end,

	ambient_light_r = function(self, parent)
		parent = self:GetParentEx()

		if parent:IsValid() then
			return render.GetAmbientLightColor():ToColor().r
		end

		return 0
	end,
	ambient_light_g = function(self, parent)
		parent = self:GetParentEx()

		if parent:IsValid() then
			return render.GetAmbientLightColor():ToColor().g
		end

		return 0
	end,
	ambient_light_b = function(self, parent)
		parent = self:GetParentEx()

		if parent:IsValid() then
			return render.GetAmbientLightColor():ToColor().b
		end

		return 0
 	end,

	owner_health = function(self)
		local owner = self:GetPlayerOwner()

		if owner:IsValid() then
			return owner:Health()
		end

		return 0
	end,
	owner_max_health = function(self)
		local owner = self:GetPlayerOwner()

		if owner:IsValid() then
			return owner:GetMaxHealth()
		end

		return 0
	end,
	owner_armor = function(self)
		local owner = self:GetPlayerOwner()

		if owner:IsValid() then
			return owner:Armor()
		end

		return 0
	end,
	owner_total_ammo = function(self, parent, id)
		local owner = self:GetPlayerOwner()
		id = id and id:lower()

		if owner:IsValid() then
			return (owner.GetAmmoCount and id) and owner:GetAmmoCount(id) or 0
		end

		return 0
	end,

	player_color_r = function(self)
		local owner = self:GetPlayerOwner()

		if owner:IsValid() then
			return owner:GetPlayerColor().r
		end

		return 1
	end,
	player_color_g = function(self)
		local owner = self:GetPlayerOwner()

		if owner:IsValid() then
			return owner:GetPlayerColor().g
		end

		return 1
	end,
	player_color_b = function(self)
		local owner = self:GetPlayerOwner()

		if owner:IsValid() then
			return owner:GetPlayerColor().b
		end

		return 1
	end,

	weapon_color_r = function(self)
		local owner = self:GetPlayerOwner()

		if owner:IsValid() then
			return owner:GetWeaponColor().r
		end

		return 1
	end,
	weapon_color_g = function(self)
		local owner = self:GetPlayerOwner()

		if owner:IsValid() then
			return owner:GetWeaponColor().g
		end

		return 1
	end,
	weapon_color_b = function(self)
		local owner = self:GetPlayerOwner()

		if owner:IsValid() then
			return owner:GetWeaponColor().b
		end

		return 1
	end,

	weapon_primary_ammo = function(self)
		local owner = self:GetOwner(true)

		if owner:IsValid() then
			owner = owner.GetActiveWeapon and owner:GetActiveWeapon() or owner

			return owner.Clip1 and owner:Clip1() or 0
		end

		return 0
	end,
	weapon_primary_total_ammo = function(self)
		local owner = self:GetOwner(true)

		if owner:IsValid() then
			local wep = owner.GetActiveWeapon and owner:GetActiveWeapon() or owner

			return (wep.GetPrimaryAmmoType and owner.GetAmmoCount) and owner:GetAmmoCount(wep:GetPrimaryAmmoType()) or 0
		end

		return 0
	end,
	weapon_primary_clipsize = function(self)
		local owner = self:GetOwner(true)

		if owner:IsValid() then
			owner = owner.GetActiveWeapon and owner:GetActiveWeapon() or owner

			return owner.GetMaxClip1 and owner:GetMaxClip1() or 0
		end

		return 0
	end,
	weapon_secondary_ammo = function(self)
		local owner = self:GetOwner(true)

		if owner:IsValid() then
			owner = owner.GetActiveWeapon and owner:GetActiveWeapon() or owner

			return owner.Clip2 and owner:Clip2() or 0
		end

		return 0
	end,
	weapon_secondary_total_ammo = function(self)
		local owner = self:GetOwner(true)

		if owner:IsValid() then
			local wep = owner.GetActiveWeapon and owner:GetActiveWeapon() or owner

			return (wep.GetSecondaryAmmoType and owner.GetAmmoCount) and owner:GetAmmoCount(wep:GetSecondaryAmmoType()) or 0
		end

		return 0
	end,
	weapon_secondary_clipsize = function(self)
		local owner = self:GetOwner(true)

		if owner:IsValid() then
			owner = owner.GetActiveWeapon and owner:GetActiveWeapon() or owner

			return owner.GetMaxClip2 and owner:GetMaxClip2() or 0
		end

		return 0
	end,

	hsv_to_color = function(self, parent, h, s, v)
		h = tonumber(h) or 0
		s = tonumber(s) or 1
		v = tonumber(v) or 1

		local c = HSVToColor(h%360, s, v)

		return c.r, c.g, c.b
	end,

	lerp = function(self, parent, m, a, b)
		m = tonumber(m) or 0
		a = tonumber(a) or -1
		b = tonumber(b) or 1

		return (b - a) * m + a
	end,
}

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

function PART:CheckLastVar(parent)
	if self.last_var ~= self.VariableName then
		if self.last_var then
			parent[self.set_key](parent, self.last_var_val)
		end
		self.last_var = self.VariableName
		self.last_var_val = parent[self.get_key](parent)
	end
end

local allowed =
{
	number = true,
	Vector = true,
	Angle = true,
	boolean = true,
}

function PART:SetExpression(str)
	self.Expression = str
	self.ExpressionFunc = nil

	if str and str ~= "" then
		local parent = self.Parent

		if not parent:IsValid() then return end

		local parentx = self.TargetPart

		if not parentx:IsValid() then
			parentx = parent
		end

		local lib = {}

		for name, func in pairs(PART.Inputs) do
			lib[name] = function(...) return func(self, parentx, ...) end
		end

		local ok, res = pac.CompileExpression(str, lib)
		if ok then
			self.ExpressionFunc = res
			self.ExpressionError = nil
		else
			self.ExpressionFunc = true
			self.ExpressionError = res
		end
	end
end

function PART:OnHide()
	self.time = nil
	self.vec_additive = Vector()

	if self.ResetVelocitiesOnHide then
		self.last_vel = nil
		self.last_pos = nil
		self.last_vel_smooth = nil
	end
end

function PART:OnShow()
	self.time = nil
	self.vec_additive = Vector()
end

local function set(self, part, x, y, z, children)
	local T = type(part[self.VariableName])

	if allowed[T] then
		if T == "boolean" then

			x = x or part[self.VariableName] == true and 1 or 0
			part[self.set_key](part, tonumber(x) > 0)

		elseif T == "number" then

			x = x or part[self.VariableName]
			part[self.set_key](part, tonumber(x) or 0)

		else
			local val = part[self.VariableName]

			if self.Axis ~= "" and val[self.Axis] then
				val[self.Axis] = x
			else
				if T == "Angle" then
					val.p = x or val.p
					val.y = y or val.y
					val.r = z or val.r
				elseif T == "Vector" then
					val.x = x or val.x
					val.y = y or val.y
					val.z = z or val.z
				end
			end

			part[self.set_key](part, val)
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
	local parent = self:GetParent()

	if not parent:IsValid() then return end

	local parentx = self.TargetPart
	self:CalcVelocity()

	local ExpressionFunc = self.ExpressionFunc

	if not ExpressionFunc then
		self:SetExpression(self.Expression)
		ExpressionFunc = self.ExpressionFunc
	end

	if not parentx:IsValid() then
		parentx = parent
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

		if self.AffectChildren then
			for _, part in ipairs(self:GetChildren()) do
				set(self, part, x, y, z, true)
			end
		else
			set(self, parent, x, y, z)
		end

		if pace and pace.IsActive() then

			local str = ""

			if x then str = str .. math.Round(x, 3) end
			if y then str = str .. ", " .. math.Round(y, 3) end
			if z then str = str .. ", " .. math.Round(z, 3) end

			self.debug_var = str
		end
	else

		local F = self.Functions[self.Function]
		local I = self.Inputs[self.Input]

		if F and I then
			local num = self.Min + (self.Max - self.Min) * ((F(((I(self, parentx) / self.InputDivider) + self.Offset) * self.InputMultiplier, self) + 1) / 2) ^ self.Pow

			if self.Additive then
				self.vec_additive[1] = (self.vec_additive[1] or 0) + num
				num = self.vec_additive[1]
			end

			if self.AffectChildren then
				for _, part in ipairs(self:GetChildren()) do
					set(self, part, num, nil, nil, true)
				end
			else
				set(self, parent, num)
			end

			if pace and pace.IsActive() then
				self.debug_var = math.Round(num, 3)
			end
		end
	end

end

pac.RegisterPart(PART)