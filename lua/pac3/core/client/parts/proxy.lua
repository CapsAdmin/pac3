local PART = {}

PART.ClassName = "proxy"
PART.NonPhysical = true
PART.ThinkTime = 0

pac.StartStorableVars()
	pac.GetSet(PART, "VariableName", "")
	pac.GetSet(PART, "Expression", "")
	pac.GetSet(PART, "RootOwner", false)
	pac.GetSet(PART, "Additive", false)

	pac.GetSet(PART, "Input", "time")
	pac.GetSet(PART, "Function", "sin")
	pac.GetSet(PART, "Offset", 0)
	pac.GetSet(PART, "InputMultiplier", 1)
	pac.GetSet(PART, "InputDivider", 1)
	pac.GetSet(PART, "Min", 0)
	pac.GetSet(PART, "Max", 1)
	pac.GetSet(PART, "Pow", 1)
	pac.GetSet(PART, "Axis", "")
pac.EndStorableVars()

function PART:Initialize()
	self.vec_additive = {}
	self.last_vel = Vector()
	self.last_vel_smooth = Vector()
	self.last_pos = Vector()
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
}

local FrameTime = FrameTime

function PART:CalcVelocity()
	self.last_vel_smooth = (self.last_vel_smooth + (self.last_vel - self.last_vel_smooth) * FrameTime() * 10)
end

function PART:GetVelocity(part)
	local pos = part.cached_pos

	if not pos or pos == Vector() then
		if IsEntity(part) then
			pos = part:GetPos()
		else
			pos = part:GetOwner():GetPos()
		end
	end

	local time = RealTime()

	if self.next_vel_calc < time then
		self.next_vel_calc = time + 0.1
		self.last_vel = self.last_pos - pos
		self.last_pos = pos
	end

	return self.last_vel_smooth / 5
end

