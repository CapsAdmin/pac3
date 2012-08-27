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
	pac.GetSet(PART, "VariableName", "")
	pac.GetSet(PART, "Axis", "")
pac.EndStorableVars()

PART.Functions = 
{
	none = function(n) return n end,
	sin = math.sin,
	cos = math.cos,
	tan = math.tan,	
}

PART.Inputs =
{
	time = RealTime,
	synced_time = CurTime,
	camera_distance = function(s, p) return p.cached_pos:Distance(pac.EyePos) end,
	angle_distance = function(s, p) return math.Clamp(math.abs(pac.EyeAng:Forward():DotProduct((p.cached_pos - pac.EyePos):Normalize())) - 0.5, 0, 1) end,
	owner_speed = function(s, p) return p:GetOwner():GetVelocity():Length() end,
}

function PART:OnThink()
	local parent = self.Parent
	local T = type(parent[self.VariableName])
	
	if T == "number" or T == "Vector" or T == "Angle" then
		local F = self.Functions[self.Function]
		local I = self.Inputs[self.Input]
		
		if F and I then
			local num = self.Min + (self.Max - self.Min) * ((F(((I(self, parent) / self.InputDivider) + self.Offset) * self.InputMultiplier) + 1) / 2)
			
			if T == "number" then
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
				parent["Set" .. self.VariableName](parent, val)
			end		
		end
	end
end

pac.RegisterPart(PART)