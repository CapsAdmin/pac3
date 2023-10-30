local pac = pac
local Vector = Vector
local Angle = Angle

local BUILDER, PART = pac.PartTemplate("model2")

PART.FriendlyName = "entity"
PART.ClassName = "entity2"
PART.Category = "entity"
PART.ManualDraw = true
PART.HandleModifiersManually = true
PART.Icon = 'icon16/brick.png'
PART.Group = "entity"
PART.is_entity_part = true

BUILDER:StartStorableVars()
	:SetPropertyGroup("generic")
		:PropertyOrder("Name")
		:PropertyOrder("Hide")
		:PropertyOrder("ParentName")
	:SetPropertyGroup("appearance")
		:GetSet("NoDraw", false)
		:GetSet("DrawShadow", true)
		:GetSet("InverseKinematics", true)

	:SetPropertyGroup("hull")
		:GetSet("StandingHullHeight", 72, {editor_panel = "hull"})
		:GetSet("CrouchingHullHeight", 36, {editor_panel = "hull", crouch = true})
		:GetSet("HullWidth", 32, {editor_panel = "hull"})
:EndStorableVars()

BUILDER:RemoveProperty("BoneMerge")
BUILDER:RemoveProperty("Bone")
BUILDER:RemoveProperty("EyeAngles")
BUILDER:RemoveProperty("AimPartName")
BUILDER:RemoveProperty("ForceObjUrl")

function PART:SetDrawShadow(b)
	self.DrawShadow = b

	local ent = self:GetOwner()
	if not ent:IsValid() then return end

	ent:DrawShadow(b)
	ent:MarkShadowAsDirty()
end

function PART:SetStandingHullHeight(val)
	self.StandingHullHeight = val
	self:ApplyMatrix()
end
function PART:SetCrouchingHullHeight(val)
	self.CrouchingHullHeight = val
	self:ApplyMatrix()
end
function PART:SetHullWidth(val)
	self.HullWidth = val
	self:ApplyMatrix()
end

function PART:GetNiceName()
	local str = pac.PrettifyName(("/" .. self:GetModel()):match(".+/(.-)%.")) or self:GetModel()

	local class_name = "NULL"
	local ent = self:GetOwner()

	if ent:IsValid() then
		class_name = ent:GetClass()
	end

	return (str and str:gsub("%d", "") or "error") .. " " .. class_name .. " model"
end

function PART:SetPosition(pos)
	self.Position = pos
	self:ApplyMatrix()
end

function PART:SetAngles(ang)
	self.Angles = ang
	self:ApplyMatrix()
end

function PART:SetPositionOffset(pos)
	self.PositionOffset = pos
	self:ApplyMatrix()
end

function PART:SetAngleOffset(ang)
	self.AngleOffset = ang
	self:ApplyMatrix()
end

function PART:GetBonePosition()
	local ent = self:GetParentOwner()
	if not ent:IsValid() then return Vector(), Angle() end
	local ang = ent:GetAngles()
	if ent:IsPlayer() then
		ang.p = 0
	end
	return ent:GetPos(), ang
end

-- this also implicitly overrides parent init to not create a custom owner
function PART:Initialize()
	self.material_count = 0
end

function PART:OnDraw()
	local ent = self:GetOwner()
	local pos, ang = self:GetDrawPosition()
	self:PreEntityDraw(ent, pos, ang)
		self:DrawModel(ent, pos, ang)
	self:PostEntityDraw(ent, pos, ang)
end

local temp_mat = Material( "models/error/new light1" )

function PART:RenderOverride(ent)
	-- if the draw call is not from pac don't bother
	if not ent.pac_drawing_model then
		if not ent.pac_is_drawing and ent ~= pac.LocalPlayer and ent.pac_ragdoll_owner ~= pac.LocalPlayer then
			ent.RenderOverride = nil
			ent:DisableMatrix("RenderMultiply")
			ent:SetSkin(0)
			ent:SetLOD(-1)
		end
		return
	end

	if self:IsValid() and self:GetParentOwner():IsValid() then
		if ent.pac_bonemerged then
			for _, e in ipairs(ent.pac_bonemerged) do
				if e.pac_drawing_model then return end
			end
		end

		-- so eyes work
		if self.NoDraw then
			if ent == pac.LocalViewModel or ent == pac.LocalHands then return end
			render.SetBlend(0)
			render.ModelMaterialOverride(temp_mat)
			ent.pac_drawing_model = true
			ent:DrawModel()
			ent.pac_drawing_model = false
			render.SetBlend(1)
			render.ModelMaterialOverride()
			return
		end

		ent:SetSkin(self:GetSkin())
		self:Draw(self.Translucent and "translucent" or "opaque")
	else
		ent.RenderOverride = nil
	end
end

function PART:OnShow()
	local ent = self:GetOwner()

	if not ent:IsValid() then return end

	function ent.RenderOverride()
		if self:IsValid() then
			self:RenderOverride(ent)
		else
			ent.RenderOverride = nil
		end
	end

	if not self.real_model then
		self.real_model = ent:GetModel()
	end

	if not (self.old_model == self:GetModel()) or
	(pac.LocalHands:IsValid() and ent == pac.LocalHands
	and not (self.real_model == pac.LocalHands:GetModel())) then
		self.old_model = self:GetModel()
		self:SetModel(self:GetModel())
	end

	self:SetDrawShadow(self:GetDrawShadow())
	self:RefreshModel()
	self:ApplyMatrix()
end

function PART:OnHide()
	local ent = self:GetParentOwner()

	if ent:IsValid() then
		ent.RenderOverride = nil
		ent:DisableMatrix("RenderMultiply")
		ent:SetSkin(0)
		ent:SetLOD(-1)
	end
end

function PART:RealSetModel(path)
	local ent = self:GetOwner()
	if not ent:IsValid() then return end

	ent:SetModel(path)
	self.real_model = path
	self:RefreshModel()
end

function PART:OnRemove()
	local ent = self:GetOwner()
	if not ent:IsValid() then return end

	local player_owner = self:GetPlayerOwner()

	pac.emut.RestoreMutations(player_owner, "model", ent)

	if ent:IsPlayer() or ent:IsNPC() then
		pac.emut.RestoreMutations(player_owner, "size", ent)
	end

	ent:DisableMatrix("RenderMultiply")
end

function PART:SetInverseKinematics(b)
	self.InverseKinematics = b

	local ent = self:GetParentOwner()

	if ent:IsValid() then
		ent.pac_enable_ik = b
		self:ApplyMatrix()
	end
end

function PART:OnThink()
	self:CheckBoneMerge()

	local ent = self:GetOwner()

	if ent:IsValid() then
		local model = ent:GetModel()
		local bone_count = ent:GetBoneCount()
		if
			self.last_model ~= model or
			self.last_bone_count ~= bone_count
		then
			self:RefreshModel()
			self.last_model = model
			self.last_bone_count = bone_count
		end
	end
end

BUILDER:Register()