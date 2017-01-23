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

	function frame:SwitchPanel( panel )

		if ( IsValid( self.SelectedPanel ) ) then
			self.SelectedPanel:SetVisible( false )
			self.SelectedPanel = nil
		end

		self.SelectedPanel = panel

		self.HorizontalDivider:SetRight( self.SelectedPanel )
		self.HorizontalDivider:InvalidateLayout( true )

		self.SelectedPanel:SetVisible( true )
		self:InvalidateParent()

	end

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

	do
		--[[
		PAC3 Spawnlist Generator
		by Flex

		Based off of Homestuck Playset's spawnlist generator by ¦i?C (http://steamcommunity.com/profiles/76561198018719108/)
		--]]

		local SpawnTables = {}

		local function AppendToSpawnlist(kvtype, kvdata, kvtab)
			if kvtype == "header" then
				kvtab.ContentsNum = kvtab.ContentsNum+1
				local kvContainer = {}
				kvContainer[tostring(kvtab.ContentsNum)] = {}
				kvContainer[tostring(kvtab.ContentsNum)]["type"] = "header"
				kvContainer[tostring(kvtab.ContentsNum)]["text"] = kvdata
				table.Add(kvtab.Contents, kvContainer)
			elseif kvtype == "model" then
				kvtab.ContentsNum = kvtab.ContentsNum+1
				local kvContainer = {}
				kvContainer[tostring(kvtab.ContentsNum)] = {}
				kvContainer[tostring(kvtab.ContentsNum)]["type"] = "model"
				kvContainer[tostring(kvtab.ContentsNum)]["model"] = kvdata
				table.Add(kvtab.Contents, kvContainer)
			end
		end

		local function GenerateSpawnlist(uid, name, id, parent, icon)
			SpawnTables[uid] = {}
			SpawnTables[uid].UID = id.."-"..uid
			SpawnTables[uid].Name = name
			SpawnTables[uid].Contents = {}
			SpawnTables[uid].ContentsNum = 0
			SpawnTables[uid].Icon = icon
			SpawnTables[uid].ID = id
			if parent and SpawnTables[parent] then
				SpawnTables[uid].ParentID = SpawnTables[parent].ID
			else
				SpawnTables[uid].ParentID = 0
			end
		end

		local function GetModels(path,tbl)
			for _,mdl in pairs(file.Find(path.."/*","GAME")) do
				if not mdl:find(".mdl") then continue end
				if mdl:find("_arms") then continue end
				if mdl:find("_animations") then continue end
				AppendToSpawnlist("model", path.."/"..mdl, SpawnTables[tbl])
			end
		end

		local function GetModelsFromSub(path,tbl)
			for _,dir in next,select(2,file.Find(path.."/*","GAME")) do
				for _,mdl in pairs(file.Find(path.."/"..dir.."/*","GAME")) do
					if not mdl:find(".mdl") then continue end
					if mdl:find("_arms") then continue end
					if mdl:find("_animations") then continue end
					AppendToSpawnlist("model", path.."/"..dir.."/"..mdl, SpawnTables[tbl])
				end
			end
		end

		GenerateSpawnlist("TF2Weapons", "TF2 Weapons", 1, nil, "games/16/tf.png")
		GenerateSpawnlist("TF2Hats", "Hats", 2, nil, "spawnicons/models/player/items/all_class/all_domination_b_medic.png")
		GenerateSpawnlist("WS", "Workshop", 3, nil, "icon16/wrench.png")
		GenerateSpawnlist("MvM", "MvM", 4, nil, "spawnicons/models/player/items/mvm_loot/all_class/mvm_badge.png")
		GenerateSpawnlist("PModels", "Playermodels", 5, nil, "icon16/user.png")
		GenerateSpawnlist("PACMDL", "PAC Models", 6, nil, "spawnicons/models/pac/default.png")

		--Hats
		GenerateSpawnlist("AllClass", "All Class", 21, "TF2Hats", "icon16/folder.png")
		GenerateSpawnlist("Scout", "Scout", 22, "TF2Hats", "icon16/folder.png")
		GenerateSpawnlist("Soldier", "Soldier", 23, "TF2Hats", "icon16/folder.png")
		GenerateSpawnlist("Pyro", "Pyro", 24, "TF2Hats", "icon16/folder.png")
		GenerateSpawnlist("Demo", "Demoman", 25, "TF2Hats", "icon16/folder.png")
		GenerateSpawnlist("Heavy", "Heavy", 26, "TF2Hats", "icon16/folder.png")
		GenerateSpawnlist("Engineer", "Engineer", 27, "TF2Hats", "icon16/folder.png")
		GenerateSpawnlist("Medic", "Medic", 28, "TF2Hats", "icon16/folder.png")
		GenerateSpawnlist("Sniper", "Sniper", 29, "TF2Hats", "icon16/folder.png")
		GenerateSpawnlist("Spy", "Spy", 210, "TF2Hats", "icon16/folder.png")

		--Workshop
		GenerateSpawnlist("WSAllClass", "All Class", 31, "WS", "icon16/folder.png")
		GenerateSpawnlist("WSScout", "Scout", 32, "WS", "icon16/folder.png")
		GenerateSpawnlist("WSSoldier", "Soldier", 33, "WS", "icon16/folder.png")
		GenerateSpawnlist("WSPyro", "Pyro", 34, "WS", "icon16/folder.png")
		GenerateSpawnlist("WSDemo", "Demoman", 35, "WS", "icon16/folder.png")
		GenerateSpawnlist("WSHeavy", "Heavy", 36, "WS", "icon16/folder.png")
		GenerateSpawnlist("WSEngineer", "Engineer", 37, "WS", "icon16/folder.png")
		GenerateSpawnlist("WSMedic", "Medic", 38, "WS", "icon16/folder.png")
		GenerateSpawnlist("WSSniper", "Sniper", 39, "WS", "icon16/folder.png")
		GenerateSpawnlist("WSSpy", "Spy", 310, "WS", "icon16/folder.png")
		GenerateSpawnlist("WSWep", "Weapons", 311, "WS", "icon16/gun.png")

		--Playermodels
		GenerateSpawnlist("PM_HL2", "Half-Life 2", 51, "PModels", "icon16/user.png")
		GenerateSpawnlist("PM_CIT", "Citizens", 511, "PM_HL2", "icon16/user_green.png")
		GenerateSpawnlist("PM_CSS", "Counter-Strike", 52, "PModels", "games/16/cstrike.png")
		GenerateSpawnlist("PM_GM", "Other", 53, "PModels", "games/16/garrysmod.png")

		-- Not gonna automate because we dunno what players have --

		--HL2--
		AppendToSpawnlist("header", "Resistance", SpawnTables["PM_HL2"])
		AppendToSpawnlist("model", "models/player/alyx.mdl", SpawnTables["PM_HL2"])
		AppendToSpawnlist("model", "models/player/barney.mdl", SpawnTables["PM_HL2"])
		AppendToSpawnlist("model", "models/player/eli.mdl", SpawnTables["PM_HL2"])
		AppendToSpawnlist("model", "models/player/gman_high.mdl", SpawnTables["PM_HL2"])
		AppendToSpawnlist("model", "models/player/kleiner.mdl", SpawnTables["PM_HL2"])
		AppendToSpawnlist("model", "models/player/magnusson.mdl", SpawnTables["PM_HL2"])
		AppendToSpawnlist("model", "models/player/monk.mdl", SpawnTables["PM_HL2"])
		AppendToSpawnlist("model", "models/player/mossman_arctic.mdl", SpawnTables["PM_HL2"])
		AppendToSpawnlist("model", "models/player/odessa.mdl", SpawnTables["PM_HL2"])
		AppendToSpawnlist("header", "Combine", SpawnTables["PM_HL2"])
		AppendToSpawnlist("model", "models/player/breen.mdl", SpawnTables["PM_HL2"])
		AppendToSpawnlist("model", "models/player/combine_soldier.mdl", SpawnTables["PM_HL2"])
		AppendToSpawnlist("model", "models/player/combine_soldier_prisonguard.mdl", SpawnTables["PM_HL2"])
		AppendToSpawnlist("model", "models/player/combine_super_soldier.mdl", SpawnTables["PM_HL2"])
		AppendToSpawnlist("model", "models/player/police.mdl", SpawnTables["PM_HL2"])
		AppendToSpawnlist("model", "models/player/police_fem.mdl", SpawnTables["PM_HL2"])
		AppendToSpawnlist("model", "models/player/soldier_stripped.mdl", SpawnTables["PM_HL2"])
		AppendToSpawnlist("header", "Zombies/Misc", SpawnTables["PM_HL2"])
		AppendToSpawnlist("model", "models/player/charple.mdl", SpawnTables["PM_HL2"])
		AppendToSpawnlist("model", "models/player/corpse1.mdl", SpawnTables["PM_HL2"])
		AppendToSpawnlist("model", "models/player/zombie_classic.mdl", SpawnTables["PM_HL2"])
		AppendToSpawnlist("model", "models/player/zombie_fast.mdl", SpawnTables["PM_HL2"])
		AppendToSpawnlist("model", "models/player/zombie_soldier.mdl", SpawnTables["PM_HL2"])

		--HL2 Citizens--
		AppendToSpawnlist("header", "City", SpawnTables["PM_CIT"])
		for i = 1,9 do
			AppendToSpawnlist("model", "models/player/group01/male_0"..i..".mdl", SpawnTables["PM_CIT"])
		end
		for i = 1,6 do
			AppendToSpawnlist("model", "models/player/group01/female_0"..i..".mdl", SpawnTables["PM_CIT"])
		end
		AppendToSpawnlist("header", "Refugees", SpawnTables["PM_CIT"])
		AppendToSpawnlist("model", "models/player/group02/male_02.mdl", SpawnTables["PM_CIT"])
		AppendToSpawnlist("model", "models/player/group02/male_04.mdl", SpawnTables["PM_CIT"])
		AppendToSpawnlist("model", "models/player/group02/male_06.mdl", SpawnTables["PM_CIT"])
		AppendToSpawnlist("model", "models/player/group02/male_08.mdl", SpawnTables["PM_CIT"])
		AppendToSpawnlist("header", "Resistance", SpawnTables["PM_CIT"])
		for i = 1,9 do
			AppendToSpawnlist("model", "models/player/group03/male_0"..i..".mdl", SpawnTables["PM_CIT"])
		end
		for i = 1,6 do
			AppendToSpawnlist("model", "models/player/group03/female_0"..i..".mdl", SpawnTables["PM_CIT"])
		end
		AppendToSpawnlist("header", "Medics", SpawnTables["PM_CIT"])
		for i = 1,9 do
			AppendToSpawnlist("model", "models/player/group03m/male_0"..i..".mdl", SpawnTables["PM_CIT"])
		end
		for i = 1,6 do
			AppendToSpawnlist("model", "models/player/group03m/female_0"..i..".mdl", SpawnTables["PM_CIT"])
		end

		--CSS--
		AppendToSpawnlist("header", "Terrorists", SpawnTables["PM_CSS"])
		AppendToSpawnlist("model", "models/player/arctic.mdl", SpawnTables["PM_CSS"])
		AppendToSpawnlist("model", "models/player/guerilla.mdl", SpawnTables["PM_CSS"])
		AppendToSpawnlist("model", "models/player/leet.mdl", SpawnTables["PM_CSS"])
		AppendToSpawnlist("model", "models/player/phoenix.mdl", SpawnTables["PM_CSS"])

		AppendToSpawnlist("header", "Counter-Terrorists", SpawnTables["PM_CSS"])
		AppendToSpawnlist("model", "models/player/gasmask.mdl", SpawnTables["PM_CSS"])
		AppendToSpawnlist("model", "models/player/swat.mdl", SpawnTables["PM_CSS"])
		AppendToSpawnlist("model", "models/player/urban.mdl", SpawnTables["PM_CSS"])
		AppendToSpawnlist("header", "Hostages", SpawnTables["PM_CSS"])
		for i = 1,4 do
			AppendToSpawnlist("model", "models/player/hostage/hostage_0"..i..".mdl", SpawnTables["PM_CSS"])
		end

		--Other--
		AppendToSpawnlist("model", "models/player/dod_american.mdl", SpawnTables["PM_GM"])
		AppendToSpawnlist("model", "models/player/dod_german.mdl", SpawnTables["PM_GM"])
		AppendToSpawnlist("model", "models/player/p2_chell.mdl", SpawnTables["PM_GM"])
		AppendToSpawnlist("model", "models/player/skeleton.mdl", SpawnTables["PM_GM"])

		--PAC Models--
		AppendToSpawnlist("model", "models/pac/default.mdl", SpawnTables["PACMDL"])
		AppendToSpawnlist("model", "models/pac/female/base_female.mdl", SpawnTables["PACMDL"])
		AppendToSpawnlist("model", "models/pac/female/base_female_jiggle.mdl", SpawnTables["PACMDL"])
		AppendToSpawnlist("model", "models/pac/female/base_female_arm_l.mdl", SpawnTables["PACMDL"])
		AppendToSpawnlist("model", "models/pac/female/base_female_arm_r.mdl", SpawnTables["PACMDL"])
		AppendToSpawnlist("model", "models/pac/female/base_female_leg_l.mdl", SpawnTables["PACMDL"])
		AppendToSpawnlist("model", "models/pac/female/base_female_leg_r.mdl", SpawnTables["PACMDL"])
		AppendToSpawnlist("model", "models/pac/female/base_female_torso.mdl", SpawnTables["PACMDL"])
		AppendToSpawnlist("model", "models/pac/female/base_female_torso_jiggle.mdl", SpawnTables["PACMDL"])
		AppendToSpawnlist("model", "models/pac/male/base_male.mdl", SpawnTables["PACMDL"])
		AppendToSpawnlist("model", "models/pac/male/base_male_arm_l.mdl", SpawnTables["PACMDL"])
		AppendToSpawnlist("model", "models/pac/male/base_male_arm_r.mdl", SpawnTables["PACMDL"])
		AppendToSpawnlist("model", "models/pac/male/base_male_leg_l.mdl", SpawnTables["PACMDL"])
		AppendToSpawnlist("model", "models/pac/male/base_male_leg_r.mdl", SpawnTables["PACMDL"])
		AppendToSpawnlist("model", "models/pac/male/base_male_torso.mdl", SpawnTables["PACMDL"])
		AppendToSpawnlist("header", "Jiggles", SpawnTables["PACMDL"])
		for i = 0,5 do
			AppendToSpawnlist("model", "models/pac/jiggle/base_cloth_"..i..".mdl", SpawnTables["PACMDL"])
		end
		for i = 0,5 do
			AppendToSpawnlist("model", "models/pac/jiggle/base_cloth_"..i.."_gravity.mdl", SpawnTables["PACMDL"])
		end
		for i = 0,5 do
			AppendToSpawnlist("model", "models/pac/jiggle/base_jiggle_"..i..".mdl", SpawnTables["PACMDL"])
		end
		for i = 0,5 do
			AppendToSpawnlist("model", "models/pac/jiggle/base_jiggle_"..i.."_gravity.mdl", SpawnTables["PACMDL"])
		end
		AppendToSpawnlist("header", "Capes", SpawnTables["PACMDL"])
		AppendToSpawnlist("model", "models/pac/jiggle/clothing/base_cape_1.mdl", SpawnTables["PACMDL"])
		AppendToSpawnlist("model", "models/pac/jiggle/clothing/base_cape_2.mdl", SpawnTables["PACMDL"])
		AppendToSpawnlist("model", "models/pac/jiggle/clothing/base_cape_1_gravity.mdl", SpawnTables["PACMDL"])
		AppendToSpawnlist("model", "models/pac/jiggle/clothing/base_cape_2_gravity.mdl", SpawnTables["PACMDL"])
		AppendToSpawnlist("model", "models/pac/jiggle/clothing/base_trench_1.mdl", SpawnTables["PACMDL"])
		AppendToSpawnlist("model", "models/pac/jiggle/clothing/base_trench_1_gravity.mdl", SpawnTables["PACMDL"])

		-- AUTOMATION BELOW --
		--Weapons
		GetModels("models/weapons/c_models","TF2Weapons")
		GetModelsFromSub("models/weapons/c_models","TF2Weapons")

		--Hats
		GetModels("models/player/items/all_class","AllClass")
		GetModels("models/player/items/scout","Scout")
		GetModels("models/player/items/soldier","Soldier")
		GetModels("models/player/items/pyro","Pyro")
		GetModels("models/player/items/demo","Demo")
		GetModels("models/player/items/heavy","Heavy")
		GetModels("models/player/items/engineer","Engineer")
		GetModels("models/player/items/medic","Medic")
		GetModels("models/player/items/sniper","Sniper")
		GetModels("models/player/items/spy","Spy")

		--MvM
		GetModelsFromSub("models/player/items/mvm_loot","MvM")

		--Workshop
		GetModelsFromSub("models/workshop/player/items/all_class","WSAllClass")
		GetModelsFromSub("models/workshop/player/items/scout","WSScout")
		GetModelsFromSub("models/workshop/player/items/soldier","WSSoldier")
		GetModelsFromSub("models/workshop/player/items/pyro","WSPyro")
		GetModelsFromSub("models/workshop/player/items/demo","WSDemo")
		GetModelsFromSub("models/workshop/player/items/heavy","WSHeavy")
		GetModelsFromSub("models/workshop/player/items/engineer","WSEngineer")
		GetModelsFromSub("models/workshop/player/items/medic","WSMedic")
		GetModelsFromSub("models/workshop/player/items/sniper","WSSniper")
		GetModelsFromSub("models/workshop/player/items/spy","WSSpy")
		GetModelsFromSub("models/workshop/weapons/c_models","WSWep")

		local ViewPanel = vgui.Create( "ContentContainer", frame.PropPanel )
		ViewPanel:SetVisible( false )

		local pac_node = frame.ContentNavBar.Tree:AddNode("PAC3","icon16/user_edit.png")
		pac_node.DoClick = function()
			ViewPanel:Clear( true )
			frame:SwitchPanel( ViewPanel )
		end

		local nodes = {}

		for _,t in SortedPairs(SpawnTables) do
			nodes[t.ID] = pac_node:AddNode(t.Name,t.Icon)

			nodes[t.ID].DoClick = function(s,node)
				if ( ViewPanel && ViewPanel.CurrentNode && ViewPanel.CurrentNode == node ) then return end
				ViewPanel:Clear( true )
				ViewPanel.CurrentNode = node

				if t.Contents then
					for _,c in pairs(t.Contents) do
						if c.type == "model" then
							addModel( ViewPanel, { model = c.model} )
						elseif c.type == "header" then
							local cp = spawnmenu.GetContentType("header")
							if cp then
								cp( ViewPanel, { text = c.text} )
							end
						end
					end
				end

				frame:SwitchPanel( ViewPanel )
				ViewPanel.CurrentNode = node
			end
		end

		for _,n in pairs(nodes) do
			for _,t in pairs(SpawnTables) do
				if t.ParentID and nodes[t.ParentID] then
					nodes[t.ParentID]:InsertNode(nodes[t.ID])
				end
			end
		end


	end

	local root = frame.ContentNavBar.Tree:AddNode( "Your Spawnlists" )
	root:SetExpanded( true )
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
	frame.OldSpawnlists = frame.ContentNavBar.Tree:AddNode( "#spawnmenu.category.browse", "icon16/cog.png" )
	frame.OldSpawnlists:SetExpanded( true )

	-- Games
	local gamesNode = frame.OldSpawnlists:AddNode( "#spawnmenu.category.games", "icon16/folder_database.png" )

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

	for _, game in SortedPairsByMemberValue( games, "title" ) do

		if game.mounted then
			addBrowseContent( viewPanel, gamesNode, game.title, "games/16/" .. ( game.icon or game.folder ) .. ".png", "", game.folder )
		end
	end

	-- Addons
	local addonsNode = frame.OldSpawnlists:AddNode( "#spawnmenu.category.addons", "icon16/folder_database.png" )

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