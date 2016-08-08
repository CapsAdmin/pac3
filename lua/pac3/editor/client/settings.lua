function pace.OnToggleFocus(show_editor)
	if pace.Focused then
		pace.KillFocus(show_editor)
	else
		pace.GainFocus(show_editor)
	end
end

function pace.SetTPose(b)
	if b then
		hook.Add("CalcMainActivity", "pace_tpose", function(ply)
			if ply == LocalPlayer() then
				return
					ply:LookupSequence("reference"),
					ply:LookupSequence("reference")
			end
		end)
	else
		hook.Remove("CalcMainActivity", "pace_tpose")
	end

	pace.tposed = b
end

function pace.SetBreathing(b)
	if b then
		pace.AddHook("UpdateAnimation", function(ply)
			if ply == LocalPlayer() then
				for k,v in pairs(reset_pose_params) do
					ply:SetPoseParameter(v, 0)
				end
				ply:ClearPoseParameters()
			end
		end)
	else
		pace.RemoveHook("UpdateAnimation")
	end

	pace.breathing = b
end

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
