
local PREFIX = '[PAC3] '
local PREFIX_COLOR = Color(255, 255, 0)

local DEFAULT_TEXT_COLOR = Color(200, 200, 200)
local BOOLEAN_COLOR = Color(33, 83, 226)
local NUMBER_COLOR = Color(245, 199, 64)
local STEAMID_COLOR = Color(255, 255, 255)
local ENTITY_COLOR = Color(180, 232, 180)
local FUNCTION_COLOR = Color(62, 106, 255)
local TABLE_COLOR = Color(107, 200, 224)
local URL_COLOR = Color(174, 124, 192)

function pac.RepackMessage(strIn)
	local output = {}

	for line in string.gmatch(strIn, '([^ ]+)') do
		if #output ~= 0 then
			table.insert(output, ' ')
		end

		table.insert(output, line)
	end

	return output
end

local function FormatMessage(tabIn)
	local prevColor = DEFAULT_TEXT_COLOR
	local output = {prevColor}

	for i, val in ipairs(tabIn) do
		local valType = type(val)

		if valType == 'number' then
			table.insert(output, NUMBER_COLOR)
			table.insert(output, tostring(val))
			table.insert(output, prevColor)
		elseif valType == 'string' then
			if val:find('^https?://') then
				table.insert(output, URL_COLOR)
				table.insert(output, val)
				table.insert(output, prevColor)
			else
				table.insert(output, val)
			end
		elseif valType == 'Player' then
			if team then
				table.insert(output, team.GetColor(val:Team()) or ENTITY_COLOR)
			else
				table.insert(output, ENTITY_COLOR)
			end

			table.insert(output, val:Nick())

			if val.SteamName and val:SteamName() ~= val:Nick() then
				table.insert(output, ' (' .. val:SteamName() .. ')')
			end

			table.insert(output, '<')
			table.insert(output, val:SteamID())
			table.insert(output, '>')
			table.insert(output, prevColor)
		elseif valType == 'Entity' or valType == 'NPC' or valType == 'Vehicle' then
			table.insert(output, ENTITY_COLOR)
			table.insert(output, tostring(val))
			table.insert(output, prevColor)
		elseif valType == 'table' then
			if val.r and val.g and val.b then
				table.insert(output, val)
				prevColor = val
			else
				table.insert(output, TABLE_COLOR)
				table.insert(output, tostring(val))
				table.insert(output, prevColor)
			end
		elseif valType == 'function' then
			table.insert(output, FUNCTION_COLOR)
			table.insert(output, string.format('function - %p', val))
			table.insert(output, prevColor)
		elseif valType == 'boolean' then
			table.insert(output, BOOLEAN_COLOR)
			table.insert(output, tostring(val))
			table.insert(output, prevColor)
		else
			table.insert(output, tostring(val))
		end
	end

	return output
end

pac.FormatMessage = FormatMessage

function pac.Message(...)
	local formatted = FormatMessage({...})
	MsgC(PREFIX_COLOR, PREFIX, unpack(formatted))
	MsgC('\n')
	return formatted
end

function pac.dprint(fmt, ...)
	if not pac.debug then return end
	MsgN("\n")
	MsgN(">>>PAC3>>>")
	MsgN(fmt:format(...))
	if pac.debug_trace then
		MsgN("==TRACE==")
		debug.Trace()
		MsgN("==TRACE==")
	end
	MsgN("<<<PAC3<<<")
	MsgN("\n")
end


local function int_to_bytes(num,endian,signed)
    if num<0 and not signed then num=-num print"warning, dropping sign from number converting to unsigned" end
    local res={}
    local n = math.ceil(select(2,math.frexp(num))/8) -- number of bytes to be used.
    if signed and num < 0 then
        num = num + 2^n
    end
    for k=n,1,-1 do -- 256 = 2^8 bits per char.
        local mul=2^(8*(k-1))
        res[k]=math.floor(num/mul)
        num=num-res[k]*mul
    end
    assert(num==0)
    if endian == "big" then
        local t={}
        for k=1,n do
            t[k]=res[n-k+1]
        end
        res=t
    end
    return string.char(unpack(res))
end

