local render_CullMode = render.CullMode
local render_SuppressEngineLighting = render.SuppressEngineLighting
local render_SetBlend = render.SetBlend
local render_SetColorModulation = render.SetColorModulation
local render_MaterialOverride = render.MaterialOverride
local game_SinglePlayer = game.SinglePlayer
local RunConsoleCommand = RunConsoleCommand
local Angle = Angle
local Vector = Vector
local NULL = NULL
local Color = Color

local PART = {}

PART.ClassName = "entity"

pac.StartStorableVars()
	pac.GetSet(PART, "Material", "")
	pac.GetSet(PART, "Model", "")
	pac.GetSet(PART, "Color", Vector(255, 255, 255))
	pac.GetSet(PART, "Brightness", 1)
	pac.GetSet(PART, "Alpha", 1)
	pac.GetSet(PART, "Scale", Vector(1,1,1))
	pac.GetSet(PART, "Size", 1)
	pac.GetSet(PART, "OverallSize", 1)
	pac.GetSet(PART, "HideEntity", false)
	pac.GetSet(PART, "Invert", false)
	pac.GetSet(PART, "DoubleFace", false)
	pac.GetSet(PART, "DrawWeapon", true)
	pac.GetSet(PART, "Fullbright", false)

	pac.GetSet(PART, "RelativeBones", true)

	pac.GetSet(PART, "Skin", 0)
	pac.GetSet(PART, "Bodygroup", 0)
	pac.GetSet(PART, "BodygroupState", 0)
	pac.GetSet(PART, "DrawShadow", true)
	pac.GetSet(PART, "Weapon", false)
	pac.GetSet(PART, "InverseKinematics", false)
	pac.GetSet(PART, "MuteFootsteps", false)
	pac.GetSet(PART, "MuteSounds", false)
	pac.GetSet(PART, "AllowOggWhenMuted", false)
	pac.GetSet(PART, "HideBullets", false)
	pac.GetSet(PART, "AnimationRate", 1)
	pac.GetSet(PART, "SprintSpeed", 0)
	pac.GetSet(PART, "RunSpeed", 0)
	pac.GetSet(PART, "WalkSpeed", 0)
	pac.GetSet(PART, "CrouchSpeed", 0)
	pac.GetSet(PART, "FallApartOnDeath", false)
	pac.GetSet(PART, "DeathRagdollizeParent", false)
	pac.GetSet(PART, "HideRagdollOnDeath", false)
	pac.GetSet(PART, "DrawPlayerOnDeath", false)
	pac.GetSet(PART, "HidePhysgunBeam", false)
	pac.GetSet(PART, "LodOverride", -1)

	pac.GetSet(PART, "UseLegacyScale", false)
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

ENTFIELD(PART, "RunSpeed", "run_speed")
ENTFIELD(PART, "WalkSpeed", "walk_speed")
ENTFIELD(PART, "CrouchSpeed", "crouch_speed")
ENTFIELD(PART, "SprintSpeed", "sprint_speed")

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

	if self.Weapon then
		return "Weapon"
	end

	return self.ClassName
end


function PART:SetUseLegacyScale(b)
	self.UseLegacyScale = b
	self:UpdateScale()
end

function PART:SetWeapon(b)
	self.Weapon = b
	if b then
		self:OnShow()
	else
		self:OnHide()
	end
end


function PART:OnBuildBonePositions()
	local ent = self:GetOwner()

	if self.OverallSize ~= 1 then
		for _ = 0, ent:GetBoneCount() do
			ent:ManipulateBoneScale(0, Vector(1, 1, 1) * self.OverallSize)
		end
	end
end

function PART:SetDrawShadow(b)
	self.DrawShadow = b

	local ent = self:GetOwner()
	if ent:IsValid() then
		ent:DrawShadow(b)
	end
end

function PART:SetBodygroupState(var)
	var = var or 0

	self.BodygroupState = var

	local ent = self:GetOwner()
	timer.Simple(0, function()
		if self:IsValid() and ent:IsValid() then
			ent:SetBodygroup(self.Bodygroup, var)
		end
	end)
end

function PART:SetBodygroup(var)
	var = var or 0

	self.Bodygroup = var

	local ent = self:GetOwner()
	timer.Simple(0, function()
		if self:IsValid() and ent:IsValid() then
			ent:SetBodygroup(var, self.BodygroupState)
		end
	end)
