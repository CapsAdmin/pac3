-- made by Morten and CapsAdmin

pac.webaudio = pac.webaudio or {}
local webaudio = pac.webaudio

webaudio.Streams = webaudio.Streams or {}

webaudio.FilterType =
{
	None     = 0,
	LowPass  = 1,
	HighPass = 2,
}

webaudio.Streams.STREAM = {}
STREAM = webaudio.Streams.STREAM
STREAM.__index = STREAM

STREAM.Id                     = nil
STREAM.Url                    = "" -- ??

-- Playback speed
STREAM.PlaybackSpeed          = 1

-- Volume
STREAM.Panning                = 0
STREAM.Volume                 = 1
STREAM.AdditiveVolumeFraction = 0

STREAM.loaded                 = false
STREAM.duration               = 0
STREAM.position               = 0
STREAM.rad3d                  = 1000
STREAM.usedoppler             = true
STREAM.paused                 = true

local function DECLARE_PROPERTY(propertyName, javascriptSetterCode, defaultValue, filterFunction)
	STREAM[propertyName] = defaultValue

	STREAM["Set" .. propertyName] = function(self, value)
		if filterFunction then
			value = filterFunction(var, self)
		end

		self[propertyName] = value
		
		self:Call(javascriptSetterCode, value)
	end

	STREAM["Get" .. propertyName] = function(self, ...)
		return self[propertyName]
	end
end

-- Identity
function STREAM:GetId()
	return self.Id
end

function STREAM:SetId(id)
	self.Id = id
	return self
end

function STREAM:GetUrl()
	return self.Url
end

function STREAM:SetUrl(url)
	self.Url = url
	return self
end

-- State
function STREAM:IsLoaded()
	return self.loaded
end

function STREAM:IsValid()
	return true
end

function STREAM:Remove()
	self.IsValid = function() return false end
end

-- Browser
function STREAM:Call(fmt, ...)
	if not self.loaded then return end

	local code = string.format("try { streams[%d]%s } catch(e) { lua.print(e.toString()) }", self:GetId(), string.format(fmt, ...))

	webaudio.Browser.QueueJavascript(code)
end

function STREAM:CallNow(fmt, ...)
	if not self.loaded then return end

	local code = string.format("try { streams[%d]%s } catch(e) { lua.print(e.toString()) }", self:GetId(), string.format(fmt, ...))

	webaudio.Browser.RunJavascript(code)
end

-- Playback
function STREAM:SetMaxLoopCount(maxLoopCount)
	self:Call(".max_loop = %i", maxLoopCount == true and -1 or maxLoopCount == false and 1 or tonumber(maxLoopCount) or 1)
	self.MaxLoopCount = maxLoopCount
end

STREAM.SetLooping = STREAM.SetMaxLoopCount

-- SampleCount
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

function STREAM:Start()
	self.paused = false
	self:CallNow(".play(true, 0)")
end
STREAM.Play = STREAM.Start

function STREAM:Stop()
	self.paused = true
	self:CallNow(".play(false, 0)")
end

function STREAM:Restart()
	self:SetSamplePosition(0)
end

function STREAM:SetPosition(positionFraction)
	self:SetSamplePosition((positionFraction % 1) * self:GetLength())
end

STREAM.pitch_mod = 0

DECLARE_PROPERTY("SamplePosition", ".position = %f", 0)

function STREAM:GetPlaybackSpeed()
	return self.PlaybackSpeed
end

function STREAM:SetPlaybackSpeed(playbackSpeedMultiplier)
	if self.PlaybackSpeed == playbackSpeedMultiplier then return self end
	
	self.PlaybackSpeed = playbackSpeedMultiplier
	
	self:Call(".speed = %f", self.PlaybackSpeed + self.pitch_mod)
	
	return self
end

DECLARE_PROPERTY("FilterType",     ".filter_type = %i")
DECLARE_PROPERTY("FilterFraction", ".filter_fraction = %f", 0, function(num) return math.Clamp(num, 0, 1) end)

DECLARE_PROPERTY("Echo",         ".useEcho(%s)", false)
DECLARE_PROPERTY("EchoDelay",    ".setEchoDelay(Math.ceil(audio.sampleRate * %f))", 1, function(num) return math.max(num, 0) end)
DECLARE_PROPERTY("EchoFeedback", ".echo_feedback = %f", 0.75)


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

				self:Call(".vol_right = %f", (math.Clamp(1 + pan, 0, 1) * vol) + self.AdditiveVolumeFraction)
				self:Call(".vol_left  = %f", (math.Clamp(1 - pan, 0, 1) * vol) + self.AdditiveVolumeFraction)

				if self.usedoppler then
					local offset = self.pos3d - eye_pos
					local relative_velocity = self.vel3d - eye_vel
					local meters_per_second = offset:GetNormalized():Dot(-relative_velocity) * 0.0254

					self:Call(".speed = %f", (self.PlaybackSpeed + (meters_per_second / webaudio.SpeedOfSound)) + self.pitch_mod)
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

-- Volume
function STREAM:GetPanning()
	return self.Panning
end

function STREAM:GetVolume()
	return self.Volume
end

function STREAM:GetAdditiveVolumeModifier ()
	return self.AdditiveVolumeModifier
end

function STREAM:SetPanning(panning)
	if self.Panning == panning then return self end
	
	self.Panning = panning

	if not self.use3d then
		self:UpdateVolume()
	end
	
	return self
end

function STREAM:SetVolume(volumeFraction)
	if self.Volume == volumeFraction then return self end
	
	self.Volume = volumeFraction

	if not self.use3d then
		self:UpdateVolume()
	end
	
	return self
end

function STREAM:SetAdditiveVolumeModifier (additiveVolumeFraction)
	if self.AdditiveVolumeFraction == additiveVolumeFraction then return self end
	
	self.AdditiveVolumeFraction = additiveVolumeFraction

	if not self.use3d then
		self:UpdateVolume()
	end
	
	return self
end

function STREAM:UpdateVolume()
	self:Call(".vol_right = %f", (math.Clamp(1 + self.Panning, 0, 1) * self.Volume) + self.AdditiveVolumeFraction)
	self:Call(".vol_left  = %f", (math.Clamp(1 - self.Panning, 0, 1) * self.Volume) + self.AdditiveVolumeFraction)
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

function STREAM:__tostring()
	return string.format("stream[%p][%d][%s]", self, self:GetId(), self:GetUrl())
end
