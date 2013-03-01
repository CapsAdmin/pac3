function pac.SetupENT(ENT, owner)	
	ENT.pac_owner = ENT.pac_owner or owner or "self"
	
	local function find(parent, name)
		for key, part in pairs(parent:GetChildren()) do
			if part:GetName():lower():find(name:lower()) then
				return part
			end

			local part = find(part, name)
			if part then return part end
		end
	end

	function ENT:FindPACPart(outfit, name)
		self.pac_part_find_cache = self.pac_part_find_cache or {}

		local part = self.pac_outfits[outfit.self.UniqueID] or pac.NULL

		if part:IsValid() then
			local cached = self.pac_part_find_cache[name] or pac.NULL

			if cached:IsValid() then return cached end

			part = find(part, name)

			if part:IsValid() then
				self.pac_part_find_cache[name] = part

				return part
			end
		end
	end

	function ENT:GetPACPartPosAng(outfit, name)
		local part = self:FindPACPart(outfit, name)

		if part then
			return part.cached_pos, part.cached_ang
		end
	end

	function ENT:AttachPACPart(outfit, owner)
		owner = owner or self.pac_owner or self.Owner
		
		if self.pac_owner == "self" then
			owner = self
		elseif self[self.pac_owner] then
			owner = self[self.pac_owner]
		end
		
		self.pac_outfits = self.pac_outfits or {}

		local part = self.pac_outfits[outfit.self.UniqueID] or pac.NULL

		if part:IsValid() then
			part:Remove()
		end

		part = pac.CreatePart(outfit.self.ClassName, owner)
		part:SetTable(outfit)

		self.pac_outfits[outfit.self.UniqueID] = part

		self.pac_part_find_cache = {}
		
		if self.pac_show_in_editor == nil then
			self:SetShowPACPartsInEditor(false)
			self.pac_show_in_editor = nil
		end
	end

	function ENT:RemovePACPart(outfit)
		self.pac_outfits = self.pac_outfits or {}

		local part = self.pac_outfits[outfit.self.UniqueID] or pac.NULL

		if part:IsValid() then
			part:Remove()
		end

		self.pac_part_find_cache = {}
	end
	
	function ENT:AttachPACSession(session)
		for _, part in pairs(session) do
			self:AttachPACPart(part)
		end
	end
	
	function ENT:RemovePACSession(session)
		for _, part in pairs(session) do
			self:RemovePACPart(part)
		end
	end
	
	function ENT:SetPACDrawDistance(dist)
		self.pac_draw_distance = dist
	end
	
	function ENT:GetPACDrawDistance()
		return self.pac_draw_distance
	end
		
	function ENT:SetShowPACPartsInEditor(b)
		self.pac_outfits = self.pac_outfits or {}
		
		for key, part in pairs(self.pac_outfits) do
			part.show_in_editor = b
		end
		
		self.pac_show_in_editor = b
	end
	
	function ENT:GetShowPACPartsInEditor()
		return self.pac_show_in_editor
	end
end

function pac.SetupSWEP(SWEP, owner)
	SWEP.pac_owner = owner or "Owner"	
	pac.SetupENT(SWEP, owner)	
end