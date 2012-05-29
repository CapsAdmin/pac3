local PANEL = {}

PANEL.ClassName = "new"
PANEL.Base = "DPanelList"

PANEL.Buttons = {}

function PANEL:Init()
	self:Dock(FILL)

	self:EnableVerticalScrollbar(true)
	self:EnableHorizontal(true)
	self:SetSpacing(2)
	self:SetPadding(2)

	local btn = vgui.Create("DButton")
	btn:SetImage(pace.PartIcons["part"])
	btn:SetText("part")
	btn:SetWide(self:GetWide())
	btn.DoClick = function()
		pace.Call("CreatePart")
	end
	PANEL.Buttons["part"] = btn
	
	self:AddItem(btn)

	for class_name in pairs(pac.GetRegisteredParts()) do
		if class_name ~= "base" then
			local btn = vgui.Create("DButton")
			btn:SetImage(pace.PartIcons[class_name])
			btn:SetText(class_name)
			btn.DoClick = function()
				pace.Call("CreatePart", class_name)
			end
			PANEL.Buttons[class_name] = btn
			
			self:AddItem(btn)
		end
	end

	self:PerformLayout()
end

function PANEL:PerformLayout()
	for name, btn in pairs(self.Buttons) do
		if name == "part" then
			btn:SetWide(self:GetWide() - self:GetSpacing() * 2)
		else
			btn:SetWide((self:GetWide() / 2) - (self:GetSpacing() * 2) + 1 )
		end
	end
	DPanelList.PerformLayout(self)
end

pace.RegisterPanel(PANEL)