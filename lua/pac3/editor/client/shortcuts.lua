include("parts.lua")
include("popups_part_tutorials.lua")

local L = pace.LanguageString

concommand.Add( "pac_toggle_focus", function() pace.Call("ToggleFocus") end)
concommand.Add( "pac_focus", function() pace.Call("ToggleFocus") end)

local legacy_input = CreateConVar("pac_editor_shortcuts_legacy_mode", "1", FCVAR_ARCHIVE, "Reverts the editor to hardcoded key checks ignoring customizable keys. Some keys are hidden and held down causing serious editor usage problems.")

local last_recorded_combination

pace.PACActionShortcut_Dictionary = {
	"wear",
	"save",
	"load",
	"hide_editor",
	"hide_editor_visible",
	"copy",
	"paste",
	"cut",
	"clone",
	"delete",
	"expand_all",
	"collapse_all",
	"editor_up",
	"editor_down",
	"editor_pageup",
	"editor_pagedown",
	"editor_node_collapse",
	"editor_node_expand",
	"undo",
	"redo",
	"hide",
	"panic",
	"restart",
	"partmenu",
	"add_part",
	"property_search_current_part",
	"property_search_in_tree",
	"toolbar_pac",
	"toolbar_tools",
	"toolbar_player",
	"toolbar_view",
	"toolbar_options",
	"zoom_panel",
	"reset_zoom",
	"reset_view_position",
	"view_orthographic",
	"view_follow_entity",
	"view_follow_entity_ang_frontback",
	"view_follow_entity_sideview",
	"reset_eyeang",
	"reset_eyeang_pitch",
	"T_Pose",
	"bulk_select",
	"clear_bulkselect",
	"copy_bulkselect",
	"bulk_insert",
	"bulk_delete",
	"bulk_pack",
	"bulk_paste_1",
	"bulk_paste_2",
	"bulk_paste_3",
	"bulk_paste_4",
	"bulk_paste_properties_1",
	"bulk_paste_properties_2",
	"bulk_hide",
	"help_info_popup",
	"ultra_cleanup",
	"arraying_menu",
	"bulk_morph",
	"criteria_process",
	"toggle_pins",
}

pace.PACActionShortcut_Default = {
	["wear"] = {
		[1] = {"CTRL", "n"}
	},

	["save"] = {
		[1] = {"CTRL", "s"}
	},

	["hide_editor"] = {
		[1] = {"CTRL", "e"}
	},

	["help_info_popup"] = {
		[1] = {"F1"}
	},

	["hide_editor_visible"] = {
		[1] = {"ALT", "e"}
	},

	["copy"] = {
		[1] = {"CTRL", "c"}
	},

	["paste"] = {
		[1] = {"CTRL", "v"}
	},
	["cut"] = {
		[1] = {"CTRL", "x"}
	},
	["delete"] = {
		[1] = {"DEL"}
	},
	["expand_all"] = {

	},
	["collapse_all"] = {

	},
	["undo"] = {
		[1] = {"CTRL", "z"}
	},
	["redo"] = {
		[1] = {"CTRL", "y"}
	},
	["T_Pose"] = {
		[1] = {"CTRL", "t"}
	},
	["property_search_current_part"] = {
		[1] = {"CTRL", "f"}
	},
	["property_search_in_tree"] = {
		[1] = {"CTRL", "SHIFT", "f"}
	},
	["editor_up"] = {
		[1] = {"UPARROW"}
	},
	["editor_down"] = {
		[1] = {"DOWNARROW"}
	},
	["editor_pageup"] = {
		[1] = {"PGUP"}
	},
	["editor_pagedown"] = {
		[1] = {"PGDN"}
	},
	["editor_node_collapse"] = {
		[1] = {"LEFTARROW"}
	},
	["editor_node_expand"] = {
		[1] = {"RIGHTARROW"}
	}
}

pace.PACActionShortcut_NoCTRL = {
	["wear"] = {
		[1] = {"n"}
	},

	["save"] = {
		[1] = {"m"}
	},

	["hide_editor"] = {
		[1] = {"q"}
	},

	["copy"] = {
		[1] = {"c"}
	},

	["paste"] = {
		[1] = {"v"}
	},

	["cut"] = {
		[1] = {"x"}
	},

	["delete"] = {
		[1] = {"DEL"}
	},

	["undo"] = {
		[1] = {"z"}
	},

	["redo"] = {
		[1] = {"y"}
	},

	["T_Pose"] = {
		[1] = {"t"}
	}
}

