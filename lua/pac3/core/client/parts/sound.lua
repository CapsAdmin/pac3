local PART = {}

PART.ClassName = "sound"
PART.NonPhysical = true
PART.ThinkTime = 0

pac.StartStorableVars()
	pac.GetSet(PART, "Sound", "")
	pac.GetSet(PART, "Volume", 1)
	pac.GetSet(PART, "Pitch", 0.4)
	pac.GetSet(PART, "MinPitch", 100)
	pac.GetSet(PART, "MaxPitch", 100)
	pac.GetSet(PART, "RootOwner", true)
	pac.GetSet(PART, "PlayOnFootstep", false)
	pac.GetSet(PART, "Overlapping", false)
pac.EndStorableVars()

function PART:Initialize()
	self:PlaySound()
end

function PART:OnShow()
	self.played_overlapping = false
	self:PlaySound()
end

function PART:OnHide()
	self.played_overlapping = false
	self:StopSound()
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

	if self:IsHiddenEx() then
		self:StopSound()
	else
		if not self.csptch or not self.csptch:IsPlaying() then
			self:PlaySound()
		end
	end
end

-- fixes by Python 1320

-- Sound protection. TODO: MAKE A BETTER FIX. Iterative removal of the special characters?
-- This will make special sound effects break if used directly from lua, but I doubt this is common.
-- Won't protect engine but engine shouldn't do this anyway.
-- TODO: Beta new sound functions

-- https://developer.valvesoftware.com/wiki/Soundscripts#Sound_Characters
-- we are using this for bad replacements as it won't break stuff too badly ["*"]=true,   

local bad = 
{ 
	["#"]=true,
	["@"]=true,
	[">"]=true,
	["<"]=true,
	["^"]=true,
	[")"]=true,
	["}"]=true,
	["$"]=true,
	["!"]=true,
	["?"]=true, -- especially bad
}

local function fix(snd)
	if bad[snd:sub(1,1)] then
		snd = snd:gsub("^(.)",function() return "*" end)
	end
	if bad[snd:sub(2,2)] then
		snd = snd:gsub("^(..)",function(a) return a[1].."*" end)
	end	
	return snd
end
	
function PART:SetSound(str)
	if type(str) ~= "string" then self.Sound = "" return end

	if bad[str:sub(1,1)] or bad[str:sub(2,2)] then
		str = fix(str)
	end

	self.Sound = str:gsub("\\", "/")
	
	self:PlaySound()
end

function PART:SetVolume(num)
	self.Volume = num
	
	if not self.csptch then
		self:PlaySound()
	end
	
	if self.csptch then
		self.csptch:ChangeVolume(math.Clamp(self.Volume, 0.001, 1), 0)
	end
end

function PART:SetPitch(num)
	self.Pitch = num
	
	if not self.csptch then
		self:PlaySound()
	end
	
	if self.csptch then
		self.csptch:ChangePitch(math.Clamp(self.Pitch*255, 1, 255), 0)
	end
end

function PART:PlaySound(osnd, ovol)
	local ent = self:GetOwner(self.RootOwner)

	if ent:IsValid() then
		local snd
		
		if osnd and self.Sound == "" then
			snd = osnd
		else
			local sounds = self.Sound:Split(";")
			
			if #sounds > 1 then
				snd = table.Random(sounds)
			else
				snd = self.Sound:gsub(
					"(%[%d-,%d-%])", 
					function(minmax) 
						local min, max = minmax:match("%[(%d-),(%d-)%]")
						if max < min then
							max = min
						end
						return math.random(min, max) 
					end
				)
			end
		end
						
		local vol
		
		if osnd and self.Volume == -1 then
			vol = ovol or 1
		else
			vol = self.Volume
		end
											
		local pitch
		
		if self.MinPitch == self.MaxPitch then
			pitch = self.Pitch * 255
		else
			pitch = math.random(self.MinPitch, self.MaxPitch)
		end
		
		if self.Overlapping then
			if not self.played_overlapping then
				ent:EmitSound(snd, vol * 160, pitch)
				self.played_overlapping = true
			end
		else
			if self.csptch then
				self.csptch:Stop()
			end
			
			local csptch = CreateSound(ent, snd)

			csptch:PlayEx(vol, pitch)		
			ent.pac_csptch = csptch
			self.csptch = csptch
		end
	end
end

function PART:StopSound()
	if self.csptch then
		self.csptch:Stop()
	end
end

local channels = 
{
	CHAN_AUTO = 0,
	CHAN_WEAPON = 1,
	CHAN_VOICE = 2,
	CHAN_ITEM = 3,
	CHAN_BODY = 4,
	CHAN_STREAM = 5,
	CHAN_STATIC = 6,
}

for key, CHAN in pairs(channels) do
	sound.Add( 
	{
		name = "pac_silence_" .. key:lower(),
		channel = CHAN,
		volume = 0,
		soundlevel = 0,
		pitchstart = 0,
		pitchend = 0,
		sound = "ambient/_period.wav"
	} )
end

hook.Add("pac_PlayerFootstep", "pac_sound_footstep", function(ply, pos, snd, vol)
	if ply.pac_footstep_override then
		for key, part in pairs(ply.pac_footstep_override) do
			if not part:IsHiddenEx() then
				part:PlaySound(snd, vol)
			end
		end
	end
end)

pac.RegisterPart(PART)