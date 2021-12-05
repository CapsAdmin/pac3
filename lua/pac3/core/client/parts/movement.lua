local BUILDER, PART = pac.PartTemplate("base")

PART.ClassName = "player_movement"
PART.Group = "entity"
PART.Icon = "icon16/user_go.png"


local pac_movement_default = {}
local update_these = {}

local function ADD(PART, name, default, ...)
	BUILDER:GetSet(name, default, ...)

	pac_movement_default[name] = default

	PART["Set" .. name] = function(self, val)
		self[name] = val

		local ply = self:GetRootPart():GetOwner()

		if ply == pac.LocalPlayer then

			if self:IsHidden() then return end

			local num = GetConVarNumber("pac_free_movement")
			if num == 1 or (num == -1 and hook.Run("PlayerNoClip", ply, true)) then
				ply.pac_movement = ply.pac_movement or table.Copy(pac_movement_default)

				if ply.pac_movement[name] ~= val then
					net.Start("pac_modify_movement", true)
						net.WriteString(name)
						net.WriteType(val)
					net.SendToServer()
				end
				ply.pac_movement[name] = val
			end
		end
	end

	table.insert(update_these, function(s) PART["Set" .. name](s, PART["Get" .. name](s)) end)
end

BUILDER:StartStorableVars()
	BUILDER:SetPropertyGroup("generic")
		ADD(PART, "Noclip", false)
		ADD(PART, "Gravity", Vector(0, 0, -600))

	BUILDER:SetPropertyGroup("movement")
		ADD(PART, "SprintSpeed", 400)
		ADD(PART, "RunSpeed", 200)
		ADD(PART, "WalkSpeed", 100)
		ADD(PART, "DuckSpeed", 25)

	BUILDER:SetPropertyGroup("ground")
		ADD(PART, "JumpHeight", 200, {editor_clamp = {0,  10000}})
		ADD(PART, "MaxGroundSpeed", 750)
		ADD(PART, "StickToGround", true)
		ADD(PART, "GroundFriction", 0.12, {editor_clamp = {0,  1}, editor_sensitivity = 0.1})

	BUILDER:SetPropertyGroup("air")
		ADD(PART, "AllowZVelocity", false)
		ADD(PART, "AirFriction", 0.01, {editor_clamp = {0,  1}, editor_sensitivity = 0.1})
		ADD(PART, "MaxAirSpeed", 1)

	BUILDER:SetPropertyGroup("view angles")
		ADD(PART, "ReversePitch", false)
		ADD(PART, "UnlockPitch", false)
		ADD(PART, "VelocityToViewAngles", 0, {editor_clamp = {0,  1}, editor_sensitivity = 0.1})
		ADD(PART, "RollAmount", 0, {editor_sensitivity = 0.25})

	BUILDER:SetPropertyGroup("fin")
		ADD(PART, "FinEfficiency", 0)
		ADD(PART, "FinLiftMode", "normal", {enums = {
			normal = "normal",
			none = "none",
		}})
		ADD(PART, "FinCline", false)

BUILDER:EndStorableVars()

function PART:GetNiceName()
	local ent = self:GetRootPart():GetOwner()
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
	local ent = self:GetRootPart():GetOwner()

	if ent:IsValid() then
		ent.last_movement_part = self:GetUniqueID()
		for i,v in ipairs(update_these) do
			v(self)
		end
	end
end

function PART:OnHide()
	local ent = self:GetRootPart():GetOwner()

	if ent == pac.LocalPlayer and ent.last_movement_part == self:GetUniqueID() then
		net.Start("pac_modify_movement", true)
			net.WriteString("disable")
		net.SendToServer()

		ent.pac_movement = nil
	end
end

BUILDER:Register()