pace.PACActionShortcut_Experimental = {
	["help_info_popup"] = {
		[1] = {"F1"}
	},
	["property_search_in_tree"] = {
		[1] = {"CTRL", "f"}
	},
	["wear"] = {
		[1] = {"CTRL", "n"}
	},
	["restart"] = {
		[1] = {"CTRL", "ALT", "SHIFT", "r"}
	},
	["panic"] = {
		[1] = {"CTRL", "ALT", "SHIFT", "p"}
	},

	["save"] = {
		[1] = {"CTRL", "m"}
	},

	["load"] = {
		[1] = {"SHIFT", "m"}
	},

	["hide_editor"] = {
		[1] = {"CTRL", "e"},
		[2] = {"INS"},
		[3] = {"TAB"},
		[4] = {"4"}
	},

	["hide_editor_visible"] = {
		[1] = {"ALT", "e"},
		[2] = {"5"}
	},

	["copy"] = {
		[1] = {"CTRL", "c"}
	},

	["copy_bulkselect"] = {
		[1] = {"SHIFT", "CTRL", "c"}
	},

	["paste"] = {
		[1] = {"CTRL", "v"}
	},
	["cut"] = {
		[1] = {"CTRL", "x"}
	},
	["bulk_insert"] = {
		[1] = {"CTRL", "SHIFT", "v"}
	},
	["delete"] = {
		[1] = {"DEL"}
	},
	["bulk_delete"] = {
		[1] = {"SHIFT", "DEL"}
	},
	["clear_bulkselect"] = {
		[1] = {"CTRL", "SHIFT", "DEL"}
	},
	["undo"] = {
		[1] = {"CTRL", "z"},
		[2] = {"u"}
	},
	["redo"] = {
		[1] = {"CTRL", "y"},
		[2] = {"i"}
	},
	["T_Pose"] = {
		[1] = {"CTRL", "t"}
	},
	["zoom_panel"] = {
		[1] = {"ALT", "v"}
	},
	["toolbar_view"] = {
		[1] = {"SHIFT", "v"}
	},
	["add_part"] = {
		[1] = {"1"}
	},
	["partmenu"] = {
		[1] = {"2"}
	},
	["bulk_select"] = {
		[1] = {"3"}
	},
	["hide"] = {
		[1] = {"CTRL", "h"}
	},
	["bulk_hide"] = {
		[1] = {"SHIFT", "h"}
	},
	["editor_up"] = {
		[1] = {"UPARROW"}
	},
	["editor_down"] = {
		[1] = {"DOWNARROW"}
	},
	["editor_pageup"] = {
		[1] = {"PGUP"}
	},
	["editor_pagedown"] = {
		[1] = {"PGDN"}
	},
	["editor_node_collapse"] = {
		[1] = {"LEFTARROW"}
	},
	["editor_node_expand"] = {
		[1] = {"RIGHTARROW"}
	}
}

pace.PACActionShortcut = pace.PACActionShortcut or pace.PACActionShortcut_Experimental

--pace.PACActionShortcut = pace.PACActionShortcuts_NoCTRL


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
pace.passthrough_keys = {
	[KEY_LWIN] = true,
	[KEY_RWIN] = true,
	[KEY_CAPSLOCK] = true
}
pace.shortcuts_ignored_keys = {
	[KEY_CAPSLOCKTOGGLE] = true,
	[KEY_NUMLOCKTOGGLE] = true,
	[KEY_SCROLLLOCKTOGGLE] = true
}

