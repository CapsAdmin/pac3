local PART = {}

PART.ClassName = "player_config"
PART.Group = "entity"
PART.Icon = 'icon16/brick.png'
PART.NonPhysical = true

local blood_colors = {
	dont_bleed = _G.DONT_BLEED,
	red = _G.BLOOD_COLOR_RED,
	yellow = _G.BLOOD_COLOR_YELLOW,
	green = _G.BLOOD_COLOR_GREEN,
	mech = _G.BLOOD_COLOR_MECH,
	antlion = _G.BLOOD_COLOR_ANTLION,
	zombie = _G.BLOOD_COLOR_ZOMBIE,
	antlion_worker = _G.BLOOD_COLOR_ANTLION_WORKER,
}

pac.StartStorableVars()

pac.SetPropertyGroup()
	pac.GetSet(PART, "MuteSounds", false)
	pac.GetSet(PART, "AllowOggWhenMuted", false)
	pac.GetSet(PART, "HideBullets", false)
	pac.GetSet(PART, "HidePhysgunBeam", false)
	pac.GetSet(PART, "UseLegacyScale", false)
	pac.GetSet(PART, "BloodColor", "red", {enums = blood_colors})

pac.SetPropertyGroup(PART, "behavior")
	pac.GetSet(PART, "MuteFootsteps", false)

pac.SetPropertyGroup(PART, "death")
	pac.GetSet(PART, "FallApartOnDeath", false)
	pac.GetSet(PART, "DeathRagdollizeParent", true)
	pac.GetSet(PART, "DrawPlayerOnDeath", false)
	pac.GetSet(PART, "HideRagdollOnDeath", false)

pac.EndStorableVars()

local function ENTFIELD(PART, name, field)
	field = "pac_" .. field

	PART.ent_fields = PART.ent_fields or {}
	PART.ent_fields[field] = name

	PART["Set" .. name] = function(self, val)
		self[name] = val

		local owner = self:GetActualOwner()

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

function PART:GetActualOwner()
	local owner = self:GetOwner()
	if owner:IsValid() and owner:GetRagdollOwner():IsPlayer() then
		return owner:GetRagdollOwner()
	end
	return owner
end

function PART:GetNiceName()
	local ent = self:GetActualOwner()

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
	local ent = self:GetActualOwner()
	pac.emut.MutateEntity(self:GetPlayerOwner(), "blood_color", ent, blood_colors[self.BloodColor == "" and "red" or self.BloodColor])

	if ent:IsValid() then
		for _, field in pairs(self.ent_fields) do
			self["Set" .. field](self, self[field])
		end
	end
end

function PART:OnThink()
	local ent = self:GetActualOwner()

	if ent:IsValid() then
		ent.pac_mute_footsteps = self.MuteFootsteps
	end
end

function PART:OnHide()
	local ent = self:GetActualOwner()

	if ent:IsValid() then
		local player_owner = self:GetPlayerOwner()

		if IsValid(player_manager) then
			pac.emut.RestoreMutations(player_owner, "blood_color", ent)
		end

		for key in pairs(self.ent_fields) do
			ent[key] = nil
		end
	end
end

function PART:SetBloodColor(str)
	self.BloodColor = str

	local ent = self:GetActualOwner()
	pac.emut.MutateEntity(self:GetPlayerOwner(), "blood_color", ent, blood_colors[self.BloodColor == "" and "red" or self.BloodColor])
end

pac.RegisterPart(PART)