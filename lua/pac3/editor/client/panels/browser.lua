local L = pace.LanguageString
local PANEL = {}

PANEL.ClassName = "browser"
PANEL.Base = "DListView"

PANEL.Dir = ""
AccessorFunc(PANEL, "Dir", "Dir")
local current_dir = ""

local raw_size = CreateClientConVar("pac_browser_display_raw_file_size", "0", true, false, "whether to ignore nice filesize, switching to actual numeric sorting instead of alphabetical")
cvars.AddChangeCallback("pac_browser_display_raw_file_size", function()
	if pace.SpawnlistBrowser then
		pace.SpawnlistBrowser:PopulateFromClient()
	end
end)

function PANEL:SetDir(str)
	self.Dir = str
	current_dir = str
	self:PopulateFromClient()
end

function PANEL:Init()
	self:AddColumn(L"name")
	self:AddColumn(L"size")
	self:AddColumn(L"modified")
	self:PopulateFromClient()
	self:FixColumnsLayout()
end

local function OnMousePressed(self, mcode)
	if mcode == MOUSE_RIGHT then
		self:GetListView():OnRowRightClick(self:GetID(), self)
	elseif mcode == MOUSE_LEFT then
		self:GetListView():OnClickLine(self, true)
		self:OnSelect()
	end
end

