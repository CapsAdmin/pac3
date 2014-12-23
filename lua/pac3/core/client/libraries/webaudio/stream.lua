-- made by Morten and CapsAdmin

pac.webaudio = pac.webaudio or {}
local webaudio = pac.webaudio

webaudio.Streams = webaudio.Streams or {}

webaudio.Streams.STREAM = {}
STREAM = webaudio.Streams.STREAM
STREAM.__index = STREAM

STREAM.loaded = false
STREAM.duration = 0
STREAM.position = 0
STREAM.rad3d = 1000
STREAM.usedoppler = true
STREAM.url = "" -- ??
STREAM.paused = true

function STREAM:IsLoaded()
	return self.loaded
end

function STREAM:IsValid()
	return true
end

function STREAM:Remove()
	self.IsValid = function() return false end
end

function STREAM:Call(fmt, ...)
	if not self.loaded then return end

	local code = ("try { streams[%d]%s } catch(e) { lua.print(e.toString()) }"):format(self.id, fmt:format(...))

	webaudio.Browser.QueueJavascript(code)
end

function STREAM:CallNow(fmt, ...)
	if not self.loaded then return end

	local code = ("try { streams[%d]%s } catch(e) { lua.print(e.toString()) }"):format(self.id, fmt:format(...))

	webaudio.Browser.RunJavascript(code)
end

local function BIND(propertyName, js_set, def, check)
	STREAM[propertyName] = def

	STREAM["Set" .. propertyName] = function(self, var)
		if check then
			var = check(var, self)
		end

		self[propertyName] = var
		
		-- ewww
		if propertyName == "Speed" then
			var = var + self.pitch_mod
		end	
		
		self:Call(js_set, var)
	end

	STREAM["Get" .. propertyName] = function(self, ...)
		return self[propertyName]
	end
end

STREAM.pitch_mod = 0
STREAM.volume_mod = 0

BIND("SamplePosition", ".position = %f", 0)
BIND("Speed", ".speed = %f", 1)

STREAM.SetPitch = STREAM.SetSpeed
STREAM.GetPitch = STREAM.GetSpeed

webaudio.FILTER =
{
	NONE = 0,
	LOWPASS = 1,
	HIGHPASS = 2,
}

BIND("FilterType", ".filter_type = %i")
BIND("FilterFraction", ".filter_fraction = %f", 0, function(num) return math.Clamp(num, 0, 1) end)

BIND("Echo", ".useEcho(%s)", false)
BIND("EchoDelay", ".setEchoDelay(Math.ceil(audio.sampleRate * %f))", 1, function(num) return math.max(num, 0) end)
BIND("EchoFeedback", ".echo_feedback = %f", 0.75)

function STREAM:SetMaxLoopCount(var)
	self:Call(".max_loop = %i", var == true and -1 or var == false and 1 or tonumber(var) or 1)
	self.MaxLoopCount= var
end

STREAM.SetLooping = STREAM.SetMaxLoopCount

function STREAM:GetLength()
	return self.Length
end

function STREAM:Pause()
	self.paused = true
	self:CallNow(".play(false)")
end

function STREAM:Resume()
	self.paused = false
	self:CallNow(".play(true)")
end

function STREAM:Stop()
	self.paused = true
	self:CallNow(".play(false, 0)")
end

function STREAM:Start()
	self.paused = false
	self:CallNow(".play(true, 0)")
end

STREAM.Play = STREAM.Start

function STREAM:Restart()
	self:SetSamplePosition(0)
end

function STREAM:SetPosition(num)
	self:SetSamplePosition((num%1) * self:GetLength())
end

do -- 3d
	function STREAM:Enable3D(b)
		self.use3d = b
	end

	function STREAM:EnableDoppler(b)
		self.usedoppler = b
	end

	function STREAM:Set3DPos(vec)
		self.pos3d = vec
	end

	function STREAM:Get3DPos(vec)
		return self.pos3d
	end

	function STREAM:Set3DRadius(num)
		self.rad3d = num
	end

	function STREAM:Get3DRadius(num)
		return self.rad3d
	end

	function STREAM:Set3DVelocity(vec)
		self.vel3d = vec
	end

	function STREAM:Get3DVelocity(vec)
		return self.vel3d
	end

	local eye_pos, eye_ang, eye_vel, last_eye_pos

	hook.Add("RenderScene", "webaudio_3d", function(pos, ang)
		eye_pos = pos
		eye_ang = ang
		eye_vel = eye_pos - (last_eye_pos or eye_pos)

		last_eye_pos = eye_pos
	end)

	function STREAM:Think()
		if self.paused then return end

		local ent = self.source_ent

		if ent:IsValid() then
			self.pos3d = ent:GetPos()
		end

		if self.use3d then
			self.pos3d = self.pos3d or Vector()
			self.vel3d = self.vel3d or Vector()

			self.vel3d = self.pos3d - (self.last_ent_pos or self.pos3d)
			self.last_ent_pos = self.pos3d

			local offset = self.pos3d - eye_pos
			local len = offset:Length()

			if len < self.rad3d then
				local pan = (offset):GetNormalized():Dot(eye_ang:Right())
				local vol = math.Clamp((-len + self.rad3d) / self.rad3d, 0, 1) ^ 1.5
				vol = vol * 0.75 * self.Volume

				self:Call(".vol_right = %f", (math.Clamp(1 + pan, 0, 1) * vol) + self.volume_mod)
				self:Call(".vol_left = %f", (math.Clamp(1 - pan, 0, 1) * vol) + self.volume_mod)

				if self.usedoppler then
					local offset = self.pos3d - eye_pos
					local relative_velocity = self.vel3d - eye_vel
					local meters_per_second = offset:GetNormalized():Dot(-relative_velocity) * 0.0254

					self:Call(".speed = %f", (self.Speed + (meters_per_second / webaudio.SpeedOfSound)) + self.pitch_mod)
				end

				self.out_of_reach = false
			else
				if not self.out_of_reach then
					self:Call(".vol_right = 0")
					self:Call(".vol_left = 0")
					self.out_of_reach = true
				end
			end
		end
	end

	STREAM.source_ent = NULL

	function STREAM:SetSourceEntity(ent, dont_remove)
		self.source_ent = ent

		if not dont_remove then
			ent:CallOnRemove("webaudio_remove_stream_" .. tostring(self), function()
				if self:IsValid() then
					self:Remove()
				end
			end)
		end
	end
end

do -- panning
	STREAM.Panning = 0

	function STREAM:SetPanning(num)
		self.Panning = num

		if not self.use3d then
			self:Call(".vol_right = %f", (math.Clamp(1 + num, 0, 1) * self.Volume) + self.volume_mod)
			self:Call(".vol_left = %f", (math.Clamp(1 - num, 0, 1) * self.Volume) + self.volume_mod)
		end
	end

	function STREAM:GetPanning()
		return self.Panning
	end
end

do -- gain
	STREAM.Volume = 1

	function STREAM:SetVolume(num)
		self.Volume = num
		self:SetPanning(self:GetPanning())
	end

	function STREAM:GetVolume()
		return self.Volume
	end
end

function STREAM:__newindex(key, val)
	if key == "OnFFT" then
		if type(val) == "function" then
			self:Call(".usefft(true)")
		else
			self:Call(".usefft(false)")
		end
	end

	rawset(self, key, val)
end

STREAM.__tostring = function(s) return string.format("stream[%p][%d][%s]", s, s.id, s.url) end
