function pace.ClearUndo()
	pace.UndoPosition = 1
	pace.UndoHistory = {}
end

local function get_current_outfit()
	local data = {}

	for key, part in pairs(pac.GetLocalParts()) do
		if not part:HasParent() then
			table.insert(data, part:ToUndoTable())
		end
	end

	return data
end

local function find_uid_part(part, findpart)
	for _, child in ipairs(part.children) do
		if child.self.UniqueID == findpart.self.UniqueID then
			return child
		end
	end
end

local function diff_remove(a, b, aparent, bparent)
	for _, apart in ipairs(a.children) do
		local bpart = find_uid_part(b, apart)

		if not bpart then
			local part = pac.GetPartFromUniqueID(pac.LocalPlayer:UniqueID(), apart.self.UniqueID)
			local parent = pac.GetPartFromUniqueID(pac.LocalPlayer:UniqueID(), apart.self.ParentUID)

			if part:IsValid() then
				if part:GetParent() == parent then
					do
						local parent = part:GetParent()
						if parent:IsValid() then pace.Call("PartSelected", parent) end
					end
					part:Remove()
				end
			end
		else
			diff_remove(apart, bpart, a, b)
		end
	end
end


local function diff_create(a, b, aparent, bparent)

	for _, bpart in ipairs(b.children) do
		local apart = find_uid_part(a, bpart)

		if apart then
			for key, aval in pairs(apart.self) do
				local bval = bpart.self[key]

				if aval ~= bval then
					local part = pac.GetPartFromUniqueID(pac.LocalPlayer:UniqueID(), bpart.self.UniqueID)
					local parent = pac.GetPartFromUniqueID(pac.LocalPlayer:UniqueID(), apart.self.ParentUID)

					if part:IsValid() and part:GetParent() == parent then
						if part["Set" .. key] then
							pace.Call("VariableChanged", part, key, bval, true)
						end
					end
				end
			end

			diff(apart, bpart, a, b)
		else
			local part = pac.CreatePart(bpart.self.ClassName, pac.LocalPlayer)
			part:SetUndoTable(bpart)
			part:ResolvePartNames()
		end
	end
end

function pace.ApplyDifference(data)
	local A = get_current_outfit()
	local B = data

	diff_remove({children = A}, {children = B})
	diff_create({children = A}, {children = B})
end

pace.ClearUndo()

local last_json

function pace.RecordUndoHistory()
	local data = get_current_outfit()

	local json = util.TableToJSON(data)
	if json == last_json then return end
	last_json = json

	for i = pace.UndoPosition + 1, #pace.UndoHistory do
		table.remove(pace.UndoHistory)
	end

	table.insert(pace.UndoHistory, data)
	pace.UndoPosition = #pace.UndoHistory

	pace.FlashNotification("Undo position: " .. pace.UndoPosition .. "/" .. #pace.UndoHistory)
end

function pace.Undo()
	pace.UndoPosition = math.Clamp(pace.UndoPosition - 1, 0, #pace.UndoHistory)
	local data = pace.UndoHistory[pace.UndoPosition]

	if data then
		pace.ApplyDifference(data)
		pace.FlashNotification("Undo position: " .. pace.UndoPosition .. "/" .. #pace.UndoHistory)
	else
		pace.FlashNotification('Nothing to undo')
	end
end

function pace.Redo()
	pace.UndoPosition = math.Clamp(pace.UndoPosition + 1, 1, #pace.UndoHistory + 1)
	local data = pace.UndoHistory[pace.UndoPosition]

	if data then
		pace.ApplyDifference(data)
		pace.FlashNotification("Undo position: " .. pace.UndoPosition .. "/" .. #pace.UndoHistory)
	else
		pace.FlashNotification('Nothing to redo')
	end
end

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

	pace.Clipboard = part
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

	pace.RecordUndoHistory()

	pace.Clipboard = part
	part:DeattachFull()
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

	pace.RecordUndoHistory()

	part:DeattachFull()
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

	pace.RecordUndoHistory()

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

	pace.RecordUndoHistory()

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

	pace.RecordUndoHistory()

	local findParent
	local newObj = part:Clone()

	if part == pace.current_part then
		findParent = part:GetParent()

		if not findParent or not findParent:IsValid() then
			findParent = part
		end
	elseif pace.current_part and pace.current_part:IsValid() then
		findParent = pace.current_part
	else
		findParent = pace.Call("CreatePart", "group", L"paste data")
	end

	newObj:Attach(findParent)
	surface.PlaySound("buttons/button9.wav")
end

function pace.UndoThink()
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
end

pac.AddHook("Think", "pace_undo_Think", pace.UndoThink)

pace.RecordUndoHistory()

pace.LoadParts("autoload", true)