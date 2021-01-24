local MIN, MAX = 0.1, 10

local ALLOW_TO_CHANGE = pacx.AddServerModifier("model", function(enable)
	if not enable then
		for _, ent in ipairs(ents.GetAll()) do
			if ent.pacx_model_original then
				pacx.SetModel(ent)
			end
			ent:SetNW2String("pacx_model", nil)
		end
	end

	-- we can also add a way to restore, but maybe it's best to just rewear
end)

function pacx.SetModelOnServer(ent, path)
	path = path or ""
	net.Start("pacx_setmodel")
		net.WriteEntity(ent)
		net.WriteString(path)
	net.SendToServer()
end

function pacx.GetModel(ent)
	return ent:GetNW2String("pacx_model", ent:GetModel())
end

function pacx.SetModel(ent, path, ply)
	if not path or path == "" then
		if ent.pacx_model_original then
			ent:SetModel(ent.pacx_model_original)
			ent.pacx_model_original = nil
			ent:SetNW2String("pacx_model", nil)
		end
		return
	end

	if CLIENT then
		pacx.SetModelOnServer(ent, path)
	end

	ent.pacx_model_original = ent.pacx_model_original or ent:GetModel()

	if path:find("^http") then
		pac.Message(ply, " wants to use ", path, " as model on ", ent)

		pac.DownloadMDL(path, function(mdl_path)
			pac.Message(mdl_path, " downloaded for ", ent, ': ', path)

			ent:SetModel(mdl_path)
			ent:SetNW2String("pacx_model", mdl_path)
		end, function(err)
			pac.Message(err)
		end, ply)
	else
		if not util.IsValidModel(path) then
			path = player_manager.TranslatePlayerModel(path)
			if not util.IsValidModel(path) then
				return
			end
		end

		ent:SetModel(path)
		ent:SetNW2String("pacx_model", path)
	end
end

if SERVER then
	util.AddNetworkString("pacx_setmodel")

	net.Receive("pacx_setmodel", function(_, ply)
		if not ALLOW_TO_CHANGE:GetBool() then return end

		local ent = net.ReadEntity()

		if not pace.CanModify(ply, ent) then return end

		local path = net.ReadString()

		if hook.Run("PACApplyModel", ply, path) == false then return end

		pacx.SetModel(ent, path, ply)
	end)
end


do -- is there a nicer way to do this?
	local function check(ply)
		local mdl = pacx.GetModel(ply)
		if mdl and ply:GetModel():lower() ~= mdl:lower() then
			ply:SetModel(mdl)
		end
	end

	timer.Create("pac_setmodel", 0.25, 0, function()
		for _, ply in ipairs(player.GetAll()) do
			check(ply)
		end
	end)

	gameevent.Listen("player_spawn")
	hook.Add("player_spawn", "pacx_setmodel", function(data)
		local ply = player.GetByID(data.userid)
		if not ply:IsValid() then return end
		check(ply)
		timer.Simple(0, function()
			if ply:IsValid() then
				check(ply)
			end
		end)
	end)
end