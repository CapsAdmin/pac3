local MIN, MAX = 0.1, 10

local ALLOW_TO_CHANGE = pacx.AddServerModifier("model", function(enable)
	if not enable then
		for _, ent in ipairs(ents.GetAll()) do
			if ent.pacx_model_original then
				pacx.SetModel(ent)
			end
		end
	end

	-- we can also add a way to restore, but maybe it's best to just rewear
end)

function pacx.SetModelOnServer(ent, path)
	net.Start("pacx_setmodel")
		net.WriteEntity(ent)
		net.WriteString(path or "")
	net.SendToServer()
end

function pacx.SetModel(ent, path, ply)
	if not path or path == "" then
		if ent.pacx_model_original then
			ent:SetModel(ent.pacx_model_original)
			ent.pacx_model_original = nil
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
		end, function(err)
			pac.Message(err)
		end, ply)
	else
		if not util.IsValidModel(path) then return end

		ent:SetModel(path)
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