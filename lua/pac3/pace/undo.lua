pace.UndoHistory = {}

function pace.CallChangeForUndo(obj, key, value)
	timer.Create("pace_undo_" .. key, 0.1, 1, function()
		table.insert(pace.UndoHistory, {obj = obj, key = key, value = value})
	end)
end

function pace.Undo(step)
	step = step or 1
	for i=0, step do
		local data = pace.UndoHistory[#pace.UndoHistory - i]
		if data then
			pace.OnVariableChanged(data.obj, data.key, data.value, true)
		end
	end
end