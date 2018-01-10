local PART = {}
local snd_mute_losefocus = GetConVar('snd_mute_losefocus')

PART.ClassName = "webaudio"

PART.Group = 'effects'
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
end

function PART:GetNiceName()
	return pac.PrettifyName(("/" .. self:GetURL()):match(".+/(.-)%.")) or "no sound"
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
	local forward = ang:Forward()

	local shouldMute = snd_mute_losefocus:GetBool()
	local focus = system.HasFocus()
	local volume = shouldMute and not focus and 0 or self:GetVolume()

	for url, streamdata in pairs(self.streams) do
		local stream = streamdata.stream
		if streamdata.Loading then goto CONTINUE end
		if not stream:IsValid() then self.streams[url] = nil goto CONTINUE end

		stream:SetPos(pos, forward)

		if not self.random_pitch then self:SetRandomPitch(self.RandomPitch) end

		stream:Set3DFadeDistance(self.MinimumRadius, self.MaximumRadius)
		stream:Set3DCone(self.InnerAngle, self.OuterAngle, self.OuterVolume)
		stream:SetVolume(volume)
		stream:SetPlaybackRate(self:GetPitch() + self.random_pitch)
		if streamdata.StartPlaying then
			stream:Play()
			streamdata.StartPlaying = nil
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

	local urls = {}

	for _, url in pairs(URL:Split(";")) do
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

	for url, streamdata in pairs(self.streams) do
		local stream = streamdata.stream
		if streamdata.Loading or not stream:IsValid() then self.streams[url] = nil goto CONTINUE end

		stream:Stop()
		::CONTINUE::
	end

	self.streams = {}

	for _, url in pairs(urls) do

		url = pac.FixupURL(url)

		local flags = "3d noplay noblock"

		local callback = function (snd, ...)
			if not snd or not snd:IsValid() then
				pac.Message("Failed to load ", url, " (" .. flags .. ")")
				self.streams[url] = nil
			else

				if self.streams[url] then
					if self.streams[url].PlayAfterLoad or (pace and pace.Editor:IsValid() and pace.current_part:IsValid() and pace.current_part.ClassName == "webaudio" and self:GetPlayerOwner() == pac.LocalPlayer) then
						self.streams[url].PlayAfterLoad = nil
						if self.Loop and (snd:GetLength() > 0) then
							snd:EnableLooping(true)
						else
							snd:EnableLooping(false)
						end
						self.streams[url].Loading = false
						self.streams[url].StartPlaying = true
					end

					self.streams[url].stream = snd
				end

			end
		end


		self.streams[url] = {Loading = true}

		sound.PlayURL(url, flags, callback)

	end

	self.URL = URL
end

PART.last_stream = NULL

function PART:PlaySound()
	local streamdata = table.Random(self.streams) or NULL

	local stream = streamdata.stream
	if streamdata.Loading then streamdata.PlayAfterLoad = true return end
	if not stream:IsValid() then return end

	self:SetRandomPitch(self.RandomPitch)

	if self.last_stream:IsValid() and not self.Overlapping and self.last_stream ~= stream then
		self.last_stream:SetTime(0)
		self.last_stream:Pause()
	end

	streamdata.StartPlaying = true

	self.last_stream = stream
end

function PART:StopSound()
	for key, streamdata in pairs(self.streams) do
		local stream = streamdata.stream
		if streamdata.Loading then streamdata.PlayAfterLoad = nil goto CONTINUE end
		if not stream:IsValid() then self.streams[key] = nil goto CONTINUE end

		if self.StopOnHide then
			streamdata.StartPlaying = nil
			if self.PauseOnHide then
				stream:Pause()
			else
				pcall(function() stream:SetTime(0) end)
				stream:Pause()
			end
		end
		::CONTINUE::
	end
end

function PART:OnShow(from_rendering)
	if not from_rendering then
		self:PlaySound()
	end
end

function PART:OnHide()
	self:StopSound()
end

function PART:OnRemove()
	for key, streamdata in pairs(self.streams) do
		local stream = streamdata.stream
		if streamdata.Loading or not stream:IsValid() then self.streams[key] = nil goto CONTINUE end

		stream:Stop()
		::CONTINUE::
	end
end

pac.RegisterPart(PART)