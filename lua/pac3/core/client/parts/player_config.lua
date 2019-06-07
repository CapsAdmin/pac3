local PART = {}

PART.ClassName = "player_config"
PART.Group = "experimental"
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
	pac.GetSet(PART, "DrawPlayerOnDeath", false)
	pac.GetSet(PART, "HidePhysgunBeam", false)
	pac.GetSet(PART, "UseLegacyScale", false)
	pac.GetSet(PART, "BloodColor", "red", {enums = blood_colors})
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

	self:UpdateBloodColor()

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

	self:UpdateBloodColor("red")

	if ent:IsValid() then
		for key in pairs(self.ent_fields) do
			ent[key] = nil
		end
	end
end

function PART:UpdateBloodColor(override)
	local ent = self:GetOwner()
	if ent == pac.LocalPlayer then
		local num = blood_colors[override or self.BloodColor]
		if num then
			net.Start("pac.BloodColor")
				net.WriteInt(num, 6)
			net.SendToServer()
		end
	end
end

function PART:SetBloodColor(str)
	self.BloodColor = str

	self:UpdateBloodColor()
end

pac.RegisterPart(PART)