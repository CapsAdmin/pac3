AddCSLuaFile()

if SERVER then
	local function pacVersion()
		local addonFound = false

		for k,v in pairs(select(2, file.Find( "addons/*", "GAME" ))) do
			if file.Exists("addons/"..v.."/lua/autorun/pac_init.lua", "GAME") then
				addonFound = true
				local dir = "addons/"..v.."/.git/"
				local head = file.Read(dir.."HEAD", "GAME") -- Where head points to
				if not head then break end

				head = string.match(head, "ref:%s+(%S+)")
				if not head then break end

				local lastCommit = string.match(file.Read( dir..head, "GAME") or "", "%S+")
				if not lastCommit then break end

				return "Git: " .. string.GetFileFromFilename(head) .. " (" .. lastCommit .. ")"
			end
		end

		if addonFound then
			return "unknown"
		else
			return "workshop"
		end
	end

	SetGlobalString("pac_version", pacVersion())
end

function _G.PAC_VERSION()
	return GetGlobalString("pac_version")
end

concommand.Add("pac_version", function()
	print(PAC_VERSION())
	if CLIENT and PAC_VERSION() == "workshop" then
		print("Fetching workshop info...")
		steamworks.FileInfo( "104691717", function(result)
			print("Updated: " .. os.date("%x %X", result.updated))
		end)
	end
end)


--accessed in the editor under pac-help-version
function pac.OpenMOTD(mode)
	local pnl = vgui.Create("DFrame")
	pnl:SetSize(math.min(1400, ScrW()),math.min(900,ScrH()))

	local html = vgui.Create("DHTML", pnl)

	if mode == "combat_update" then
		pnl:SetTitle("Welcome to a new update!")
		html:SetHTML(pace.cedrics_combat_update_changelog_html)
	elseif mode == "local_changelog" then
		pnl:SetTitle("Latest changes of this installation")
		html:SetHTML(pace.current_version_changelog_html)
	elseif mode == "commit_history" then
		pnl:SetTitle("Newest changes from the develop branch (please update your PAC version!)")
		html:OpenURL("https://github.com/CapsAdmin/pac3/commits/develop")
	end
	html:Dock(FILL)

	pnl:Center()
	pnl:MakePopup()
end


--CHANGELOGS

