local BUILDER, PART = pac.PartTemplate("base")

PART.ClassName = "player_config"
PART.Group = "entity"
PART.Icon = 'icon16/brick.png'


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

BUILDER:StartStorableVars()

BUILDER:SetPropertyGroup("generic")
	BUILDER:GetSet("MuteSounds", false)
	BUILDER:GetSet("AllowOggWhenMuted", false)
	BUILDER:GetSet("HideBullets", false)
	BUILDER:GetSet("HidePhysgunBeam", false)
	BUILDER:GetSet("UseLegacyScale", false)
	BUILDER:GetSet("GrabEarAnimation", true)
	BUILDER:GetSet("BloodColor", "red", {enums = blood_colors})

BUILDER:SetPropertyGroup("behavior")
	BUILDER:GetSet("MuteFootsteps", false)

BUILDER:SetPropertyGroup("death")
	BUILDER:GetSet("FallApartOnDeath", false)
	BUILDER:GetSet("DeathRagdollizeParent", true)
	BUILDER:GetSet("DrawPlayerOnDeath", false)
	BUILDER:GetSet("HideRagdollOnDeath", false)

BUILDER:EndStorableVars()

local ent_fields = {}

function BUILDER:EntityField(name, field)
	field = "pac_" .. field

	ent_fields[field] = name

	self.PART["Set" .. name] = function(self, val)
		self[name] = val

		local owner = self:GetActualOwner()

		if owner:IsValid() then
			owner[field] = val
		end
	end
end

BUILDER:EntityField("InverseKinematics", "enable_ik")
BUILDER:EntityField("MuteFootsteps", "mute_footsteps")
BUILDER:EntityField("AnimationRate", "global_animation_rate")
BUILDER:EntityField("FallApartOnDeath", "death_physics_parts")
BUILDER:EntityField("DeathRagdollizeParent", "death_ragdollize")
BUILDER:EntityField("HideRagdollOnDeath", "death_hide_ragdoll")
BUILDER:EntityField("DrawPlayerOnDeath", "draw_player_on_death")
BUILDER:EntityField("HidePhysgunBeam", "hide_physgun_beam")
BUILDER:EntityField("MuteSounds", "mute_sounds")
BUILDER:EntityField("AllowOggWhenMuted", "allow_ogg_sounds")
BUILDER:EntityField("HideBullets", "hide_bullets")

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

	if ent:IsValid() then
		pac.emut.MutateEntity(self:GetPlayerOwner(), "blood_color", ent, blood_colors[self.BloodColor == "" and "red" or self.BloodColor])
	end

	if ent:IsValid() then
		for _, field in pairs(ent_fields) do
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

		pac.emut.RestoreMutations(player_owner, "blood_color", ent)

		for key in pairs(ent_fields) do
			ent[key] = nil
		end
	end
end

function PART:SetBloodColor(str)
	self.BloodColor = str

	local ent = self:GetActualOwner()
	if ent:IsValid() then
		pac.emut.MutateEntity(self:GetPlayerOwner(), "blood_color", ent, blood_colors[self.BloodColor == "" and "red" or self.BloodColor])
	end
end

function PART:SetGrabEarAnimation(b)
	self.GrabEarAnimation = b

	local ent = self:GetActualOwner()
	if ent:IsValid() then
		ent.pac_disable_ear_grab = not b
	end
end

BUILDER:Register()
