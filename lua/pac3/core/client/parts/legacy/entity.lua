local render_CullMode = render.CullMode
local render_SuppressEngineLighting = render.SuppressEngineLighting
local render_SetBlend = render.SetBlend
local render_SetColorModulation = render.SetColorModulation
local render_MaterialOverride = render.MaterialOverride
local game_SinglePlayer = game.SinglePlayer
local Angle = Angle
local Vector = Vector
local NULL = NULL
local Color = Color

local BUILDER, PART = pac.PartTemplate("base_drawable")

PART.FriendlyName = "legacy entity"
PART.ClassName = "entity"
PART.Group = 'legacy'
PART.Icon = 'icon16/brick.png'

BUILDER:StartStorableVars()
	BUILDER:SetPropertyGroup("generic")
		BUILDER:PropertyOrder("Name")
		BUILDER:PropertyOrder("Hide")
		BUILDER:GetSet("Model", "")
		BUILDER:GetSet("Material", "")
		BUILDER:GetSet("HideEntity", false)
		BUILDER:GetSet("DrawWeapon", true)
		BUILDER:GetSet("MuteSounds", false)
		BUILDER:GetSet("AllowOggWhenMuted", false)
		BUILDER:GetSet("HideBullets", false)
		BUILDER:GetSet("DrawPlayerOnDeath", false)
		BUILDER:GetSet("HidePhysgunBeam", false)
		BUILDER:GetSet("UseLegacyScale", false)
	BUILDER:SetPropertyGroup("appearance")
		BUILDER:GetSet("Color", Vector(255, 255, 255), {editor_panel = "color"})
		BUILDER:GetSet("Brightness", 1)
		BUILDER:GetSet("Alpha", 1, {editor_sensitivity = 0.25, editor_clamp = {0, 1}})
		BUILDER:GetSet("Fullbright", false)
		BUILDER:PropertyOrder("DrawOrder")
		BUILDER:PropertyOrder("Translucent")
		BUILDER:GetSet("Invert", false)
		BUILDER:GetSet("DoubleFace", false)
		BUILDER:GetSet("Skin", 0, {editor_onchange = function(self, num) return math.Round(math.max(tonumber(num), 0)) end})
		BUILDER:GetSet("DrawShadow", true)
		BUILDER:GetSet("LodOverride", -1)
	BUILDER:SetPropertyGroup("movement")
		BUILDER:GetSet("SprintSpeed", 0)
		BUILDER:GetSet("RunSpeed", 0)
		BUILDER:GetSet("WalkSpeed", 0)
		BUILDER:GetSet("CrouchSpeed", 0)
	BUILDER:SetPropertyGroup("orientation")
		BUILDER:PropertyOrder("AimPartName")
		BUILDER:PropertyOrder("Bone")
		BUILDER:PropertyOrder("Position")
		BUILDER:PropertyOrder("Angles")
		BUILDER:PropertyOrder("EyeAngles")
		BUILDER:GetSet("Size", 1, {editor_sensitivity = 0.25})
		BUILDER:GetSet("Scale", Vector(1,1,1))
	BUILDER:SetPropertyGroup("behavior")
		BUILDER:GetSet("RelativeBones", true)
		BUILDER:GetSet("Weapon", false)
		BUILDER:GetSet("InverseKinematics", false)
		BUILDER:GetSet("MuteFootsteps", false)
		BUILDER:GetSet("SuppressFrames", false)
		BUILDER:GetSet("AnimationRate", 1)
		BUILDER:GetSet("FallApartOnDeath", false)
		BUILDER:GetSet("DeathRagdollizeParent", false)
		BUILDER:GetSet("HideRagdollOnDeath", false)
		BUILDER:GetSetPart("EyeTarget")
BUILDER:EndStorableVars()

local ent_fields = {}

function BUILDER:EntityField(name, field)

	field = "pac_" .. field

	ent_fields[field] = name

	self.PART["Set" .. name] = function(self, val)
		self[name] = val

		local owner = self:GetOwner()

		if owner:IsValid() then
			owner[field] = val
		end
	end

end

BUILDER:EntityField("InverseKinematics", "enable_ik")
BUILDER:EntityField("MuteFootsteps", "mute_footsteps")
BUILDER:EntityField("AnimationRate", "global_animation_rate")

BUILDER:EntityField("RunSpeed", "run_speed")
BUILDER:EntityField("WalkSpeed", "walk_speed")
BUILDER:EntityField("CrouchSpeed", "crouch_speed")
BUILDER:EntityField("SprintSpeed", "sprint_speed")

BUILDER:EntityField("FallApartOnDeath", "death_physics_parts")
BUILDER:EntityField("DeathRagdollizeParent", "death_ragdollize")
BUILDER:EntityField("HideRagdollOnDeath", "death_hide_ragdoll")
BUILDER:EntityField("DrawPlayerOnDeath", "draw_player_on_death")
BUILDER:EntityField("HidePhysgunBeam", "hide_physgun_beam")

