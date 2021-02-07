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
	if not other then net.WriteBool(false) return end
	net.WriteBool(true)
	net.WriteDouble(other.StandingHullHeight or 0)
	net.WriteDouble(other.CrouchingHullHeight or 0)
	net.WriteDouble(other.HullWidth or 0)
end

local function read_other()
	if net.ReadBool() then
		local other = {}
		other.StandingHullHeight = net.ReadDouble()
		other.CrouchingHullHeight = net.ReadDouble()
		other.HullWidth = net.ReadDouble()
		return other
	end
end

function pacx.SetEntitySizeOnServer(ent, multiplier, other)
	net.Start("pacx_size")
		net.WriteEntity(ent)
		net.WriteDouble(multiplier or 1)
		write_other(other)
	net.SendToServer()
end

function pacx.SetEntitySizeMultiplier(ent, multiplier, other)
	multiplier = multiplier or 1
	multiplier = math.Clamp(multiplier, MIN, MAX)

	if multiplier ~= ent.pacx_size then
		ent.pacx_size = multiplier

		if CLIENT then
			if not ALLOW_TO_CHANGE:GetBool() then
				ent:SetModelScale(multiplier)
				return
			end
		end

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

	if ent.SetHull and ent.SetHullDuck and ent.ResetHull then
		if other then
			local smin, smax = Vector(), Vector()
			local cmin, cmax = Vector(), Vector()

			local w = math.Clamp(other.HullWidth or 32, 1, 4096)

			smin.x = -w / 2
			smax.x = w / 2
			smin.y = -w / 2
			smax.y = w / 2

			cmin.x = -w / 2
			cmax.x = w / 2
			cmin.y = -w / 2
			cmax.y = w / 2

			smin.z = 0
			smax.z = math.Clamp(other.StandingHullHeight or 72, 1, 4096)

			cmin.z = 0
			cmax.z = math.Clamp(other.CrouchingHullHeight or 36, 1, 4096)

			ent:SetHull(smin, smax)
			ent:SetHullDuck(cmin, cmax)
		else
			ent:ResetHull()
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
