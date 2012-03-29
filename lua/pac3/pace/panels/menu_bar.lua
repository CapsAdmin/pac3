local PANEL = {}

PANEL.ClassName = "menu_bar"
PANEL.Base = "DPanelList"

function PANEL:Init()
	DPanelList.Init(self)

	self:AddMenu("file", function(menu)
		menu:AddOption("new", pace.Call("New"))
		menu:AddSpacer()
		menu:AddOption("open", pace.Call("Open"))
		menu:AddOption("save", pace.Call("Save"))
		menu:AddSpacer()
		menu:AddOption("exit", pace.Call("Exit"))
	end)

	self:AddMenu("edit", function(menu)
		menu:AddOption("undo", pace.Call("Undo"))
		menu:AddOption("redo", pace.Call("Redo"))
	end)

	self:EnableHorizontal(true)
end

function PANEL:AddMenu(name, callback)
	local btn = vgui.Create("DButton")
		btn:SetText(name)
		btn:SizeToContents()
		btn:SetWide(50)
		btn:SetTall(btn:GetTall() + 2)
		btn.DoClick = function()
			local menu = DermaMenu()

			callback(menu)
			menu:SetPos(btn:GetPos())
			menu:Open()
		end
	self:AddItem(btn)

end

pace.RegisterPanel(PANEL)