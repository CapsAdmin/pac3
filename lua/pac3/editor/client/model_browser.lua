-- based on starfall

local L = pace.LanguageString

function pace.ModelBrowser(callback)
	local addModel

	pace.model_browser_callback = callback
	if pace.model_browser and pace.model_browser:IsValid() then
		pace.model_browser:SetVisible(true)
		pace.model_browser:MakePopup()
		return
	end

	local frame = vgui.Create( "DFrame" )
	frame:SetTitle( L"Model Viewer - Click an icon to insert model filename into editor" )
	frame:SetSize(ScrW()/1.5, ScrH()/1.5)
	frame:Center()
	frame:SetDeleteOnClose(false)

	function frame:OnClose()
		self:SetVisible(false)
	end
	local sidebarPanel = vgui.Create( "DPanel", frame )
	sidebarPanel:Dock( LEFT )
	sidebarPanel:SetSize( 190, 10 )
	sidebarPanel:DockMargin( 0, 0, 4, 0 )
	sidebarPanel.Paint = function () end

	frame.ContentNavBar = vgui.Create( "ContentSidebar", sidebarPanel )
	frame.ContentNavBar:Dock( FILL )
	frame.ContentNavBar:DockMargin( 0, 0, 0, 0 )
	frame.ContentNavBar.Tree:SetBackgroundColor( Color( 240, 240, 240 ) )
	frame.ContentNavBar.Tree.OnNodeSelected = function ( self, node )
		if not IsValid( node.propPanel ) then return end

		if IsValid( frame.PropPanel.selected ) then
			frame.PropPanel.selected:SetVisible( false )
			frame.PropPanel.selected = nil
		end

		frame.PropPanel.selected = node.propPanel

		frame.PropPanel.selected:Dock( FILL )
		frame.PropPanel.selected:SetVisible( true )
		frame.PropPanel:InvalidateParent()

		frame.HorizontalDivider:SetRight( frame.PropPanel.selected )
	end

	frame.PropPanel = vgui.Create( "DPanel", frame )
	frame.PropPanel:Dock( FILL )
	function frame.PropPanel:Paint ( w, h )
		draw.RoundedBox( 0, 0, 0, w, h, Color( 240, 240, 240 ) )
	end

	frame.HorizontalDivider = vgui.Create( "DHorizontalDivider", frame )
	frame.HorizontalDivider:Dock( FILL )
	frame.HorizontalDivider:SetLeftWidth( 175 )
	frame.HorizontalDivider:SetLeftMin( 175 )
	frame.HorizontalDivider:SetRightMin( 450 )

	frame.HorizontalDivider:SetLeft( sidebarPanel )
	frame.HorizontalDivider:SetRight( frame.PropPanel )

	local root = frame.ContentNavBar.Tree:AddNode( "Spawnlists" )
	root.info = {}
	root.info.id = 0

	local function hasGame ( name )
		for k, v in pairs( engine.GetGames() ) do
			if v.folder == name and v.mounted then
				return true
			end
		end
		return false
	end

	function addModel ( container, obj )

		local icon = vgui.Create( "SpawnIcon", container )

		if ( obj.body ) then
			obj.body = string.Trim( tostring(obj.body), "B" )
		end

		if ( obj.wide ) then
			icon:SetWide( obj.wide )
		end

		if ( obj.tall ) then
			icon:SetTall( obj.tall )
		end

		icon:InvalidateLayout( true )

		icon:SetModel( obj.model, obj.skin or 0, obj.body )

		icon:SetTooltip( string.Replace( string.GetFileFromFilename( obj.model ), ".mdl", "" ) )

		icon.DoClick = function ( icon )
			pace.model_browser:SetVisible(false)
			pace.model_browser_callback(obj.model)
		end
		icon.OpenMenu = function ( icon )

			local menu = DermaMenu()
			menu:AddOption("Copy to clipboard", function() SetClipboardText(obj.model) end)

			local submenu = menu:AddSubMenu( "Re-Render", function () icon:RebuildSpawnIcon() end )
				submenu:AddOption( "This Icon", function () icon:RebuildSpawnIcon() end )
				submenu:AddOption( "All Icons", function () container:RebuildAll() end )

			local ChangeIconSize = function ( w, h )

				icon:SetSize( w, h )
				icon:InvalidateLayout( true )
				container:OnModified()
				container:Layout()
				icon:SetModel( obj.model, obj.skin or 0, obj.body )

			end

			local submenu = menu:AddSubMenu( "Resize", function () end )
				submenu:AddOption( "64 x 64 (default)", function () ChangeIconSize( 64, 64 ) end )
				submenu:AddOption( "64 x 128", function () ChangeIconSize( 64, 128 ) end )
				submenu:AddOption( "64 x 256", function () ChangeIconSize( 64, 256 ) end )
				submenu:AddOption( "64 x 512", function () ChangeIconSize( 64, 512 ) end )
				submenu:AddSpacer()
				submenu:AddOption( "128 x 64", function () ChangeIconSize( 128, 64 ) end )
				submenu:AddOption( "128 x 128", function () ChangeIconSize( 128, 128 ) end )
				submenu:AddOption( "128 x 256", function () ChangeIconSize( 128, 256 ) end )
				submenu:AddOption( "128 x 512", function () ChangeIconSize( 128, 512 ) end )
				submenu:AddSpacer()
				submenu:AddOption( "256 x 64", function () ChangeIconSize( 256, 64 ) end )
				submenu:AddOption( "256 x 128", function () ChangeIconSize( 256, 128 ) end )
				submenu:AddOption( "256 x 256", function () ChangeIconSize( 256, 256 ) end )
				submenu:AddOption( "256 x 512", function () ChangeIconSize( 256, 512 ) end )
				submenu:AddSpacer()
				submenu:AddOption( "512 x 64", function () ChangeIconSize( 512, 64 ) end )
				submenu:AddOption( "512 x 128", function () ChangeIconSize( 512, 128 ) end )
				submenu:AddOption( "512 x 256", function () ChangeIconSize( 512, 256 ) end )
				submenu:AddOption( "512 x 512", function () ChangeIconSize( 512, 512 ) end )

			menu:AddSpacer()
			menu:AddOption( "Delete", function () icon:Remove() end )
			menu:Open()

		end

		icon:InvalidateLayout( true )

		if ( IsValid( container ) ) then
			container:Add( icon )
		end

		return icon

	end

	local function addBrowseContent ( viewPanel, node, name, icon, path, pathid )
		local models = node:AddFolder( name, path .. "models", pathid, false )
		models:SetIcon( icon )

		models.OnNodeSelected = function ( self, node )

			if viewPanel and viewPanel.currentNode and viewPanel.currentNode == node then return end

			viewPanel:Clear( true )
			viewPanel.currentNode = node

			local path = node:GetFolder()
			local searchString = path .. "/*.mdl"

			local Models = file.Find( searchString, node:GetPathID() )
			for k, v in pairs( Models ) do
				if not IsUselessModel( v ) then
					addModel( viewPanel, { model = path .. "/" .. v } )
				end
			end

			node.propPanel = viewPanel
			frame.ContentNavBar.Tree:OnNodeSelected( node )

			viewPanel.currentNode = node

		end
	end

	local function addAddonContent ( panel, folder, path )
		local files, folders = file.Find( folder .. "*", path )

		for k, v in pairs( files ) do
			if string.EndsWith( v, ".mdl" ) then
				addModel( panel, { model = folder .. v } )
			end
		end

		for k, v in pairs( folders ) do
			addAddonContent( panel, folder .. v .. "/", path )
		end
	end

	local function fillNavBar ( propTable, parentNode )
		for k, v in SortedPairs( propTable ) do
			if v.parentid == parentNode.info.id and ( v.needsapp ~= "" and hasGame( v.needsapp ) or v.needsapp == "" ) then
				local node = parentNode:AddNode( v.name, v.icon )
				node:SetExpanded( true )
				node.info = v

				node.propPanel = vgui.Create( "ContentContainer", frame.PropPanel )
				node.propPanel:DockMargin( 5, 0, 0, 0 )
				node.propPanel:SetVisible( false )

				for i, object in SortedPairs( node.info.contents ) do
					if object.type == "model" then
						addModel( node.propPanel, object )
					elseif object.type == "header" then
						if not object.text or type( object.text ) ~= "string" then return end

						local label = vgui.Create( "ContentHeader", node.propPanel )
						label:SetText( object.text )

						node.propPanel:Add( label )
					end
				end

				fillNavBar( propTable, node )
			end
		end
	end

	fillNavBar( spawnmenu.GetPropTable(), root )

	-- Games
	local gamesNode = frame.ContentNavBar.Tree:AddNode( "#spawnmenu.category.games", "icon16/folder_database.png" )

	local viewPanel = vgui.Create( "ContentContainer", frame.PropPanel )
	viewPanel:DockMargin( 5, 0, 0, 0 )
	viewPanel:SetVisible( false )

	local games = engine.GetGames()
	table.insert( games, {
		title = "All",
		folder = "GAME",
		icon = "all",
		mounted = true
	} )
	table.insert( games, {
		title = "Garry's Mod",
		folder = "garrysmod",
		mounted = true
	} )
	table.insert( games, {
		title = "Downloaded",
		folder = "DOWNLOAD",
		mounted = true
	} )

	for _, game in SortedPairsByMemberValue( games, "title" ) do

		if game.mounted then
			addBrowseContent( viewPanel, gamesNode, game.title, "games/16/" .. ( game.icon or game.folder ) .. ".png", "", game.folder )
		end
	end

	-- Addons
	local addonsNode = frame.ContentNavBar.Tree:AddNode( "#spawnmenu.category.addons", "icon16/folder_database.png" )

	local viewPanel = vgui.Create( "ContentContainer", frame.PropPanel )
	viewPanel:DockMargin( 5, 0, 0, 0 )
	viewPanel:SetVisible( false )

	function addonsNode:OnNodeSelected ( node )
		if node == addonsNode then return end
		viewPanel:Clear( true )
		addAddonContent( viewPanel, "models/", node.addon.title )
		node.propPanel = viewPanel
		frame.ContentNavBar.Tree:OnNodeSelected( node )
	end
	for _, addon in SortedPairsByMemberValue( engine.GetAddons(), "title" ) do
		if addon.downloaded and addon.mounted and addon.models > 0 then
			local node = addonsNode:AddNode( addon.title .. " ("..addon.models..")", "icon16/bricks.png" )
			node.addon = addon
		end
	end

	-- Search box
	local viewPanel = vgui.Create( "ContentContainer", frame.PropPanel )
	viewPanel:DockMargin( 5, 0, 0, 0 )
	viewPanel:SetVisible( false )

	frame.searchBox = vgui.Create( "DTextEntry", sidebarPanel )
	frame.searchBox:Dock( TOP )
	frame.searchBox:SetValue( "Search..." )
	frame.searchBox:SetTooltip( "Press enter to search" )
	frame.searchBox.propPanel = viewPanel

	frame.searchBox._OnGetFocus = frame.searchBox.OnGetFocus
	function frame.searchBox:OnGetFocus ()
		if self:GetValue() == "Search..." then
			self:SetValue( "" )
		end
		frame.searchBox:_OnGetFocus()
	end

	frame.searchBox._OnLoseFocus = frame.searchBox.OnLoseFocus
	function frame.searchBox:OnLoseFocus ()
		if self:GetValue() == "" then
			self:SetText( "Search..." )
		end
		frame.searchBox:_OnLoseFocus()
	end

	function frame.searchBox:updateHeader ()
		self.header:SetText( frame.searchBox.results .. " Results for \"" .. self.search .. "\"" )
	end

	local searchTime = nil

	function frame.searchBox:getAllModels ( time, folder, extension, path )
		if searchTime and time ~= searchTime then return end
		if self.results and self.results >= 256 then return end
		self.load = self.load + 1
		local files, folders = file.Find( folder .. "/*", path )

		for k, v in pairs( files ) do
			local file = folder .. v
			if v:EndsWith( extension ) and file:find( self.search:PatternSafe() ) and not IsUselessModel( file ) then
				addModel( self.propPanel, { model = file } )
				self.results = self.results + 1
				self:updateHeader()
			end
			if self.results >= 256 then break end
		end

		for k, v in pairs( folders ) do
			timer.Simple( k * 0.02, function()
				if searchTime and time ~= searchTime then return end
				if self.results >= 256 then return end
				self:getAllModels( time, folder .. v .. "/", extension, path )
			end )
		end
		timer.Simple( 1, function ()
			if searchTime and time ~= searchTime then return end
			self.load = self.load - 1
		end )
	end

	function frame.searchBox:OnEnter ()
		if self:GetValue() == "" then return end

		self.propPanel:Clear()

		self.results = 0
		self.load = 1
		self.search = self:GetText()

		self.header = vgui.Create( "ContentHeader", self.propPanel )
		self.loading = vgui.Create( "ContentHeader", self.propPanel )
		self:updateHeader()
		self.propPanel:Add( self.header )
		self.propPanel:Add( self.loading )

		searchTime = CurTime()
		self:getAllModels( searchTime, "models/", ".mdl", "GAME" )
		self.load = self.load - 1

		frame.ContentNavBar.Tree:OnNodeSelected( self )
	end

	frame:MakePopup()

	pace.model_browser = frame
end

if pace.model_browser and pace.model_browser:IsValid() then pace.model_browser:Remove() end