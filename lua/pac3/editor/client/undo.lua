
pace.UndoHistory = {}
pace.UndoPosition = 1
pace.SuppressUndo = false

local last = {}

function pace.CallChangeForUndo(part, key, val, delay)
	if pace.SuppressUndo or key == "Parent" then return end

	if
		(last.part == part and last.key == key) and
		(last.val == val or (delay and last.delay > RealTime()))
	then
		return
	end

	last.key = key
	last.val = val
	last.part = part
	last.delay = RealTime() + (delay or 0)

	pace.AddUndo(part, function()
		part["Set" .. key](part, val)
	end)
end

function pace.AddUndo(callValid, callUndo, callRedo)
	if type(callValid) == 'table' then
		local part = callValid
		callValid = function() return part:IsValid() end
	elseif type(callValid) == 'nil' then
		callValid = function() return true end
	elseif type(callValid) ~= 'function' then
		error('Invalid validation function')
	end

	assert(type(callUndo) == 'function', 'Invalid undo function')
	callRedo = callRedo or callUndo
	assert(type(callRedo) == 'function', 'Invalid redo function')

	pace.UndoPosition = math.Clamp(pace.UndoPosition, 0, #pace.UndoHistory)

	for i = pace.UndoPosition + 1, #pace.UndoHistory do
		pace.UndoHistory[i] = nil
	end

	pace.UndoPosition = pace.UndoPosition + 1
	pace.UndoHistory[pace.UndoPosition] = {
		undo = callUndo,
		redo = callRedo,
		valid = callValid
	}
end

function pace.ApplyUndo(redo)
	local data = pace.UndoHistory[pace.UndoPosition]

	if data and data.valid() then
		pace.SuppressUndo = true

		if redo then
			data.redo()
		else
			data.undo()
		end

		pace.SuppressUndo = false
		surface.PlaySound("buttons/button9.wav")

		pace.RefreshTree(true)
	else
		table.remove(pace.UndoHistory, pace.UndoPosition)
	end

	pace.UndoPosition = math.Clamp(pace.UndoPosition, 1, #pace.UndoHistory)
end

function pace.Undo()
	if pace.UndoPosition <= 1 then
		pace.FlashNotification('Nothing to undo')
		return
	end

	pace.UndoPosition = pace.UndoPosition - 1
	pace.ApplyUndo(false)
end

function pace.Redo()
	if pace.UndoPosition >= #pace.UndoHistory then
		pace.FlashNotification('Nothing to redo')
		return
	end

	pace.UndoPosition = pace.UndoPosition + 1
	pace.ApplyUndo(true)
end

pace.OnUndo = pace.Undo
pace.OnRedo = pace.Redo

local hold = false
local last = 0

local function thinkUndo()
	-- whooaaa
	-- if input.IsControlDown() and input.IsKeyDown(KEY_X) then
	-- 	pace.UndoPosition = math.Round((gui.MouseY() / ScrH()) * #pace.UndoHistory)
	-- 	pace.ApplyUndo()
	-- 	return
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

	part:Remove()
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
	if IsValid(vgui.GetKeyboardFocus()) and vgui.GetKeyboardFocus():GetClassName():find('Text') then return end
	thinkUndo()
	thinkCopy()
	thinkPaste()
	thinkCut()
	thinkDelete()
	thinkExpandAll()
	thinkCollapseAll()
end

pac.AddHook("Think", "pace_undo_Think", pace.UndoThink)
