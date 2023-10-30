
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

texture_keys["include"] = "include"

-- for pac_restart
PAC_MDL_SALT = PAC_MDL_SALT or 0

local cached_paths = {}

function pac.DownloadMDL(url, callback, onfail, ply)
	local skip_cache = false

	if url:StartWith("_") then
		skip_cache = true
		url = url:sub(2)
	end

	if not skip_cache and cached_paths[url] then
		callback(cached_paths[url])
		return
	end

	return pac.resource.Download(url, function(path)
		if ply:IsPlayer() and not ply:IsValid() then
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

		local id = util.CRC(url .. file_content)

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

				for i, data in ipairs(files) do
					if data.file_name:EndsWith(".mdl") then
						local found_materials = {}
						local found_materialdirs = {}
						local found_mdl_includes = {}

						local vtf_dir_offset
						local vtf_dir_count

						local material_offset
						local material_count

						local include_mdl_dir_offset
						local include_mdl_dir_count

						if DEBUG_MDL then
							file.Write(data.file_name..".debug.old.dat", data.buffer)
						end

						local f = pac.StringStream(data.buffer)
						local id = f:read(4)
						local version = f:readUInt32()
						local checksum = f:readUInt32()

						local name_offset = f:tell()
						local name = f:read(64)
						local size_offset = f:tell()
						local size = f:readUInt32()

						f:skip(12 * 6) -- skips over all the vec3 stuff

						f:skip(4) -- flags
						f:skip(8) -- bone
						f:skip(8) -- bone controller
						f:skip(8) -- hitbox
						f:skip(8) -- local anim
						f:skip(8) -- sequences
						f:skip(8) -- activitylistversion + eventsindexed

						do
							material_count = f:readUInt32()
							material_offset = f:readUInt32() + 1 -- +1 to convert 0 indexed to 1 indexed

							local old_pos = f:tell()
							f:seek(material_offset)

							for i = 1, material_count do
								local material_start = f:tell()
								local material_name_offset = f:readInt32()
								f:skip(60)
								local material_end = f:tell()

								local material_name_pos = material_start + material_name_offset
								f:seek(material_name_pos)

								local material_name = (f:readString() .. ".vmt"):lower()
								local found = false

								for i, v in pairs(files) do
									if v.file_name == material_name then
										found = v.file_path
										break
									elseif v.file_path == ("materials/" .. material_name) then
										v.file_name = material_name
										found = v.file_path
										break
									end
								end

								if not found then
									for i, v in pairs(files) do
										if string.find(v.file_path, material_name, 1, true) or string.find(material_name, v.file_name, 1, true) then
											table.insert(files, {file_name = material_name, buffer = v.buffer, crc = v.crc, file_path = v.file_path})
											found = v.file_path
											break
										end
									end
								end

								if not found then
									if ply == pac.LocalPlayer then
										pac.Message(Color(255, 50,50), url, " the model wants to find ", material_name , " but it was not found in the zip archive")
									end
									local dummy = "VertexLitGeneric\n{\n\t$basetexture \"error\"\n}"
									table.insert(files, {file_name = material_name, buffer = dummy, crc = util.CRC(dummy), file_path = material_name})
								end

								table.insert(found_materials, {name = material_name, offset = material_name_pos})
								f:seek(material_end)
							end

							if ply == pac.LocalPlayer and #found_materials == 0 then
								pac.Message(Color(255, 200, 50), url, ": could not find any materials in this model")
							end

							f:seek(old_pos)
						end


						do
							vtf_dir_count = f:readUInt32()
							vtf_dir_offset = f:readUInt32() + 1 -- +1 to convert 0 indexed to 1 indexed

							local old_pos = f:tell()
							f:seek(vtf_dir_offset)
							for i = 1, vtf_dir_count do
								local offset_pos = f:tell()
								local offset = f:readUInt32() + 1 -- +1 to convert 0 indexed to 1 indexed

								local old_pos = f:tell()
								f:seek(offset)
								local dir = f:readString()
								table.insert(found_materialdirs, {offset_pos = offset_pos, offset = offset, dir = dir})
								table.insert(found_vmt_directories, {dir = dir})
								f:seek(old_pos)
							end
							table.sort(found_vmt_directories, function(a,b) return #a.dir>#b.dir end)
							f:seek(old_pos)
						end

						f:skip(4 + 8) -- skin
						f:skip(8) -- bodypart
						f:skip(8) -- attachment
						f:skip(4 + 8) -- localnode
						f:skip(8) -- flex
						f:skip(8) -- flex rules
						f:skip(8) -- ik
						f:skip(8) -- mouth
						f:skip(8) -- localpose
						f:skip(4) -- render2dprop
						f:skip(8) -- keyvalues
						f:skip(8) -- iklock
						f:skip(12) -- mass
						f:skip(4) -- contents

						do
							include_mdl_dir_count = f:readUInt32()
							include_mdl_dir_offset = f:readUInt32() + 1 -- +1 to convert 0 indexed to 1 indexed

							local old_pos = f:tell()

							f:seek(include_mdl_dir_offset)
							for i = 1, include_mdl_dir_count do
								local base_pos = f:tell()

								f:skip(4)

								local file_name_offset = f:readUInt32()
								local old_pos = f:tell()
									f:seek(base_pos + file_name_offset)
									table.insert(found_mdl_includes, {base_pos = base_pos, path = f:readString()})
								f:seek(old_pos)
							end

							f:seek(old_pos)
						end

						f:skip(4) -- virtual pointer

						local anim_name_offset_pos = f:tell()

						if VERBOSE or DEBUG_MDL then
							print(data.file_name, "MATERIAL DIRECTORIES:")
							PrintTable(found_materialdirs)
							print("============")
							print(data.file_name, "MATERIALS:")
							PrintTable(found_materials)
							print("============")
							print(data.file_name, "MDL_INCLUDES:")
							PrintTable(found_mdl_includes)
							print("============")
						end

						do -- replace the mdl name (max size is 64 bytes)
							local newname = string.sub(dir .. data.file_name:lower(), 1, 63)
							f:seek(name_offset)
							f:write(newname .. string.rep("\0", 64-#newname))
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

							if found then
								local path = "models/" .. dir .. file_name
								local newoffset = f:size() + 1
								f:seek(newoffset)
								f:writeString(path)
								f:seek(v.base_pos + 4)
								f:writeInt32(newoffset - v.base_pos)
							elseif ply == pac.LocalPlayer and not file.Exists(v.path, "GAME") then
								pac.Message(Color(255, 50, 50), "the model want to include ", v.path, " but it doesn't exist")
							end
						end

						-- if we extend the mdl file with vmt directories we don't have to change any offsets cause nothing else comes after it
						if data.file_name == "model.mdl" then
							for i,v in ipairs(found_materialdirs) do
								local newoffset = f:size() + 1
								f:seek(newoffset)
								f:writeString(dir)
								f:seek(v.offset_pos)
								f:writeInt32(newoffset - 1) -- -1 to convert 1 indexed to 0 indexed
							end
						else
							local new_name = "models/" .. dir .. data.file_name:gsub("mdl$", "ani")
							local newoffset = f:size() + 1
							f:seek(newoffset)
							f:writeString(new_name)
							f:seek(anim_name_offset_pos)
							f:writeInt32(newoffset - 1) -- -1 to convert 1 indexed to 0 indexed
						end

						local cursize = f:size()

						-- Add nulls to align to 4 bytes
						local padding = 4-cursize%4
						if padding<4 then
							f:seek(cursize+1)
							f:write(string.rep("\0",padding))
							cursize = cursize + padding
						end

						f:seek(size_offset)
						f:writeInt32(cursize)

						data.buffer = f:getString()

						if DEBUG_MDL then
							file.Write(data.file_name..".debug.new.dat", data.buffer)
						end

						local crc = pac.StringStream()
						crc:writeInt32(tonumber(util.CRC(data.buffer)))
						data.crc = crc:getString()
					end
				end

				for i, data in ipairs(files) do
					if data.file_name:EndsWith(".vmt") then
						local proxies = data.buffer:match('("?%f[%w_]P?p?roxies%f[^%w_]"?%s*%b{})')
						data.buffer = data.buffer:lower():gsub("\\", "/")

						if proxies then
							data.buffer = data.buffer:gsub('("?%f[%w_]proxies%f[^%w_]"?%s*%b{})', proxies)
						end

						if DEBUG_MDL or VERBOSE then
							print(data.file_name .. ":")
						end

						for shader_param in pairs(texture_keys) do
							data.buffer = data.buffer:gsub('("?%$?%f[%w_]' .. shader_param .. '%f[^%w_]"?%s+"?)([^"%c]+)("?%s?)', function(l, vtf_path, r)
								if vtf_path == "env_cubemap" then
									return
								end

								local new_path
								for _, info in ipairs(found_vmt_directories) do
									if info.dir == "" then continue end

									new_path, count = vtf_path:gsub("^" .. info.dir:gsub("\\", "/"):lower(), dir)
									if count == 0 then
										new_path = nil
									else
										break
									end
								end

								if not new_path then
									for _, info in ipairs(files) do
										local vtf_name = (vtf_path:match(".+/(.+)") or vtf_path)
										if info.file_name:EndsWith(".vtf") then
											if info.file_name == vtf_name .. ".vtf" or info.file_name == vtf_name then
												new_path = dir .. vtf_name
												break
											end
										elseif (info.file_name:EndsWith(".vmt") and l:StartWith("include")) then
											if info.file_name == vtf_name then
												new_path = "materials/" .. dir .. vtf_name
												break
											end
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

						local crc = pac.StringStream()
						crc:writeInt32(tonumber(util.CRC(data.buffer)))
						data.crc = crc:getString()
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

				cached_paths[url] = v
				callback(v)

				file.Delete("pac3_cache/downloads/" .. id .. ".dat")
				break
			end
		end
	end, onfail)
end