function pace.LookupShortcutsForAction(action, provided_inputs, do_it)
	pace.BulkSelectKey = input.GetKeyCode(GetConVar("pac_bulk_select_key"):GetString())

	--combo is the table of key names for one combo slot
	local function input_contains_one_match(combo, action, inputs)
		--if pace.shortcut_inputs_count ~= #combo then return false end --if input has too much or too little keys, we already know it doesn't match
		for _,key in ipairs(combo) do --check the combo's keys for a match
			--[[if not (input.IsKeyDown(input.GetKeyCode(key)) and inputs[input.GetKeyCode(key)]) then --all keys must be there
				return false
			end]]

			if not input.IsKeyDown(input.GetKeyCode(key)) then --all keys must be there
				return false
			end
		end
		return true
	end

	local function shortcut_contains_counterexample(combo, action, inputs)

		local counterexample = false
		for key,bool in ipairs(inputs) do --check the input for counter-examples
			if input.IsKeyDown(key) then
				if pace.shortcuts_ignored_keys[key] then continue end
				if not table.HasValue(combo, input.GetKeyName(key)) then --any keypress that is not in the combo invalidates the combo
					--some keys don't count as counterexamples??
					--random windows or capslocktoggle keys being pressed screw up the input
					--bulk select should allow rolling select with the scrolling options

					if key == pace.BulkSelectKey and not action == "editor_up" and not action == "editor_down" and not action == "editor_pageup" and not action == "editor_pagedown" then
						counterexample = true
					elseif not pace.passthrough_keys[key] and key ~= pace.BulkSelectKey then
						counterexample = true
					end

					if pace.passthrough_keys[key] or key == pace.BulkSelectKey then
						counterexample = false
					end
				end

			end
		end
		return counterexample
	end

	if not pace.PACActionShortcut[action] then return false end
	local final_success = false

	local keynames_str = ""
	for key,bool in ipairs(provided_inputs) do
		if bool then keynames_str = keynames_str .. input.GetKeyName(key) .. "," end
	end

	for i=1,10,1 do --go through each combo slot
		if pace.PACActionShortcut[action][i] then --is there a combo in that slot
			combo = pace.PACActionShortcut[action][i]
			local keynames_str = ""

			local single_match = false
			if input_contains_one_match(combo, action, provided_inputs) then
				single_match = true
				if shortcut_contains_counterexample(combo, action, provided_inputs) then
					single_match = false
				end
			end

			if single_match and do_it then
				pace.DoShortcutFunc(action)
				final_success = true
				--MsgC(Color(50,255,100),"-------------------------\n\n\n\nrun yes " .. action .. "\n" .. keynames_str .. "\n\n\n\n-------------------------")
			end
		end
	end

	return final_success
end

function pace.AssignEditorShortcut(action, tbl, index)
	print("received a new shortcut assignation")

	pace.PACActionShortcut[action] = pace.PACActionShortcut[action] or {}
	pace.PACActionShortcut[action][index] = pace.PACActionShortcut[action][index] or {}

	if table.IsEmpty(tbl) or not tbl then
		pace.PACActionShortcut[action][index] = nil
		print("wiped shortcut " .. action .. " off index " .. index)
		return
	end
	--validate tbl argument
	for i,key in pairs(tbl) do
		print(i,key)
		if not isnumber(i) then print("passed a wrong table") return end
		if not isstring(key) then print("passed a wrong table") return end
	end
	pace.PACActionShortcut[action][index] = tbl
end

