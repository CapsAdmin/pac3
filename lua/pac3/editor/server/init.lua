pace = pace or {}

-- for the default models
resource.AddWorkshop("104691717")

pace.Parts = pace.Parts or {}
pace.Errors = {}

util.AddNetworkString('pac_submit_acknowledged')
util.AddNetworkString('pac_update_playerfilter')

function pace.CanPlayerModify(ply, ent)
	if not IsValid(ply) or not IsValid(ent) then
		return false
	end

	if ply == ent then
		return true
	end

	if game.SinglePlayer() then
		return true
	end

	if ent.CPPICanTool and ent:CPPICanTool(ply, "paint") then
		return true
	end

	if ent.CPPIGetOwner and ent:CPPIGetOwner() == ply then
		return true
	end

	if hook.Run("CanTool", ply, util.TraceLine({ start = ply:EyePos(), endpos = ent:WorldSpaceCenter(), filter = ply }), "paint") == true then
		return true
	end

	return false
end

include("util.lua")
include("wear.lua")
include("bans.lua")
include("spawnmenu.lua")

do
	util.AddNetworkString("pac_in_editor")

	net.Receive("pac_in_editor", function(_, ply)
		ply:SetNW2Bool("pac_in_editor", net.ReadBit() == 1)
	end)

	util.AddNetworkString("pac_in_editor_posang")

	net.Receive("pac_in_editor_posang", function(_, ply)
		local pos = net.ReadVector()
		local ang = net.ReadAngle()
		local part_pos = net.ReadVector()

		net.Start("pac_in_editor_posang", true)
			net.WriteEntity(ply)
			net.WriteVector(pos)
			net.WriteAngle(ang)
			net.WriteVector(part_pos)
		net.SendPVS(ply:GetPos())
	end)
end


CreateConVar("has_pac3_editor", "1", {FCVAR_NOTIFY})

resource.AddSingleFile("materials/icon64/pac3.png")