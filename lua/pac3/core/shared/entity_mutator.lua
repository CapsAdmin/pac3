-- rate limit?

local CLIENT = CLIENT
local SERVER = SERVER

if pac.emut then
	for _, ent in ipairs(ents.GetAll()) do
		if ent.pac_mutations then
			for _, mutator in pairs(ent.pac_mutations) do
				xpcall(pac.emut.RestoreMutations, function() end, mutator.Owner, mutator.ClassName, mutator.Entity)
			end
		end
	end
end

local emut = {}

pac.emut = emut

emut.registered_mutators = {}

do
	-- TOOD: use list instead of hash map
	emut.active_mutators = {}

	function emut.AddMutator(mutator)
		emut.active_mutators[mutator] = mutator
	end

	function emut.RemoveMutator(mutator)
		emut.active_mutators[mutator] = nil
	end

	function emut.RemoveMutatorsOwnedByEntity(ent)
		if not ent.pac_mutations then return end

		for class_name, mutator in pairs(ent.pac_mutations) do
			emut.RemoveMutator(mutator)
			ent.pac_mutations[class_name] = nil
		end
	end

	function emut.GetAllMutators()
		local out = {}

		for _, mutator in pairs(emut.active_mutators) do
			table.insert(out, mutator)
		end

		return out
	end
end

local function on_error(msg)
	print(debug.traceback(msg))
	ErrorNoHalt(msg)
end

local suppress_send_to_server = false
local override_enabled = false

function emut.MutateEntity(owner, class_name, ent, ...)
	if not IsValid(owner) then owner = game.GetWorld() end
	assert(emut.registered_mutators[class_name], "invalid mutator " .. class_name)
	if not IsValid(ent) then ErrorNoHalt("entity is invalid") return end

	if hook.Run("PACMutateEntity", owner, ent, class_name, ...) == false then
		return
	end

	if SERVER then
		if pace.IsBanned(owner) then return end

		if override_enabled and owner:IsPlayer() and not emut.registered_mutators[class_name].cvar:GetBool() then
			pac.Message(owner, "tried to set size when it's disabled")
			return false
		end
	end

	ent.pac_mutations = ent.pac_mutations or {}

	local mutator = ent.pac_mutations[class_name]

	if not mutator then
		mutator = setmetatable({Entity = ent, Owner = owner}, emut.registered_mutators[class_name])
		mutator.original_state = {mutator:StoreState()}
		ent.pac_mutations[class_name] = mutator
		emut.AddMutator(mutator)
	end

	-- notify about owner change?
	mutator.Owner = owner
	mutator.current_state = {...}

	if not xpcall(mutator.Mutate, on_error, mutator, ...) then
		mutator.current_state = nil
		emut.RestoreMutations(owner, class_name, ent)
		return
	end

	if CLIENT and not emut.registered_mutators[class_name].cvar:GetBool() then
		return false
	end

	if CLIENT and owner == LocalPlayer() and not suppress_send_to_server then
		net.Start("pac_entity_mutator")
			net.WriteString(class_name)
			net.WriteEntity(ent)
			net.WriteBool(false)
			mutator:WriteArguments(...)
		net.SendToServer()
	end

	if SERVER then
		net.Start("pac_entity_mutator")
			net.WriteEntity(owner)
			net.WriteString(class_name)
			net.WriteEntity(ent)
			net.WriteBool(false)
			mutator:WriteArguments(...)
		net.SendPVS(owner:GetPos())
	end

	return true
end

function emut.RestoreMutations(owner, class_name, ent)
	if not IsValid(owner) then owner = game.GetWorld() end
	assert(emut.registered_mutators[class_name], "invalid mutator " .. class_name)
	if not IsValid(ent) then ErrorNoHalt("entity is invalid") return end

	if SERVER then
		if not override_enabled then
			if not emut.registered_mutators[class_name].cvar:GetBool() then
				return false
			end
		end
	end

	local mutator = ent.pac_mutations and ent.pac_mutations[class_name]

	if mutator then
		xpcall(mutator.Mutate, on_error, mutator, unpack(mutator.original_state))
		ent.pac_mutations[class_name] = nil
		emut.RemoveMutator(mutator)
	end

	if CLIENT then
		if not emut.registered_mutators[class_name].cvar:GetBool() then
			return false
		end
	end

	if CLIENT and owner == LocalPlayer() and not suppress_send_to_server then
		net.Start("pac_entity_mutator")
			net.WriteString(class_name)
			net.WriteEntity(ent)
			net.WriteBool(true)
		net.SendToServer()
	end

	if SERVER then
		net.Start("pac_entity_mutator")
			net.WriteEntity(owner)
			net.WriteString(class_name)
			net.WriteEntity(ent)
			net.WriteBool(true)
		net.SendPVS(owner:GetPos())
		-- we also include the player who made the mutations, in case the server wants the arguments to be something else
	end
end

