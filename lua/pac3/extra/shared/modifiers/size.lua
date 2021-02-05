local MIN, MAX = 0.1, 10

local ALLOW_TO_CHANGE = pacx.AddServerModifier("size", function(enable)
	if not enable then
		for _, ent in ipairs(ents.GetAll()) do
			if ent.pacx_size then
				pacx.SetEntitySizeMultiplier(ent)
			end
		end
	end

	-- we can also add a way to restore, but i don't think it's worth it
end)

local function change(ent, property, multiplier, default_override)
	if ent["Set" .. property] and ent["Get" .. property] then

		local default = ent.pacx_size_default_props

		if not default[property] then
			default[property] = default_override or ent["Get" .. property](ent)
		end

		ent["Set" .. property](ent, default[property] * multiplier)
	end
end

local function write_other(other)
	net.WriteVector(other.HullStandingMin or Vector())
	net.WriteVector(other.HullStandingMax or Vector())

	net.WriteVector(other.HullCrouchingMin or Vector())
	net.WriteVector(other.HullCrouchingMax or Vector())
end

local function read_other()
	local other = {}
	other.HullStandingMin = net.ReadVector()
	other.HullStandingMax = net.ReadVector()

	other.HullCrouchingMin = net.ReadVector()
	other.HullCrouchingMax = net.ReadVector()
	return other
end

function pacx.SetEntitySizeOnServer(ent, multiplier, other)
	net.Start("pacx_size")
		net.WriteEntity(ent)
		net.WriteDouble(multiplier or 1)
		write_other(other or {})
	net.SendToServer()
end

function pacx.SetEntitySizeMultiplier(ent, multiplier, other)
	multiplier = multiplier or 1
	multiplier = math.Clamp(multiplier, MIN, MAX)

	if multiplier ~= ent.pacx_size then
		ent.pacx_size = multiplier

		if CLIENT then
			pacx.SetEntitySizeOnServer(ent, multiplier, other)
		end

		ent.pacx_size_default_props = ent.pacx_size_default_props or {}
		local default = ent.pacx_size_default_props

		change(ent, "ViewOffset", multiplier)
		change(ent, "ViewOffsetDucked", multiplier)
		change(ent, "StepSize", multiplier)
		change(ent, "ModelScale", multiplier, 1)

		if ent.GetPhysicsObject then
			local phys = ent:GetPhysicsObject()
			if phys:IsValid() then
				if not default.Mass then
					default.Mass = phys:GetMass()
				end

				phys:SetMass(default.Mass * multiplier)
			end
		end
	end

	if other then
		if ent.SetHull and (other.HullStandingMin:Length() ~= 0 or other.HullStandingMax:Length() ~= 0) then
			local min = other.HullStandingMin*1
			min.x = math.min(min.x, 0)
			min.y = math.min(min.y, 0)
			min.z = math.min(min.z, 0)

			local max = other.HullStandingMax*1
			max.x = math.max(max.x, 0.01)
			max.y = math.max(max.y, 0.01)
			max.z = math.max(max.z, 0.01)

			ent:SetHull(min, max)
		end

		if ent.SetHullDuck and (other.HullCrouchingMin:Length() ~= 0 or other.HullCrouchingMax:Length() ~= 0) then
			local min = other.HullCrouchingMin*1
			min.x = math.min(min.x, 0)
			min.y = math.min(min.y, 0)
			min.z = math.min(min.z, 0)

			local max = other.HullCrouchingMax*1
			max.x = math.max(max.x, 0.01)
			max.y = math.max(max.y, 0.01)
			max.z = math.max(max.z, 0.01)

			ent:SetHullDuck(min, max)
		end
	end

	if multiplier == 1 then
		ent.pacx_size_default_props = nil
	end
end

if SERVER then
	util.AddNetworkString("pacx_size")

	net.Receive("pacx_size", function(_, ply)
		if not ALLOW_TO_CHANGE:GetBool() then return end

		local ent = net.ReadEntity()

		if not pace.CanPlayerModify(ply, ent) then return end

		local multiplier = net.ReadDouble()
		local other = read_other()

		pacx.SetEntitySizeMultiplier(ent, multiplier, other)
	end)
end
