local PART = {}

PART.ClassName = "base"

pac.GetSet(PART, "BoneIndex")
pac.GetSet(PART, "Hide", false)
pac.GetSet(PART, "Owner", NULL)
pac.GetSet(PART, "Outfit")
pac.GetSet(PART, "Tooltip")
pac.GetSet(PART, "SilkIcon", "plugin")

pac.StartStorableVars()
	pac.GetSet(PART, "Parent", "")
	pac.GetSet(PART, "Bone", "head")
	pac.GetSet(PART, "WeaponClass", "")
	pac.GetSet(PART, "HideWeaponClass", false)
	pac.GetSet(PART, "LocalPos", Vector(0,0,0))
	pac.GetSet(PART, "LocalAng", Angle(0,0,0))
	pac.GetSet(PART, "AngleVelocity", Angle(0,0,0))
	pac.GetSet(PART, "Name", "")
	pac.GetSet(PART, "Description", "")
pac.EndStorableVars()

do -- parenting and children
	function PART:SetParent(var)
		if self.Outfit then
			for key, part in ipairs(self.Outfit:GetParts()) do
				if var == part:GetName() and part:HasChild(self) then
					return false
				end
			end
		end

		self.Parent = var or ""
		if not var then
			self:OnParent(nil)
		end

		return true
	end

	function PART:GetChildren()
		local tbl = {}

		for key, part in ipairs(self.Outfit:GetParts()) do
			if part:GetParent() == self:GetName() then
				table.insert(tbl, part)
			end
		end

		return tbl
	end

	function PART:HasParent()
		return self:GetParent() ~= ""
	end

	function PART:HasChildren()
		return #self:GetChildren() > 0
	end

	function PART:HasChild(part)
		for key, child in ipairs(self:GetChildren()) do
			if child == part then
				return true
			end
		end
		return false
	end

	function PART:UpdateParent()
		for key, part in ipairs(self.Outfit:GetParts()) do
			if self.Parent == part:GetName() and part ~= self then
				self.RealParent = part
				self:OnParent(part)
				return
			end
		end
		self.RealParent = nil
	end
end

do -- bones
	function PART:SetBone(var)
		self.Bone = var
		self.BoneIndex = nil
	end

	function PART:ClearBone()
		self.BoneIndex = nil
	end

	function PART:GetModelBones()
		return pac.GetModelBones(self.Owner)
	end

	function PART:GetModelBonesSorted()
		return pac.GetModelBonesSorted(self.Owner)
	end

	function PART:GetRealBoneName(name, owner)
		owner = owner or self:GetOwner()

		if not owner.pac_bones and owner.pac_bones[name] and owner.pac_bones[name].real then
			owner.pac_bones = pac.GetAllBones(owner)
		end

		return owner:IsValid() and owner.pac_bones and owner.pac_bones[name] and owner.pac_bones[name].real or name
	end

	function PART:GetBonePosition(owner)
		owner = owner or self.Owner

		if not self.BoneIndex then
			self:UpdateBoneIndex(owner)
		end

		if self.Parent ~= "" and not self.RealParent or self.RealParent == self then
			self:UpdateParent()
		end

		local pos, ang
		if self.RealParent and self.RealParent:IsValid() then
			pos, ang = self.RealParent:GetDrawPosition()
		else
			pos, ang = owner:GetBonePosition(self.BoneIndex)
		end

		return pos, ang
	end

	function PART:UpdateBoneIndex(owner)
		owner = owner or self.Owner
		self.BoneIndex = owner:LookupBone(self:GetRealBoneName(self.Bone))
		if not self.BoneIndex and (owner:IsNPC() or owner:IsPlayer()) and owner.GetActiveWeapon then
			local wep = owner:GetActiveWeapon()

			if wep:IsWeapon() then
				self.BoneIndex = wep:LookupBone(self:GetRealBoneName(self.Bone, wep))
				if not self.BoneIndex then
					self.Error = self.Bone .. " cannot be found on '" .. tostring(owner) .. "' in both self and its active weapon"

					MsgN(self.Error)
				end
			end
		end
	end

