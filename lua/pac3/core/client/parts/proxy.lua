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
		end, description = "What property of the target part should be changed.\nYou don't need to follow the list builder if you know what you're doing with target parts."})

		BUILDER:GetSet("RootOwner", false)
		BUILDER:GetSetPart("TargetPart", {description = "send output to an external part. supports name and uid"})
		BUILDER:GetSet("MultipleTargetParts", "", {description = "send output to multiple external partss.\npaste multiple UIDs or names here, separated by semicolons. With bulk select, you can select parts and right click to get that done quickly.."})
		BUILDER:GetSetPart("OutputTargetPart", {hide_in_editor = true})
		BUILDER:GetSet("AffectChildren", false)
		BUILDER:GetSet("Expression", "", {description = "write math here. hit F1 for a tutorial or right click for examples.", editor_panel = "code_proxy"})

	BUILDER:SetPropertyGroup("easy setup")
		BUILDER:GetSet("Input", "time", {enums = function(part) return part.Inputs end, description = "base (inner) function for easy setup\nin sin(time()) it is time"})
		BUILDER:GetSet("Function", "sin", {enums = function(part) return part.Functions end, description = "processing (outer) function for easy setup.\nin sin(time()) it is sin"})
		BUILDER:GetSet("Axis", "", {description = "The direction where the output ends up.\nx,y,z for vectors, p,y,r or r,g,b for colors\nIf you provide an expression with vector notation content, it will expand to the next axes. for example \"0,1,2\" on y will put 0 on y and 1 on z, 2 will overflow to nowhere."})
		BUILDER:GetSet("Min", 0)
		BUILDER:GetSet("Max", 1)
		BUILDER:GetSet("Offset", 0)
		BUILDER:GetSet("InputMultiplier", 1)
		BUILDER:GetSet("InputDivider", 1)
		BUILDER:GetSet("Pow", 1)

	BUILDER:SetPropertyGroup("behavior")
		BUILDER:GetSet("Additive", false, {description = "This means that every computation frame, the proxy will add its output to its current stored memory. This can quickly get out of control if you don't know what you're doing! This is like using the feedback() function"})
		BUILDER:GetSet("PlayerAngles", false, {description = "For some functions/inputs (eye angles, owner velocity increases, aim length) it will choose between the owner entity's Angles or EyeAngles. Unsure of whether this makes a difference."})
		BUILDER:GetSet("ZeroEyePitch", false, {description = "For some functions/inputs (eye angles, owner velocity increases, aim length) it will force the angle to be horizon level."})
		BUILDER:GetSet("ResetVelocitiesOnHide", true, {description = "Because velocity calculators use smoothing that makes the output converge toward a crude rolling average, it might matter whether you want to get a clean slate readout.\n(VelocityRoughness is how close to the snapshots it will be. Lower means smoother but delayed. Higher means less smoothing but it might overshoot and be inaccurate because of frame time works and varies)"})
		BUILDER:GetSet("VelocityRoughness", 10)
		BUILDER:GetSet("PreviewOutput", false, {description = "Previews the proxy's output (for yourself) next to the nearest owner entity in the game"})

	BUILDER:SetPropertyGroup("extra expressions")
		BUILDER:GetSet("ExpressionOnHide", "", {description = "Math to apply once, when the proxy is hidden. It computes once, so it will not move.", editor_panel = "code_proxy"})
		BUILDER:GetSet("Extra1", "", {description = "Write extra math here.\nIt computes before the main expression and can be accessed from the main expression as extra1() or var1() to save space, or by another proxy as extra1(\"uid or name\") or var1(\"uid or name\")", editor_panel = "code_proxy"})
		BUILDER:GetSet("Extra2", "", {description = "Write extra math here.\nIt computes before the main expression and can be accessed from the main expression as extra2() or var2() to save space, or by another proxy as extra2(\"uid or name\") or var2(\"uid or name\")", editor_panel = "code_proxy"})
		BUILDER:GetSet("Extra3", "", {description = "Write extra math here.\nIt computes before the main expression and can be accessed from the main expression as extra3() or var3() to save space, or by another proxy as extra3(\"uid or name\") or var3(\"uid or name\")", editor_panel = "code_proxy"})
		BUILDER:GetSet("Extra4", "", {description = "Write extra math here.\nIt computes before the main expression and can be accessed from the main expression as extra4() or var4() to save space, or by another proxy as extra4(\"uid or name\") or var4(\"uid or name\")", editor_panel = "code_proxy"})
		BUILDER:GetSet("Extra5", "", {description = "Write extra math here.\nIt computes before the main expression and can be accessed from the main expression as extra5() or var5() to save space, or by another proxy as extra5(\"uid or name\") or var5(\"uid or name\")", editor_panel = "code_proxy"})
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

function PART:GetOrFindCachedPart(uid_or_name)
	local part = nil
	self.erroring_cached_parts = {}
	self.found_cached_parts = self.found_cached_parts or {}
	if self.found_cached_parts[uid_or_name] then self.erroring_cached_parts[uid_or_name] = nil return self.found_cached_parts[uid_or_name] end
	if self.erroring_cached_parts[uid_or_name] then return end
	if self.bad_uid_search and self.bad_uid_search > 250 then return end

	local owner = self:GetPlayerOwner()
	part = pac.GetPartFromUniqueID(pac.Hash(owner), uid_or_name) or pac.FindPartByPartialUniqueID(pac.Hash(owner), uid_or_name)
	if not part:IsValid() then
		part = pac.FindPartByName(pac.Hash(owner), uid_or_name, self)
	else
		self.found_cached_parts[uid_or_name] = part
		return part
	end
	if not part:IsValid() then
		self.erroring_cached_parts[uid_or_name] = true
		self.bad_uid_search = self.bad_uid_search or 0
		self.bad_uid_search = self.bad_uid_search + 1
		if self:GetPlayerOwner() == LocalPlayer() then
			pace.FlashNotification("performance warning! " .. tostring(self) .. " keeps searching for parts not finding anything! " .. tostring(uid_or_name) .. " may be unused!")
		end
	else
		self.found_cached_parts[uid_or_name] = part
		return part
	end
	return part
