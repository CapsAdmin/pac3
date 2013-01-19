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

local function calc_velocity(part)
	if IsEntity(part) and part:IsValid() then
		return part:GetVelocity()
	end

	local diff = part.cached_pos - (part.last_pos or Vector(0, 0, 0))
	part.last_pos = part.cached_pos

	part.last_vel_smooth = part.last_vel_smooth or Vector(0, 0, 0)
	part.last_vel_smooth = (part.last_vel_smooth + (diff - part.last_vel_smooth) * FrameTime() * 4)
	
	return part.last_vel_smooth
end

PART.Inputs =
{
	time = RealTime,
	synced_time = CurTime,
	random = function(s, p)
		return math.random()
	end,
	timeex = function(s, p)
		s.time = s.time or 0
		s.time = s.time + (FrameTime() * 60)
		
		return s.time
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
			return parent:GetOwner(self.RootOwner):GetVelocity():Length() 
		end
		
		return 0
	end,
	owner_velocity_forward = function(self, parent) 
		local owner = self:GetOwner(self.RootOwner)
		
		if owner:IsValid() then 
			return owner:EyeAngles():Forward():Dot(calc_velocity(parent))
		end
		
		return 0
	end,
	owner_velocity_right = function(self, parent) 
		local owner = self:GetOwner(self.RootOwner)
		
		if owner:IsValid() then 
			return owner:EyeAngles():Right():Dot(calc_velocity(parent))
		end
		
		return 0
	end,
	owner_velocity_up = function(self, parent) 
		local owner = self:GetOwner(self.RootOwner)
		
		if owner:IsValid() then 
			return owner:EyeAngles():Up():Dot(calc_velocity(parent))
		end
		
		return 0
	end,
	
	-- parent part
	parent_velocity_length = function(self, parent) 
		parent = parent.Parent
		
		if parent:IsValid() then
			return calc_velocity(parent):Length()
		end
		
		return 0
	end,
	parent_velocity_forward = function(self, parent) 
		parent = parent.Parent
		
		if parent:IsValid() then
			return parent.cached_ang:Forward():Dot(calc_velocity(parent))
		end
		
		return 0
	end,
	parent_velocity_right = function(self, parent) 
		parent = parent.Parent
		
		if parent:IsValid() then
			return parent.cached_ang:Right():Dot(calc_velocity(parent))
		end
		
		return 0
	end,
	parent_velocity_up = function(self, parent) 
		parent = parent.Parent
		
		if parent:IsValid() then 
			return parent.cached_ang:Up():Dot(calc_velocity(parent))
		end
		
		return 0
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
		if not self.Parent:IsValid() then self.needs_compiliation = true return end
	
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

function PART:OnParent()
	self.needs_compiliation = true
end

function PART:OnHide()
	self.time = 0
end

function PART:OnThink()
	if self:IsHiddenEx() then return end
	
	local parent = self.Parent
	if not parent:IsValid() then return end
	
	if self.needs_compiliation then
		self:SetExpression(self.Expression)
		self.needs_compiliation = false
	end
	
	if self.ExpressionFunc then
		local T = type(parent[self.VariableName])
		
		if allowed[T] then
			local ok, x,y,z = pcall(self.ExpressionFunc)
			
			if not ok then
				if self:GetPlayerOwner() == LocalPlayer() then	
					ErrorNoHalt(x.."\n")
				end
			end
			
			if T == "boolean" then
				x = x or parent["Get" .. self.VariableName] == true and 1 or 0
				parent["Set" .. self.VariableName](parent, tonumber(x) > 0)
			elseif T == "number" then
							
				if self.Additive then	
					self.vec_additive[1] = (self.vec_additive[1] or 0) + x
					x = self.vec_additive[1]
				end
			
				x = x or parent["Get" .. self.VariableName]
				parent["Set" .. self.VariableName](parent, tonumber(x))
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
					parent["Set" .. self.VariableName](parent, tonumber(num))
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