end

do -- serializing
	function PART:AddStorableVar(var)
		self.StorableVars = self.StorableVars or {}

		self.StorableVars[var] = var
	end

	function PART:GetStorableVars()
		self.StorableVars = self.StorableVars or {}

		return self.StorableVars
	end

	function PART:SetTable(tbl)
		for key, value in pairs(tbl) do
			if self["Set" .. key] then
				self["Set" .. key](self, value)
			else
				self[key] = value
			end
		end
	end

	function PART:ToTable()
		local tbl = {}

		for _, key in pairs(self:GetStorableVars()) do
			tbl[key] = self[key]
		end

		tbl.ClassName = self.ClassName

		return tbl
	end
end

do -- events
	function PART:Initialize()

	end

	function PART:Remove()
		pac.CallHook("OnPartRemove", self)

		if self.Outfit then
			self:OnDetach(self.Outfit)
		end

		self:OnRemove()
		pac.MakeNull(self)
	end

	function PART:OnAttach() end
	function PART:OnDetach() end
	function PART:OnStore()	end
	function PART:OnRemove() end
	function PART:OnRestore() end
	function PART:OnParent() end

	function PART:OnSetOwner(ent)
		if not ent:IsPlayer() then
			self.PostDrawTranslucentRenderables = self.PostDrawTranslucentRenderables or self.PostPlayerDraw
		end
	end
end

function PART:SetHideWeaponClass(var)
	self.pac_weapons_reset = nil
	self.HideWeaponClass = var
end

function PART:GetName()
	return self.Name or "unknown name"
end

function PART:IsValid()
	return true
end

function PART:GetDrawPosition(owner)
	return LocalToWorld(self.LocalPos, self:GetVelocityAngle(self.LocalAng), self:GetBonePosition(owner))
end

function PART:GetVelocityAngle(ang)
	local v = self.AngleVelocity

	if v.p == 0 and v.y == 0 and v.r == 0 then
		self.LocalAngVel = nil
	else
		local delta = FrameTime() * 10
		self.LocalAngVel = self.LocalAngVel or Angle(0, 0, 0)

		self.LocalAngVel.p = (self.LocalAngVel.p or 0) + (v.p * delta)
		self.LocalAngVel.y = (self.LocalAngVel.y or 0) + (v.y * delta)
		self.LocalAngVel.r = (self.LocalAngVel.r or 0) + (v.r * delta)

		ang = self.LocalAngVel + self.LocalAng
	end

	return ang
end

function PART:Think()
	local ply = self:GetOwner()

	if ply.GetActiveWeapon then
		local wep = ply:GetActiveWeapon()

		--if wep ~= ply.pac_lastweapon then
			if wep:IsValid() then
				self:OnWeaponChanged(wep)
			end
		--	ply.pac_lastweapon = wep
		--end

	end

	if self.OnThink then self:OnThink() end
end

function PART:OnWeaponChanged(wep)

	if not self.pac_weapons_reset then
		for key, wep in pairs(self:GetOwner():GetWeapons()) do
			wep:SetColor(255,255,255,255)
		end

		self.pac_weapons_reset = true
	end

	wep.pac_bones = pac.GetAllBones(wep)

	if self.WeaponClass then
		local wep_class = wep:GetClass()

		-- todo: avoid concatenation?
		if pac.PatternCache[wep_class..self.WeaponClass] or wep_class:find(self.WeaponClass) then
			self.Hide = false
		else
			self.Hide = true
		end

		if not self.Hide and self.HideWeaponClass then
			wep:SetColor(255,255,255,0)
		elseif not self.Hide and not self.HideWeaponClass then
			wep:SetColor(255,255,255,255)
		end

	end
end

pac.RegisterPart(PART)