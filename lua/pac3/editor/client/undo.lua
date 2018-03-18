
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
	pace.UndoPosition = pace.UndoPosition - 1
	pace.ApplyUndo(false)
end

function pace.Redo()
	pace.UndoPosition = pace.UndoPosition + 1
	pace.ApplyUndo(true)
end

pace.OnUndo = pace.Undo
pace.OnRedo = pace.Redo

local hold = false
local last = 0

function pace.UndoThink()
	if not pace.IsActive() then return end

	-- whooaaa
	if input.IsControlDown() and input.IsKeyDown(KEY_X) then
		pace.UndoPosition = math.Round((gui.MouseY() / ScrH()) * #pace.UndoHistory)
		pace.ApplyUndo()
		return
	end

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

pac.AddHook("Think", "pace_undo_Think", pace.UndoThink)
