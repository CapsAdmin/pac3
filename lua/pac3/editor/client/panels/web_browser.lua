local PANEL = {}

PANEL.Base = "DFrame"
PANEL.ClassName = "web_browser"

function PANEL:Init()
	self:SetTitle("Web Browser")
	self:SetDeleteOnClose(false)
	self:ShowCloseButton(true)
	self:SetDraggable(true)
	self:SetSizable(true)

	local top = vgui.Create("EditablePanel", self)
		top:Dock(TOP)
		top:SetTall(24)
	self.top = top

	local btn = vgui.Create("DButton", top)
		btn:SetText("Back")
		btn:SizeToContents()
		btn:SetWide(btn:GetWide()+8)
		btn:Dock(LEFT)
		btn.DoClick = function()
			self.browser:RunJavascript("history.back();")
		end

	local btn = vgui.Create("DButton", top)
		btn:SetText("Forward")
		btn:SizeToContents()
		btn:SetWide(btn:GetWide()+8)
		btn:Dock(LEFT)
		btn.DoClick = function()
			self.browser:RunJavascript("history.forward();")
		end

	local btn = vgui.Create("DButton", top)
		btn:SetText("Refresh")
		btn:SizeToContents()
		btn:SetWide(btn:GetWide() + 8)
		btn:Dock(LEFT)

		btn.DoClick = function()
			self.browser:RunJavascript("location.reload(true);")
		end

		btn.Paint = function(btn,w,h)
			DButton.Paint(btn,w,h)

			if self.loaded then
				if self.browser:IsLoading() then
					self.loaded = false
				end

				surface.SetDrawColor(100, 240, 50, 200)
				surface.DrawRect(1, 1, w-2, h-2)
			end

			if self.browser:IsLoading() then
				surface.SetDrawColor(240 + math.sin(RealTime()*10)*15, 100, 50, 200)
				surface.DrawRect(1, 1, w-2, h-2)
			end
		end

	local entry = vgui.Create("DTextEntry", top)
		self.entry = entry
		entry:Dock(FILL)
		entry:SetTall( 24)

		entry.OnEnter = function(entry)
			local val = entry:GetText()
			local js,txt = val:match("javascript:(.+)")

			if js and txt then
				self.browser:QueueJavascript(txt)
				return
			end

			self:OpenURL(val)
		end

	local browser = vgui.Create("DHTML", self)
		self.browser = browser
		browser:Dock(FILL)
		browser.Paint = function() end
		browser.OpeningURL = pac.Message
		browser.FinishedURL = pac.Message
		browser:AddFunction("gmod", "LoadedURL", function(url, title)
			self:LoadedURL(url,title)
		end)
		browser:AddFunction("gmod", "dbg", function(...)
			pac.Message('[Browser] ', ...)
		end)
		browser:AddFunction("gmod", "status", function(txt)
			self:StatusChanged(txt)
		end)
		browser.ActionSignal = function(...)
			pac.Message('[BrowserACT] ', ...)
		end

		browser.OnKeyCodePressed = function(browser,code)
			if code == 96 then
				self.browser:RunJavascript[[location.reload(true);]]
				return
			end
		end

	local status = vgui.Create("DLabel", self)
		self.status = status
		status:SetText""
		status:Dock(BOTTOM)
end

function PANEL:StatusChanged(txt)
	if self.statustxt ~= txt then
		self.statustxt = txt
		self.status:SetText(txt or "")
	end
end

function PANEL:LoadedURL(url,title)
	if self.entry:HasFocus() then return end
	self.entry:SetText(url)
	self.loaded = true
	self:SetTitle(title and title ~= "" and title or "Web browser")
end

function PANEL:OpenURL(url)
	self.browser:OpenURL(url)
	self.entry:SetText(url)
end

function PANEL:Think(w,h)
	self.BaseClass.Think(self,w,h)
	if input.IsKeyDown(KEY_ESCAPE) then
		self:Close()
	end

	if not self.wasloading and self.browser:IsLoading() then
		self.wasloading = true
	end
	if self.wasloading and not self.browser:IsLoading() then
		self.wasloading = false
		self.browser:QueueJavascript[[gmod.LoadedURL(document.location.href,document.title); gmod.status(""); ]]
		self.browser:QueueJavascript[[function alert(str) { console.log("Alert: "+str); }]]
		self.browser:QueueJavascript[[if (!document.body.style.background) { document.body.style.background = 'white'; }; void 0;]]
		self.browser:QueueJavascript[[
			function getLink() {
				gmod.status(this.href || "-");
			}
			function clickLink() {
				if (this.href) {
					gmod.LoadedURL(this.href,"Loading...");
				}
				gmod.status("Loading...");
			}
			var links = document.getElementsByTagName("a");
			for (i = 0; i < links.length; i++) {
				links[i].addEventListener('mouseover',getLink,false)
				links[i].addEventListener('click',clickLink,false)
			}

		]]
	end

end

function PANEL:Show()
	if not self:IsVisible() then
		self:SetVisible(true)
		self:MakePopup()
		self:SetKeyboardInputEnabled(true)
		self:SetMouseInputEnabled(true)
	end

	if ValidPanel(self.browser) then
		self.browser:RequestFocus()
	end
end

function PANEL:Close()
	self:SetVisible(false)
end

pace.wiki_panel = NULL

function pace.ShowWiki(url)
	if pace.wiki_panel:IsValid() then
		pace.wiki_panel:Remove()
	end

	local pnl = pace.CreatePanel("web_browser")
	pnl:OpenURL(url or pace.WikiURL)
	pnl:SetSize(ScrW()*0.9, ScrH()*0.8)
	pnl:Center()
	pnl:MakePopup()
	pace.wiki_panel = pnl
end

pace.RegisterPanel(PANEL)