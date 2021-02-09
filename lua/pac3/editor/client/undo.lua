function pace.ClearUndo()
	pace.UndoPosition = 1
	pace.UndoHistory = {}
end

local function get_current_outfit()
	local data = {}

	for key, part in pairs(pac.GetLocalParts()) do
		if not part:HasParent() and part.show_in_editor ~= false then
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

			diff_create(apart, bpart, a, b)
		else
			local part = pac.CreatePart(bpart.self.ClassName)
			part:SetUndoTable(bpart)
			part:ResolvePartNames()
			pace.Call("PartSelected", part)
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