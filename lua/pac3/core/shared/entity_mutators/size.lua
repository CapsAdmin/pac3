local MUTATOR = {}

MUTATOR.ClassName = "size"

function MUTATOR:WriteArguments(multiplier, other)
	net.WriteDouble(multiplier)

	if other then
		net.WriteBool(true)
		net.WriteDouble(other.StandingHullHeight)
		net.WriteDouble(other.CrouchingHullHeight)
		net.WriteDouble(other.HullWidth)
	end

	if SERVER then
		local hidden_state = self.original_state[3]
		if hidden_state then
			net.WriteBool(true)
			net.WriteTable(hidden_state)
		else
			net.WriteBool(false)
		end
	else
		net.WriteBool(false)
	end
end

function MUTATOR:ReadArguments()
	local multiplier = math.Clamp(net.ReadDouble(), 0.1, 10)
	local other = false
	local hidden_state

	if net.ReadBool() then
		other = {}
		other.StandingHullHeight = net.ReadDouble()
		other.CrouchingHullHeight = net.ReadDouble()
		other.HullWidth = net.ReadDouble()
	end

	if net.ReadBool() then
		hidden_state = net.ReadTable()
	end

	return multiplier, other, hidden_state
end

function MUTATOR:StoreState()
	local ent = self.Entity

	return
		1,--ent:GetModelScale(),
		false, -- we will just ent:ResetHull()
		{
			ViewOffset = ent.GetViewOffset and ent:GetViewOffset() or nil,
			ViewOffsetDucked = ent.GetViewOffsetDucked and ent:GetViewOffsetDucked() or nil,
			StepSize = ent.GetStepSize and ent:GetStepSize() or nil,
		}
end

local functions = {
	"ViewOffset",
	"ViewOffsetDucked",
	"StepSize",
}

function MUTATOR:Mutate(multiplier, other, hidden_state)
	local ent = self.Entity

	ent:SetModelScale(multiplier)

	-- hmmm
	hidden_state = hidden_state or self.original_state[3]

	if hidden_state then
		for _, key in ipairs(functions) do
			local original = hidden_state[key]
			if original then
				local setter = ent["Set" .. key]

				if setter then
					setter(ent, original * multiplier)
				end
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
end

pac.emut.Register(MUTATOR)