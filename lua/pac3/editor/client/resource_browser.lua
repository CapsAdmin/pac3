-- based on starfall

local L = pace.LanguageString

local function install_click(icon, path, pattern, on_menu)
	local old = icon.OnMouseReleased
	icon.OnMouseReleased = function(_, code)
		if code == MOUSE_LEFT then
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

local next_generate_icon = 0
local max_generating = 5

local function setup_paint(panel, generate_cb, draw_cb)
	local old = panel.Think
	panel.Think = function(self)
		if self.last_paint and self.last_paint < RealTime() and self.setup_material == false then
			next_generate_icon = next_generate_icon - 1
			self.setup_material = nil
		end
		return old(self)
	end

	local old = panel.Paint
	panel.Paint = function(self,w,h)
		if not self.ready_to_draw then return end

		self.last_paint = RealTime() + 0.1

		if self.setup_material == false then
			self.setup_material = true
			next_generate_icon = next_generate_icon - 1
		end

		if not self.setup_material then
			if next_generate_icon > max_generating then return end
			next_generate_icon = next_generate_icon + 1

			generate_cb(self)

			self.setup_material = false
		end

		old(self,w,h)

		draw_cb(self, w, h)
	end
end

local function create_texture_icon(path)
	local icon = vgui.Create("DButton")
	icon:SetTooltip(path)
	icon:SetSize(128,128)
	icon:SetWrap(true)
	icon:SetText("")

	install_click(icon, path, "^materials/(.+)%.vtf$")

	setup_paint(
		icon,
		function(self)
			self.mat = get_unlit_mat(path)
		end,
		function(self, w, h)
			if self.mat then
				surface.SetDrawColor(255,255,255,255)
				surface.SetMaterial(self.mat)
				surface.DrawTexturedRect(0,0,w,h)
			end
		end
	)

	return icon
end

surface.CreateFont("pace_resource_browser_fixed_width", {
	font = "dejavu sans mono",
})

local function create_material_icon(path, grid_panel)

	if #pace.model_browser_browse_types_tbl == 1 and file.Read(path, "GAME") then
		local shader =  file.Read(path, "GAME"):match("^(.-){"):Trim():gsub("%p", ""):lower()
		if not (shader == "vertexlitgeneric" or shader == "unlitgeneric" or shader == "eyerefract" or shader == "refract") then
			return
		end
	end

	local mat_path = path:match("materials/(.+)%.vmt")

	local icon = vgui.Create("DButton")
	icon:SetTooltip(path)
	icon:SetSize(128,128)
	icon:SetWrap(true)
	icon:SetText("")

	setup_paint(
		icon,
		function(self)
			self:SetupMaterial()
		end,
		function(self, w, h)
			surface.SetDrawColor(0,0,0,240)
			surface.DrawRect(0,0,w,h)
		end
	)

	function icon:SetupMaterial()
		local mat = Material(mat_path)
		local shader = mat:GetShader():lower()

		if shader == "vertexlitgeneric" then
			local pnl = vgui.Create("DModelPanel", icon)
			pnl:SetMouseInputEnabled(false)
			pnl:Dock(FILL)
			pnl:SetLookAt( Vector( 0, 0, 0 ) )
			pnl:SetFOV(1)
			pnl:SetModel("models/hunter/plates/plate1x1.mdl")
			pnl:SetCamPos(Vector(1,0,1) * 1900)
			pnl.mouseover = false

			local m = Matrix()
			m:Scale(Vector(1.42,1,0.01))
			pnl.Entity:EnableMatrix("RenderMultiply", m)

			--[[

			local old = icon.OnCursorEntered
			function icon:OnCursorEntered(...)
				if pace.current_part:IsValid() and pace.current_part.Materialm then
					pace.resource_browser_old_mat = pace.resource_browser_old_mat or pace.current_part.Materialm
					pace.current_part.Materialm = mat
				end

				old(self, ...)
			end


			local old = icon.OnCursorExited
			function icon:OnCursorExited(...)
				if pace.current_part:IsValid() and pace.current_part.Materialm then
					pace.current_part.Materialm = pace.resource_browser_old_mat
				end
				old(self, ...)
			end
]]
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

				cam.Start3D( self.vCamPos, Angle(45, 180, 0), self.fFOV, x, y, w, h, 5, self.FarZ )

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

	grid_panel:Add(icon)

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

		self.zoom = ScrW()/15

		self.IconList = vgui.Create( "DPanel", self:GetCanvas())
		self.IconList:Dock( TOP )

		function self.IconList:PerformLayout()
			local x, y = 0, 0
			local max_width = self:GetWide()
			local height = 0

			local total_width

			for _, child in ipairs(self:GetChildren()) do
				height = math.max(height, child:GetTall())

				if x + child:GetWide() > max_width then
					total_width = x - max_width
					x = 0
					y = y + height
					height = 0
				end

				child:SetPos(x, y)

				x = x + child:GetWide()
			end

			if total_width then
				for _, child in ipairs(self:GetChildren()) do
					local x, y = child:GetPos()
					child:SetPos(x - total_width/2, y)
				end
			end

			self:SetTall(y + height)
		end
	end

	function PANEL:Add(pnl)
		pnl.ready_to_draw = true
		self.IconList:Add(pnl)
		self.IconList:InvalidateLayout()
		self:InvalidateLayout()
	end

	function PANEL:CalcZoom()
		for i,v in ipairs(self.IconList:GetChildren()) do
			v:SetSize(self.zoom, self.zoom)
		end

		self.IconList:InvalidateLayout()
		self:InvalidateLayout()
	end

	function PANEL:OnMouseWheeled(delta)
		if input.IsControlDown() then
			self.zoom = math.Clamp(self.zoom + delta * 4, 16, 512)
			self:InvalidateLayout()
			return
		end
		return BaseClass.OnMouseWheeled(self, delta)
	end

	function PANEL:PerformLayout()
		self:CalcZoom()
		BaseClass.PerformLayout( self )
	end

	function PANEL:Clear()
		for k,v in ipairs(self.IconList:GetChildren()) do
			v:Remove()
		end
	end

	vgui.Register( "pac_ResourceBrowser_ContentContainer", PANEL, "DScrollPanel" )
