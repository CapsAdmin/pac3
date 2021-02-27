local utility = pac999.utility

local entity = {}
entity.component_templates = {}

entity.entity_pool = utility.CreateObjectPool("entities")
entity.component_pools = {}

function entity.GetAll()
	return entity.entity_pool.list
end

function entity.GetAllComponents(name)
	return entity.component_pools[name] and entity.component_pools[name].list or {}
end

local function table_remove_value(tbl, val)
	for i, v in ipairs(tbl) do
		if v == val then
			table.remove(tbl, i)
			return true
		end
	end
	return false
end

do
	local META = {}

	META.removed = false

	function META:__index(key)

		if META[key] ~= nil then
			return META[key]
		end

		if self.ComponentFunctions[key] ~= nil then
			return self.ComponentFunctions[key]
		end

		error("no such key: " .. tostring(key), 2)
	end

	function META:__newindex(key, val)
		if META[key] == nil then
			error("cannot newindex: entity." .. tostring(key) .. " = " .. tostring(val), 2)
		end
	end

	function META:__tostring()
		local names = {}

		for _, component in ipairs(self.Components) do
			table.insert(names, component.ClassName)
		end

		return self.Name .. "[" .. table.concat(names, ",") .. "]" .. "[" .. self.Identifier .. "]"
	end

	META.Name = "entity"

	function META:SetName(str)
		rawset(self, "Name", str)
	end

	function META:IsValid()
		return self.removed ~= true
	end

	function META:Remove()
		if self.removed then return end

		self.removed = true

		self:FireEvent("Finish")

		for i = #self.Components, 1, -1 do
			self:RemoveComponent(self.Components[i].ClassName)
		end

		assert(#self.Components == 0)

		entity.entity_pool:remove(self)

		for event in pairs(self.events) do
			self:RemoveEvents(event)
		end
	end


	function META:BuildAccessibleComponentFunctions()
		self.ComponentFunctions = {}

		local blacklist = {
			Start = true,
			Finish = true,
		}

		for _, component in ipairs(self.Components) do
			for key, val in pairs(getmetatable(component)) do
				if not blacklist[key] and type(val) == "function" then
					local old = self.ComponentFunctions[key]
					if old then
						self.ComponentFunctions[key] = function(ent, ...)
							old(ent, ...)
							return component[key](component, ...)
						end
					else
						self.ComponentFunctions[key] = function(ent, ...)
							return component[key](component, ...)
						end
					end
				end
			end
		end
	end

	local i = 0
	local function gen_component_id()
		i = i + 1
		return tostring(i)
	end

	function META:AddComponent(name)
		local meta = assert(entity.component_templates[name])
		local component = setmetatable({entity = self}, meta)
		component.id = gen_component_id()

		if meta.StorableVars then
			for key in pairs(meta.StorableVars) do
				component[key] = pac999.utility.CopyValue(meta[key]) or meta[key]
			end
		end

		if component.Start then
			component:Start()
		end

		rawset(self, name, component)
		table.insert(self.Components, component)
		entity.component_pools[meta.ClassName]:insert(component)

		for event_name, callback in pairs(meta.EVENTS) do
			self:AddEvent(event_name, callback, "metatable_" .. name, component)
		end

		self:BuildAccessibleComponentFunctions()

		return component
	end

	function META:RemoveComponent(name)
		local component = assert(self[name])

		if component.Finish then
			component:Finish()
		end

		rawset(self, name, nil)
		assert(table_remove_value(self.Components, component))
		entity.component_pools[component.ClassName]:remove(component)

		for event_name in pairs(entity.component_templates[name].EVENTS) do
			self:RemoveEvent(event_name, "metatable_" .. name)
		end

		self:BuildAccessibleComponentFunctions()
	end

	function META:HasComponent(name)
		return rawget(self, name) ~= nil
	end

	do
		function META:FireEvent(name, ...)
			if not self:IsValid() then
				error("firing event " .. name ..  " on invalid entity", 2)
			end

			if not self.events[name] then return false end

			for _, event in ipairs(self.events[name]) do

				if event.component then
					if not event.component:IsValid() then
						error("firing event " .. name ..  " on invalid component", 2)
					end
				end

				event.callback(event.component or self, ...)
			end
		end

		function META:AddEvent(name, callback, sub_id, component)
			self.events[name] = self.events[name] or {}

			local event = {
				callback = callback,
				id = sub_id or #self.events[name],
				component = component,
			}

			table.insert(self.events[name], event)
			return event.id
		end

		function META:RemoveEvents(name)
			if not self.events[name] then return false end

			for i in ipairs(self.events[name]) do
				self.events[name][i] = nil
			end

			self.events[name] = nil

			return true
		end

		function META:RemoveEvent(name, sub_id)
			if not self.events[name] then return false end

			for i, event in ipairs(self.events[name]) do
				if event.id == sub_id then
					table.remove(self.events[name], i)

					if not self.events[name][1] then
						self.events[name] = nil
					end

					return true
				end
			end

			return false
		end
	end

	function entity.ComponentTemplate(name, required)
		local META = {}
		META.ClassName = name
		META.EVENTS = {}
		META.RequiredComponents = required
		META.__index = META

		META.id = -1

		function META:__tostring()
			local name = self.entity.Name
			if name == "entity" then
				name = ""
			else
				name = name .. ": "
			end

			return name .. "component[" .. self.ClassName .. "]["..self.id.."]"
		end

		META.removed = false

		function META:IsValid()
			return self.removed == false
		end

		function META:Remove()
			self.removed = true
			self.entity:RemoveComponent(name)
		end

		local BUILDER = {}
		do
			pac999.VariableOrder = {}

			BUILDER.META = META

			function BUILDER:StartStorableVars()

				self.store = true
				self.group = nil

				return self
			end

			function BUILDER:EndStorableVars()

				self.store = false
				self.group = nil

				return self
			end

			function BUILDER:GetPropData(key)
				return self.PropertyUserdata and self.PropertyUserdata[key] or nil
			end

			function BUILDER:PropData(key)
				self.PropertyUserdata = self.PropertyUserdata or {}
				self.PropertyUserdata[key] = self.PropertyUserdata[key] or {}
				return self.PropertyUserdata[key]
			end

			function BUILDER:StoreProp(key)
				self.META.StorableVars = self.META.StorableVars or {}
				self.META.StorableVars[key] = key
			end

			function BUILDER:RemoveProp(key)
				self.PropertyUserdata = self.PropertyUserdata or {}
				self.PropertyUserdata[key] = nil

				self.META.StorableVars = self.META.StorableVars or {}
				self.META.StorableVars[key] = nil
			end

			local function insert_key(tbl, key)
				for _, k in ipairs(tbl) do
					if k == key then
						return
					end
				end

				table.insert(tbl, key)
			end

			function BUILDER:SetPropertyGroup(name)

				local tbl = self.META

				self.group = name

				if tbl then
					pac999.GroupOrder[tbl.ClassName] = pac999.GroupOrder[tbl.ClassName] or {}
					insert_key(pac999.GroupOrder[tbl.ClassName], name)
				end

				pac999.GroupOrder.none = pac999.GroupOrder.none or {}
				insert_key(pac999.GroupOrder.none, name)

				return self
			end

			function BUILDER:PropertyOrder(key)
				local tbl = self.META

				pac999.VariableOrder[tbl.ClassName] = pac999.VariableOrder[tbl.ClassName] or {}
				insert_key(pac999.VariableOrder[tbl.ClassName], key)

				if self.group then
					self:PropData(key).group = self.group
				end

				return self
			end

			function BUILDER:GetSet(key, def, udata)
				local tbl = self.META

				pac999.VariableOrder[tbl.ClassName] = pac999.VariableOrder[tbl.ClassName] or {}
				insert_key(pac999.VariableOrder[tbl.ClassName], key)

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

			function BUILDER:GetSetPart(key, udata)
				udata = udata or {}
				udata.editor_panel = udata.editor_panel or "part"
				udata.part_key = key

				local META = self.META

				self:GetSet(key .. "UID", "", udata)

				META["Set" .. key .. "UID"] = function(self, uid)
					if type(uid) == "table" then
						uid = uid.UniqueID
					end

					self[key.."UID"] = uid

					local owner_id = self:GetPlayerOwner():UniqueID()
					local part = pac999.GetPartFromUniqueID(owner_id, uid)

					if part:IsValid() then
						self["Set" .. key](self, part)
					elseif uid ~= "" then
						self.unresolved_uid_parts = self.unresolved_uid_parts or {}
						self.unresolved_uid_parts[owner_id] = self.unresolved_uid_parts[owner_id] or {}
						self.unresolved_uid_parts[owner_id][uid] = self.unresolved_uid_parts[owner_id][uid] or {}
						self.unresolved_uid_parts[owner_id][uid][key] = key
					end
				end

				META["Set" .. key] = META["Set" .. key] or function(self, var) self[key] = var end
				META["Get" .. key] = META["Get" .. key] or function(self) return self[key] end
				META[key] = NULL

				return self
			end

			function BUILDER:RemoveProperty(key)
				self.META["Set" .. key] = nil
				self.META["Get" .. key] = nil
				self.META["Is" .. key] = nil
				self.META[key] = nil

				self:RemoveProp(key)

				return self
			end

			function BUILDER:Register()
				entity.Register(META)
			end
		end

		return BUILDER, META
	end

	function entity.Register(META)
		assert(META.ClassName)

		entity.component_pools[META.ClassName] =
		entity.component_pools[META.ClassName] or utility.CreateObjectPool(META.ClassName)

		entity.component_templates[META.ClassName] = META
	end

	local function get_metatables(component_names, metatables, done)
		metatables = metatables or {}
		done = done or {}

		for _, name in ipairs(component_names) do
			local meta = entity.component_templates[name]

			if not meta then
				error(name .. " is an unknown component")
			end

			if not done[name] then
				table.insert(metatables, meta)
				done[name] = true
			end

			if meta.RequiredComponents then
				get_metatables(meta.RequiredComponents, metatables, done)
			end
		end

		return metatables
	end

	local ref = 0

	function entity.Create(component_names)
		local self = setmetatable({
			Identifier = ref,
			Components = {},
			ComponentFunctions = {},
			events = {},
		}, META)

		ref = ref + 1

		entity.entity_pool:insert(self)

		if component_names then
			for _, name in ipairs(component_names) do
				self:AddComponent(name)
			end
		end

		return self
	end
end

pac999.AddHook("PreDrawOpaqueRenderables", function()
	for _, obj in ipairs(pac999.entity.GetAll()) do
		obj:FireEvent("Update")
	end
end)

return entity