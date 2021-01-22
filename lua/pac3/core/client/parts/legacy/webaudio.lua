local PART = {}
local snd_mute_losefocus = GetConVar('snd_mute_losefocus')

PART.ClassName = "webaudio"
PART.Group = 'legacy'
PART.Icon = 'icon16/sound_add.png'

pac.StartStorableVars()
	pac.GetSet(PART, "URL", "")
	pac.GetSet(PART, "Volume", 1, {editor_sensitivity = 0.125})
	pac.GetSet(PART, "Pitch", 1, {editor_sensitivity = 0.125})
	pac.GetSet(PART, "MinimumRadius", 0)
	pac.GetSet(PART, "MaximumRadius", 0)

	pac.GetSet(PART, "InnerAngle", 360)
	pac.GetSet(PART, "OuterAngle", 360)
	pac.GetSet(PART, "OuterVolume", 0)

	pac.GetSet(PART, "Loop", false)
	pac.GetSet(PART, "StopOnHide", true)
	pac.GetSet(PART, "PauseOnHide", false)
	pac.GetSet(PART, "Overlapping", false)

	pac.GetSet(PART, "PlayOnFootstep", false)
	pac.GetSet(PART, "RandomPitch", 0, {editor_sensitivity = 0.125})
pac.EndStorableVars()

function PART:Initialize()
	self.streams = {}
	self.stream_count = 0
end

function PART:GetNiceName()
	local str = pac.PrettifyName("/" .. self:GetURL())
	return str and str:match(".+/(.-)%.") or "no sound"
end

function PART:OnThink()
	if self.last_playonfootstep ~= self.PlayOnFootstep then
		local ent = self:GetOwner()
		if ent:IsValid() and ent:IsPlayer() then
			ent.pac_footstep_override = ent.pac_footstep_override or {}

			if self.PlayOnFootstep then
				ent.pac_footstep_override[self.UniqueID] = self
			else
				ent.pac_footstep_override[self.UniqueID] = nil
			end

			if table.Count(ent.pac_footstep_override) == 0 then
				ent.pac_footstep_override = nil
			end

			self.last_playonfootstep = self.PlayOnFootstep
		end
	end
end

function PART:OnDraw(ent, pos, ang)
	if not self.streams then return end
	local forward = ang:Forward()

	local shouldMute = snd_mute_losefocus:GetBool()
	local focus = system.HasFocus()
	local volume = shouldMute and not focus and 0 or self:GetVolume()

	for url, streamdata in pairs(self.streams) do
		local stream = streamdata.stream
		if streamdata.Loading then goto CONTINUE end

		if not stream:IsValid() then
			self.streams[url] = nil
			self.stream_count = self.stream_count - 1
			-- TODO: Notify the user somehow or reload streams
			goto CONTINUE
		end

		stream:SetPos(pos, forward)

		if not self.random_pitch then self:SetRandomPitch(self.RandomPitch) end

		stream:Set3DFadeDistance(self.MinimumRadius, self.MaximumRadius)
		stream:Set3DCone(self.InnerAngle, self.OuterAngle, self.OuterVolume)
		stream:SetVolume(volume)
		stream:SetPlaybackRate(self:GetPitch() + self.random_pitch)

		if streamdata.StartPlaying then
			stream:Play()
			streamdata.StartPlaying = false
		end

		::CONTINUE::
	end
end

function PART:SetRandomPitch(num)
	self.RandomPitch = num
	self.random_pitch = math.Rand(-num, num)
end

function PART:SetLoop(b)
	self.Loop = b
	self:SetURL(self:GetURL())
end

function PART:SetURL(URL)
	self.InSetup = true

	timer.Create("pac3_webaudio_seturl_" .. tostring(self), 0.5, 1, function()
		if not self:IsValid() then return end

		self.InSetup = false
		self:SetupURLStreamsNow(URL)

		if self.PlayAfterSetup then
			self:PlaySound()
			self.PlayAfterSetup = false
		end
	end)

	self.URL = URL
end