PART.Inputs =
{
	time = RealTime,
	synced_time = CurTime,
	random = function(s, p)
		return math.random()
	end,
	timeex = function(s, p)
		s.time = s.time or RealTime()
		
		return RealTime() - s.time
	end,

	eye_position_distance = function(self, parent)
		return parent.cached_pos:Distance(pac.EyePos)
	end,
	eye_angle_distance = function(self, parent)
		return math.Clamp(math.abs(pac.EyeAng:Forward():DotProduct((parent.cached_pos - pac.EyePos):GetNormalized())) - 0.5, 0, 1)
	end,

	aim_length = function(self, parent)
		local owner = self:GetOwner(self.RootOwner)

		if owner:IsValid() then
			local res = util.QuickTrace(owner:EyePos(), owner:EyeAngles():Forward() * 16000, {owner, owner:GetParent()})

			return res.StartPos:Distance(res.HitPos)
		end

		return 0
	end,
	aim_length_fraction = function(self, parent)
		local owner = self:GetOwner(self.RootOwner)

		if owner:IsValid() then
			local res = util.QuickTrace(owner:EyePos(), owner:EyeAngles():Forward() * 16000, {owner, owner:GetParent()})

			return res.Fraction
		end

		return 0
	end,

	owner_eye_angle_pitch = function(self, parent)
		local owner = self:GetOwner(self.RootOwner)

		if owner:IsValid() then
			local n = owner:EyeAngles().p
			return -(1 + math.NormalizeAngle(n) / 89) / 2 + 1
		end

		return 0
	end,
	owner_eye_angle_yaw = function(self, parent)
		local owner = self:GetOwner(self.RootOwner)

		if owner:IsValid() then
			local n = owner:EyeAngles().y
			return math.NormalizeAngle(n)/90
		end

		return 0
	end,
	owner_eye_angle_roll = function(self, parent)
		local owner = self:GetOwner(self.RootOwner)

		if owner:IsValid() then
			local n = owner:EyeAngles().r
			return math.NormalizeAngle(n)/90
		end

		return 0
	end,

	-- outfit owner
	owner_velocity_length = function(self, parent)
		local owner = self:GetOwner(self.RootOwner)

		if owner:IsValid() then
			return self:GetVelocity(parent:GetOwner(self.RootOwner)):Length()
		end

		return 0
	end,
	owner_velocity_forward = function(self, parent)
		local owner = self:GetOwner(self.RootOwner)

		if owner:IsValid() then
			return owner:EyeAngles():Forward():Dot(self:GetVelocity(parent))
		end

		return 0
	end,
	owner_velocity_right = function(self, parent)
		local owner = self:GetOwner(self.RootOwner)

		if owner:IsValid() then
			return owner:EyeAngles():Right():Dot(self:GetVelocity(parent))
		end

		return 0
	end,
	owner_velocity_up = function(self, parent)
		local owner = self:GetOwner(self.RootOwner)

		if owner:IsValid() then
			return owner:EyeAngles():Up():Dot(self:GetVelocity(parent))
		end

		return 0
	end,

	-- parent part
	parent_velocity_length = function(self, parent)
		repeat
			if not parent.Parent:IsValid() then break end
			parent = parent.Parent
		until parent.cached_pos ~= vector_origin

		return self:GetVelocity(parent):Length()
	end,
	parent_velocity_forward = function(self, parent)
		repeat
			if not parent.Parent:IsValid() then break end
			parent = parent.Parent
		until parent.cached_pos ~= vector_origin

		return -parent.cached_ang:Forward():Dot(self:GetVelocity(parent))
	end,
	parent_velocity_right = function(self, parent)
		repeat
			if not parent.Parent:IsValid() then break end
			parent = parent.Parent
		until parent.cached_pos ~= vector_origin

		return parent.cached_ang:Right():Dot(self:GetVelocity(parent))
	end,
	parent_velocity_up = function(self, parent)
		repeat
			if not parent.Parent:IsValid() then break end
			parent = parent.Parent
		until parent.cached_pos ~= vector_origin

		return parent.cached_ang:Up():Dot(self:GetVelocity(parent))
	end,

	command = function(self)
		local ply = self:GetPlayerOwner()
		local data = ply.pac_proxy_event

		if data and data.name == self:GetName() then
			self.last_command_proxy_num = data.num
			return data.num
		end

		return self.last_command_proxy_num or 0
	end,

	voice_volume = function(self)
		local ply = self:GetPlayerOwner()

		return ply:VoiceVolume()
	end,

	light_amount_r = function(self, parent)
		parent = parent.Parent

		if parent:IsValid() then
			return render.GetAmbientLightColor(parent.cached_pos) * render.GetLightColor(parent.cached_pos).r
		end
	end,

	light_amount_g = function(self, parent)
		parent = parent.Parent

		if parent:IsValid() then
			return render.GetAmbientLightColor(parent.cached_pos) * render.GetLightColor(parent.cached_pos).g
		end
	end,

	light_amount_b = function(self, parent)
		parent = parent.Parent

		if parent:IsValid() then
			return render.GetAmbientLightColor(parent.cached_pos) * render.GetLightColor(parent.cached_pos).b
		end
	end,

	owner_health = function(self)
		local owner = self:GetOwner(self.RootOwner)

		if owner:IsValid() then
			return owner:Health()
		end

		return 0
	end,

	owner_armor = function(self)
		local owner = self:GetOwner(self.RootOwner)

		if owner:IsValid() then
			return owner:Armor()
		end

		return 0
	end,
	
	player_color_r = function(self)
		local vec = self:GetOwner(self.RootOwner)
		
		if owner:IsValid() and owner:IsPlayer() then
			local vec = Vector(GetConVarString("cl_playercolor"))
			
			return vec.r
		end
		
		return 1
	end,
	player_color_g = function(self)
		local vec = self:GetOwner(self.RootOwner)
		
		if owner:IsValid() and owner:IsPlayer() then
			local vec = Vector(GetConVarString("cl_playercolor"))
			
			return vec.g
		end
		
		return 1
	end,	
	player_color_b = function(self)
		local vec = self:GetOwner(self.RootOwner)
		
		if owner:IsValid() and owner:IsPlayer() then
			local vec = Vector(GetConVarString("cl_playercolor"))
			
			return vec.b
		end
		
		return 1
	end,
}

