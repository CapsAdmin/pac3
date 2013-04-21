local PART = {}

PART.ClassName = "ogg"
PART.NonPhysical = true

pac.StartStorableVars()
	pac.GetSet(PART, "URL", "")
	pac.GetSet(PART, "Volume", 1)
	pac.GetSet(PART, "Pitch", 1)
	pac.GetSet(PART, "Radius", 1500)
	pac.GetSet(PART, "PlayCount", 1)
	pac.GetSet(PART, "Doppler", false)
	pac.GetSet(PART, "StopOnHide", false)
	pac.GetSet(PART, "PauseOnHide", false)
	pac.GetSet(PART, "Overlapping", false)
	
	pac.GetSet(PART, "FilterType", 0)
	pac.GetSet(PART, "FilterFraction", 1)
	
	pac.GetSet(PART, "Echo", false)
	pac.GetSet(PART, "EchoDelay", 0.5)
	pac.GetSet(PART, "EchoFeedback", 0.75)
	
	pac.GetSet(PART, "PlayOnFootstep", false)
	pac.GetSet(PART, "MinPitch", 0)
	pac.GetSet(PART, "MaxPitch", 0)
pac.EndStorableVars()

function PART:Initialize()
	self.streams = {}
end

function PART:GetNiceName()
	return pac.PrettifyName(("/".. self:GetURL()):match(".+/(.-)%.")) or "no sound"
end

local BIND = function(name, set, check)
	set = set or "Set" .. name
	PART["Set" .. name] = function(self, var)				
		if check then
			var = check(var)
		end
		
		for key, stream in pairs(self.streams) do
			if stream:IsValid() then
				stream[set](stream, var)
			else
				self.streams[key] = nil
			end
		end
		
		self[name] = var
	end
end

BIND("Pitch")
BIND("PlayCount", "SetMaxLoopCount")
BIND("Volume", nil, function(n) return math.Clamp(n, 0, 4) end)
BIND("Radius", "Set3DRadius")

BIND("FilterType")
BIND("FilterFraction")
BIND("Echo")

BIND("Echo")
BIND("EchoDelay")
BIND("EchoFeedback", nil, function(n) return math.Clamp(n, 0, 0.99) end)

function PART:PlaySound(ovol)
	local ent = self:GetOwner(self.RootOwner)

	if ent:IsValid() then						
		local vol
		
		if osnd and self.Volume == -1 then
			vol = ovol or 1
		else
			vol = self.Volume
		end
		
		self:PlaySound(nil, vol)
	end
end

function PART:Think()	
	if self:IsHidden() then return end

	local owner = self:GetOwner(true) 
	
	for key, stream in pairs(self.streams) do
		if not stream:IsValid() then self.streams[key] = nil continue end
			
		if self.PlayCount == 0 then
			stream:Resume()
		end
		
		if stream.owner_set ~= owner and owner:IsValid() then
			stream:SetSourceEntity(owner)
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
		
	for _, URL in pairs(urls) do	
		local stream = pac.webaudio.Stream(URL)
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
			
		self.streams[URL] = stream
	end
	
	self.URL = URL
end

PART.last_stream = NULL

function PART:PlaySound(_, vol)
	if pac.webaudio.rate > 48000 then
		local clr, str = Color(255, 0, 0), "[PAC3] the ogg part (custom sounds) cannot be used because you have your sample rate set to " .. pac.webaudio.rate .. " kHz. This is not supported nor is it recommended. Set it to 48000 or below to fix this.\n"
	
		if self:GetPlayerOwner() == pac.LocalPlayer then
			chat.AddText(clr, str)
		else
			MsgC(clr, str)
		end
		
		return
	end

	local stream = table.Random(self.streams) or NULL
	
	if not stream:IsValid() then return end
		
	vol = vol or 0
	
	self.volume_mod = vol
		
	if self.last_stream:IsValid() and not self.Overlapping then
		self.last_stream:Stop()
	end	
	
	if self.MinPitch ~= self.MaxPitch then
		stream.pitch_mod = math.Rand(self.MinPitch, self.MaxPitch)
	else
		stream.pitch_mod = 0
	end
	
	stream:SetVolume(stream:GetVolume())
	stream:SetPitch(stream:GetPitch())
	
	if self.PauseOnHide then
		stream:Resume()
	else
		stream:Start()
	end
	
	self.last_stream = stream
end

function PART:OnShow(from_event)	
	if not from_event then return end

	self:PlaySound()
end

function PART:OnHide(from_event)
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