function PART:SetupURLStreamsNow(URL)
	local urls = {}

	for _, url in ipairs(URL:Split(";")) do
		local min, max = url:match(".+%[(.-),(.-)%]")

		min = tonumber(min)
		max = tonumber(max)

		if min and max then
			for i = min, max do
				table.insert(urls, (url:gsub("%[.-%]", i)))
			end
		else
			table.insert(urls, url)
		end
	end

	if #urls >= 150 then
		local cp = {}

		for i = 1, 150 do
			table.insert(cp, urls[i])
		end

		urls = cp
	end

	for url, streamdata in pairs(self.streams) do
		if IsValid(streamdata.stream) then
			streamdata.stream:Stop()
		end
	end

	self.streams = {}
	self.stream_count = 0

	local inPace = pace and pace.IsActive() and pace.current_part == self and self:GetPlayerOwner() == pac.LocalPlayer

	for _, url in ipairs(urls) do
		local flags = "3d noplay noblock"
		local function callback(channel, errorCode, errorString)
			local streamdata = self.streams[url]
			if not streamdata then
				if IsValid(channel) then channel:Stop() end
				return
			end

			if not channel or not channel:IsValid() then
				pac.Message("Failed to load ", url, " (" .. flags .. ") - " .. (errorString or errorCode or "UNKNOWN"))

				if errorCode == -1 then
					pac.Message('GMOD BUG: WAVe and Vorbis files are known to be not working with 3D flag, recode file into MPEG-3 format!')
				end

				self.streams[url] = nil
				self.stream_count = self.stream_count - 1
				return
			end

			streamdata.Loading = false

			if streamdata.valid then
				if streamdata.PlayAfterLoad or inPace then
					channel:EnableLooping(self.Loop and channel:GetLength() > 0)
					streamdata.PlayAfterLoad = false
					streamdata.StartPlaying = true
				end

				streamdata.stream = channel

				if self.NeedsToPlayAfterLoad then
					self.NeedsToPlayAfterLoad = false
					self:PlaySound()
				end

				return
			end

			channel:Stop()
		end

		self.streams[url] = {Loading = true, valid = true}
		self.stream_count = self.stream_count + 1

		sound.PlayURL(url, flags, callback)
	end
end

function PART:PlaySound()
	if self.InSetup then
		self.PlayAfterSetup = true
		return
	end

	if self.stream_count == 0 then return end

	local i, streamdata, atLeastSome = 0

	while i < 20 and i < self.stream_count do
		streamdata = table.Random(self.streams)

		if IsValid(streamdata.stream) then
			if not atLeastSome and streamdata.Loading then
				atLeastSome = true
			end

			break
		end

		i = i + 1
	end

	local stream = streamdata.stream

	if not IsValid(stream) then
		if atLeastSome then
			self.NeedsToPlayAfterLoad = true
		end

		return
	end

	self:SetRandomPitch(self.RandomPitch)

	if IsValid(self.last_stream) and not self.Overlapping and self.last_stream ~= stream then
		self.last_stream:SetTime(0)
		self.last_stream:Pause()
	end

	streamdata.StartPlaying = true
	self.last_stream = stream
end

function PART:StopSound()
	local toremove

	for key, streamdata in pairs(self.streams) do
		streamdata.PlayAfterLoad = false
		streamdata.StartPlaying = false

		local stream = streamdata.stream

		if IsValid(stream) then
			if self.PauseOnHide then
				stream:Pause()
			else
				pcall(function() stream:SetTime(0) end)
				stream:Pause()
			end
		elseif stream then
			toremove = toremove or {}
			table.insert(toremove, key)
		end
	end

	if toremove then
		for i, index in ipairs(toremove) do
			self.streams[index] = nil
		end

		self.stream_count = self.stream_count - #toremove
	end
end

function PART:OnShow(from_rendering)
	if not from_rendering then
		self:PlaySound()
	end
end

function PART:OnHide()
	if self.StopOnHide then
		self:StopSound()
	end
end

function PART:OnRemove()
	for key, streamdata in pairs(self.streams) do
		streamdata.valid = false

		if IsValid(streamdata.stream) then
			streamdata.stream:Stop()
		end
	end
end

pac.RegisterPart(PART)
