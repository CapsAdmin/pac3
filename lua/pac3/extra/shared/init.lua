include("hands.lua")
include("pac_weapon.lua")
include("projectiles.lua")
include("net_combat.lua")

local cvar = CreateConVar("pac_restrictions", "0", FCVAR_REPLICATED)

if CLIENT then
	local mins, maxs = Vector(-8, -8, -8), Vector(8, 8, 8)

	pac.AddHook("pac_EditorCalcView", "restrictions", function()
		if cvar:GetBool() and not pac.LocalPlayer:IsAdmin() then
			local ent = pace.GetViewEntity()

			local dir = pace.ViewPos - ent:EyePos()
			local dist = ent:BoundingRadius() * (5 + ent:GetModelScale())

			local filter = player.GetAll()
			table.insert(filter, ent)

			if dir:LengthSqr() > (dist * dist) then
				pace.ViewPos = ent:EyePos() + (dir:GetNormalized() * dist)
			end

			local res = util.TraceHull({
				start = ent:EyePos(),
				endpos = pace.ViewPos,
				filter = filter,
				mins = mins,
				maxs = maxs
			})

			if res.Hit then
				return res.HitPos
			end
		end
	end)
end