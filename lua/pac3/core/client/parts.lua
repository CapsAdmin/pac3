local class = pac.class

pac.ActiveParts = pac.ActiveParts or {}
local part_count = 0 -- unique id thing

function pac.CreatePart(name)
	local part = class.Create("part", name)

	if part.PreInitialize then 
		part:PreInitialize()
	end
	part:Initialize()

	table.insert(pac.ActiveParts, part)
	part.Id = part_count

	part:SetName("part " .. #pac.ActiveParts)
	part:SetPlayerOwner(LocalPlayer())

	pac.CallHook("OnPartCreated", part)
	
	part_count = part_count + 1

	return part
end

function pac.RegisterPart(META, name)
	if not META.Base then
		class.InsertIntoBaseField(META, "base")
	end
	class.Register(META, "part", name)
end

function pac.GetRegisteredParts()
	return class.GetAll("part")
end

function pac.GetPart(name)
	return class.Get("part", name)
end

function pac.GetParts(owned_only)
	if owned_only then		
		local tbl = {}
		for key, part in pairs(pac.ActiveParts) do
			if not part:IsValid() then
				pac.ActiveParts[key] = nil
			elseif part:GetPlayerOwner() == LocalPlayer() then
				table.insert(tbl, part)
			end
		end
		return tbl
	end
	for key, part in pairs(pac.ActiveParts) do
		if not part:IsValid() then
			pac.ActiveParts[key] = nil
		end
	end
	return pac.ActiveParts
end

function pac.RemoveAllParts()
	for key, part in pairs(pac.GetParts()) do
		if part:IsValid() then
			part:Remove()
		end
	end
	pac.ActiveParts = {}
end

function pac.GetPartCount(class, children)
	class = class:lower()
	local count = 0

	for key, part in pairs(children or pac.GetParts()) do
		if part.ClassName:lower() == class then
			count = count + 1
		end
	end

	return count
end

function pac.CallPartHook(name, ...)
	for key, part in pairs(pac.GetParts()) do
		if part[name] then
			part[name](part, ...)
		end
	end
end

do -- meta
	local PART = {}

	PART.ClassName = "base"
	PART.Internal = true

	function PART:__tostring()
		return string.format("%s[%s][%i]", self.Type, self.ClassName, self.Id)
	end
	
	pac.GetSet(PART, "BoneIndex")
	pac.GetSet(PART, "PlayerOwner", NULL)
	pac.GetSet(PART, "Owner", NULL)
	pac.GetSet(PART, "Parent", pac.NULL)
	pac.GetSet(PART, "Tooltip")
	pac.GetSet(PART, "SilkIcon", "plugin")

	pac.StartStorableVars()
		pac.GetSet(PART, "ParentName", "")
		pac.GetSet(PART, "Bone", "head")
		pac.GetSet(PART, "WeaponClass", "")
		pac.GetSet(PART, "HideWeaponClass", false)
		pac.GetSet(PART, "Position", Vector(0,0,0))
		pac.GetSet(PART, "Angles", Angle(0,0,0))
		pac.GetSet(PART, "AngleVelocity", Angle(0, 0, 0))
		pac.GetSet(PART, "EyeAngles", false)
		pac.GetSet(PART, "Name", "")
		pac.GetSet(PART, "Description", "")
		pac.GetSet(PART, "Hide", false)
	pac.EndStorableVars()
	
	function PART:PreInitialize()
		self.Children = {}
		
		self.Position = self.Position * 1
		self.Angles = self.Angles * 1
		self.AngleVelocity = self.AngleVelocity * 1
		
		self.Owner = NULL
		self.Parent = pac.NULL
	end
	
	do -- owner
		function PART:SetOwner(ent)
			ent = ent or NULL
			
			self.Owner = ent

			if ent.GetActiveWeapon and ent:GetActiveWeapon():IsWeapon() then
				self:OnWeaponChanged(ent:GetActiveWeapon())
			end
			
			if ent:IsValid() then
				self:OnAttach(ent)
			else
				self:OnDetach(ent)
			end
		end
		
		function PART:GetOwner()
			if not self.Owner:IsValid() then
				if self:GetParent():IsValid() then
					return self:GetParent():GetOwner()
				else
					return LocalPlayer() -- asdasdasdasd
				end
			end		
			
			return self.Owner
		end

		function PART:GetOwnerModelBones()
			return pac.GetModelBones(self:GetOwner())
		end

		function PART:GetOwnerModelBonesSorted()
			return pac.GetModelBonesSorted(self:GetOwner())
		end
	end

	do -- parenting
		function PART:CreatePart(name)
			local part = pac.CreatePart(name)
			self:AddChild(self)
			return part
		end
	
		function PART:SetParent(var)
			if not var or not var:IsValid() then
				self:UnParent()
				return false
			else
				return var:AddChild(self)
			end
		end
		
		function PART:SetParentName(var)		
			self:UnParent()
			self.ParentName = var
			self.ParentNameNotFound = nil
		end
		
		function PART:UpdateParentName()
			local name = self.ParentName
			
			if self.ParentNameNotFound == name then return end
			
			local parent
			
			for key, part in pairs(pac.GetParts()) do
				if part:GetOwner() == self:GetOwner() and part:GetName() == name then
					parent = part
					break
				end
			end
			
			if parent then
				self:SetParent(parent)
			else
				self.ParentNameNotFound = name
			end
		end
		
		function PART:AddChild(var)
			if not var or not var:IsValid() then self:UnParent() end
			if self == var or var:HasChild(self) then return false end
			
			local parts = self:GetChildren()

			var.Parent = self

			local id = table.insert(parts, var)
			
			var.ParentName = self:GetName()
			var:OnParent(self)
			self:OnChildAdd(var)

			return id
		end

		function PART:HasParent()
			return self.Parent and self.Parent:IsValid()
		end

		function PART:HasChildren()
			return #self:GetChildren() > 0
		end

		function PART:HasChild(part)
			for key, child in pairs(self:GetChildren()) do
				if child == part then
					return true
				end
			end
			return false
		end
		
		function PART:RemoveChild(var)
			local children = self:GetChildren()
			
			if children[var] then	
				if children[var]:IsValid() then
					children[var].Parent = pac.NULL
					children[var].ParentName = ""
					children[var] = nil
				end
			else
				for index, part in pairs(children) do
					if part == var then
						children[index].Parent = pac.NULL
						children[index].ParentName = ""
						children[index] = nil
						return
					end
				end
			end
			
			self.Children = children
		end
		
		function PART:GetRootPart()
			local p = self
			
			repeat
				p = p:GetParent()
			until not p:IsValid()
			
			return p
		end

		function PART:GetChildren()
			local children = self.Children
			
			for key, part in pairs(children) do
				if not part:IsValid() then
					children[key] = nil
				end
			end

			return children
		end
		
		function PART:RemoveChildren()
			for key, part in pairs(self:GetChildren()) do
				part:Remove()
			end
			self.Children = {}
		end

		function PART:GetChildByName(var)
			local parts = self:GetChildren()
			if parts[var] then
				return parts[var]
			else
				for index, part in pairs(parts[var]) do
					if part:GetName() == var then
						return self.Children[index]
					end
				end
			end
		end
		
		function PART:UnParent()
			local parent = self:GetParent()
			
			if parent:IsValid() then
				parent:RemoveChild(self)
			end
			
			self:OnUnParent()
		end
	end

	do -- bones
		function PART:SetBone(var)
			self.Bone = var
			self.BoneIndex = nil
			self.TriedToFindBone = nil
		end

		function PART:ClearBone()
			self.BoneIndex = nil
			self.TriedToFindBone = nil
		end

		function PART:GetModelBones()
			return pac.GetModelBones(self:GetOwner())
		end

		function PART:GetModelBonesSorted()
			return pac.GetModelBonesSorted(self:GetOwner())
		end

		function PART:GetRealBoneName(name, owner)
			owner = owner or self:GetOwner()

			if not owner.pac_bones or not owner.pac_bones[name] or not owner.pac_bones[name].real then
				owner.pac_bones = pac.GetAllBones(owner)
			end

			return owner:IsValid() and owner.pac_bones and owner.pac_bones[name] and owner.pac_bones[name].real or name
		end

		function PART:GetBonePosition(owner)
			owner = owner or self:GetOwner()
						
			if not self.BoneIndex and self.TriedToFindBone ~= self.Bone then
				self:UpdateBoneIndex(owner)
			end
			
			local pos, ang = owner:GetPos(), owner:GetAngles()
			
			if self.BoneIndex then
				if self.Parent:IsValid() and (self.Parent.ClassName ~= "group" and self.Parent.ClassName ~= "player") then
					pos, ang = self.Parent:GetDrawPosition()
				elseif owner:IsValid() then
					pos, ang = owner:GetBonePosition(self.BoneIndex)
				end
			end
				
			return pos, ang
		end

		function PART:UpdateBoneIndex(owner)
			owner = owner or self:GetOwner()
			self.BoneIndex = owner:LookupBone(self:GetRealBoneName(self.Bone))
			if not self.BoneIndex and (owner:IsNPC() or owner:IsPlayer()) and owner.GetActiveWeapon then
				local wep = owner:GetActiveWeapon()

				if wep:IsWeapon() then
					self.BoneIndex = wep:LookupBone(self:GetRealBoneName(self.Bone, wep))
					if not self.BoneIndex then
						self.Error = self.Bone .. " cannot be found on '" .. tostring(owner) .. "' in both self and its active weapon"
						MsgN(self.Error)
						self.TriedToFindBone = self.Bone
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

		function PART:Clear()
			self:RemoveChildren()
		end
		
		function PART:SetTable(tbl)
			for key, value in pairs(tbl.self) do
				if self["Set" .. key] then
					self["Set" .. key](self, value)
				else
					self[key] = value
				end
			end
			
			for key, value in pairs(tbl.children) do
				local part = pac.CreatePart(value.self.ClassName)
				part:SetOwner(self:GetOwner())
				part:SetTable(value)
				self:AddChild(part)
			end
		end
		
		local function COPY(var) 
			if type(var) == "Vector" or type(var) == "Angle" then 
				return var * 1 
			end 
			
			if type(var) == "table" then
				return table.Copy(var)
			end
			
			return var 
		end

		function PART:ToTable()
			local tbl = {self = {ClassName = self.ClassName}, children = {}}

			for _, key in pairs(self:GetStorableVars()) do
				tbl.self[key] = COPY(self[key])
			end
						
			for _, part in pairs(self:GetChildren()) do
				table.insert(tbl.children, part:ToTable())
			end

			return tbl
		end
		
		function PART:GetVars()
			local tbl = {}

			for _, key in pairs(self:GetStorableVars()) do
				tbl[key] = COPY(self[key])
			end
			
			return tbl			
		end
		
		function PART:Clone()
			local part = pac.CreatePart(self.ClassName)
			part:SetOwner(self:GetOwner())
			part:SetTable(self:ToTable())
			part:SetName(self:GetName() .. " copy")
			return part
		end
	end

	do -- events
		function PART:Initialize() end
		function PART:OnRemove() end
		
		function PART:Remove()
			pac.CallHook("OnPartRemove", self)

			if self.Parent then
				self:OnDetach(self.Parent)
			end

			for key, part in pairs(self:GetChildren()) do
				if part:IsValid() then
					part:Remove()
				end
			end
			
			self:OnRemove()
			pac.MakeNull(self)
		end

		function PART:OnAttach() end
		function PART:OnDetach() end
				
		function PART:OnStore()	end
		function PART:OnRestore() end
		
		function PART:OnThink()	end
		function PART:OnParent() end
		function PART:OnChildAdd() end
		function PART:OnUnParent() end
		function PART:Highlight() end
		function PART:OnWeaponChanged() end
		
		function PART:OnSetOwner(ent)
			if not ent:IsPlayer() then
				self.PostDrawTranslucentRenderables = self.PostDrawTranslucentRenderables or self.PostPlayerDraw
			end
		end
	end
	
	do -- highlight
		PART.highlight = 0

		function PART:Highlight()
			self.highlight = CurTime() + 0.1	
			
			for key, part in pairs(self:GetChildren()) do
				part.highlight = CurTime() + 0.1
				part:Highlight()
			end
		end

		function PART:IsHighlighting()
			return self.highlight > CurTime()
		end
	end
	
	do -- player specific		
		function PART:WeaponChanged(wep)

			if not self.pac_weapons_reset then
				for key, wep in pairs(self:GetOwner():GetWeapons()) do
					if net then 
						wep:SetColor(color_white)
					else
						wep:SetColor(255,255,255,255)
					end
				end

				self.pac_weapons_reset = true
			end

			wep.pac_bones = pac.GetAllBones(wep)

			if self.WeaponClass then
				local wep_class = wep:GetClass()

				-- todo: avoid concatenation?
				if pac.PatternCache[wep_class..self.WeaponClass] or wep_class:find(self.WeaponClass) then
					self.WeaponClassHidden = false
				else
					self.WeaponClassHidden = true
				end

				if not self:IsHidden() and self.HideWeaponClass then
					if net then 
						wep:SetColor(Color(255,255,255,0))
					else
						wep:SetColor(255,255,255,0)
					end
				elseif not self:IsHidden() and not self.HideWeaponClass then
					if net then
						wep:SetColor(Color(255,255,255,255))
					else
						wep:SetColor(255,255,255,255)
					end
				end

			end
		end
	end
	
	function PART:IsHidden()
		return self.Hide == true or self.WeaponClassHidden == true or self.EventHide == true or false
	end

	function PART:Draw(event)
		if self[event] and not self:IsHidden() then
			self[event](self, self:GetOwner(), self:GetDrawPosition())
		end
		for index, part in pairs(self:GetChildren()) do
			if part[event] and not part:IsHidden() then
				part:Draw(event)
			end
		end
	end
	
	function PART:SetWeaponClass(var)
		self.WeaponClass = var
		
		local owner = self:GetOwner()
		if owner.GetActiveWeapon then
			local wep = owner:GetActiveWeapon()
			if wep:IsValid() then
				self:WeaponChanged(wep) 
			end
		end
	end
		
	function PART:Think()
		local ply = self:GetOwner()

		if ply.GetActiveWeapon then
			local wep = ply:GetActiveWeapon()
			local class = wep:IsValid() and wep:GetClass() or ""
			
			if class ~= self.lastweapon then
				if class ~= "" then 
					self:WeaponChanged(wep) 
				end
				self.lastweapon = class
			end			
		end
		
		if not self.Parent:IsValid() and self.ParentName and self.ParentName ~= "" then
			self:UpdateParentName()
		end
	end
	
	function PART:SubmitToServer()
		pac.SubmitPart(self:GetOwner(), self:ToTable())
	end

	function PART:SetHideWeaponClass(var)
		self.pac_weapons_reset = nil
		self.HideWeaponClass = var
	end
	
	function PART:GetName()
		return self.Name or "no name"
	end

	function PART:IsValid()
		return true
	end

	function PART:CalcEyeAngles(pos, ang)
		if self.EyeAngles and self:GetOwner():IsPlayer() then
			pos, ang = LocalToWorld(self.Position, self:CalcAngleVelocity(self.Angles), pos, ang)
			ang = self.Angles + (self:GetOwner():GetEyeTraceNoCursor().HitPos - pos):Angle()
			return ang
		end
		
		return ang
	end
		
	function PART:CalcAngleVelocity(ang)
		local v = self.AngleVelocity
		
		if v.p == 0 and v.y == 0 and v.r == 0 then
			self.AnglesVel = nil
		else				
			local delta = FrameTime() * 10
			self.AnglesVel = self.AnglesVel or Angle(0, 0, 0)

			self.AnglesVel.p = self.AnglesVel.p + (v.p * delta)
			self.AnglesVel.y = self.AnglesVel.y + (v.y * delta)
			self.AnglesVel.r = self.AnglesVel.r + (v.r * delta)
				
			return self.AnglesVel + ang	
		end
		
		return ang
	end		
	
	function PART:GetDrawPosition(owner)
		owner = owner or self:GetOwner()
		
		if not owner:IsValid() then
			if self.Parent:IsValid() and self.Parent.ClassName == "model" and self.Parent:GetEntity():IsValid() then
				self:SetOwner(self.Parent:GetEntity())
			elseif pace.GetViewEntity():IsValid() then
				self:SetOwner(pace.GetViewEntity())
			else
				self:SetOwner(LocalPlayer())
			end
			owner = self:GetOwner()
		end
	
		
		if owner:IsValid() then
			local pos, ang = self:GetBonePosition(owner)
			
			ang = self:CalcEyeAngles(pos, ang)
			
			return LocalToWorld(
				self.Position, 
				self:CalcAngleVelocity(self.Angles), 
				pos or owner:GetPos(), 
				ang or owner:GetAngles()
			)
		end
		
		return Vector(0, 0, 0), Angle(0, 0, 0)
	end

	pac.RegisterPart(PART)
end