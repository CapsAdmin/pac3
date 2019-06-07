function pace.OnToggleFocus(show_editor)
	if pace.Focused then
		pace.KillFocus(show_editor)
	else
		pace.GainFocus(show_editor)
	end
end

function pace.SetTPose(b)
	if b then
		pac.AddHook("CalcMainActivity", "pace_tpose", function(ply)
			if ply == LocalPlayer() then
				ply:SetRenderAngles(ply:GetAngles())
				local act = ply:LookupSequence("ragdoll") or ply:LookupSequence("reference")
				return act, act
			end
		end)
	else
		pac.RemoveHook("CalcMainActivity", "pace_tpose")
	end

	pace.tposed = b
end

function pace.SetResetPoseParameters(b)
	if b then
		pac.AddHook("UpdateAnimation", "pace_reset_pose_parameters", function(ply)
			if ply == LocalPlayer() then
				ply:ClearPoseParameters()
				ply:InvalidateBoneCache()

			end
		end)
	else
		pac.RemoveHook("UpdateAnimation", "pace_reset_pose_parameters")
	end

	pace.reset_pose_parameters = b
end


function pace.SetBreathing(b)
	if b then
		pac.AddHook("UpdateAnimation", "pace_stop_breathing", function(ply)
			if ply == LocalPlayer() then
				for i = 0, 6 do
					--ply:AddVCDSequenceToGestureSlot(0, 4, math.random(), false)
				end
				--return true
			end
		end)
	else
		pac.RemoveHook("UpdateAnimation", "pace_stop_breathing")
	end

	pace.breathing = b
end

pace.SetTPose(false)
pace.SetResetPoseParameters(false)
pace.SetBreathing(false)

pace.SetBreathing(true)

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
