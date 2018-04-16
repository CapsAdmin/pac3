local PART = {}

PART.ClassName = "player_config"
PART.Group = "experimental"
PART.Icon = 'icon16/brick.png'
PART.NonPhysical = true

pac.StartStorableVars()

pac.SetPropertyGroup()
	pac.GetSet(PART, "MuteSounds", false)
	pac.GetSet(PART, "AllowOggWhenMuted", false)
	pac.GetSet(PART, "HideBullets", false)
	pac.GetSet(PART, "DrawPlayerOnDeath", false)
	pac.GetSet(PART, "HidePhysgunBeam", false)
	pac.GetSet(PART, "UseLegacyScale", false)
	pac.GetSet(PART, "BloodColor", "BLOOD_COLOR_RED", {
		enums = {
			["Don't Bleed"] 	= "DONT_BLEED",
			["Red"] 			= "BLOOD_COLOR_RED",
			["Yellow"] 			= "BLOOD_COLOR_YELLOW",
			["Green"] 			= "BLOOD_COLOR_GREEN",
			["Sparks"] 			= "BLOOD_COLOR_MECH"
		}
	})
pac.SetPropertyGroup(PART, "behavior")
	pac.GetSet(PART, "InverseKinematics", false)
	pac.GetSet(PART, "MuteFootsteps", false)
	pac.GetSet(PART, "FallApartOnDeath", false)
	pac.GetSet(PART, "DeathRagdollizeParent", false)
	pac.GetSet(PART, "HideRagdollOnDeath", false)
pac.EndStorableVars()

local function ENTFIELD(PART, name, field)
	field = "pac_" .. field

	PART.ent_fields = PART.ent_fields or {}
	PART.ent_fields[field] = name

	PART["Set" .. name] = function(self, val)
		self[name] = val

		local owner = self:GetOwner()

		if owner:IsValid() then
			owner[field] = val
		end
	end
end

ENTFIELD(PART, "InverseKinematics", "enable_ik")
ENTFIELD(PART, "MuteFootsteps", "hide_weapon")
ENTFIELD(PART, "AnimationRate", "global_animation_rate")
ENTFIELD(PART, "FallApartOnDeath", "death_physics_parts")
ENTFIELD(PART, "DeathRagdollizeParent", "death_ragdollize")
ENTFIELD(PART, "HideRagdollOnDeath", "death_hide_ragdoll")
ENTFIELD(PART, "DrawPlayerOnDeath", "draw_player_on_death")
ENTFIELD(PART, "HidePhysgunBeam", "hide_physgun_beam")
ENTFIELD(PART, "MuteSounds", "mute_sounds")
ENTFIELD(PART, "AllowOggWhenMuted", "allow_ogg_sounds")
ENTFIELD(PART, "HideBullets", "hide_bullets")

function PART:GetNiceName()
	local ent = self:GetOwner()

	if ent:IsValid() then
		if ent:IsPlayer() then
			return ent:Nick()
		else
			return language.GetPhrase(ent:GetClass())
		end
	end

	return self.ClassName
end

function PART:OnShow()
	local ent = self:GetOwner()
	self:ReplicateBloodColor()

	if ent:IsValid() then
		for _, field in pairs(self.ent_fields) do
			self["Set" .. field](self, self[field])
		end
	end
end

function PART:OnThink()
	local ent = self:GetOwner()

	if ent:IsValid() then
		ent.pac_mute_footsteps = self.MuteFootsteps
	end
end

function PART:OnHide()
	local ent = self:GetOwner()
	self:ReplicateBloodColor(BLOOD_COLOR_RED)

	if ent:IsValid() then
		for key in pairs(self.ent_fields) do
			ent[key] = nil
		end
	end
end

function PART:ReplicateBloodColor(id)
	local ent = self:GetOwner()
	if not ent:IsValid() then return end
	if ent ~= pac.LocalPlayer then return end
	id = id or (getfenv(1) or _G)[self:GetBloodColor()]
	if type(id) ~= 'number' then return end

	net.Start("pac.BloodColor")
	net.WriteInt(id, 6)
	net.SendToServer()
end

function PART:SetBloodColor(newColor)
	-- if self:GetBloodColor() == newColor then return end
	self.BloodColor = newColor
	self:ReplicateBloodColor()
end

pac.RegisterPart(PART)