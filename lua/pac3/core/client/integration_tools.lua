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

function pac.AddEntityClassListener(class, session, check_func, draw_dist)
	
	if session.self then
		session = {session}
	end
	
	draw_dist = 0
	check_func = check_func or function(ent) return ent:GetClass() == class end
	
	local id = "pac_auto_attach_" .. class
	
	local weapons = {}
	local function weapon_think()
		for _, ent in pairs(weapons) do
			if ent.Owner and ent.Owner:IsValid() then
				if not ent.AttachPACSession then
					pac.SetupSWEP(ent)
				end
			
				if ent.Owner:GetActiveWeapon() == ent then
					if not ent.pac_deployed then
						ent:AttachPACSession(session)
						ent.pac_deployed = true			
					end
					
					ent.pac_last_owner = ent.Owner
				else
					if ent.pac_deployed then
						ent:RemovePACSession(session)
						ent.pac_deployed = false
					end
				end
			elseif (ent.pac_last_owner or NULL):IsValid() and not ent.pac_last_owner:Alive() then
				if ent.pac_deployed then
					ent:RemovePACSession(session)
					ent.pac_deployed = false
				end
			end
		end
	end
	
	local function created(ent)
		if ent:IsValid() and check_func(ent) then
			if ent:IsWeapon() then
				weapons[ent:EntIndex()] = ent
				hook.Add("Think", id, weapon_think)
			else
				pac.SetupENT(ent)
				ent:AttachPACSession(session)
				ent:SetPACDrawDistance(draw_dist)
			end
		end
	end
	
	local function removed(ent)
		if ent:IsValid() and check_func(ent) and ent.pac_outfits then
			ent:RemovePACSession(session)
			weapons[ent:EntIndex()] = nil
		end
	end
	
	for key, ent in pairs(ents.GetAll()) do
		created(ent)
	end
	
	hook.Add("EntityRemoved", id, removed)
	hook.Add("OnEntityCreated", id, created)
end

function pac.RemoveEntityClassListener(class, session, check_func)
	if session.self then
		session = {session}
	end
	
	check_func = check_func or function(ent) return ent:GetClass() == class end
	
	for key, ent in pairs(ents.GetAll()) do
		if check_func(ent) and ent.pac_outfits then
			ent:RemovePACSession(session)
		end
	end
	
	local id = "pac_auto_attach_" .. class
		
	hook.Remove("Think", id)
	hook.Remove("EntityRemoved", id)
	hook.Remove("OnEntityCreated", id)
end

timer.Simple(0, function()
	if easylua and luadev then
		function easylua.PACSetClassListener(class_name, name, b)
			if b == nil then
				b = true
			end
			
			luadev.RunOnClients(("pac.%s(%q, {%s})"):format(b and "AddEntityClassListener" or "RemoveEntityClassListener", class_name, file.Read("pac3/sessions/".. name .. ".txt", "DATA"))) 
		end
	end
end)