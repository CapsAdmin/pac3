local L = pace.LanguageString

local function populate_part_menu(menu, part, func)
	if part:HasChildren() then
		local menu, pnl = menu:AddSubMenu(part:GetName(), function()
			pace.current_part[func](pace.current_part, part)
		end)

		pnl:SetImage(part.Icon)

		for key, part in ipairs(part:GetChildren()) do
			populate_part_menu(menu, part, func)
		end
	else
		menu:AddOption(part:GetName(), function()
			pace.current_part[func](pace.current_part, part)
		end):SetImage(part.Icon)
	end
end

do -- bone
	local PANEL = {}

	PANEL.ClassName = "properties_bone"
	PANEL.Base = "pace_properties_base_type"

	function PANEL:MoreOptionsLeftClick()
		if not pace.current_part:IsValid() or not pace.current_part:GetOwner():IsValid() then return end

		pace.SelectBone(pace.current_part:GetOwner(), function(data)
			if not self:IsValid() then return end
			self:SetValue(L(data.friendly))
			self.OnValueChanged(data.friendly)
		end, pace.current_part.ClassName == "bone" or pace.current_part.ClassName == "timeline_dummy_bone")
	end

	function PANEL:MoreOptionsRightClick()
		local bones = pac.GetModelBones(pace.current_part:GetOwner())

		local menu = DermaMenu()

		menu:MakePopup()

		local list = {}
		for k,v in pairs(bones) do
			table.insert(list, v.friendly)
		end

		pace.CreateSearchList(
			self,
			self.CurrentKey,
			L"bones",
			function(list)
				list:AddColumn(L"name")
			end,
			function()
				return list
			end,
			function()
				return pace.current_part:GetBone()
			end,
			function(list, key, val)
				return list:AddLine(val)
			end
		)
	end

	pace.RegisterPanel(PANEL)
end

do -- part
	local PANEL = {}

	PANEL.ClassName = "properties_part"
	PANEL.Base = "pace_properties_base_type"

	function PANEL:OnValueSet(val)
		if not IsValid(self.part) then return end
		local func_name = "Get" .. self.CurrentKey:sub(1, -5)
		local part = self.part[func_name](self.part)

		if IsValid(self.Icon) then self.Icon:Remove() end

		if not part:IsValid() then
			return
		end

		if
			GetConVar("pac_editor_model_icons"):GetBool() and
			part.is_model_part and
			part.GetModel and
			part:GetEntity():IsValid() and
			part.ClassName ~= "entity2" and
			part.ClassName ~= "weapon" -- todo: is_model_part is true, class inheritance issues?
		then
			local pnl = vgui.Create("SpawnIcon", self)
			pnl:SetModel(part:GetEntity():GetModel() or "")
			self.Icon = pnl
		elseif type(part.Icon) == "string" then
			local pnl = vgui.Create("DImage", self)
			pnl:SetImage(part.Icon)
			self.Icon = pnl
		end
	end

	function PANEL:PerformLayout()
		if not IsValid(self.Icon) then return end
		self:SetTextInset(11, 0)
		self.Icon:SetPos(4,0)
		surface.SetFont(pace.CurrentFont)
		local w,h = surface.GetTextSize(".")
		h = h / 1.5
		self.Icon:SetSize(h, h)
		self.Icon:CenterVertical()
	end

	function PANEL:MoreOptionsLeftClick()
		pace.SelectPart(pac.GetLocalParts(), function(part)
			if not self:IsValid() then return end
			self:SetValue(part:GetName())
			self.OnValueChanged(part)
		end)
	end

	function PANEL:MoreOptionsRightClick(key)
		local menu = DermaMenu()

		menu:MakePopup()

		for _, part in pairs(pac.GetLocalParts()) do
			if not part:HasParent() then
				populate_part_menu(menu, part, "Set" .. key)
			end
		end

		pace.FixMenu(menu)
	end

	pace.RegisterPanel(PANEL)
end