--one for the current install. edit as needed!
pace.current_version_changelog_html = [[
	<body style="background-color:white;">
	<h3>Reminder: If you installed from github into your addons folder, you have to update manually</h3>
		<h1>Major update special! : The Combat Update "PAC4.5"</h1>

			<h2 style="margin-left: 15px">new parts</h2>
				<h3 style="margin-left: 35px">damage zone</h3>
				<h3 style="margin-left: 35px">lock</h3>
				<h3 style="margin-left: 35px">force</h3>
				<h3 style="margin-left: 35px">health modifier</h3>
				<h3 style="margin-left: 35px">hitscan</h3>
				<h3 style="margin-left: 35px">interpolator</h3>

			<h2 style="margin-left: 15px">major editor customizability</h2>
				<h3 style="margin-left: 35px">keyboard shortcuts and new actions</h3>
				<h3 style="margin-left: 35px">part menu actions</h3>
				<h3 style="margin-left: 35px">part categories</h3>
				<h3 style="margin-left: 35px">favorites system and proxy/command banks</h3>
				<h3 style="margin-left: 35px">popup system (F1) and tutorials for parts and events</h3>
				<h3 style="margin-left: 35px">eventwheel colors</h3>

			<h2 style="margin-left: 15px">Bulk Select + Bulk Apply Properties</h2>

			<h2 style="margin-left: 15px">PAC Copilot</h2>
				<h3 style="margin-left: 35px">highlight an important property when creating some parts</h3>
				<h3 style="margin-left: 35px">re-focus to pac camera when creating camera part</h3>
				<h3 style="margin-left: 35px">setup command event if writing a generic name in an event</h3>
				<h3 style="margin-left: 35px">right click a material part's load VMT to gather the active model's materials for fast editing</h3>

			<h2 style="margin-left: 15px">Command event features</h2>
				<h3 style="margin-left: 35px">pac_event_sequenced command for activating series (combos, variations etc.)</h3>
				<h3 style="margin-left: 35px">eventwheel colors</h3>
				<h3 style="margin-left: 35px">eventwheel styles and grid eventwheel</h3>
				<h3 style="margin-left: 35px">pac_eventwheel_visibility_rule command for filtering eventwheel with many choices and keywords</h3>

			<h2 style="margin-left: 15px">More miscellaneous features</h2>
				<h3 style="margin-left: 35px">nearest life aim part names : point movable parts toward the nearest NPC or player</h3>
				<h3 style="margin-left: 35px">prompt for autoload : optional menu to pick between autoload.txt, your autosave backup, or your latest loaded outfit</h3>
				<h3 style="margin-left: 35px">improvements to player movement, physics, projectile parts</h3>


		<h1>Changelog : November 2023</h1>
			<h2>Fixed legacy lights</h2>

		<h1>Changelog : October 2023</h1>
			<h2>Fixed lights</h2>
			<h2>Fixed webcontent limit cvar's help text</h2>
			<h2>Add hook for autowear</h2>

		<h1>Changelog : September 2023</h1>
			<h2>Fix for .obj urls</h2>
			<h2>Text part: define fonts, 2D text modes, more data sources</h2>
			<h2>Updated README</h2>
			<h2>prepare for automated develop deployment</h2>
			<h2>keep original proxy data in .vmt files</h2>
			<h2>fix player/weapon color proxies in mdlzips</h2>
			<h2>add new material files when looking for missing ones</h2>

		<h1>Changelog : August 2023</h1>
			<h2>"spawn as props" bone scale retention</h2>
			<h2>Fix/rework submitpart</h2>

		<h1>Changelog : July 2023</h1>
			<h2>small fix for sequential in legacy sound</h2>
			<h2>less awkward selection when deleting keyframes</h2>
			<h2>more proxy functions</h2>
			<h2>Changed Hands SWEP to work better with pac</h2>
			<h2>Reduce network usage on entity mutators</h2>
			<h2>Various command part error handling</h2>

		<h1>Changelog : June 2023</h1>
			<h2>sequential playback for legacy sound and websound parts</h2>
			<h2>more proxy functions</h2>

		<h1>Changelog : June 2023</h1>
			<h2>Fix new dropbox urls</h2>

		<h1>Changelog : May 2023</h1>
			<h2>make "free children" actually work</h2>
			<h2>add a way to disable the eargrab animations</h2>

		<h1>Changelog : April 2023</h1>
			<h2>Fix voice volume error spam</h2>
			<h2>Add input to proxy error</h2>
			<h2>new hitpos pac bones</h2>
			<h2>beam start/end width multipliers</h2>
			<h2>text part features</h2>
			<h2>a fix for singleplayer mute footsteps</h2>
			<h2>options for particles</h2>
			<h2>Prevent excessive pac size abuse</h2>

		<h1>Changelog : February 2023</h1>
			<h2>sort vmt directories</h2>
			<h2>add support for 'patch' materials in mdlzips</h2>

		<h1>Changelog : January 2023</h1>
			<h2>fixing a small bug with autoload and button events</h2>
			<h2>Added bearing to event and proxy to help with 2d sprites</h2>
			<h2>maybe fix command events</h2>
			<h2>add default values to command events</h2>
			<h2>add cvars to hide pac cameras and/or 'in-editor' information</h2>
	</body>
]]


