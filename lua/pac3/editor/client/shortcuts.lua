
function pace.OnShortcutSave()
	if not IsValid(pace.current_part) then return end

	local part = pace.current_part:GetRootPart()
	surface.PlaySound("buttons/button9.wav")
	pace.SaveParts(nil, "part " .. (part:GetName() or "my outfit"), part, true)
end

function pace.OnShortcutWear()
	if IsValid(pace.current_part) then return end

	local part = pace.current_part:GetRootPart()
	surface.PlaySound("buttons/button9.wav")
	pace.SendPartToServer(part)
end

local last = 0

function pace.CheckShortcuts()
	if not pace.Editor or not pace.Editor:IsValid() then return end
	if last > RealTime() or input.IsMouseDown(MOUSE_LEFT) then return end

	if input.IsKeyDown(KEY_LALT) and input.IsKeyDown(KEY_E) then
		pace.Call("ToggleFocus", true)
		last = RealTime() + 0.2
	end

	if input.IsKeyDown(KEY_LCONTROL) and input.IsKeyDown(KEY_E) then
		pace.Call("ToggleFocus")
		last = RealTime() + 0.2
	end

	if input.IsKeyDown(KEY_LALT) and input.IsKeyDown(KEY_LCONTROL) and input.IsKeyDown(KEY_P) then
		RunConsoleCommand("pac_restart")
	end

	-- Only if the editor is in the foreground
	if pace.Editor:HasFocus() then
		if input.IsKeyDown(KEY_LCONTROL) and input.IsKeyDown(KEY_S) then
			pace.Call("ShortcutSave")
			last = RealTime() + 0.2
		end

		-- CTRL + (W)ear?
		if input.IsKeyDown(KEY_LCONTROL) and input.IsKeyDown(KEY_N) then
			pace.Call("ShortcutWear")
			last = RealTime() + 0.2
		end

		if input.IsKeyDown(KEY_LCONTROL) and input.IsKeyDown(KEY_T) then
			pace.SetTPose(not pace.GetTPose())
			last = RealTime() + 0.2
		end

		if input.IsKeyDown(KEY_LCONTROL) and input.IsKeyDown(KEY_F) then
			pace.properties.search:SetVisible(true)
			pace.properties.search:RequestFocus()
			pace.properties.search:SetEnabled(true)
			pace.property_searching = true

			last = RealTime() + 0.2
		end

	end
end

pac.AddHook("Think", "pace_shortcuts", pace.CheckShortcuts)
