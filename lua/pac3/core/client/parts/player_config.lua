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

BUILDER:SetPropertyGroup()
	BUILDER:GetSet("MuteSounds", false)
	BUILDER:GetSet("AllowOggWhenMuted", false)
	BUILDER:GetSet("HideBullets", false)
	BUILDER:GetSet("HidePhysgunBeam", false)
	BUILDER:GetSet("UseLegacyScale", false)
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

local function ENTFIELD(PART, name, field)
	field = "pac_" .. field

	ent_fields[field] = name

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

		if IsValid(player_manager) then
			pac.emut.RestoreMutations(player_owner, "blood_color", ent)
		end

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

BUILDER:Register()