function emut.Register(meta)

	if Entity(1):IsValid() then
		for _, ent in ipairs(ents.GetAll()) do
			if ent.pac_mutations then
				for class_name, mutator in pairs(ent.pac_mutations) do
					if class_name == meta.ClassName then
						xpcall(emut.RestoreMutations, function() end, mutator.Owner, mutator.ClassName, mutator.Entity)
					end
				end
			end
		end
	end

	meta.Mutate = meta.Mutate or function() end
	meta.StoreState = meta.StoreState or function() end

	function meta:Disable()
		if self.disabled_state then return end

		local state = {xpcall(self.StoreState, on_error, self)}
		if state[1] then
			table.remove(state, 1)
			self.disabled_state = state
			override_enabled = true
			xpcall(emut.MutateEntity, on_error, self.Owner, self.ClassName, self.Entity, unpack(self.original_state))
			override_enabled = false
		end
	end

	function meta:Enable()
		if not self.disabled_state then return end

		xpcall(emut.MutateEntity, on_error, self.Owner, self.ClassName, self.Entity, unpack(self.disabled_state))

		self.disabled_state = nil
	end

	function meta:__tostring()
		return "mutator[" .. self.ClassName .. "]" .. "[" .. tostring(self.Owner) .. "]" .. "[" .. tostring(self.Entity) .. "]"
	end

	meta.__index = meta
	emut.registered_mutators[meta.ClassName] = meta

	do
		local name = "pac_modifier_" .. meta.ClassName

		local default = 1

		if GAMEMODE and GAMEMODE.FolderName and not GAMEMODE.FolderName:lower():find("sandbox") then
			default = 0
		end

		meta.cvar = CreateConVar(name, default, CLIENT and {FCVAR_REPLICATED} or {FCVAR_ARCHIVE, FCVAR_REPLICATED})

		if SERVER then
			cvars.AddChangeCallback(name, function()
				local enable = meta.cvar:GetBool()

				if enable then
					pac.Message("entity modifier ", name, " is now enabled")
					emut.EnableMutator()
				else
					pac.Message("entity modifier ", name, " is now disabled")
					emut.DisableMutator()
				end

			end, name .. "_change")
		end
	end

	if meta.Update then
		timer.Create("pac_entity_mutator_" .. meta.ClassName, meta.UpdateRate, 0, function()

			if not meta.cvar:GetBool() then return end

			for _, mutator in ipairs(emut.GetAllMutators()) do
				if mutator.ClassName == meta.ClassName then
					if not xpcall(mutator.Update, on_error, mutator, unpack(mutator.current_state)) then
						xpcall(emut.RestoreMutations, on_error, mutator.Owner, mutator.ClassName, mutator.Entity)
						emut.RemoveMutator(mutator)
					end
				end
			end
		end)
	end
end

if SERVER then
	util.AddNetworkString("pac_entity_mutator")
	net.Receive("pac_entity_mutator", function(len, ply)
		local class_name = net.ReadString()
		if not emut.registered_mutators[class_name] then return end

		local ent = net.ReadEntity()
		if not ent:IsValid() then return end

		if net.ReadBool() then
			emut.RestoreMutations(ply, class_name, ent)
		else
			if not pace.CanPlayerModify(ply, ent) then return end

			emut.MutateEntity(ply, class_name, ent, emut.registered_mutators[class_name].ReadArguments())
		end
	end)

	function emut.EnableMutator()
		for _, mutator in ipairs(emut.GetAllMutators()) do
			mutator:Enable()
		end
	end

	function emut.DisableMutator()
		for _, mutator in ipairs(emut.GetAllMutators()) do
			mutator:Disable()
		end
	end

	function emut.ReplicateMutatorsForPlayer(ply)
		for _, mutator in ipairs(emut.GetAllMutators()) do
			net.Start("pac_entity_mutator")
				net.WriteEntity(mutator.Owner)
				net.WriteString(mutator.ClassName)
				net.WriteEntity(mutator.Entity)
				net.WriteBool(false)
				mutator:WriteArguments(unpack(mutator.current_state))
			net.Send(ply)
		end
	end

	hook.Add("PlayerInitialSpawn", "pac_entity_mutators_spawn", function(ply)
		local id = "pac_entity_mutators_spawn" .. ply:UniqueID()
		hook.Add( "SetupMove", id, function(movingPly, _, cmd)
			if not ply:IsValid() then
				hook.Remove("SetupMove", id)
			elseif movingPly == ply and not cmd:IsForced() then
				emut.ReplicateMutatorsForPlayer(ply)

				hook.Remove("SetupMove", id)
			end
		end)
	end)
end

function emut.RemoveMutationsForPlayer(ply)
	for _, mutator in ipairs(emut.GetAllMutators()) do
		if mutator.Owner == ply then
			emut.RestoreMutations(mutator.Owner, mutator.ClassName, mutator.Entity)
		end
	end
end

hook.Add("EntityRemoved", "pac_entity_mutators_left", function(ent)
		if not IsValid(ent) then return end
		if ent:IsPlayer() then
			if Player(ent:UserID()) == NULL then
				emut.RemoveMutationsForPlayer(ent)
			end
		else
			emut.RemoveMutatorsOwnedByEntity(ent)
		end
end)

if CLIENT then
	net.Receive("pac_entity_mutator", function(len)
		local ply = net.ReadEntity()
		if not ply:IsValid() then return end
		local class_name = net.ReadString()
		local ent = net.ReadEntity()
		if not ent:IsValid() then return end

		suppress_send_to_server = true

		xpcall(function()
			if net.ReadBool() then
				emut.RestoreMutations(ply, class_name, ent)
			else
				emut.MutateEntity(ply, class_name, ent, emut.registered_mutators[class_name].ReadArguments())
			end
		end, on_error)

		suppress_send_to_server = false
	end)
end

function emut.LoadMutators()
	local files = file.Find("pac3/core/shared/entity_mutators/*.lua", "LUA")

	for _, name in pairs(files) do
		include("pac3/core/shared/entity_mutators/" .. name)
	end
end

emut.LoadMutators()