end

function PART:UpdateScale(ent)
	ent = ent or self:GetOwner()
	if ent:IsValid() then
		if self.UseLegacyScale then
			if ent:IsPlayer() or ent:IsNPC() then
				pac.SetModelScale(ent, nil, self.Size)
			else
				pac.SetModelScale(ent, self.Scale * self.Size)
			end
		else
			if ent:IsPlayer() or ent:IsNPC() then
				local size = ent:GetModelScale() -- compensate for serverside scales..
				pac.SetModelScale(ent, self.Scale * self.Size * (1/size))
			else
				pac.SetModelScale(ent, self.Scale * self.Size)
			end
		end
	end
end

function PART:SetSize(val)
	self.Size = val
	self:UpdateScale()
end

function PART:SetScale(val)
	self.Scale = val
	self:UpdateScale()
end

PART.Colorf = Vector(1,1,1)

function PART:SetColor(var)
	var = var or Vector(255, 255, 255)

	self.Color = var
	self.Colorf = Vector(var.r, var.g, var.b) / 255

	self.Colorc = self.Colorc or Color(var.r, var.g, var.b, self.Alpha)
	self.Colorc.r = var.r
	self.Colorc.g = var.g
	self.Colorc.b = var.b
end

function PART:SetAlpha(var)
	self.Alpha = var

	self.Colorc = self.Colorc or Color(self.Color.r, self.Color.g, self.Color.b, self.Alpha)
	self.Colorc.a = var
end

function PART:SetMaterial(var)
	var = var or ""

	if not pac.Handleurltex(self, var) then
		if var == "" then
			self.Materialm = nil
		else
			self.Materialm = pac.Material(var, self)
			self:CallEvent("material_changed")
		end
	end

	self.Material = var
end

function PART:SetRelativeBones(b)
	self.RelativeBones = b
	local ent = self:GetOwner()
	if ent:IsValid() then
		self:UpdateScale(ent)
	end
end

function PART:SetDrawWeapon(b)
	self.DrawWeapon = b
	self:UpdateWeaponDraw(self:GetOwner())
end

function PART:UpdateWeaponDraw(ent)
	local wep = ent and ent:IsValid() and ent.GetActiveWeapon and ent:GetActiveWeapon() or NULL

	if wep and wep:IsWeapon() then
		local hide = not self.DrawWeapon
		if hide == true then
			wep.pac_hide_weapon = hide
			pac.HideWeapon(wep, hide)
		end
	end
end

function PART:UpdateColor()
	render_SetColorModulation(self.Colorf.r * self.Brightness, self.Colorf.g * self.Brightness, self.Colorf.b * self.Brightness)
	render_SetBlend(self.Alpha)
end

function PART:UpdateMaterial()
	if self.Materialm then
		render_MaterialOverride(self.Materialm)
	end
end

function PART:UpdateAll(ent)
	self:UpdateColor(ent)
	self:UpdateMaterial(ent)
	self:UpdateScale(ent)
end

local angle_origin = Angle()

function PART:OnShow()
	local ent = self:GetOwner()

	if ent:IsValid() then

		if ent == pac.LocalPlayer and self.Model ~= "" then
			RunConsoleCommand("pac_setmodel", self.Model)
		end

		if self.Weapon and ent.GetActiveWeapon and ent:GetActiveWeapon():IsValid() then
			ent = ent:GetActiveWeapon()
		else
			if self.Model ~= "" and self:GetOwner() == pac.LocalPlayer and self.Model:lower() ~= self:GetOwner():GetModel():lower() then
				RunConsoleCommand("pac_setmodel", self.Model)
			end
		end

		for _, field in pairs(self.ent_fields) do
			self["Set" .. field](self, self[field])
		end


		self:SetColor(self:GetColor())
		ent:SetColor(self.Colorc)
		self:UpdateWeaponDraw(self:GetOwner())

		function ent.RenderOverride()
			if self:IsValid() then
				if not self.HideEntity then

					self:ModifiersPostEvent("PreDraw")
					self:PreEntityDraw(ent)

					local modpos = not self.Position:IsZero() or not self.Angles:IsZero()
					local pos

					if modpos then
						pos = ent:GetPos()

						self.cached_pos, self.cached_ang = self:GetDrawPosition(not self.Weapon and "none" or nil)

						ent:SetPos(self.cached_pos)
						ent:SetRenderAngles(self.cached_ang)
						ent:SetupBones()
					else
						self.cached_pos = ent:GetPos()
						self.cached_ang = ent:GetAngles()
					end

					ent:SetSkin(self.Skin)

					ent:DrawModel()

					if modpos then
						ent:SetPos(pos)
						ent:SetRenderAngles(angle_origin)
					end

					self:PostEntityDraw(ent)
					self:ModifiersPostEvent("OnDraw")
				end
			else
				ent.RenderOverride = nil
			end
		end

		self.current_ro = ent.RenderOverride

		self:UpdateScale()

		if self.LodOverride ~= -1 then self:SetLodOverride(self.LodOverride) end
	end