BUILDER:EntityField("MuteSounds", "mute_sounds")
BUILDER:EntityField("AllowOggWhenMuted", "allow_ogg_sounds")
BUILDER:EntityField("HideBullets", "hide_bullets")

function PART:Initialize()
	self:SetColor(self:GetColor())
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

function PART:SetDrawShadow(b)
	self.DrawShadow = b

	local ent = self:GetOwner()
	if ent:IsValid() then
		ent:DrawShadow(b)
	end
end

function PART:UpdateScale(ent)
	ent = ent or self:GetOwner()

	if not ent:IsValid() then return end

	if not self.UseLegacyScale then
		ent.pac3_Scale = self.Size
	end

	if ent:IsPlayer() or ent:IsNPC() then
		if self:GetPlayerOwner() == pac.LocalPlayer then
			pac.emut.MutateEntity(self:GetPlayerOwner(), "size", ent, self.Size)
		end
		pac.SetModelScale(ent, self.Scale)
	else
		pac.SetModelScale(ent, self.Scale * self.Size)
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
			self:CallRecursive("OnMaterialChanged")
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

function PART:UpdateWeaponDraw(ent)
	local wep = ent and ent:IsValid() and ent.GetActiveWeapon and ent:GetActiveWeapon() or NULL

	if wep:IsWeapon() then
		if not wep.pac_weapon_class then
			wep:SetNoDraw(not self.DrawWeapon)
		end
	end
end

function PART:UpdateColor()
	render_SetColorModulation(self.Colorf.r * self.Brightness, self.Colorf.g * self.Brightness, self.Colorf.b * self.Brightness)
	if pac.drawing_motionblur_alpha then return end
	render_SetBlend(self.Alpha)
end

function PART:UpdateMaterial()
	local mat = self.MaterialOverride or self.Materialm
	if mat then
		render_MaterialOverride(mat)
	end
end

function PART:UpdateAll(ent)
	self:UpdateColor(ent)
	self:UpdateMaterial(ent)
	self:UpdateScale(ent)
end

local angle_origin = Angle()

local function setup_suppress()
	local last_framenumber = 0
	local current_frame = 0
	local current_frame_count = 0

	return function()
		local frame_number = FrameNumber()

		if frame_number == last_framenumber then
			current_frame = current_frame + 1
		else
			last_framenumber = frame_number

			if current_frame_count ~= current_frame then
				current_frame_count = current_frame
			end

			current_frame = 1
		end

		return current_frame < current_frame_count
	end
end

function PART:OnShow()
	local ent = self:GetOwner()
	if not ent:IsValid() then return end

	self:SetModel(self:GetModel())

	if self.Weapon and ent.GetActiveWeapon and ent:GetActiveWeapon():IsValid() then
		ent = ent:GetActiveWeapon()
	end

	for _, field in pairs(ent_fields) do
		self["Set" .. field](self, self[field])
	end

	self:SetColor(self:GetColor())
	ent:SetColor(self.Colorc)
	self:UpdateWeaponDraw(self:GetOwner())

	function ent.RenderOverride()
		if self:IsValid() then
			if not self.HideEntity then
				if self.SuppressFrames then
					if not self.should_suppress then
						self.should_suppress = setup_suppress()
					end

					if self.should_suppress() then
						return
					end
				end

				self:ModifiersPostEvent("PreDraw")
				self:PreEntityDraw(ent)

				local modpos = not self.Position:IsZero() or not self.Angles:IsZero()
				local pos

				self.BoneOverride = nil

				if modpos then
					pos = ent:GetPos()

					self.BoneOverride = "none"

					local pos, ang = self:GetDrawPosition()
					ent:SetPos(pos)
					ent:SetRenderAngles(ang)
					pac.SetupBones(ent)
				end

				ent:SetSkin(self.Skin)

				if ent.pac_bodygroups_torender then
					for bgID, bgVal in pairs(ent.pac_bodygroups_torender) do
						ent:SetBodygroup(bgID, bgVal)
					end
				end

				ent.pac_bodygroups_torender = nil

				if self.EyeTarget.GetWorldPosition then
					ent:SetEyeTarget(self.EyeTarget:GetWorldPosition())
				end

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

local ALLOW_TO_MDL = CreateConVar('pac_allow_mdl', '1', CLIENT and {FCVAR_REPLICATED} or {FCVAR_ARCHIVE, FCVAR_REPLICATED}, 'Allow to use custom MDLs')
local ALLOW_TO_USE_MDL = CreateConVar('pac_allow_mdl_entity', '1', CLIENT and {FCVAR_REPLICATED} or {FCVAR_ARCHIVE, FCVAR_REPLICATED}, 'Allow to use custom MDLs as Entity')

