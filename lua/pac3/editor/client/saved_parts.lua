local L = pace.LanguageString


function pace.SaveParts(name, prompt_name, override_part)
	if not name or prompt_name then
		Derma_StringRequest(
			L"save parts",
			L"filename:",
			prompt_name or pace.LastSaveName or "autoload",

			function(name)
				pace.LastSaveName = name
				pace.SaveParts(name, nil, override_part)

				pace.RefreshFiles()
			end
		)
	else
		pac.dprint("saving parts %s", name)

		local data = {}

		if pace.use_current_part_for_saveload and pace.current_part:IsValid() then
			override_part = pace.current_part
		end

		if override_part then
			data = override_part:ToTable()
		else
			for key, part in pairs(pac.GetParts(true)) do
				if not part:HasParent() and part.show_in_editor ~= false then
					table.insert(data, part:ToTable())
				end
			end
		end

		data = hook.Run("pac_pace.SaveParts",data) or data

		file.CreateDir("pac3")
		file.CreateDir("pac3/__backup/")


		if not override_part and #file.Find("pac3/sessions/*", "DATA") > 0 and not name:find("/") then
			pac.luadata.WriteFile("pac3/sessions/" .. name .. ".txt", data)
		else
			pac.luadata.WriteFile("pac3/" .. name .. ".txt", data)
		end

		pace.Backup(data, name)
	end
end

function pace.Backup(data, name)
	name = name or ""

	if not data then
		data = {}
		for key, part in pairs(pac.GetParts(true)) do
			if not part:HasParent() then
				table.insert(data, part:ToTable())
			end
		end
	end

	if #data > 0 then

		local files, folders = file.Find("pac3/__backup/*", "DATA")
		--local newest_time,newest_name
		if #files > 200 then
			chat.AddText("PAC3 is trying to delete backup files (new system) but you have way too many for lua to delete because of the old system")
			chat.AddText(
				("Go to %s and delete everything in that folder! You should only get this warning once if you've used the SVN version of PAC3.")
				:format(util.RelativePathToFull("lua/includes/init.lua"):gsub("\\", "/"):gsub("lua/includes/init.lua", "data/pac3/__backup/"))
			)
		elseif #files > 100 then
			local temp = {}
			for key, name in pairs(files) do
				local time = file.Time("pac3/__backup/" .. name, "DATA")
				table.insert(temp, {path = "pac3/__backup/" .. name, time = time})
			end

			table.sort(temp, function(a, b)
				return a.time > b.time
			end)

			for i = 100, #files do
				file.Delete(temp[i].path, "DATA")
			end
		end

		--if not newest_name then
		--	for key, name in pairs(files) do
		--		local time = file.Time("pac3/__backup/" .. name, "DATA")
		--		if time > newest_time then
		--			newest_time = time
		--			newest_name = name
		--		end
		--	end
		--end

		local date = os.date("%y-%m-%d-%H_%M_%S")
		pac.luadata.WriteFile("pac3/__backup/" .. (name=="" and name or (name..'_')) .. date .. ".txt", data)
	end
end

function pace.LoadParts(name, clear, override_part)
	if not name then
		local frm = vgui.Create("DFrame")
		frm:SetTitle(L"parts")
		local pnl = pace.CreatePanel("browser", frm)

		pnl.OnLoad = function(node)
			pace.LoadParts(node.FileName, clear, override_part)
		end

		if #file.Find("pac3/sessions/*", "DATA") > 0 then
			pnl:SetDir("sessions/")
		else
			pnl:SetDir("")
		end

		pnl:Dock(FILL)

		frm:SetSize(300, 500)
		frm:MakePopup()
		frm:Center()

		local btn = vgui.Create("DButton", frm)
		btn:Dock(BOTTOM)
		btn:SetText(L"load from url")
		btn.DoClick = function()
			Derma_StringRequest(
				L"load part",
				L"pastebin urls also work!",
				"",
				function(name)
					pace.LoadParts(name, clear, override_part)
				end
			)
		end

	else
		pac.dprint("loading Parts %s",  name)

		if name:find("https?://") then

			name = pac.FixupURL(name)

			local function callback(str)
				local data,err = pac.luadata.Decode(str)
				if not data then
					ErrorNoHalt(("URL fail: %s : %s\n"):format(name,err))
					return
				end
				pace.LoadPartsFromTable(data, clear, override_part)
			end

			pac.SimpleFetch(name, callback)
		else
			name = name:gsub("%.txt", "")

			local data,err = pac.luadata.ReadFile("pac3/" .. name .. ".txt")

			if name == "autoload" and (not data or not next(data)) then
				local err
				data,err = pac.luadata.ReadFile("pac3/sessions/" .. name .. ".txt",nil,true)
				if not data then
					if err then
						ErrorNoHalt(("Autoload failed: %s\n"):format(err))
					end
					return
				end
			elseif not data then
				ErrorNoHalt(("Decoding %s failed: %s\n"):format(name,err))
				return
			end

			pace.LoadPartsFromTable(data, clear, override_part)
		end
	end