do -- owner
	local PANEL = {}

	PANEL.ClassName = "properties_ownername"
	PANEL.Base = "pace_properties_base_type"

	function PANEL:MoreOptionsLeftClick()
		pace.SelectEntity(function(ent)
			if not self:IsValid() then return end
			pace.current_part:SetOwnerName(ent:EntIndex())
			local name = pace.current_part:GetOwnerName()
			self.OnValueChanged(name)
			self:SetValue(L(name))
		end)
	end

	function PANEL:MoreOptionsRightClick()
		local menu = DermaMenu()
		menu:MakePopup()

		local function get_friendly_name(ent)
			local name = ent.GetName and ent:GetName()
			if not name or name == "" then
				name = ent:GetClass()
			end

			return ent:EntIndex() .. " - " .. name
		end

		for key, name in pairs(pac.OwnerNames) do
			menu:AddOption(name, function() pace.current_part:SetOwnerName(name) end)
		end

		local entities = menu:AddSubMenu(L"entities", function() end)
		entities.GetDeleteSelf = function() return false end
		for _, ent in pairs(ents.GetAll()) do
			if ent:EntIndex() > 0 then
				entities:AddOption(get_friendly_name(ent), function()
					pace.current_part:SetOwnerName(ent:EntIndex())
					self.OnValueChanged(ent:EntIndex())
				end)
			end
		end

		pace.FixMenu(menu)
	end

	pace.RegisterPanel(PANEL)
end

do -- sequence list
	local PANEL = {}

	PANEL.ClassName = "properties_sequence"
	PANEL.Base = "pace_properties_base_type"

	function PANEL:MoreOptionsLeftClick()
		pace.CreateSearchList(
			self,
			self.CurrentKey,
			L"animations",

			function(list)
				list:AddColumn(L"id"):SetFixedWidth(25)
				list:AddColumn(L"name")
			end,

			function()
				return pace.current_part:GetSequenceList()
			end,

			function()
				return pace.current_part.SequenceName or pace.current_part.GestureName
			end,

			function(list, key, val)
				return list:AddLine(key, val)
			end
		)
	end

	pace.RegisterPanel(PANEL)
end

do -- aimpart
	local PANEL = {}

	PANEL.ClassName = "properties_aimpartname"
	PANEL.Base = "pace_properties_base_type"

	function PANEL:MoreOptionsLeftClick()
		pace.SelectPart(pac.GetLocalParts(), function(part)
			if not self:IsValid() then return end
			self:SetValue(part:GetName())
			self.OnValueChanged(part)
		end)
	end

	function PANEL:MoreOptionsRightClick(key)
		local menu = DermaMenu()
		menu:MakePopup()

		for key, name in pairs(pac.AimPartNames) do
			menu:AddOption(L(key), function() pace.current_part:SetAimPartName(name) end):SetImage("icon16/eye.png")
		end

		for _, part in pairs(pac.GetLocalParts()) do
			if not part:HasParent() then
				populate_part_menu(menu, part, "SetAimPartName")
			end
		end

		pace.FixMenu(menu)
	end

	pace.RegisterPanel(PANEL)
end

do -- model
	local PANEL = {}

	PANEL.ClassName = "properties_model"
	PANEL.Base = "pace_properties_base_type"

	function PANEL:MoreOptionsRightClick()
		pace.SafeRemoveSpecialPanel()
		g_SpawnMenu:Open()
	end

	function PANEL:MoreOptionsLeftClick(key)
		pace.close_spawn_menu = true
		pace.SafeRemoveSpecialPanel()

		local part = pace.current_part


		pace.AssetBrowser(function(path)
			if not part:IsValid() then return end
			-- because we refresh the properties

			if IsValid(self) and self.OnValueChanged then
				self.OnValueChanged(path)
			end

			if pace.current_part.SetMaterials then
				local model = pace.current_part:GetModel()
				local part = pace.current_part
				if part.pace_last_model and part.pace_last_model ~= model then
					part:SetMaterials("")
				end
				part.pace_last_model = model
			end

			pace.PopulateProperties(pace.current_part)

			for k,v in ipairs(pace.properties.List) do
				if v.panel and v.panel.part == part and v.key == key then
					self = v.panel
					break
				end
			end

		end, "models")

		pac.AddHook("Think", "pace_close_browser", function()
			if part ~= pace.current_part then
				pac.RemoveHook("Think", "pace_close_browser")
				pace.model_browser:SetVisible(false)
			end
		end)
	end

	pace.RegisterPanel(PANEL)
end

