local lol = os.clock()

local found = {}
for _, file_name in pairs(file.Find("particles/*.pcf", "GAME")) do
	local data = file.Read("particles/"..file_name, "GAME", "b")
	if data then
		for str in data:gmatch("\3%c([%a_]+)%c") do
			if #str > 1 then
				found[str] = file_name
			end
		end
	end
end

print(os.clock() - lol)
print(table.Count(found))
PrintTable(found)

do return end

local function read_string(f)
	local chars = {}
	for i = 1, 64 do
		local b = f:ReadByte()
		if not b or b == 0 then break end
		table.insert(chars, string.char(b))
	end
	return table.concat(chars)
end


for _, file_name in pairs(file.Find("particles/*.pcf", "GAME")) do
	local f = file.Open("particles/"..file_name, "rb", "GAME")

	local header = f:Read(43)

	f:Skip(2)

	local strings = {}

	local count = f:ReadShort()
	if count > 0 and count < 10000 then
		for i = 1, count do
			strings[i] = read_string(f)
			if i > 1050 then break end
		end
	else
		print("STRINGS:", header, count, file_name)
	end

	local tbl = {}

	local count = f:ReadLong()
	if count > 0 and count < 10000 then
		for i = 1, count do
			local data = {}
			data.type_name_index = f:ReadShort()
			data.element_name = read_string(f)
			data.data_signature = f:Read(16)
			tbl[i] = data
		end
	else
		print("ELEMENTS:", header, count, file_name)
	end
	print(header)
	--PrintTable(tbl)
	f:Close()
	--do return end
end