usermessage.Hook("pac_proxy", function(umr)
	local ply = umr:ReadEntity()
	local str = umr:ReadString()
	local num = umr:ReadFloat()

	if ply:IsValid() then
		ply.pac_proxy_event = {name = str, num = num}
	end
end)

function PART:CheckLastVar(parent)
	if self.last_var ~= self.VariableName then
		if self.last_var then
			parent["Set" .. self.VariableName](parent, self.last_var_val)
		end
		self.last_var = self.VariableName
		self.last_var_val = parent["Get" .. self.VariableName](parent)
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
		if not self.Parent:IsValid() then return end

		local lib = {}

		for name, func in pairs(PART.Inputs) do
			lib[name] = function() return func(self, parent) end
		end

		local ok, res = pac.CompileExpression(str, lib)
		if ok then
			self.ExpressionFunc = res
		else
			print(res)
		end
	end
end

function PART:OnHide()
	self.time = nil
	self.vec_additive = Vector()
end

function PART:OnShow()
	self.time = nil
	self.vec_additive = Vector()
end

function PART:OnThink()
	self:CalcVelocity()

	if self:IsHiddenEx() then return end

	local parent = self.Parent
	if not parent:IsValid() then return end

	if not self.ExpressionFunc then
		self:SetExpression(self.Expression)
	end

	if self.ExpressionFunc then
		local T = type(parent[self.VariableName])

		if allowed[T] then
			local ok, x,y,z = pcall(self.ExpressionFunc)

			if not ok then
				if self:GetPlayerOwner() == LocalPlayer() then
					ErrorNoHalt(x .. "\n")
				end
				return
			end

			if T == "boolean" then

				x = x or parent[self.VariableName] == true and 1 or 0
				parent["Set" .. self.VariableName](parent, tonumber(x) > 0)

			elseif T == "number" then

				if self.Additive then
					self.vec_additive[1] = (self.vec_additive[1] or 0) + x
					x = self.vec_additive[1]
				end

				x = x or parent[self.VariableName]
				parent["Set" .. self.VariableName](parent, tonumber(x) or 0)

			else
				local val = parent[self.VariableName]

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

				if T == "Angle" then
					val.p = x or val.p
					val.y = y or val.y
					val.r = z or val.r
				else
					val.x = x or val.x
					val.y = y or val.y
					val.z = z or val.z
				end

				parent["Set" .. self.VariableName](parent, val)
			end
		end
	else
		local T = type(parent[self.VariableName])

		if allowed[T] then
			local F = self.Functions[self.Function]
			local I = self.Inputs[self.Input]

			if F and I then
				local num = self.Min + (self.Max - self.Min) * ((F(((I(self, parent) / self.InputDivider) + self.Offset) * self.InputMultiplier, self) + 1) / 2) ^ self.Pow

				if self.Additive then
					self.vec_additive[1] = (self.vec_additive[1] or 0) + num
					num = self.vec_additive[1]
				end

				if T == "boolean" then
					parent["Set" .. self.VariableName](parent, tonumber(num) > 0)
				elseif T == "number" then
					parent["Set" .. self.VariableName](parent, tonumber(num) or 0)
				else
					local val = parent[self.VariableName]
					if self.Axis ~= "" and val[self.Axis] then
						val[self.Axis] = num
					else
						if T == "Angle" then
							val.p = num
							val.y = num
							val.r = num
						else
							val.x = num
							val.y = num
							val.z = num
						end
					end

					parent["Set" .. self.VariableName](parent, val)
				end
			end
		end
	end
end

pac.RegisterPart(PART)