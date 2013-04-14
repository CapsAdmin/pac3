local PART = {}

PART.ClassName = "ogg"
PART.NonPhysical = true

pac.StartStorableVars()
	pac.GetSet(PART, "URL", "")
	pac.GetSet(PART, "Volume", 1)
	pac.GetSet(PART, "Pitch", 1)
	pac.GetSet(PART, "Radius", 500)
	pac.GetSet(PART, "Loop", 1)
	pac.GetSet(PART, "Doppler", false)
	pac.GetSet(PART, "StopOnHide", true)
	
	pac.GetSet(PART, "FilterType", 0)
	pac.GetSet(PART, "FilterFraction", 1)
	pac.GetSet(PART, "FilterQuality", 1)
	pac.GetSet(PART, "FilterGain", 1)
pac.EndStorableVars()

PART.stream = NULL

function PART:GetNiceName()
	return pac.PrettifyName(("/".. self:GetURL()):match(".+/(.-)%.")) or "no sound"
end

local BIND = function(name, set, check)
	set = set or "Set" .. name
	PART["Set" .. name] = function(self, var)				
		if check then
			var = check(var)
		end
				
		if self.stream:IsValid() then 
			self.stream[set](self.stream, var)
		end
		
		self[name] = var
	end
end

BIND("Pitch", "SetSpeed")
BIND("Loop", "SetLoopCount")
BIND("Volume", nil, function(n) return math.Clamp(n, 0, 2) end)
BIND("Radius", "Set3DRadius", function(n) return math.Clamp(n, 0, 1500) end)

BIND("FilterType")
BIND("FilterFraction")
BIND("FilterQuality", nil, function(n) return math.Clamp(n, 0, 5) end)
BIND("FilterGain", nil, function(n) return math.Clamp(n, 0, 2) end)

function PART:Think()	

	if not self.stream:IsValid() then return end
	
	local owner = self:GetOwner(true) 
	
	if self.owner_set ~= owner and owner:IsValid() then
		self.stream:SetSourceEntity(owner)
		self.owner_set = owner
	end
	
	if not self.hacky_init and self.stream.loaded then
		for key in pairs(self.StorableVars) do
			if key ~= "URL" then
				self["Set" .. key](self, self["Get" .. key](self))
			end
		end
		
		self.hacky_init = true
	end
end

function PART:SetURL(name)
	if self.stream:IsValid() then
		self.stream:Remove()
	end
		
	self.stream = pac.webaudio.Stream(name)
	self.stream:Enable3D(true)
	self.hacky_init = false
		
	self.URL = name
end

function PART:OnShow(from_event)
	if not self.stream:IsValid() then return end
	
	if self.StopOnHide then
		self.stream:Play()
	else
		self.stream:Pause()
	end
end

function PART:OnHide(from_event)
	if not self.stream:IsValid() then return end
	
	if self.StopOnHide then
		self.stream:Stop()
	else
		self.stream:Resume()
	end
end

function PART:OnRemove()
	if not self.stream:IsValid() then return end
	
	self.stream:Remove()
end

function PART:SetDoppler(num)
	if not self.stream:IsValid() then return end
	self.stream:EnableDoppler(num)
end

pac.RegisterPart(PART)