end

function PART:SetMultipleTargetParts(str)
	self.MultipleTargetParts = str
	self.MultiTargetPart = {}
	if str == "" then self.MultiTargetPart = nil self.ExtraHermites = nil return end
	if not string.find(str, ";") then
		local part = self:GetOrFindCachedPart(str)
		if IsValid(part) then
			self:SetTargetPart(part)
			self.MultipleTargetParts = ""
		else
			timer.Simple(3, function()
				local part = self:GetOrFindCachedPart(str)
				if part then
					self:SetTargetPart(part)
					self.MultipleTargetParts = ""
				end
			end)
		end
		self.MultiTargetPart = nil
	else
		self:SetTargetPart()
		self.MultiTargetPart = {}
		self.ExtraHermites = {}
		local uid_splits = string.Split(str, ";")
		for i,uid2 in ipairs(uid_splits) do
			local part = self:GetOrFindCachedPart(uid2)
			if not IsValid(part) then
				timer.Simple(3, function()
					local part = self:GetOrFindCachedPart(uid2)
					if part then table.insert(self.MultiTargetPart, part) table.insert(self.ExtraHermites, part) end
				end)
			else table.insert(self.MultiTargetPart, part) table.insert(self.ExtraHermites, part) end
		end
		self.ExtraHermites_Property = "MultipleTargetParts"
	end

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
	self.invalid_parts_in_expression = {}
	if self:GetPlayerOwner() == pac.LocalPlayer then
		self.errors_override = true
		timer.Simple(5, function() self.errors_override = false end) --initialize hack to stop erroring when referenced parts aren't created yet but will be created shortly
	end

end

PART.Tutorials = include("pac3/editor/client/proxy_function_tutorials.lua")


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

PART.Inputs.polynomial = function(self, x, ...)
	x = x or 1
	local total = 0
	local args = { ... }

	pow = 0
	for _, coefficient in ipairs(args) do
		total = total + coefficient*math.pow(x, pow)
		pow = pow + 1
	end
	return total

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

--I'll be reusing these on sample and hold / drift
local ease_aliases = {}
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
		ease_aliases[ease] = ease
		ease_aliases["ease"..ease] = ease
		ease_aliases["ease_"..ease] = ease
	end
end

PART.Inputs.sample_and_hold = function(self, seed, duration, min, max, ease)
	if not seed then self:SetInfo("sample_and_hold's arguments are (seed, duration, min, max, ease)\nease is a string like \"linear\" \"InSine\" or \"InOutElastic\"") end
	seed = seed or 0

	min = min or 0
	max = max or 1

	duration = duration or 1
	if duration == 0 then return min + math.random()*(max-min) end

	self.samplehold = self.samplehold or {}
	self.samplehold_prev = self.samplehold_prev or {}
	self.samplehold_prev[seed] = self.samplehold_prev[seed] or {value = min, refresh = CurTime()}
	self.samplehold[seed] = self.samplehold[seed] or {value = min + math.random()*(max-min), refresh = CurTime() + duration}

	local prev = self.samplehold_prev[seed].value
	local frac = 1 - (self.samplehold[seed].refresh - CurTime()) / duration
	local delta = self.samplehold[seed].value - prev

	if CurTime() > self.samplehold[seed].refresh then
		self.samplehold_prev[seed] = self.samplehold[seed]
		self.samplehold[seed] = {value = min + math.random()*(max-min), refresh = CurTime() + duration}
	end
	if not ease then
		return self.samplehold[seed].value
	elseif ease == "lin" or ease == "linear" then
		return prev + frac * delta
	else
		local eased_frac = math.ease[ease_aliases[ease]] and math.ease[ease_aliases[ease]](frac) or 1
		return prev + eased_frac*delta
	end
end
PART.Inputs.samplehold = PART.Inputs.sample_and_hold
PART.Inputs.random_drift = PART.Inputs.sample_and_hold
PART.Inputs.drift = PART.Inputs.sample_and_hold

PART.Inputs.timeex = function(s)
	s.time = s.time or pac.RealTime

	return pac.RealTime - s.time
end

PART.Inputs.part_distance = function(self, uid1, uid2)
	if not uid1 then return 0 end
	local PartA = self:GetOrFindCachedPart(uid1)
	local PartB
	if not uid2 then
		PartB = self:GetParent()
	else
		PartB = self:GetOrFindCachedPart(uid2)
	end

	if not IsValid(PartB) then
		if uid2 then
			--second argument exists and failed to find anything, ERROR
			self.invalid_parts_in_expression[uid2] = "invalid argument " .. uid2 .. " in part_distance"
		end
	end

	if not IsValid(PartA) then --first argument exists and failed to find anything, ERROR
		self.invalid_parts_in_expression[uid1] = "invalid argument " .. uid1 .. " in part_distance"
	end

	if not IsValid(PartA) or not IsValid(PartB) then return 0 end
	if not PartA.Position or not PartB.Position then return 0 end
	self.valid_parts_in_expression[PartA] = PartA
	self.valid_parts_in_expression[PartB] = PartB
	return (PartB:GetWorldPosition() - PartA:GetWorldPosition()):Length()
end

PART.Inputs.sum = function(self, ...)
	sum = 0
	local args = { ... }
	if not args[1] then return 0 end
	for i=1,#args,1 do
		sum = sum + args[i]
	end
	return sum
end

PART.Inputs.product = function(self, ...)
	sum = 1
	local args = { ... }
	if not args[1] then return 0 end
	for i=1,#args,1 do
		sum = sum * args[i]
	end
	return sum
