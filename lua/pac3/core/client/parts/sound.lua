local webaudio = include("pac3/libraries/webaudio.lua")
pac.webaudio2 = webaudio
local PART = {}

PART.FriendlyName = "web sound"
PART.ClassName = "sound2"
PART.NonPhysical = true
PART.Icon = 'icon16/music.png'
PART.Group = 'effects'

pac.StartStorableVars()
	pac.GetSet(PART, "Path", "", {editor_panel = "sound"})
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
	pac.GetSet(PART, "PlayOnFootstep", false)
	pac.GetSet(PART, "MinPitch", 0, {editor_sensitivity = 0.125})
	pac.GetSet(PART, "MaxPitch", 0, {editor_sensitivity = 0.125})

	pac.SetPropertyGroup(PART, "filter")
		pac.GetSet(PART, "FilterType", 0, {enums = {
			none = "0",
			lowpass = "1",
			highpass = "2",
		}})
		pac.GetSet(PART, "FilterFraction", 1, {editor_sensitivity = 0.125, editor_clamp = {0, 1}})

	pac.SetPropertyGroup(PART, "echo")
		pac.GetSet(PART, "Echo", false)
		pac.GetSet(PART, "EchoDelay", 0.5, {editor_sensitivity = 0.125})
		pac.GetSet(PART, "EchoFeedback", 0.75, {editor_sensitivity = 0.125})

	pac.SetPropertyGroup(PART, "lfo")
		pac.GetSet(PART, "PitchLFOAmount", 0, {editor_sensitivity = 0.125, editor_friendly = "pitch amount"})
		pac.GetSet(PART, "PitchLFOTime", 0, {editor_sensitivity = 0.125, editor_friendly = "pitch time"})

		pac.GetSet(PART, "VolumeLFOAmount", 0, {editor_sensitivity = 0.125, editor_friendly = "volume amount"})
		pac.GetSet(PART, "VolumeLFOTime", 0, {editor_sensitivity = 0.125, editor_friendly = "volume time"})

pac.EndStorableVars()

function PART:Initialize()
	webaudio.Initialize()
	self.streams = {}
end

function PART:GetNiceName()
	local path = self:GetPath() .. ";"
	local tbl = {}
	for i, path in ipairs(path:Split(";")) do
		if path ~= "" then
			if path:StartWith("http") then
				path = path:gsub("%%(..)", function(char)
					local num = tonumber("0x" .. char)
					if num then
						return string.char(num)
					end
				end)
			end
			tbl[i] = pac.PrettifyName(("/".. path):match(".+/(.-)%.") or path:match("(.-)%.")) or "sound"
		end
	end
	return table.concat(tbl, ";")
end

PART.stream_vars = {}

local BIND = function(propertyName, setterMethodName, check)
	table.insert(PART.stream_vars, propertyName)
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
BIND("EchoDelay")
BIND("EchoFeedback", nil, function(n) return math.Clamp(n, 0, 0.99) end)

BIND("PitchLFOAmount")
BIND("PitchLFOTime")

BIND("VolumeLFOAmount")
BIND("VolumeLFOTime")

BIND("Doppler")

function PART:OnThink()
	local owner = self:GetOwner(true)

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

function PART:SetPath(path)
	self.Path = path

	local paths = {}

	for _, path in ipairs(path:Split(";")) do
		local min, max = path:match(".+%[(.-),(.-)%]")

		min = tonumber(min)
		max = tonumber(max)

		if min and max then
			for i = min, max do
				table.insert(paths, (path:gsub("%[.-%]", i)))
			end
		else
			table.insert(paths, path)
		end
	end

	for _, stream in pairs(self.streams) do
		if stream:IsValid() then
			stream:Remove()
		end
	end

	self.streams = {}

	local function load(path)
		local stream = webaudio.CreateStream(path)
		self.streams[path] = stream

		stream:Set3D(true)
		stream.OnLoad = function()
			for _, key in ipairs(PART.stream_vars) do
				self["Set" .. key](self, self["Get" .. key](self))
			end
		end
		stream.OnError =  function(_, err, info)
			info = info or "unknown error"
			if self:IsValid() and LocalPlayer() == self:GetPlayerOwner() and pace and pace.IsActive() then
				if pace and pace.current_part == self and not IsValid(pace.BusyWithProperties) then
					pace.MessagePrompt(err .. "\n" .. info, "OGG error for" .. path, "OK")
				else
					pac.Message("OGG error: ", err, " reason: ", info)
				end
			end
		end

		stream.UpdateSourcePosition = function()
			if self:IsValid() then
				stream.SourcePosition = self:GetDrawPosition()
			end
		end

		if
			pace and
			pace.Editor:IsValid() and
			pace.current_part:IsValid() and
			pace.current_part.ClassName == "ogg2" and
			self:GetPlayerOwner() == pac.LocalPlayer
		then
			stream:Play()
		end
	end

	for _, path in ipairs(paths) do
		local info = sound.GetProperties(path)
		if info then
			path = info.sound
		end

		if not pac.resource.Download(path, function(path) load("data/" .. path) end) then
			load("sound/" .. path)
		end
	end
end

PART.last_stream = NULL

function PART:PlaySound(_, additiveVolumeFraction)
	additiveVolumeFraction = additiveVolumeFraction or 0

	local stream = table.Random(self.streams) or NULL

	if not stream:IsValid() then return end

	stream:SetAdditiveVolumeModifier(additiveVolumeFraction)

	if self.last_stream:IsValid() and not self.Overlapping and not self.PauseOnHide  then
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
		stream:Play()
	end

	self.last_stream = stream
end

function PART:StopSound()
	for key, stream in pairs(self.streams) do
		if stream:IsValid() then
			if self.PauseOnHide then
				stream:Pause()
			elseif self.StopOnHide then
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
		if not stream:IsValid() then self.streams[key] = nil goto CONTINUE end

		stream:Remove()
		::CONTINUE::
	end
end

pac.RegisterPart(PART)