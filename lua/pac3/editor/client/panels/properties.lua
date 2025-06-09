local L = pace.LanguageString

local languageID = CreateClientConVar("pac_editor_languageid", 1, true, false, "Whether we should show the language indicator inside of editable text entries.")
local favorites_menu_expansion = CreateClientConVar("pac_favorites_try_to_build_asset_series", "0", true, false)
local extra_dynamic = CreateClientConVar("pac_special_property_update_dynamically", "1", true, false, "Whether proxies should refresh the properties, and some booleans may show more information.")
local special_property_text_color = CreateClientConVar("pac_special_property_text_color", "160 0 80", true, false, "R G B color of special property text\npac_special_property_text_color \"\" will make it not change the color\nSpecial contexts like proxies and hidden parts can show a different color to show that changes are happening in real time.")

pace.special_property_text_color = Color(160,0,80)
if special_property_text_color:GetString() ~= "" then
	local r,g,b = unpack(string.Split(special_property_text_color:GetString(), " "))
	r = tonumber(r) or 0 g = tonumber(g) or 0 b = tonumber(b) or 0
	pace.special_property_text_color = Color(r,g,b)
else
	pace.special_property_text_color = nil
end
cvars.AddChangeCallback("pac_special_property_text_color", function(cvar, old, new)
	if new ~= "" then
		local r,g,b = unpack(string.Split(special_property_text_color:GetString(), " "))
		r = tonumber(r) or 0 g = tonumber(g) or 0 b = tonumber(b) or 0
		pace.special_property_text_color = Color(r,g,b)
	else
		pace.special_property_text_color = nil
	end
end, "pac_change_special_property_text_color")

local searched_cache_series_results = {}

function pace.ShowSpecial(pnl, parent, size)
	size = size or 150

	pnl:SetPos(pace.Editor:GetWide(), select(2, parent:LocalToScreen()) - size + 25)
	pnl:SetSize(size, size)
	pnl:MakePopup()
end

function pace.FixMenu(menu)
	menu:SetMaxHeight(500)
	menu:InvalidateLayout(true, true)
	menu:SetPos(pace.Editor:GetPos() + pace.Editor:GetWide(), gui.MouseY() - (menu:GetTall() * 0.5))
end


function pace.GoToPart(part)
	pace.OnPartSelected(part, true)
	local delay = 0
	if not IsValid(part.pace_tree_node) then --possible de-loaded node
		delay = 0.5
	end
	local parent = part:GetParent()
	while IsValid(parent) and (parent:GetParent() ~= parent) do
		parent:SetEditorExpand(true)
		parent = parent:GetParent()
		if parent:IsValid() then
			parent:SetEditorExpand(true)
		end
	end
	pace.RefreshTree(true)

	timer.Simple(delay, function() if IsValid(part.pace_tree_node) then
		pace.tree:ScrollToChild(part.pace_tree_node)
	end end)
end
---returns table
--start_index is the first known index
--continuous is whether it's continuous (some series have holes)
--end_index is the last known
function pace.FindAssetSeriesBounds(base_directory, base_file, extension)

	--LEADING ZEROES FIX NOT YET IMPLEMENTED
	local function leading_zeros(str)
		str = string.StripExtension(str)

		local untilzero_pattern = "%f[1-9][0-9]+$"
		local afterzero_pattern = "0+%f[1-9+]"
		local beforenumbers_pattern = "%f[%f[1-9][0-9]+$]"
		--string.gsub(str, "%f[1-9][0-9]+$", "") --get the start until the zeros stop

		--string.gsub(str, "0+%f[1-9+]", "") --leave start

		if string.find(str, afterzero_pattern) then
			return string.gsub(str, untilzero_pattern, string.match(str, afterzero_pattern))
		end
	end
	--print(base_file .. "leading zeros?" , leading_zeros(base_file))
	if searched_cache_series_results[base_directory .. "/" .. base_file] then return searched_cache_series_results[base_directory .. "/" .. base_file] end
	local tbl = {}
	local i = 0 --try with 0 at first
	local keep_looking = true
	local file_n
	local lookaheads_left = 15
	local next_exists
	tbl.start_index = nil
	tbl.all_paths = {}
	local index_compressed = 1 --increasing ID number of valid files

	while keep_looking do

		file_n = base_directory .. "/" .. base_file .. i .. "." .. extension
		--print(file_n , "file" , file.Exists(file_n, "GAME") and "exists" or "doesn't exist")
		--print("checking" , file_n) print("\tThe file" , file.Exists(file_n, "GAME") and "exists" or "doesn't exist")
		if file.Exists(file_n, "GAME") then
			if not tbl.start_index then tbl.start_index = i end
			tbl.end_index = i
			tbl.all_paths[index_compressed] = file_n
			index_compressed = index_compressed + 1
		end


		i = i + 1
		file_n = base_directory .. "/" .. base_file .. i .. "." .. extension
		next_exists = file.Exists(file_n, "GAME")
		if not next_exists then
			if tbl.start_index then tbl.continuous = false end
			lookaheads_left = lookaheads_left - 1
		else
			lookaheads_left = 15
		end
		keep_looking = next_exists or lookaheads_left > 0
	end
	if not tbl.start_index then tbl.continuous = false end
	--print("result of search:")
	--PrintTable(tbl)
	searched_cache_series_results[base_directory .. "/" .. base_file] = tbl
	return tbl
end


