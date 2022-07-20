include("pac3/libraries/webaudio/urlogg.lua")
include("pac3/libraries/webaudio/browser.lua")
include("pac3/libraries/webaudio/stream.lua")
include("pac3/libraries/webaudio/streams.lua")

local BUILDER, PART = pac.PartTemplate("base_movable")

PART.FriendlyName = "legacy ogg"
PART.ClassName = "ogg"

PART.Group = "legacy"
PART.Icon = 'icon16/music.png'

BUILDER:StartStorableVars()
	BUILDER:GetSet("URL", "")
	BUILDER:GetSet("Volume", 1, {editor_sensitivity = 0.25})
	BUILDER:GetSet("Pitch", 1, {editor_sensitivity = 0.125})
	BUILDER:GetSet("Radius", 1500)
	BUILDER:GetSet("PlayCount", 1, {editor_onchange = function(self, num)
		self.sens = 0.25
		num = tonumber(num)
		return math.Round(math.max(num, 0))
	end})
	BUILDER:GetSet("Doppler", false)
	BUILDER:GetSet("StopOnHide", false)
	BUILDER:GetSet("PauseOnHide", false)
	BUILDER:GetSet("Overlapping", false)

	BUILDER:GetSet("FilterType", 0, {editor_onchange = function(self, num)
		self.sens = 0.25
		num = tonumber(num)
		return math.Round(math.Clamp(num, 0, 2))
	end})
	BUILDER:GetSet("FilterFraction", 1, {editor_sensitivity = 0.125, editor_clamp = {0, 1}})

	--BUILDER:GetSet("Echo", false)
	--BUILDER:GetSet("EchoDelay", 0.5)
	--BUILDER:GetSet("EchoFeedback", 0.75)

	BUILDER:GetSet("PlayOnFootstep", false)
	BUILDER:GetSet("MinPitch", 0, {editor_sensitivity = 0.125})
	BUILDER:GetSet("MaxPitch", 0, {editor_sensitivity = 0.125})
BUILDER:EndStorableVars()

function PART:Initialize()
	self.streams = {}
end

function PART:GetNiceName()
	local str = pac.PrettifyName("/".. self:GetURL())
	return str and str:match(".+/(.-)%.") or "no sound"
end

local stream_vars = {"Doppler", "Radius"}

local BIND = function(propertyName, setterMethodName, check)
	table.insert(stream_vars, propertyName)
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

--BIND("Echo")
--BIND("EchoDelay")
--BIND("EchoFeedback", nil, function(n) return math.Clamp(n, 0, 0.99) end)

function PART:OnThink()
	local owner = self:GetRootPart():GetOwner()

	for url, stream in pairs(self.streams) do
		if not stream:IsValid() then self.streams[url] = nil goto CONTINUE end

		if self.PlayCount == 0 then
			stream:Resume()
		end

		if stream.owner_set ~= owner and owner:IsValid() then
			stream:SetSourceEntity(owner, true)
			stream.owner_set = owner
		end
		::CONTINUE::
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

	self:SetError()

	for _, url in pairs(urls) do
		local stream = pac.webaudio.Streams.CreateStream(url)
		self.streams[url] = stream

		stream:Enable3D(true)
		stream.OnLoad = function()
			for _, key in ipairs(stream_vars) do
				self["Set" .. key](self, self["Get" .. key](self))
			end
		end
		stream.OnError =  function(err, info)
			pac.Message("OGG error: ", err, " reason: ", info or "none")
			self:SetError(str)
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
	local stream = table.Random(self.streams) or NULL

	if pac.webaudio.sample_rate and pac.webaudio.sample_rate > 48000 then
		pac.Message(Color(255, 0, 0), "The ogg part (custom sounds) might not work because you have your sample rate set to ", pac.webaudio.sample_rate, " Hz. Set it to 48000 or below if you experience any issues.")
		self:SetInfo("The ogg part (custom sounds) might not work because you have your sample rate set to " .. pac.webaudio.sample_rate .. " Hz. Set it to 48000 or below if you experience any issues.")
	end

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
		if not stream:IsValid() then self.streams[key] = nil goto CONTINUE end

		if not self.StopOnHide then
			if self.PauseOnHide then
				stream:Pause()
			else
				stream:Stop()
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
	for key, stream in pairs(self.streams) do
		if not stream:IsValid() then self.streams[key] = nil goto CONTINUE end

		stream:Remove()
		::CONTINUE::
	end
end

function PART:SetDoppler(num)
	for key, stream in pairs(self.streams) do
		if not stream:IsValid() then self.streams[key] = nil goto CONTINUE end

		stream:EnableDoppler(num)
		::CONTINUE::
	end

	self.Doppler = num
end

BUILDER:Register()
