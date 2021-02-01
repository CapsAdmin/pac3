local PART = {}

PART.ClassName = "player_movement"
PART.Group = "entity"
PART.Icon = "icon16/user_go.png"
PART.NonPhysical = true

local pac_movement_default = {}

local function ADD(PART, name, default, ...)
	pac.GetSet(PART, name, default, ...)

	pac_movement_default[name] = default

	PART["Set" .. name] = function(self, val)
		self[name] = val

		local ply = self:GetOwner(true)

		if ply == pac.LocalPlayer then
			local num = GetConVarNumber("pac_free_movement")
			if num == 1 or (num == -1 and hook.Run("PlayerNoClip", ply, true)) then
				ply.pac_movement = ply.pac_movement or table.Copy(pac_movement_default)
				ply.pac_movement[name] = val

				net.Start("pac_modify_movement")
					net.WriteString(name)
					net.WriteType(val)
				net.SendToServer()
			end
		end
	end

	PART.update_these = PART.update_these or {}

	table.insert(PART.update_these, function(s) PART["Set" .. name](s, PART["Get" .. name](s)) end)
end

pac.StartStorableVars()
	pac.SetPropertyGroup(PART, "generic")
		ADD(PART, "Noclip", false)
		ADD(PART, "Gravity", Vector(0, 0, -600))

	pac.SetPropertyGroup(PART, "movement")
		ADD(PART, "SprintSpeed", 400)
		ADD(PART, "RunSpeed", 200)
		ADD(PART, "WalkSpeed", 100)
		ADD(PART, "DuckSpeed", 25)

	pac.SetPropertyGroup(PART, "ground")
		ADD(PART, "JumpHeight", 200, {editor_clamp = {0,  10000}})
		ADD(PART, "MaxGroundSpeed", 750)
		ADD(PART, "StickToGround", true)
		ADD(PART, "GroundFriction", 0.12, {editor_clamp = {0,  1}, editor_sensitivity = 0.1})

	pac.SetPropertyGroup(PART, "air")
		ADD(PART, "AllowZVelocity", false)
		ADD(PART, "AirFriction", 0.01, {editor_clamp = {0,  1}, editor_sensitivity = 0.1})
		ADD(PART, "MaxAirSpeed", 1)

	pac.SetPropertyGroup(PART, "view angles")
		ADD(PART, "ReversePitch", false)
		ADD(PART, "UnlockPitch", false)
		ADD(PART, "VelocityToViewAngles", 0, {editor_clamp = {0,  1}, editor_sensitivity = 0.1})
		ADD(PART, "RollAmount", 0, {editor_sensitivity = 0.25})

	pac.SetPropertyGroup(PART, "fin")
		ADD(PART, "FinEfficiency", 0)
		ADD(PART, "FinLiftMode", "normal", {enums = {
			normal = "normal",
			none = "none",
		}})
		ADD(PART, "FinCline", false)

pac.EndStorableVars()

function PART:GetNiceName()
	local ent = self:GetOwner(true)
	local str = self.ClassName

	if ent:IsValid() then
		if ent:IsPlayer() then
			str = ent:Nick()
		else
			str = language.GetPhrase(ent:GetClass())
		end
	end

	return str .. "'s movement"
end

function PART:OnShow()
	local ent = self:GetOwner(true)

	if ent:IsValid() then
		for i,v in ipairs(self.update_these) do
			v(self)
		end
	end
end

function PART:OnHide()
	--if not self:IsEventHidden() then return end
	local ent = self:GetOwner(true)

	if ent == pac.LocalPlayer then
		net.Start("pac_modify_movement")
			net.WriteString("disable")
		net.SendToServer()

		ent.pac_movement = nil
	end
end

pac.RegisterPart(PART)