pace.UndoHistory = {}
pace.UndoPosition = 1

pace.OnUndo = pace.Undo
pace.OnRedo = pace.Redo

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

	pac.dprint("added %q = %q for %s to undo history", key, tostring(val), tostring(part))
	table.insert(pace.UndoHistory, pace.UndoPosition, {part = part, key = key, val = pac.class.Copy(part["Get" .. key](part))})
	pace.UndoPosition = 1
end

function pace.ApplyUndo()
	local data = pace.UndoHistory[pace.UndoPosition]

	if data and data.part:IsValid() then
		pace.SuppressUndo = true
		pac.dprint("undone %q = %q for %s to undo history", data.key, tostring(data.val), tostring(data.part))
		data.part["Set" .. data.key](data.part, data.val)
		pace.SuppressUndo = false
		surface.PlaySound("buttons/button9.wav")
		pace.RefreshTree(true)
	else
		table.remove(pace.UndoHistory, pace.UndoPosition)
	end

	pace.UndoPosition = math.Clamp(pace.UndoPosition, 1, #pace.UndoHistory)
end

function pace.Undo()
	pace.UndoPosition = pace.UndoPosition + 1
	pace.ApplyUndo()
end

function pace.Redo()
	pace.UndoPosition = pace.UndoPosition - 1
	pace.ApplyUndo()
end

local last = 0

function pace.UndoThink()
	if not pace.IsActive() then return end

	-- whooaaa
	if input.IsControlDown() and input.IsKeyDown(KEY_X) then
		pace.UndoPosition = math.Round((gui.MouseY() / ScrH()) * #pace.UndoHistory)
		pace.ApplyUndo()
		return
	end

	if not input.IsKeyDown(KEY_Z) then
		wait = false
	end

	if wait then return end


	if input.IsControlDown() and ((input.IsKeyDown(KEY_LSHIFT) and input.IsKeyDown(KEY_Z)) or input.IsKeyDown(KEY_Y)) then
		pace.Redo()
		wait = true
	elseif input.IsControlDown() and input.IsKeyDown(KEY_Z) then
		pace.Undo()
		wait = true
	end
end

pac.AddHook("Think", "pace_undo_Think", pace.UndoThink)