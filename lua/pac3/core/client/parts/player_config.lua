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
pac.SetPropertyGroup(PART, "movement")
	pac.GetSet(PART, "SprintSpeed", -1, {editor_clamp = {-1,  10000}})
	pac.GetSet(PART, "RunSpeed", -1, {editor_clamp = {-1,  10000}})
	pac.GetSet(PART, "WalkSpeed", -1, {editor_clamp = {-1,  10000}})
	pac.GetSet(PART, "CrouchSpeed", -1, {editor_clamp = {-1,  10000}})
	pac.GetSet(PART, "JumpHeight", -1, {editor_clamp = {-1,  10000}})
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

do
	local function ADD(func, func2)
		PART["Set" .. func] = function(self, val)
			self[func] = val
			self["Update" .. func](self)
		end

		PART["Update" .. func] = function(self, disable)
			local ply = self:GetOwner()

			if ply == pac.LocalPlayer then
				local num = GetConVarNumber("pac_free_movement")
				if num == 1 or (num == -1 and hook.Run("PlayerNoClip", ply, true)) or disable then
					local val = disable and -1 or self[func]

					ply[func2](ply, val)
					net.Start("pac_modify_movement")
						net.WriteString(func)
						net.WriteFloat(val)
					net.SendToServer()
				end
			end
		end
	end

	ADD("RunSpeed", "SetRunSpeed")
	ADD("WalkSpeed", "SetWalkSpeed")
	ADD("CrouchSpeed", "SetCrouchedWalkSpeed")
	--ADD("AltWalkSpeed")
	--ADD("AltCrouchSpeed")
	ADD("JumpHeight", "SetJumpPower")
end

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

	if ent:IsValid() then

		for _, field in pairs(self.ent_fields) do
			self["Set" .. field](self, self[field])
		end

		self:UpdateWalkSpeed()
		self:UpdateRunSpeed()
		self:UpdateCrouchSpeed()
		self:UpdateJumpHeight()
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

	if ent:IsValid() then
		for key in pairs(self.ent_fields) do
			ent[key] = nil
		end

		self:UpdateWalkSpeed(true)
		self:UpdateRunSpeed(true)
		self:UpdateCrouchSpeed(true)
		self:UpdateJumpHeight(true)
	end
end

pac.RegisterPart(PART)