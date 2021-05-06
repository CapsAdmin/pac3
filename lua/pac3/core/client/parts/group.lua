local BUILDER, PART = pac.PartTemplate("base")

PART.ClassName = "group"

PART.Icon = 'icon16/world.png'
PART.Description = "right click to add parts"

BUILDER:StartStorableVars()
	BUILDER:GetSet("Duplicate", false)
	BUILDER:GetSet("OwnerName", "self")
BUILDER:EndStorableVars()

function PART:Initialize()
	timer.Simple(0, function()
		if self:IsValid() and not self:HasParent() and not self.Owner:IsValid() then
			self:UpdateOwnerName()
		end
	end)
end

function PART:SetOwner(ent)
	if not self:HasParent() then
		if IsValid(self.last_owner) and self.last_owner ~= ent then
			self:CallRecursive("OnHide", true)
		end

		self.last_owner = self.Owner
	end

	self.Owner = ent or NULL

	if not self:HasParent() then
		local owner = self:GetOwner()

		if self.last_owner:IsValid() then
			pac.UnhookEntityRender(self.last_owner, self)
		end

		if owner:IsValid() then
			pac.HookEntityRender(owner, self)
		end
	end
end

function PART:HideInvalidOwners()
	local prev_owner = self:GetOwner()

	if not prev_owner:IsValid() then
		self:SetOwner(NULL)
	end
end

function PART:UpdateOwnerName(ent)
	-- this is only supported by groups in root
	if self:HasParent() then return end

	local prev_owner = self:GetOwner()

	if self.Duplicate then
		ent = pac.HandleOwnerName(self:GetPlayerOwner(), self.OwnerName, ent, self, function(e) return e.pac_duplicate_attach_uid ~= self.UniqueID end) or NULL
		if ent ~= prev_owner and ent:IsValid() then

			local tbl = self:ToTable()
			tbl.self.OwnerName = "self"
			tbl.self.Duplicate = false
			pac.SetupENT(ent)
			local part = ent:AttachPACPart(tbl)
			part:SetShowInEditor(false)
			ent:CallOnRemove("pac_remove_outfit_" .. tbl.self.UniqueID, function()
				ent:RemovePACPart(tbl)
			end)

			if self:GetPlayerOwner() == pac.LocalPlayer then
				ent:SetPACDrawDistance(0)
			end

			ent.pac_duplicate_attach_uid = part:GetUniqueID()
		end
	else
		ent = pac.HandleOwnerName(self:GetPlayerOwner(), self.OwnerName, ent, self) or NULL
	end

	if ent ~= prev_owner then
		self:SetOwner(ent)
	end
end

local Base_SetPlayerOwner = PART.SetPlayerOwner

function PART:SetPlayerOwner(ply)
	local prev = self.PlayerOwner

	Base_SetPlayerOwner(self, ply)

	if prev:IsValid() then
		self:UpdateOwnerName()
	end
end

function PART:SetOwnerName(name)
	if name == "" then
		name = "self"
	end

	self.OwnerName = name

	if self.Owner:IsValid() then
		self:UpdateOwnerName()
	end
end

function PART:GetNiceName()
	return #self:GetChildrenList() .. " children"
end

function PART:OnVehicleChanged(ply, vehicle)
	if self:HasParent() then return end

	if self.OwnerName == "active vehicle" then
		self:UpdateOwnerName()
	end
end

BUILDER:Register()