local function RandomModel()
	for _, tbl in RandomPairs(spawnmenu.GetPropTable()) do
		for _, val in RandomPairs(tbl.contents) do
			if val.model then
				return val.model
			end
		end
	end
end

local function RandomMaterial()
	return table.Random(list.Get("OverrideMaterials"))
end

function test.Run(done)
	local root = pac.CreatePart("group")
	local classes = {}
	for class_name in pairs(pac.GetRegisteredParts()) do
		local part = root:CreatePart(class_name)
		table.insert(classes, class_name)
	end

	local run = true

	timer.Simple(10, function()
		run = false
		root:Remove()
		done()
	end)

	local file = file.Open("pac_test_log.txt", "w", "DATA")
	local function log(line)
		file:Write(line .. "\n")
		file:Flush()
	end

	while run do
		local children = root:GetChildrenList()
		for _, part in RandomPairs(children) do
			if part.ClassName == "player_movement" then continue end

			for key, val in RandomPairs(part.StorableVars) do

				if key == "UniqueID" then continue end
				if key == "Name" then continue end
				if key == "OwnerName" then continue end
				if key == "Command" then continue end

				log(part.ClassName .. ".Get" .. key)
				local val = part["Get"..key](part)

				if key:EndsWith("UID") then
					if math.random() > 0.5 then
						val = table.Random(children)
					else
						val = part:CreatePart(table.Random(classes))
					end
					val = val:GetUniqueID()
				elseif type(val) == "number" then
					val = math.Rand(-1000, 100)
				elseif type(val) == "Vector" then
					val = VectorRand()*1000
				elseif type(val) == "Angle" then
					val = Angle(math.Rand(0, 360), math.Rand(0, 360), math.Rand(0, 360))
				elseif type(val) == "boolean" then
					val = math.random() > 0.5
				elseif type(val) == "string" then



					local udata = pac.GetPropertyUserdata(part, key)

					if udata then
						local t = udata.editor_panel
						if t == "model" then
							val = RandomModel()
						elseif t == "material" then
							val = RandomMaterial()
						elseif key == "Bone" then
							for bone in RandomPairs(part:GetModelBones()) do
								val = bone
								break
							end
						else
							print(part.ClassName, key, t)
							val = util.CRC(math.random())
						end
					else
						print(part, key)
					end
				end

				log(part.ClassName .. ".Set" .. key .. " = " .. tostring(val))
				part["Set" .. key](part, val)
			end
			yield()
			test.SetTestTimeout(1)
			break
		end
	end


end