-- based on starfall

local L = pace.LanguageString

local function install_click(icon, path, pattern, on_menu)
	local old = icon.OnMouseReleased
	icon.OnMouseReleased = function(_, code)
		if code == MOUSE_LEFT then
			pace.model_browser:SetVisible(false)
			pace.model_browser_callback(path, "GAME")
		elseif code == MOUSE_RIGHT then
			local menu = DermaMenu()
			menu:AddOption(L"copy path", function()
				if pattern then
					path = path:match(pattern)
				end
				SetClipboardText(path)
			end)
			if on_menu then on_menu(menu) end
			menu:Open()
		end

		return old(_, code)
	end
end

local function get_unlit_mat(path)
	if path:find("%.png$") then
		return Material(path:match("materials/(.+)"))
	elseif path:find("%.vmt$") then
		local tex = Material(path:match("materials/(.+)%.vmt")):GetTexture("$basetexture")
		if tex then
			local mat = CreateMaterial(path .. "_pac_resource_browser", "UnlitGeneric")
			mat:SetTexture("$basetexture", tex)
			return mat
		end
	end

	return CreateMaterial(path .. "_pac_resource_browser", "UnlitGeneric", {["$basetexture"] = path:match("materials/(.+)%.vtf")})
end

local function create_texture_icon(path)
	local icon = vgui.Create("DButton")
	icon:SetTooltip(path)
	icon:SetSize(128,128)
	icon:SetWrap(true)
	icon:SetText("")

	install_click(icon, path, "^materials/(.+)%.vtf$")

	local mat = get_unlit_mat(path)

	icon.Paint = function(self,w,h)
		surface.SetDrawColor(255,255,255,255)
		surface.SetMaterial(mat)
		surface.DrawTexturedRect(0,0,w,h)
		return true
	end

	return icon
end

surface.CreateFont("pace_resource_browser_fixed_width", {
	font = "dejavu sans mono",
})

local function create_material_icon(path)
	local mat_path = path:match("materials/(.+)%.vmt")
	local mat = Material(mat_path)
	local shader = mat:GetShader():lower()

	local SPAWNICON = vgui.GetControlTable("SpawnIcon")
	local icon = vgui.Create("DButton")
	icon:SetTooltip(path)
	icon:SetSize(128,128)
	icon:SetWrap(true)
	icon:SetText("")
	local old = icon.Paint
	icon.Paint = function(_,w,h) old(_,w,h) surface.SetDrawColor(0,0,0,240) surface.DrawRect(0,0,w,h) end

	if shader == "vertexlitgeneric" then
		local pnl =  vgui.Create("DModelPanel", icon)
		pnl:SetMouseInputEnabled(false)
		pnl:Dock(FILL)
		pnl:SetModel("models/pac/default.mdl")
		pnl:SetLookAt( Vector( 0, 0, 0 ) )
		pnl:SetFOV(1)
		pnl:SetCamPos(Vector(1,1,1) * 600)
		pnl.PreDrawModel = function() render.ModelMaterialOverride(mat) end
		pnl.PostDrawModel = function() render.ModelMaterialOverride() end
	elseif shader == "lightmappedgeneric" or shader == "spritecard" then
		local pnl = vgui.Create("DPanel", icon)
		pnl:SetMouseInputEnabled(false)
		pnl:Dock(FILL)

		local mat = get_unlit_mat(path)

		pnl.Paint = function(self,w,h)
			surface.SetDrawColor(255,255,255,255)
			surface.SetMaterial(mat)
			surface.DrawTexturedRect(0,0,w,h)
		end

	else
		local pnl = vgui.Create("DImage", icon)
		pnl:SetMouseInputEnabled(false)
		pnl:Dock(FILL)
		pnl:SetImage(mat_path)
	end


	install_click(icon, path, "^materials/(.+)%.vmt$", function(menu)
		local function create_text_view(str)
			local frame = vgui.Create("DFrame")
			frame:SetTitle(path)
			frame:SetSize(500, 500)
			frame:Center()
			frame:SetSizable(true)

			local scroll = vgui.Create("DScrollPanel", frame)
			scroll:Dock(FILL)
			scroll:DockMargin( 0, 5, 5, 5 )

			local text = vgui.Create("DTextEntry", scroll)
			text:SetMultiline(true)
			text:SetFont("pace_resource_browser_fixed_width")

			text:SetText(str)

			surface.SetFont(text:GetFont())
			local _,h = surface.GetTextSize(str)
			text:SetTall(h+50)
			text:SetWide(frame:GetWide())

			frame:MakePopup()
		end

		menu:AddOption("view .vmt", function()
			create_text_view(file.Read(path, "GAME"):gsub("\t", "    "))
		end)

		menu:AddOption("view keyvalues", function()
			local tbl = {}
			for k,v in pairs(Material(mat_path):GetKeyValues()) do
				table.insert(tbl, {k = k, v = v})
			end
			table.sort(tbl, function(a,b) return a.k < b.k end)

			local str = ""
			for _, v in ipairs(tbl) do
				str = str .. v.k:sub(2) .. ":\n" .. tostring(v.v) .. "\n\n"
			end

			create_text_view(str)
		end)
	end)

	return icon
