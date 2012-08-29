local PART = {}

PART.ClassName = "proxy"
PART.NonPhysical = true
PART.ThinkTime = 0

pac.StartStorableVars()
	pac.GetSet(PART, "InputMultiplier", 1)
	pac.GetSet(PART, "Min", 0)
	pac.GetSet(PART, "Max", 1)
	pac.GetSet(PART, "Offset", 0)
	pac.GetSet(PART, "Function", "sin")
	pac.GetSet(PART, "Input", "time")
	pac.GetSet(PART, "InputDivider", 1)
	pac.GetSet(PART, "Pow", 1)
	pac.GetSet(PART, "VariableName", "")
	pac.GetSet(PART, "Axis", "")
pac.EndStorableVars()

PART.Functions = 
{
	none = function(n) return n end,
	sin = math.sin,
	cos = math.cos,
	tan = math.tan,
	mod = function(n, s) return n%s.Max end,
}

local function getvel(e)
	if e.IsPACEntity then
		
	end
end

PART.Inputs =
{
	time = RealTime,
	synced_time = CurTime,
	camera_distance = function(s, p) return p.cached_pos:Distance(pac.EyePos) end,
	angle_distance = function(s, p) return math.Clamp(math.abs(pac.EyeAng:Forward():DotProduct((p.cached_pos - pac.EyePos):GetNormalized())) - 0.5, 0, 1) end,
	owner_speed = function(s, p) return p:GetOwner():GetVelocity():Length() end,
	owner_speed_ex = function(s, p) s.owner_speed_ex = (s.owner_speed_ex or 0) + p:GetOwner():GetVelocity():Length() return s.owner_speed_ex end,
	parent_speed = function(s, p)
		p = p.Parent
		if not p:IsValid() then return 0 end
		local diff = p.cached_pos - (p.last_pos or Vector(0,0,0))
		p.last_pos = p.cached_pos
		
		p.last_vel_smooth = p.last_vel_smooth or 0
		p.last_vel_smooth = (p.last_vel_smooth + (diff:Length() - p.last_vel_smooth) * FrameTime() * 4)
		
		return p.last_vel_smooth
	end,
	parent_speed_ex = function(s, p)
		p = p.Parent
		if not p:IsValid() then return 0 end
		local diff = p.cached_pos - (p.last_pos or Vector(0,0,0))
		p.last_pos = p.cached_pos
		
		p.last_vel_smooth = p.last_vel_smooth or 0
		p.last_vel_smooth = (p.last_vel_smooth + (diff:Length() - p.last_vel_smooth) * FrameTime() * 4)
		
		s.parent_speed_ex = (s.parent_speed_ex or 0) + p.last_vel_smooth
		
		return s.parent_speed_ex
	end,
	local_parent_speed = function(s, p)
		p = p.Parent
		local ent = p:GetPlayerOwner()
		local pos = 0
		
		if ent:IsValid() then
			pos = p:GetPlayerOwner():EyePos():Distance(p.cached_pos)
		end
		
		local diff = math.abs(pos - (p.last_speed_ex or 0))
		p.last_speed_ex = pos
		
		p.last_vel_smooth = p.last_vel_smooth or 0
		p.last_vel_smooth = (p.last_vel_smooth + (diff - p.last_vel_smooth) * FrameTime() * 4)
			
		return p.last_vel_smooth - 1
	end,
}

function PART:CheckLastVar(parent)
	if self.last_var ~= self.VariableName then
		if self.last_var then
			parent["Set" .. self.VariableName](parent, self.last_var_val)
		end
		self.last_var = self.VariableName
		self.last_var_val = parent["Get" .. self.VariableName](parent)
	end	
end

function PART:OnThink()
	local parent = self.Parent
	if not parent:IsValid() then return end
	
	local T = type(parent[self.VariableName])
	
	if T == "number" or T == "Vector" or T == "Angle" then
		local F = self.Functions[self.Function]
		local I = self.Inputs[self.Input]
		
		if F and I then
			local num = self.Min + (self.Max - self.Min) * ((F(((I(self, parent) / self.InputDivider) + self.Offset) * self.InputMultiplier, self) + 1) / 2) ^ self.Pow
			
			if T == "number" then
				--self:CheckLastVar(parent)
				parent["Set" .. self.VariableName](parent, num)
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
				
				--self:CheckLastVar(parent)
				parent["Set" .. self.VariableName](parent, val)
			end		
		end
	end
end

pac.RegisterPart(PART)