end

function pace.LoadPartsFromTable(data, clear, override_part)
	if pace.use_current_part_for_saveload and pace.current_part:IsValid() then
		override_part = pace.current_part
	end

	if clear then
		pace.ClearParts()
	end

	if data.self then
		local part = override_part or pac.CreatePart(data.self.ClassName)
		part:SetTable(data)
	else
		data = pace.FixBadGrouping(data)
		data = pace.FixUniqueIDs(data)

		for key, tbl in pairs(data) do
			local part = pac.CreatePart(tbl.self.ClassName)
			part:SetTable(tbl)
		end
	end

	pace.RefreshTree(true)
end

local function add_files(tbl, dir)
	local files, folders = file.Find("pac3/" .. dir .. "/*", "DATA")

	if folders then
		for key, folder in pairs(folders) do
			if folder == "__backup" or folder == "objcache" or folder == "__animations" then continue end
			tbl[folder] = {}
			add_files(tbl[folder], dir .. "/" .. folder)
		end
	end

	if files then
		for i, name in pairs(files) do
			if name:find("%.txt") then
				local path = "pac3/" .. dir .. "/" .. name

				if file.Exists(path, "DATA") then
					local data = {}
						data.Name = name:gsub("%.txt", "")
						data.FileName = name
						data.Size = string.NiceSize(file.Size(path, "DATA"))
						local time = file.Time(path, "DATA")
						data.LastModified = os.date("%m/%d/%Y %H:%M", time)
						data.Time = file.Time(path, "DATA")
						data.Path = path
						data.RelativePath = (dir .. "/" .. data.Name):sub(2)

					local dat,err=pac.luadata.ReadFile(path)
						data.Content = dat

					if dat then
						table.insert(tbl, data)
					else
						pac.dprint(("Decoding %s failed: %s\n"):format(path,err))
						chat.AddText(("Could not load: %s\n"):format(path))
					end

				end
			end
		end
	end

	table.sort(tbl, function(a,b)
		if a.Time and b.Time then
			return a.Name < b.Name
		end

		return true
	end)
end

function pace.GetSavedParts(dir)
	if pace.CachedFiles then
		return pace.CachedFiles
	end

	local out = {}

	add_files(out, dir or "")

	pace.CachedFiles = out

	return out
end

local function populate_part(menu, part, override_part, clear)
	local name = part.self.Name or ""

	if name == "" then
		name = part.self.ClassName .. " (no name)"
	end

	if #part.children > 0 then
		local menu, pnl = menu:AddSubMenu(name, function() pace.LoadPartsFromTable(part, nil, override_part) end)
		pnl:SetImage(pace.GetIconFromClassName(part.self.ClassName))
		menu.GetDeleteSelf = function() return false end
		local old = menu.Open
		menu.Open = function(...)
			if not menu.pac_opened then
				for key, part in pairs(part.children) do
					populate_part(menu, part, override_part, clear)
				end
				menu.pac_opened = true
			end

			return old(...)
		end
	else
		menu:AddOption(name, function()
			pace.LoadPartsFromTable(part, clear, override_part)
		end):SetImage(pace.GetIconFromClassName(part.self.ClassName))
	end
end

local function populate_parts(menu, tbl, override_part, clear)
	for key, data in pairs(tbl) do
		if not data.Path then
			local menu, pnl = menu:AddSubMenu(key, function()end, data)
			pnl:SetImage(pace.MiscIcons.load)
			menu.GetDeleteSelf = function() return false end
			local old = menu.Open
			menu.Open = function(...)
				if not menu.pac_opened then
					populate_parts(menu, data, override_part, clear)
					menu.pac_opened = true
				end

				return old(...)
			end
		else
			local icon = pace.MiscIcons.outfit
			local parts = data.Content

			if parts.self then
				icon = pace.GetIconFromClassName(parts.self.ClassName)
				parts = {parts}
			end

			local outfit, pnl = menu:AddSubMenu(data.Name, function()
				pace.LoadParts(data.RelativePath, clear, override_part)
			end)
			pnl:SetImage(icon)
			outfit.GetDeleteSelf = function() return false end

			local old = outfit.Open
			outfit.Open = function(...)
				if not outfit.pac_opened then
					for key, part in pairs(parts) do
						populate_part(outfit, part, override_part, clear)
					end
					outfit.pac_opened = true
				end

				return old(...)
			end
		end
	end
end