end

local function create_model_icon(path)
	local icon = vgui.Create("SpawnIcon")

	icon:SetSize(64, 64)
	icon:InvalidateLayout(true)
	icon:SetModel(path)
	icon:SetTooltip(path)

	install_click(icon, path)

	icon:InvalidateLayout(true)

	return icon
end

do
	local PANEL = {}

	DEFINE_BASECLASS( "DScrollPanel" )

	function PANEL:Init()
		self:SetPaintBackground( false )

		self.IconList = vgui.Create( "DTileLayout", self:GetCanvas())
		self.IconList:SetBaseSize( 64 )
		self.IconList:SetSelectionCanvas( true )
		self.IconList:Dock( TOP )
	end

	function PANEL:Add(pnl)
		self.IconList:Add(pnl)
		self:Layout()
	end

	function PANEL:Layout()
		self.IconList:Layout()
		self:InvalidateLayout()
	end

	function PANEL:PerformLayout()
		BaseClass.PerformLayout( self )
		self.IconList:SetMinHeight( self:GetTall() - 16 )
	end

	function PANEL:Clear()
		self.IconList:Clear( true )
	end

	vgui.Register( "pac_ResourceBrowser_ContentContainer", PANEL, "DScrollPanel" )
end

function pace.ResourceBrowser(callback, browse_types_str)
	browse_types_str = browse_types_str or "models;materials;textures;sound"
	local browse_types = browse_types_str:Split(";")

	local texture_view = false
	local material_view = table.HasValue(browse_types, "materials")

	if table.RemoveByValue(browse_types, "textures") then
		texture_view = true
		if not material_view then
			table.insert(browse_types, "materials")
		end
	end

	if pace.model_browser_browse_types ~= browse_types_str and pace.model_browser and pace.model_browser:IsValid() then
		pace.model_browser:Remove()
	end

	local addModel

	pace.model_browser_callback = callback or print
	pace.model_browser_browse_types = browse_types_str

	if pace.model_browser and pace.model_browser:IsValid() then
		pace.model_browser:SetVisible(true)
		pace.model_browser:MakePopup()
		return
	end

	local frame = vgui.Create("DFrame")
	frame:SetTitle(L"resource browser" .. " - " .. (browse_types_str:gsub(";", " ")))
	frame:SetSize(ScrW()/1.5, ScrH()/1.5)
	frame:Center()
	frame:SetDeleteOnClose(false)
	frame:SetSizable(true)

	function frame:OnClose()
		self:SetVisible(false)
	end

	--[[

	local menu_bar = vgui.Create("DMenuBar", frame)
	menu_bar:Dock(TOP)
	menu_bar:AddMenu("file")
	local view_menu = menu_bar:AddMenu("view")
	view_menu:SetDeleteSelf(false)

	local tool_bar = vgui.Create("DPanel", frame)
	tool_bar:Dock(TOP)

	local browse_back = vgui.Create("DImageButton", tool_bar)
	browse_back:SetImage("icon16/arrow_left.png")
	browse_back:SizeToContents()
	browse_back.DoClick = function()

	end
]]
	local left_panel = vgui.Create("DPanel", frame)
	left_panel:Dock(LEFT)
	left_panel:SetSize(190, 10)
	left_panel:DockMargin(0, 0, 4, 0)
	left_panel.Paint = function () end

	local divider

	local tree = vgui.Create("DTree", left_panel)
	tree:Dock(FILL)
	tree:DockMargin(0, 0, 0, 0)
	tree:SetBackgroundColor(Color(240, 240, 240))
	tree.OnNodeSelected = function (self, node)
		if not IsValid(node.propPanel) then return end

		if IsValid(frame.PropPanel.selected) then
			frame.PropPanel.selected:SetVisible(false)
			frame.PropPanel.selected = nil
		end

		frame.PropPanel.selected = node.propPanel

		frame.PropPanel.selected:Dock(FILL)
		frame.PropPanel.selected:SetVisible(true)
		frame.PropPanel:InvalidateParent()

		divider:SetRight(frame.PropPanel.selected)
	end

	local root_node = tree:AddNode("content", "icon16/folder_database.png")
	root_node:SetExpanded(true)

	frame.PropPanel = vgui.Create("DPanel", frame)
	frame.PropPanel:Dock(FILL)

	function frame.PropPanel:Paint (w, h)
		draw.RoundedBox(0, 0, 0, w, h, Color(240, 240, 240))
	end

	divider = vgui.Create("DHorizontalDivider", frame)
	divider:Dock(FILL)
	divider:SetLeftWidth(175)
	divider:SetLeftMin(175)
	divider:SetRightMin(450)

	divider:SetLeft(left_panel)
	divider:SetRight(frame.PropPanel)


	local sound_list = vgui.Create("DListView", frame.PropPanel)
	sound_list:AddColumn(L"path")
	sound_list:AddColumn(L"byte size")
	sound_list:AddColumn(L"duration")
	sound_list:Dock(FILL)
	sound_list:SetMultiSelect(false)
	sound_list:SetVisible(false)


	if texture_view or material_view then
		local node = root_node:AddNode("materials", "icon16/folder_database.png")

		local viewPanel = vgui.Create("pac_ResourceBrowser_ContentContainer", frame.PropPanel)
		viewPanel:DockMargin(5, 0, 0, 0)
		viewPanel:SetVisible(false)

		for list_name, materials in pairs(pace.Materials) do
			local list = node:AddNode(list_name)
			list.propPanel = viewPanel

			list.OnNodeSelected = function()
				if viewPanel and viewPanel.currentNode and viewPanel.currentNode == list then return end

				viewPanel:Clear(true)
				viewPanel.currentNode = list

				if material_view then
					for _, material_name in ipairs(materials) do
						local path = "materials/" .. material_name .. ".vmt"
						local icon = create_material_icon(path)

						if icon then
							viewPanel:Add(icon)
						end
					end
				end

				if texture_view then
					local done = {}
					local textures = {}

					for _, material_name in ipairs(materials) do
						local mat = Material(material_name)
						for k, v in pairs(mat:GetKeyValues()) do
							if type(v) == "ITexture" then
								local name = v:GetName()
								if not done[name] then
									done[name] = true
									table.insert(textures, "materials/" .. name .. ".vtf")
								end
							end
						end
					end

					for _, path in ipairs(textures) do
						viewPanel:Add(create_texture_icon(path))
					end
				end

				tree:OnNodeSelected(list)
				viewPanel.currentNode = list
			end

			if texture_view or material_view and #browse_types == 1 then
				node:SetExpanded(true)
				list:SetExpanded(true)
				tree:SetSelectedItem(list)
			end
		end
	end

	if table.HasValue(browse_types, "models") then

		local spawnlists = root_node:AddFolder("Spawnlists")
		spawnlists.info = {}
		spawnlists.info.id = 0

		local function hasGame (name)
			for k, v in pairs(engine.GetGames()) do
				if v.folder == name and v.mounted then
					return true
				end
			end
			return false
		end

		local function fillNavBar(propTable, parentNode)
			for k, v in SortedPairs(propTable) do
				if v.parentid == parentNode.info.id and (v.needsapp ~= "" and hasGame(v.needsapp) or v.needsapp == "") then
					local node = parentNode:AddNode(v.name, v.icon)
					node:SetExpanded(true)
					node.info = v

					node.propPanel = vgui.Create("pac_ResourceBrowser_ContentContainer", frame.PropPanel)
					node.propPanel:DockMargin(5, 0, 0, 0)
					node.propPanel:SetVisible(false)

					for i, object in SortedPairs(node.info.contents) do
						if object.type == "model" then
							node.propPanel:Add(create_model_icon(object.model))

							if not frame.selected_construction_props and #browse_types == 1 and v.name == "Construction Props" then
								node:SetExpanded(true)
								parentNode:SetExpanded(true)
								tree:SetSelectedItem(node)
								frame.selected_construction_props = true
							end
						elseif object.type == "header" then
							if not object.text or type(object.text) ~= "string" then return end

							local label = vgui.Create("ContentHeader", node.propPanel)
							label:SetText(object.text)

							node.propPanel:Add(label)
						end
					end

					fillNavBar(propTable, node)
				end
			end
		end

		fillNavBar(spawnmenu.GetPropTable(), spawnlists)
	end

	do -- mounted
		local function addBrowseContent(viewPanel, node, name, icon, path, pathid)
			local function on_select(self, node)
				if viewPanel and viewPanel.currentNode and viewPanel.currentNode == node then return end

				sound_list:Clear()
				viewPanel:Clear(true)
				viewPanel.currentNode = node

				local searchString = node:GetFolder()

				if searchString == "" then
					searchString = "*"
				else
					searchString = searchString .. "/*"
				end

				local files, folders = file.Find(searchString, node:GetPathID())

				if files then
					--[[
					for _, dir in pairs(folders) do

						local SPAWNICON = vgui.GetControlTable("SpawnIcon")
						local icon = vgui.Create("DButton", viewPanel)
						icon:SetSize(64,64)
						icon:SetText(dir)
						icon:SetWrap(true)

						icon.Paint = SPAWNICON.Paint
						icon.PaintOver = SPAWNICON.PaintOver

						icon.DoClick = function()
							for _, child in pairs(node.ChildNodes:GetChildren()) do
								if child:GetFolder() == ((node:GetFolder() == "" and dir) or (node:GetFolder() .. "/" .. dir)) then
									prev_node = tree.Tree:GetSelectedItem()
									tree.Tree:SetSelectedItem(child)
									node:SetExpanded(true)
									break
								end
							end
						end

						viewPanel:Add(icon)
					end
					]]
					if self.dir == "models" then
						for k, v in pairs(files) do
							local path = node:GetFolder() ..  "/" .. v

							if not IsUselessModel(path) then
								viewPanel:Add(create_model_icon(path))
							end
						end
					elseif self.dir == "materials" then
						for k, v in pairs(files) do
							local path = node:GetFolder() ..  "/" .. v

							if v:find("%.vmt$") then
								if material_view then
									local icon = create_material_icon(path)

									if icon then
										viewPanel:Add(icon)
									end
								end
							elseif texture_view then
								viewPanel:Add(create_texture_icon(path))
							end

						end
					elseif self.dir == "sound" then
						for k, v in pairs(files) do
							local path = node:GetFolder() ..  "/" .. v

							local sound_path = path:match("sound/(.+)")
							local duration = SoundDuration(sound_path)

							local line = sound_list:AddLine(path, file.Size(path, pathid), duration)

							local play = vgui.Create("DImageButton", line)
							play:SetImage("icon16/control_play.png")
							play:SizeToContents()
							play:Dock(LEFT)

							function play:Start()
								for _, v in pairs(sound_list:GetLines()) do
									v.play:Stop()
								end

								self:SetImage("icon16/control_stop.png")

								local snd = CreateSound(LocalPlayer(), sound_path)
								snd:Play()
								pace.resource_browser_snd = snd

								timer.Create("pac_resource_browser_play", duration, 1, function()
									if self:IsValid() then
										self:Stop()
									end
								end)
							end

							function play:Stop()
								self:SetImage("icon16/control_play.png")

								if pace.resource_browser_snd then
									pace.resource_browser_snd:Stop()
									timer.Remove("pac_resource_browser_play")
								end
							end

							line.OnMousePressed = function(_, code)
								if code == MOUSE_RIGHT then
									play:Start()
									sound_list:ClearSelection()
									sound_list:SelectItem(line)
								else
									pace.model_browser:SetVisible(false)
									pace.model_browser_callback(path, pathid)
								end
							end

							local label = line.Columns[1]
							label:SetTextInset(play:GetWide() + 5, 0)

							play.DoClick = function()
								if timer.Exists("pac_resource_browser_play") and sound_list:GetLines()[sound_list:GetSelectedLine()] == line then
									play:Stop()
									return
								end
								sound_list:ClearSelection()
								sound_list:SelectItem(line)

								play:Start()
							end

							line.play = play
						end
					end

					if self.dir == "sound" then
						node.propPanel = sound_list
					else
						node.propPanel = viewPanel
					end
					tree:OnNodeSelected(node)
					viewPanel.currentNode = node
				end
			end

			if #browse_types == 1 then
				node = node:AddFolder( name, path .. browse_types[1], pathid, false )
				node:SetIcon( icon )
				node.dir = browse_types[1]
				node.OnNodeSelected = on_select
			else
				local _, dirs = file.Find("*", pathid)
				node = node:AddNode(name, icon)
				node.OnNodeSelected = on_select
				node:SetFolder("")
				node:SetPathID(pathid)
				node.viewPanel = viewPanel

				for _, dir in ipairs(dirs) do
					if table.HasValue(browse_types, dir:lower()) then
						local node = node:AddFolder(dir, path .. dir, pathid, false)
						node.dir = dir
						node.OnNodeSelected = on_select
					end
				end
			end
		end

		local viewPanel = vgui.Create("pac_ResourceBrowser_ContentContainer", frame.PropPanel)
		viewPanel:DockMargin(5, 0, 0, 0)
		viewPanel:SetVisible(false)

		do
			local special = {
				{
					title = "All",
					folder = "GAME",
					icon = "games/16/all.png",
				},
				{
					title = "Downloaded",
					folder = "DOWNLOAD",
					icon = "materials/icon16/server_go.png",
				},
				{
					title = "Workshop",
					folder = "WORKSHOP",
					icon = "materials/icon16/plugin.png",
				},
				{
					title = "Thirdparty",
					folder = "THIRDPARTY",
					icon = "materials/icon16/folder_brick.png",
				},
				{
					title = "Mod",
					folder = "MOD",
					icon = "materials/icon16/folder_brick.png",
				},
			}

			for _, info in ipairs(special) do
				addBrowseContent(viewPanel, root_node, info.title, info.icon, "", info.folder)
			end
		end

		do
			local games = engine.GetGames()
			table.insert(games, {
				title = "Garry's Mod",
				folder = "garrysmod",
				mounted = true
			})

			for _, game in SortedPairsByMemberValue(games, "title") do
				if game.mounted then
					addBrowseContent(viewPanel, root_node, game.title, "games/16/" .. (game.icon or game.folder) .. ".png", "", game.folder)
				end
			end
		end

		for _, addon in SortedPairsByMemberValue(engine.GetAddons(), "title") do
			if addon.downloaded and addon.mounted then
				addBrowseContent(viewPanel, root_node, addon.title, "icon16/bricks.png", "", addon.title)
			end
		end
	end

	if table.HasValue(browse_types, "models") then
		local view = vgui.Create("pac_ResourceBrowser_ContentContainer", frame.PropPanel)
		view:DockMargin(5, 0, 0, 0)
		view:SetVisible(false)

		local search = vgui.Create("DTextEntry", left_panel)
		search:Dock(TOP)
		search:SetValue("Search...")
		search:SetTooltip("Press enter to search")
		search.propPanel = view

		search._OnGetFocus = search.OnGetFocus
		function search:OnGetFocus ()
			if self:GetValue() == "Search..." then
				self:SetValue("")
			end
			search:_OnGetFocus()
		end

		search._OnLoseFocus = search.OnLoseFocus
		function search:OnLoseFocus ()
			if self:GetValue() == "" then
				self:SetText("Search...")
			end
			search:_OnLoseFocus()
		end

		function search:updateHeader()
			self.header:SetText(search.results .. " Results for \"" .. self.search .. "\"")
		end

		local searchTime = nil

		function search:StartSearch(time, folder, extension, path)
			if searchTime and time ~= searchTime then return end
			if self.results and self.results >= 256 then return end
			self.load = self.load + 1
			local files, folders = file.Find(folder .. "/*", path)

			for k, v in pairs(files) do
				local file = folder .. v
				if v:EndsWith(extension) and file:find(self.search:PatternSafe()) and not IsUselessModel(file) then
					self.propPanel:Add(create_model_icon(file))
					self.results = self.results + 1
					self:updateHeader()
				end
				if self.results >= 256 then break end
			end

			for k, v in pairs(folders) do
				timer.Simple(k * 0.02, function()
					if searchTime and time ~= searchTime then return end
					if self.results >= 256 then return end
					self:StartSearch(time, folder .. v .. "/", extension, path)
				end)
			end
			timer.Simple(1, function ()
				if searchTime and time ~= searchTime then return end
				self.load = self.load - 1
			end)
		end

		function search:OnEnter ()
			if self:GetValue() == "" then return end

			self.propPanel:Clear()

			self.results = 0
			self.load = 1
			self.search = self:GetText()

			self.header = vgui.Create("DLabel", self.propPanel)
			self:updateHeader()
			self.propPanel:Add(self.header)

			searchTime = CurTime()
			self:StartSearch(searchTime, "models/", ".mdl", "GAME")
			self.load = self.load - 1

			tree:OnNodeSelected(self)
		end
	end

	frame:MakePopup()

	pace.model_browser = frame
end

if pace.model_browser and pace.model_browser:IsValid() then pace.model_browser:Remove() end

concommand.Add("pac_resource_browser", function()
	pace.ResourceBrowser(print)
end)