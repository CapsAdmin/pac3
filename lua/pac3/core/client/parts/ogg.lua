local PART = {}

PART.ClassName = "ogg"
PART.NonPhysical = true
PART.Group = 'effects'
PART.Icon = 'icon16/music.png'

pac.StartStorableVars()
	pac.GetSet(PART, "URL", "")
	pac.GetSet(PART, "Volume", 1, {editor_sensitivity = 0.25})
	pac.GetSet(PART, "Pitch", 1, {editor_sensitivity = 0.125})
	pac.GetSet(PART, "Radius", 1500)
	pac.GetSet(PART, "PlayCount", 1, {editor_onchange = function(self, num)
		self.sens = 0.25
		num = tonumber(num)
		return math.Round(math.max(num, 0))
	end})
	pac.GetSet(PART, "Doppler", false)
	pac.GetSet(PART, "StopOnHide", false)
	pac.GetSet(PART, "PauseOnHide", false)
	pac.GetSet(PART, "Overlapping", false)

	pac.GetSet(PART, "FilterType", 0)
	pac.GetSet(PART, "FilterFraction", 1)

	--pac.GetSet(PART, "Echo", false)
	--pac.GetSet(PART, "EchoDelay", 0.5)
	--pac.GetSet(PART, "EchoFeedback", 0.75)

	pac.GetSet(PART, "PlayOnFootstep", false)
	pac.GetSet(PART, "MinPitch", 0, {editor_sensitivity = 0.125})
	pac.GetSet(PART, "MaxPitch", 0, {editor_sensitivity = 0.125})
pac.EndStorableVars()

function PART:Initialize()
	self.streams = {}
end

function PART:GetNiceName()
	return pac.PrettifyName(("/".. self:GetURL()):match(".+/(.-)%.")) or "no sound"
end

local BIND = function(propertyName, setterMethodName, check)
	setterMethodName = setterMethodName or "Set" .. propertyName
	PART["Set" .. propertyName] = function(self, value)
		if check then
			value = check(value)
		end

		for url, stream in pairs(self.streams) do
			if stream:IsValid() then
				stream[setterMethodName](stream, value)
			else
				self.streams[url] = nil
			end
		end

		self[propertyName] = value
	end
end

BIND("Pitch",     "SetPlaybackSpeed")
BIND("PlayCount", "SetMaxLoopCount" )
BIND("Volume",    nil, function(n) return math.Clamp(n, 0, 4) end)
BIND("Radius",    "SetSourceRadius" )

BIND("FilterType")
BIND("FilterFraction")
BIND("Echo")

BIND("Echo")
BIND("EchoDelay")
BIND("EchoFeedback", nil, function(n) return math.Clamp(n, 0, 0.99) end)

function PART:OnThink()
	local owner = self:GetOwner(true)

	for url, stream in pairs(self.streams) do
		if not stream:IsValid() then self.streams[url] = nil continue end

		if self.PlayCount == 0 then
			stream:Resume()
		end

		if stream.owner_set ~= owner and owner:IsValid() then
			stream:SetSourceEntity(owner, true)
			stream.owner_set = owner
		end
	end

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
		if stream:IsValid() then
			stream:Remove()
		end
	end

	self.streams = {}

	for _, url in pairs(urls) do

		url = pac.FixupURL(url)

		local stream = pac.webaudio.Streams.CreateStream(url)
		self.streams[url] = stream

		stream:Enable3D(true)
		stream.OnLoad = function()
			for key in pairs(self.StorableVars) do
				if key ~= "URL" then
					self["Set" .. key](self, self["Get" .. key](self))
				end
			end
		end
		stream.OnError =  function(err, info)
			local str = ("OGG error: %s reason: %s\n"):format(err, info or "none")
			MsgC(Color(255, 0, 0), "[PAC3] " .. str)
			self.Errored = str
		end

		if pace and pace.Editor:IsValid() and pace.current_part:IsValid() and pace.current_part.ClassName == "ogg" and self:GetPlayerOwner() == pac.LocalPlayer then
			stream:Play()
		end
	end

	self.URL = URL
end

PART.last_stream = NULL

function PART:PlaySound(_, additiveVolumeFraction)
	additiveVolumeFraction = additiveVolumeFraction or 0

	if pac.webaudio.GetSampleRate() > 48000 then
		local warningColor   = Color(255, 0, 0)
		local warningMessage = "[PAC3] The ogg part (custom sounds) might not work because you have your sample rate set to " .. pac.webaudio.GetSampleRate() .. " Hz. Set it to 48000 or below if you experience any issues.\n"
		--[[
		if self:GetPlayerOwner() == pac.LocalPlayer then
			chat.AddText(warningColor, warningMessage)
		else
			MsgC(warningColor, warningMessage)
		end]]
	end

	local stream = table.Random(self.streams) or NULL

	if not stream:IsValid() then return end

	stream:SetAdditiveVolumeModifier (additiveVolumeFraction)

	if self.last_stream:IsValid() and not self.Overlapping then
		self.last_stream:Stop()
	end

	if self.MinPitch ~= self.MaxPitch then
		stream:SetAdditivePitchModifier(math.Rand(self.MinPitch, self.MaxPitch))
	else
		stream:SetAdditivePitchModifier(0)
	end

	if self.PauseOnHide then
		stream:Resume()
	else
		stream:Start()
	end

	self.last_stream = stream
end

function PART:StopSound()
	for key, stream in pairs(self.streams) do
		if not stream:IsValid() then self.streams[key] = nil continue end

		if not self.StopOnHide then
			if self.PauseOnHide then
				stream:Pause()
			else
				stream:Stop()
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

		stream:Remove()
	end
end

function PART:SetDoppler(num)
	for key, stream in pairs(self.streams) do
		if not stream:IsValid() then self.streams[key] = nil continue end

		stream:EnableDoppler(num)
	end

	self.Doppler = num
end

pac.RegisterPart(PART)