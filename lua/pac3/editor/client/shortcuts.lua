
function pace.OnShortcutSave()
	if not IsValid(pace.current_part) then return end

	local part = pace.current_part:GetRootPart()
	surface.PlaySound("buttons/button9.wav")
	pace.SaveParts(nil, "part " .. (part:GetName() or "my outfit"), part, true)
end

function pace.OnShortcutWear()
	if not IsValid(pace.current_part) then return end

	local part = pace.current_part:GetRootPart()
	surface.PlaySound("buttons/button9.wav")
	pace.SendPartToServer(part)
	pace.FlashNotification('Wearing group: ' .. part:GetName())
end

local last = 0

function pace.CheckShortcuts()
	if gui.IsConsoleVisible() then return end
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
	if pace.IsFocused() then
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

do
	local hold = false
	local last = 0

	local function thinkUndo()
		-- whooaaa
		-- if input.IsControlDown() and input.IsKeyDown(KEY_X) then
		--  pace.UndoPosition = math.Round((gui.MouseY() / ScrH()) * #pace.UndoHistory)
		--  pace.ApplyUndo()
		--  return
		-- end

		if not input.IsKeyDown(KEY_Z) and not input.IsKeyDown(KEY_Y) then
			hold = false
		end

		if hold then return end

		if input.IsControlDown() and ((input.IsKeyDown(KEY_LSHIFT) and input.IsKeyDown(KEY_Z)) or input.IsKeyDown(KEY_Y)) then
			pace.Redo()
			hold = true
		elseif input.IsControlDown() and input.IsKeyDown(KEY_Z) then
			pace.Undo()
			hold = true
		end
	end

	local hold = false

	local function thinkCopy()
		if not input.IsKeyDown(KEY_C) then
			hold = false
		end

		if hold or not (input.IsControlDown() and input.IsKeyDown(KEY_C)) then return end

		-- copy
		hold = true
		local part = pace.current_part

		if not part or not part:IsValid() then
			pace.FlashNotification('No part selected to copy')
			return
		end

		pace.Copy(part)

		surface.PlaySound("buttons/button9.wav")
	end

	local hold = false

	local function thinkCut()
		if not input.IsKeyDown(KEY_X) then
			hold = false
		end

		if hold or not (input.IsControlDown() and input.IsKeyDown(KEY_X)) then return end

		-- copy
		hold = true
		local part = pace.current_part

		if not part or not part:IsValid() then
			pace.FlashNotification('No part selected to cut')
			return
		end

		pace.Cut(part)

		surface.PlaySound("buttons/button9.wav")
	end

	local hold = false

	local function thinkDelete()
		if not input.IsKeyDown(KEY_DELETE) then
			hold = false
		end

		if hold or not input.IsKeyDown(KEY_DELETE) then return end

		-- delete
		hold = true
		local part = pace.current_part

		if not part or not part:IsValid() then
			pace.FlashNotification('No part to delete')
			return
		end

		pace.RemovePart(part)

		surface.PlaySound("buttons/button9.wav")
	end

	local REVERSE_COLLAPSE_CONTROLS = CreateConVar('pac_reverse_collapse', '1', {FCVAR_ARCHIVE}, 'Reverse Collapse/Expand hotkeys')
	local hold = false

	local function thinkExpandAll()
		if not input.IsKeyDown(KEY_LALT) and not input.IsKeyDown(KEY_RALT) and not input.IsKeyDown(KEY_0) then
			hold = false
		end

		if hold or not input.IsShiftDown() or (not input.IsKeyDown(KEY_LALT) and not input.IsKeyDown(KEY_RALT)) or not input.IsKeyDown(KEY_0) then return end

		-- expand all
		hold = true
		local part = pace.current_part

		if not part or not part:IsValid() then
			pace.FlashNotification('No part to expand')
			return
		end

		part:CallRecursive('SetEditorExpand', not REVERSE_COLLAPSE_CONTROLS:GetBool())

		surface.PlaySound("buttons/button9.wav")
		pace.RefreshTree(true)
	end

	local hold = false

	local function thinkCollapseAll()
		if not input.IsKeyDown(KEY_LALT) and not input.IsKeyDown(KEY_RALT) and not input.IsKeyDown(KEY_0) then
			hold = false
		end

		if hold or input.IsShiftDown() or (not input.IsKeyDown(KEY_LALT) and not input.IsKeyDown(KEY_RALT)) or not input.IsKeyDown(KEY_0) then return end

		-- collapse all
		hold = true
		local part = pace.current_part

		if not part or not part:IsValid() then
			pace.FlashNotification('No part to collapse')
			return
		end

		part:CallRecursive('SetEditorExpand', REVERSE_COLLAPSE_CONTROLS:GetBool())

		surface.PlaySound("buttons/button9.wav")
		pace.RefreshTree(true)
	end

	local hold = false

	local function thinkPaste()
		if not input.IsKeyDown(KEY_V) then
			hold = false
		end

		if hold or not (input.IsControlDown() and input.IsKeyDown(KEY_V)) then return end

		-- paste
		hold = true
		local part = pace.Clipboard

		if not part then
			pace.FlashNotification('No part is stored in clipboard')
			return
		end

		local findParent

		if part == pace.current_part then
			findParent = part:GetParent()

			if not findParent or not findParent:IsValid() then
				findParent = part
			end
		elseif pace.current_part and pace.current_part:IsValid() then
			findParent = pace.current_part
		else
			pace.RecordUndoHistory()
			findParent = pace.Call("CreatePart", "group", L"paste data")
			pace.RecordUndoHistory()
		end

		pace.Paste(findParent)

		surface.PlaySound("buttons/button9.wav")
	end

	pac.AddHook("Think", "pace_keyboard_shortcuts", function()
		if not pace.IsActive() then return end
		if not pace.Focused then return end
		if IsValid(vgui.GetKeyboardFocus()) and vgui.GetKeyboardFocus():GetClassName():find('Text') then return end
		if gui.IsConsoleVisible() then return end
		thinkUndo()
		thinkCopy()
		thinkPaste()
		thinkCut()
		thinkDelete()
		thinkExpandAll()
		thinkCollapseAll()
	end)
end