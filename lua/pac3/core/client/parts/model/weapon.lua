local pac = pac
local NULL = NULL

local BUILDER, PART = pac.PartTemplate("model2")

PART.ClassName = "weapon"
PART.FriendlyName = "weapon"
PART.Category = "entity"
PART.ManualDraw = true
PART.HandleModifiersManually = true
PART.Icon = 'icon16/brick.png'
PART.Group = "entity"
PART.is_model_part = false

BUILDER:StartStorableVars()
	:SetPropertyGroup("generic")
		:PropertyOrder("Name")
		:PropertyOrder("Hide")
		:PropertyOrder("ParentName")
		:GetSet("OverridePosition", false)
		:GetSet("Class", "all", {enums = function()
			local out = {
				["physgun"] = "weapon_physgun",
				["357"] = "weapon_357",
				["alyxgun"] = "weapon_alyxgun",
				["annabelle"] = "weapon_annabelle",
				["ar2"] = "weapon_ar2",
				["brickbat"] = "weapon_brickbat",
				["bugbait"] = "weapon_bugbait",
				["crossbow"] = "weapon_crossbow",
				["crowbar"] = "weapon_crowbar",
				["frag"] = "weapon_frag",
				["physcannon"] = "weapon_physcannon",
				["pistol"] = "weapon_pistol",
				["rpg"] = "weapon_rpg",
				["shotgun"] = "weapon_shotgun",
				["smg1"] = "weapon_smg1",
				["striderbuster"] = "weapon_striderbuster",
				["stunstick"] = "weapon_stunstick",
			}
			for _, tbl in pairs(weapons.GetList()) do
				if not tbl.ClassName:StartWith("ai_") then
					local friendly = tbl.ClassName:match("weapon_(.+)") or tbl.ClassName
					out[friendly] = tbl.ClassName
				end
			end
			return out
		end})
	:SetPropertyGroup("appearance")
		:GetSet("NoDraw", false)
		:GetSet("DrawShadow", true)
	:SetPropertyGroup("orientation")
		:GetSet("Bone", "right hand")
	:EndStorableVars()

BUILDER:RemoveProperty("Model")
BUILDER:RemoveProperty("ForceObjUrl")

function PART:SetDrawShadow(b)
	self.DrawShadow = b

	local ent = self:GetOwner()
	if not ent:IsValid() then return end

	ent:DrawShadow(b)
	ent:MarkShadowAsDirty()
end

function PART:GetNiceName()
	if self.Class ~= "all" then
		return self.Class
	end
	return self.ClassName
end

function PART:Initialize()
	self.material_count = 0
end
function PART:OnDraw()
	local ent = self:GetOwner()
	if not ent:IsValid() then return end
	local pos, ang = self:GetDrawPosition()

	local old
	if self.OverridePosition then
		old = ent:GetParent()
		ent:SetParent(NULL)
		ent:SetPos(pos)
		ent:SetAngles(ang)
		pac.SetupBones(ent)
	end
	ent.pac_render = true

	self:PreEntityDraw(ent, pos, ang)
		self:DrawModel(ent, pos, ang)
	self:PostEntityDraw(ent, pos, ang)
	pac.ResetBones(ent)

	if self.OverridePosition then
		ent:MarkShadowAsDirty()
		ent:SetParent(old)
	end
	ent.pac_render = nil
end

PART.AlwaysThink = true

function PART:OnThink()
	local ent = self:GetRootPart():GetOwner()
	if ent:IsValid() and ent.GetActiveWeapon then
		local wep = ent:GetActiveWeapon()
		if wep:IsValid() then
			if wep ~= self.Owner then
				if self.Class == "all" or (self.Class:lower() == wep:GetClass():lower()) then
					self:OnHide()
					self.Owner = wep
					self:SetEventTrigger(self, false)
					wep.RenderOverride = function()
						if self:IsHiddenCached() then
							wep.RenderOverride = nil
							return
						end
						if wep.pac_render then
							if not self.NoDraw then
								if self.DrawShadow then
									wep:CreateShadow()
								end
								wep:DrawModel()
							end
						end
					end
					wep.pac_weapon_part = self
					self:SetDrawShadow(self:GetDrawShadow())
				else
					self:SetEventTrigger(self, true)
					self:OnHide()
				end
			end
		end
	end
end

function PART:OnShow(from_rendering)
	self.Owner = NULL
end

function PART:OnHide()
	local ent = self:GetRootPart():GetOwner()

	if ent:IsValid() and ent.GetActiveWeapon then
		for _, wep in pairs(ent:GetWeapons()) do
			if wep.pac_weapon_part == self then
				wep.RenderOverride = nil
				wep:SetParent(ent)
			end
		end
		self.Owner = NULL
	end
end

BUILDER:Register()