end

PART.Inputs.average = function(self, ...)
	sum = 0
	local args = { ... } if isvector(args[1]) then sum = vector_origin end
	if not args[1] then return 0 end
	for i=1,#args,1 do
		sum = sum + args[i]
	end
	return sum / #args
end
PART.Inputs.mean = PART.Inputs.average

PART.Inputs.median = function(self, ...)
	sum = 0
	local args = { ... } if isvector(args[1]) then sum = vector_origin end
	if not args[1] then return 0 end
	table.sort(args)
	local count = #args
	if (count % 2) == 1 then
		return args[math.floor(count/2) + 1]
	else
		return (args[count/2] + args[count/2 + 1]) / 2
	end
	return sum
end


PART.Inputs.part_pos_x = function(self, uid1)
	local PartA
	if not uid1 then --no argument, take parent
		PartA = self:GetParent()
		return PartA:GetWorldPosition().x
	else
		PartA = self:GetOrFindCachedPart(uid1)
	end

	if not IsValid(PartA) and uid1 then --first argument exists and failed to find anything, ERROR
		self.invalid_parts_in_expression[uid1] = "invalid argument " .. uid1 .. " in part_pos_x"
	end

	if not IsValid(PartA) then return 0 end
	if not PartA.Position then return 0 end
	self.valid_parts_in_expression[PartA] = PartA
	return PartA:GetWorldPosition().x
end

PART.Inputs.part_pos_y = function(self, uid1)
	local PartA
	if not uid1 then --no argument, take parent
		PartA = self:GetParent()
		return PartA:GetWorldPosition().y
	else
		PartA = self:GetOrFindCachedPart(uid1)
	end

	if not IsValid(PartA) and uid1 then --first argument exists and failed to find anything, ERROR
		self.invalid_parts_in_expression[uid1] = "invalid argument " .. uid1 .. " in part_pos_y"
	end

	if not IsValid(PartA) then return 0 end
	if not PartA.Position then return 0 end
	self.valid_parts_in_expression[PartA] = PartA
	return PartA:GetWorldPosition().y
end

PART.Inputs.part_pos_z = function(self, uid1)
	local PartA
	if not uid1 then --no argument, take parent
		PartA = self:GetParent()
		return PartA:GetWorldPosition().z
	else
		PartA = self:GetOrFindCachedPart(uid1)
	end

	if not IsValid(PartA) and uid1 then --first argument exists and failed to find anything, ERROR
		self.invalid_parts_in_expression[uid1] = "invalid argument " .. uid1 .. " in part_pos_z"
	end

	if not IsValid(PartA) then return 0 end
	if not PartA.Position then return 0 end
	self.valid_parts_in_expression[PartA] = PartA
	return PartA:GetWorldPosition().z
end

PART.Inputs.delta_x = function(self, uid1, uid2)
	if not uid1 then return 0 end
	local PartA = self:GetOrFindCachedPart(uid1)
	local PartB
	if not uid2 then
		PartB = self:GetParent()
	else
		PartB = self:GetOrFindCachedPart(uid2)
	end
	if not IsValid(PartB) then
		if uid2 then
			--second argument exists and failed to find anything, ERROR
			self.invalid_parts_in_expression[uid2] = "invalid argument " .. uid2 .. " in delta_x"
		end
	end

	if not IsValid(PartA) and uid1 then --first argument exists and failed to find anything, ERROR
		self.invalid_parts_in_expression[uid1] = "invalid argument " .. uid1 .. " in delta_x"
	end

	if not IsValid(PartA) or not IsValid(PartB) then return 0 end
	if not PartA.Position or not PartB.Position then return 0 end
	self.valid_parts_in_expression[PartA] = PartA
	self.valid_parts_in_expression[PartB] = PartB
	return PartB:GetWorldPosition().x - PartA:GetWorldPosition().x
end

PART.Inputs.delta_y = function(self, uid1, uid2)
	if not uid1 then return 0 end
	local PartA = self:GetOrFindCachedPart(uid1)
	local PartB
	if not uid2 then
		PartB = self:GetParent()
	else
		PartB = self:GetOrFindCachedPart(uid2)
	end
	if not IsValid(PartB) then
		if uid2 then
			--second argument exists and failed to find anything, ERROR
			self.invalid_parts_in_expression[uid2] = "invalid argument " .. uid2 .. " in delta_y"
		end
	end

	if not IsValid(PartA) and uid1 then --first argument exists and failed to find anything, ERROR
		self.invalid_parts_in_expression[uid1] = "invalid argument " .. uid1 .. " in delta_y"
	end

	if not IsValid(PartA) or not IsValid(PartB) then return 0 end
	if not PartA.Position or not PartB.Position then return 0 end
	self.valid_parts_in_expression[PartA] = PartA
	self.valid_parts_in_expression[PartB] = PartB
	return PartB:GetWorldPosition().y - PartA:GetWorldPosition().y
end

PART.Inputs.delta_z = function(self, uid1, uid2)
	if not uid1 then return 0 end
	local PartA = self:GetOrFindCachedPart(uid1)
	local PartB
	if not uid2 then
		PartB = self:GetParent()
	else
		PartB = self:GetOrFindCachedPart(uid2)
	end
	if not IsValid(PartB) then
		if uid2 then
			--second argument exists and failed to find anything, ERROR
			self.invalid_parts_in_expression[uid2] = "invalid argument " .. uid2 .. " in delta_z"
		end
	end

	if not IsValid(PartA) and uid1 then --first argument exists and failed to find anything, ERROR
		self.invalid_parts_in_expression[uid1] = "invalid argument " .. uid1 .. " in delta_z"
	end

	if not IsValid(PartA) or not IsValid(PartB) then return 0 end
	if not PartA.Position or not PartB.Position then return 0 end
	self.valid_parts_in_expression[PartA] = PartA
	self.valid_parts_in_expression[PartB] = PartB
	return PartB:GetWorldPosition().z - PartA:GetWorldPosition().z
