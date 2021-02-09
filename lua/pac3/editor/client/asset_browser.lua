-- based on starfall
CreateClientConVar("pac_asset_browser_close_on_select", "1")
CreateClientConVar("pac_asset_browser_remember_layout", "1")

local function table_tolist(tbl, sort)
	local list = {}
	for key, val in pairs(tbl) do
		table.insert(list, {key = key, val = val})
	end

	return list
end

local function table_sortedpairs(tbl, sort)
	local list = table_tolist(tbl)
	table.sort(list, sort)
	local i = 0
	return function()
		i = i + 1
		if list[i] then
			return list[i].key, list[i].val
		end
	end
end

local file_Exists
do
	local cache = {}
	file_Exists = function(path, id)
		local key = path .. id

		if cache[key] == nil then
			cache[key] = file.Exists(path, id)
		end

		return cache[key]
	end
end

local get_material_keyvalues
do
	local cache = {}
	get_material_keyvalues = function(path)
		if cache[path] == nil then
			cache[path] = Material(path):GetKeyValues()
		end

		return cache[path]
	end
end

local L = pace.LanguageString

local function install_click(icon, path, pattern, on_menu, pathid)
	local old = icon.OnMouseReleased
	icon.OnMouseReleased = function(_, code)
		if code == MOUSE_LEFT then
			pace.model_browser_callback(path, pathid)
		elseif code == MOUSE_RIGHT then
			local menu = DermaMenu()
			menu:AddOption(L"copy path", function()
				if pattern then
					for _, pattern in ipairs(type(pattern) == "string" and {pattern} or pattern) do
						local test = path:match(pattern)
						if test then
							path = test
							break
						end
					end
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
			local mat = CreateMaterial(path .. "_pac_asset_browser", "UnlitGeneric")
			mat:SetTexture("$basetexture", tex)
			return mat
		end
	end

	return CreateMaterial(path .. "_pac_asset_browser", "UnlitGeneric", {["$basetexture"] = path:match("materials/(.+)%.vtf")})
end

local next_generate_icon = 0
local max_generating = 5

local function setup_paint(panel, generate_cb, draw_cb)
	local old = panel.Paint
	panel.Paint = function(self,w,h)
		if not self.ready_to_draw then return end

		if not self.setup_material then
			generate_cb(self)
			self.setup_material = true
		end

		draw_cb(self, w, h)
	end

	local old = panel.OnRemove
	panel.OnRemove = function(...)
		next_generate_icon = math.max(next_generate_icon - 1, 0)

		if old then
			old(...)
		end
	end
end

local function create_texture_icon(path, pathid)
	local icon = vgui.Create("DButton")
	icon:SetTooltip(path)
	icon:SetSize(128,128)
	icon:SetWrap(true)
	icon:SetText("")

	install_click(icon, path, {"^materials/(.+)%.vtf$", "^materials/(.+%.png)$"}, nil, pathid)

	setup_paint(
		icon,
		function(self)
			self.mat = get_unlit_mat(path)
			self.realwidth = self.mat:Width()
			self.realheight = self.mat:Height()
		end,
		function(self, W, H)
			if self.mat then
				local w = math.min(W, self.realwidth)
				local h = math.min(H, self.realheight)

				surface.SetDrawColor(255,255,255,255)
				surface.SetMaterial(self.mat)
				surface.DrawTexturedRect(W/2 - w/2, H/2 - h/2, w, h)
			end
		end
	)

	return icon
end

surface.CreateFont("pace_asset_browser_fixed_width", {
	font = "dejavu sans mono",
})

local bad_materials = {}

local function create_material_icon(path, grid_panel)

	if #pace.model_browser_browse_types_tbl == 1 then
		if bad_materials[path] ~= nil then
			local str = file.Read(path, "GAME")
			if str then
				local shader =  str:match("^(.-){"):Trim():gsub("%p", ""):lower()
				if not (shader == "vertexlitgeneric" or shader == "unlitgeneric" or shader == "eyerefract" or shader == "refract") then
					bad_materials[path] = true
				else
					bad_materials[path] = false
				end
			end
		end

		if bad_materials[path] then
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
			pnl:SetCamPos(Vector(1,0,1) * 1825)
			pnl.mouseover = false

			local m = Matrix()
			m:Scale(Vector(1.37,0.99,0.01))
			pnl.Entity:EnableMatrix("RenderMultiply", m)

			--[[

			local old = icon.OnCursorEntered
			function icon:OnCursorEntered(...)
				if pace.current_part:IsValid() and pace.current_part.Materialm then
					pace.asset_browser_old_mat = pace.asset_browser_old_mat or pace.current_part.Materialm
					pace.current_part.Materialm = mat
				end

				old(self, ...)
			end


			local old = icon.OnCursorExited
			function icon:OnCursorExited(...)
				if pace.current_part:IsValid() and pace.current_part.Materialm then
					pace.current_part.Materialm = pace.asset_browser_old_mat
				end
				old(self, ...)
			end
]]

			local unlit_mat = get_unlit_mat(path)

			function pnl:Paint( w, h )
				local x, y = self:ScreenToLocal(gui.MouseX(), gui.MouseY())

				if (x > w*8 or y > h*8) or (x < -w*4 or y < -h*4) then
					surface.SetDrawColor(255,255,255,255)
					surface.SetMaterial(unlit_mat)
					surface.DrawTexturedRect(0,0,w,h)
					return
				end

				x = x / w
				y = y / h

				x = x * 50
				y = y * 50

				x = x - 25
				y = y - 55
				local light_pos = Vector(y, x, 30)

				local pos_x, pos_y = self:LocalToScreen( 0, 0 )
				cam.Start3D( self.vCamPos, Angle(45, 180, 0), self.fFOV, pos_x, pos_y, w, h, 5, self.FarZ )

				render.SuppressEngineLighting( true )


				render.SetColorModulation( 1, 1, 1 )
				render.SetBlend(1)
				render.SetLocalModelLights({{
					color = Vector(1,1,1),
					pos = self.Entity:GetPos() + light_pos,
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
			text:SetFont("pace_asset_browser_fixed_width")

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
			for k,v in pairs(get_material_keyvalues(mat_path)) do
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

local function create_model_icon(path, pathid)
	local icon = vgui.Create("SpawnIcon")

	icon:SetSize(64, 64)
	icon:SetModel(path)
	icon:SetTooltip(path)

	if path:StartWith("addons/") then
		path = path:match("^addons/.-/(.+)") or path
	end

	install_click(icon, path, nil, nil, pathid)

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

	local BaseClass = baseclass.Get( "DPanel" )

	function PANEL:Init()
		self.zoom = pace.model_browser:GetCookieNumber("zoom", 100)

		self.ContentContainers = {}

		self:SetWide(102)
		self:SetPaintBackground(false)

		self.ZoomOut = vgui.Create("DButton", self)
		self.ZoomOut:Dock(RIGHT)
		self.ZoomOut:DockMargin(2, 2, 2, 2)
		self.ZoomOut:SetText("-")
		self.ZoomOut:SetWide(20)
		self.ZoomOut.DoClick = function()
			self:SetZoom(self.zoom - 10)
		end

		self.ZoomText = vgui.Create("DTextEntry", self)
		self.ZoomText:Dock(RIGHT)
		self.ZoomText:DockMargin(2, 2, 2, 2)
		self.ZoomText:SetWide(50)
		self:SetZoomText(self.zoom)
		self.ZoomText.OnValueChange = function(value)
			local new_zoom = tonumber(value:GetText())
			if new_zoom then
				self:SetZoom(new_zoom)
			else
				self:SetZoomText(self.zoom)
			end
		end

		self.ZoomIn = vgui.Create("DButton", self)
		self.ZoomIn:Dock(RIGHT)
		self.ZoomIn:DockMargin(2, 2, 2, 2)
		self.ZoomIn:SetText("+")
		self.ZoomIn:SetWide(20)
		self.ZoomIn.DoClick = function()
			self:SetZoom(self.zoom + 10)
		end
	end

	function PANEL:AddContentContainer(pnl)
		if not table.HasValue(self.ContentContainers, pnl) then
			table.insert(self.ContentContainers, pnl)
		end
	end

	function PANEL:VisibilityCheck()
		local zoomUsable = false
		for i,v in ipairs(self.ContentContainers) do
			if v and v:IsVisible() then
				zoomUsable = true
				break
			end
		end
		self:SetVisible(zoomUsable)
	end

	function PANEL:SetZoom(num)
		self.zoom = math.Clamp(num, 16, 512)
		pace.model_browser:SetCookie("zoom", self.zoom)

		self:SetZoomText(self.zoom)

		local toDelete = {}
		for i,v in ipairs(self.ContentContainers) do
			if not (v and v:IsValid()) then
				table.insert(toDelete, i)
			elseif v:IsVisible() then
				v:CalcZoom()
			end
		end

		// Clean up any panels that are invalid for what ever reason
		for i,v in ipairs(toDelete) do
			table.remove(self.ContentContainers, v)
		end
	end

	function PANEL:SetZoomText(num)
		self.ZoomText:SetText(math.Round(num, 1) .. "%")
	end

	vgui.Register( "pac_AssetBrowser_ZoomControls", PANEL, "DPanel" )
end

do
	local PANEL = {}

	local BaseClass = baseclass.Get( "DScrollPanel" )

	function PANEL:Init()
		self:SetPaintBackground( false )

		self.IconList = vgui.Create( "DPanel", self:GetCanvas())
		self.IconList:Dock( TOP )

		function self.IconList:PerformLayout()
			if not self.invalidate then return end
			self.invalidate = nil
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
		pnl.original_size = {w=pnl:GetWide(),h=pnl:GetTall()}
		if self.ZoomControls then
			pnl:SetSize(pnl.original_size.w * self.ZoomControls.zoom * 0.01, pnl.original_size.h * self.ZoomControls.zoom * 0.01)
		end
		self.IconList:Add(pnl)
		self.IconList.invalidate = true
	end

	function PANEL:SetZoomControls(pnl)
		self.ZoomControls = pnl
		pnl:AddContentContainer(self)
	end

	function PANEL:CalcZoom()
		if self.ZoomControls then
			for i,v in ipairs(self.IconList:GetChildren()) do
				v:SetSize(v.original_size.w * self.ZoomControls.zoom * 0.01, v.original_size.h * self.ZoomControls.zoom * 0.01)
			end
			self.IconList.invalidate = true
		end
	end

	function PANEL:OnMouseWheeled(delta)
		if input.IsControlDown() and self.ZoomControls then
			self.ZoomControls:SetZoom(self.ZoomControls.zoom + delta * 4)
			return
		end
		return BaseClass.OnMouseWheeled(self, delta)
	end

	function PANEL:Clear()
		for k,v in ipairs(self.IconList:GetChildren()) do
			v:Remove()
		end
	end

	vgui.Register( "pac_AssetBrowser_ContentContainer", PANEL, "DScrollPanel" )
end

function pace.AssetBrowser(callback, browse_types_str, part_key)
	browse_types_str = browse_types_str or "models;materials;textures;sound"
	local browse_types = browse_types_str:Split(";")

	if not pac.asset_browser_cache then
		if file.Exists("pac3_cache/pac_asset_browser_index.txt", "DATA") then
			pac.asset_browser_cache = util.JSONToTable(file.Read("pac3_cache/pac_asset_browser_index.txt", "DATA")) or {}
		else
			pac.asset_browser_cache = {}
		end
	end

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

	pace.model_browser_callback = function(...)
		callback = callback or print

		if callback(...) == false then return end

		if GetConVar("pac_asset_browser_close_on_select"):GetBool() then
			pace.model_browser:SetVisible(false)
		end
	end
	pace.model_browser_browse_types = browse_types_str
	pace.model_browser_browse_types_tbl = browse_types
	pace.model_browser_part_key = part_key

	if pace.model_browser and pace.model_browser:IsValid() then
		pace.model_browser:SetVisible(true)
		pace.model_browser:MakePopup()
		return
	end

	local divider

	local frame = vgui.Create("DFrame")
	frame.title = L"asset browser" .. " - " .. (browse_types_str:gsub(";", " "))

	if GetConVar("pac_asset_browser_remember_layout"):GetBool() then
		frame:SetCookieName("pac_asset_browser")
	end

	local x = frame:GetCookieNumber("x", ScrW() - ScrW()/2.75)
	local y = frame:GetCookieNumber("y", 0)
	local w = frame:GetCookieNumber("w", ScrW()/2.75)
	local h = frame:GetCookieNumber("h", ScrH())

	x = math.Clamp(x, 0, ScrW())
	y = math.Clamp(y, 0, ScrH())

	w = math.Clamp(w, 50, ScrW())
	h = math.Clamp(h, 50, ScrH())

	frame:SetPos(x, y)
	frame:SetSize(w, h)

	frame:SetDeleteOnClose(false)
	frame:SetSizable(true)

	local last_x
	local last_y
	local last_w
	local last_h
	local div_x

	local old_think = frame.Think
	frame.Think = function(...)
		local x,y = frame:GetPos()
		local w,h = frame:GetSize()

		local div_x = divider:GetLeftWidth()

		if x ~= last_x then frame:SetCookie("x", x) last_x = x end
		if y ~= last_y then frame:SetCookie("y", y) last_y = y end
		if w ~= last_w then frame:SetCookie("w", w) last_w = w end
		if h ~= last_h then frame:SetCookie("h", h) last_h = h end
		if div_x ~= last_div_x then frame:SetCookie("div", div_x) last_div_x = div_x end

		return old_think(...)
	end
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
				file.Delete("pac3_cache/pac_asset_browser_index.txt")
				pac.asset_browser_cache = {}
			end,

			L"cancel", function()

			end
		)
	end):SetImage(pace.MiscIcons.clear)



	local options_menu = menu_bar:AddMenu(L"options")
	options_menu:SetDeleteSelf(false)
	options_menu:AddCVar(L"close browser on select", "pac_asset_browser_close_on_select", "1", "0")
	options_menu:AddCVar(L"remember layout", "pac_asset_browser_remember_layout", "1", "0")


	local zoom_controls = vgui.Create("pac_AssetBrowser_ZoomControls", menu_bar)
	zoom_controls:Dock(RIGHT)


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

	local tree = vgui.Create("DTree", left_panel)
	tree:Dock(FILL)
	tree:DockMargin(0, 0, 0, 0)
	tree:SetBackgroundColor(Color(240, 240, 240))
	frame.tree = tree
	tree.OnNodeSelected = function (self, node)
		if not IsValid(node.propPanel) then return end

		if IsValid(frame.PropPanel.selected) then
			frame.PropPanel.selected:SetVisible(false)
			frame.PropPanel.selected = nil
		end

		frame.PropPanel.selected = node.propPanel

		frame.dir = node.dir
		frame.pathid = node.pathid or node.GetPathID and node:GetPathID() or "GAME"

		frame.PropPanel.selected:Dock(FILL)
		frame.PropPanel.selected:SetVisible(true)
		zoom_controls:VisibilityCheck()

		divider:SetRight(frame.PropPanel.selected)

		if node.dir then
			local pathid = frame.pathid or "GAME"
			if pathid == "GAME" then pathid = "all" end

			update_title("browsing " .. pathid .. "/" .. node.dir .. "/*")
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
	divider:SetLeftWidth(frame:GetCookieNumber("div", 140))
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
			pace.asset_browser_snd = snd

			timer.Create("pac_asset_browser_play", SoundDuration(sound), 1, function()
				if play:IsValid() then
					play:Stop()
				end
			end)
		end

		function play.Stop()
			play:SetImage("icon16/control_play.png")

			if pace.asset_browser_snd then
				pace.asset_browser_snd:Stop()
				timer.Remove("pac_asset_browser_play")
			end
		end

		line.OnMousePressed = function(_, code)
			self:ClearSelection()
			self:SelectItem(line)

			if code == MOUSE_RIGHT then
				play:Start()
			else
				pace.model_browser_callback(sound, "GAME")
			end
		end

		local label = line.Columns[1]
		label:SetTextInset(play:GetWide() + 5, 0)

		play.DoClick = function()
			if timer.Exists("pac_asset_browser_play") and self:GetLines()[self:GetSelectedLine()] == line then
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

	local select_me

	if texture_view or material_view then
		local node = root_node:AddNode("materials", "icon16/folder_database.png")
		node.dir = "materials"

		local viewPanel = vgui.Create("pac_AssetBrowser_ContentContainer", frame.PropPanel)
		viewPanel:DockMargin(5, 0, 0, 0)
		viewPanel:SetVisible(false)
		viewPanel:SetZoomControls(zoom_controls)

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
						if file_Exists(path, "GAME") then
							create_material_icon(path, viewPanel)
						end
					end
				end

				if texture_view then
					local done = {}
					local textures = {}

					for _, material_name in ipairs(materials) do
						for k, v in pairs(get_material_keyvalues(material_name)) do
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

			if #browse_types == 1 and list_name == "materials" and (texture_view or material_view) then
				select_me = list
			end
		end
	end

	if table.HasValue(browse_types, "models") then

		local spawnlists = root_node:AddNode("spawnlists")
		spawnlists.info = {}
		spawnlists.info.id = 0
		spawnlists.dir = "models"

		local has_game = {}

		has_game[""] = true

		for k, v in pairs(engine.GetGames()) do
			if v.mounted then
				has_game[v.folder] = true
			end
		end

		local function fillNavBar(propTable, parentNode)
			for k, v in table_sortedpairs(propTable, function(a, b) return a.key < b.key end) do
				if v.parentid == parentNode.info.id and has_game[v.needsapp] then
					local node = parentNode:AddNode(v.name, v.icon)
					node:SetExpanded(true)
					node.info = v
					node.dir = "models"

					node.propPanel = vgui.Create(vgui.GetControlTable("ContentContainer") and "ContentContainer" or "pac_AssetBrowser_ContentContainer", frame.PropPanel)
					node.propPanel:DockMargin(5, 0, 0, 0)
					node.propPanel:SetVisible(false)

					parentNode.propPanel = node.propPanel

					node.OnNodeSelected = function()
						if not node.setup then
							node.setup = true
							for i, object in table_sortedpairs(v.contents, function(a, b) return a.key < b.key end) do
								if object.type == "model" then
									node.propPanel:Add(create_model_icon(object.model))
								elseif object.type == "header" then
									if not object.text or type(object.text) ~= "string" then return end

									local label = vgui.Create("ContentHeader", node.propPanel)
									label:SetText(object.text)

									node.propPanel:Add(label)
								end
							end
						end

						tree:OnNodeSelected(node)
					end

					if #browse_types == 1 and v.name == "Construction Props" then
						select_me = node
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

		node.OnNodeSelected = function()
			local categories = {}

			for _, sound_name in ipairs(sound.GetTable()) do
				local category = sound_name:match("^(.-)%.") or sound_name:match("^(.-)_") or sound_name:match("^(.-)%u")
				if not category or category == nil then category = "misc" end

				categories[category] = categories[category] or {}
				table.insert(categories[category], sound_name)
			end

			local sorted = {}

			for name, sounds in pairs(categories) do
				table.sort(sounds, function(a, b) return a < b end)
				table.insert(sorted, {name = name, sounds = sounds})
			end

			table.sort(sorted, function(a, b) return a.name < b.name end)

			for _, data in ipairs(sorted) do
				local category_name, sounds = data.name, data.sounds

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

				if searchString == "" and #browse_types == 1 then
					local count = 0
					local function find_recursive(path, pathid)
						if count >= 500 then return end
						local files_, folders_ = file.Find(path .. "/*", pathid)
						if files_ then
							for i,v in ipairs(files_) do
								count = count + 1

								local path = path .. "/" .. v

								path = path:gsub("^.-(" .. browse_types[1] .. "/.+)$", "%1")

								if browse_types[1] == "models" then
									if not IsUselessModel(path) then
										viewPanel:Add(create_model_icon(path, pathid))
									end
								elseif browse_types[1] == "materials" then
									if path:find("%.vmt$") then
										if material_view then
											create_material_icon(path, viewPanel)
										end
									elseif texture_view then
										viewPanel:Add(create_texture_icon(path, pathid))
									end
								elseif browse_types[1] == "sound" then
									sound_list:AddSound(path, pathid)
								end
							end
							for i,v in ipairs(folders_) do
								find_recursive(path .. "/" .. v, pathid)
							end
						end
					end
					find_recursive(path .. browse_types[1], node:GetPathID())
				else
					local files, folders = file.Find(searchString .. "/*", node:GetPathID())

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

								if not path:StartWith("models/pac3_cache/") then
									if not IsUselessModel(path) then
										viewPanel:Add(create_model_icon(path, pathid))
									end
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
									viewPanel:Add(create_texture_icon(path, pathid))
								end

							end
						elseif self.dir == "sound" then
							for k, v in pairs(files) do
								local path = node:GetFolder() ..  "/" .. v
								sound_list:AddSound(path, pathid)
							end
						end
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

			node = node:AddNode(name, icon)
			node:SetFolder("")
			node:SetPathID(pathid)
			node.viewPanel = viewPanel

			for _, dir in ipairs(browse_types) do
				local files, folders = file.Find(path .. dir .. "/*", pathid)
				if files and (files[1] or folders[1]) then
					local parent = node

					local node = node:AddFolder(dir, path .. dir, pathid, false)
					node.dir = dir
					node.OnNodeSelected = on_select

					if not select_me and #browse_types == 1 and name == "all" and browse_types[1] == dir and dir ~= "models" then
						select_me = node
					end

					if not select_me and #browse_types == 3 and name == "all" and dir == "materials" then
						select_me = node
					end
				end
			end

			node.OnNodeSelected = on_select
		end

		local viewPanel = vgui.Create("pac_AssetBrowser_ContentContainer", frame.PropPanel)
		viewPanel:DockMargin(5, 0, 0, 0)
		viewPanel:SetVisible(false)
		viewPanel:SetZoomControls(zoom_controls)

		do
			local special = {
				{
					title = "all",
					folder = "GAME",
					icon = "games/16/all.png",
				},
				{
					title = "downloaded",
					folder = "DOWNLOAD",
					icon = "materials/icon16/server_go.png",
				},
				{
					title = "workshop",
					folder = "WORKSHOP",
					icon = "materials/icon16/plugin.png",
				},
				{
					title = "thirdparty",
					folder = "THIRDPARTY",
					icon = "materials/icon16/folder_brick.png",
				},
				{
					title = "mod",
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

			for _, game in table_sortedpairs(games, function(a, b) return a.val.title < b.val.title end) do
				if game.mounted then
					addBrowseContent(viewPanel, root_node, game.title, "games/16/" .. (game.icon or game.folder) .. ".png", "", game.folder)
				end
			end
		end

		local node = root_node:AddNode("addons")

		for _, addon in table_sortedpairs(engine.GetAddons(), function(a, b) return a.val.title < b.val.title end) do
			if addon.file:StartWith("addons/") then
				local _, dirs = file.Find("*", addon.title)

				if
					table.HasValue(dirs, "materials") or
					table.HasValue(dirs, "models") or
					table.HasValue(dirs, "sound")
				then
					addBrowseContent(viewPanel, node, addon.title, "icon16/bricks.png", "", addon.title)
				end
			end
		end

		local _, folders = file.Find("addons/*", "MOD")

		for _, path in ipairs(folders) do
			if
				file.IsDir("addons/" .. path .. "/materials", "MOD") or
				file.IsDir("addons/" .. path .. "/sound", "MOD") or
				file.IsDir("addons/" .. path .. "/models", "MOD")
			then
				addBrowseContent(viewPanel, node, path, "icon16/folder.png", "addons/" .. path .. "/", "MOD")
			end
		end
	end

	local model_view = vgui.Create("pac_AssetBrowser_ContentContainer", frame.PropPanel)
	model_view:DockMargin(5, 0, 0, 0)
	model_view:SetVisible(false)
	model_view:SetZoomControls(zoom_controls)

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

	local function find(path, pathid)
		local key = path .. pathid

		if pac.asset_browser_cache[key] then
			return unpack(pac.asset_browser_cache[key])
		end

		local files, folders = file.Find(path, pathid)

		pac.asset_browser_cache[key] = {files, folders}

		return files, folders
	end

	function search:PerformLayout()
		cancel:SetPos(self:GetWide() - 16 - 2, 2)
	end

	function search:StartSearch(search_text, folder, extensions, pathid, cb)

		cancel:SetVisible(true)

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
				if v ~= "pac3_cache" then
					local func = function()
						self:StartSearch(search_text, folder .. v .. "/", extensions, pathid, cb)
					end
					self.delay_functions[func] = func
				end
			end
		end
	end

	function search:Stop()
		cancel:SetVisible(false)

		self.delay_functions = {}
		self.searched = false
	end

	function search:Cancel(why)
		self:Stop()

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

		if input.IsControlDown() and input.IsKeyDown(KEY_F) then
			self:RequestFocus()
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
			if i > 50 then break end
		end

		if i == 0 and self.searched then
			self:Stop()
			update_title()
			file.Write("pac3_cache/pac_asset_browser_index.txt", util.TableToJSON(pac.asset_browser_cache))
		end

		if frame.dir then
			if not self:IsEnabled() then
				self:SetEnabled(true)
			end
			local change = false
			if self:GetValue() == "" or self:GetValue() == self.default_text then
				change = true
			end

			local pathid = frame.pathid or "GAME"
			if pathid == "GAME" then pathid = "all" end

			self.default_text = L("search " .. pathid .. "/" .. frame.dir .. "/*")
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
		local pathid = frame.pathid or "GAME"
		local dir = frame.dir

		if dir == "models" then
			self.propPanel = self.model_view
			self.propPanel:Clear()
			self:StartSearch(self:GetValue(), "models/", {".mdl"}, pathid, function(path, pathid)
				if count >= 500 then return false, "too many results (" .. count .. ")" end
				count = count + 1
				if not IsUselessModel(path) then
					self.propPanel:Add(create_model_icon(path, pathid))
				end
			end)
		elseif dir == "sound" then
			self.propPanel = sound_list
			self.propPanel:Clear()
			self:StartSearch(self:GetValue(), "sound/", {".wav", ".mp3", ".ogg"}, pathid, function(path, pathid)
				if count >= 1500 then return false, "too many results (" .. count .. ")" end
				count = count + 1
				sound_list:AddSound(path, pathid)
			end)
		elseif dir == "materials" then
			self.propPanel = self.model_view
			self.propPanel:Clear()

			self:StartSearch(self:GetValue(), "materials/", {".vmt", ".vtf", ".png"}, pathid, function(path, pathid)
				if count >= 750 then return false, "too many results (" .. count .. ")" end
				if path:EndsWith(".vmt") then
					if material_view then
						count = count + 1
						create_material_icon(path, self.propPanel)
					end
				elseif texture_view then
					self.propPanel:Add(create_texture_icon(path, pathid))
					count = count + 1
				end
			end)
		elseif dir == "sound names" then
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

		self.dir = dir
		self.pathid = pathid
		tree:OnNodeSelected(self)
	end

	file_menu:AddSpacer()
	file_menu:AddOption(L"exit", function() frame:Remove() end):SetImage(pace.MiscIcons.exit)

	if select_me then
		select_me:GetParentNode():SetExpanded(true)
		select_me:SetExpanded(true)
		tree:SetSelectedItem(select_me)
	end

	frame:MakePopup()
end

if pace.model_browser and pace.model_browser:IsValid() then
	local visible = pace.model_browser:IsVisible()
	pace.model_browser:Remove()

	if visible then
		pace.AssetBrowser(function(...) print(...) return false end)
	end
end

concommand.Add("pac_asset_browser", function(_, _, args)
	pace.AssetBrowser(function(path) SetClipboardText(path) update_title("copied " .. path .. " to clipboard!") return false end, args[1] and table.concat(args, ";"))
	pace.model_browser:SetSize(ScrW()/1.25, ScrH()/1.25)
	pace.model_browser:Center()
end)

list.Set(
	"DesktopWindows",
	"PACAssetBrowser",
	{
		title = "Asset Browser",
		icon = "icon16/images.png",
		width = 960,
		height = 700,
		onewindow = true,
		init = function(icn, pnl)
			pnl:Remove()
			RunConsoleCommand("pac_asset_browser")
		end
	}
)
