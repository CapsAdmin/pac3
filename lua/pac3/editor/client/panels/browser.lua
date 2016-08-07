local L = pace.LanguageString
local PANEL = {}

PANEL.ClassName = "browser"
PANEL.Base = "DListView"

PANEL.Dir = ""
AccessorFunc(PANEL, "Dir", "Dir")

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

function PANEL:AddOutfits(folder, callback)
	for i, name in pairs(file.Find(folder.."*", "DATA")) do
		if name:find("%.txt") then
			local outfit = folder .. name
			if file.Exists(outfit, "DATA") then
				local filenode = self:AddLine(
					name:gsub("%.txt", ""),
					string.NiceSize(file.Size(outfit, "DATA")),
					os.date("%m/%d/%Y %H:%M", file.Time(outfit, "DATA"))
				)
				filenode.FileName = name
				filenode.OnSelect = callback
				filenode.OnMousePressed = OnMousePressed
			end
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