do -- materials and textures
	local PANEL_MATERIAL = {}

	PANEL_MATERIAL.ClassName = "properties_material"
	PANEL_MATERIAL.Base = "pace_properties_base_type"

	function PANEL_MATERIAL:MoreOptionsLeftClick(key)
		pace.AssetBrowser(function(path)
			if not self:IsValid() then return end
			path = path:match("materials/(.+)%.vmt") or "error"
			self:SetValue(path)
			self.OnValueChanged(path)
		end, "materials", key)
	end

	function PANEL_MATERIAL:MoreOptionsRightClick()
		pace.SafeRemoveSpecialPanel()

		local pnl = pace.CreatePanel("mat_browser")

		pace.ShowSpecial(pnl, self, 300)

		function pnl.MaterialSelected(_, path)
			self:SetValue(path)
			self.OnValueChanged(path)
		end

		pace.ActiveSpecialPanel = pnl
	end

	local PANEL = {}
	local pace_material_display

	PANEL.ClassName = "properties_textures"
	PANEL.Base = "pace_properties_base_type"

	function PANEL:MoreOptionsLeftClick()
		pace.AssetBrowser(function(path)
			if not self:IsValid() then return end
			path = path:match("materials/(.+)%.vtf") or "error"
			self:SetValue(path)
			self.OnValueChanged(path)
		end, "textures")
	end

	function PANEL:MoreOptionsRightClick()
		pace.SafeRemoveSpecialPanel()

		local pnl = pace.CreatePanel("mat_browser")

		pace.ShowSpecial(pnl, self, 300)

		function pnl.MaterialSelected(_, path)
			self:SetValue(path)
			self.OnValueChanged(path)
		end

		pace.ActiveSpecialPanel = pnl
	end

	function PANEL:HUDPaint()
		if IsValid(self.editing) then return self:MustHideTexture() end
		-- Near Button?
		-- local w, h = self:GetSize()
		-- local x, y = self:LocalToScreen(w, 0)

		-- Near cursor
		local W, H = ScrW(), ScrH()
		local x, y = input.GetCursorPos()
		local w, h = 256, 256
		x = x + 12
		y = y + 4

		if x + w > W then
			x = x - w - 24
		end

		if y + h > H then
			y = y - h - 8
		end

		surface.SetDrawColor(255, 255, 255, 255)
		surface.SetAlphaMultiplier(1)
		surface.SetMaterial(pace_material_display)
		surface.DrawTexturedRect(x, y, w, h)
	end

	PANEL_MATERIAL.HUDPaint = PANEL.HUDPaint

	function PANEL:MustShowTexture()
		if self.isShownTexture then return end

		if not pace_material_display then
			pace_material_display = CreateMaterial('pace_material_display', "UnlitGeneric", {})
		end

		if pace.current_part[self.CurrentKey] then
			if pace.current_part[self.CurrentKey] == "" then
				pace_material_display:SetTexture("$basetexture", "models/debug/debugwhite")
			elseif not string.find(pace.current_part[self.CurrentKey], '^https?://') then
				pace_material_display:SetTexture("$basetexture", pace.current_part[self.CurrentKey])
			else
				local function callback(mat, tex)
					if not tex then return end
					pace_material_display:SetTexture("$basetexture", tex)
				end

				pac.urltex.GetMaterialFromURL(pace.current_part[self.CurrentKey], callback, false, 'UnlitGeneric')
			end
		end

		local id = tostring(self)
		pac.AddHook("PostRenderVGUI", id, function()
			if self:IsValid() then
				self:HUDPaint()
			else
				pac.RemoveHook("PostRenderVGUI", id)
			end
		end)
		self.isShownTexture = true
	end

	PANEL_MATERIAL.MustShowTexture = PANEL.MustShowTexture

	function PANEL:MustHideTexture()
		if not self.isShownTexture then return end
		self.isShownTexture = false
		pac.RemoveHook('PostRenderVGUI', tostring(self))
	end

	PANEL_MATERIAL.MustHideTexture = PANEL.MustHideTexture

	function PANEL:ThinkTextureDisplay()
		if self.preTextureThink then self:preTextureThink() end
		if not IsValid(self.textureButton) or IsValid(self.editing) then return end
		local rTime = RealTime()
		self.lastHovered = self.lastHovered or rTime

		if not self.textureButton:IsHovered() and not self:IsHovered() then
			self.lastHovered = rTime
		end

		if self.lastHovered + 0.5 < rTime then
			self:MustShowTexture()
		else
			self:MustHideTexture()
		end
	end

	PANEL_MATERIAL.ThinkTextureDisplay = PANEL.ThinkTextureDisplay

	function PANEL:OnMoreOptionsLeftClickButton(btn)
		self.preTextureThink = self.Think
		self.Think = self.ThinkTextureDisplay
		self.textureButton = btn
	end

	PANEL_MATERIAL.OnMoreOptionsLeftClickButton = PANEL.OnMoreOptionsLeftClickButton

	pace.RegisterPanel(PANEL)
	pace.RegisterPanel(PANEL_MATERIAL)
