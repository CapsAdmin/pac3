local PART = {}

PART.ClassName = "sound"
PART.NonPhysical = true
PART.ThinkTime = 0
PART.Group = 'effects'
PART.Icon = 'icon16/sound.png'

pac.StartStorableVars()
	pac.GetSet(PART, "Sound", "")
	pac.GetSet(PART, "Volume", 1, {editor_sensitivity = 0.25})
	pac.GetSet(PART, "Pitch", 0.4, {editor_sensitivity = 0.125})
	pac.GetSet(PART, "MinPitch", 100, {editor_sensitivity = 0.125})
	pac.GetSet(PART, "MaxPitch", 100, {editor_sensitivity = 0.125})
	pac.GetSet(PART, "RootOwner", true)
	pac.GetSet(PART, "PlayOnFootstep", false)
	pac.GetSet(PART, "Overlapping", false)
	pac.GetSet(PART, "SoundLevel", 100)
	pac.GetSet(PART, "Loop", false)
	pac.GetSet(PART, "LocalPlayerOnly", false)
pac.EndStorableVars()

function PART:GetNiceName()
	return pac.PrettifyName(("/" .. self:GetSound()):match(".+/(.-)%.")) or "no sound"
end

function PART:Initialize()
	--self:PlaySound()
end

function PART:OnShow(from_rendering)
	if not from_rendering then
		self.played_overlapping = false
		self:PlaySound()
	end

	local ent = self:GetOwner()

	if ent:IsValid() and ent:IsPlayer() then
		ent.pac_footstep_override = ent.pac_footstep_override or {}
		if self.PlayOnFootstep then
			ent.pac_footstep_override[self.UniqueID] = self
		else
			ent.pac_footstep_override[self.UniqueID] = nil
		end
	end
end

function PART:OnHide()
	self.played_overlapping = false
	self:StopSound()

	if self.PlayOnFootstep then

		local ent = self:GetOwner()

		if ent:IsValid() then
			ent.pac_footstep_override = nil

			if ent:IsPlayer() then
				ent.pac_footstep_override = ent.pac_footstep_override or {}


				ent.pac_footstep_override[self.UniqueID] = nil
			end
		end
	end
end

function PART:OnThink()
	if not self.csptch then
		self:PlaySound()
	else
		if self.Loop then
			pac.playing_sound = true
			if not self.csptch:IsPlaying() then self.csptch:Play() end
			self.csptch:ChangePitch((self.Pitch * 255) + math.sin(pac.RealTime) / 2, 0)
			pac.playing_sound = false
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
	["#"] = true,
	["@"] = true,
	[">"] = true,
	["<"] = true,
	["^"] = true,
	[")"] = true,
	["}"] = true,
	["$"] = true,
	["!"] = true,
	["?"] = true, -- especially bad
}

local function fix(snd)
	if bad[snd:sub(1,1)] then
		snd = snd:gsub("^(.)",function() return "*" end)
	end
	if bad[snd:sub(2,2)] then
		snd = snd:gsub("^(..)",function(a) return a[1] .. "*" end)
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
		self.csptch:ChangePitch(math.Clamp(self.Pitch * 255, 1, 255), 0)
	end
end

function PART:PlaySound(osnd, ovol)
	local ent = self:GetOwner(self.RootOwner)

	if ent:IsValid() then
		if ent:GetClass() == "viewmodel" or ent == pac.LocalHands then
			ent = pac.LocalPlayer
		end

		if self:GetLocalPlayerOnly() and ent ~= pac.LocalPlayer then return end

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

		pac.playing_sound = true

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


			csptch:SetSoundLevel(self.SoundLevel)
			csptch:PlayEx(vol, pitch)
			ent.pac_csptch = csptch
			self.csptch = csptch
		end

		pac.playing_sound = false
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

pac.RegisterPart(PART)