end

function PART:SetModel(str)
	self.Model = str

	local ent = self:GetOwner()
	if str ~= "" and ent:IsValid() and ent == pac.LocalPlayer then
		RunConsoleCommand("pac_setmodel", self.Model)
	end
end

function PART:SetLodOverride(num)
	self.LodOverride = num
	local owner = self:GetOwner()
	if owner:IsValid() then
		owner:SetLOD(num)
	end
end

function PART:OnThink()
	local ent = self:GetOwner()

	if ent:IsValid() then
		ent.pac_mute_footsteps = self.MuteFootsteps

		if self.Weapon and ent.GetActiveWeapon and ent:GetActiveWeapon():IsValid() then
			ent = ent:GetActiveWeapon()
		end

		-- holy shit why does shooting reset the scale in singleplayer
		-- dumb workaround
		if game_SinglePlayer() and ent:IsPlayer() and ent:GetModelScale() ~= self.Size then
			self:UpdateScale(ent)
		end

		if self.HideEntity or self.Weapon and self.current_ro ~= ent.RenderOverride then
			self:OnShow()
		end

		ent.pac_material = self.Material
		ent.pac_materialm = self.Materialm
		ent.pac_color = self.Colorf
		ent.pac_alpha = self.Alpha
		ent.pac_brightness = self.Brightness

		ent.pac_hide_entity = self.HideEntity
		ent.pac_fullbright = self.Fullbright
		ent.pac_invert = self.Invert
	end
end

function PART:OnHide()
	local ent = self:GetOwner()

	if ent:IsValid() then
		if self.Weapon and ent.GetActiveWeapon and ent:GetActiveWeapon():IsValid() then
			ent = ent:GetActiveWeapon()
		end

		ent.RenderOverride = nil
		ent:SetColor(Color(255, 255, 255, 255))

		ent.pac_material = nil
		ent.pac_materialm = nil
		ent.pac_color = nil
		ent.pac_alpha = nil
		ent.pac_brightness = nil

		ent.pac_hide_entity = nil
		ent.pac_fullbright = nil
		ent.pac_invert = nil

		for key in pairs(self.ent_fields) do
			ent[key] = nil
		end

		if self.UseLegacyScale then
			if ent:IsPlayer() then
				pac.SetModelScale(ent, nil, 1)
			else
				pac.SetModelScale(ent, Vector(1,1,1))
			end
		else
			pac.SetModelScale(ent, Vector(1,1,1))
		end

		local weps = ent.GetWeapons and ent:GetWeapons()

		if weps then
			for _, wep in pairs(weps) do
				wep.pac_hide_weapon = nil
				pac.HideWeapon(wep, false)
			end
		end

		if self.LodOverride ~= -1 then
			ent:SetLOD(-1)
		end
	end
end

function PART:SetHideEntity(b)
	self.HideEntity = b
	if b then
		self:OnHide()
	else
		self:OnShow()
	end
end

function PART:PreEntityDraw(ent)
	self:UpdateWeaponDraw(ent)

	self:UpdateColor(ent)
	self:UpdateMaterial(ent)

	if self.Invert then
		render_CullMode(1) -- MATERIAL_CULLMODE_CW
	end

	if self.Fullbright then
		render_SuppressEngineLighting(true)
	end
end

function PART:PostEntityDraw()
	if self.Invert then
		render_CullMode(0) -- MATERIAL_CULLMODE_CCW
	end

	if self.Fullbright then
		render_SuppressEngineLighting(false)
	end

	render_SetBlend(1)
	render_SetColorModulation(1,1,1)

	render_MaterialOverride()
end

pac.RegisterPart(PART)