end


do -- sound
	local PANEL = {}

	PANEL.ClassName = "properties_sound"
	PANEL.Base = "pace_properties_base_type"

	function PANEL:MoreOptionsLeftClick()
		pace.AssetBrowser(function(path)
			if not self:IsValid() then return end

			self:SetValue(path)
			self.OnValueChanged(path)

			if pace.current_part:IsValid() then
				pace.current_part:OnShow()
			end
		end, "sound")
	end

	pace.RegisterPanel(PANEL)
end

do -- model modifiers
	local PANEL = {}

	PANEL.ClassName = "properties_model_modifiers"
	PANEL.Base = "pace_properties_base_type"

	function PANEL:ExtraPopulate()
		local part = pace.current_part
		local ent = part:GetEntity()
		if not ent:IsValid() or not ent:GetBodyGroups() then return end

		local group = pac.GetPropertyUserdata(part, self.CurrentKey) and pac.GetPropertyUserdata(part, self.CurrentKey).group

		local tbl = {}

		if ent:SkinCount() and ent:SkinCount() > 1 then
			tbl.skin = {
				val = ent:GetSkin(),
				callback = function(val)
					local tbl = part:ModelModifiersToTable(part:GetModelModifiers())
					tbl.skin = val
					part:SetModelModifiers(part:ModelModifiersToString(tbl))
				end,
				userdata = {editor_onchange = function(self, num) return math.Clamp(math.Round(num), 0, ent:SkinCount() - 1) end, group = group},
			}
		end

		for _, info in ipairs(ent:GetBodyGroups()) do
			if info.num > 1 then
				tbl[info.name] = {
					val = part:ModelModifiersToTable(part:GetModelModifiers())[info.name] or 0,
					callback = function(val)
						local tbl = part:ModelModifiersToTable(part:GetModelModifiers())
						tbl[info.name] = val
						part:SetModelModifiers(part:ModelModifiersToString(tbl))
					end,
					userdata = {editor_onchange = function(self, num) return math.Clamp(math.Round(num), 0, info.num - 1) end, group = "bodygroups"},
				}
			end
		end
		pace.properties:Populate(tbl, true)
	end

	pace.RegisterPanel(PANEL)
end

do -- model modifiers
	local PANEL = {}

	PANEL.ClassName = "properties_model_materials"
	PANEL.Base = "pace_properties_base_type"

	function PANEL:ExtraPopulate()
		local part = pace.current_part
		local ent = part:GetEntity()
		if not ent:IsValid() or not ent:GetMaterials() or #ent:GetMaterials() == 1 then return end

		local tbl = {}
		local cur = part.Materials:Split(";")

		for i, name in ipairs(ent:GetMaterials()) do
			name = name:match(".+/(.+)") or name
			tbl[name] = {
				val = cur[i] or "",
				callback = function(val)
					if not ent:IsValid() or not ent:GetMaterials() or #ent:GetMaterials() == 1 then return end
					local tbl = part.Materials:Split(";")
					tbl[i] = val
					for i, name in ipairs(ent:GetMaterials()) do
						tbl[i] = tbl[i] or ""
					end
					part:SetMaterials(table.concat(tbl, ";"))
				end,
				userdata = {editor_panel = "material", editor_friendly = name, group = "sub materials"},
			}
		end
		pace.properties:Populate(tbl, true)
	end

	pace.RegisterPanel(PANEL)
end

