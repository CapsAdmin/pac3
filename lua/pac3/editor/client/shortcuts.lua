CreateClientConVar( "pac_focus_input1", "", true, false, "Set the first key for the custom shorctut of pac3 editor focus. Format according to internal names of the keys as console binds e.g. e or ctrl" )
CreateClientConVar( "pac_focus_input2", "", true, false, "Set the second key for the custom shorctut of pac3 editor focus. Format according to internal names of the keys as console binds e.g. e or ctrl" )
concommand.Add( "pac_toggle_focus", function() pace.Call("ToggleFocus") end)
concommand.Add( "pac_focus", function() pace.Call("ToggleFocus") end)

local last_recorded_combination

local focusKeyPrimary
local focusKeySecondary

local ShortcutActions

ShortcutActions = {}
ShortcutActions["wear"] = {0}
ShortcutActions["save"] = {1,2,3}
ShortcutActions["focus"] = {67,83}
ShortcutActions["copy"] = {0}
ShortcutActions["paste"] = {0}
ShortcutActions["cut"] = {0}
ShortcutActions["delete"] = {0}
ShortcutActions["expand_all"] = {0}
ShortcutActions["collapse_all"] = {0}
ShortcutActions["undo"] = {0}
ShortcutActions["redo"] = {0}

concommand.Add( "pac_echo_shortcut", function()
	timer.Simple( 3, function()
		surface.PlaySound("buttons/button1.wav")
		inputs = get_all_inputs()
		print("inputs:")
		printed_list = ""
		input_list = {}
		for k,v in pairs(inputs) do
			printed_list = printed_list .. "key" .. k .. ", (code " .. v .. ", named " .. input.GetKeyName(v) .. ")\n"
			input_list[k] = v
		end
		print(printed_list)
		print(unpack(input_list))
		last_recorded_combination = input_list
		end
	)
end)
--[[
concommand.Add( "pac_assign_shortcut", function()
	local action_name = "focus"
	ShortcutActions[action_name] = last_recorded_combination
	print("assigned "..action_name.." for ")
	print(unpack(ShortcutActions[action_name]))
end)




concommand.Add( "pac_echo_shortcut_megatable", function() 
	for k,v in ipairs(ShortcutActions) do
		unpacked_combo_string = ""
		for k2,v2 in ipairs(ShortcutActions[k][2]) do
			if (ShortcutActions[k][2][k2] ~= nil) then
				unpacked_combo_string = unpacked_combo_string .. ShortcutActions[k][2][k2] .. ","
			end
		end
		print(ShortcutActions[k][1] .. " " .. unpacked_combo_string)
	end
	
	test_combos = {
		{1,2},
		{1,3,2},
		{1,2,3},
		{0},
		{4},
		{54,57},
	}
	
	print("the match between " .. "{1,2}" .. " and {\"save\",{1,2,3}} is ", matches_input(test_combos[1], "save"))
	
end)

function get_all_inputs()
	list = {}
	count = 1
	for key=1,BUTTON_CODE_LAST do
		if input.IsKeyDown(key) then
			list[count] = key
			count = count + 1
		end
	end
	return list
end


function matches_input(combo_in, action_name)
	local target = ShortcutActions[action_name][2]
	print("combo_in length is ", #combo_in, ", target length is ", #target)
	if #combo_in ~= #target.length then return false end
	full_match = true
	print("trying to match")
	for k,v in pairs(combo_in) do
		if ((combo_in[v] == nil) or (target[v] == nil)) then
			full_match = false
		else
			if (combo_in[v] == target[v]) then
				print("matched " .. target[v])
			else
				full_match = false
			end
		end
	end
	return full_match
end
]]--


	--[[thinkUndo()
	thinkCopy()
	thinkPaste()
	thinkCut()
	thinkDelete()
	thinkExpandAll()
	thinkCollapseAll()]]--


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
local last_print_time = CurTime()

function pace.CheckShortcuts()
	--[[
	if input.IsKeyDown(KEY_H) then 
		if last_print_time + 1 < CurTime() then
			surface.PlaySound("buttons/button9.wav")
			print("input report!")
			print(unpack(get_all_inputs()))
			print("done at time of "..last_print_time.."\n")
			--chat.print("input report!\n"..unpack(get_all_inputs()).."\ndone at time of "..last_print_time)
			last_print_time = CurTime()
		end
	end]]--
	focusKeyPrimary = input.GetKeyCode(GetConVar("pac_focus_input1"):GetString())
	focusKeySecondary = input.GetKeyCode(GetConVar("pac_focus_input2"):GetString())
	
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
	-- can make new hardcoded custom shortcuts for focus
	--[[if input.IsKeyDown(KEY_LSHIFT) and input.IsKeyDown(KEY_R) then
		pace.Call("ToggleFocus")
		last = RealTime() + 0.2
	end]]--
	--convar custom inputs
	--if not ((focusKeyPrimary == -1) and (focusKeySecondary == -1)) then
		if input.IsKeyDown(focusKeyPrimary) and input.IsKeyDown(focusKeySecondary) then
			pace.Call("ToggleFocus")
			last = RealTime() + 0.2
		end
	--end

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

--[[
function pace.FillShortcutSettings(pnl)
	local list = vgui.Create("DCategoryList", pnl)
	list:Dock(FILL)
	do
		local cat = list:Add(L"Wear")
		cat.Header:SetSize(40,40)
		cat.Header:SetFont("DermaLarge")
		local list = vgui.Create("DListLayout")
		list:DockPadding(20,20,20,20)
		cat:SetContents(list)

		local mode = vgui.Create("DComboBox", list)

		mode.OnSelect = function(_, _, value)
			if IsValid(mode.form) then
				mode.form:Remove()
			end
			mode.form:SetParent(list)
		end
	end
	return list
end
]]--

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