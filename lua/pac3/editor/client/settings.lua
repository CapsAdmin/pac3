function pace.OnToggleFocus(show_editor)
	if pace.Focused then
		pace.KillFocus(show_editor)
	else
		pace.GainFocus(show_editor)
	end
end

function pace.SetTPose(b)
	local ply = LocalPlayer()

	if b then
		ply.pace_tpose_last_sequence = ply:GetSequence()
		ply.pace_tpose_last_layer_sequence = {}
		for i = 0, 16 do
			ply.pace_tpose_last_layer_sequence[i] = ply:GetLayerSequence(i)
		end

		local function reset_angles(ply)
			local ang = ply:EyeAngles()
			ang.p = 0
			ply:SetEyeAngles(ang)
			ply:SetRenderAngles(ang)
			ply:SetAngles(ang)
		end

		pac.AddHook("PrePlayerDraw", "pace_tpose", function(ply)
			if ply ~= LocalPlayer() then return end

			for i = 0, 16 do
				ply:SetLayerSequence(i, 0)
			end

			ply:SetSequence(ply:LookupSequence("ragdoll") or ply:LookupSequence("reference"))
			reset_angles(ply)
		end)

		pac.AddHook("UpdateAnimation", "pace_tpose", function()
			local ply = LocalPlayer()
			ply:ClearPoseParameters()
			reset_angles(ply)

			for i = 0, ply:GetNumPoseParameters() - 1 do
				local name = ply:GetPoseParameterName(i)
				if name then
					ply:SetPoseParameter(name, 0)
				end
			end
		end)

		pac.AddHook("CalcMainActivity", "pace_tpose", function(ply)
			if ply == LocalPlayer() then
				for i = 0, 16 do
					ply:SetLayerSequence(i, 0)
				end

				local act = ply:LookupSequence("ragdoll") or ply:LookupSequence("reference")

				return act, act
			end
		end)
	else
		pac.RemoveHook("PrePlayerDraw", "pace_tpose")
		pac.RemoveHook("UpdateAnimation", "pace_tpose")
		pac.RemoveHook("CalcMainActivity", "pace_tpose")

		if ply.pace_tpose_last_sequence then
			ply:SetSequence(ply.pace_tpose_last_sequence)
			ply.pace_tpose_last_sequence = nil
		end

		if ply.pace_tpose_last_layer_sequence then
			for i, seq in ipairs(ply.pace_tpose_last_layer_sequence) do
				ply:SetLayerSequence(i, seq)
			end

			ply.pace_tpose_last_layer_sequence = nil
		end
	end

	pace.tposed = b
end

pace.SetTPose(pace.tposed)

function pace.ToggleCameraFollow()
	local c = GetConVar("pac_camera_follow_entity")
	RunConsoleCommand("pac_camera_follow_entity", c:GetBool() and "0" or "1")
end

function pace.GetBreathing()
	return pace.breathing
end
function pace.ResetEyeAngles()
	local ent = pace.GetViewEntity()
	if ent:IsValid() then
		if ent:IsPlayer() then

			RunConsoleCommand("+forward")
			timer.Simple(0, function()
				RunConsoleCommand("-forward")
				timer.Simple(0.1, function()
					RunConsoleCommand("+back")
					timer.Simple(0.015, function()
						RunConsoleCommand("-back")
					end)
				end)
			end)

			ent:SetEyeAngles(Angle(0, 0, 0))
		else
			ent:SetAngles(Angle(0, 0, 0))
		end

		ent:SetupBones()
	end
end