end

PART.Inputs.event_alternative = function(self, uid1, num1, num2)
	if not uid1 then return 0 end
	num1 = num1 or 0
	num2 = num2 or 1
	local PartA = self:GetOrFindCachedPart(uid1)

	if not IsValid(PartA) then
		if uid1 then --first argument exists and failed to find anything, ERROR
			self.invalid_parts_in_expression[uid1] = "invalid argument: " .. uid1 .. " in event_alternative"
		end
		return 0
	end

	if PartA.ClassName == "event" then
		self.valid_parts_in_expression[PartA] = PartA
		if PartA.event_triggered then return num1 or 0
		else return num2 or 0 end
	else
		self.invalid_parts_in_expression[uid1] = "found part, but invalid class : " .. uid1 .. " : " .. tostring(PartA) .. " in event_alternative"
		return -1
	end
	return 0
end
PART.Inputs.if_else_event = PART.Inputs.event_alternative
PART.Inputs.if_event = PART.Inputs.event_alternative

--normalized sine
PART.Inputs.nsin = function(self, radians) return 0.5 + 0.5*math.sin(radians) end
--normalized sin starting at 0 with timeex
PART.Inputs.nsin2 = function(self, radians) return 0.5 + 0.5*math.sin(-math.pi/2 + radians) end
--normalized cos
PART.Inputs.ncos = function(self, radians) return 0.5 + 0.5*math.cos(radians) end
--normalized cos starting at 0 with timeex
PART.Inputs.ncos2 = function(self, radians) return 0.5 + 0.5*math.cos(-math.pi + radians) end

--easy clamp fades
--speed and two zero-crossing points (when it begins moving, when it goes back to 0)
PART.Inputs.ezfade = function(self, speed, starttime, endtime)
	speed = speed or 1
	starttime = starttime or 0
	self.time = self.time or pac.RealTime
	local timeex = pac.RealTime - self.time
	local start_offset_constant = -starttime * speed
	local result = 0

	if speed < 0 then --if negative, we can use that as a simple fadeout notation
		speed = -speed
		endtime = endtime or starttime
		if endtime == 0 then endtime = 1/speed end
		local end_offset_constant = endtime * speed
		result = math.Clamp(end_offset_constant - timeex * speed, 0, 1)
	elseif endtime == nil then --only a fadein
		result = math.Clamp(start_offset_constant + timeex * speed, 0, 1)
	else --fadein fadeout
		local end_offset_constant = endtime * speed
		result = math.Clamp(start_offset_constant + timeex * speed, 0, 1) * math.Clamp(end_offset_constant - timeex * speed, 0, 1)
	end
	return result
end

--four crossing points
PART.Inputs.ezfade_4pt = function(self, in_starttime, in_endtime, out_starttime, out_endtime)
	if not in_starttime or not in_endtime then
		if not self.errors_override then self:SetError("ezfade_4pt needs at least two arguments! (in_starttime, in_endtime, out_starttime, out_endtime)") end
		self.error = true return 0
	end -- needs at least two args. we could assume 0 starting point and first arg is fadein end, but it'll mess up the order and confuse people

	local fadein_result = 0
	local fadeout_result = 1
	local in_speed = 1
	local out_speed = 1

	self.time = self.time or pac.RealTime
	local timeex = pac.RealTime - self.time

	if in_starttime == in_endtime then
		if timeex < in_starttime then
			fadein_result = 0
		else
			fadein_result = 1
		end
	else
		in_speed = 1 / (in_endtime - in_starttime)
		local start_offset_constant = -in_starttime * in_speed
		fadein_result = math.Clamp(start_offset_constant + timeex * in_speed, 0, 1)
	end
	if not out_starttime then --missing data, assume no fadeout
		fadeout_result = 1
	elseif not out_endtime then --missing data, assume no fadeout
		fadeout_result = 1
	else
		if out_starttime ~= out_endtime then
			out_speed =  1 / (out_endtime - out_starttime)
			local end_offset_constant = out_endtime * out_speed
			fadeout_result = math.Clamp(end_offset_constant - timeex * out_speed, 0, 1)
		else
			if timeex > out_starttime then
				fadeout_result = 0
			else
				fadeout_result = 1
			end
		end

	end
	return fadein_result * fadeout_result
end

for i=1,5,1 do
	PART.Inputs["var" .. i] = function(self, uid1)
		if not uid1 then
			return self["feedback_extra" .. i]
		elseif self.last_extra_feedbacks[i][uid1] then --a thing to skip part searching when we found the part
			return self.last_extra_feedbacks[i][uid1]["feedback_extra" .. i] or 0
		else
			local PartA = self:GetOrFindCachedPart(uid1)
			if IsValid(PartA) and PartA.ClassName == "proxy" then
				self.last_extra_feedbacks[i][uid1] = PartA
			end
		end
		return 0
	end
	PART.Inputs["extra" .. i] = PART.Inputs["var" .. i] --alias
end

PART.Inputs.number_operator_alternative = function(self, comp1, op, comp2, num1, num2)
	if not (comp1 and op and comp2) then return -1 end
	if not (isnumber(comp1) and isnumber(comp2) and (isnumber(num1) or isvector(num1)) and (isnumber(num2) or isvector(num2))) then return -1 end
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
	elseif op == "~=" or op == "!=" or op == "not equal" then
		b = comp1 ~= comp2
	end
	if b then return num1 or 1 else return num2 or 0 end
end
PART.Inputs.if_else = PART.Inputs.number_operator_alternative

