local PART = {}

PART.ClassName = "ogg"
PART.NonPhysical = true

pac.StartStorableVars()
	pac.GetSet(PART, "URL", "")
	pac.GetSet(PART, "Volume", 1)
	pac.GetSet(PART, "Pitch", 1)
	pac.GetSet(PART, "Radius", 500)
	pac.GetSet(PART, "Loop", 1)
	pac.GetSet(PART, "Doppler", true)
	pac.GetSet(PART, "StopOnHide", false)
	pac.GetSet(PART, "PauseOnHide", false)
	pac.GetSet(PART, "Overlapping", false)
	
	pac.GetSet(PART, "FilterType", 0)
	pac.GetSet(PART, "FilterFraction", 1)
	pac.GetSet(PART, "FilterQuality", 1)
	pac.GetSet(PART, "FilterGain", 1)
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
BIND("Loop", "SetLoopCount")
BIND("Volume", nil, function(n) return math.Clamp(n, 0, 2) end)
BIND("Radius", "Set3DRadius", function(n) return math.Clamp(n, 0, 1500) end)

BIND("FilterType")
BIND("FilterFraction")
BIND("FilterQuality", nil, function(n) return math.Clamp(n, 0, 5) end)
BIND("FilterGain", nil, function(n) return math.Clamp(n, 0, 2) end)

function PART:Think()	
	local owner = self:GetOwner(true) 
	
	for key, stream in pairs(self.streams) do
		if not stream:IsValid() then self.streams[key] = nil continue end
				
		if stream.owner_set ~= owner and owner:IsValid() then
			stream:SetSourceEntity(owner)
			stream.owner_set = owner
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
			
		self.streams[URL] = stream
	end
	
	self.URL = URL
end

PART.last_stream = NULL

function PART:OnShow(from_event)
	
	if not from_event then return end

	local stream = table.Random(self.streams)
	if not stream:IsValid() then return end
		
	if self.last_stream:IsValid() and not self.Overlapping then
		self.last_stream:Stop()
	end
				
	if self.PauseOnHide then
		stream:Resume()
	else
		stream:Start()
	end
	
	self.last_stream = stream

end

function PART:OnHide(from_event)
	local stream = table.Random(self.streams)
	if not stream:IsValid() then return end
	
	if not self.StopOnHide then		
		if self.PauseOnHide then
			stream:Pause()
		else
			stream:Stop()
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
end

pac.RegisterPart(PART)