function pace.AddSavedPartsToMenu(menu, clear, override_part)
	menu.GetDeleteSelf = function() return false end

	menu:AddOption(L"load from url", function()
		Derma_StringRequest(
			L"load parts",
			L"pastebin urls also work!",
			"",

			function(name)
				pace.LoadParts(name, clear, override_part)
			end
		)
	end):SetImage(pace.MiscIcons.url)

	if not override_part and pace.example_outfits then
		local examples, pnl = menu:AddSubMenu(L"examples")
		pnl:SetImage(pace.MiscIcons.help)
		examples.GetDeleteSelf = function() return false end

		local sorted = {}
		for k,v in pairs(pace.example_outfits) do sorted[#sorted + 1] = {k = k, v = v} end
		table.sort(sorted, function(a, b) return a.k < b.k end)

		for _, data in pairs(sorted) do
			examples:AddOption(data.k, function() pace.LoadPartsFromTable(data.v) end)
			:SetImage(pace.MiscIcons.outfit)
		end
	end

	local backups, pnl = menu:AddSubMenu(L"backups")
	pnl:SetImage(pace.MiscIcons.clone)
	backups.GetDeleteSelf = function() return false end
	local files = file.Find("pac3/__backup/*", "DATA")
	table.sort(files, function(a, b)
		return file.Time("pac3/__backup/" .. a, "DATA") > file.Time("pac3/__backup/" .. b, "DATA")
	end)
	for _, name in pairs(files) do
		local full_path = "pac3/__backup/" .. name
		local friendly_name = os.date("%m/%d/%Y %H:%M:%S ", file.Time(full_path, "DATA")) .. string.NiceSize(file.Size(full_path, "DATA"))
		backups:AddOption(friendly_name, function() pace.LoadParts("__backup/" .. name, true) end)
		:SetImage(pace.MiscIcons.outfit)
	end

	menu:AddSpacer()

	local tbl = pace.GetSavedParts()
	populate_parts(menu, tbl, override_part, clear)
end

local function populate_parts(menu, tbl, dir, override_part)
	dir = dir or ""
	menu:AddOption(L"new file", function() pace.SaveParts(nil, dir .. "/", override_part) end)
	:SetImage(pace.MiscIcons.new)
	menu:AddSpacer()
	for key, data in pairs(tbl) do
		if not data.Path then
			local menu, pnl = menu:AddSubMenu(key, function()end, data)
			pnl:SetImage(pace.MiscIcons.load)
			menu.GetDeleteSelf = function() return false end
			populate_parts(menu, data, dir .. "/" .. key, override_part)
		else
			local parts = data.Content

			if parts[1] then
				local menu, pnl = menu:AddSubMenu(data.Name, function() pace.SaveParts(nil, data.RelativePath, override_part) end)
				menu.GetDeleteSelf = function() return false end
				pnl:SetImage(pace.MiscIcons.outfit)

				menu:AddOption(L"delete", function()
					file.Delete("pac3/" .. data.RelativePath .. ".txt", "DATA")
					pace.RefreshFiles()
				end):SetImage(pace.MiscIcons.clear)

				pnl:SetImage(pace.MiscIcons.outfit)
			elseif parts.self then
				menu:AddOption(data.Name, function() pace.SaveParts(nil, data.RelativePath, override_part)  end)
				:SetImage(pace.GetIconFromClassName(parts.self.ClassName))
			end
		end
	end
end

function pace.AddSaveMenuToMenu(menu, override_part)
	menu.GetDeleteSelf = function() return false end

	if not override_part then
		menu:AddOption(L"auto load (your spawn outfit)", function()
			pace.SaveParts("autoload", nil, override_part)
			pace.RefreshFiles()
		end)
		:SetImage(pace.MiscIcons.autoload)
		menu:AddSpacer()
	end

	local tbl = pace.GetSavedParts()
	populate_parts(menu, tbl, nil, override_part)
end

-- this fixes parts that are using the same uniqueid as other parts because of some bugs in older versions
function pace.FixUniqueIDs(data)
	local ids = {}

	local function iterate(part)
		ids[part.self.UniqueID] = ids[part.self.UniqueID] or {}

		table.insert(ids[part.self.UniqueID], part)

		for key, part in pairs(part.children) do
			iterate(part)
		end
	end

	for key, part in pairs(data) do
		iterate(part)
	end

	for key, val in pairs(ids) do
		if #val > 1 then
			for key, part in pairs(val) do
				pac.dprint("Part (%s using model %s) named %q has %i other parts with the same unique id. Fixing!", part.self.ClassName, part.self.Name, part.self.Model or "", #val)
				part.self.UniqueID = util.CRC(key .. tostring(part) .. SysTime())
			end
		end
	end

	return data
end

-- this is for fixing parts that are not in a group

function pace.FixBadGrouping(data)
	local parts = {}
	local other = {}

	for key, part in pairs(data) do
		if part.self.ClassName ~= "group" then
			table.insert(parts, part)
		else
			table.insert(other, part)
		end
	end

	if #parts > 0 then
		local out = {
			{
				["self"] = {
					["EditorExpand"] = true,
					["ClassName"] = "group",
					["UniqueID"] = util.CRC(tostring(data)),
					["Name"] = "automatic group",
					["Description"] = "Please put your parts in groups!",
				},

				["children"] = parts,
			},
		}

		for k,v in pairs(other) do
			table.insert(out, v)
		end

		return out
	end

	return data
end