function pace.DoShortcutFunc(action)

	pace.delaybulkselect = RealTime() + 0.5
	pace.delayshortcuts = RealTime() + 0.2
	pace.delaymovement = RealTime() + 1

	if action == "editor_up" then pace.DoScrollControls(action)
	elseif action == "editor_down" then pace.DoScrollControls(action)
	elseif action == "editor_pageup" then pace.DoScrollControls(action)
	elseif action == "editor_pagedown" then pace.DoScrollControls(action)
	end
	if action == "editor_node_expand" then pace.Call("VariableChanged", pace.current_part, "EditorExpand", true)
	elseif action == "editor_node_collapse" then pace.Call("VariableChanged", pace.current_part, "EditorExpand", false) end

	if action == "redo" then pace.Redo(pace.current_part) pace.delayshortcuts = RealTime() end
	if action == "undo" then pace.Undo(pace.current_part) pace.delayshortcuts = RealTime() end
	if action == "delete" then pace.RemovePart(pace.current_part) end
	if action == "hide" then pace.current_part:SetHide(not pace.current_part:GetHide()) pace.PopulateProperties(pace.current_part) end

	if action == "copy" then pace.Copy(pace.current_part) end
	if action == "cut" then pace.Cut(pace.current_part) end
	if action == "paste" then pace.Paste(pace.current_part) end
	if action == "clone" then pace.Clone(pace.current_part) end
	if action == "save" then pace.Call("ShortcutSave") end
	if action == "load" then
		local function add_expensive_submenu_load(pnl, callback)
			local old = pnl.OnCursorEntered
			pnl.OnCursorEntered = function(...)
				callback()
				pnl.OnCursorEntered = old
				return old(...)
			end
		end
		local menu = DermaMenu()
		local x,y = input.GetCursorPos()
		menu:SetPos(x,y)

		menu.GetDeleteSelf = function() return false end

		menu:AddOption(L"load from url", function()
			Derma_StringRequest(
				L"load parts",
				L"Some indirect urls from on pastebin, dropbox, github, etc are handled automatically. Pasting the outfit's file contents into the input field will also work.",
				"",

				function(name)
					pace.LoadParts(name, clear, override_part)
				end
			)
		end):SetImage(pace.MiscIcons.url)

		menu:AddOption(L"load from clipboard", function()
			pace.MultilineStringRequest(
				L"load parts from clipboard",
				L"Paste the outfits content here.",
				"",

				function(name)
					local data,err = pace.luadata.Decode(name)
					if data then
						pace.LoadPartsFromTable(data, clear, override_part)
					end
				end
			)
		end):SetImage(pace.MiscIcons.paste)

		if not override_part and pace.example_outfits then
			local examples, pnl = menu:AddSubMenu(L"examples")
			pnl:SetImage(pace.MiscIcons.help)
			examples.GetDeleteSelf = function() return false end

			local sorted = {}
			for k,v in pairs(pace.example_outfits) do sorted[#sorted + 1] = {k = k, v = v} end
			table.sort(sorted, function(a, b) return a.k < b.k end)

			for _, data in pairs(sorted) do
				examples:AddOption(data.k, function() pace.LoadPartsFromTable(data.v) end)
				:SetImage(pace.MiscIcons.outfit)
			end
		end

		menu:AddSpacer()

		pace.AddOneDirectorySavedPartsToMenu(menu, "templates", "templates")
		pace.AddOneDirectorySavedPartsToMenu(menu, "__backup_save", "backups")

		menu:AddSpacer()
		do
			local menu, icon = menu:AddSubMenu(L"load (expensive)", function() pace.LoadParts(nil, true) end)
			menu:SetDeleteSelf(false)
			icon:SetImage(pace.MiscIcons.load)
			add_expensive_submenu_load(icon, function() pace.AddSavedPartsToMenu(menu, true) end)
		end

		menu:SetMaxHeight(ScrH() - y)
		menu:MakePopup()

	end
	if action == "wear" then pace.Call("ShortcutWear") end

	if action == "hide_editor" and not (pace.ActiveSpecialPanel and pace.ActiveSpecialPanel.luapad) then pace.Call("ToggleFocus") pace.delaymovement = RealTime() pace.delaybulkselect = RealTime() end
	if action == "hide_editor_visible" and not (pace.ActiveSpecialPanel and pace.ActiveSpecialPanel.luapad) then pace.Call("ToggleFocus", true) end
	if action == "panic" then pac.Panic() end
	if action == "restart" then RunConsoleCommand("pac_restart") end
	if action == "collapse_all" then

		local part = pace.current_part

		if not part or not part:IsValid() then
			pace.FlashNotification('No part to collapse')
		else

		end
		part:CallRecursive('SetEditorExpand', GetConVar("pac_reverse_collapse"):GetBool())
		pace.RefreshTree(true)
	end
	if action == "expand_all" then

		local part = pace.current_part

		if not part or not part:IsValid() then
			pace.FlashNotification('No part to collapse')
		else

		end
		part:CallRecursive('SetEditorExpand', not GetConVar("pac_reverse_collapse"):GetBool())
		pace.RefreshTree(true)
	end

	if action == "partmenu" then pace.OnPartMenu(pace.current_part) end
	if action == "property_search_current_part" then
		if pace.properties.search:IsVisible() then
			pace.properties.search:SetVisible(false)
			pace.properties.search:SetEnabled(false)
			pace.property_searching = false
		else
			pace.properties.search:SetVisible(true)
			pace.properties.search:RequestFocus()
			pace.properties.search:SetEnabled(true)
			pace.property_searching = true
		end

	end
	if action == "property_search_in_tree" then
		if pace.tree_search_open then
			pace.tree_searcher:Remove()
		else
			pace.OpenTreeSearch()
		end
	end
	if action == "add_part" then pace.OnAddPartMenu(pace.current_part) end
	if action == "toolbar_tools" then
		menu = DermaMenu()
		local x,y = input.GetCursorPos()
		menu:SetPos(x,y)
		pace.AddToolsToMenu(menu)
	end
	if action == "toolbar_pac" then
		menu = DermaMenu()
		local x,y = input.GetCursorPos()
		menu:AddOption("pac")
		menu:SetPos(x,y)
		pace.PopulateMenuBarTab(menu, "pac")
	end
	if action == "toolbar_options" then
		menu = DermaMenu()
		local x,y = input.GetCursorPos()
		menu:SetPos(x,y)
		pace.PopulateMenuBarTab(menu, "options")
	end
	if action == "toolbar_player" then
		menu = DermaMenu()
		local x,y = input.GetCursorPos()
		menu:SetPos(x,y)
		pace.PopulateMenuBarTab(menu, "player")

	end
	if action == "toolbar_view" then
		menu = DermaMenu()
		local x,y = input.GetCursorPos()
		menu:SetPos(x,y)
		pace.PopulateMenuBarTab(menu, "view")
	end

	if action == "zoom_panel" then
		pace.PopupMiniFOVSlider()
	end
	if action == "reset_zoom" then
		pace.ResetZoom()
	end
	if action == "reset_view_position" then
		pace.ResetView()
	end
	if action == "view_orthographic" then
		pace.OrthographicView()
	end
	if action == "view_follow_entity" then
		GetConVar("pac_camera_follow_entity"):SetBool(not GetConVar("pac_camera_follow_entity"):GetBool())
	end
	if action == "reset_eyeang" then
		pace.ResetEyeAngles()
	elseif action == "reset_eyeang_pitch" then
		pace.ResetEyeAngles(true)
	end
	if action == "view_follow_entity_ang_frontback" then
		pace.ResetEyeAngles(true)
		local b = GetConVar("pac_camera_follow_entity_ang"):GetBool()
		GetConVar("pac_camera_follow_entity_ang_use_side"):SetBool(false)
		if not b then
			pace.view_reversed = 1
			GetConVar("pac_camera_follow_entity_ang"):SetBool(true)
			timer.Simple(0, function() pace.FlashNotification("view_follow_entity_ang_frontback (back)") end)
		else
			if pace.view_reversed == -1 then
				GetConVar("pac_camera_follow_entity_ang"):SetBool(false)
				timer.Simple(0, function() pace.FlashNotification("view_follow_entity_ang_frontback (disable)") end)
			else
				timer.Simple(0, function() pace.FlashNotification("view_follow_entity_ang_frontback (front)") end)
			end
			pace.view_reversed = -pace.view_reversed
		end
	end
	if action == "view_follow_entity_sideview" then
		pace.ResetEyeAngles(true)
		local b = GetConVar("pac_camera_follow_entity_ang"):GetBool()
		GetConVar("pac_camera_follow_entity_ang_use_side"):SetBool(true)
		if not b then
			pace.view_reversed = 1
			GetConVar("pac_camera_follow_entity_ang"):SetBool(true)
			timer.Simple(0, function() pace.FlashNotification("view_follow_entity_sideview (left)") end)
		else
			if pace.view_reversed == -1 then
				GetConVar("pac_camera_follow_entity_ang"):SetBool(false)
				timer.Simple(0, function() pace.FlashNotification("view_follow_entity_sideview (disable)") end)
			else
				timer.Simple(0, function() pace.FlashNotification("view_follow_entity_sideview (right)") end)
			end
			pace.view_reversed = -pace.view_reversed
		end
	end

	if action == "T_Pose" or action == "t_pose" then pace.SetTPose(not pace.GetTPose()) end

	if action == "bulk_select" then
		pace.DoBulkSelect(pace.current_part)
	end
	if action == "clear_bulkselect" then pace.ClearBulkList() end
	if action == "bulk_copy" then pace.BulkCopy(pace.current_part) end --deprecated keyword
	if action == "copy_bulkselect" then pace.BulkCopy(pace.current_part) end
	if action == "bulk_insert" then pace.BulkCutPaste(pace.current_part) end
	if action == "bulk_delete" then pace.BulkRemovePart() end
	if action == "bulk_pack" then
		root = pac.CreatePart("group")
		for i,v in ipairs(pace.BulkSelectList) do
			v:SetParent(root)
		end
	end
	if action == "bulk_paste_1" then pace.BulkPasteFromBulkSelectToSinglePart(pace.current_part) end
	if action == "bulk_paste_2" then pace.BulkPasteFromSingleClipboard(pace.current_part) end
	if action == "bulk_paste_3" then pace.BulkPasteFromBulkClipboard(pace.current_part) end
	if action == "bulk_paste_4" then pace.BulkPasteFromBulkClipboardToBulkSelect(pace.current_part) end

	if action == "bulk_paste_properties_1" then
		pace.Copy(pace.current_part)
		for _,v in ipairs(pace.BulkSelectList) do
			pace.PasteProperties(v)
		end
	end
	if action == "bulk_paste_properties_2" then
		for _,v in ipairs(pace.BulkSelectList) do
			pace.PasteProperties(v)
		end
	end
	if action == "bulk_hide" then pace.BulkHide() pace.PopulateProperties(pace.current_part) end

	if action == "help_info_popup" then
		if pace.floating_popup_reserved then
			pace.floating_popup_reserved:Remove()
		end

		--[[pac.InfoPopup("Looks like you don't have an active part. You should right click and go make one to get started", {
			obj_type = "screen",
			clickfunc = function() pace.OnAddPartMenu(pace.current_part) end,
			hoverfunc = "open",
			pac_part = false
		}, ScrW()/2, ScrH()/2)]]


		local popup_setup_tbl = {
			obj_type = "",
			clickfunc = function() pace.OnAddPartMenu(pace.current_part) end,
			hoverfunc = "open",
			pac_part = pace.current_part,
			panel_exp_width = 900, panel_exp_height = 400
		}

		--obj_type types
		local popup_prefered_type = GetConVar("pac_popups_preferred_location"):GetString()
		popup_setup_tbl.obj_type = popup_prefered_type

		if popup_prefered_type == "pac tree label" then
			popup_setup_tbl.obj = pace.current_part.pace_tree_node
			pace.floating_popup_reserved = pace.current_part:SetupEditorPopup(nil, true, popup_setup_tbl)

		elseif popup_prefered_type == "part world" then
			popup_setup_tbl.obj = pace.current_part
			pace.floating_popup_reserved = pace.current_part:SetupEditorPopup(nil, true, popup_setup_tbl)

		elseif popup_prefered_type == "screen" then
			pace.floating_popup_reserved = pace.current_part:SetupEditorPopup(nil, true, popup_setup_tbl, ScrW()/2, ScrH()/2)

		elseif popup_prefered_type == "cursor" then
			pace.floating_popup_reserved = pace.current_part:SetupEditorPopup(nil, true, popup_setup_tbl, input.GetCursorPos())

		elseif popup_prefered_type == "tracking cursor" then
			pace.floating_popup_reserved = pace.current_part:SetupEditorPopup(nil, true, popup_setup_tbl, input.GetCursorPos())

		elseif popup_prefered_type == "menu bar" then
			popup_setup_tbl.obj = pace.Editor
			pace.floating_popup_reserved = pace.current_part:SetupEditorPopup(nil, true, popup_setup_tbl)

		end




		--[[if IsValid(pace.current_part) then
			pac.AttachInfoPopupToPart(pace.current_part)
		else
			pac.InfoPopup("Looks like you don't have an active part. You should right click and go make one to get started", {
				obj_type = "screen",
				--hoverfunc = function() pace.OnAddPartMenu(pace.current_part) end,
				pac_part = false
			}, ScrW()/2, ScrH()/2)
		end]]
	end

	if action == "ultra_cleanup" then
		pace.UltraCleanup(pace.current_part)
	end

	if action == "arraying_menu" then
		pace.OpenArrayingMenu(pace.current_part)
	end

	if action == "bulk_morph" then
		pace.BulkMorphProperty()
	end

	if action == "criteria_process" then
		pace.PromptProcessPartsByCriteria(pace.current_part)
	end

	if action == "toggle_pins" then
		GetConVar("pac_editor_pins"):SetBool(not GetConVar("pac_editor_pins"):GetBool())
	end
end

pace.delaybulkselect = 0
pace.delayshortcuts = 0
pace.delaymovement = 0

--only check once. what does this mean?
--if a shortcut is SUCCESSFULLY run (check_input = false), stop checking until inputs are reset (if no_input then check_input = true end)
--always refresh the inputs, but check if we stay the same before checking the shortcuts!
--

local skip = false
local no_input_override = false
local has_run_something = false
local previous_inputs_str = ""

function pace.CheckShortcuts()
	if GetConVar("pac_editor_shortcuts_legacy_mode"):GetBool() then
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
				if not input.IsKeyDown(KEY_LSHIFT)then
					pace.properties.search:SetVisible(true)
					pace.properties.search:RequestFocus()
					pace.properties.search:SetEnabled(true)
					pace.property_searching = true

					last = RealTime() + 0.2
				else
					pace.OpenTreeSearch()
				end
			end

			if input.IsKeyDown(KEY_F1) then
				last = RealTime() + 0.5
				local new_popup = true
				if IsValid(pace.legacy_floating_popup_reserved) then
					new_popup = false
					if pace.current_part ~= pace.legacy_floating_popup_reserved_part then
						if IsValid(pace.legacy_floating_popup_reserved) then
							pace.legacy_floating_popup_reserved:Remove()
							pace.legacy_floating_popup_reserved = nil
							pace.legacy_floating_popup_reserved_part = nil
						end
						new_popup = true
					end
				else
					pace.legacy_floating_popup_reserved = nil
					pace.legacy_floating_popup_reserved_part = nil
				end

				local popup_setup_tbl = {
					obj_type = "",
					clickfunc = function() pace.OnAddPartMenu(pace.current_part) end,
					hoverfunc = "open",
					pac_part = pace.current_part,
					panel_exp_width = 900, panel_exp_height = 400,
					from_legacy = true
				}

				popup_setup_tbl.obj_type = "pac tree label"
				popup_setup_tbl.obj = pace.current_part.pace_tree_node

				if new_popup then
					local created_panel = pace.current_part:SetupEditorPopup(nil, true, popup_setup_tbl)
					pace.legacy_floating_popup_reserved = created_panel
					pace.legacy_floating_popup_reserved_part = pace.current_part
				end
				pac.AddHook("Think", "killpopupwheneditorunfocused", function()
					if not pace:IsFocused() then
						if IsValid(pace.legacy_floating_popup_reserved) then pace.legacy_floating_popup_reserved:Remove() end
					end
					if not IsValid(pace.legacy_floating_popup_reserved) then pace.legacy_floating_popup_reserved = nil end
				end)
			end
		end
		return
	end

	local input_active = {}
	local no_input = true
	no_input_override = false
	local inputs_str = ""
	pace.shortcut_inputs_count = 0
	for i=1,172,1 do --build bool list of all current keys
		if input.IsKeyDown(i) then
			if pace.shortcuts_ignored_keys[i] then continue end
			if pace.passthrough_keys[i] or i == pace.BulkSelectKey then no_input_override = true end
			input_active[i] = true
			pace.shortcut_inputs_count = pace.shortcut_inputs_count + 1
			no_input = false
			inputs_str = inputs_str .. input.GetKeyName(i) .. " "
		else input_active[i] = false end
	end

	if previous_inputs_str ~= inputs_str then
		if last + 0.2 > RealTime() and has_run_something then
			skip = true
		else
			has_run_something = false
		end

	end
	if no_input then
		skip = false
	end
	previous_inputs_str = inputs_str


	if IsValid(vgui.GetKeyboardFocus()) and vgui.GetKeyboardFocus():GetClassName():find('Text') then return end
	if gui.IsConsoleVisible() then return end
	if not pace.Editor or not pace.Editor:IsValid() then return end


	if skip and not no_input_override then return end

	local starttime = SysTime()

	for action,list_of_lists in pairs(pace.PACActionShortcut) do
		if not has_run_something then
			if (action == "hide_editor" or action == "hide_editor_visible") and pace.LookupShortcutsForAction(action, input_active, true) then --we can focus back if editor is not focused
				--pace.DoShortcutFunc(action)
				last = RealTime()
				has_run_something = true
				check_input = false
			elseif pace.Focused and pace.LookupShortcutsForAction(action, input_active, true) then --we can't do anything else if not focused
				--pace.DoShortcutFunc(action)
				pace.FlashNotification(action)
				last = RealTime()
				has_run_something = true
				check_input = false
			end
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
		if GetConVar("pac_editor_shortcuts_legacy_mode"):GetBool() then
			thinkUndo()
			thinkCopy()
			thinkPaste()
			thinkCut()
			thinkDelete()
			thinkExpandAll()
			thinkCollapseAll()
		end

	end)
end