local previous_folder = "pac3/"
function PANEL:AddOutfits(folder, callback)
	local files, folders = file.Find(folder.."*", "DATA")
	previous_folder = string.sub(folder, 6, #folder)

	if folder ~= "pac3/" then
		local filenode = self:AddLine("<<< " .. previous_folder,"", "")
		filenode.OnSelect = function() self:SetDir(string.GetPathFromFilename(string.sub(previous_folder, 1, #previous_folder - 1))) end
		filenode.OnMousePressed = OnMousePressed
	end

	for i, name in ipairs(files) do
		if name:find("%.txt") then
			local outfit = folder .. name
			if file.Exists(outfit, "DATA") then
				local filenode = self:AddLine(
					name:gsub("%.txt", ""),
					raw_size:GetBool() and file.Size(outfit, "DATA") or string.NiceSize(file.Size(outfit, "DATA")),
					raw_size:GetBool() and file.Time(outfit, "DATA") or os.date("%m/%d/%Y %H:%M", file.Time(outfit, "DATA"))
				)
				filenode.FileName = name
				filenode.OnSelect = callback
				filenode.OnMousePressed = OnMousePressed
			end
		end
	end

	--separator
	if #folders > 0 and #files > 0 then self:AddLine("","","") end

	for i, name in ipairs(folders) do
		local folder2 = folder..name.."/"
		if file.Exists(folder2, "DATA") then
			local filenode = self:AddLine(
				name,
				"<folder>",
				raw_size:GetBool() and file.Time(folder2, "DATA") or os.date("%m/%d/%Y %H:%M", file.Time(folder2, "DATA"))
			)
			filenode.FileName = name
			filenode.OnSelect = function() self:SetDir(string.sub(folder2, 6, #folder2)) end
			filenode.OnMousePressed = OnMousePressed
		end
	end
end

function PANEL:PopulateFromClient()
	self:Clear()

	self:AddOutfits("pac3/" .. self.Dir, function(node)
		pace.LoadParts(self.Dir .. node.FileName, true)
		pace.RefreshTree()
	end)
end

local current_file = ""
function PANEL.OnRowRightClick(_self,id, self)
	current_file = current_dir .. self.FileName
	local m=DermaMenu()
		m:AddOption(L"View",function()
			self:GetListView():OnClickLine(self, true)
			self:OnSelect()
		end)
		local peek, pnl = m:AddSubMenu("peek")
			peek:AddOption(L"peek in browser",function()
				local data,err = pace.luadata.ReadFile("pac3/" .. current_file)
				if not err then timer.Simple(0, function() pace.PeekOutfit(data, "SpawnlistBrowser") end) end
			end)
			peek:AddOption(L"peek in separate window",function()
				local data,err = pace.luadata.ReadFile("pac3/" .. current_file)
				if not err then timer.Simple(0, function() pace.PeekOutfit(data, "DFrame") end) end
			end)
		m:AddOption(L"wear on server",function()
			self:GetListView():OnClickLine(self, true)
			self:OnSelect()
			timer.Simple(0,function()
				RunConsoleCommand"pac_wear_parts"
			end)
		end)

		m:AddOption(L"copy path",function()
			SetClipboardText("pac3/" .. current_file)
		end)

	m:Open()
end

pace.RegisterPanel(PANEL)

do -- peek mode
	-- there'll be a chance of reduced outfits (where default variables are not saved to reduce file size)
	local function SafeGetKey(part, key)
		if not istable(part) then return nil end
		if not part.ClassName then return nil end
		if part[key] == nil then part[key] = pac.registered_parts[part.ClassName][key] end
		return part[key]
	end

	local function get_name(part)
		local name = part.Name or ""
		if name == "" then
			name = part.ClassName .. " (no name)"
			if (part.ClassName == "model2" or part.ClassName == "entity2") and SafeGetKey(part, "Model") ~= "" then
				name = string.GetFileFromFilename(part.Model)
			elseif part.ClassName == "event" then
				name = "event : " .. SafeGetKey(part,"Event") .. " " .. SafeGetKey(part,"Arguments")
			elseif part.ClassName == "bone3" then
				name = part.Bone or "head"
			end
		end
		return name
	end

	--these are meant to support luadata-type parts that haven't been initialized
	function pac.GetPartIcon(part, arg)
		if isstring(part) then
			part = {["ClassName"] = part, ["Model"] = arg}
		end
		part.Model = SafeGetKey(part,"Model")
		if part.ClassName == "model2" or part.ClassName == "entity2" then
			if part.Model ~= "" then
				if file.Exists("materials/spawnicons/"..string.gsub(part.Model, ".mdl", "")..".png", "GAME") then
					return "materials/spawnicons/"..string.gsub(part.Model, ".mdl", "")..".png"
				end
			end
		elseif part.ClassName == "event" then
			return part.Invert and "icon16/clock_red.png" or "icon16/clock.png"
		end
		return pac.registered_parts[part.ClassName] and pac.registered_parts[part.ClassName].Icon
	end

	function pac.GetPartName(part)
		if part.is_valid then
			return part:GetName()
		else
			return get_name(part)
		end
	end

	function pace.PeekOutfit(data, display)
		if not data then
			current_file = "[active outfit]"
			data = {}
			for key, part in pairs(pac.GetLocalParts()) do
				if not part:HasParent() and part:GetShowInEditor() then
					table.insert(data, part:ToSaveTable())
				end
			end
		end
		if not display then
			display = "DFrame"
		end

		if display == "DFrame" or display == "SpawnlistBrowser" then
			local frame
			local title = current_file
			if display == "SpawnlistBrowser" then
				frame = vgui.Create("DFrame", pace.SpawnlistBrowser_panels[1])
				frame:Dock(FILL)
				pace.SpawnlistBrowser_panels[2]:Hide()
				frame:ShowCloseButton(false)
				frame:SetDraggable(false)
				frame:DockPadding(0,15,0,0)
				local title_bg_col = Color(200,200,200)
				local black = Color(0,0,0)
				frame.PaintOver = function(self, w, h)
					surface.SetDrawColor(title_bg_col)
					surface.DrawRect(0,0,w,15)
					surface.SetTextColor(black)
					surface.SetFont("DermaDefaultBold")
					local tx, th = surface.GetTextSize(title)
					surface.SetTextPos(w/2 - tx/2,2)
					surface.DrawText(title)
				end
			else
				frame = vgui.Create("DFrame")
				frame:SetTitle(current_file)
				frame:MakePopup()
				frame:SetSize(0.4*ScrW(),0.75*ScrH())
				frame:Center()
				local x,y = frame:GetPos()
				frame:SetY(ScrH())
				frame:MoveTo(x, (y + ScrH())/2, 1, 0, 2)
				frame:MoveTo(x, y, 1, 1, 0.5)
			end
			local tree = vgui.Create("DTree", frame)
			tree:Dock(FILL)
			local close = tree:AddNode("close", "icon16/cancel.png")
				close.DoClick = function()
					frame:Close()
				end
				frame.OnClose = function()
					if display == "SpawnlistBrowser" then
						pace.SpawnlistBrowser_panels[2]:Show()
					end
				end
			local info = tree:AddNode("collected outfit-level information", "icon16/help.png")

			local missing_models = {}
			local level = 0
			local function rec_pop(node, tbl)
				for i,v in ipairs(tbl) do
					local part = v.self
					local newnode = node:AddNode(pac.GetPartName(part, part.ClassName), pac.GetPartIcon(part.ClassName, part.Model))
					newnode.DoRightClick = function()
						local menu = DermaMenu()
						menu:AddOption("Create Part", function()
							local inject_part = pac.CreatePart(part.ClassName, nil, v)
						end):SetImage("icon16/add.png")
						menu:AddOption("Create Part (at current part)", function()
							local inject_part = pac.CreatePart(part.ClassName, nil, v)
							inject_part:SetParent(pace.current_part)
						end):SetImage("icon16/add.png")
						menu:AddOption("Create (at current part) / Merge Part (if uid exists)", function()
							local uid = part.UniqueID
							local existing_part = pac.GetPartFromUniqueID(pac.Hash(LocalPlayer()),uid)
							local parent = pace.current_part
							if existing_part and existing_part:IsValid() then
								parent = existing_part:GetParent()
								existing_part:Remove()
							end
							local inject_part = pac.CreatePart(part.ClassName, nil, v)
							inject_part:SetParent(parent)
						end):SetImage("icon16/arrow_merge.png")
						menu:AddOption("Cut to clipboard", function()
							local inject_part = pac.CreatePart(part.ClassName, nil, v)
							pace.Cut(inject_part)
						end):SetImage("icon16/cut.png")
						menu:SetPos(input.GetCursorPos())
						menu:AddOption("expand (recursive)", function() newnode:ExpandRecurse(true) end):SetIcon("icon16/arrow_down.png")
						menu:AddOption("collapse (recursive)", function() newnode:ExpandRecurse(false) end):SetIcon("icon16/arrow_up.png")
						menu:MakePopup()
					end
					if part.EditorExpand then newnode:SetExpanded(true) end
					local props = {}
					for k,v in pairs(part) do
						if v == pac.registered_parts[part.ClassName][k] then continue end
						local str = tostring(v)
						if #str > 128 then str = string.sub(str,1,128) .. "..." end
						table.insert(props, k .. " = " .. str)
					end
					newnode:SetTooltip(table.concat(props, "\n"))
					if part.ClassName == "model2" then
						if not file.Exists(part.Model, "GAME") then
							if not missing_models[part.Model] then
								info:AddNode("[MISSING MODEL] " .. newnode:GetText(), pac.GetPartIcon(part.ClassName, part.Model))
								missing_models[part.Model] = missing_models[part.Model]
								newnode:SetText("[MISSING MODEL] " .. newnode:GetText())
							end
						end
					elseif part.ClassName == "group" then
						if part.ModelTracker ~= nil and part.ModelTracker ~= "" and level == 0 then
							local newnode2 = info:AddNode(pac.GetPartName(part) .. " saved using playermodel: " .. part.ModelTracker, pac.GetPartIcon("entity2", part.ModelTracker))
							if part.ClassTracker ~= nil and part.ClassTracker ~= "" then
								newnode2:AddNode("entity class : " .. part.ClassTracker, "icon16/world.png")
							end
						end
					end
					if #v.children ~= 0 then
						level = level + 1
						rec_pop(newnode,  v.children)
						level = level - 1
					end
				end
			end

			rec_pop(tree, data)
			tree:Dock(FILL)
		end

	end
end