--cedric's PAC4.5 combat update readme. please don't touch! it's a major update that happened once so it doesn't make sense to edit it after that
pace.cedrics_combat_update_changelog_html = [[
	<body style="background-color:white;">
	<h1 id="pac45">PAC4.5</h1>
	<hr>
	<p>Welcome to my combat update for PAC3. Here&#39;s the overview of the important bits to expect.</p>
	<h1 id="new-combat-related-parts">New combat-related parts:</h1>
	<pre><code>
	damage_zone: deals damage (a more direct and controllable alternative to projectiles)

	hitscan: shoots bullets

	lock: teleport/grab

	force: does physics forces

	health_modifier: changes your health, armor etc

	interpolated_multibone: morphs position / angles between different base_movables nodes, like a path
	</code></pre>
	<p>The combat features work with the principle of consent. The lock part especially is severely restricted for grabbing players, for what should be obvious reasons. You can only damage or grab players who have opted in for the corresponding consent.</p>
	<pre><code>
	pac_client_damage_zone_consent 0
	pac_client_hitscan_consent 0
	pac_client_force_consent 0
	pac_client_grab_consent 0
	pac_client_lock_camera_consent 0
	</code></pre>
	<p>There are also commands for clients to free themselves if they&#39;re being grabbed.</p>
	<pre><code>
	pac_break_lock
	pac_stop_lock
	</code></pre>
	<p>Multiple options exist for servers to prevent mass abuse. cvars, size limits, damage limits, entity limits, which combat parts are allowed, as well as several net-protecting options to ease the load on the server&#39;s processing and on the network (reliable channel)...</p>
	<p>I know how big of a change this is. When creating the settings the first time, the combat parts will only be enabled for singleplayer sandbox. In multiplayer and in other gamemodes, it will be 0.</p>
	<pre><code>
	pac_sv_combat_whitelisting 0
	pac_sv_damage_zone 1
	pac_sv_lock 1
	pac_sv_lock_grab 1
	pac_sv_lock_teleport 1
	pac_sv_lock_max_grab_radius 200
	pac_sv_combat_enforce_netrate 0
	pac_sv_entity_limit_per_combat_operation 500
	pac_sv_entity_limit_per_player_per_combat_operation 40
	pac_sv_player_limit_as_fraction_to_drop_damage_zone 1
	pac_sv_block_combat_features_on_next_restart 0
	...
	</code></pre>


	<h1 id="editor-features">Editor features:</h1>
	<h2 id="bulk-select">Bulk Select</h2>
	<p>Select multiple parts and do some basic operations repeatedly. By default it&#39;s CTRL + click to select/unselect a part.</p>
	<p>Along with it, Bulk Apply Properties is a new menu to change multiple parts&#39; properties at once.</p>
	<p>pac_bulk_select_halo_mode is a setting to decide when to highlight the bulk selected parts with the usual hover halos</p>

	<h2 id="extensive-customizability-user-configs-will-be-saved-in-datapac3_config">Extensive customizability (user configs will be saved in data/pac3_config)</h2>
	<p>Customizable shortcuts for almost every action (in the pac settings menu).</p>
	<p>Reordering the part menu actions layout (in the pac settings menu).</p>
	<p>Changing your part categories, with possible custom icons.</p>
	<p>Command events:</p>
	<p>	pac_eventwheel_visibility_rule</p>
	<p>	Colors for the event wheel (with a menu)</p>
	<p>	A new grid style and some sub-styles to choose from</p>
	<p>	Changeable activation modes between mouse click and releasing the bind</p>
	<p>	Visibility rules / filtering modes to filter out keywords etc. see the command pac_eventwheel_visibility_rule for more info.</p>


	<h2 id="expanded-settings-menu">Expanded settings menu</h2>
	<p>Clients can configure their editor experience, and owners with server access can configure serverwide combat-related limits and policies and more.</p>
	<h2 id="favorite-assets-for-quick-access-user-configs-will-be-saved-in-datapac3_config">Favorite assets for quick access (user configs will be saved in data/pac3_config)</h2>
	<p>right click on assets in the pac asset browser to save it to your favorites. it can also try to do series if they end in a number, but it might fail. right clicking on the related field will bring it up in your list</p>


	<h2 id="popup-system">Popup system</h2>
	<p>A new framework to show information in the editor. Select a part and press F1 to open information about it. Currently holds part tutorials,  part size and notes. It can be configured to be on various places, and different colors. Look for that in the editor's options tab.</p>


	<h2 id="editor-copilot--foolproofing-and-editor-assist">PAC copilot : Foolproofing and editor assist</h2>
	<p>Selecting an event will pick an appropriate operator, and clicking away from a proxy without a variable name will notify you about how it won&#39;t work, telling you to go back and change it</p>


	<p>Writing a name into an event&#39;s type will create a command event with that name if the name isn&#39;t a recognized event type, so you can quickly setup command events.</p>


	<p>auto-disable editor camera to preview the camera part when creating a camera part</p>


	<p>auto-focus on the relevant property when creating certain parts</p>


	<h1 id="reference-and-help-features">Reference and help features</h1>
	<p>proxy bank: some presets with tooltip explanations. right click on the expression field to look at them</p>


	<p>command bank: presets to use the command part. again, right click on the expression field to look at them</p>


	<p>A built-in wiki written by me, for every part and most event types: short tooltips to tell you what a part does when you hover over the label when choosing which part to create, longer tutorials opened with F1 when you select an existing part.</p>


	<h1 id="miscellaneous-features">Miscellaneous features</h1>
	<h2 id="part-notes">Part notes</h2>
	<p>a text field for the base_part, so you can write notes on any part.</p>
	<h2 id="prompt-for-autoload">Prompt for autoload</h2>
	<p>option to get a prompt to choose between your autoload file, your latest backup or latest loaded outfit when starting.</p>
	<h2 id="queue-propnpc-outfits-singleplayer-only">Queue prop/NPC outfits (singleplayer only)</h2>
	<p>option so that, when loading an outfit for props/NPCs, instead of hanging in the editor and needing to reassign the owner name manually, pac will not wear yet, but wait for you to spawn an appropriate prop or entity that had the outfit.</p>


	<h2 id="pac_event_sequenced">pac_event_sequenced</h2>
	<p>pac_event but with more options to control series of numbered events.</p>
	<p>pac will try to register the max number when you create a command event with the relevant number e.g. to reach command10 you need to have a command event with the name command10. rewear for best results.</p>
	<p>examples:</p>
	<p>this increments by 1 (and loops back if necessary)</p>
	<pre><code>pac_event_sequenced hat_style +
	</code></pre>
	<p>this sets the series to 3</p>
	<pre><code>pac_event_sequenced hat_style set 3
	</code></pre>
	<p>keywords for going forward: +, add, forward, advance, sequence+</p>
	<p>keywords for going backward: -, sub, backward, sequence-</p>
	<p>keyword to set: set</p>


	<h2 id="improvements-to-physics-and-projectile-parts">Improvements to physics and projectile parts</h2>
	<p>Set the surface properties, preview the sizes and some more.</p>
	<p>For projectiles to change the physics mesh (override mesh), it might have some issues.</p>

	<h2 id="improvements-to-player-movement">Improvements to the player movement part</h2>
	<p>option to preserve in first person</p>
	<p>An attempt to handle water, glass and ice better.</p>


	<h2 id="bigger-fonts-for-the-editor--pac_editor_scale-for-the-trees-scale">Bigger fonts for the editor + pac_editor_scale for the tree&#39;s scale</h2>
	<p>just a quick edit for people with higher resolution screens</p>


	<h2 id="new-hover-halo-colors">New hover halos</h2>
	<p>You can recolor your hover halos for when you mouse over model parts and the bulk select</p>
	<p>the default, pac_hover_color 255 255 255, is white, but you can change the R G B values or use the keywords rainbow, ocean, rave or none</p>
	<p>pac_hover_pulserate controls the speed</p>
	<p>pac_hover_halo_limit controls how many parts can be drawn. if there are too many, pac can break</p>

	<h2 id="new-tools">New tools</h2>
	<p>-destroy hidden parts, proxies and events. I also call it Ultra cleanup. This is a quick but destructive optimization tool to improve framerate by only keeping visible parts and obliterating non-static elements. You can mark parts to keep by writing &quot;important&quot; in their notes field.</p>
	<p>-Engrave targets: assign proxies and events&#39; target part to quickly allow you to reorganize them in a separate group in the editor.</p>
	<p>-dump model submaterials: same as dump player submaterials (prints the submaterials in the console) but for a pac3 model you select in the tree</p>
	<hr>
	<h3 id="thank-you-for-reading-now-go-make-something-cool">Thank you for reading. Now go make something cool!</h3>
	<h3 id="yours-truly">Yours truly,</h3>
	<h3 id="cedric">Cédric.</h3>
	<body>
	]]
