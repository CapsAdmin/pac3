pac.PartTemplates = pac.PartTemplates or {}
pac.VariableOrder = {}
pac.GroupOrder = pac.GroupOrder or {}
pac.NetworkDictionary = pac.NetworkDictionary or {}

do
	local META = {}
	META.__index = META

	function META:StartStorableVars()

		self.store = true
		self.group = nil

		return self
	end

	function META:EndStorableVars()

		self.store = false
		self.group = nil

		return self
	end

	function META:GetPropData(key)
		return self.PropertyUserdata and self.PropertyUserdata[key] or nil
	end

	function META:PropData(key)
		self.PropertyUserdata = self.PropertyUserdata or {}
		self.PropertyUserdata[key] = self.PropertyUserdata[key] or {}
		return self.PropertyUserdata[key]
	end

	function META:StoreProp(key)
		self.PART.StorableVars = self.PART.StorableVars or {}
		self.PART.StorableVars[key] = key
	end

	function META:RemoveProp(key)
		self.PropertyUserdata = self.PropertyUserdata or {}
		self.PropertyUserdata[key] = nil

		self.PART.StorableVars = self.PART.StorableVars or {}
		self.PART.StorableVars[key] = nil
	end

	local function insert_key(tbl, key)
		for _, k in ipairs(tbl) do
			if k == key then
				return
			end
		end

		table.insert(tbl, key)
	end

	function META:SetPropertyGroup(name)

		local tbl = self.PART

		self.group = name

		if tbl then
			pac.GroupOrder[tbl.ClassName] = pac.GroupOrder[tbl.ClassName] or {}
			insert_key(pac.GroupOrder[tbl.ClassName], name)
		end

		pac.GroupOrder.none = pac.GroupOrder.none or {}
		insert_key(pac.GroupOrder.none, name)

		return self
	end

	function META:PropertyOrder(key)
		local tbl = self.PART

		pac.VariableOrder[tbl.ClassName] = pac.VariableOrder[tbl.ClassName] or {}
		insert_key(pac.VariableOrder[tbl.ClassName], key)

		if self.group then
			self:PropData(key).group = self.group
		end

		return self
	end

	function META:GetSet(key, def, udata)
		local tbl = self.PART

		pac.PrecacheNetwork(key)

		pac.VariableOrder[tbl.ClassName] = pac.VariableOrder[tbl.ClassName] or {}
		insert_key(pac.VariableOrder[tbl.ClassName], key)

		if type(def) == "number" then
			tbl["Set" .. key] = tbl["Set" .. key] or function(self, var) self[key] = tonumber(var) end
			tbl["Get" .. key] = tbl["Get" .. key] or function(self) return tonumber(self[key]) end
		elseif type(def) == "string" then
			tbl["Set" .. key] = tbl["Set" .. key] or function(self, var) self[key] = tostring(var) end
			tbl["Get" .. key] = tbl["Get" .. key] or function(self) return tostring(self[key]) end
		else
			tbl["Set" .. key] = tbl["Set" .. key] or function(self, var) self[key] = var end
			tbl["Get" .. key] = tbl["Get" .. key] or function(self) return self[key] end
		end

		tbl[key] = def

		if udata then
			table.Merge(self:PropData(key), udata)
		end

		if self.store then
			self:StoreProp(key)
		end

		if self.group then
			self:PropData(key).group = self.group
		end

		return self
	end

	function META:SetupPartName(key, udata)
		local PART = self.PART

		PART.PartNameResolvers = PART.PartNameResolvers or {}

		local part_key = key
		local part_set_key = "Set" .. part_key

		local uid_key = part_key .. "UID"
		local name_key = key .. "Name"
		local name_set_key = "Set" .. name_key

		local last_uid_key = "last_" .. uid_key:lower()
		local try_key = "try_" .. name_key:lower()

		local name_find_count_key = name_key:lower() .. "_try_count"

		-- these keys are ignored when table is set. it's kind of a hack..
		pac.PartNameKeysToIgnore = pac.PartNameKeysToIgnore or {}
		pac.PartNameKeysToIgnore[name_key] = true

		local group = self.group

		self:EndStorableVars()
			self:GetSet(part_key, NULL)
		self:StartStorableVars()

		self.group = group

		self:GetSet(name_key, "", udata or {editor_panel = "part"})
		self:GetSet(uid_key, "", {hidden = true})

		local BUILDER = self

		PART.ResolvePartNames = PART.ResolvePartNames or function(self, force)
			for _, func in ipairs(BUILDER.PartNameResolvers) do
				func(self, force)
			end
		end

		PART["Resolve" .. name_key] = function(self, force)
			PART.PartNameResolvers[part_key](self, force)
		end

		self.added_partname_solvers = self.added_partname_solvers or {}

		if not self.added_partname_solvers[name_key] then
			self.added_partname_solvers[name_key] = true
			self.PartNameResolvers = self.PartNameResolvers or {}

			table.insert(self.PartNameResolvers, function(self, force)
				if self[uid_key] == "" and self[name_key] == "" then return end

				if force or self[try_key] or self[uid_key] ~= "" and not IsValid(self[part_key]) then
					local part = pac.GetPartFromUniqueID(self.owner_id, self[uid_key])

					if IsValid(part) and part ~= self and self[part_key] ~= part then
						self[name_set_key](self, part)
						self[last_uid_key] = self[uid_key]
					elseif self[try_key] and not self.supress_part_name_find and self:GetPlayerOwner() == pac.LocalPlayer then -- match by name instead, only in editor
						for _, part in pairs(pac.GetLocalParts()) do
							if
								part ~= self and
								self[part_key] ~= part and
								part:GetName() == self[name_key]
							then
								self[name_set_key](self, part)
								break
							end

							self[last_uid_key] = self[uid_key]
						end

						self[try_key] = false
					end
				end
			end)
		end


		PART[name_set_key] = function(self, var)
			self[name_find_count_key] = 0

			if type(var) == "string" then
				if self[name_key] == var and self[uid_key] ~= "" then
					-- don't do anything to avoid editor from choosing random parts with the same name
					return
				end

				self[name_key] = var

				if var == "" then
					self[uid_key] = ""
					self[part_key] = NULL
					return
				else
					self[try_key] = true
				end

				timer.Simple(0, function() PART.PartNameResolvers[part_key](self) end)
			else
				self[name_key] = var.Name and var.Name ~= '' and var.Name or var:GetName()
				self[uid_key] = var.UniqueID
				self[part_set_key](self, var)
			end
		end

		return self
	end

	function META:RemoveProperty(key)
		self.PART["Set" .. key] = nil
		self.PART["Get" .. key] = nil
		self.PART["Is" .. key] = nil
		self.PART[key] = nil

		self:RemoveProp(key)

		return self
	end

	function META:Register()
		pac.RegisterPart(self.PART)
		pac.PartTemplates[self.PART.ClassName] = self
		return self
	end

	function pac.PartTemplate(name)
		local builder = {PART = {Builder = true}}

		if name and pac.PartTemplates[name] then
			builder = pac.CopyValue(pac.PartTemplates[name])
		end

		return setmetatable(builder, META), builder.PART
	end
end

function pac.PrecacheNetwork(key)
	local crc = tostring(util.CRC(key))

	if pac.NetworkDictionary[crc] and pac.NetworkDictionary[crc] ~= key then
		error('CRC32 Collision! ' .. crc .. ' is same for ' ..  key .. ' and ' .. pac.NetworkDictionary[crc])
	end

	pac.NetworkDictionary[crc] = key
	return crc
end

function pac.ExtractNetworkID(crc)
	return pac.NetworkDictionary[crc]
end

function pac.GetPropertyUserdata(obj, key)
	return pac.PartTemplates[obj.ClassName]:GetPropData(key) or {}
end