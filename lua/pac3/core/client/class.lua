local ipairs = ipairs
local table_insert = table.insert
local isnumber = isnumber
local tonumber = tonumber
local isstring = isstring
local tostring = tostring
local table_Merge = table.Merge
local istable = istable
local pac = pac
local setmetatable = setmetatable

pac.PartTemplates = pac.PartTemplates or {}
pac.VariableOrder = {}
pac.GroupOrder = pac.GroupOrder or {}

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

		table_insert(tbl, key)
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

		pac.VariableOrder[tbl.ClassName] = pac.VariableOrder[tbl.ClassName] or {}
		insert_key(pac.VariableOrder[tbl.ClassName], key)

		if isnumber(def) then
			tbl["Set" .. key] = tbl["Set" .. key] or function(self, var) self[key] = tonumber(var) end
			tbl["Get" .. key] = tbl["Get" .. key] or function(self) return tonumber(self[key]) end
		elseif isstring(def) then
			tbl["Set" .. key] = tbl["Set" .. key] or function(self, var) self[key] = tostring(var) end
			tbl["Get" .. key] = tbl["Get" .. key] or function(self) return tostring(self[key]) end
		else
			tbl["Set" .. key] = tbl["Set" .. key] or function(self, var) self[key] = var end
			tbl["Get" .. key] = tbl["Get" .. key] or function(self) return self[key] end
		end

		tbl[key] = def

		if udata then
			table_Merge(self:PropData(key), udata)
		end

		if self.store then
			self:StoreProp(key)
		end

		if self.group then
			self:PropData(key).group = self.group
		end

		return self
	end

	function META:GetSetPart(key, udata)
		udata = udata or {}
		udata.editor_panel = udata.editor_panel or "part"
		udata.part_key = key

		local PART = self.PART

		self:GetSet(key .. "UID", "", udata)

		PART["Set" .. key .. "UID"] = function(self, uid)
			if uid == "" or not uid then
				self["Set" .. key](self, NULL)
				self[key.."UID"] = ""
				return
			end

			if istable(uid) then
				uid = uid.UniqueID
			end

			self[key.."UID"] = uid

			local owner_id = self:GetPlayerOwnerId()
			local part = pac.GetPartFromUniqueID(owner_id, uid)

			if part:IsValid() then
				if part == self then
					part = NULL
					self[key.."UID"] = ""
				end

				self["Set" .. key](self, part)
			elseif uid ~= "" then
				self.unresolved_uid_parts = self.unresolved_uid_parts or {}
				self.unresolved_uid_parts[owner_id] = self.unresolved_uid_parts[owner_id] or {}
				self.unresolved_uid_parts[owner_id][uid] = self.unresolved_uid_parts[owner_id][uid] or {}
				self.unresolved_uid_parts[owner_id][uid][key] = key
			end
		end

		PART["Set" .. key] = PART["Set" .. key] or function(self, var)
			self[key] = var
			if var and var:IsValid() then
				self[key.."UID"] = var:GetUniqueID()
			else
				self[key.."UID"] = ""
			end
		end
		PART["Get" .. key] = PART["Get" .. key] or function(self) return self[key] end
		PART[key] = NULL

		PART.PartReferenceKeys = PART.PartReferenceKeys or {}
		PART.PartReferenceKeys[key] = key

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
		pac.PartTemplates[self.PART.ClassName] = self

		pac.RegisterPart(self.PART)

		return self
	end

	function pac.PartTemplate(name)
		local builder

		if name and pac.PartTemplates[name] then
			builder = pac.CopyValue(pac.PartTemplates[name])
		else
			builder = {PART = {}}
			builder.PART.Builder = builder
		end

		return setmetatable(builder, META), builder.PART
	end

	function pac.GetTemplate(name)
		return pac.PartTemplates[name]
	end
end

function pac.GetPropertyUserdata(obj, key)
	return pac.PartTemplates[obj.ClassName] and pac.PartTemplates[obj.ClassName]:GetPropData(key) or {}
end