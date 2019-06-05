
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
		elseif IsColor(val) then
			table.insert(output, val)
			prevColor = val
		elseif valType == 'table' then
			table.insert(output, TABLE_COLOR)
			table.insert(output, tostring(val))
			table.insert(output, prevColor)
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

local DEBUG_MDL = false
local VERBOSE = false

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

	local bytes =  string.char(unpack(res))

	if #bytes ~= 4 then
		bytes = bytes .. ("\0"):rep(4 - #bytes)
	end

	return bytes
end

local function bytes_to_int(str,endian,signed) -- use length of string to determine 8,16,32,64 bits
    local t={str:byte(1,-1)}
    if endian=="big" then --reverse bytes
        local tt={}
        for k=1,#t do
            tt[#t-k+1]=t[k]
        end
        t=tt
    end
    local n=0
    for k=1,#t do
        n=n+t[k]*2^((k-1)*8)
    end
    if signed then
        n = (n > 2^(#t*8-1) -1) and (n - 2^(#t*8)) or n -- if last bit set, negative.
    end
    return n
end

local function read_string(f)
	local chars = {}
	for i = 1, 64 do
		local b = f:ReadByte()
		if not b or b == 0 then break end
		table.insert(chars, string.char(b))
	end

	return table.concat(chars)
end

local shader_params = include("pac3/libraries/shader_params.lua")
local texture_keys = {}

for _, shader in pairs(shader_params.shaders) do
	for _, params in pairs(shader) do
		for key, info in pairs(params) do
			if info.type == "texture" then
				texture_keys[key] = key
			end
		end
	end
end

for _, params in pairs(shader_params.base) do
	for key, info in pairs(params) do
		if info.type == "texture" then
			texture_keys[key] = key
		end
	end
end

-- for pac_restart
PAC_MDL_SALT = PAC_MDL_SALT or 0

local act_enums = {}

for k,v in pairs(_G) do
	if type(k) == "string" and k:StartWith("ACT_") and type(v) == "number" then
		table.insert(act_enums, {k = k, v = v})
	end
end

table.sort(act_enums, function(a, b) return #a.k > #b.k end)

function pac.DownloadMDL(url, callback, onfail, ply)
	return pac.resource.Download(url, function(path)
		if not ply:IsValid() then
			pac.Message(Color(255, 50, 50), "player is no longer valid")
			file.Delete(path)
			return
		end

		local file_content = file.Read(path)

		if not file_content then
			pac.Message(Color(255, 50, 50), "content is empty")
			file.Delete(path)
			return
		end

		for _, name in ipairs((file.Find("pac3_cache/downloads/*_temp.dat", "DATA"))) do
			file.Delete("pac3_cache/downloads/" .. name)
		end

		local skip_cache = false
		if url:StartWith("_") then
			skip_cache = true
			url = url:sub(2)
		end

		local id = util.CRC(url .. file_content .. PAC_MDL_SALT)

		if skip_cache then
			id = util.CRC(id .. os.clock())
		end

		if skip_cache or not file.Exists("pac3_cache/downloads/"..id..".dat", "DATA") then

			local dir = "pac3_cache/" .. id .. "/"

			local f = file.Open(path, "rb", "DATA")

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

					local name = f:Read(file_name_length):lower()
					local file_path = name

					if compression_method ~= 0 then
						error("the file " .. name .. " is compressed! (use compression method 0 / store, or maybe you drag dropped files into the archive)")
					end

					f:Skip(extra_field_length)

					local buffer = f:Read(size)

					name = name:match(".+/(.+)") or name

					if not buffer then
						if not file_path:EndsWith("/") then
							pac.Message(Color(255, 50,50), file_path .. " is empty")
						end
					else
						local ok = true
						for i,v in ipairs(files) do
							if v.file_name == name then
								if ply == pac.LocalPlayer then
									pac.Message(Color(255, 50,50), file_path .. " is already a file at " .. v.file_path)
								end
								ok = false
								break
							end
						end
						if ok then
							table.insert(files, {file_name = name, buffer = buffer, crc = crc, file_path = file_path})
						end
					end
				end
			end)

			f:Close()

			local count = 0
			local model_found = false
			local other_models = {}

			table.sort(files, function(a, b) return #a.buffer > #b.buffer end)

			for i, v in ipairs(files) do
				if v.file_name:EndsWith(".mdl") then
					local name = v.file_name:match("(.+)%.mdl")
					for _, v2 in ipairs(files) do
						if v2.file_name:EndsWith(name .. ".ani") then
							v.ani = v2
							break
						end
					end
					if v.ani then
						v.file_name = v.file_name:gsub(".-(%..+)", "i"..count.."%1"):lower()
						v.ani.file_name = v.ani.file_name:gsub(".-(%..+)", "i"..count.."%1"):lower()
						count = count + 1
					else
						if not model_found or v.file_name:StartWith(model_found) then
							model_found = v.file_name:match("(.-)%.")
							v.file_name = v.file_name:gsub(".-(%..+)", "model%1"):lower()
						else
							table.insert(other_models, v.file_name)
						end
					end
				elseif v.file_name:EndsWith(".vtx") or v.file_name:EndsWith(".vvd") or v.file_name:EndsWith(".phy") then
					if not model_found or v.file_name:StartWith(model_found) then
						model_found = v.file_name:match("(.-)%.")
						v.file_name = v.file_name:gsub(".-(%..+)", "model%1"):lower()
					else
						table.insert(other_models, v.file_name)
					end
				end
			end

			if other_models[1] and ply == pac.LocalPlayer then
				pac.Message(Color(255, 200, 50), url, ": the archive contains more than one model.")
				pac.Message(Color(255, 200, 50), url, ": " .. model_found .. " was selected.")
				pac.Message(Color(255, 200, 50), url, ": these are ignored:")
				PrintTable(other_models)
			end

			if VERBOSE then
				print("FILES:")
				for i, v in ipairs(files) do
					print(v.file_name)
				end
			end

			if not ok then
				onfail(err)
				local str = file.Read(path)
				file.Delete(path)

				pac.Message(Color(255, 50,50), err)
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
					pac.Message(Color(255, 50,50), "the url isn't a binary zip archive. Is it a html website? here's the content:")
					print(str)
				elseif ply == pac.LocalPlayer then
					file.Write("pac3_cache/failed_zip_download.dat", str)
					pac.Message("the zip archive was stored to garrysmod/data/pac3_cache/failed_zip_download.dat (rename extension to .zip) if you want to inspect it")
				end
				return
			end

			local required = {
				".mdl",
				".vvd",
				".dx90.vtx",
			}
			local found = {}
			for k,v in pairs(files) do
				for _, ext in ipairs(required) do
					if v.file_name:EndsWith(ext) then
						table.insert(found, ext)
						break
					end
				end
			end

			if #found < #required then
				local str = {}

				for _, ext in ipairs(required) do
					if not table.HasValue(found, ext) then
						table.insert(str, ext)
					end
				end

				onfail("could not find " .. table.concat(str, " or ") .. " in zip archive")

				return
			end

			do -- hex models
				local found_vmt_directories = {}
				local anim_name_offset
				local anim_name_str

				for i, data in ipairs(files) do
					if data.file_name:EndsWith(".mdl") then
						local found_materials = {}
						local found_activities = {}
						local found_mdl_includes = {}

						local vtf_dir_offset
						local vtf_dir_count

						local vmt_dir_offset
						local vmt_dir_count

						local include_mdl_dir_offset
						local include_mdl_dir_count

						if DEBUG_MDL then
							file.Write(data.file_name..".debug.old.dat", data.buffer)
						end

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
						f:Skip(8) -- bone
						f:Skip(8) -- bone controller
						f:Skip(8) -- hitbox
						f:Skip(8) -- local anim

						do
							local sequence_count = f:ReadLong()
							local sequence_offset = f:ReadLong()

							if sequence_count > 0 then
								local enums = table.Copy(act_enums)

								local old_pos = f:Tell()
								f:Seek(sequence_offset)
									for i = 1, sequence_count do
										local tbl = {}
										local seek_offset = f:Tell()
										local base_header_offset = f:ReadLong()
										tbl.name_offset = f:ReadLong()
										local activity_name_offset = f:ReadLong()

										local oldpos = f:Tell()
										f:Seek(seek_offset + activity_name_offset)
										local str = read_string(f)
										if _G[str] == nil then
											for i, v in ipairs(enums) do
												if #v.k <= #str then
													table.insert(found_activities, {from = str, to = v.k, offset = seek_offset + activity_name_offset})
													table.remove(enums, i)
													break
												end
											end
										end
										f:Seek(oldpos)

										tbl.flags = f:ReadLong()
										tbl.activity = f:ReadLong()
										tbl.activity_weight = f:ReadLong()
										tbl.event_count = f:ReadLong()
										tbl.event_offset = f:ReadLong()

										tbl.bbminx = f:ReadFloat()
										tbl.bbminy = f:ReadFloat()
										tbl.bbminz = f:ReadFloat()

										tbl.bbmaxx = f:ReadFloat()
										tbl.bbmaxy = f:ReadFloat()
										tbl.bbmaxz = f:ReadFloat()

										tbl.blend_count = f:ReadLong()
										tbl.anim_index_offset = f:ReadLong()
										tbl.movement_index = f:ReadLong()
										tbl.group_size_0 = f:ReadLong()
										tbl.group_size_1 = f:ReadLong()

										tbl.param_index_0 = f:ReadLong()
										tbl.param_index_1 = f:ReadLong()

										tbl.param_start_0 = f:ReadFloat()
										tbl.param_start_1 = f:ReadFloat()

										tbl.param_end_0 = f:ReadFloat()
										tbl.param_end_1 = f:ReadFloat()

										tbl.param_parent = f:ReadLong()

										tbl.fade_in_time = f:ReadFloat()
										tbl.fade_out_time = f:ReadFloat()

										tbl.local_entry_node_index = f:ReadLong()
										tbl.local_exit_node_index = f:ReadLong()
										tbl.node_flags = f:ReadLong()

										tbl.entry_phase = f:ReadFloat()
										tbl.exit_phase = f:ReadFloat()
										tbl.last_frame = f:ReadFloat()

										tbl.next_seq = f:ReadLong()
										tbl.pose = f:ReadLong()

										tbl.ikRuleCount = f:ReadLong()
										tbl.autoLayerCount = f:ReadLong()
										tbl.autoLayerOffset = f:ReadLong()
										tbl.weightOffset = f:ReadLong()
										tbl.poseKeyOffset = f:ReadLong()

										tbl.ikLockCount = f:ReadLong()
										tbl.ikLockOffset = f:ReadLong()
										tbl.keyValueOffset = f:ReadLong()
										tbl.keyValueSize = f:ReadLong()
										tbl.cyclePoseIndex = f:ReadLong()

										f:Skip(4*7)

									end
								f:Seek(old_pos)

							end
						end

						f:Skip(8) -- activitylistversion + eventsindexed

						do
							vmt_dir_count = f:ReadLong()
							vmt_dir_offset = f:ReadLong()

							local old_pos = f:Tell()
							f:Seek(vmt_dir_offset)
								local offset = f:ReadLong()
								if offset > -1 then
									if VERBOSE then print(data.file_name, "MATERIAL OFFSET:", vmt_dir_offset + offset) end
									f:Seek(vmt_dir_offset + offset)
									for i = 1, vmt_dir_count do
										local chars = {}
										for i = 1, 64 do
											local b = f:ReadByte()
											if not b or b == 0 then break end
											table.insert(chars, string.char(b))
										end

										local mat = (table.concat(chars) .. ".vmt"):lower()
										local found = false

										for i, v in pairs(files) do
											if v.file_name == mat then
												found = v.file_path
												break
											end
										end

										if not found then
											if ply == pac.LocalPlayer then
												pac.Message(Color(255, 50,50), url, " the model wants to find ", mat, " but it was not found in the zip archive")
											end
											local dummy = "VertexLitGeneric\n{\n\t$basetexture \"error\"\n}"
											table.insert(files, {file_name = mat, buffer = dummy, crc = util.CRC(dummy), file_path = mat})
										end

										table.insert(found_materials, mat)
									end
								end
							f:Seek(old_pos)

							if ply == pac.LocalPlayer and #found_materials == 0 then
								pac.Message(Color(255, 200, 50), url, ": could not find any materials in this model")
							end
						end


						do
							vtf_dir_count = f:ReadLong()
							vtf_dir_offset = f:ReadLong()
							local old_pos = f:Tell()
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

								if chars[1] then
									local dir = table.concat(chars)

									table.insert(found_vmt_directories, {offset = offset, dir = dir})
								end

								f:Seek(old_pos)
							end
							f:Seek(old_pos)
						end
							f:Skip(4 + 8) -- skin
							f:Skip(8) -- bodypart
							f:Skip(8) -- attachment
							f:Skip(4 + 8) -- localnode
							f:Skip(8) -- flex
							f:Skip(8) -- flex rules
							f:Skip(8) -- ik
							f:Skip(8) -- mouth
							f:Skip(8) -- localpose
							f:Skip(4) -- render2dprop
							f:Skip(8) -- keyvalues
							f:Skip(8) -- iklock
							f:Skip(12) -- mass
							f:Skip(4) -- contents

						do
							include_mdl_dir_count = f:ReadLong()
							include_mdl_dir_offset = f:ReadLong()

							local old_pos = f:Tell()

							f:Seek(include_mdl_dir_offset)
							for i = 1, include_mdl_dir_count do
								local base_pos = f:Tell()

								f:Skip(4)

								local file_name_offset = f:ReadLong()
								local old_pos = f:Tell()
								f:Seek(base_pos + file_name_offset)
								table.insert(found_mdl_includes, {offset = base_pos + file_name_offset, path = read_string(f)})
								f:Seek(old_pos)
							end

							f:Seek(old_pos)
						end

						f:Skip(4) -- virtual pointer

						anim_name_offset = f:ReadLong()
						f:Seek(anim_name_offset)
						anim_name_str = read_string(f)

						f:Close()

						if VERBOSE or DEBUG_MDL then
							print(data.file_name, "MATERIAL DIRECTORIES:")
							PrintTable(found_vmt_directories)
							print("============")
							print(data.file_name, "MATERIALS:")
							PrintTable(found_materials)
							print("============")
							print(data.file_name, "ACTIVITIES:")
							PrintTable(found_activities)
							print("============")
							print(data.file_name, "MDL_INCLUDES:")
							PrintTable(found_mdl_includes)
							print("============")
						end

						local buffer = file.Read("pac3_cache/temp.dat")
						local original_size = #buffer
						file.Delete("pac3_cache/temp.dat")

						local newdir = dir
						local newname = (dir .. data.file_name:lower()):gsub("/", "\\")
						newdir = newdir:gsub("\\", "/")

						do -- replace the mdl name (max size is 64 bytes)
							local newname = newname
							if #newname < #name then
								newname = newname .. ("\0"):rep(#name - #newname)
							end

							buffer = buffer:sub(0, name_offset) .. newname .. buffer:sub(name_offset + #name + 1)
						end

						-- replace bad activity names with ones that gmod is okay with (should never extend size)
						for i,v in ipairs(found_activities) do
							local newname = v.to .. ("\0"):rep(#v.from - #v.to)
							buffer = buffer:sub(0, v.offset) .. newname .. buffer:sub(v.offset + #v.from + 1)
						end

						for i,v in ipairs(found_mdl_includes) do
							local file_name = (v.path:match(".+/(.+)") or v.path)
							local found = false

							for _, info in ipairs(files) do
								if info.file_path == file_name then
									file_name = info.file_name
									found = true
									break
								end
							end

							local path = "models/" .. newdir .. file_name

							if found then
								buffer = buffer:sub(0, v.offset) .. path .. buffer:sub(v.offset + #v.path + 1)

								local new_offset = #path - #v.path

								for i,v in ipairs(found_vmt_directories) do
									v.offset = v.offset + new_offset
								end

								local int_bytes = buffer:sub(vmt_dir_offset + 1, vmt_dir_offset + 4)
								local offset = bytes_to_int(int_bytes) + new_offset
								int_bytes = int_to_bytes(offset)
								buffer = buffer:sub(0, vmt_dir_offset) .. int_bytes .. buffer:sub(vmt_dir_offset + 4 + 1)

								if VERBOSE then
									print(data.file_name, "vmt_dir_offset: ", vmt_dir_offset)
									print(data.file_name, "NEW MATERIAL OFFSET:", vmt_dir_offset + offset)
								end

								local pos = vtf_dir_offset
								for i = 1, vtf_dir_count do
									local int_bytes = int_to_bytes(bytes_to_int(buffer:sub(pos + 1, pos + 4)) + new_offset)
									buffer = buffer:sub(0, pos) .. int_bytes .. buffer:sub(pos + 4 + 1)
									pos = pos + 4
								end
							else
								if ply == pac.LocalPlayer then
									pac.Message(Color(255, 50, 50), "the model want to include ", path, " but it doesn't exist")
								end
							end
						end

						-- if we extend the mdl file with vmt directories we don't have to change any offsets cause nothing else comes after it
						if data.file_name == "model.mdl" then
							for i,v in ipairs(found_vmt_directories) do
								local newdir = newdir .. ("\0"):rep(#v.dir - #newdir + 1)
								buffer = buffer:sub(0, v.offset) .. newdir .. buffer:sub(v.offset + #v.dir + 1)
							end
						else
							local new_name = newdir .. data.file_name:gsub("mdl$", "ani")

							buffer = buffer:sub(0, anim_name_offset) .. new_name .. buffer:sub(anim_name_offset + #anim_name_str + 1)
						end

						if #buffer ~= original_size then
							local size_bytes = int_to_bytes(#buffer)

							buffer = buffer:sub(0, size_offset) .. size_bytes .. buffer:sub(size_offset + 4 + 1)
						end

						if DEBUG_MDL then
							file.Write(data.file_name..".debug.new.dat", buffer)
						end

						data.buffer = buffer
						data.crc = int_to_bytes(tonumber(util.CRC(data.buffer)))
					end
				end

				for i, data in ipairs(files) do
					if data.file_name:EndsWith(".vmt") then
						local newdir = dir

						data.buffer = data.buffer:lower():gsub("\\", "/")

						if DEBUG_MDL or VERBOSE then
							print(data.file_name .. ":")
						end

						for shader_param in pairs(texture_keys) do
							data.buffer = data.buffer:gsub('("?%$' .. shader_param .. '"?%s+")(.-)(")', function(l, vtf_path, r)
								if vtf_path == "env_cubemap" then
									return
								end

								local new_path
								for _, info in ipairs(found_vmt_directories) do
									new_path, count = vtf_path:gsub("^" .. info.dir:gsub("\\", "/"):lower(), newdir)
									if count == 0 then
										new_path = nil
									else
										break
									end
								end

								for _, info in ipairs(files) do
									if info.file_name:EndsWith(".vtf") then
										local vtf_name = (vtf_path:match(".+/(.+)") or vtf_path)
										if info.file_name == vtf_name .. ".vtf" then
											new_path = newdir .. vtf_name
											break
										end
									end
								end

								if not new_path then
									if not file.Exists("materials/" .. vtf_path .. ".vtf", "GAME") then
										if ply == pac.LocalPlayer then
											pac.Message(Color(255, 50, 50), "vmt ", data.file_name, " wants to find texture materials/", vtf_path, ".vtf for $", shader_param ," but it doesn't exist")
											print(data.buffer)
										end
									end
									new_path = vtf_path -- maybe it's a special texture? in that case i need to it
								end

								if DEBUG_MDL or VERBOSE then
									print("\t" .. vtf_path .. " >> " .. new_path)
								end

								return l .. new_path .. r
							end)
						end

						data.crc = int_to_bytes(tonumber(util.CRC(data.buffer)))
					end
				end
			end
			if skip_cache then
				id = id .. "_temp"
			end

			local path = "pac3_cache/downloads/" .. id .. ".dat"
			local f = file.Open(path, "wb", "DATA")

			if not f then
				onfail("unable to open file " .. path .. " for writing")

				pac.Message(Color(255, 50, 50), "unable to write to ", path, " for some reason")
				if file.Exists(path, "DATA") then
					pac.Message(Color(255, 50, 50), "the file exists and its size is ", string.NiceSize(file.Size(path, "DATA")))
					pac.Message(Color(255, 50, 50), "is it locked or in use by something else?")
				else
					pac.Message(Color(255, 50, 50), "the file does not exist")
					pac.Message(Color(255, 50, 50), "are you out of disk space?")
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
		end

		local ok, tbl = game.MountGMA("data/pac3_cache/downloads/" .. id .. ".dat")

		if not ok then
			onfail("failed to mount gma mdl")
			return
		end

		for k,v in pairs(tbl) do
			if v:EndsWith("model.mdl") then
				if VERBOSE and not DEBUG_MDL then
					print("util.IsValidModel: ", tostring(util.IsValidModel(v)))

					local dev = GetConVar("developer"):GetFloat()
					if dev == 0 then
						RunConsoleCommand("developer", "3")

						timer.Simple(0.1, function()
							if CLIENT then
								ClientsideModel(v):Remove()
							else
								local ent = ents.Create("prop_dynamic")
								ent:SetModel(v)
								ent:Spawn()
								ent:Remove()
							end
							print("created and removed model")
							RunConsoleCommand("developer", "0")
						end)
					else
						if CLIENT then
							ClientsideModel(v):Remove()
						else
							local ent = ents.Create("prop_dynamic")
							ent:SetModel(v)
							ent:Spawn()
							ent:Remove()
						end
					end
				end

				callback(DEBUG_MDL and "models/error.mdl" or v)
				file.Delete("pac3_cache/downloads/" .. id .. ".dat")
				break
			end
		end
	end, onfail)
end