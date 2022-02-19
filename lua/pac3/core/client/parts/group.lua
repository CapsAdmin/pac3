local BUILDER, PART = pac.PartTemplate("base")

PART.ClassName = "group"

PART.Icon = 'icon16/world.png'
PART.Description = "right click to add parts"

BUILDER:StartStorableVars()
	BUILDER:GetSet("Duplicate", false)
	BUILDER:GetSet("OwnerName", "self")
BUILDER:EndStorableVars()

local init_list = {}
local init_index = 0

pac.AddHook("Think", "group_init", function()
	if init_index == 0 then return end

	for i = 1, init_index do
		local self = init_list[i]

		if self:IsValid() and not self:HasParent() and not self.Owner:IsValid() and not self.update_owner_once then
			self:UpdateOwnerName()
		end
	end

	init_list = {}
	init_index = 0
end)

function PART:Initialize()
	init_index = init_index + 1
	init_list[init_index] = self
end

function PART:SetOwner(ent)
	if self:HasParent() then
		self.Owner = ent or NULL
	else
		local owner = self:GetOwner()

		if owner:IsValid() then
			pac.UnhookEntityRender(owner, self)
		end

		self.Owner = ent or NULL
		owner = self:GetOwner()

		if owner:IsValid() then
			if not pac.HookEntityRender(owner, self) then
				self:ShowFromRendering()
			end
		end
	end
end

function PART:HideInvalidOwners()
	local prev_owner = self:GetOwner()

	if not prev_owner:IsValid() then
		self:SetOwner(NULL)
	end
end

function PART:UpdateOwnerName()
	-- this is only supported by groups in root
	self.update_owner_once = true
	if self:HasParent() then return end

	local ent
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