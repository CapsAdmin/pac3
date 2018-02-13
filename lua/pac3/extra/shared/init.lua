
include("hands.lua")
include("pac_weapon.lua")
include("modifiers.lua")
include("projectiles.lua")

local cvar = CreateConVar("pac_restrictions", "0", FCVAR_REPLICATED)

if CLIENT then
	pac.AddHook("pac_EditorCalcView", "pac_restrictions", function()
		if cvar:GetInt() > 0 and not LocalPlayer():IsAdmin() then
			local ent = pace.GetViewEntity()
			local dir = pace.ViewPos - ent:EyePos()
			local dist = ent:BoundingRadius() * ent:GetModelScale() * 4
			local filter = player.GetAll()
			table.insert(filter, ent)

			if dir:Length() > dist then
				pace.ViewPos = ent:EyePos() + (dir:GetNormalized() * dist)
			end

			local res = util.TraceHull({start = ent:EyePos(), endpos = pace.ViewPos, filter = filter, mins = Vector(1,1,1)*-8, maxs = Vector(1,1,1)*8})
			if res.Hit then
				return res.HitPos
			end
		end
	end)
end