local L = pace.LanguageString

function pace.WearSession()
	for key, part in pairs(pac.GetParts(true)) do
		if not part:HasParent() then
			pac.SendPartToServer(part)
		end
	end
end

function pace.ClearSession()
	pac.RemoveAllParts(true, true)
	pace.RefreshTree()
end

function pace.SaveSession(name)
	if not name then
		Derma_StringRequest(
			L"save session",
			L"filename:",
			pace.LastSaveName or "autoload",

			function(name)
				pace.LastSaveName = name
				pace.SaveSession(name)
			end
		)
	else
		pac.dprint("saving session %s", name)
		
		local data = {}
		
		for key, part in pairs(pac.GetParts(true)) do
			if not part:HasParent() then
				table.insert(data, part:ToTable())
			end
		end
		
		file.CreateDir("pac3")
		file.CreateDir("pac3/sessions")
		pac.luadata.WriteFile("pac3/sessions/" .. name .. ".txt", data)
		
		if pace.SpawnlistBrowser:IsValid() then
			pace.SpawnlistBrowser:PopulateFromClient()
		end
	end
end

function pace.LoadSession(name, append)
	if not name then
		local frm = vgui.Create("DFrame")
		frm:SetTitle(L"sessions")
		local pnl = pace.CreatePanel("browser", frm)
		
		pnl.OnLoad = function(node)
			pace.LoadSession(node.FileName)
		end
		pnl:SetDir("sessions/")
		
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
					pace.LoadSession(name, append)
				end
			)
		end
		
	else
		pac.dprint("loading session %s",  name)
		
		if not append then
			for key, part in pairs(pac.GetParts(true)) do
				if not part:HasParent() then
					pac.RemovePartOnServer(part:GetName(), nil, true)
					part:Remove()
				end
			end
		end
		
		if name:find("http") then	
			name = name:gsub("https://", "http://")
			
			if name:lower():find("pastebin.com") then
				name = name:gsub(".com/", ".com/raw.php?i=")
			end
			
			local function callback(str)
				local data = pac.luadata.Decode(str)
		
				for key, tbl in pairs(data) do
					local part = pac.CreatePart(tbl.self.ClassName)
					part:SetTable(tbl)
				end
				
				pace.RefreshTree(true)
			end
			
			http.Fetch(name, callback)		
		else
			name = name:gsub("%.txt", "")
		
			local data = pac.luadata.ReadFile("pac3/sessions/" .. name .. ".txt")
			
			data = pac.FixSession(data)
			
			timer.Simple(0.1, function()				
				for key, tbl in pairs(data) do
					local part = pac.CreatePart(tbl.self.ClassName)
					part:SetTable(tbl)
				end
				
				pace.RefreshTree(true)
			end)
			
		end
	end
end

function pace.GetSessions()
	local out = {}
	
	for i, name in pairs(file.Find("pac3/sessions/*", "DATA")) do
		if name:find("%.txt") then
			local outfit = "pac3/sessions/" .. name
			if file.Exists(outfit, "DATA") then
				local data = {}
					data.Name = name:gsub("%.txt", "")
					data.FileName = name
					data.Size = string.NiceSize(file.Size(outfit, "DATA"))
					data.LastModified = os.date("%m/%d/%Y %H:%M", file.Time(outfit, "DATA"))
				table.insert(out, data)
			end
		end
	end
	
	return out
end

function pace.AddSessionsToMenu(menu)
	menu.GetDeleteSelf = function() return false end
	for key, data in pairs(pace.GetSessions()) do
		local menu = menu:AddSubMenu(data.Name, function() pace.LoadSession(data.FileName) end)
		menu.GetDeleteSelf = function() return false end
		menu:AddOption(L"rename", function()
			Derma_StringRequest(L"rename", L"type the new name:", data.Name, function(text)
				
				local c = file.Read(data.FileName)
				file.Delete(data.FileName, "DATA")
				file.Write(data.FileName, c, "DATA")
			end)
		end)
		
		local clear = menu:AddSubMenu(L"delete", function() end)
		clear.GetDeleteSelf = function() return false end
		clear:AddOption(L"OK", function() file.Delete("pac3/sessions/" .. data.FileName, "DATA") end)
	end
end

-- this is for fixing parts that are not in a group

function pac.FixSession(data)
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
		local session = {
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
			table.insert(session, v)
		end
		
		return session
	end
	
	return data
end