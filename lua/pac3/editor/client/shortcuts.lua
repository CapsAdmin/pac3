function pace.OnShortcutSave()
	if pace.current_part:IsValid() then
		local part = pace.current_part:GetRootPart()
		pace.SavePartToFile(part, part:GetName())
		surface.PlaySound("buttons/button9.wav")
	end
end

function pace.OnShortcutWear()
	if pace.current_part:IsValid() then
		local part = pace.current_part:GetRootPart()
		pace.SendPartToServer(part)
		surface.PlaySound("buttons/button9.wav")
	end
end

local last = 0

function pace.CheckShortcuts()
	if pace.Editor and pace.Editor:IsValid() then
		if last > RealTime() or input.IsMouseDown(MOUSE_LEFT) then return end

		if input.IsKeyDown(KEY_LCONTROL) and input.IsKeyDown(KEY_M) then
			pace.Call("ShortcutSave")
			last = RealTime() + 0.2
		end

		if input.IsKeyDown(KEY_LCONTROL) and input.IsKeyDown(KEY_N) then
			pace.Call("ShortcutWear")
			last = RealTime() + 0.2
		end

		if input.IsKeyDown(KEY_LCONTROL) and input.IsKeyDown(KEY_E) then
			pace.Call("ToggleFocus")
			last = RealTime() + 0.2
		end

		if input.IsKeyDown(KEY_LCONTROL) and input.IsKeyDown(KEY_T) then
			pace.SetTPose(not pace.GetTPose())
			last = RealTime() + 0.2
		end

		if input.IsKeyDown(KEY_LALT) and input.IsKeyDown(KEY_E) then
			pace.Call("ToggleFocus", true)
			last = RealTime() + 0.2
		end

		if input.IsKeyDown(KEY_LCONTROL) and input.IsKeyDown(KEY_F) then
			pace.properties.search:SetVisible(true)
			pace.properties.search:RequestFocus()
			pace.properties.search:SetEnabled(true)
			pace.property_searching = true

			last = RealTime() + 0.2
		end

		if input.IsKeyDown(KEY_LALT) and input.IsKeyDown(KEY_LCONTROL) and input.IsKeyDown(KEY_P) then
			RunConsoleCommand("pac_restart")
		end
	end
end

hook.Add("Think", "pace_shortcuts", pace.CheckShortcuts)