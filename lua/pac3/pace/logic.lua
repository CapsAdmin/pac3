pace.properties = NULL
pace.view = NULL
pace.tree = NULL

local reset_pose_params =
{
	"body_rot_z",
	"spine_rot_z",
	"head_rot_z",
	"head_rot_y",
	"head_rot_x",
	"walking",
	"running",
	"swimming",
	"rhand",
	"lhand",
	"rfoot",
	"lfoot",
	"move_yaw",
	"aim_yaw",
	"aim_pitch",
	"breathing",
	"vertical_velocity",
	"vehicle_steer",
	"body_yaw",
	"spine_yaw",
	"head_yaw",
	"head_pitch",
	"head_roll",
}

function pace.GetTPose()
	return pace.tposed
end

function pace.SetTPose(b)
	if b then
		pac.AddHook("CalcMainActivity", function(ply) return ply:LookupSequence("ragdoll"), ply:LookupSequence("ragdoll") end)
		pac.AddHook("UpdateAnimation", function(ply) for k,v in pairs(reset_pose_params) do ply:SetPoseParameter(v, 0) end end)
	else
		pac.RemoveHook("CalcMainActivity")
		pac.RemoveHook("UpdateAnimation")
	end
	pace.tposed = b
end

function pace.SetViewOutfit(outfit)
	if outfit:GetOwner():IsPlayer() then
		pac.AddHook("ShouldDrawLocalPlayer", function() return true end)
	else
		pac.RemoveHook("ShouldDrawLocalPlayer")
	end

	pace.view:SetViewOutfit(outfit)
end

function pace.RefreshTree(rebuild)
	if rebuild then
		pace.tree.rebuild = true
		pace.tree:Clear()
	end
	if pace.tree then
		pace.tree:Populate()
		timer.Simple(0, function()
			pace.tree:Populate()
			if rebuild then
				pace.tree.rebuild = nil
			end
		end)
	end
end

function pace.PopulateProperties(obj)
	if pace.properties:IsValid() then
		pace.properties:Populate(obj)
	end
end

pace.current_outfit = pac.Null
pace.current_part = pac.Null

function pace.OnOutfitSelected(obj)
	pace.PopulateProperties(obj)
	pace.current_outfit = obj
end

function pace.OnDraw()
	pace.mctrl.HUDPaint()
end

function pace.OnPartSelected(obj)
	pace.PopulateProperties(obj)
	pace.mctrl.SetTarget(obj)
	pace.current_outfit = obj.Outfit
	pace.current_part = obj
end

function pace.OnCreateOutfit()
	local outfit = pac.CreateOutfit(LocalPlayer())
	pace.RefreshTree()
end

function pace.OnCreatePart(name)
	local outfit = pace.current_outfit
	if outfit:IsValid() then
		local part = pac.CreatePart(name)
		part:SetName(name .. " " .. #outfit:GetParts())

		local parent = pace.current_part
		if parent:IsValid() then
			part:SetParent(parent:GetName())
		end

		outfit:AddPart(part)

		pace.RefreshTree()
	end
end

function pace.OnVariableChanged(obj, key, val, skip_undo)
	local func = obj["Set" .. key]
	if func then
		func(obj, val)

		if not skip_undo then
			pace.CallChangeForUndo(obj, key, val)
		end
	end
end

pace.OnUndo = pace.Undo
pace.OnRedo = pace.Redo

local L = pace.LanguageString

function pace.SaveOutfitToFile(outfit, name)
	if not name then
		Derma_StringRequest(
			L"save outfit",
			L"filename:",
			outfit:GetName(),

			function(name)
				pace.SaveOutfitToFile(outfit, name)
			end

		)
	else
		luadata.WriteFile("pac3/outfits/" .. name .. ".txt", outfit:ToTable())
	end
end

function pace.LoadOutfitFromFile(outfit, name)
	if not name then
		Derma_StringRequest(
			L"load outfit",
			L"filename:",
			"",

			function(name)
				pace.LoadOutfitFromFile(outfit, name)
			end

		)
	else
		outfit:SetTable(luadata.ReadFile("pac3/outfits/" .. name .. ".txt"))
	end
end

function pace.OnOpenMenu()
	local menu = DermaMenu()
	menu:SetPos(gui.MousePos())
	menu:AddOption("toggle t pose", function()
		pace.SetTPose(not pace.GetTPose())
	end)
	menu:AddOption("toggle lighting", function()
		pace.view:SetLighting(not pace.view:GetLighting())
	end)
	menu:Open()
	menu:MakePopup()
end

function pace.OnPartMenu(part)
	local menu = DermaMenu()
	menu:SetPos(gui.MousePos())
	menu:AddOption("Remove", function()
		part:Remove()
		pace.RefreshTree()
		pace.OnOutfitSelected(pace.current_outfit)
	end)
	menu:Open()
	menu:MakePopup()
end

function pace.OnOutfitMenu(outfit)
	local menu = DermaMenu()
	menu:SetPos(gui.MousePos())
	menu:AddOption("save", function()
		pace.SaveOutfitToFile(outfit)
	end)
	menu:AddOption("load", function()
		pace.LoadOutfitFromFile(outfit)
		pace.RefreshTree()
	end)
	menu:AddOption("Remove", function()
		outfit:Remove()
		pace.RefreshTree()
	end)
	menu:Open()
	menu:MakePopup()
end