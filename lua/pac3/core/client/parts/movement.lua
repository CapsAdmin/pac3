local PART = {}

PART.ClassName = "player_movement"
PART.Group = "experimental"
PART.Icon = "icon16/brick_go.png"
PART.NonPhysical = true

pac.StartStorableVars()
pac.SetPropertyGroup(PART, "movement")
	pac.GetSet(PART, "SprintSpeed", -1, {editor_clamp = {-1,  10000}})
	pac.GetSet(PART, "RunSpeed", -1, {editor_clamp = {-1,  10000}})
	pac.GetSet(PART, "WalkSpeed", -1, {editor_clamp = {-1,  10000}})
	pac.GetSet(PART, "CrouchSpeed", -1, {editor_clamp = {-1,  10000}})
	pac.GetSet(PART, "JumpHeight", -1, {editor_clamp = {-1,  10000}})
pac.EndStorableVars()

do
	CreateConVar("pac_free_movement", -1, {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "allow players to modify movement. -1 apply only allow when noclip is allowed, 1 allow for all gamemodes, 0 to disable")

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
		self:UpdateWalkSpeed()
		self:UpdateRunSpeed()
		self:UpdateCrouchSpeed()
		self:UpdateJumpHeight()
	end
end

function PART:OnHide()
	local ent = self:GetOwner()

	if ent:IsValid() then
		self:UpdateWalkSpeed(true)
		self:UpdateRunSpeed(true)
		self:UpdateCrouchSpeed(true)
		self:UpdateJumpHeight(true)
	end
end

pac.RegisterPart(PART)