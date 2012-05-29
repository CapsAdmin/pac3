pace.UndoHistory = {}

function pace.CallChangeForUndo(obj, key, value)
	timer.Create("pace_undo_" .. key, 0.1, 1, function()
		table.insert(pace.UndoHistory, {obj = obj, key = key, value = value})
	end)
end

function pace.Undo()
	local data = table.remove(pace.UndoHistory)
	if data then
		pace.OnVariableChanged(data.obj, data.key, data.value, true)
	end
end

local last = 0

function pace.UndoThink()
	if input.IsKeyDown(KEY_LCONTROL) and input.IsKeyDown(KEY_Z) and last < CurTime() then
		pace.Undo()
		last = CurTime() + 0.2
	end
end

hook.Add("Think", "pace_undo_Think", pace.UndoThink)