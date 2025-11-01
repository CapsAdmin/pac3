local L = pace.LanguageString
local PANEL = {}

PANEL.ClassName = "browser"
PANEL.Base = "DListView"

PANEL.Dir = ""
AccessorFunc(PANEL, "Dir", "Dir")

local raw_size = CreateClientConVar("pac_browser_display_raw_file_size", "0", true, false, "whether to ignore nice filesize, switching to actual numeric sorting instead of alphabetical")
cvars.AddChangeCallback("pac_browser_display_raw_file_size", function()
	if pace.SpawnlistBrowser then
		pace.SpawnlistBrowser:PopulateFromClient()
	end
end)

function PANEL:SetDir(str)
	self.Dir = str
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

function PANEL.OnRowRightClick(_self,id, self)
	local m=DermaMenu()
		m:AddOption(L"View",function()
			self:GetListView():OnClickLine(self, true)
			self:OnSelect()
		end)
		m:AddOption(L"wear on server",function()
			self:GetListView():OnClickLine(self, true)
			self:OnSelect()
			timer.Simple(0,function()
				RunConsoleCommand"pac_wear_parts"
			end)
		end)

	m:Open()
end

pace.RegisterPanel(PANEL)