function pace.AddSubmenuWithBracketExpansion(pnl, func, base_file, extension, base_directory)
	if extension == "vmt" then base_directory = "materials" end --prescribed format: short
	if extension == "mdl" then base_directory = "models" end --prescribed format: full
	if extension == "wav" or extension == "mp3" or extension == "ogg" then base_directory = "sound" end  --prescribed format: no trunk

	local base_file_original = base_file
	if string.find(base_file, "%[%d+,%d+%]") then --find the bracket notation
		base_file = string.gsub(base_file, "%[%d+,%d+%]$", "")
	elseif string.find(base_file, "%d+") then
		base_file = string.gsub(base_file, "%d+$", "")
	end

	local tbl = pace.FindAssetSeriesBounds(base_directory, base_file, extension)

	local icon = "icon16/sound.png"

	if string.find(base_file, "music") or string.find(base_file, "theme") then
		icon = "icon16/music.png"
	elseif string.find(base_file, "loop") then
		icon = "icon16/arrow_rotate_clockwise.png"
	end

	if base_directory == "materials" then
		icon = "icon16/paint_can.png"
	elseif base_directory == "models" then
		icon = "materials/spawnicons/"..string.gsub(base_file, ".mdl", "")..".png"
	end

	local pnl2
	local menu2
	--print(base_file , #tbl.all_paths)
	if #tbl.all_paths > 1 then
		pnl2, menu2 = pnl:AddSubMenu(base_file .. " series", function()
			func(base_file_original .. "." .. extension)
		end)

		if base_directory == "materials" then
			menu2:SetImage("icon16/table_multiple.png")
			--local mat = string.gsub(base_file_original, "." .. string.GetExtensionFromFilename(base_file_original), "")
			--pnl2:AddOption(mat, function() func(base_file_original) end):SetImage("icon16/paint_can.png")
		elseif base_directory == "models" then
			menu2:SetImage(icon)
		elseif base_directory == "sound" then
			--print("\t" .. icon)
			menu2:SetImage(icon)
		end

	else
		if base_directory == "materials" then
			--local mat = string.gsub(base_file_original, "." .. string.GetExtensionFromFilename(base_file_original), "")
			--pnl2:AddOption(mat, function() func(base_file_original) end):SetImage("icon16/paint_can.png")
		elseif base_directory == "models" then

		elseif base_directory == "sound" then
			local snd = base_file_original
			menu2 = pnl:AddOption(snd, function() func(snd) end):SetImage(icon)
		end
	end


	--print(tbl)
	--PrintTable(tbl.all_paths)
	if not tbl then return end
	if #tbl.all_paths > 1 then
		for _,path in ipairs(tbl.all_paths) do
			path_no_trunk = string.gsub(path, base_directory .. "/", "")
			if base_directory == "materials" then
				local mat = string.gsub(path_no_trunk, "." .. string.GetExtensionFromFilename(path_no_trunk), "")
				pnl2:AddOption(mat, function() func(mat) end):SetMaterial(pace.get_unlit_mat(path))

			elseif base_directory == "models" then
				local mdl = path
				pnl2:AddOption(string.GetFileFromFilename(mdl), function() func(mdl) end):SetImage("materials/spawnicons/"..string.gsub(mdl, ".mdl", "")..".png")

			elseif base_directory == "sound" then
				local snd = path_no_trunk
				pnl2:AddOption(snd, function() func(snd) end):SetImage(icon)
			end
		end
	end



end

local function get_files_recursively(tbl, path, extension)
	local returning_call = false
	if not tbl then returning_call = true tbl = {} end
	local files, folders = file.Find(path .. "/*", "GAME")
	for _,file in ipairs(files) do
		if istable(extension) then
			for _,ext in ipairs(extension) do
				if string.GetExtensionFromFilename(file) == ext then
					table.insert(tbl, path.."/"..file)
				end
			end
		elseif string.GetExtensionFromFilename(file) == extension then
			table.insert(tbl, path.."/"..file)
		end
	end
	for _,folder in ipairs(folders) do get_files_recursively(tbl, path.."/"..folder, extension) end
	if returning_call then return tbl end
end

local function DefineMoreOptionsLeftClick(self, callFuncLeft, callFuncRight)
	local btn = vgui.Create("DButton", self)
	btn:SetSize(16, 16)
	btn:Dock(RIGHT)
	btn:SetText("...")
	btn.DoClick = function() callFuncLeft(self, self.CurrentKey) end
	btn.PerformLayout = function() btn:SetWide(self:GetTall()) end

	if callFuncRight then
		btn.DoRightClick = function() callFuncRight(self, self.CurrentKey) end
	else
		btn.DoRightClick = btn.DoClick
	end

	if self.OnMoreOptionsLeftClickButton then
		self:OnMoreOptionsLeftClickButton(btn)
	end

	return btn
end

local function populate_bookmarks(menu, mode, self)
	if mode == "models" then
		pace.bookmarked_ressources = pace.bookmarked_ressources or {}
		if not pace.bookmarked_ressources["models"] then
			pace.bookmarked_ressources["models"] = {
				"models/pac/default.mdl",
				"models/pac/plane.mdl",
				"models/pac/circle.mdl",
				"models/hunter/blocks/cube025x025x025.mdl",
				"models/editor/axis_helper.mdl",
				"models/editor/axis_helper_thick.mdl"
			}
		end

		local menu2, pnl = menu:AddSubMenu(L"Load favourite models", function()
		end)
		pnl:SetImage("icon16/cart_go.png")

		local pm = pace.current_part:GetPlayerOwner():GetModel()
		local pm_selected = player_manager.TranslatePlayerModel(GetConVar("cl_playermodel"):GetString())

		if pm_selected ~= pm then
			menu2:AddOption("Selected playermodel - " .. string.gsub(string.GetFileFromFilename(pm_selected), ".mdl", ""), function()
				pace.current_part:SetModel(pm_selected)
				pace.current_part.pace_properties["Model"]:SetValue(pm_selected)
				pace.PopulateProperties(pace.current_part)

			end):SetImage("materials/spawnicons/"..string.gsub(pm_selected, ".mdl", "")..".png")
		end

		if IsValid(pace.current_part:GetRootPart():GetOwner()) then
			local root_model = pace.current_part:GetRootPart():GetOwner():GetModel()
			if root_model ~= pm then
				if not file.Exists("materials/spawnicons/"..string.gsub(root_model, ".mdl", "")..".png", "GAME") then
					pace.FlashNotification("missing spawn icon")
					local spawnicon = vgui.Create("SpawnIcon")
					spawnicon:SetPos(0,0)
					spawnicon:SetModel(root_model)
					spawnicon:RebuildSpawnIcon()
					timer.Simple(2, function()
						spawnicon:Remove()
					end)
				end
				local pnl = menu2:AddOption("root owner model - " .. string.gsub(string.GetFileFromFilename(root_model), ".mdl", ""), function()
					pace.current_part:SetModel(root_model)
					pace.current_part.pace_properties["Model"]:SetValue(root_model)
					pace.PopulateProperties(pace.current_part)

				end)
				pnl:SetImage("materials/spawnicons/"..string.gsub(root_model, ".mdl", "")..".png")
				timer.Simple(0, function()
					pnl:SetImage("materials/spawnicons/"..string.gsub(root_model, ".mdl", "")..".png")
				end)
			end
		end
		
		menu2:AddOption("Active playermodel - " .. string.gsub(string.GetFileFromFilename(pm), ".mdl", ""), function()
			pace.current_part:SetModel(pm)
			pace.current_part.pace_properties["Model"]:SetValue(pm)
			pace.PopulateProperties(pace.current_part)
		end):SetImage("materials/spawnicons/"..string.gsub(pm, ".mdl", "")..".png")

		if IsValid(pac.LocalPlayer:GetActiveWeapon()) then
			local wep = pac.LocalPlayer:GetActiveWeapon()
			local wep_mdl = wep:GetModel()
			menu2:AddOption("Active weapon - " .. wep:GetClass() .. " - model - " .. string.gsub(string.GetFileFromFilename(wep_mdl), ".mdl", ""), function()
				pace.current_part:SetModel(wep_mdl)
				pace.current_part.pace_properties["Model"]:SetValue(wep_mdl)
				pace.PopulateProperties(pace.current_part)
			end):SetImage("materials/spawnicons/"..string.gsub(wep_mdl, ".mdl", "")..".png")
		end

		for id,mdl in ipairs(pace.bookmarked_ressources["models"]) do
			if string.sub(mdl, 1, 7) == "folder:" then
				mdl = string.sub(mdl, 8, #mdl)
				local menu3, pnl2 = menu2:AddSubMenu(string.GetFileFromFilename(mdl), function()
				end)
				pnl2:SetImage("icon16/folder.png")

				local files = get_files_recursively(nil, mdl, "mdl")

				for i,file in ipairs(files) do
					menu3:AddOption(string.GetFileFromFilename(file), function()
						self:SetValue(file)
						pace.current_part:SetModel(file)
						timer.Simple(0.2, function()
							pace.current_part.pace_properties["Model"]:SetValue(file)
							pace.PopulateProperties(pace.current_part)
						end)
					end):SetImage("materials/spawnicons/"..string.gsub(file, ".mdl", "")..".png")
				end
			else
				menu2:AddOption(string.GetFileFromFilename(mdl), function()
					self:SetValue(mdl)
					pace.current_part:SetModel(mdl)
					timer.Simple(0.2, function()
						pace.current_part.pace_properties["Model"]:SetValue(mdl)
						pace.PopulateProperties(pace.current_part)
					end)
				end):SetImage("materials/spawnicons/"..string.gsub(mdl, ".mdl", "")..".png")
			end
		end
	elseif mode == "materials" then
		pace.bookmarked_ressources = pace.bookmarked_ressources or {}
		if not pace.bookmarked_ressources["materials"] then
			pace.bookmarked_ressources["materials"] = {
				"models/debug/debugwhite.vmt",
				"vgui/null.vmt",
				"debug/env_cubemap_model.vmt",
				"models/wireframe.vmt",
				"cable/physbeam.vmt",
				"cable/cable2.vmt",
				"effects/tool_tracer.vmt",
				"effects/flashlight/logo.vmt",
				"particles/flamelet[1,5]",
				"sprites/key_[0,9]",
				"vgui/spawnmenu/generating.vmt",
				"vgui/spawnmenu/hover.vmt",
				"metal"
			}
		end

		local menu2, pnl = menu:AddSubMenu(L"Load favourite materials", function()
		end)
		pnl:SetImage("icon16/cart_go.png")

		for id,mat in ipairs(pace.bookmarked_ressources["materials"]) do
			mat = string.gsub(mat, "^materials/", "")
			local mat_no_ext = string.StripExtension(mat)

			if string.sub(mat, 1, 7) == "folder:" then
				local path = string.sub(mat, 8, #mat)
				local menu3, pnl2 = menu2:AddSubMenu(string.GetFileFromFilename(path), function()
				end)
				pnl2:SetImage("icon16/folder.png") pnl2:SetTooltip(mat)

				local files = get_files_recursively(nil, path, {"vmt"})

				for i,file in ipairs(files) do
					local mat_no_ext = string.StripExtension(string.sub(file,11,#file)) --"materials/"
					menu3:AddOption(mat_no_ext, function()
						self:SetValue(mat_no_ext)
						if self.CurrentKey == "Material" then
							pace.current_part:SetMaterial(mat_no_ext)
						elseif self.CurrentKey == "SpritePath" then
							pace.current_part:SetSpritePath(mat_no_ext)
						end
					end):SetMaterial(mat_no_ext)
				end
			elseif string.find(mat, "%[%d+,%d+%]") then --find the bracket notation
				mat_no_ext = string.gsub(mat_no_ext, "%[%d+,%d+%]", "")
				pace.AddSubmenuWithBracketExpansion(menu2, function(str)
					str = str or ""
					str = string.StripExtension(string.gsub(str, "^materials/", ""))
					self:SetValue(str)
					if self.CurrentKey == "Material" then
						pace.current_part:SetMaterial(str)
					elseif self.CurrentKey == "SpritePath" then
						pace.current_part:SetSpritePath(str)
					end
				end, mat_no_ext, "vmt", "materials")

			else
				menu2:AddOption(string.StripExtension(mat), function()
					self:SetValue(mat_no_ext)
					if self.CurrentKey == "Material" then
						pace.current_part:SetMaterial(mat_no_ext)
					elseif self.CurrentKey == "SpritePath" then
						pace.current_part:SetSpritePath(mat_no_ext)
					end
				end):SetMaterial(mat)
			end

		end

		local pac_materials = {}
		local has_pac_materials = false

		local class_shaders = {
			["material"] = "VertexLitGeneric",
			["material_3d"] = "VertexLitGeneric",
			["material_2d"] = "UnlitGeneric",
			["material_eye refract"] = "EyeRefract",
			["material_refract"] = "Refract",
		}

		for _,part in pairs(pac.GetLocalParts()) do
			if part.Name ~= "" and string.find(part.ClassName, "material") then
				if pac_materials[class_shaders[part.ClassName]] == nil then pac_materials[class_shaders[part.ClassName]] = {} end
				has_pac_materials = true
				pac_materials[class_shaders[part.ClassName]][part:GetName()] = {part = part, shader = class_shaders[part.ClassName]}
			end
		end
		if has_pac_materials then
			menu2:AddSpacer()
			for shader,mats in pairs(pac_materials) do
				local shader_submenu = menu2:AddSubMenu("pac3 materials - " .. shader)
				for mat,tbl in pairs(mats) do
					local part = tbl.part
					local pnl2 = shader_submenu:AddOption(mat, function()
						self:SetValue(mat)
						if self.CurrentKey == "Material" then
							pace.current_part:SetMaterial(mat)
						elseif self.CurrentKey == "SpritePath" then
							pace.current_part:SetSpritePath(mat)
						end
					end)
					pnl2:SetMaterial(pac.Material(mat, part))
					pnl2:SetTooltip(tbl.shader)
				end
			end
		end

		if self.CurrentKey == "Material" and pace.current_part.ClassName == "particles" then
			pnl:SetTooltip("Appropriate shaders for particles are UnlitGeneric materials.\nOOtherwise, they should usually be additive or use VertexAlpha")
		elseif self.CurrentKey == "SpritePath" then
			pnl:SetTooltip("Appropriate shaders for sprites are UnlitGeneric materials.\nOOtherwise, they should usually be additive or use VertexAlpha")
		end
	elseif mode == "sound" then
		pace.bookmarked_ressources = pace.bookmarked_ressources or {}
		if not pace.bookmarked_ressources["sound"] then
			pace.bookmarked_ressources["sound"] = {
				"music/hl1_song11.mp3",
				"music/hl2_song23_suitsong3.mp3",
				"music/hl2_song1.mp3",
				"npc/combine_gunship/dropship_engine_near_loop1.wav",
				"ambient/alarms/warningbell1.wav",
				"phx/epicmetal_hard7.wav",
				"phx/explode02.wav"
			}
		end

		local menu2, pnl = menu:AddSubMenu(L"Load favourite sounds", function()
		end)
		pnl:SetImage("icon16/cart_go.png")

		for id,snd in ipairs(pace.bookmarked_ressources["sound"]) do
			local extension = string.GetExtensionFromFilename(snd)
			local snd_no_ext = string.StripExtension(snd)
			local single_menu = not favorites_menu_expansion:GetBool()

			if string.sub(snd, 1, 7) == "folder:" then
				snd = string.sub(snd, 8, #snd)
				local menu3, pnl2 = menu2:AddSubMenu(string.GetFileFromFilename(snd), function()
				end)
				pnl2:SetImage("icon16/folder.png") pnl2:SetTooltip(snd)

				local files = get_files_recursively(nil, snd, {"wav", "mp3", "ogg"})

				for i,file in ipairs(files) do
					file = string.sub(file,7,#file) --"sound/"
					local icon = "icon16/sound.png"
					if string.find(file, "music") or string.find(file, "theme") then
						icon = "icon16/music.png"
					elseif string.find(file, "loop") then
						icon = "icon16/arrow_rotate_clockwise.png"
					end
					local pnl3 = menu3:AddOption(string.GetFileFromFilename(file), function()
						self:SetValue(file)
						if self.CurrentKey == "Sound" then
							pace.current_part:SetSound(file)
						elseif self.CurrentKey == "Path" then
							pace.current_part:SetPath(file)
						end
					end)
					pnl3:SetImage(icon) pnl3:SetTooltip(file)
				end
			elseif string.find(snd_no_ext, "%[%d+,%d+%]") then --find the bracket notation
				pace.AddSubmenuWithBracketExpansion(menu2, function(str)
					self:SetValue(str)
					if self.CurrentKey == "Sound" then
						pace.current_part:SetSound(str)
					elseif self.CurrentKey == "Path" then
						pace.current_part:SetPath(str)
					end
				end, snd_no_ext, extension, "sound")

			elseif not single_menu and string.find(snd_no_ext, "%d+") then	--find a file ending in a number
																			--expand only if we want it with the cvar
				pace.AddSubmenuWithBracketExpansion(menu2, function(str)
					self:SetValue(str)
					if self.CurrentKey == "Sound" then
						pace.current_part:SetSound(str)
					elseif self.CurrentKey == "Path" then
						pace.current_part:SetPath(str)
					end
				end, snd_no_ext, extension, "sound")

			else

				local icon = "icon16/sound.png"

				if string.find(snd, "music") or string.find(snd, "theme") then
					icon = "icon16/music.png"
				elseif string.find(snd, "loop") then
					icon = "icon16/arrow_rotate_clockwise.png"
				end

				menu2:AddOption(snd, function()
					self:SetValue(snd)
					if self.CurrentKey == "Sound" then
						pace.current_part:SetSound(snd)
					elseif self.CurrentKey == "Path" then
						pace.current_part:SetPath(snd)
					end

				end):SetIcon(icon)
			end


		end
	end
end

function pace.CreateSearchList(property, key, name, add_columns, get_list, get_current, add_line, select_value, select_value_search)
	select_value = select_value or function(val, key) return val end
	select_value_search = select_value_search or select_value
	pace.SafeRemoveSpecialPanel()

	local frame = vgui.Create("DFrame")
	frame:SetTitle(L(name))
	frame:SetSize(300, 300)
	frame:Center()
	frame:SetSizable(true)

	local list = vgui.Create("DListView", frame)
	list:Dock(FILL)
	list:SetMultiSelect(false)

	add_columns(list)

	list.OnRowSelected = function(_, id, line)
		local val = select_value(line.list_val, line.list_key)

		if property and property:IsValid() then
			property:SetValue(val)
			property.OnValueChanged(val)
		else
			if pace.current_part:IsValid() and pace.current_part["Set" .. key] then
				pace.Call("VariableChanged", pace.current_part, key, val)
			end
		end
	end

	local first = NULL

	local function build(find)
		list:Clear()

		local cur = get_current()
		local newList = {}

		for k, v in pairs(get_list()) do
			table.insert(newList, {k, v, tostring(k), tostring(v)})
		end

		table.sort(newList, function(a, b) return a[1] < b[1] end)
		if find then find = find:lower() end

		for i, data in ipairs(newList) do
			local key, val, keyFriendly, valFriendly = data[1], data[2], data[3], data[4]
			if (not find or find == "") or tostring(select_value_search(valFriendly, keyFriendly)):lower():find(find, nil, true) then

				local pnl = add_line(list, key, val)
				pnl.list_key = key
				pnl.list_val = val

				if name == "Input" or name == "Function" then --insert proxy function tutorials as tooltips
					pnl:SetTooltip(pace.TUTORIALS["proxy_functions"][key] or "")
				elseif name == "Event" then --insert event tutorials as tooltips
					pnl:SetTooltip(pace.TUTORIALS["events"][key])
				end

				if not first:IsValid() then
					first = pnl
				end

				if cur == name then
					list:SelectItem(pnl)
				end
			end
		end
	end

	local search = vgui.Create("DTextEntry", frame)
	search:Dock(BOTTOM)
	search.OnTextChanged = function() build(search:GetValue()) end
	search.OnEnter = function() if first:IsValid() then list:SelectItem(first) end frame:Remove() end
	search:RequestFocus()
	frame:MakePopup()

	build()

	pace.ActiveSpecialPanel = frame

	return frame
end

pace.ActiveSpecialPanel = NULL
pace.extra_populates = {}

function pace.SafeRemoveSpecialPanel()
	if pace.ActiveSpecialPanel:IsValid() then
		pace.ActiveSpecialPanel:Remove()
	end
end

pac.AddHook("GUIMousePressed", "pace_SafeRemoveSpecialPanel", function()
	local pnl = pace.ActiveSpecialPanel
	if pnl:IsValid() then
		if pnl.ignore_saferemovespecialpanel then return end
		local x,y = input.GetCursorPos()
		local _x, _y = pnl:GetPos()
		if x < _x or y < _y or x > _x + pnl:GetWide() or y > _y + pnl:GetTall() then
			pnl:Remove()
		end
	end
end)

pac.AddHook("PostRenderVGUI", "flash_properties", function()
	if not pace.flashes then return end
	for pnl, tbl in pairs(pace.flashes) do
		if IsValid(pnl) then
			--print(pnl:LocalToScreen(0,0))
			local x,y = pnl:LocalToScreen(0,0)
			local flash_alpha = 255*math.pow(math.Clamp((tbl.flash_end - CurTime()) / 2.5,0,1), 0.6)
			surface.SetDrawColor(Color(tbl.color.r, tbl.color.g, tbl.color.b, flash_alpha))
			local flash_size = 300*math.pow(math.Clamp((tbl.flash_end - 1.8 - CurTime()) / 0.7,0,1), 8) + 5
			if pnl:GetY() > 4 then
				surface.DrawOutlinedRect(-flash_size + x,-flash_size + y,pnl:GetWide() + 2*flash_size,pnl:GetTall() + 2*flash_size,5)
				surface.SetDrawColor(Color(tbl.color.r, tbl.color.g, tbl.color.b, flash_alpha/2))
				surface.DrawOutlinedRect(-flash_size + x - 3,-flash_size + y - 3,pnl:GetWide() + 2*flash_size + 6,pnl:GetTall() + 2*flash_size + 6,2)
			end
			if tbl.flash_end < CurTime() then pace.flashes[pnl] = nil end
		end
	end
end)

do -- container
	local PANEL = {}

	PANEL.ClassName = "properties_container"
	PANEL.Base = "DPanel"

	function PANEL:Paint(w, h)
		--surface.SetDrawColor(255, 255, 255, 255)
		--surface.DrawRect(0,0,w,h)
		--self:GetSkin().tex.CategoryList.Outer(0, 0, w, h)

		--self:GetSkin().tex.MenuBG(0, 0, w + (self.right and -1 or 3), h + 1)

		if not self.right then
			--surface.SetDrawColor(self:GetSkin().Colours.Properties.Border)
			--surface.DrawRect(0,0,w+5,h)
		else
			--surface.SetDrawColor(self:GetSkin().Colours.Properties.Border)
			--surface.DrawRect(0,0,w,h)
		end

		self.AltLine = self.alt_line
		derma.SkinHook( "Paint", "CategoryButton", self, w, h )
	end

	function PANEL:Flash()
		if not IsValid(pace.tree) or not IsValid(pace.properties) then return end
		pace.flashes = pace.flashes or {}
		pace.flashes[self] = {start = CurTime(), flash_end = CurTime() + 2.5, color = Color(255,0,0)}

		do	--scroll to the property
			local _,y = self:LocalToScreen(0,0)
			local _,py = pace.properties:LocalToScreen(0,0)
			local scry = pace.properties.scr:GetScroll()

			if y > ScrH() then
				pace.properties.scr:SetScroll(scry - py + y)
			elseif y < py - 200 then
				pace.properties.scr:SetScroll(scry + (y - py) - 100)
			end
		end

		do	--scroll to the tree node
			if self:GetChildren()[1].part.pace_tree_node then
				pace.tree:ScrollToChild(self:GetChildren()[1].part.pace_tree_node)
			end
		end

	end

	function PANEL:SetContent(pnl)
		pnl:SetParent(self)
		self.content = pnl
	end

	function PANEL:PerformLayout()
		local pnl = self.content or NULL
		if pnl:IsValid() then
			pnl:SetPos(0, 0)
			pnl:SetSize(self:GetSize())
		end
	end

	function PANEL:CreateAlternateLabel(str, no_offset)
		if not str then
			if self.alt_label then
				if IsValid(self.alt_label) then
					self.alt_label:Remove()
				end
			end
			return
		end
		if str == "" then return end
		self.alt_label = vgui.Create("DLabel", self)
		self.alt_label:SetText("<" .. L(str) .. ">")
		if pace.special_property_text_color then self.alt_label:SetTextColor(pace.special_property_text_color)
		else self.alt_label:SetTextColor(self.alt_line and self:GetSkin().Colours.Category.AltLine.Text or self:GetSkin().Colours.Category.Line.Text) end
		self.alt_label:SetPos(no_offset and 0 or 60,-1)
		self.alt_label:SetSize(200,20)
		self.alt_label:SetFont(pace.CurrentFont)
		return self.alt_label
	end

	pace.RegisterPanel(PANEL)
end

do -- list
	local PANEL = {}

	PANEL.ClassName = "properties"
	PANEL.Base = "Panel"

	AccessorFunc(PANEL, "item_height", "ItemHeight")

	function PANEL:Init()

		local search = vgui.Create("DTextEntry", self)
		search:Dock(TOP)
		search.Kill = function()
			search:SetVisible(false)
			search.searched_something = false
			search:SetText("")
			search:SetEnabled(false)

			for i,v in ipairs(self.List) do
				v.left:SetVisible(true)
				v.right:SetVisible(true)
			end
		end

		search.OnEnter = search.Kill

		search.OnTextChanged = function()
			self.scr:SetScroll(0)

			local pattern = search:GetValue()
			if pattern == "" and search.searched_something then
				search:Kill()
				search:KillFocus()
				pace.Editor:KillFocus()
				pace.Editor:MakePopup()
			else
				search.searched_something = true
				local group

				for i,v in ipairs(self.List) do
					local found = false

					if v.panel then
						if v.panel:GetText():find(pattern) then
							found = true
						end

						if v.left:GetValue():find(pattern) then
							found = true
						end
					elseif v.left and v.left.text then
						group = v.left.text
					end

					if group and group:find(pattern) then
						found = true
					end

					if not found and v.panel then
						v.left:SetVisible(false)
						v.right:SetVisible(false)
					end
				end

				for i,v in ipairs(self.List) do
					if not v.panel then
						local hide_group = true

						for i = i+1, #self.List do
							local val = self.List[i]
							if not val.panel then
								break
							end

							if val.left:IsVisible() then
								hide_group = false
								break
							end
						end

						if hide_group then
							v.left:SetVisible(false)
							v.right:SetVisible(false)
						end
					end
				end
			end
		end
		search:SetVisible(false)
		self.search = search

		self.List = {}

		local divider = vgui.Create("DHorizontalDivider", self)

		local left = vgui.Create("DPanelList", divider)
			divider:SetLeft(left)
		self.left = left

		local right = vgui.Create("DPanelList", divider)
			divider:SetRight(right)
		self.right = right

		divider:SetDividerWidth(3)

		surface.SetFont(pace.CurrentFont)
		local w,h = surface.GetTextSize("W")
		local size = h + 2

		self:SetItemHeight(size)

		self.div = divider

		function divider:PerformLayout()
			DHorizontalDivider.PerformLayout(self)

			if self.m_pLeft then
				self.m_pLeft:SetWide( self.m_iLeftWidth + self.m_iDividerWidth )
			end
		end

		local scroll = vgui.Create("DVScrollBar", self)
		scroll:Dock(RIGHT)
		self.scr = scroll

		left.OnMouseWheeled = function(_, delta) scroll:OnMouseWheeled(delta) end
		--right.OnMouseWheeled = function(_, delta) scroll:OnMouseWheeled(delta) end
	end

	function PANEL:GetHeight(hack)
		return (self.item_height * (#self.List+(hack or 1))) - (self.div:GetDividerWidth() + 1)
	end

	function PANEL:PerformLayout()
		self.scr:SetSize(10, self:GetHeight())
		self.scr:SetUp(self:GetTall(), self:GetHeight() - 10)
		self.search:SetZPos(1)
		self.div:SetPos(0, (self.search:IsVisible() and self.search:GetTall() or 0) + self.scr:GetOffset())
		local w, h = self:GetSize()
		local scroll_width = self.scr.Enabled and self.scr:GetWide() or 0
		self.div:SetLeftWidth((w/2) - scroll_width)
		self.div:SetSize(w - scroll_width, self:GetHeight())
	end

	function PANEL:Paint(w, h)
		self:GetSkin().tex.CategoryList.Outer(0, 0, w, h)
	end

	pace.CollapsedProperties = pace.luadata.ReadFile("pac3_editor/collapsed.txt") or {}

	function PANEL:AddCollapser(name)
		assert(name)
		for i,v in ipairs(self.List) do
			if v.group == name then
				return
			end
		end

		local left = vgui.Create("DButton", self)
		left:SetTall(self:GetItemHeight())
		left:SetText("")
		left.text = name

		self.left:AddItem(left)

		left.DoClick = function()
			pace.CollapsedProperties[name] = not pace.CollapsedProperties[name]
			pace.PopulateProperties(pace.current_part)

			pace.Editor:InvalidateLayout()
			pace.luadata.WriteFile("pac3_editor/collapsed.txt", pace.CollapsedProperties)
		end

		left.GetValue = function() return name end

		local right = vgui.Create("DButton", self)
		right:SetTall(self:GetItemHeight())
		right:SetText("")
		self.right:AddItem(right)

		right.DoClick = left.DoClick

		left.Paint = function(_, w, h)
			--surface.SetDrawColor(left:GetSkin().Colours.Category.Header)
			--surface.DrawRect(0,0,w*2,h)
			left:GetSkin().tex.CategoryList.Header( 0, 0, w*2, h )

			surface.SetFont(pace.CurrentFont)

			local txt = L(name)
			local _, _h = surface.GetTextSize(txt)
			local middle = h/2 - _h/2

			--surface.SetTextPos(11, middle)
			--surface.SetTextColor(derma.Color("text_dark", self, color_black))
			--surface.SetFont(pace.CurrentFont)
			--surface.DrawText(txt)
			draw.TextShadow({text = txt, font = pace.CurrentFont, pos = {11, middle}, color = left:GetSkin().Colours.Category.Header}, 1, 100)

			local txt = (pace.CollapsedProperties[name] and "+" or "-")
			local w = surface.GetTextSize(txt)
			draw.TextShadow({text = txt, font = pace.CurrentFont, pos = {6-w*0.5, middle}, color = left:GetSkin().Colours.Category.Header}, 1, 100)

		end

		right.Paint = function(_,w,h)
			left:GetSkin().tex.CategoryList.Header(-w,0,w*2,h)
		end

		table.insert(self.List, {left = left, right = right, panel = var, key = key, group = name})

		return #self.List
	end

	function PANEL:AddKeyValue(key, var, pos, obj, udata, group)
		local btn = pace.CreatePanel("properties_label")
			btn:SetTall(self:GetItemHeight())

			--description tooltips should be on the text label. they are broken on every type except boolean.
			if udata and udata.description then
				btn:SetTooltip(udata.description)
			end
			do
				local key = key
				if key:EndsWith("UID") then
					key = key:sub(1, -4)
				end

				btn:SetValue(L((udata and udata.editor_friendly or key):gsub("%u", " %1"):lower()):Trim())
				pace.current_part["pac_property_label_"..key] = btn
				if udata then
					if udata.group == "bodygroups" then
						if key[1] == "_" then --bodygroup exceptions
							btn.lbl:SetText(key:sub(2,-1))
						end
					end
				end
			end
			
			if obj then
				btn.key_name = key
				btn.part_namepart_name = obj.ClassName
			end



		local pnl = pace.CreatePanel("properties_container")
		pnl:SetTall(self:GetItemHeight())
		pnl.right = true
		pnl.alt_line = #self.List%2 == 1
		btn.alt_line = pnl.alt_line

		if ispanel(var) then
			pnl:SetContent(var)
			pace.current_part["pac_property_panel_"..key] = var

			if key == "Hide" then
				local reasons_hidden = pace.current_part:GetReasonsHidden()
				if not table.IsEmpty(reasons_hidden) then
					pnl:SetTooltip("Hidden by:" .. table.ToString(reasons_hidden, "", true))
					local label = pnl:CreateAlternateLabel("hidden")

					local goto_btn = vgui.Create("DButton", pnl)
					goto_btn:SetText("")
					goto_btn:SetTooltip("jump to...")
					goto_btn:SetSize(self:GetItemHeight(), self:GetItemHeight())
					goto_btn:Dock(RIGHT)
					goto_btn:SetImage("icon16/arrow_turn_right.png")

					goto_btn.DoClick = function()
						local menu = DermaMenu()
						menu:SetPos(input.GetCursorPos())
						for part,reason in pairs(reasons_hidden) do
							if part ~= pace.current_part then
								menu:AddOption("jump to " .. tostring(part), function()
									pace.GoToPart(part)
								end):SetImage("icon16/arrow_turn_right.png")
							end
						end
						menu:MakePopup()
					end
				end
				pace.current_part.hide_property_pnl = var
			elseif key == "Model" then
				local btn2 = vgui.Create("DImageButton", pnl)
				btn2:SetSize(self:GetItemHeight(), self:GetItemHeight())
				btn2:Dock(RIGHT) pnl:DockPadding(0,0,self:GetItemHeight(),0)
				btn2:SetTooltip("bookmarks")
				btn2:SetImage("icon16/cart_go.png")
				btn2.DoClick = function()
					local menu = DermaMenu()
					menu:SetPos(input.GetCursorPos())
					menu:MakePopup()
					populate_bookmarks(menu, "models", var)
				end
			elseif key == "Material" or key == "SpritePath" then
				local btn2 = vgui.Create("DImageButton", pnl)
				btn2:SetSize(self:GetItemHeight(), self:GetItemHeight())
				btn2:Dock(RIGHT) pnl:DockPadding(0,0,self:GetItemHeight(),0)
				btn2:SetTooltip("bookmarks")
				btn2:SetImage("icon16/cart_go.png")
				btn2.DoClick = function()
					local menu = DermaMenu()
					menu:SetPos(input.GetCursorPos())
					menu:MakePopup()
					populate_bookmarks(menu, "materials", var)
				end
			elseif string.find(pace.current_part.ClassName, "sound") then
				if key == "Sound" or key == "Path" then
					local btn2 = vgui.Create("DImageButton", pnl)
					btn2:SetSize(self:GetItemHeight(), self:GetItemHeight())
					btn2:Dock(RIGHT) pnl:DockPadding(0,0,self:GetItemHeight(),0)
					btn2:SetTooltip("bookmarks")
					btn2:SetImage("icon16/cart_go.png")
					btn2.DoClick = function()
						local menu = DermaMenu()
						menu:SetPos(input.GetCursorPos())
						menu:MakePopup()
						populate_bookmarks(menu, "sound", var)
					end
				end
			end
		end

		self.left:AddItem(btn)
		self.right:AddItem(pnl)

		local pos

		if group then
			for i, v in ipairs(self.List) do
				if v.group == group then
					for i = i + 1, #self.List do
						local v = self.List[i]
						if v.group or not v then
							pos = i
							break
						end
					end
				end
			end
		end

		if pos then
			table.insert(self.left.Items, pos, table.remove(self.left.Items))
			table.insert(self.right.Items, pos, table.remove(self.right.Items))

			table.insert(self.List, pos, {left = btn, right = pnl, panel = var, key = key})
		else
			table.insert(self.List, {left = btn, right = pnl, panel = var, key = key})
		end
	end

	function PANEL:Clear()
		if pace.bypass_tree then return end
		for key, data in pairs(self.List) do
			data.left:Remove()
			data.right:Remove()
		end

		self.left:Clear()
		self.right:Clear()

		self.List = {}
	end

	local function FlatListToGroups(list)
		local temp = {}

		for _, prop in ipairs(list) do
			if prop.udata.hidden then continue end

			local group = prop.udata.group or "generic"
			temp[group] = temp[group] or {}
			table.insert(temp[group], prop)
		end

		return temp
	end

	local function SortGroups(groups)
		local out = {}

		local temp = {}
		table.Add(temp, pac.GroupOrder[pace.current_part.ClassName] or {})
		table.Add(temp, pac.GroupOrder.none)
		local done = {}
		for i, name in ipairs(temp) do
			for group, props in pairs(groups) do
				if group == name then
					if not done[group] then
						table.insert(out, {group = group, props = props})
						done[group] = true
					end
				end
			end
		end

		for group, props in pairs(groups) do
			if not done[group] then
				table.insert(out, {group = group, props = props})
			end
		end

		return out
	end

	function PANEL:Populate(flat_list)
		if pace.bypass_tree then return end
		self:Clear()

		for _, data in ipairs(SortGroups(FlatListToGroups(flat_list))) do
			self:AddCollapser(data.group or "generic")
			for pos, prop in ipairs(data.props) do

				if prop.udata and prop.udata.hide_in_editor then
					continue
				end

				local val = prop.get()
				local T = type(val):lower()

				if prop.udata and prop.udata.editor_panel then
					T = prop.udata.editor_panel or T
				elseif pace.PanelExists("properties_" .. prop.key:lower()) then
					--is it code bloat to fix weird edge cases like bodygroups on specific models???
					--idk but it's more egregious to allow errors just because of what bodygroups the model has
					if prop.key:lower() ~= "container" then
						T = prop.key:lower()
					end
				elseif not pace.PanelExists("properties_" .. T) then
					T = "string"
				end

				if pace.CollapsedProperties[prop.udata.group] ~= nil and pace.CollapsedProperties[prop.udata.group] then goto CONTINUE end

				local pnl = pace.CreatePanel("properties_" .. T)

				if pnl.PostInit then
					pnl:PostInit()
				end

				if prop.udata and prop.udata.description then
					pnl:SetTooltip(L(prop.udata.description))
				end

				local part = pace.current_part
				part.pace_properties = part.pace_properties or {}
				part.pace_properties[prop.key] = pnl
				pnl.part = part
				pnl.udata = prop.udata

				if prop.udata.enums then
					DefineMoreOptionsLeftClick(pnl, function(self)
						pace.CreateSearchList(
							self,
							self.CurrentKey,
							L(prop.key),

							function(list)
								list:AddColumn("enum")
							end,

							function()
								local tbl

								if isfunction(prop.udata.enums) then
									if pace.current_part:IsValid() then
										tbl = prop.udata.enums(pace.current_part)
									end
								else
									tbl = prop.udata.enums
								end

								local enums = {}

								if tbl then
									for k, v in pairs(tbl) do
										if not isstring(v) then
											v = k
										end

										if not isstring(k) then
											k = v
										end

										enums[k] = v
									end
								end

								return enums
							end,

							function()
								return pace.current_part[prop.key]
							end,

							function(list, key, val)
								return list:AddLine(key)
							end,

							function(val, key)
								return val
							end
						)
					end)
				end
				if prop.udata.editor_sensitivity or prop.udata.editor_clamp or prop.udata.editor_round then
					pnl.LimitValue = function(self, num)
						if prop.udata.editor_sensitivity then
							self.sens = prop.udata.editor_sensitivity
						end
						if prop.udata.editor_clamp then
							num = math.Clamp(num, unpack(prop.udata.editor_clamp))
						end
						if prop.udata.editor_round then
							num = math.Round(num)
						end
						return num
					end
				elseif prop.udata.editor_onchange then
					pnl.LimitValue = prop.udata.editor_onchange
				end

				pnl.CurrentKey = prop.key

				if pnl.ExtraPopulate then
					table.insert(pace.extra_populates, {pnl = pnl, func = pnl.ExtraPopulate})
					pnl:Remove()
					goto CONTINUE
				end

				pnl:SetValue(val)

				pnl.OnValueChanged = function(val)
					if T == "number" then
						val = tonumber(val) or 0
					elseif T == "string" then
						val = tostring(val)
					end

					pace.Call("VariableChanged", pace.current_part, prop.key, val)
				end

				self:AddKeyValue(prop.key, pnl, pos, flat_list, prop.udata)

				::CONTINUE::
			end
		end
	end

	pace.RegisterPanel(PANEL)
end

do -- non editable string
	local DTooltip = _G.DTooltip
	if DTooltip and DTooltip.PositionTooltip then
		pace_Old_PositionTooltip = pace_Old_PositionTooltip or DTooltip.PositionTooltip
		function DTooltip.PositionTooltip(self, ...)
			if self.TargetPanel.pac_tooltip_hack then
				local args = {pace_Old_PositionTooltip(self, ...)}

				if (  not IsValid( self.TargetPanel ) ) then
					self:Remove()
					return;
				end

				self:PerformLayout()

				local x, y      = input.GetCursorPos()
				local w, h      = self:GetSize()

				local lx, ly    = self.TargetPanel:LocalToScreen( 0, 0 )

				y = math.min( y, ly - h )

				self:SetPos( x, y )


				return unpack(args)
			end

			return pace_Old_PositionTooltip(self, ...)
		end
	end


	local PANEL = {}

	PANEL.ClassName = "properties_label"
	PANEL.Base = "pace_properties_container"

	function PANEL:SetValue(str)
		local lbl = vgui.Create("DLabel")
			lbl:SetTextColor(self.alt_line and self:GetSkin().Colours.Category.AltLine.Text or self:GetSkin().Colours.Category.Line.Text)
			lbl:SetFont(pace.CurrentFont)
			lbl:SetText(str)
			lbl:SetTextInset(10, 0)
			lbl:SizeToContents()
			lbl.pac_tooltip_hack = true
			self.lbl = lbl
		self:SetContent(lbl)

		if self.part_name and self.key_name then
			lbl.OnCursorEntered = function()

				if lbl.wiki_info then
					lbl:SetTooltip(lbl.wiki_info)
					return
				end

				if not lbl.fetching_wiki then
					lbl:SetCursor("waitarrow")
					pace.GetPropertyDescription(self.part_name, self.key_name, function(str)
						if lbl:IsValid() then
							lbl:SetTooltip(str)
							ChangeTooltip(lbl)
							lbl.wiki_info = str
							lbl:SetCursor("arrow")
						end
					end)
					lbl.fetching_wiki = true
				end
			end
		end
	end

	function PANEL:GetValue()
		return self.lbl:GetValue()
	end

	pace.RegisterPanel(PANEL)
end

local position_multicopy_properties = {
	["Position"] = true,
	["Angles"] = true,
	["PositionOffset"] = true,
	["AngleOffset"] = true,
}
local appearance_multicopy_properties = {
	["Material"] = true,
	["Color"] = true,
	["Brightness"] = true,
	["Alpha"] = true,
	["Translucent"] = true,
	["BlendMode"] = true
}

local function install_movable_multicopy(copymenu, key)
	if position_multicopy_properties[key] then
		copymenu:AddOption("Copy Angles & Position", function()
			pace.MultiCopy(pace.current_part, {"Angles", "Position"})
		end)
		copymenu:AddOption("Copy Angle & Position Offsets", function()
			pace.MultiCopy(pace.current_part, {"AngleOffset", "PositionOffset"})
		end)
		copymenu:AddOption("Copy Angle & Position and their Offsets", function()
			pace.MultiCopy(pace.current_part, {"Angles", "Position", "AngleOffset", "PositionOffset"})
		end)
		copymenu:AddOption("Copy Angles & Angle Offset", function()
			pace.MultiCopy(pace.current_part, {"Angles", "AngleOffset"})
		end)
		copymenu:AddOption("Copy Position & Position Offset", function()
			pace.MultiCopy(pace.current_part, {"Position", "PositionOffset"})
		end)
	end
end
local function install_appearance_multicopy(copymenu, key)
	if appearance_multicopy_properties[key] then
		copymenu:AddOption("Material & Color", function()
			pace.MultiCopy(pace.current_part, {"Material", "Color"})
		end)
		copymenu:AddOption("Material & Color & Brightness", function()
			pace.MultiCopy(pace.current_part, {"Material", "Color", "Brightness"})
		end)
		copymenu:AddOption("Transparency", function()
			pace.MultiCopy(pace.current_part, {"Alpha", "Translucent", "BlendMode"})
		end):SetTooltip("Alpha, Translucent, Blend mode")
		copymenu:AddOption("Copy Material & Color & Alpha", function()
			pace.MultiCopy(pace.current_part, {"Material", "Color", "Alpha"})
		end)
		copymenu:AddOption("All appearance-related properties", function()
			pace.MultiCopy(pace.current_part, {"Material", "Color", "Brightness", "Alpha", "Translucent", "BlendMode"})
		end):SetTooltip("Material, Color, Brightness, Alpha, Translucent, Blend mode")
	end
end
local function reformat_color(col, proper_in, proper_out)
	local multiplier = 1
	if not proper_in then multiplier = multiplier / 255 end
	if not proper_out then multiplier = multiplier * 255 end
	col.r = math.Clamp(col.r * multiplier,0,255)
	col.g = math.Clamp(col.g * multiplier,0,255)
	col.b = math.Clamp(col.b * multiplier,0,255)
	col.a = math.Clamp(col.a * multiplier,0,255)
	return col
end
local function do_multicopy()
	if not pace.multicopy_source or not pace.multicopy_selected_properties then return end
	for i,v in ipairs(pace.multicopy_selected_properties) do
		local key = v[1]
		local val = v[2] if not val then continue end if val == "" then continue end
		if pace.current_part["Set"..key] then
			if key == "Color" then
				local color = pace.multicopy_source:GetColor()
				local color_copy = Color(color.r,color.g,color.b)
				reformat_color(color_copy, pace.multicopy_source.ProperColorRange, pace.current_part.ProperColorRange)
				local vec = Vector(color_copy.r,color_copy.g,color_copy.b)
				pace.current_part["Set"..key](pace.current_part,vec)
			else
				pace.current_part["Set"..key](pace.current_part,val)
			end
		end
	end
end

do -- base editable
	local PANEL = {}


	PANEL.ClassName = "properties_base_type"
	PANEL.Base = "DLabel"

	PANEL.SingleClick = true

	function PANEL:Flash()
		--redirect to the parent (container)
		self:GetParent():Flash()
	end

	function PANEL:OnCursorMoved()
		self:SetCursor("hand")
	end

	function PANEL:OnValueChanged()

	end

	function PANEL:Init(...)
		self.pac_property_panel = self
		if DLabel and DLabel.Init then
			local status = DLabel.Init(self, ...)
			self:SetText('')
			self:SetMouseInputEnabled(true)
			return status
		end

		return status
	end

	function PANEL:PostInit()
		if self.MoreOptionsLeftClick then
			self:DefineMoreOptionsLeftClick(self.MoreOptionsLeftClick, self.MoreOptionsRightClick)
		end
	end

	function PANEL:DefineMoreOptionsLeftClick(callFuncLeft, callFuncRight)
		return DefineMoreOptionsLeftClick(self, callFuncLeft, callFuncRight)
	end

	function PANEL:SetValue(var, skip_encode)
		if self.editing then return end

		local value = skip_encode and var or self:Encode(var)
		if isnumber(value) then
			-- visually round numbers so 0.6 doesn't show up as 0.600000000001231231 on wear
			value = math.Round(value, 7)
		end
		local str = tostring(value) --this is the text that will end up on the display
		local original_str = string.Trim(str,"\n") --this is the minimally-altered text that will remain as the internal value
		local lines = string.Explode("\n", original_str)
		if #lines > 1 then
			str = "<multiple lines>"
		end

		self:SetTextColor(self.alt_line and self:GetSkin().Colours.Category.AltLine.Text or self:GetSkin().Colours.Category.Line.Text)
		if str == "<multiple lines>" or self.used_by_proxy then
			if pace.special_property_text_color then
				self:SetTextColor(pace.special_property_text_color)
			end
		end

		self:SetFont(pace.CurrentFont)
		self:SetText("  " .. string.Trim(str,"\n")) -- ugh
		self:SizeToContents()

		if #str > 10 then
			self:SetTooltip(original_str)
		else
			self:SetTooltip()
		end

		self.original_str = original_str
		self.original_var = var

		if self.OnValueSet then
			self:OnValueSet(var)
		end
	end

	-- kind of a hack
	local last_focus = NULL

	function PANEL:OnMousePressed(mcode)
		if last_focus:IsValid() then
			last_focus:Reset()
			last_focus = NULL
		end

		if mcode == MOUSE_LEFT then
			--if input.IsKeyDown(KEY_R) then
			--  self:Restart()
			--else
				self.MousePressing = true
				if self:MousePress(true) == false then return end
				if self.SingleClick or (self.last_press or 0) > RealTime() then
					self:EditText()
					self:DoubleClick()
					self.last_press = 0

					last_focus = self
				else
					self.last_press = RealTime() + 0.2
				end
			--end
		end

		if mcode == MOUSE_RIGHT then
			local menu = DermaMenu()
			menu:SetPos(input.GetCursorPos())
			menu:MakePopup()
			self:PopulateContextMenu(menu)
		end
	end

	function pace.MultiCopy(part, tbl)
		pace.clipboardtooltip = ""
		pace.multicopy_selected_properties = {}
		local str_tbl = {[1] = "multiple properties from " .. tostring(part)}
		for i,v in ipairs(tbl) do
			if part["Get"..v] then
				local val = part["Get" .. v](part)
				table.insert(pace.multicopy_selected_properties, {v, val})
				table.insert(str_tbl,v .. " : " .. tostring(val))
			end
		end
		pace.clipboardtooltip = table.concat(str_tbl, "\n")
		pace.multicopying = true
		pace.multicopy_source = part
	end
	function PANEL:PopulateContextMenu(menu)
		if self.user_proxies then
			for _,part in pairs(self.user_proxies) do
				menu:AddOption("jump to " .. tostring(part), function()
					pace.GoToPart(part)
				end):SetImage("icon16/arrow_turn_right.png")
			end
		end

		if self.udata and self.udata.editor_panel == "part" then
			if self:GetValue() ~= "" then
				local part = pac.GetPartFromUniqueID(pac.Hash(pac.LocalPlayer), self:GetValue())
				if IsValid(part) then
					menu:AddOption("jump to " .. tostring(part), function()
						pace.GoToPart(part)
					end):SetImage("icon16/arrow_turn_right.png")
				end
			end
		end

		pace.clipboardtooltip = pace.clipboardtooltip or ""
		local copymenu, copypnl = menu:AddSubMenu(L"copy", function()
			pace.clipboard = pac.CopyValue(self:GetValue())
			pace.clipboardtooltip = pace.clipboard .. " (from " .. tostring(pace.current_part) .. ")"
			pace.multicopying = false
		end) copypnl:SetImage(pace.MiscIcons.copy) copymenu.GetDeleteSelf = function() return false end
		install_movable_multicopy(copymenu, self.CurrentKey)
		install_appearance_multicopy(copymenu, self.CurrentKey)

		local pnl = menu:AddOption(L"paste", function()
			if pace.multicopying then
				do_multicopy()
				pace.PopulateProperties(pace.current_part)
			else
				self:SetValue(pac.CopyValue(pace.clipboard))
				self.OnValueChanged(self:GetValue())
			end
		end) pnl:SetImage(pace.MiscIcons.paste) pnl:SetTooltip(pace.clipboardtooltip)

		if #pace.BulkSelectList > 0 then
			local uid_tbl = {}
			local names_tbl = {}
			for i,part in ipairs(pace.BulkSelectList) do
				table.insert(uid_tbl, part.UniqueID)
				table.insert(names_tbl, part:GetName())
			end
			local pnl = menu:AddOption(L"paste UID list", function()
				self:SetValue(table.concat(uid_tbl,";"))
				self.OnValueChanged(self:GetValue())
			end) pnl:SetImage(pace.MiscIcons.paste) pnl:SetTooltip(table.concat(names_tbl,"\n"))
		end

		--command's String variable
		if self.CurrentKey == "String" then

			pace.bookmarked_ressources = pace.bookmarked_ressources or {}
			pace.bookmarked_ressources["command"] =
				{
					--[[["user"] = {

					},]]
					["basic lua"] = {
						{
							lua = true,
							nicename = "if alive then say I\'m alive",
							expression = "if LocalPlayer():Health() > 0 then print(\"I\'m alive\") RunConsoleCommand(\"say\", \"I\'m alive\") else RunConsoleCommand(\"say\", \"I\'m DEAD\") end",
							explanation = "To showcase a basic if/else statement, this will make you say \"I'm alive\" or \"I\'m DEAD\" depending on whether you have more than 0 health."
						},
						{
							lua = true,
							nicename = "print 100 first numbers",
							expression = "for i=0,100,1 do print(\"number\" .. i) end",
							explanation = "To showcase a basic for loop (with the number setup), this will print the first 100 numbers in the console."
						},
						{
							lua = true,
							nicename = "print all entities' health",
							expression = "for _,ent in pairs(ents.GetAll()) do print(ent, ent:Health()) end",
							explanation = "To showcase a basic for loop (using a table iterator), this will print the list of all entities\' health"
						},
						{
							lua = true,
							nicename = "print all entities' health",
							expression = "local random_n = 1 + math.floor(math.random()*5) RunConsoleCommand(\"pac_event\", \"event_\"..random_n)",
							explanation = "To showcase basic number handling and variables, this will run a pac_event command for \"event_1\" to \"event_5\""
						}
					},
					["movement"] ={
						{
							lua = false,
							nicename = "dash",
							expression = "+forward;+speed",
							explanation = "go forward. WARNING. It holds forever until you release it with -forward;-speed"
						},
					},
					["weapons"] = {
						{
							lua = false,
							nicename = "go unarmed (using console)",
							expression = "give none; use none",
							explanation = "use the hands swep (\"none\"). In truth, we need to split the command and run the second one after a delay, or run the full thing twice. the console doesn't let us switch to a weapon we don't yet have"
						},
						{
							lua = true,
							nicename = "go unarmed (using lua)",
							expression = "RunConsoleCommand(\"give\", \"none\") timer.Simple(0.1, function() RunConsoleCommand(\"use\", \"none\") end)",
							explanation = "use the hands swep (\"none\"). we need lua because the console doesn't let us switch to a weapon we don't yet have"
						}
					},
					["events logic"] = {
						{
							lua = true,
							nicename = "random command event activation",
							expression = "RunConsoleCommand(\"pac_event\", \"COMMAND\" .. math.ceil(math.random()*4))",
							explanation = "randomly pick between commands COMMAND1 to COMMAND4.\nReplace 4 to another whole number if you need more or less"
						},
						{
							lua = true,
							nicename = "command series (held down)",
							expression = "local i = LocalPlayer()[\"COMMAND\"] RunConsoleCommand(\"pac_event\", \"COMMAND\" .. i, \"1\") RunConsoleCommand(\"pac_event\", \"COMMAND\" .. i-1, \"0\") if i > 5 then i = 0 end LocalPlayer()[\"COMMAND\"] = i + 1",
							explanation = "goes in the series of COMMAND1 to COMMAND5 activating the current number and deactivating the previous.\nYou can replace COMMAND for another name, and replace the i > 5 for another limit to loop back around\nAlthough now you can use pac_event_sequenced to control event series"
						},
						{
							lua = true,
							nicename = "command series (impulse)",
							expression = "local i = LocalPlayer()[\"COMMAND\"] RunConsoleCommand(\"pac_event\", \"COMMAND\" .. i) if i >= 5 then i = 0 end LocalPlayer()[\"COMMAND\"] = i + 1",
							explanation = "goes in the series of COMMAND1 to COMMAND5 activating one command instantaneously.\nYou can replace COMMAND for another name, and replace the i >= 5 for another limit to loop back around"
						},
						{
							lua = nil,
							nicename = "save current events to a single command",
							explanation = "this hardcoded preset should build a list of all your active command events and save it as a single command string for you"
						}
					},
					--[[["experimental things"] = {
						{
							nicename = "",
							expression = "",
							explanation = ""
						},
					}]]
				}

			local menu1, pnl1 = menu:AddSubMenu(L"example commands", function()
            end)
			pnl1:SetIcon("icon16/cart_go.png")
			for group, tbl in pairs(pace.bookmarked_ressources["command"]) do
				local icon = "icon16/bullet_white.png"
				if group == "user" then icon = "icon16/user.png"
				elseif group == "movement" then icon = "icon16/user_go.png"
				elseif group == "weapons" then icon = "icon16/bomb.png"
				elseif group == "events logic" then icon = "icon16/clock.png"
				elseif group == "spatial" then icon = "icon16/world.png"
				elseif group == "experimental things" then icon = "icon16/ruby.png"
				end
				local menu2, pnl2 = menu1:AddSubMenu(group)
				pnl2:SetIcon(icon)

				if not table.IsEmpty(tbl) then
					for i,tbl2 in pairs(tbl) do
						--print(tbl2.nicename)
						local str = tbl2.nicename or "invalid name"
						local pnl3 = menu2:AddOption(str, function()
							if pace.current_part.ClassName == "command" then
								local expression = pace.current_part.String
								local hardcode = tbl2.lua == nil
								local new_expression = ""
								if hardcode then

									if tbl2.nicename == "save current events to a single command" then
										local tbl3 = {}
										for i,v in pairs(LocalPlayer().pac_command_events) do tbl3[i] = v.on end
										for i,v in pairs(LocalPlayer().pac_command_events) do RunConsoleCommand("pac_event", i, "0") end
										new_expression = ""

										for i,v in pairs(tbl3) do new_expression = new_expression .. "pac_event " .. i .. " " .. v .. ";" end
										pace.current_part:SetUseLua(false)
									end

								end
								if expression == "" then --blank: bare insert
									expression = tbl2.expression
									pace.current_part:SetUseLua(tbl2.lua)
								elseif pace.current_part.UseLua == tbl2.lua then --something present: concatenate the existing bit but only if we're on the same mode
									expression = expression .. ";" .. tbl2.expression
									pace.current_part:SetUseLua(tbl2.lua)
								end

								if not hardcode then
									pace.current_part:SetString(expression)
									self:SetValue(expression)
								else
									pace.current_part:SetString(new_expression)
									self:SetValue(new_expression)
								end
							end

						end)
						pnl3:SetIcon(icon)
						pnl3:SetTooltip(tbl2.explanation)
					end

				end
			end
		end

		--proxy expression
		if self.CurrentKey == "Expression" then


			pace.bookmarked_ressources = pace.bookmarked_ressources or {}
			pace.bookmarked_ressources["proxy"] = pace.bookmarked_ressources["proxy"]
			local menu1, pnl1 = menu:AddSubMenu(L"Proxy template bits", function()
            end)
			pnl1:SetIcon("icon16/cart_go.png")
			for group, tbl in pairs(pace.bookmarked_ressources["proxy"]) do
				local icon = "icon16/bullet_white.png"
				if group == "user" then icon = "icon16/user.png"
				elseif group == "fades and transitions" then icon = "icon16/shading.png"
				elseif group == "pulses" then icon = "icon16/transmit_blue.png"
				elseif group == "facial expressions" then icon = "icon16/emoticon_smile.png"
				elseif group == "spatial" then icon = "icon16/world.png"
				elseif group == "experimental things" then icon = "icon16/ruby.png"
				end
				local menu2, pnl2 = menu1:AddSubMenu(group)
				pnl2:SetIcon(icon)

				if not table.IsEmpty(tbl) then
					for i,tbl2 in pairs(tbl) do
						--print(tbl2.nicename)
						local str = tbl2.nicename or "invalid name"
						local pnl3 = menu2:AddOption(str, function()
							if pace.current_part.ClassName == "proxy" then
								local expression = pace.current_part.Expression
								if expression == "" then --blank: bare insert
									expression = tbl2.expression
								elseif true then --something present: multiply the existing bit?
									expression = expression .. " * " .. tbl2.expression
								end

								pace.current_part:SetExpression(expression)
								self:SetValue(expression)
							end

						end)
						pnl3:SetIcon(icon)
						pnl3:SetTooltip(tbl2.explanation)
					end

				end
			end

			local tutorials, pnl2 = menu:AddSubMenu(L"Tutorials for the active functions")
				for i, kw in ipairs(pace.current_part:GetActiveFunctions()) do
					pace.current_part.errors_override = true --hack to stop competing SetInfo, SetWarning and SetError buttons
					local tutorial = pace.current_part:GetTutorial(kw) if tutorial == nil then continue end
					local pnl3 = tutorials:AddOption(kw, function()
						pace.alternate_message_prompts = true
						pace.current_part:SetInfo(tutorial)
						pace.current_part:AttachEditorPopup(tutorial, true)
					end) pnl3:SetIcon("icon16/calculator.png")
					pnl3:SetTooltip(tutorial)
				end
			pnl2:SetImage("icon16/information.png")
		end

		if self.CurrentKey == "Function" or self.CurrentKey == "Input" then
			local proxy = pace.current_part
			menu:AddOption("Translate easy setup into an expression", function()
				proxy:SetExpression(
					proxy.Min .. " + (" .. proxy.Max .. "-" .. proxy.Min .. ") * (" ..
					"(" .. proxy.Function .. "(((" .. proxy.Input .. "()/" .. proxy.InputDivider .. ") + " .. proxy.Offset .. ") * " ..
					proxy.InputMultiplier .. ") + 1) / 2) ^" .. proxy.Pow
				)
				pace.PopulateProperties(proxy)
			end):SetIcon("icon16/calculator.png")

			local tutorials, pnl2 = menu:AddSubMenu(L"Tutorials for the active functions")
				for i, kw in ipairs(pace.current_part:GetActiveFunctions()) do
					pace.current_part.errors_override = true --hack to stop competing SetInfo, SetWarning and SetError buttons
					local tutorial = pace.current_part:GetTutorial(kw) if tutorial == nil then continue end
					local pnl3 = tutorials:AddOption(kw, function()
						pace.alternate_message_prompts = true
						pace.current_part:SetInfo(tutorial)
						pace.current_part:AttachEditorPopup(tutorial, true)
					end) pnl3:SetIcon("icon16/calculator.png")
					pnl3:SetTooltip(tutorial)
				end
				pnl2:SetTooltip(pace.current_part:GetTutorial(pace.current_part[self.CurrentKey]))
			pnl2:SetImage("icon16/information.png")
		end

		if self.CurrentKey == "LoadVmt" then
			local inserted_mat_owners = {}
			
			local owner = pace.current_part:GetOwner()
			local name = string.GetFileFromFilename( owner:GetModel() )
			local mats = owner:GetMaterials()

			local pnl, menu2 = menu:AddSubMenu(L"Load " .. name .. "'s material", function()
            end)
			menu2:SetImage("icon16/paintcan.png")
			inserted_mat_owners[owner:GetModel()] = true

			for id,mat in ipairs(mats) do
				pnl:AddOption(string.GetFileFromFilename(mat), function()
					pace.current_part:SetLoadVmt(mat)
				end)
			end

			--add parent owners (including the owner entity at root)
			for i,part in ipairs(pace.current_part:GetParentList()) do
				local owner = part:GetOwner()
				local name = string.GetFileFromFilename( owner:GetModel() )
				local mats = owner:GetMaterials()
				if not inserted_mat_owners[owner:GetModel()] then
					local pnl, menu2 = menu:AddSubMenu(L"Load " .. name .. "'s material", function()
					end)
					menu2:SetImage("icon16/paintcan.png")
					inserted_mat_owners[owner:GetModel()] = true

					for id,mat in ipairs(mats) do
						pnl:AddOption(string.GetFileFromFilename(mat), function()
							pace.current_part:SetLoadVmt(mat)
						end)
					end
				end

			end
		end

		if self.CurrentKey == "SurfaceProperties" and pace.current_part.GetSurfacePropsTable then
			local tbl = pace.current_part:GetSurfacePropsTable()
			menu:AddOption(L"See physics info", function()
				local pnl2 = vgui.Create("DFrame")
				local txt_zone = vgui.Create("DTextEntry", pnl2)
				local str = ""
				for i,v in pairs(tbl) do
					str = str .. i .. "  =  " .. v .."\n"
				end
				txt_zone:SetMultiline(true)
				txt_zone:SetText(str)
				txt_zone:Dock(FILL)
				pnl2:SetTitle("SurfaceProp info : " .. pace.current_part.SurfaceProperties)
				pnl2:SetSize(500, 500)
				pnl2:SetPos(ScrW()/2, ScrH()/2)
				pnl2:MakePopup()

            end):SetImage("icon16/table.png")

		end

		if self.CurrentKey == "Model" then
			populate_bookmarks(menu, "models", self)
		end

		if self.CurrentKey == "Material" or self.CurrentKey == "SpritePath" then
			populate_bookmarks(menu, "materials", self)
		end

		if string.find(pace.current_part.ClassName, "sound") then
			if self.CurrentKey == "Sound" or self.CurrentKey == "Path" then
				populate_bookmarks(menu, "sound", self)
			end
		end

		--long string menu to bypass the DLabel's limits for some fields
		if (pace.current_part.ClassName == "sound2" and self.CurrentKey == "Path") or self.CurrentKey == "Notes" or (pace.current_part.ClassName == "text" and self.CurrentKey == "Text")
			or (pace.current_part.ClassName == "command" and self.CurrentKey == "String")
			or self.CurrentKey == "Expression" or self.CurrentKey == "ExpressionOnHide" or self.CurrentKey == "Extra1" or self.CurrentKey == "Extra2" or self.CurrentKey == "Extra3" or self.CurrentKey == "Extra4" or self.CurrentKey == "Extra5" then
			menu:AddOption(L"Insert long text", function()
				local pnl = vgui.Create("DFrame")
				local DText = vgui.Create("DTextEntry", pnl)
				local DButtonOK = vgui.Create("DButton", pnl)
				DText:SetMaximumCharCount(50000)

				local h = math.min(ScrH() - 100, 800)
				pnl:SetSize(1200,h)
				pnl:SetTitle("Long text with newline support for " .. self.CurrentKey .. ". Do not touch the label after this!")
				pnl:SetPos(200, 100)
				DButtonOK:SetText("OK")
				DButtonOK:SetSize(80,20)
				DButtonOK:SetPos(500, h - 25)
				DText:SetPos(5,25)
				DText:SetSize(1190,h - 50)
				DText:SetMultiline(true)
				DText:SetContentAlignment(7)
				pnl:MakePopup()
				DText:RequestFocus()
				DText:SetText(pace.current_part[self.CurrentKey])

				DButtonOK.DoClick = function()
					local str = DText:GetText()
					pace.current_part[self.CurrentKey] = str
					if pace.current_part.ClassName == "sound2" then
						pace.current_part.AllPaths = str
						pace.current_part:UpdateSoundsFromAll()
					end
					pace.PopulateProperties(pace.current_part)
					pnl:Remove()
				end
			end):SetImage('icon16/text_letter_omega.png')
		end

		--left right swap available on strings (and parts)
		if type(self:GetValue()) == 'string' then
			menu:AddSpacer()
			menu:AddOption(L"change sides", function()
				local var
				local part
				if self.udata and self.udata.editor_panel == "part" then
					part = pac.GetPartFromUniqueID(pac.Hash(pac.LocalPlayer), self:GetValue())
					var = part:IsValid() and part:GetName()
				else
					var = self:GetValue()
				end

				local var_flip
				if string.match(var, "left") != nil then
					var_flip = string.gsub(var,"left","right")
				elseif string.match(var, "right") != nil then
					var_flip = string.gsub(var,"right","left")
				end

				if self.udata and self.udata.editor_panel == "part" then
					local target = pac.FindPartByName(pac.Hash(pac.LocalPlayer), var_flip or var, pace.current_part)
					self:SetValue(target or part)
					self.OnValueChanged(target or part)
				else
                self:SetValue(var_flip or var)
                self.OnValueChanged(var_flip or var)
            end
		end):SetImage("icon16/arrow_switch.png")

		--numeric sign flip available on numbers
		elseif type(self:GetValue()) == 'number' then
			menu:AddSpacer()
			menu:AddOption(L"flip sign (+/-)", function()
				local val = self:GetValue()
				self:SetValue(-val)
				self.OnValueChanged(self:GetValue())
			end):SetImage("icon16/arrow_switch.png")

			if self.CurrentKey == "Size" then
				if pace.current_part.ClassName == "sprite" then
					menu:AddOption(L"apply size to scales", function()
						local val = self:GetValue()
						pace.current_part.SizeX = pace.current_part.SizeX * val
						pace.current_part.SizeY = pace.current_part.SizeX * val
						self:SetValue(1)
						self.OnValueChanged(self:GetValue())
						pace.PopulateProperties(pace.current_part)
					end):SetImage("icon16/arrow_down.png")
				elseif pace.current_part.SetScale and pace.current_part.GetScale then
					menu:AddOption(L"apply size to scales", function()
						local val = self:GetValue()
						pace.current_part:SetScale(val * pace.current_part:GetScale())
						self:SetValue(1)
						self.OnValueChanged(self:GetValue())
						pace.PopulateProperties(pace.current_part)
					end):SetImage("icon16/arrow_down.png")
				end
			end
		end

		menu:AddSpacer()
		menu:AddOption(L"reset", function()
			if pace.current_part and pace.current_part.DefaultVars[self.CurrentKey] then
				local val = pac.CopyValue(pace.current_part.DefaultVars[self.CurrentKey])
				self:SetValue(val)
				self.OnValueChanged(val)
			end
		end):SetImage(pace.MiscIcons.clear)
	end

	function PANEL:OnMouseReleased()
		self:MousePress(false)
		self.MousePressing = false
	end

	function PANEL:IsMouseDown()
		if not input.IsMouseDown(MOUSE_LEFT) then
			self.MousePressing = false
		end
		return self.MousePressing
	end

	function PANEL:DoubleClick()

	end

	function PANEL:MousePress()

	end

	function PANEL:Restart()
		self:SetValue(self:Decode(""))
		self.OnValueChanged(self:Decode(""))
	end

	function PANEL:EncodeEdit(str)
		return str
	end

	function PANEL:DecodeEdit(str)
		return str
	end

	function PANEL:EditText()
		local oldText = self:GetText()
		self:SetText("")

		local pnl = vgui.Create("DTextEntry")
		self.editing = pnl
		pnl:SetFont(pace.CurrentFont)
		pnl:SetDrawBackground(false)
		pnl:SetDrawBorder(false)
		pnl:SetText(self:EncodeEdit(self.original_str or ""))
		pnl:SetKeyboardInputEnabled(true)
		pnl:SetDrawLanguageID(languageID:GetBool())
		pnl:RequestFocus()
		pnl:SelectAllOnFocus(true)

		pnl.OnTextChanged = function() oldText = pnl:GetText() end

		local hookID = tostring({})
		local textEntry = pnl
		local delay = os.clock() + 0.1
		local inset_x = self:GetTextInset()

		pac.AddHook('Think', hookID, function(code)
			if not IsValid(self) or not IsValid(textEntry) or self.CurrentKey == nil then return pac.RemoveHook('Think', hookID) end
			if textEntry:IsHovered() or self:IsHovered() then return end
			if delay > os.clock() then return end
			if not input.IsMouseDown(MOUSE_LEFT) and not input.IsKeyDown(KEY_ESCAPE) then return end
			pac.RemoveHook('Think', hookID)
			self.editing = false
			pace.BusyWithProperties = NULL
			textEntry:Remove()
			self:SetText(oldText)
			pnl:OnEnter()
		end)

		--local x,y = pnl:GetPos()
		--pnl:SetPos(x+3,y-4)
		--pnl:Dock(FILL)
		local x, y = self:LocalToScreen()
		pnl:SetPos(x+5 + inset_x, y)
		pnl:SetSize(self:GetSize())
		pnl:SetWide(ScrW())
		pnl:MakePopup()

		pnl.OnEnter = function()
			pace.BusyWithProperties = NULL
			self.editing = false

			pnl:Remove()

			self:SetText(tostring(self:Encode(self:DecodeEdit(pnl:GetText() or ""))), true)
			self.OnValueChanged(self:Decode(self:GetText()))
		end

		local old = pnl.Paint
		pnl.Paint = function(...)
			if not self:IsValid() then pnl:Remove() return end
			local x, y = self:LocalToScreen()
			local _,prop_y = pace.properties:LocalToScreen(0,0)
			y = math.Clamp(y,prop_y,ScrH() - self:GetTall())

			pnl:SetPos(x + 5 + inset_x, y)

			surface.SetFont(pnl:GetFont())
			local w = surface.GetTextSize(pnl:GetText()) + 6

			surface.DrawRect(0, 0, w, pnl:GetTall())
			surface.SetDrawColor(self:GetSkin().Colours.Properties.Border)
			surface.DrawOutlinedRect(0, 0, w, pnl:GetTall())

			pnl:SetWide(w)

			old(...)
		end

		local skincolor = self:GetSkin().Colours.Category.Line.Button
		local col = Color(skincolor.r,skincolor.g,skincolor.b, 255)

		--draw a rectangle with property key's name and arrows to show where the line is scrolling out of bounds
		pac.AddHook('PostRenderVGUI', hookID .. "2", function(code)
			if not IsValid(self) or not IsValid(pnl) or self.CurrentKey == nil  then pac.RemoveHook('Think', hookID .. "2") return end
			local _,prop_y = pace.properties:LocalToScreen(0,0)
			local x, y = self:LocalToScreen()
			local overflow = y < prop_y or y > ScrH() - self:GetTall()
			if overflow then
				local str = ""
				if y > ScrH() then
					str = "↓↓ " .. " " .. self.CurrentKey .. " " .. " ↓↓"
				else
					str = "↑↑ " .. " " .. self.CurrentKey .. " " .. " ↑↑"
				end
				y = math.Clamp(y,prop_y,ScrH() - self:GetTall())
				surface.SetFont(pnl:GetFont())
				local w2 = surface.GetTextSize(str)
				
				surface.SetDrawColor(col)
				surface.DrawRect(x - w2, y, w2, pnl:GetTall())
				surface.SetTextColor(self:GetSkin().Colours.Category.Line.Text)
				surface.SetTextPos(x - w2, y)
				surface.DrawText(str)
			end
		end)

		pace.BusyWithProperties = pnl
	end

	pace.BusyWithProperties = NULL

	local function click()
		if not input.IsMouseDown(MOUSE_LEFT) then return end
		local pnl = pace.BusyWithProperties
		if pnl and pnl ~= true and pnl:IsValid() then
			local x, y = input.GetCursorPos()
			local _x, _y = pnl:GetParent():LocalToScreen()
			if x < _x or y < _y or x > _x + pnl:GetParent():GetWide() or y > _y + pnl:GetParent():GetTall() then
				pnl:OnEnter()
			end
		end
	end

	pac.AddHook("GUIMousePressed", "pace_property_text_edit", click)
	pac.AddHook("VGUIMousePressed", "pace_property_text_edit", click)

	function PANEL:Reset()
		if IsValid(self.editing) then
			self.editing:OnEnter()
			self.editing = false
		else
			self:SetValue(self.original_var)
			self.OnValueChanged(self.original_var)
		end
	end

	function PANEL:GetValue()
		return self.original_var
	end

	function PANEL:Encode(var)
		return var
	end

	function PANEL:Decode(var)
		return var
	end

	function PANEL:PerformLayout()
		self:SetSize(self:GetParent():GetSize())
	end

	pace.RegisterPanel(PANEL)
end

do -- string
	local PANEL = {}

	PANEL.ClassName = "properties_string"
	PANEL.Base = "pace_properties_base_type"

	PANEL.SingleClick = true

	pace.RegisterPanel(PANEL)
end

do -- vector
	local function VECTOR(ctor, type, arg1, arg2, arg3, encode, special_callback, sens)
		local PANEL = {}

		PANEL.ClassName = "properties_" .. type
		PANEL.Base = "pace_properties_container"

		PANEL.vector_type = type

		function PANEL:Init(...)
			self.vector = ctor(0,0,0)

			local left = pace.CreatePanel("properties_number", self)
			local middle = pace.CreatePanel("properties_number", self)
			local right = pace.CreatePanel("properties_number", self)
			--a hack so that the scrolling out-of-bounds indicator rectangle with arrows has the key
			timer.Simple(0, function()
				if not IsValid(left) then return end
				left.CurrentKey = self.CurrentKey
				middle.CurrentKey = self.CurrentKey
				right.CurrentKey = self.CurrentKey
			end)

			left.PopulateContextMenu = function(_, menu) self:PopulateContextMenu(menu) end
			middle.PopulateContextMenu = function(_, menu) self:PopulateContextMenu(menu) end
			right.PopulateContextMenu = function(_, menu) self:PopulateContextMenu(menu) end

			if encode then
				left.Encode = encode
				middle.Encode = encode
				right.Encode = encode
			end

			if sens then
				left.sens = sens
				middle.sens = sens
				right.sens = sens
			end

			local function on_change(arg1, arg2, arg3)
				local restart = 0

				return function(num)
					self.vector[arg1] = num

					if input.IsKeyDown(KEY_R) then
						self:Restart()
						restart = os.clock() + 0.1
					elseif input.IsKeyDown(KEY_LSHIFT) then
						middle:SetValue(num)
						self.vector[arg2] = num

						right:SetValue(num)
						self.vector[arg3] = num
					end

					if restart > os.clock() then
						self:Restart()
						return
					end

					self.OnValueChanged(self.vector * 1)
					self:InvalidateLayout()

					if self.OnValueSet then
						self:OnValueSet(self.vector * 1)
					end
				end
			end

			left:SetMouseInputEnabled(true)
			left.OnValueChanged = on_change(arg1, arg2, arg3)

			middle:SetMouseInputEnabled(true)
			middle.OnValueChanged = on_change(arg2, arg1, arg3)

			right:SetMouseInputEnabled(true)
			right.OnValueChanged = on_change(arg3, arg2, arg1)

			self.left = left
			self.middle = middle
			self.right = right

			self.pac_property_panel = self
			left.pac_property_panel = self
			middle.pac_property_panel = self
			right.pac_property_panel = self

			if self.MoreOptionsLeftClick then
				local btn = vgui.Create("DButton", self)
				btn:SetSize(16, 16)
				btn:Dock(RIGHT)
				btn:SetText("...")
				btn.DoClick = function() self:MoreOptionsLeftClick(self.CurrentKey) end
				btn.DoRightClick = self.MoreOptionsRightClick and function() self:MoreOptionsRightClick(self.CurrentKey) end or btn.DoClick

				if type == "color" or type == "color2" then
					btn:SetText("")
					btn.Paint = function(_,w,h)
						if type == "color2" then
							surface.SetDrawColor(self.vector.x*255, self.vector.y*255, self.vector.z*255, 255)
						else
							surface.SetDrawColor(self.vector.x, self.vector.y, self.vector.z, 255)
						end
						surface.DrawRect(0,0,w,h)
						surface.SetDrawColor(self:GetSkin().Colours.Properties.Border)
						surface.DrawOutlinedRect(0,0,w,h)
					end

					--screen color picker
					local btn2 = vgui.Create("DImageButton", self)
					btn2:SetSize(16, 16)
					btn2:Dock(RIGHT) btn2:DockPadding(0,0,16,0)
					btn2:SetTooltip("Color picker")
					btn2:SetImage("icon16/sitemap_color.png")
					btn2.DoClick = function()
						pace.FlashNotification("Hold Left Shift to open a circle to average nearby pixels")
						local averaging_radius = 0
						local lock_x
						local lock_y
						pac.AddHook("DrawOverlay", "colorpicker", function()
							render.CapturePixels()
							local mx, my = input.GetCursorPos()
							local cx = mx
							local cy = my
							
							local r,g,b,a = render.ReadPixel(mx,my)

							--we may average on nearby pixels
							if input.IsKeyDown(KEY_LSHIFT) then
								lock_x = lock_x or mx
								lock_y = lock_y or my
								local dx = mx-lock_x
								local dy = my-lock_y

								averaging_radius = math.floor(math.sqrt(dx^2 + dy^2))
							else
								lock_x = nil
								lock_y = nil
								averaging_radius = 0
							end
							if lock_x and lock_y then
								cx = lock_x
								cy = lock_y
							end
							local r_sum = 0
							local g_sum = 0
							local b_sum = 0

							if averaging_radius > 0 then
								local counted_pixels = 0
								for x=cx-averaging_radius,mx+averaging_radius,1 do
									for y=cy-averaging_radius,my+averaging_radius,1 do
										if x^2 + y^2 > averaging_radius^2 then
											counted_pixels = counted_pixels + 1
											local r,g,b,a = render.ReadPixel(x,y)
											r_sum = r_sum + r
											g_sum = g_sum + g
											b_sum = b_sum + b
										end
									end
								end
								if counted_pixels ~= 0 then
									r = math.floor(r_sum / counted_pixels)
									g = math.floor(g_sum / counted_pixels)
									b = math.floor(b_sum / counted_pixels)
								end

								if RealTime() % 0.2 > 0.1 then
									surface.DrawCircle(cx, cy, averaging_radius, 0,0,0,255)
								else
									surface.DrawCircle(cx, cy, averaging_radius, 255,255,255,255)
								end
								draw.DrawText("(average color) radius = "..averaging_radius, "TargetID", cx + 15, cy + 15, picked_color, TEXT_ALIGN_LEFT)
							end
							
							local color = Color(0,0,0)
							if r + g + a < 400 then
								color = Color(255,255,255)
							end

							local picked_color = Color(r,g,b)
							draw.RoundedBox(0,cx + 15,cy,120,18,color)
							draw.DrawText(r .. " " .. g .. " " .. " " .. b, "TargetID", cx + 15, cy, picked_color, TEXT_ALIGN_LEFT)
							if input.IsMouseDown(MOUSE_LEFT) then
								pac.CopyValue(picked_color)
								if pace.current_part.ProperColorRange then
									self.OnValueChanged(Vector(picked_color.r/255,picked_color.g/255,picked_color.b/255))
								else
									self.OnValueChanged(Vector(picked_color.r,picked_color.g,picked_color.b))
								end
								
								pac.RemoveHook("DrawOverlay", "colorpicker")
							end
							if input.IsKeyDown(KEY_ESCAPE) then pac.RemoveHook("DrawOverlay", "colorpicker") end
						end)
					end
				end
			end

			self.Paint = function() end
		end

		PANEL.MoreOptionsLeftClick = special_callback

		function PANEL:Restart()
			if pace.current_part and pace.current_part.DefaultVars[self.CurrentKey] then
				self.vector = pac.CopyValue(pace.current_part.DefaultVars[self.CurrentKey])
			else
				self.vector = ctor(0,0,0)
			end

			self.left:SetValue(self.vector[arg1])
			self.middle:SetValue(self.vector[arg2])
			self.right:SetValue(self.vector[arg3])

			self.OnValueChanged(self.vector * 1)
		end

		function PANEL:PopulateContextMenu(menu)
			if self.user_proxies then
				for _,part in pairs(self.user_proxies) do
					menu:AddOption("jump to " .. tostring(part), function()
						pace.GoToPart(part)
					end):SetImage("icon16/arrow_turn_right.png")
				end
			end
			pace.clipboardtooltip = pace.clipboardtooltip or ""
			local copymenu, copypnl = menu:AddSubMenu(L"copy", function()
				pace.clipboard = pac.CopyValue(self.vector)
				pace.clipboardtooltip = tostring(pace.clipboard) .. " (from " .. tostring(pace.current_part) .. ")"
				pace.multicopying = false
			end) copypnl:SetImage(pace.MiscIcons.copy) copymenu.GetDeleteSelf = function() return false end
			install_movable_multicopy(copymenu, self.CurrentKey)
			install_appearance_multicopy(copymenu, self.CurrentKey)

			local pnl = menu:AddOption(L"paste", function()
				if pace.multicopying then
					do_multicopy()
					pace.PopulateProperties(pace.current_part)
				else
					local val = pac.CopyValue(pace.clipboard)
					if isnumber(val) then
						val = ctor(val, val, val)
					elseif isvector(val) and type == "angle" then
						val = ctor(val.x, val.y, val.z)
					elseif isangle(val) and type == "vector" then
						val = ctor(val.p, val.y, val.r)
					end

					if _G.type(val):lower() == type or type == "color" or type == "color2" then
						self:SetValue(val)

						self.OnValueChanged(self.vector * 1)
					end
				end
			end) pnl:SetImage(pace.MiscIcons.paste) pnl:SetTooltip(pace.clipboardtooltip)
			menu:AddSpacer()
			menu:AddOption(L"reset", function()
				if pace.current_part and pace.current_part.DefaultVars[self.CurrentKey] then
					local val = pac.CopyValue(pace.current_part.DefaultVars[self.CurrentKey])
					self:SetValue(val)
					self.OnValueChanged(val)
				end
			end):SetImage(pace.MiscIcons.clear)
		end

		function PANEL:SetValue(vec)
			self.vector = vec * 1

			self.left:SetValue(math.Round(vec[arg1], 4))
			self.middle:SetValue(math.Round(vec[arg2], 4))
			self.right:SetValue(math.Round(vec[arg3], 4))
		end

		function PANEL:PerformLayout()
			self.left:SizeToContents()
			self.left:SetWide(math.max(self.left:GetWide(), 22))

			self.middle:SizeToContents()
			self.middle:SetWide(math.max(self.middle:GetWide(), 22))

			self.right:SizeToContents()
			self.right:SetWide(math.max(self.right:GetWide(), 22))

			self.middle:MoveRightOf(self.left, 10)
			self.right:MoveRightOf(self.middle, 10)
		end

		function PANEL:OnValueChanged(vec)
		end

		pace.RegisterPanel(PANEL)
	end

	VECTOR(Vector, "vector", "x", "y", "z")
	VECTOR(Angle, "angle", "p", "y", "r")

	local function tohex(vec, color2)
		return color2 and ("#%.2X%.2X%.2X"):format(vec.x * 255, vec.y * 255, vec.z * 255) or ("#%.2X%.2X%.2X"):format(vec.x, vec.y, vec.z)
	end

	local function fromhex(str)
		local r, g, b

		if #str <= 4 then -- Supports "#xxx" and "xxx"
			r, g, b = str:match("#?(.)(.)(.)")

			if r and g and b then
				r, g, b = r .. r, g .. g, b .. b
			end
		elseif #str <= 7 then -- Supports "#xxxxxx" and "xxxxxx"
			r, g, b = str:match("#?(..)(..)(..)")
		end

		if r and g and b then
			return Color(tonumber(r, 16) or 255, tonumber(g, 16) or 255, tonumber(b, 16) or 255)
		end
	end

	local function fromColorStr(str)
		local r1, g1, b1 = str:match("([0-9]+), *([0-9]+), *([0-9]+)")
		local r2, g2, b2 = str:match("([0-9]+) +([0-9]+) +([0-9]+)")

		if r1 and g1 and b1 then
			return Color(tonumber(r1) or 255, tonumber(g1) or 255, tonumber(b1) or 255)
		elseif r2 and g2 and b2 then
			return Color(tonumber(r2) or 255, tonumber(g2) or 255, tonumber(b2) or 255)
		end
	end

	local function uncodeValue(valIn)
		local fromHex = fromhex(valIn)
		local fromShareXColorStr = fromColorStr(valIn)

		return fromHex or fromShareXColorStr
	end

	VECTOR(Vector, "color", "x", "y", "z",
		function(self, num) -- this function needs second argument
			local pnum = tonumber(num)

			if not pnum then
				local uncode = uncodeValue(num)

				if uncode then
					timer.Simple(0, function()
						local parent = self:GetParent()
						parent.left:SetValue(uncode.r, true)
						parent.middle:SetValue(uncode.g, true)
						parent.right:SetValue(uncode.b, true)

						parent.left.OnValueChanged(uncode.r)
						parent.middle.OnValueChanged(uncode.g)
						parent.right.OnValueChanged(uncode.b)
					end)

					return '0'
				end

				return '0'
			end

			return tostring(math.Clamp(math.Round(pnum or 0), 0, 255))
		end,

		function(self)
			pace.SafeRemoveSpecialPanel()

			local dlibbased = vgui.GetControlTable("DLibColorMixer")

			local frm = vgui.Create("DFrame")
			frm:SetTitle("Color")

			pace.ShowSpecial(frm, self, 300)

			if dlibbased then
				frm:SetWide(500)
			end

			local clr = vgui.Create(dlibbased and "DLibColorMixer" or "DColorMixer", frm)
			clr:Dock(FILL)
			clr:SetAlphaBar(false) -- Alpha isn't needed
			clr:SetColor(Color(self.vector.x, self.vector.y, self.vector.z))

			local html_color

			if not dlibbased then
				html_color = vgui.Create("DTextEntry", frm)
				html_color:Dock(BOTTOM)
				html_color:SetText(tohex(self.vector))

				html_color.OnEnter = function()
					local valGet = uncodeValue(html_color:GetValue())

					if valGet then
						clr:SetColor(valGet)
					end
				end
			end

			function clr.ValueChanged(_, newColor) -- Only update values when the Color mixer value changes
				local vec = Vector(newColor.r, newColor.g, newColor.b)
				self.OnValueChanged(vec)
				self:SetValue(vec)

				if not dlibbased then
					html_color:SetText(tohex(vec))
				end
			end

			pace.ActiveSpecialPanel = frm
		end,
		10
	)

	VECTOR(Vector, "color2", "x", "y", "z",
		function(_, num)
			num = tonumber(num) or 0

			if input.IsKeyDown(KEY_LCONTROL) then
				num = math.Round(num)
			end

			return tostring(num)
		end,

		function(self)
			pace.SafeRemoveSpecialPanel()

			local dlibbased = vgui.GetControlTable("DLibColorMixer")

			local frm = vgui.Create("DFrame")
			frm:SetTitle("color")

			pace.ShowSpecial(frm, self, 300)

			if dlibbased then
				frm:SetWide(500)
			end

			local clr = vgui.Create(dlibbased and "DLibColorMixer" or "DColorMixer", frm)
			clr:Dock(FILL)
			clr:SetAlphaBar(false)
			clr:SetColor(Color(self.vector.x * 255, self.vector.y * 255, self.vector.z * 255))

			local html_color

			if not dlibbased then
				html_color = vgui.Create("DTextEntry", frm)
				html_color:Dock(BOTTOM)
				html_color:SetText(tohex(self.vector, true))
				html_color.OnEnter = function()
					local col = uncodeValue(html_color:GetValue())
					if col then
						local vec = col:ToVector()
						clr:SetColor(col)
						self.OnValueChanged(vec)
						self:SetValue(vec)
					end
				end
			end

			function clr.ValueChanged(_, newcolor)
				local vec = Vector(newcolor.r / 255, newcolor.g / 255, newcolor.b / 255)
				self.OnValueChanged(vec)
				self:SetValue(vec)

				if not dlibbased then
					html_color:SetText(tohex(vec, true))
				end
			end

			pace.ActiveSpecialPanel = frm
		end,
		0.25
	)

end

do -- number
	local PANEL = {}

	PANEL.ClassName = "properties_number"
	PANEL.Base = "pace_properties_base_type"

	PANEL.sens = 1

	PANEL.SingleClick = false

	function PANEL:MousePress(bool)
		if bool then
			self.mousey = gui.MouseY()
			self.mousex = gui.MouseX()
			self.oldval = tonumber(self:GetValue()) or 0
		else
			self.mousey = nil
		end
	end

	function PANEL:OnCursorMoved()
		if self.used_by_proxy then self:SetCursor("no") return end
		self:SetCursor("sizens")
	end

	function PANEL:SetNumberValue(val)
		if self.LimitValue then
			val = self:LimitValue(val) or val
		end

		val = self:Encode(val)
		self:SetValue(val)
		self.OnValueChanged(tonumber(val))
	end

	function PANEL:OnMouseWheeled(delta)
		if not input.IsKeyDown(KEY_LCONTROL) then delta = delta / 10 end
		if input.IsKeyDown(KEY_LALT) then delta = delta / 10 end
		local val = self:GetValue() + (delta * self.sens)

		self:SetNumberValue(val)
	end

	function PANEL:Think()
		if self:IsMouseDown() then
			local sens = self.sens

			if input.IsKeyDown(KEY_LALT) then
				sens = sens / 10
			end

			local delta = (self.mousey - gui.MouseY()) / 10
			local val = (self.oldval or 0) + (delta * sens)

			if input.IsKeyDown(KEY_R) then
				if pace.current_part and pace.current_part.DefaultVars[self.CurrentKey] then
					val = pace.current_part.DefaultVars[self.CurrentKey]
				end
			end

			self:SetNumberValue(val)

			if gui.MouseY()+1 >= ScrH() then
				self.mousey = 0
				self.oldval = val
				input.SetCursorPos(gui.MouseX(), 0)
			elseif gui.MouseY() <= 0 then
				self.mousey = ScrH()
				self.oldval = val
				input.SetCursorPos(gui.MouseX(), ScrH())
			end
		end
	end

	function PANEL:Encode(num)
		if not tonumber(num) then
			local ok, res = pac.CompileExpression(num)
			if ok then
				num = res() or 0
			end
		end

		num = tonumber(num) or 0

		if self:IsMouseDown() then
			if input.IsKeyDown(KEY_LCONTROL) then
				num = math.Round(num)
			elseif input.IsKeyDown(KEY_PAD_MINUS) or input.IsKeyDown(KEY_MINUS) then
				num = -num
			end


			if input.IsKeyDown(KEY_LALT) then
				num = math.Round(num, 5)
			else
				num = math.Round(num, 3)
			end
		end

		return num
	end

	function PANEL:Decode(str)
		return tonumber(str) or 0
	end

	pace.RegisterPanel(PANEL)
end

do -- boolean
	local PANEL = {}

	PANEL.ClassName = "properties_boolean"
	PANEL.Base = "pace_properties_container"

	function PANEL:Init()
		local chck = vgui.Create("DCheckBox", self)
		chck.OnChange = function()
			if self.during_change then return end
			local b = chck:GetChecked()
			self.OnValueChanged(b)
			self.lbl:SetText(L(tostring(b)))
		end
		chck.DoRightClick = function()
			local menu = DermaMenu()
			menu:SetPos(input.GetCursorPos())
			if self.user_proxies then
				for _,part in pairs(self.user_proxies) do
					menu:AddOption("jump to " .. tostring(part), function()
						pace.GoToPart(part)
					end):SetImage("icon16/arrow_turn_right.png")
				end
			end
			menu:AddOption(L"reset", function()
				if pace.current_part and (pace.current_part.DefaultVars[self.CurrentKey] ~= nil) then
					local val = pac.CopyValue(pace.current_part.DefaultVars[self.CurrentKey])
					self:SetValue(val)
					self.OnValueChanged(val)
				end
			end):SetImage(pace.MiscIcons.clear)
			menu:MakePopup()
		end
		self.chck = chck

		local lbl = vgui.Create("DLabel", self)
		lbl:SetFont(pace.CurrentFont)
		lbl:SetTextColor(self.alt_line and self:GetSkin().Colours.Category.AltLine.Text or self:GetSkin().Colours.Category.Line.Text)
		self.lbl = lbl
	end

	function PANEL:Paint() end

	function PANEL:SetValue(b)
		self.during_change = true
		self.chck:SetChecked(b)
		self.chck:Toggle()
		self.chck:Toggle()
		self.lbl:SetText(L(tostring(b)))
		if self.used_by_proxy then
			if pace.special_property_text_color then
				self.lbl:SetTextColor(pace.special_property_text_color)
			end
		end
		self.during_change = false
	end

	function PANEL:OnValueChanged()

	end

	function PANEL:PerformLayout()
		self.BaseClass.PerformLayout(self)

		local s = 4

		self.chck:SetPos(s*0.5, s*0.5+1)
		self.chck:SetSize(self:GetTall()-s, self:GetTall()-s)

		self.lbl:MoveRightOf(self.chck, 5)
		self.lbl:CenterVertical()
		local w,h = self:GetParent():GetSize()
		self:SetSize(w-2,h)
		self.lbl:SetSize(w-h-2,h)
	end

	pace.RegisterPanel(PANEL)
end


local tree_search_excluded_vars = {
	["ParentUID"] = true,
	["UniqueID"] = true,
	["ModelTracker"] = true,
	["ClassTracker"] = true,
	["LoadVmt"] = true
}

function pace.OpenTreeSearch()
	--[[if GetConVar("pac_tree_lazymode"):GetBool() then
		timer.Simple(0, function()
			for i,v in pairs(pac.GetLocalParts()) do
				v.no_populate = false
				v.dormant_node = false
			end
			pace.RefreshTree(true)
		end)
	end]]
	if pace.tree_search_open then return end
	pace.Editor.y_offset = 24
	pace.tree_search_open = true
	pace.tree_search_match_index = 0
	pace.tree_search_matches = {}
	local resulting_part
	local search_term = "friend"
	local matched_property
	local matches = {}

	local base = vgui.Create("DFrame")
	pace.tree_searcher = base
	local edit = vgui.Create("DTextEntry", base)
	local patterns = vgui.Create("DButton", base)
	local search_button = vgui.Create("DButton", base)
	local range_label = vgui.Create("DLabel", base)
	local close_button = vgui.Create("DButton", base)
	local case_box = vgui.Create("DButton", base)

	case_box:SetText("Aa")
	case_box:SetPos(325,2)
	case_box:SetSize(25,20)
	case_box:SetTooltip("case sensitive")
	case_box:SetColor(Color(150,150,150))
	case_box:SetFont("DermaDefaultBold")

	patterns:SetText("^[abc]")
	patterns:SetPos(490,2)
	patterns:SetSize(40,20)
	patterns:SetTooltip("use Lua patterns")
	patterns:SetColor(Color(150,150,150))
	patterns:SetFont("DermaDefaultBold")

	function case_box:DoClick()
		self.on = not self.on
		if self.on then
			self:SetColor(Color(0,0,0))
		else
			self:SetColor(Color(150,150,150))
		end
	end

	function patterns:DoClick()
		self.on = not self.on
		if self.on then
			self:SetColor(Color(0,0,0))
		else
			self:SetColor(Color(150,150,150))
		end
	end


	local function select_match()
		if table.IsEmpty(pace.tree_search_matches) then range_label:SetText("0 / 0") return end
		if not pace.tree_search_matches[pace.tree_search_match_index] then return end

		resulting_part = pace.tree_search_matches[pace.tree_search_match_index].part_matched
		matched_property = pace.tree_search_matches[pace.tree_search_match_index].key_matched
		if resulting_part ~= pace.current_part then pace.OnPartSelected(resulting_part, true) end
		local parent = resulting_part:GetParent()
		while IsValid(parent) and (parent:GetParent() ~= parent) do
			parent.pace_tree_node:SetExpanded(true)
			parent = parent:GetParent()
			if parent:IsValid() then
				parent.pace_tree_node:SetExpanded(true)
			end
		end
		--pace.RefreshTree()
		pace.FlashProperty(resulting_part, matched_property, false)
	end

	function base.OnRemove()
		pace.tree_search_open = false
		if not IsValid(pace.Editor) then return end
		pace.Editor.y_offset = 0
	end

	function base.Think()
		if not IsValid(pace.Editor) then base:Remove() return end
		if not pace.Focused then base:Remove() end
		base:SetX(pace.Editor:GetX())
		base:SetWide(pace.Editor:GetWide())
	end
	function base.Paint(_,w,h)
		surface.SetDrawColor(Color(255,255,255))
		surface.DrawRect(0,0,w,h)
	end
	base:SetDraggable(false)
	base:SetX(pace.Editor:GetX())
	base:ShowCloseButton(false)

	close_button:SetSize(40,20)
	close_button:SetPos(450,2)
	close_button:SetText("close")
	function close_button.DoClick()
		base:Remove()
	end

	local fwd = vgui.Create("DButton", base)
	local bck = vgui.Create("DButton", base)

	local function perform_search()
		local case_sensitive = case_box.on
		matches = {}
		pace.tree_search_matches = {}
		search_term = edit:GetText()
		local nopatterns = patterns.on
		if not case_sensitive then search_term = string.lower(search_term) end
		for _,part in pairs(pac.GetLocalParts()) do
			if (string.find(part.UniqueID, string.sub(search_term,2,#search_term-1)) or string.find(part.UniqueID, search_term)) and (#search_term > 8) then
				table.insert(matches, #matches + 1, {part_matched = part, key_matched = "UniqueID"})
				table.insert(pace.tree_search_matches, #matches, {part_matched = part, key_matched = "UniqueID"})
			end

			for k,v in pairs(part:GetProperties()) do
				local value = v.get(part)

				if (type(value) ~= "number" and type(value) ~= "string") or tree_search_excluded_vars[v.key] then continue end

				value = tostring(value)
				if not case_sensitive then value = string.lower(value) end


				if string.find(case_sensitive and v.key or string.lower(v.key), search_term) or (string.find(value, search_term,1, not nopatterns)) then
					if v.key == "Name" and part.Name == "" then continue end
					table.insert(matches, #matches + 1, {part_matched = part, key_matched = v.key})
					table.insert(pace.tree_search_matches, #matches, {part_matched = part, key_matched = v.key})
				end
			end
		end
		table.sort(pace.tree_search_matches, function(a, b)
			if not IsValid(a.part_matched.pace_tree_node) then return false end
			if not IsValid(b.part_matched.pace_tree_node) then return false end
			return select(2, a.part_matched.pace_tree_node:LocalToScreen()) < select(2, b.part_matched.pace_tree_node:LocalToScreen())
		end)
		if table.IsEmpty(matches) then range_label:SetText("0 / 0") else pace.tree_search_match_index = 1 end
		range_label:SetText(pace.tree_search_match_index .. " / " .. #pace.tree_search_matches)
	end

	base:SetSize(pace.Editor:GetWide(),24)
	edit:SetSize(290,20)
	edit:SetPos(0,2)
	base:MakePopup()
	edit:RequestFocus()
	edit:SetUpdateOnType(true)
	edit.previous_search = ""

	range_label:SetSize(50,20)
	range_label:SetPos(295,2)
	range_label:SetText("0 / 0")
	range_label:SetTextColor(Color(0,0,0))

	fwd:SetSize(25,20)
	fwd:SetPos(375,2)
	fwd:SetText(">")
	function fwd.DoClick()
		if table.IsEmpty(pace.tree_search_matches) then range_label:SetText("0 / 0") return end
		pace.tree_search_match_index = (pace.tree_search_match_index % math.max(#matches,1)) + 1
		range_label:SetText(pace.tree_search_match_index .. " / " .. #pace.tree_search_matches)
		select_match()
	end

	search_button:SetSize(50,20)
	search_button:SetPos(400,2)
	search_button:SetText("search")
	function search_button.DoClick()
		perform_search()
		select_match()
	end

	bck:SetSize(25,20)
	bck:SetPos(350,2)
	bck:SetText("<")
	function bck.DoClick()
		if table.IsEmpty(pace.tree_search_matches) then range_label:SetText("0 / 0") return end
		pace.tree_search_match_index = ((pace.tree_search_match_index - 2 + #matches) % math.max(#matches,1)) + 1
		range_label:SetText(pace.tree_search_match_index .. " / " .. #pace.tree_search_matches)
		select_match()
	end

	function edit.OnEnter()
		if edit.previous_search ~= edit:GetText() then
			perform_search()
			edit.previous_search = edit:GetText()
		elseif not table.IsEmpty(pace.tree_search_matches) then
			fwd:DoClick()
		else
			perform_search()
		end
		select_match()

		timer.Simple(0.1,function() edit:RequestFocus() end)
	end

end