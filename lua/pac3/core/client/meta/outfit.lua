local L = pac.LanguageString

local OUTFIT = {}
OUTFIT.ClassName = "outfit"
OUTFIT.Type = "outfit"
OUTFIT.__index = OUTFIT
OUTFIT.__tostring = function(self) return string.format("pac_outfit[%s][%s]", tostring(self:GetOwner()), self:GetName()) end

OUTFIT.Parts = {}
OUTFIT.Name = "No Name"
OUTFIT.Description = ""
OUTFIT.Owner = NULL

pac.StartStorableVars()
	pac.GetSet(OUTFIT, "Name", "")
	pac.GetSet(OUTFIT, "Description", "")

	pac.GetSet(OUTFIT, "HidePlayer", false)
	pac.GetSet(OUTFIT, "HideWeapon", false)
	pac.GetSet(OUTFIT, "Scale", Vector(1,1,1))

	pac.GetSet(OUTFIT, "Color", Color(255, 255, 255, 255))
	pac.GetSet(OUTFIT, "Material", "")

	pac.GetSet(OUTFIT, "Hue", 0)
	pac.GetSet(OUTFIT, "Saturation", 1)
	pac.GetSet(OUTFIT, "Brightness", 1)
pac.EndStorableVars()


pac.GetSet(OUTFIT, "Model", "")
pac.GetSet(OUTFIT, "Owner", NULL)

function OUTFIT:OnAttach(ent)
	ent.pac_bones = pac.GetAllBones(ent)

	for key, part in pairs(self:GetParts()) do
		part:SetOwner(ent)
		part:OnAttach(self)
		if ent.GetActiveWeapon and ent:GetActiveWeapon():IsWeapon() then
			part:OnWeaponChanged(ent:GetActiveWeapon())
		end
	end
end

function OUTFIT:OnDetach(ent)
	ent:SetColor(255, 255, 255, 255)
	ent:SetMaterial("")
	--ent:SetModel("")

	for key, part in pairs(self:GetParts()) do
		part:OnDetach(self)
		part:SetOwner(ent)
	end
end

function OUTFIT:GetOwnerModelBones()
	return pac.GetModelBones(self.Owner)
end

function OUTFIT:GetOwnerModelBonesSorted()
	return pac.GetModelBonesSorted(self.Owner)
end

function OUTFIT:GetOwnerWeaponBones()
	if not self.Owner.GetActiveWeapon then return false end
	local wep = self.Owner:GetActiveWeapon()
	return wep:IsWeapon() and wep.pac_bones
end

function OUTFIT:Clear()
	for index, part in pairs(self:GetParts()) do
		part:Remove()
	end

	self.Parts = {}

	self:SetOwner(self.Owner)
end

function OUTFIT:Remove()
	pac.CallHook("OnOutfitRemove", self)
	pac.SubmitOutfit(self.Owner, self.Name)
	self:Clear()
	pac.RemoveOutfit(self)
	pac.MakeNull(self)
end
do -- serializing
	function OUTFIT:AddStorableVar(var)
		self.StorableVars = self.StorableVars or {}

		self.StorableVars[var] = var
	end

	function OUTFIT:GetStorableVars()
		self.StorableVars = self.StorableVars or {}

		return self.StorableVars
	end

	function OUTFIT:SetTable(outfit_data)
		if not outfit_data then return end

		for key, val in pairs(outfit_data) do
			if key ~= "Parts" then
				self["Set"..key](self, val)
			end
		end

		for _, data in pairs(outfit_data.Parts) do
			local part = pac.CreatePart(data.ClassName)

			part.Outfit = self

			if part then
				data.ClassName = nil
				part:SetTable(data)
			end

			self:AddPart(part)
		end

		for key, part in ipairs(self:GetParts()) do
			part:SetParent(part:GetParent())
			part:UpdateParent()
			part:UpdateBoneIndex()
		end
	end

	function OUTFIT:ToTable()
		local tbl = {}
		tbl.Parts = {}

		for _, name in pairs(self.StorableVars) do
			tbl[name] = self[name]
		end

		for key, part in pairs(self:GetParts()) do
			table.insert(tbl.Parts, part:ToTable())
		end

		return tbl
	end
end

function OUTFIT:Draw(event)
	for index, part in pairs(self:GetParts()) do
		if part[event] and not part.Hide then
			part[event](part, self.Owner, part:GetDrawPosition())
		end
	end
end

function OUTFIT:CallPartFunc(func, ...)
	for key, part in pairs(self:GetParts()) do
		if part[func] then
			part[func](part, ...)
		end
	end
end

function OUTFIT:SetOwner(ent)
	if pac.IsValidEntity(ent) then
		if pac.IsValidEntity(self.Owner) then
			self:OnDetach(self.Owner)
		end

		self.Owner = ent
		self:OnAttach(ent)
		self:CallPartFunc("ClearBone")
		self:CallPartFunc("OnSetOwner", ent)
	end
end

function OUTFIT:IsValid()
	return true
end

do -- parts
	function OUTFIT:AddPart(var)
		var.Outfit = self
		var.Owner = self.Owner

		local owner = self:GetOwner()

		if owner.GetActiveWeapon and owner:GetActiveWeapon():IsWeapon() then
			var:OnWeaponChanged(owner:GetActiveWeapon())
		end

		for key, part in ipairs(self:GetParts()) do
			if part:GetName() == var.Name then
				var.Name = var.Name .. " conflict"
			end
		end

		local id = table.insert(self:GetParts(), var)

		var:OnAttach(self)

		return id
	end

	function OUTFIT:RemovePart(var)
		if self:GetParts()[var] and self:GetParts()[var]:IsValid() then
			self.Parts[var]:Remove()
			self.Parts[var] = nil
		else
			for index, part in pairs(self:GetParts()) do
				if part == var then
					self.Parts[index]:Remove()
					self.Parts[index] = nil
					return
				end
			end
		end
	end

	function OUTFIT:GetPartCount(class)
		class = class:lower()
		local count = 0

		for key, part in pairs(self:GetParts()) do
			if part.ClassName:lower() == class then
				count = count + 1
			end
		end

		return count
	end

	function OUTFIT:GetParts(class)
		for key, part in pairs(self.Parts) do
			if not part:IsValid() then
				self.Parts[key] = nil
			end
		end

		return self.Parts
	end

	function OUTFIT:GetPart(var)
		if self:GetParts()[var] then
			return self.Parts[var]
		else
			for index, part in pairs(self:GetParts()) do
				if part:GetName() == var then
					return self.Parts[index]
				end
			end
		end
	end
end

function OUTFIT:AddStorableVar(var)
	self.StorableVars = self.StorableVars or {}

	self.StorableVars[var] = var
end

function OUTFIT:GetStorableVars()
	self.StorableVars = self.StorableVars or {}

	return self.StorableVars
end

function OUTFIT:SubmitToServer()
	pac.SubmitOutfit(self.Owner, self:ToTable())
end

pac.OutfitMeta = OUTFIT