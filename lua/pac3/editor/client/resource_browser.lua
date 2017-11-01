-- based on starfall

local L = pace.LanguageString

local function install_click(icon, path, pattern, on_menu)
	local old = icon.OnMouseReleased
	icon.OnMouseReleased = function(_, code)
		if code == MOUSE_LEFT then
			if pace.model_browser_callback(path, "GAME") ~= false then
				pace.model_browser:SetVisible(false)
			end
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

local next_generate_icon = 0

local function create_texture_icon(path)
	local icon = vgui.Create("DButton")
	icon:SetTooltip(path)
	icon:SetSize(128,128)
	icon:SetWrap(true)
	icon:SetText("")

	install_click(icon, path, "^materials/(.+)%.vtf$")

	icon.Paint = function(self,w,h)
		if not self.ready_to_draw then return end
		if not self.setup_material then
			if next_generate_icon < RealTime() then
				self.mat = get_unlit_mat(path)
				self.setup_material = true
				next_generate_icon = RealTime() + 0.001
			end
		end

		if self.mat then
			surface.SetDrawColor(255,255,255,255)
			surface.SetMaterial(self.mat)
			surface.DrawTexturedRect(0,0,w,h)
		end
		return true
	end

	return icon
end

surface.CreateFont("pace_resource_browser_fixed_width", {
	font = "dejavu sans mono",
})

local function create_material_icon(path)
	local icon = vgui.Create("DButton")
	icon:SetTooltip(path)
	icon:SetSize(128,128)
	icon:SetWrap(true)
	icon:SetText("")
	local old = icon.Paint
	icon.Paint = function(self,w,h)
		if not self.ready_to_draw then return end
		if not self.setup_material then
			if next_generate_icon < RealTime() then
				self:SetupMaterial()
				self.setup_material = true
				next_generate_icon = RealTime() + 0.001
			end
		end
		old(self,w,h)
		surface.SetDrawColor(0,0,0,240)
		surface.DrawRect(0,0,w,h)
	end

	function icon:SetupMaterial()
		local mat_path = path:match("materials/(.+)%.vmt")
		local mat = Material(mat_path)
		local shader = mat:GetShader():lower()

		if shader == "vertexlitgeneric" then
			local pnl = vgui.Create("DModelPanel", icon)
			pnl:SetMouseInputEnabled(false)
			pnl:Dock(FILL)
			pnl:SetLookAt( Vector( 0, 0, 0 ) )
			pnl:SetFOV(1)

			local old = icon.OnCursorEntered
			function icon:OnCursorEntered(...)
				do return end
				pnl:SetModel("models/pac/default.mdl")
				pnl:SetCamPos(Vector(1,1,1) * 600)
				pnl.mouseover = true

				pnl.Entity:DisableMatrix("RenderMultiply")

				old(self, ...)
			end

			local function setup()
				pnl:SetModel("models/hunter/plates/plate1x1.mdl")
				pnl:SetCamPos(Vector(1,0,1) * 2100)
				pnl.mouseover = false

				local m = Matrix()
				m:Scale(Vector(1.375,1,0.01))
				pnl.Entity:EnableMatrix("RenderMultiply", m)
			end

			local old = icon.OnCursorExited
			function icon:OnCursorExited(...)
				setup()

				old(self, ...)
			end

			setup()

			function pnl:Think()

				local x, y = self:ScreenToLocal(gui.MouseX(), gui.MouseY())
				x = x / self:GetWide()
				y = y / self:GetTall()

				x = x * 50
				y = y * 50

				x = x - 25
				y = y - 55

				self.light_pos = Vector(y, x, 30)
			end

			function pnl:Paint( w, h )
				local x, y = self:LocalToScreen( 0, 0 )

				local ang = self.aLookAngle
				if ( !ang ) then
					ang = ( self.vLookatPos - self.vCamPos ):Angle()
				end

				if self.mouseover then
					self.Entity:SetAngles( Angle( 0, RealTime() * 10 % 360, 0 ) )
				end

				cam.Start3D( self.vCamPos, ang, self.fFOV, x, y, w, h, 5, self.FarZ )

				render.SuppressEngineLighting( true )


				render.SetColorModulation( 1, 1, 1 )
				render.SetBlend(1)

				render.SetLocalModelLights({{
					color = Vector(1,1,1),
					pos = self.Entity:GetPos() + self.light_pos,
				}})


				self:DrawModel()

				render.SuppressEngineLighting( false )
				cam.End3D()
			end

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

local function update_title(info)
	if info then
		info = " - " .. info
		pace.model_browser:SetTitle(pace.model_browser.title .. info)
	else
		pace.model_browser:SetTitle(pace.model_browser.title)
	end
end