function pac.DownloadMDL(url, callback, onfail, ply)
	return pac.resource.Download(url, function(path)
		local id = util.CRC(ply:UniqueID() .. url .. file.Read(path))
		local dir = "pac3/" .. id .. "/"

		local f = file.Open(path, "rb", "DATA")

		local found = false
		local files = {}

		local ok, err = pcall(function()
			for i = 1, 128 do
				local pos = f:Tell()

				local sig = f:ReadLong()

				if sig == 0x02014b50 then break end

				assert(sig == 0x04034b50, "bad zip signature (file is not a zip?)")

				f:Seek(pos+6) local bitflag = f:ReadShort()
				f:Seek(pos+8) local compression_method = f:ReadShort()
				f:Seek(pos+14) local crc = f:ReadShort()
				f:Seek(pos+18) local size2 = f:ReadLong()
				f:Seek(pos+22) local size = f:ReadLong()
				f:Seek(pos+26) local file_name_length = f:ReadShort()
				local extra_field_length = f:ReadShort()

				local name = f:Read(file_name_length)

				if compression_method ~= 0 then
					error("compression method for "..name.." is not 0 / store! (maybe you drag dropped files into the archive)")
				end

				if not name:EndsWith(".vtf") and not name:EndsWith(".vmt") then
					name = name:gsub(".-(%..+)", "model%1"):lower()
				end

				f:Skip(extra_field_length)

				local buffer = f:Read(size)

				if name:EndsWith(".mdl") then
					--local path = buffer:sub(13, 12+64)
					--buffer = buffer:gsub(path, mdl_dir .. "model.mdl")
					found = true
				end

				table.insert(files, {file_name = name, buffer = buffer, crc = crc})
			end
		end)

		if not ok then
			onfail(err)
			local str = file.Read(path)
			pac.Message(Color(255, 50,50), "the zip archive downloaded (", string.NiceSize(#str) ,") could not be parsed")

			local is_binary = false
			for i = 1, #str do
				local b = str:byte(i)
				if b == 0 then
					is_binary = true
					break
				end
			end

			if not is_binary then
				pac.Message(Color(255, 50,50), "the zip archive doesn't appear to be binary:")
				print(str)
			end

			if ply == pac.LocalPlayer then
				file.Write("pac3_cache/failed_zip_download.dat", str)
				pac.Message(Color(255, 50,50), "the zip archive was stored to garrysmod/data/pac3_cache/failed_zip_download.dat (rename extension to .zip) if you want to inspect it")
			end
			return
		end

		if not found then
			for k,v in pairs(files) do
				print(v.file_name, string.NiceSize(#v.buffer))
			end
			onfail("mdl not found in archive")
			return
		end

		do -- hex models
			local found_directories = {}
			local found_materials = {}

			for i, data in ipairs(files) do
				if data.file_name:EndsWith(".mdl") then
					file.Write("pac3_cache/temp.dat", data.buffer)

					local f = file.Open("pac3_cache/temp.dat", "rb", "DATA")
					local id = f:Read(4)
					local version = f:ReadLong()
					local checksum = f:ReadLong()
					local name_offset = f:Tell()
					local name = f:Read(64)
					local size_offset = f:Tell()
					local size = f:ReadLong()

					f:Skip(12 * 6) -- skips over all the vec3 stuff

					f:Skip(4) -- flags
					f:Skip(8 * 6)

					do
						local vmt_dir_count = f:ReadLong()
						local vmt_dir_offset = f:ReadLong()

						if ply == pac.LocalPlayer then

							local old_pos = f:Tell()
							f:Seek(vmt_dir_offset)
								local offset = f:ReadLong()
								if offset > -1 then
									f:Seek(vmt_dir_offset + offset)
									for i = 1, vmt_dir_count do
										local chars = {}
										for i = 1, 64 do
											local b = f:ReadByte()
											if not b or b == 0 then break end
											table.insert(chars, string.char(b))
										end

										local mat = table.concat(chars) .. ".vmt"
										local found = false

										for i, v in pairs(files) do
											if v.file_name:EndsWith(mat) then
												found = true
												break
											end
										end

										if not found then
											pac.Message(Color(255, 50,50), url, " the model wants to find ", mat, " but it was not found in the zip archive")
										end

										table.insert(found_materials, mat)
									end
								end
							f:Seek(old_pos)
						end
					end

					local vtf_dir_count = f:ReadLong()
					local vtf_dir_offset = f:ReadLong()

					f:Seek(vtf_dir_offset)

					local done = {}

					for i = 1, vtf_dir_count do
						local offset = f:ReadLong()
						local old_pos = f:Tell()
						if not offset then break end

						f:Seek(offset)

						local chars = {}
						for i = 1, 64 do
							local b = f:ReadByte()
							if not b or b == 0 then break end
							table.insert(chars, string.char(b))
						end

						local dir = table.concat(chars)
						table.insert(found_directories, {offset = offset, dir = dir})

						f:Seek(old_pos)
					end

					f:Close()

					local buffer = file.Read("pac3_cache/temp.dat")
					file.Delete("pac3_cache/temp.dat")

					local newdir = dir
					newdir = newdir:gsub("/", "\\")

					for i,v in ipairs(found_directories) do
						if #newdir < #v.dir then
							newdir = newdir .. ("\0"):rep(#v.dir - #newdir + 1)
						end

						buffer = (buffer:sub(0, v.offset) .. newdir .. buffer:sub(v.offset + #v.dir + 1)):sub(0, size)
					end

					local newname = (dir .. data.file_name:lower()):gsub("/", "\\")

					do
						local newname = newname
						if #newname < #name then
							newname = newname .. ("\0"):rep(#name - #newname)
						end

						buffer = buffer:sub(0, name_offset) .. newname .. buffer:sub(name_offset + #name + 1)
					end

					--buffer = buffer:Replace(name:match("^(.+%.mdl)"), newname)
					--buffer = buffer:sub(0, size_offset) .. int_to_bytes(#buffer) .. buffer:sub(size_offset + 4 - 1)

					data.buffer = buffer
					data.crc = int_to_bytes(tonumber(util.CRC(data.buffer)))
					break
				end
			end


			for i, data in ipairs(files) do
				if not data.file_name:EndsWith(".mdl") then
					if data.file_name:EndsWith(".vmt") then
						local newdir = dir

						data.buffer = data.buffer:lower():gsub("\\", "/")

						for _, info in ipairs(found_directories) do
							data.buffer = data.buffer:gsub("[\"\']%S-" .. info.dir:gsub("\\", "/"):lower(), "\"" .. newdir)
							data.buffer = data.buffer:gsub(info.dir:gsub("\\", "/"):lower(), newdir)
						end

						data.crc = int_to_bytes(tonumber(util.CRC(data.buffer)))
					end
				end
			end
		end

		local path = "pac3_cache/downloads/" .. id .. ".dat"
		local f = file.Open(path, "wb", "DATA")

		if not f then
			file.Delete(path)
			pac.Message("unable to open file " .. path .. " for writing")
			id = id .. "_"
			path = "pac3_cache/downloads/" .. id .. ".dat"
			pac.Message("trying " .. path .. " for writing instead")
			f = file.Open(path, "wb", "DATA")
		end

		if not f then
			onfail("unable to open file " .. path .. " for writing")

			pac.Message(Color(255, 50, 50), "unable to write to ", path, " for some reason")
			if file.Exists(path, "DATA") then
				pac.Message(Color(255, 50, 50), "the file exists and its size is ", string.NiceSize(file.Size(path, "DATA")))
				pac.Message(Color(255, 50, 50), "is it locked or in use by something else?")
			else
				pac.Message(Color(255, 50, 50), "the file does not exist")
				pac.Message(Color(255, 50, 50), "are you out of space?")
			end
			return
		end

		f:Write("GMAD")
		f:WriteByte(3)
		f:WriteLong(0)f:WriteLong(0)
		f:WriteLong(0)f:WriteLong(0)
		f:WriteByte(0)
		f:Write("name here")f:WriteByte(0)
		f:Write("description here")f:WriteByte(0)
		f:Write("author here")f:WriteByte(0)
		f:WriteLong(1)

		for i, data in ipairs(files) do
			f:WriteLong(i)
			if data.file_name:EndsWith(".vtf") or data.file_name:EndsWith(".vmt") then
				f:Write("materials/" .. dir .. data.file_name:lower())f:WriteByte(0)
			else
				f:Write("models/" .. dir .. data.file_name:lower())f:WriteByte(0)
			end
			f:WriteLong(#data.buffer)f:WriteLong(0)
			f:WriteLong(data.crc)
		end

		f:WriteLong(0)

		for i, data in ipairs(files) do
			f:Write(data.buffer)
		end

		f:Flush()

		local content = file.Read("pac3_cache/downloads/" .. id .. ".dat", "DATA")
		f:Write(util.CRC(content))
		f:Close()

		local ok, tbl = game.MountGMA("data/pac3_cache/downloads/" .. id .. ".dat")

		if not ok then
			onfail("failed to mount gma mdl")
			return
		end

		for k,v in pairs(tbl) do
			if v:EndsWith(".mdl") then
				callback(v)
				file.Delete("pac3_cache/downloads/" .. id .. ".dat")
				break
			end
		end
	end)
end