PART.Inputs.hexadecimal_level_sequence = function(self, freq, str)
	if not str then return 0 end
	local index = 1 + math.ceil(#str * freq * pac.RealTime) % #str
	return (tonumber(string.sub(str,index,index),16) or 0) / 15
end

local letter_numbers = {
	a = 0,
	b = 1,
	c = 2,
	d = 3,
	e = 4,
	f = 5,
	g = 6,
	h = 7,
	i = 8,
	j = 9,
	k = 10,
	l = 11,
	m = 12,
	n = 13,
	o = 14,
	p = 15,
	q = 16,
	r = 17,
	s = 18,
	t = 19,
	u = 20,
	v = 21,
	w = 22,
	x = 23,
	y = 24,
	z = 25
}

PART.Inputs.letters_level_sequence = function(self, freq, str)
	if not str then return 0 end
	local index = 1 + math.ceil(#str * freq * pac.RealTime) % #str
	local lookup_result = letter_numbers[string.sub(str,index,index)] or 0
	return lookup_result / 25
end

PART.Inputs.numberlist_level_sequence = function(self, freq, ...)
	local args = { ... }
	if not args[1] then return 0 end
	local index = 1 + math.ceil(#args * freq * pac.RealTime) % #args

	return args[index] or 0
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

PART.Inputs.bodygroup = function(self, name, uid)
	local owner
	if not uid then
		if self:GetParent().Bodygroup then
			owner = self:GetParent():GetOwner()
		else
			owner = get_owner(self)
		end
	else
		owner = self:GetOrFindCachedPart(uid):GetOwner()
	end
	local bgs = owner:GetBodyGroups()
	if bgs then
		for i,tbl in ipairs(bgs) do
			if tbl.name == name then return owner:GetBodygroup(tbl.id) end
		end
	end
	return 0
end

PART.Inputs.model_bodygroup = PART.Inputs.bodygroup

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

PART.Inputs.sequenced_event_number = function(self, name)
	local ply = self:GetPlayerOwner()
	if ply.pac_command_event_sequencebases then
		if ply.pac_command_event_sequencebases[name] then
			return ply.pac_command_event_sequencebases[name].current
		end
	end
	return 0
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

do -- weapon, player and owner entity/part color
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

	do
		local function reformat_color(col, proper_in, proper_out)
			local multiplier = 1
			if not proper_in then multiplier = multiplier / 255 end
			if not proper_out then multiplier = multiplier * 255 end
			col.r = math.Clamp(col.r * multiplier,0,255)
			col.g = math.Clamp(col.g * multiplier,0,255)
			col.b = math.Clamp(col.b * multiplier,0,255)
			col.a = math.Clamp(col.a * multiplier,0,255)
			return col
		end
		local function get_entity_color(self, field)
			local owner = get_owner(self)
			local part = self:GetTarget()
			if not self.RootOwner then --we can get the color from a pac part
				owner = self:GetParent()
				if not owner.GetColor then --or from the root owner entity...
					owner = get_owner(self)
				end
			end
			local color = owner:GetColor()
			if isvector(color) then --pac parts color are vector. reformat to a color first
				color = Color(color[1], color[2], color[3], owner.GetAlpha and owner:GetAlpha() or 255)
			end
			reformat_color(color, owner.ProperColorRange, part.ProperColorRange) --cram or un-cram the 255 range into 1 or vice versa
			if field then return color[field] else return color["r"], color["g"], color["b"] end
		end

		PART.Inputs.ent_color = function(self) return get_entity_color(self) end
		PART.Inputs.ent_color_r = function(self) return get_entity_color(self, "r") end
		PART.Inputs.ent_color_g = function(self) return get_entity_color(self, "g") end
		PART.Inputs.ent_color_b = function(self) return get_entity_color(self, "b") end
		PART.Inputs.ent_color_a = function(self) return get_entity_color(self, "a") end
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

PART.Inputs.server_maxplayers = function(self)
	return game.MaxPlayers()
end
PART.Inputs.server_playercount = function(self) return #player.GetAll() end
PART.Inputs.server_population = PART.Inputs.server_playercount
PART.Inputs.server_botcount = function(self) return #player.GetBots() end
PART.Inputs.server_humancount = function(self) return #player.GetHumans() end

PART.Inputs.pac_healthbars_total = function(self)
	local ent = self:GetPlayerOwner()
	if ent.pac_healthbars then
		return ent.pac_healthbars_total or 0
	end
	return 0
end

PART.Inputs.healthmod_bar_total = PART.Inputs.pac_healthbars_total

PART.Inputs.pac_healthbars_layertotal = function(self, layer)
	local ent = self:GetPlayerOwner()
	if ent.pac_healthbars and ent.pac_healthbars_layertotals then
		return ent.pac_healthbars_layertotals[layer] or 0
	end
	return 0
end

PART.Inputs.healthmod_bar_layertotal = PART.Inputs.pac_healthbars_layertotal

PART.Inputs.pac_healthbar_uidvalue = function(self, uid)
	local ent = self:GetPlayerOwner()
	local part = self:GetOrFindCachedPart(uid)

	if not IsValid(part) then
		self.invalid_parts_in_expression[uid] = "invalid uid : " .. uid .. " in pac_healthbar_uidvalue"
	elseif part.ClassName ~= "health_modifier" then
		self.invalid_parts_in_expression[uid] = "invalid class : " .. uid .. " in pac_healthbar_uidvalue"
	end
	if ent.pac_healthbars and ent.pac_healthbars_uidtotals then
		if ent.pac_healthbars_uidtotals[part.UniqueID] then

			if part:IsValid() then
				self.valid_parts_in_expression[part] = part
			end
		end
		return ent.pac_healthbars_uidtotals[part.UniqueID] or 0
	end
	return 0
end

PART.Inputs.healthmod_bar_uidvalue = PART.Inputs.pac_healthbar_uidvalue

PART.Inputs.pac_healthbar_remaining_bars = function(self, uid)
	local ent = self:GetPlayerOwner()
	local part = self:GetOrFindCachedPart(uid)
	if not IsValid(part) then
		self.invalid_parts_in_expression[uid] = "invalid uid or name : " .. uid .. " in pac_healthbar_remaining_bars"
	elseif part.ClassName ~= "health_modifier" then
		self.invalid_parts_in_expression[uid] = "invalid class : " .. uid .. " in pac_healthbar_remaining_bars"
	end
	if ent.pac_healthbars and ent.pac_healthbars_uidtotals then
		if ent.pac_healthbars_uidtotals[uid] then

			if part:IsValid() then
				self.valid_parts_in_expression[part] = part
			end
		end
		return part.healthbar_index or 0
	end
	return 0
end

PART.Inputs.healthmod_bar_remaining_bars = PART.Inputs.pac_healthbar_remaining_bars


local proxy_verbosity = CreateConVar("pac_proxy_verbosity", 1, FCVAR_ARCHIVE, "whether to print info when running pac_proxy")
net.Receive("pac_proxy", function()
	local ply = net.ReadEntity()
	local str = net.ReadString()

	local x = net.ReadFloat()
	local y = net.ReadFloat()
	local z = net.ReadFloat()

	if ply:IsValid() then
		ply.pac_proxy_events = ply.pac_proxy_events or {}
		ply.pac_proxy_events[str] = {name = str, x = x, y = y, z = z}
		if proxy_verbosity:GetBool() and pac.LocalPlayer == ply then
			pac.Message("pac_proxy -> command(\""..str.."\") is " .. x .. "," .. y .. "," .. z)
		end
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

function PART:SetExpression(str, slot)
	str = string.Trim(str,"\n")
	self.bad_uid_search = nil
	self.found_cached_parts = {}
	self.erroring_cached_parts = {}

	if self == pace.current_part and (pace.ActiveSpecialPanel and pace.ActiveSpecialPanel.luapad) and str ~= "" then
		--update luapad text if we update the expression from the properties
		if slot == pace.ActiveSpecialPanel.luapad.keynumber then --this check prevents cross-contamination
			pace.ActiveSpecialPanel.luapad:SetText(str)
		end
	end

	if not slot then --that's the default expression
		self.Expression = str
		self.ExpressionFunc = nil
		self.valid_parts_in_expression = {}
		self.invalid_parts_in_expression = {}
	elseif slot == 0 then --that's the expression on hide
		self.ExpressionOnHide = str
		self.ExpressionOnHideFunc = nil
	elseif slot <= 5 then --that's one of the custom variables
		self["CustomVariable" .. slot] = str
		self["Extra" .. slot .. "Func"] = nil
		self.has_extras = true
	end
	self.last_extra_feedbacks = {
		[1] = {},
		[2] = {},
		[3] = {},
		[4] = {},
		[5] = {},
	}

	if str and str ~= "" then
		local lib = {}

		for name, func in pairs(PART.Inputs) do
			lib[name] = function(...) return func(self, ...) end
		end

		local ok, res = pac.CompileExpression(str, lib)
		if ok then
			if not slot then --that's the default expression
				self.ExpressionFunc = res
				self.ExpressionError = nil
				self:SetError()
			elseif slot == 0 then --that's the expression on hide
				self.ExpressionOnHideFunc = res
				self.ExpressionOnHideError = nil
				self:SetError()
			elseif slot <= 5 then --that's one of the extra custom variables
				self["Extra" .. slot .. "Func"] = res
				self["Extra" .. slot .. "Error"] = nil
				self:SetError()
			end

		else
			if not slot then --that's the default expression
				self.ExpressionFunc = true
				self.ExpressionError = res
				self:SetError(res)
			elseif slot == 0 then --that's the expression on hide
				self.ExpressionOnHideFunc = true
				self.ExpressionOnHideError = res
				self:SetError(res)
			elseif slot <= 5 then --that's one of the extra custom variables
				self["Extra" .. slot .. "Func"] = true
				self["Extra" .. slot .. "Error"] = res
				self:SetError(res)
			end

		end
	end
end

function PART:SetExpressionOnHide(str)
	self.ExpressionOnHide = str
	self:SetExpression(str, 0)
end

function PART:SetExtra1(str)
	self.Extra1 = str
	self:SetExpression(str, 1)
end

function PART:SetExtra2(str)
	self.Extra2 = str
	self:SetExpression(str, 2)
end

function PART:SetExtra3(str)
	self.Extra3 = str
	self:SetExpression(str, 3)
end

function PART:SetExtra4(str)
	self.Extra4 = str
	self:SetExpression(str, 4)
end

function PART:SetExtra5(str)
	self.Extra5 = str
	self:SetExpression(str, 5)
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

	if self.ExpressionOnHide ~= "" and self.ExpressionOnHideFunc then
		self:OnThink(true)
	end
end

function PART:OnShow()
	self.time = nil
	self.rand = nil
	self.rand_id = nil
	self.vec_additive = Vector()
end

local extra_dynamic = CreateClientConVar("pac_special_property_update_dynamically", "1", true, false, "Whether proxies should refresh the properties, and some booleans may show more information.")
local function set(self, part, x, y, z, children)
	local val = part:GetProperty(self.VariableName)
	local original_x
	local T = type(val)
	local vector_type = false

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
			original_x = x
			x = x or val
			part:SetProperty(self.VariableName, tonumber(x) or 0)
			self.using_x = true
		else
			vector_type = true
			if self.Axis ~= "" and val[self.Axis] then
				val = val * 1
				val[self.Axis] = x or 0
				if T == "Angle" then
					self.using_x = self.Axis == "p" or self.Axis == "x" or self.Axis == "pitch"
					self.using_y = self.Axis == "y" or self.Axis == "y" or self.Axis == "yaw"
					self.using_z = self.Axis == "r" or self.Axis == "z" or self.Axis == "roll"
				elseif T == "Vector" then
					self.using_x = self.Axis == "x"
					self.using_y = self.Axis == "y"
					self.using_z = self.Axis == "z"
				end
			else
				self.using_x = x ~= nil
				self.using_y = y ~= nil
				self.using_z = z ~= nil
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

	--update the property if this is the current part
	if not extra_dynamic:GetBool() then return end
	if pace:IsActive() then
		if self:GetPlayerOwner() ~= pac.LocalPlayer then return end
		if part ~= pace.current_part then return end
		local property_pnl = part["pac_property_panel_"..self.VariableName]
		if IsValid(property_pnl) then
			local container = property_pnl:GetParent()
			local math_description = "expression:\n"..self.Expression
			if self.Expression == "" then math_description = "using " .. self.Function .. " and " .. self.Input end
			if vector_type then
				property_pnl.user_proxies = property_pnl.right.user_proxies or {}
				property_pnl.user_proxies [self] = self
				if self.using_x then
					property_pnl.used_by_proxy = true
					container = property_pnl.left
					property_pnl.left.used_by_proxy = true
					property_pnl.left.user_proxies = property_pnl.left.user_proxies or {}
					property_pnl.left.user_proxies [self] = self
					local num = x or 0
					property_pnl.left:SetValue(math.Round(tonumber(num),4))
					container:SetTooltip("LOCKED: Used by proxy:\n"..self:GetName().."\n\n" .. math_description)
				end
				if self.using_y then
					property_pnl.used_by_proxy = true
					container = property_pnl.middle
					property_pnl.middle.used_by_proxy = true
					property_pnl.middle.user_proxies = property_pnl.middle.user_proxies or {}
					property_pnl.middle.user_proxies [self] = self
					local num = y or x or 0
					property_pnl.middle:SetValue(math.Round(tonumber(num),4))
					container:SetTooltip("LOCKED: Used by proxy:\n"..self:GetName().."\n\n" .. math_description)
				end
				if self.using_z then
					property_pnl.used_by_proxy = true
					container = property_pnl.right
					property_pnl.right.used_by_proxy = true
					property_pnl.right.user_proxies = property_pnl.right.user_proxies or {}
					property_pnl.right.user_proxies [self] = self
					local num = z or x or 0
					property_pnl.right:SetValue(math.Round(tonumber(num),4))
					container:SetTooltip("LOCKED: Used by proxy:\n"..self:GetName().."\n\n" .. math_description)
				end
			elseif T == "boolean" then
				if x ~= nil then
					property_pnl.used_by_proxy = true
					property_pnl.user_proxies = property_pnl.user_proxies or {}
					property_pnl.user_proxies [self] = self
					property_pnl:SetValue(tonumber(x) > 0)
					container:SetTooltip("LOCKED: Used by proxy:\n"..self:GetName().."\n\n" .. math_description)
				end
			elseif original_x ~= nil then
				property_pnl.used_by_proxy = true
				property_pnl.user_proxies = property_pnl.user_proxies or {}
				property_pnl.user_proxies [self] = self
				property_pnl:SetValue(math.Round(tonumber(x) or 0,4))
				container:SetTooltip("LOCKED: Used by proxy:\n"..self:GetName().."\n\n" .. math_description)
			end
			
			
		end
	end
end

function PART:RunExpression(ExpressionFunc)
	if ExpressionFunc==true then
		return false,self.ExpressionError
	end
	return pcall(ExpressionFunc)
end

local function get_preview_draw_string(self)
	local str = self.debug_var or ""
	local name = self.Name
	if self.Name == "" then
		name = self:GetTarget().Name
		if name == "" then
			name = self:GetTarget():GetNiceName()
		end
	end
	str = name .. "." .. self.VariableName .. " = " .. str
	return str
end

local function remove_line_from_previews(self)
	text_preview_ent_rows = {}
	if text_preview_ent_rows[self:GetOwner()] then
		text_preview_ent_rows[self:GetOwner()][self] = {}
	end
	pace.flush_proxy_previews = true
	timer.Simple(0.1, function() pace.flush_proxy_previews = false end)
end


local text_preview_ent_rows = {}

local function draw_proxy_text(self, str)
	if pace.flush_proxy_previews then text_preview_ent_rows = {} return end
	local ent = self:GetOwner()
	local pos = ent:GetPos()
	local tbl = pos:ToScreen()
	text_preview_ent_rows[ent] = text_preview_ent_rows[ent] or {}
	if not text_preview_ent_rows[ent][self] then
		text_preview_ent_rows[ent][self] = table.Count(text_preview_ent_rows[ent])
	end
	tbl.x = tbl.x + 20
	tbl.y = tbl.y + 10 * text_preview_ent_rows[ent][self]
	draw.DrawText(get_preview_draw_string(self), "ChatFont", tbl.x, tbl.y)
end

function PART:OnWorn()
	remove_line_from_previews(self) --just for a quick refresh
end

function PART:OnRemove()
	remove_line_from_previews(self)
	pac.RemoveHook("HUDPaint", "proxy" .. self.UniqueID)
end

function PART:OnThink(to_hide)
	local part = self:GetTarget()
	if not part:IsValid() then return end
	if part.ClassName == 'woohoo' then --why a part hardcode exclusion??
		--ok fine I guess it's because it's super expensive, but at least we can be selective about it, the other parameters are safe
		if self.VariableName == "Resolution" or self.VariableName == "BlurFiltering" and self.touched then
			return
		end
	end

	--foolproofing: scream at the user if they didn't set a variable name and there's no extra expressions ready to be used
	if self == pace.current_part then self.touched = true end
	if self ~= pace.current_part and self.VariableName == "" and self.touched and self.Extra1 == ""	and self.Extra2 == "" and self.Extra3 == "" and self.Extra4 == "" and self.Extra5 == "" then
		self:AttachEditorPopup("You forgot to set a variable name! The proxy won't work until it knows where to send the math!", true)
		pace.FlashNotification("An edited proxy still has no variable name! The proxy won't work until it knows where to send the math!")
		self:SetWarning("You forgot to set a variable name! The proxy won't work until it knows where to send the math!")
		self.touched = false
	elseif self.VariableName ~= "" and not self.error and not self.errors_override then self:SetWarning() end

	self:CalcVelocity()

	if self.has_extras then --pre-calculate the extra expressions if needed
		for i=1,5,1 do
			if self["Extra" .. i] ~= "" then
				local ok, x,y,z = self:RunExpression(self["Extra" .. i .. "Func"])
				if ok then
					self["feedback_extra" .. i] = x
				end
			end
		end
	end

	local ExpressionFunc = self.ExpressionFunc
	if to_hide then ExpressionFunc = self.ExpressionOnHideFunc end

	if not ExpressionFunc then
		self:SetExpression(self.Expression)
		ExpressionFunc = self.ExpressionFunc
	end

	if ExpressionFunc then

		local ok, x,y,z = self:RunExpression(ExpressionFunc)

		if not ok then self.error = true
			if self:GetPlayerOwner() == pac.LocalPlayer and self.Expression ~= self.LastBadExpression then
				--don't spam the chat every time we type a single character in the luapad
				if not (pace.ActiveSpecialPanel and pace.ActiveSpecialPanel.luapad) then
					chat.AddText(Color(255,180,180),"============\n[ERR] PAC Proxy error on "..tostring(self)..":\n"..x.."\n============\n")
				end
				self.LastBadExpression = self.Expression
				self.Error = x --will be used by the luapad for its title
			end

			if not self.errors_override then self:SetError(self.Error) end
			return
		end
		self.Error = nil
		if not self.errors_override then self:SetError() end

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
			if self.MultiTargetPart then
				for _,part2 in ipairs(self.MultiTargetPart) do
					if not part2.GetProperty then continue end
					set(self, part2, x, y, z, true)
				end
			else
				for _, part in ipairs(self:GetChildren()) do
					set(self, part, x, y, z, true)
				end
			end
		else
			if self.MultiTargetPart then
				for _,part2 in ipairs(self.MultiTargetPart) do
					if not part2.GetProperty then continue end
					set(self, part2, x, y, z)
				end
			else
				set(self, part, x, y, z)
			end
		end

		if pace and pace.IsActive() then

			local str = ""

			if x then str = str .. math.Round(x, 3) end
			if y then str = str .. ", " .. math.Round(y, 3) end
			if z then str = str .. ", " .. math.Round(z, 3) end

			local val = part:GetProperty(self.VariableName)
			local T = type(val)

			if T == "boolean" then
				str = (tonumber(x) or 0) > 0 and "true" or "false"
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
				if self.MultiTargetPart then
					for _,part2 in ipairs(self.MultiTargetPart) do
						if not part2.GetProperty then continue end
						set(self, part2, num, nil, nil, true)
					end
				else
					for _, part in ipairs(self:GetChildren()) do
						set(self, part, num, nil, nil, true)
					end
				end
			else
				if self.MultiTargetPart then
					for _,part2 in ipairs(self.MultiTargetPart) do
						if not part2.GetProperty then continue end
						set(self, part2, num)
					end
				else
					set(self, part, num)
				end

			end

			if pace and pace.IsActive() then
				self.debug_var = math.Round(num, 3)
			end

			if self.Name == "" and pace.current_part == self and self.pace_properties and IsValid(self.pace_properties["Name"]) then
				self.pace_properties["Name"]:SetText(self:GetNiceName())
			end
		end
	end

	if table.Count(self.invalid_parts_in_expression) > 0 then
		local error_msg = ""
		for str, message in pairs(self.invalid_parts_in_expression) do
			error_msg = error_msg .. " " .. message .. "\n"
		end
		self:SetError(error_msg) self.error = true
	end
	if self:GetPlayerOwner() == pac.LocalPlayer then
		if self.PreviewOutput then
			pac.AddHook("HUDPaint", "proxy" .. self.UniqueID, function() draw_proxy_text(self, str) end)
		else
			pac.RemoveHook("HUDPaint", "proxy" .. self.UniqueID)
		end
	end

end


function PART:GetActiveFunctions()
	if self.Expression == "" then return {self.Input, self.Function} end
	local possible_funcs = {}
	for kw,_ in pairs(PART.Inputs) do
		local kw2 = kw .. "("
		if string.find(self.Expression, kw2, 0, true) ~= nil then
			table.insert(possible_funcs, kw)
		end
	end

	return possible_funcs
end

function PART:GetTutorial(str)
	if not str then
		if pace and pace.TUTORIALS then
			return pace.TUTORIALS.PartInfos[self.ClassName].popup_tutorial
		end
	end
	return PART.Tutorials[str]
end

function PART:AttachEditorPopup(str, flash, tbl)
	if str == nil then
		local funcs = self:GetActiveFunctions()
		if #funcs > 0 then
			str = "active functions"
			if self.Expression ~= "" then
				str = self.Expression .. "\n\nactive functions"
			end
			for i, kw in ipairs(self:GetActiveFunctions()) do
				str = str .. "\n\n====================================================================\n\n" .. self:GetTutorial(kw)
			end
		end
	end
	local pnl = self:SetupEditorPopup(str, flash, tbl)
	if flash and pnl then
		pnl:MakePopup()
	end
	return pnl
end

timer.Simple(10, function()
	pace.TUTORIALS["proxy_functions"] = PART.Tutorials
end)

BUILDER:Register()