end

function pace.ResourceBrowser(callback, browse_types_str, part_key)
	browse_types_str = browse_types_str or "models;materials;textures;sound"
	local browse_types = browse_types_str:Split(";")

	local texture_view = false
	local material_view = table.HasValue(browse_types, "materials")
	local sound_view = table.HasValue(browse_types, "sound")

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
	pace.model_browser_browse_types_tbl = browse_types
	pace.model_browser_part_key = part_key

	if pace.model_browser and pace.model_browser:IsValid() then
		pace.model_browser:SetVisible(true)
		pace.model_browser:MakePopup()
		return
	end

	local frame = vgui.Create("DFrame")
	frame.title = L"resource browser" .. " - " .. (browse_types_str:gsub(";", " "))
	frame:SetSize(ScrW()/2.75, ScrH())
	frame:SetPos(ScrW() - frame:GetWide(), 0)
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

	--local root_node = tree:AddNode("content", "icon16/folder_database.png")
	--root_node:SetExpanded(true)

	local root_node = tree

	frame.PropPanel = vgui.Create("DPanel", frame)
	frame.PropPanel:Dock(FILL)

	function frame.PropPanel:Paint (w, h)
		draw.RoundedBox(0, 0, 0, w, h, Color(240, 240, 240))
	end

	divider = vgui.Create("DHorizontalDivider", frame)
	divider:Dock(FILL)
	divider:SetLeftWidth(140)
	divider:SetLeftMin(0)
	divider:SetRightMin(0)

	divider:SetLeft(left_panel)
	divider:SetRight(frame.PropPanel)


	local sound_name_list = vgui.Create("DListView", frame.PropPanel)
	sound_name_list:AddColumn(L"name")
	sound_name_list:Dock(FILL)
	sound_name_list:SetMultiSelect(false)
	sound_name_list:SetVisible(false)

	local sound_list = vgui.Create("DListView", frame.PropPanel)
	sound_list:AddColumn(L"path")
	sound_list:AddColumn(L"byte size")
	sound_list:Dock(FILL)
	sound_list:SetMultiSelect(false)
	sound_list:SetVisible(false)

	local function AddGeneric(self, sound, ...)
		local line = self:AddLine(sound, ...)
		local play = vgui.Create("DImageButton", line)
		play:SetImage("icon16/control_play.png")
		play:SizeToContents()
		play:Dock(LEFT)

		function play.Start()
			for _, v in pairs(self:GetLines()) do
				v.play:Stop()
			end

			play:SetImage("icon16/control_stop.png")

			local snd = CreateSound(LocalPlayer(), sound)
			snd:Play()
			pace.resource_browser_snd = snd

			timer.Create("pac_resource_browser_play", SoundDuration(sound), 1, function()
				if play:IsValid() then
					play:Stop()
				end
			end)
		end

		function play.Stop()
			play:SetImage("icon16/control_play.png")

			if pace.resource_browser_snd then
				pace.resource_browser_snd:Stop()
				timer.Remove("pac_resource_browser_play")
			end
		end

		line.OnMousePressed = function(_, code)
			if code == MOUSE_RIGHT then
				play:Start()
				self:ClearSelection()
				self:SelectItem(line)
			else
				pace.model_browser_callback(sound, "GAME")
			end
		end

		local label = line.Columns[1]
		label:SetTextInset(play:GetWide() + 5, 0)

		play.DoClick = function()
			if timer.Exists("pac_resource_browser_play") and self:GetLines()[self:GetSelectedLine()] == line then
				play:Stop()
				return
			end
			self:ClearSelection()
			self:SelectItem(line)

			play:Start()
		end

		line.play = play
	end

	function sound_name_list:AddSound(name)
		AddGeneric(self, name)
	end

	function sound_list:AddSound(path, pathid)
		local sound_path = path:match("sound/(.+)")

		AddGeneric(self, sound_path, file.Size(path, pathid))
	end

	if texture_view or material_view then
		local node = root_node:AddNode("materials", "icon16/folder_database.png")
		node.dir = "materials"

		local viewPanel = vgui.Create("pac_ResourceBrowser_ContentContainer", frame.PropPanel)
		viewPanel:DockMargin(5, 0, 0, 0)
		viewPanel:SetVisible(false)

		node.propPanel = viewPanel

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
						if file.Exists(path, "GAME") then
							create_material_icon(path, viewPanel)
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

		local spawnlists = root_node:AddNode("spawnlists")
		spawnlists.info = {}
		spawnlists.info.id = 0
		spawnlists.dir = "models"
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

					parentNode.propPanel = node.propPanel

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

	if sound_view then
		local node = root_node:AddNode("game sounds", "icon16/sound.png")
		node.dir = "sound names"
		node.propPanel = sound_name_list
		local sorted = {}

		for _, sound_name in ipairs(sound.GetTable()) do
			local category = sound_name:match("^(.-)%.") or sound_name:match("^(.-)_") or sound_name:match("^(.-)%u") or "misc"
			sorted[category] = sorted[category] or {}
			table.insert(sorted[category], sound_name)
		end

		for category_name, sounds in pairs(sorted) do
			local node = node:AddNode(category_name, "icon16/sound.png")
			node.dir = "sound names"
			node.propPanel = sound_name_list

			node.OnNodeSelected = function()
				sound_name_list:Clear()
				for _, sound_name in ipairs(sounds) do
					sound_name_list:AddSound(sound_name)
				end

				tree:OnNodeSelected(node)
			end
		end
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
									create_material_icon(path, viewPanel)
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

			if #browse_types == 1 and node.AddFolder then
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
				self:Cancel(reason)
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
				if count >= 750 then return false, "too many results (" .. count .. ")" end
				if path:EndsWith(".vmt") then
					if material_view then
						count = count + 1
						create_material_icon(path, self.propPanel)
					end
				elseif texture_view then
					self.propPanel:Add(create_texture_icon(path))
					count = count + 1
				end
			end)
		elseif frame.dir == "sound names" then
			self.propPanel = sound_name_list
			self.propPanel:Clear()

			local search_text = self:GetValue()
			for _, name in ipairs(sound.GetTable()) do
				if count >= 1500 then update_title("too many results (" .. count .. ")") return end
				if name:find(search_text, nil, true) then
					count = count + 1
					sound_name_list:AddSound(name)
				end
			end
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