do -- arguments
	local PANEL = {}

	PANEL.ClassName = "properties_event_arguments"
	PANEL.Base = "pace_properties_base_type"

	function PANEL:ExtraPopulate()
		if not pace.current_part:IsValid() or pace.current_part.ClassName ~= "event" then return end

		local data = pace.current_part.Events[pace.current_part.Event]
		if not data then return end

		local tbl = {}
		local args = {pace.current_part:GetParsedArguments(data)}
		if args then
			for pos, arg in ipairs(data:GetArguments()) do
				local nam, typ, userdata = unpack(arg)
				if args[pos] then
					arg = args[pos]
				else
					if typ == "string" then
						arg = ""
					elseif typ == "number" then
						arg = 0
					elseif typ == "boolean" then
						arg = false
					end
				end
				if typ == "number" then
					arg = tonumber(arg) or 0
				elseif typ == "boolean" then
					arg = tobool(arg) or false
				end
				tbl[nam] = {
					val = arg,
					callback = function(val)
						if not pace.current_part:IsValid() then return end
						local args = {pace.current_part:GetParsedArguments(data)}
						args[pos] = val
						pace.current_part:ParseArguments(unpack(args))
						--self:SetValue(pace.current_part.Arguments)
					end,
					userdata = userdata,
				}
			end
			pace.properties:Populate(tbl, true, L"arguments")
		end

	end

	pace.RegisterPanel(PANEL)
end

do -- script
	local PANEL = {}

	PANEL.ClassName = "properties_code"
	PANEL.Base = "pace_properties_base_type"

	function PANEL:MoreOptionsLeftClick()
		pace.SafeRemoveSpecialPanel()

		local frame = vgui.Create("DFrame")
		frame:SetTitle(L"script")
		pace.ShowSpecial(frame, self, 512)
		frame:SetSizable(true)

		local editor = vgui.Create("pace_luapad", frame)
		editor:Dock(FILL)

		editor:SetText(pace.current_part:GetCode())
		editor.OnTextChanged = function(self)
			pace.current_part:SetCode(self:GetValue())
		end

		editor.last_error = ""

		function editor:CheckGlobal(str)
			local part = pace.current_part

			if not part:IsValid() then frame:Remove() return end

			return part:ShouldHighlight(str)
		end

		function editor:Think()
			local part = pace.current_part

			if not part:IsValid() then frame:Remove() return end

			local title = L"script editor"

			if part.Error then
				title = part.Error

				local line = tonumber(title:match("SCRIPT_ENV:(%d-):"))

				if line then
					title = title:match("SCRIPT_ENV:(.+)")
					if self.last_error ~= title then
						editor:SetScrollPosition(line)
						editor:SetErrorLine(line)
						self.last_error = title
					end
				end
			else
				editor:SetErrorLine(nil)

				if part.script_printing then
					title = part.script_printing
					part.script_printing = nil
				end
			end

			frame:SetTitle(title)
		end

		pace.ActiveSpecialPanel = frame
	end

	pace.RegisterPanel(PANEL)
end

do -- hull
	local PANEL = {}

	PANEL.ClassName = "properties_hull"
	PANEL.Base = "pace_properties_number"

	function PANEL:OnValueSet()
		local function stop()
			RunConsoleCommand("-duck")
			hook.Remove("PostDrawOpaqueRenderables", "pace_draw_hull")
		end

		local time = os.clock() + 3

		hook.Add("PostDrawOpaqueRenderables", "pace_draw_hull", function()

			if not pace.current_part:IsValid() then stop() return end
			if pace.current_part.ClassName ~= "entity2" then stop() return end

			local ent = pace.current_part:GetEntity()
			if not ent.GetHull then stop() return end
			if not ent.GetHullDuck then stop() return end

			local min, max = ent:GetHull()

			if self.udata and self.udata.crouch then
				min, max = ent:GetHullDuck()
				RunConsoleCommand("+duck")
			end

			min = min * ent:GetModelScale()
			max = max * ent:GetModelScale()

			render.DrawWireframeBox( ent:GetPos(), Angle(0), min, max, Color(255, 204, 51, 255), true )

			if time < os.clock() then
				stop()
			end
		end)
	end

	pace.RegisterPanel(PANEL)
end
