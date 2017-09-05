local PART = {}
local snd_mute_losefocus = GetConVar('snd_mute_losefocus')

PART.ClassName = "webaudio"

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

	for url, stream in pairs(self.streams) do
		if not stream:IsValid() then self.streams[url] = nil continue end

		stream:SetPos(pos, forward)

		if not self.random_pitch then self:SetRandomPitch(self.RandomPitch) end

		stream:Set3DFadeDistance(self.MinimumRadius, self.MaximumRadius)
		stream:Set3DCone(self.InnerAngle, self.OuterAngle, self.OuterVolume)
		stream:SetVolume(volume)
		stream:SetPlaybackRate(self:GetPitch() + self.random_pitch)
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

	for _, stream in pairs(self.streams) do
		if not stream:IsValid() then self.streams[key] = nil continue end

		stream:Stop()
	end

	self.streams = {}

	for _, url in pairs(urls) do
		local flags = "3d noplay noblock"

		local callback callback = function (snd, ...)
			if not snd or not snd:IsValid() then
				print("[PAC3] Failed to load ", url, "(" .. flags .. ")")
				return
			end

			if pace and pace.Editor:IsValid() and pace.current_part:IsValid() and pace.current_part.ClassName == "webaudio" and self:GetPlayerOwner() == pac.LocalPlayer then
				if self.Loop and (snd:GetLength() > 0) then
					snd:EnableLooping(true)
				else
					snd:EnableLooping(false)
				end
				snd:Play()
			end

			self.streams[url] = snd
		end

		url = pac.FixupURL(url)

		sound.PlayURL(url, flags, callback)

	end

	self.URL = URL
end

PART.last_stream = NULL

function PART:PlaySound()
	local stream = table.Random(self.streams) or NULL

	if not stream:IsValid() then return end

	self:SetRandomPitch(self.RandomPitch)

	if self.last_stream:IsValid() and not self.Overlapping and self.last_stream ~= stream then
		self.last_stream:SetTime(0)
		self.last_stream:Pause()
	end

	stream:Play()

	self.last_stream = stream
end

function PART:StopSound()
	for key, stream in pairs(self.streams) do
		if not stream:IsValid() then self.streams[key] = nil continue end

		if self.StopOnHide then
			if self.PauseOnHide then
				stream:Pause()
			else
				pcall(function() stream:SetTime(0) end)
				stream:Pause()
			end
		end
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
	for key, stream in pairs(self.streams) do
		if not stream:IsValid() then self.streams[key] = nil continue end

		stream:Stop()
	end
end

pac.RegisterPart(PART)