function PART:SetModel(path)
	self.Model = path

	local ent = self:GetOwner()

	if not ent:IsValid() then return end

	pac.ResetBoneCache(ent)

	if path:find("^http") then
		local status, reason = hook.Run('PAC3AllowMDLDownload', self:GetPlayerOwner(), self, path)
		local status2, reason2 = hook.Run('PAC3AllowEntityMDLDownload', self:GetPlayerOwner(), self, path)

		if ALLOW_TO_USE_MDL:GetBool() and ALLOW_TO_MDL:GetBool() and status ~= false and status2 ~= false then
			if ent == pac.LocalPlayer then
				pac.Message("downloading ", path, " to use as player model")
			end

			pac.DownloadMDL(path, function(real_path)
				if not ent:IsValid() then return end

				if self:GetPlayerOwner() == pac.LocalPlayer then
					pac.Message("finished downloading ", path)
					pac.emut.MutateEntity(self:GetPlayerOwner(), "model", ent, self.Model)
				end

				ent:SetModel(real_path)

				ent:SetSubMaterial()

				for i = 0, #ent:GetBodyGroups() - 1 do
					ent:SetBodygroup(i, 0)
				end

				pac.ResetBoneCache(ent)

				for _, child in ipairs(self:GetChildrenList()) do
					child:OnShow(true)
				end
			end, function(err)
				pac.Message(err)
				self:SetError(err)
			end, self:GetPlayerOwner())

			self.mdl_zip = true
		else
			local msg = reason2 or reason or "mdl is not allowed"
			self.loading = msg
			self:SetError(msg)
			pac.Message(self:GetPlayerOwner(), ' - mdl files are not allowed')
		end
	elseif self.Model ~= "" then

		if self:GetPlayerOwner() == pac.LocalPlayer then
			pac.emut.MutateEntity(self:GetPlayerOwner(), "model", ent, self.Model)
		end

		ent:SetModel(self.Model)


		pac.RunNextFrame('entity updatemat ' .. tostring(ent), function()
			if not ent:IsValid() or not self:IsValid() then return end
			pac.ResetBoneCache(ent)
			ent:SetSubMaterial()

			for i = 0, #ent:GetBodyGroups() - 1 do
				ent:SetBodygroup(i, 0)
			end

			self:CallRecursive("CalcShowHide", true)
		end)

		self.mdl_zip = false
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

		if (self.HideEntity or self.Weapon) and self.current_ro ~= ent.RenderOverride then
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

function PART:OnRemove()
	local ent = self:GetOwner()

	if not ent:IsValid() then return end

	if self:GetPlayerOwner() == pac.LocalPlayer then
		pac.emut.RestoreMutations(self:GetPlayerOwner(), "model", ent)
		pac.emut.RestoreMutations(self:GetPlayerOwner(), "size", ent)
	end

	pac.SetModelScale(ent)
end

function PART:OnHide()
	local ent = self:GetOwner()

	if not ent:IsValid() then return end

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

	for key in pairs(ent_fields) do
		ent[key] = nil
	end

	if ent:IsPlayer() or ent:IsNPC() then
		-- do nothing, we want the player to feel small even on hide
	else
		pac.SetModelScale(ent, Vector(1,1,1))
	end

	local weps = ent.GetWeapons and ent:GetWeapons()

	if weps then
		for _, wep in pairs(weps) do
			if not wep.pac_weapon_class then
				wep:SetNoDraw(false)
			end
		end
	end

	if self.LodOverride ~= -1 then
		ent:SetLOD(-1)
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

BUILDER:Register()

do
	local IN_SPEED = IN_SPEED
	local IN_WALK = IN_WALK
	local IN_DUCK = IN_DUCK

	local function mod_speed(cmd, speed)
		if speed and speed ~= 0 then
			local forward = cmd:GetForwardMove()
			forward = forward > 0 and speed or forward < 0 and -speed or 0

			local side = cmd:GetSideMove()
			side = side > 0 and speed or side < 0 and -speed or 0


			cmd:SetForwardMove(forward)
			cmd:SetSideMove(side)
		end
	end

	pac.AddHook("CreateMove", "legacy_entity_part_speed_modifier", function(cmd)
		if cmd:KeyDown(IN_SPEED) then
			mod_speed(cmd, pac.LocalPlayer.pac_sprint_speed)
		elseif cmd:KeyDown(IN_WALK) then
			mod_speed(cmd, pac.LocalPlayer.pac_walk_speed)
		elseif cmd:KeyDown(IN_DUCK) then
			mod_speed(cmd, pac.LocalPlayer.pac_crouch_speed)
		else
			mod_speed(cmd, pac.LocalPlayer.pac_run_speed)
		end
	end)
end
