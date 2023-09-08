local BUILDER, PART = pac.PartTemplate("base_movable")

PART.FriendlyName = "legacy sound"
PART.Group = "legacy"
PART.ClassName = "sound"

PART.ThinkTime = 0
PART.Group = 'effects'
PART.Icon = 'icon16/sound.png'

BUILDER:StartStorableVars()
BUILDER:SetPropertyGroup("generic")
	BUILDER:GetSet("Sound", "")
	BUILDER:GetSet("Volume", 1, {editor_sensitivity = 0.25})
	BUILDER:GetSet("Pitch", 0.4, {editor_sensitivity = 0.125})
	BUILDER:GetSet("MinPitch", 100, {editor_sensitivity = 0.125})
	BUILDER:GetSet("MaxPitch", 100, {editor_sensitivity = 0.125})
	BUILDER:GetSet("RootOwner", true)
	BUILDER:GetSet("SoundLevel", 100)
	BUILDER:GetSet("LocalPlayerOnly", false)
BUILDER:SetPropertyGroup("playback")
	BUILDER:GetSet("PlayOnFootstep", false)
	BUILDER:GetSet("Overlapping", false)
	BUILDER:GetSet("Loop", false)
	BUILDER:GetSet("Sequential", false, {description = "if there are multiple sounds (separated by ; or using [min,max] notation), plays these sounds in sequential order instead of randomly"})
	BUILDER:GetSet("SequentialStep",1,
		{editor_onchange =
		function(self, num)
			self.sens = 0.25
			num = tonumber(num)
			return math.Round(num)
		end})
BUILDER:EndStorableVars()

function PART:GetNiceName()
	local str = pac.PrettifyName("/" .. self:GetSound())
	return str and str:match(".+/(.-)%.") or "no sound"
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
	if not isstring(str) then self.Sound = "" return end

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
	local ent = self.RootOwner and self:GetRootPart():GetOwner() or self:GetOwner()

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

			--case 1: proper semicolon list
			if #sounds > 1 then
				if self.Sequential then
					self.seq_index = self.seq_index or 1

					snd = sounds[self.seq_index]

					self.seq_index = self.seq_index + self.SequentialStep
					self.seq_index = self.seq_index % (#sounds+1)
					if self.seq_index == 0 then self.seq_index = 1 end
				else snd = table.Random(sounds) end

			--case 2: one sound, which may or may not be bracket notation
			elseif #sounds == 1 then
				--bracket notation
				if string.match(sounds[1],"%[(%d-),(%d-)%]") then
					local function minmaxpath(minmax,str)
						local min, max = minmax:match("%[(%d-),(%d-)%]")
						if minmax:match("%[(%d-),(%d-)%]") == nil then return 1 end
						if max < min then
							max = min
						end
						if str == "min" then return tonumber(min)
						elseif str == "max" then return tonumber(max) else return tonumber(max) end
					end
					if self.Sequential then
						self.seq_index = self.seq_index or minmaxpath(self.Sound,"min")
						snd = self.Sound:gsub(
							"(%[%d-,%d-%])",self.seq_index
						)
						self.seq_index = self.seq_index + self.SequentialStep

						local span = minmaxpath(self.Sound,"max") - minmaxpath(self.Sound,"min") + 1
						if self.seq_index > minmaxpath(self.Sound,"max") then
							self.seq_index = self.seq_index - span
						elseif self.seq_index < minmaxpath(self.Sound,"min") then
							self.seq_index = self.seq_index + span
						end
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
				--single sound
				else snd = sounds[1] or osnd end
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

BUILDER:Register()
