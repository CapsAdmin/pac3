pace = pace or {}

-- for the default models
resource.AddWorkshop("104691717")

pace.luadata = include("pac3/libraries/luadata.lua")
pace.Parts = pace.Parts or {}
pace.Errors = {}

do
	util.AddNetworkString("pac.TogglePartDrawing")

	function pac.TogglePartDrawing(ent, b, who) --serverside interface to clientside function of the same name
		net.Start("pac.TogglePartDrawing")
		net.WriteEntity(ent)
		net.WriteBit(b)
		if not who then
			net.Broadcast()
		else
			net.Send(who)
		end
	end
end

local pac_sv_prop_outfits = CreateConVar("pac_sv_prop_outfits", "0", CLIENT and {FCVAR_REPLICATED} or {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Allow applying parts on other entities serverside\n0=don't\n1=allow on props but not players\n2=allow on other players")

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

	if pac_sv_prop_outfits:GetInt() ~= 0 then
		if pac_sv_prop_outfits:GetInt() == 1 then
			return not (ply ~= ent and ent:IsPlayer())
		elseif pac_sv_prop_outfits:GetInt() == 2 then
			return true
		end

	end

	do
		local tr = util.TraceLine({ start = ply:EyePos(), endpos = ent:WorldSpaceCenter(), filter = ply })
		if tr.Entity == ent and hook.Run("CanTool", ply, tr, "paint") == true then
			return true
		end
	end

	return false
end

include("util.lua")
include("wear.lua")
include("wear_filter.lua")
include("bans.lua")
include("spawnmenu.lua")
include("show_outfit_on_use.lua")
include("pac_settings_manager.lua")

do
	util.AddNetworkString("pac_in_editor")

	net.Receive("pac_in_editor", function(_, ply)
		ply:SetNW2Bool("pac_in_editor", net.ReadBit() == 1)
	end)

	util.AddNetworkString("pac_in_editor_posang")

	net.Receive("pac_in_editor_posang", function(_, ply)
		if not ply.pac_last_editor_message then
			ply.pac_last_editor_message = 0
		end

		if ply.pac_last_editor_message > CurTime() then return end
		ply.pac_last_editor_message = CurTime() + 0.2

		local pos = net.ReadVector()
		local ang = net.ReadAngle()
		local part_pos = net.ReadVector()

		net.Start("pac_in_editor_posang", true)
			net.WritePlayer(ply)
			net.WriteVector(pos)
			net.WriteAngle(ang)
			net.WriteVector(part_pos)
		net.SendPVS(ply:GetPos())
	end)
end

CreateConVar("has_pac3_editor", "1", {FCVAR_NOTIFY})

resource.AddSingleFile("materials/icon64/new pac icon.png")
resource.AddSingleFile("materials/icon64/pac3.png")