do
	local PANEL = {}

	local BaseClass = baseclass.Get( "DScrollPanel" )

	function PANEL:Init()
		self:SetPaintBackground( false )

		self.IconList = vgui.Create( "DTileLayout", self:GetCanvas())
		self.IconList:SetBaseSize( 64 )
		self.IconList:SetSelectionCanvas( true )
		self.IconList:Dock( TOP )
do return end
		local old = self.IconList.PerformLayout
		self.IconList.PerformLayout = function(self)
			timer.Create("icon_layout", 0.1, 1, function()
				if self:IsValid() then
					old(self)
					for i, v in ipairs(self:GetChildren()) do
						v.ready_to_draw = true
					end
				end
			end)
		end
	end

	function PANEL:Add(pnl)
		pnl.ready_to_draw = true
		self.IconList:Add(pnl)
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

local show_sound_duration = CreateClientConVar("pac_resource_browser_sound_duration", "0", true)

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
	frame.title = L"resource browser" .. " - " .. (browse_types_str:gsub(";", " "))
	frame:SetSize(ScrW()/1.5, ScrH()/1.5)
	frame:Center()
	frame:SetDeleteOnClose(false)
	frame:SetSizable(true)
	pace.model_browser = frame
	update_title()

	function frame:OnClose()
		self:SetVisible(false)
	end

	local menu_bar = vgui.Create("DMenuBar", frame)
	menu_bar:Dock(TOP)
	local file_menu = menu_bar:AddMenu(L"file")
	file_menu:AddOption(L"clear search cache", function()
		Derma_Query(
			L"Are you sure you want to clear? A good time to clear is when there is a big TF2 update or you've decided to permanently unmount some games to avoid them showing up in the search results.",
			L"clear search cache",

			L"clear", function()
				file.Delete("pac3_cache/pac_resource_browser_index.txt")
				pac.resource_browser_cache = {}
			end,

			L"cancel", function()

			end
		)
	end):SetImage(pace.MiscIcons.clear)

	local view_menu = menu_bar:AddMenu(L"view")
	view_menu:SetDeleteSelf(false)
	view_menu:AddCVar(L"show sound duration (slower search)", "pac_resource_browser_sound_duration", "1", "0")


--[[
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
		frame.dir = node.dir

		frame.PropPanel.selected:Dock(FILL)
		frame.PropPanel.selected:SetVisible(true)
		frame.PropPanel:InvalidateParent()

		divider:SetRight(frame.PropPanel.selected)

		if node.dir then
			update_title("browsing " .. node.dir .. "/*")
		else
			update_title()
		end
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

	function sound_list:AddSound(path, pathid)
		local sound_path = path:match("sound/(.+)")

		local duration = show_sound_duration:GetBool() and SoundDuration(sound_path) or -1

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

			timer.Create("pac_resource_browser_play", duration or SoundDuration(sound_path), 1, function()
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
				if pace.model_browser_callback(path, pathid) ~= false then
					pace.model_browser:SetVisible(false)
				end
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


	if texture_view or material_view then
		local node = root_node:AddNode("materials", "icon16/folder_database.png")
		node.dir = "materials"

		local viewPanel = vgui.Create("pac_ResourceBrowser_ContentContainer", frame.PropPanel)
		viewPanel:DockMargin(5, 0, 0, 0)
		viewPanel:SetVisible(false)

		for list_name, materials in pairs(pace.Materials) do
			local list = node:AddNode(list_name)
			list.dir = "materials"
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
		root_node.dir = "models"
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
					node.dir = "models"

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

				node.dir = self.dir
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
							sound_list:AddSound(path, pathid)
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

	local model_view = vgui.Create("pac_ResourceBrowser_ContentContainer", frame.PropPanel)
	model_view:DockMargin(5, 0, 0, 0)
	model_view:SetVisible(false)

	local search = vgui.Create("DTextEntry", left_panel)
	search:Dock(TOP)
	search:SetTooltip("Press enter to search")
	search.propPanel = model_view
	search.model_view = model_view
	search.delay_functions = {}

	file_menu:AddOption(L"build search cache", function()
		search:StartSearch("", "models/", {}, "GAME", function(path, pathid) end)
		search:StartSearch("", "sound/", {}, "GAME", function(path, pathid) end)
		search:StartSearch("", "materials/", {}, "GAME", function(path, pathid) end)
	end)

	local cancel = vgui.Create("DImageButton", search)
	cancel:SetImage(pace.MiscIcons.clear)
	cancel:SetSize(16, 16)
	cancel.DoClick = function() search:Cancel() end
	cancel:SetVisible(false)
	cancel:PerformLayout()

	do
		local old = search.OnGetFocus
		function search:OnGetFocus ()
			if self:GetValue() == self.default_text then
				self:SetValue("")
			end
			old(self)
		end
	end

	do
		local old = search.OnLoseFocus
		function search:OnLoseFocus ()
			if self:GetValue() == "" then
				self:SetValue(self.default_text)
			end
			old(self)
		end
	end

	if file.Exists("pac3_cache/pac_resource_browser_index.txt", "DATA") then
		pac.resource_browser_cache = util.JSONToTable(file.Read("pac3_cache/pac_resource_browser_index.txt", "DATA")) or {}
	else
		pac.resource_browser_cache = {}
	end

	local function find(path, pathid)
		local key = path .. pathid

		if pac.resource_browser_cache[key] then
			return unpack(pac.resource_browser_cache[key])
		end

		local files, folders = file.Find(path, pathid)

		pac.resource_browser_cache[key] = {files, folders}

		return files, folders
	end

	function search:PerformLayout()
		cancel:SetPos(self:GetWide() - 16 - 2, 2)
	end

	function search:StartSearch(search_text, folder, extensions, pathid, cb)

		cancel:SetVisible(true)
		cancel:PerformLayout()

		local files, folders = find(folder .. "*", pathid)

		self.searched = true

		if files then
			update_title(table.Count(self.delay_functions) .. " directories left - " .. folder .. "*")

			for k, v in ipairs(files) do
				local file = folder .. v
				for _, ext in ipairs(extensions) do
					if v:EndsWith(ext) and file:find(search_text, nil, true) then
						local func = function() return cb(file, pathid) end
						self.delay_functions[func] = func
						break
					end
				end
			end

			for k, v in ipairs(folders) do
				local func = function()
					self:StartSearch(search_text, folder .. v .. "/", extensions, pathid, cb)
				end
				self.delay_functions[func] = func
			end
		end
	end

	function search:Cancel(why)
		cancel:InvalidateLayout()
		cancel:SetVisible(false)

		self.delay_functions = {}
		self.searched = false
		if why then
			update_title("search canceled: " .. why)
		else
			update_title("search canceled")
		end
	end

	function search:Think()
		if input.IsKeyDown(KEY_ESCAPE) then
			self:Cancel()
			return
		end

		local i = 0
		for key, func in pairs(self.delay_functions) do
			i = i + 1
			local ok, reason = func()

			if ok == false then
				self:Cancel()
				return
			end
			self.delay_functions[func] = nil
			if i > 30 then break end
		end

		if i == 0 and self.searched then
			update_title()
			self.searched = false
			file.Write("pac3_cache/pac_resource_browser_index.txt", util.TableToJSON(pac.resource_browser_cache))
		end

		if frame.dir then
			if not self:IsEnabled() then
				self:SetEnabled(true)
			end
			local change = false
			if self:GetValue() == "" or self:GetValue() == self.default_text then
				change = true
			end
			self.default_text = L("search " .. frame.dir .. "/*")
			if change then
				self:SetValue(self.default_text)
			end
		else
			self:SetValue("")
			if self:IsEnabled() then
				self:SetEnabled(false)
			end
		end
	end

	function search:OnEnter()
		if self:GetValue() == "" then return end

		local count = 0

		if frame.dir == "models" then
			self.propPanel = self.model_view
			self.propPanel:Clear()
			self:StartSearch(self:GetValue(), "models/", {".mdl"}, "GAME", function(path, pathid)
				if count >= 500 then return false, "too many results (" .. count .. ")" end
				count = count + 1
				if not IsUselessModel(path) then
					self.propPanel:Add(create_model_icon(path))
				end
			end)
		elseif frame.dir == "sound" then
			self.propPanel = sound_list
			self.propPanel:Clear()
			self:StartSearch(self:GetValue(), "sound/", {".wav", ".mp3", ".ogg"}, "GAME", function(path, pathid)
				if count >= 1500 then return false, "too many results (" .. count .. ")" end
				count = count + 1
				sound_list:AddSound(path, pathid)
			end)
		elseif frame.dir == "materials" then
			self.propPanel = self.model_view
			self.propPanel:Clear()

			self:StartSearch(self:GetValue(), "materials/", {".vmt", ".vtf"}, "GAME", function(path, pathid)
				if count >= 500 then return false, "too many results (" .. count .. ")" end
				count = count + 1
				if path:EndsWith(".vmt") then
					if material_view then
						local icon = create_material_icon(path)

						if icon then
							self.propPanel:Add(icon)
						end
					end
				elseif texture_view then
					self.propPanel:Add(create_texture_icon(path))
				end
			end)
		end

		self.dir = frame.dir
		tree:OnNodeSelected(self)
	end

	file_menu:AddSpacer()
	file_menu:AddOption(L"exit", function() frame:SetVisible(false) end):SetImage(pace.MiscIcons.exit)

	frame:MakePopup()
end

if pace.model_browser and pace.model_browser:IsValid() then
	pace.model_browser:Remove()
	pace.ResourceBrowser(function(...) print(...) return false end)
end

concommand.Add("pac_resource_browser", function()
	pace.ResourceBrowser(function(...) print(...) return false end)
end)