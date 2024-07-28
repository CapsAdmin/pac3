local L = pace.LanguageString

local function populate_part_menu(menu, part, func)
	if part:HasChildren() then
		local menu, pnl = menu:AddSubMenu(pace.pac_show_uniqueid:GetBool() and string.format("%s (%s)", part:GetName(), part:GetPrintUniqueID()) or part:GetName(), function()
			func(part)
		end)

		pnl:SetImage(part.Icon)

		for key, part in ipairs(part:GetChildren()) do
			populate_part_menu(menu, part, func)
		end
	else
		menu:AddOption(pace.pac_show_uniqueid:GetBool() and string.format("%s (%s)", part:GetName(), part:GetPrintUniqueID()) or part:GetName(), function()
			func(part)
		end):SetImage(part.Icon)
	end
end


local function get_friendly_name(ent)
	if not IsValid(ent) then return "NULL" end
	local name = ent.GetName and ent:GetName()
	if not name or name == "" then
		name = ent:GetClass()
	end

	if ent:EntIndex() == -1 then

		if name == "10C_BaseFlex" then
			return "csentity - " .. ent:GetModel()
		end

		return name
	end

	if ent == pac.LocalPlayer then
		return name
	end

	return ent:EntIndex() .. " - " .. name
end

do -- bone
	local PANEL = {}

	PANEL.ClassName = "properties_bone"
	PANEL.Base = "pace_properties_base_type"

	function PANEL:MoreOptionsLeftClick()
		if not pace.current_part:IsValid() or not pace.current_part:GetParentOwner():IsValid() then return end

		pace.SelectBone(pace.current_part:GetParentOwner(), function(data)
			if not self:IsValid() then return end
			self:SetValue(L(data.friendly))
			self.OnValueChanged(data.friendly)
		end, pace.current_part.ClassName == "bone" or pace.current_part.ClassName == "timeline_dummy_bone")
	end

	function PANEL:MoreOptionsRightClick()
		local bones = pac.GetModelBones(pace.current_part:GetParentOwner())

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

	function PANEL:EncodeEdit(uid)
		local part = pac.GetPartFromUniqueID(pac.Hash(pac.LocalPlayer), uid)

		if part:IsValid() then
			return part:GetName()
		end

		return ""
	end

	function PANEL:DecodeEdit(name)

		if name:Trim() ~= "" then
			local part = pac.FindPartByName(pac.Hash(pac.LocalPlayer), name, pace.current_part)
			if part:IsValid() then
				return part:GetUniqueID()
			end
		end

		return ""
	end

	function PANEL:OnValueSet(val)
		if not IsValid(self.part) then return end
		local part = pac.GetPartFromUniqueID(pac.Hash(pac.LocalPlayer), val)

		if IsValid(self.Icon) then self.Icon:Remove() end


		if not part:IsValid() then
			if self.CurrentKey == "TargetEntityUID" then
				local owner = pace.current_part:GetOwner()
				self:SetText(" " .. get_friendly_name(owner))
				local pnl = vgui.Create("DImage", self)
				pnl:SetImage(pace.GroupsIcons.entity)
				self.Icon = pnl
			end
			return
		end

		if self.CurrentKey == "TargetEntityUID" then
			if part.Owner:IsValid() then
				local owner = part:GetOwner()
				self:SetText(" " .. part:GetName())
			else
				local owner = part:GetOwner()
				self:SetText(" " .. get_friendly_name(owner))
			end
			local pnl = vgui.Create("DImage", self)
			pnl:SetImage(pace.GroupsIcons.entity)
			self.Icon = pnl
			return
		end

		self:SetText(" " .. (pace.pac_show_uniqueid:GetBool() and string.format("%s (%s)", part:GetName(), part:GetPrintUniqueID()) or part:GetName()))

		if
			GetConVar("pac_editor_model_icons"):GetBool() and
			part.is_model_part and
			part.GetModel and
			part:GetOwner():IsValid() and
			part.ClassName ~= "entity2" and
			part.ClassName ~= "weapon" -- todo: is_model_part is true, class inheritance issues?
		then
			local pnl = vgui.Create("SpawnIcon", self)
			pnl:SetModel(part:GetOwner():GetModel() or "")
			self.Icon = pnl
		elseif isstring(part.Icon) then
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
			self:SetValue(part:GetUniqueID())
			self.OnValueChanged(part)
		end, self)
	end

	function PANEL:MoreOptionsRightClick(key)
		local menu = DermaMenu()

		menu:MakePopup()

		for _, part in pairs(pac.GetLocalParts()) do
			if not part:HasParent() and part:GetShowInEditor() then
				populate_part_menu(menu, part, function(part)
					if not self:IsValid() then return end
					self:SetValue(part:GetUniqueID())
					self.OnValueChanged(part)
				end)
			end
		end

		if key ~= "ParentUID" then
			menu:AddOption("none", function()
				self:SetValue("")
				self.OnValueChanged("")
			end):SetImage(pace.MiscIcons.clear)
		end

		pace.FixMenu(menu)
	end

	pace.RegisterPanel(PANEL)
end

do -- custom animation frame event
	local PANEL = {}

	PANEL.ClassName = "properties_custom_animation_frame"
	PANEL.Base = "pace_properties_part"

	function PANEL:MoreOptionsLeftClick()
		pace.CreateSearchList(
			self,
			self.CurrentKey,
			L"custom animations",

			function(list)
				list:AddColumn(L"name")
				list:AddColumn(L"id")
			end,

			function()
				local output = {}
				local parts = pac.GetLocalParts()

				for i, part in pairs(parts) do

					if part.ClassName == "custom_animation" then
						local name = part.Name ~= "" and part.Name or "no name"
						output[i] = name
					end
				end

				return output
			end,

			function() return pace.current_part:GetProperty("animation") end,

			function(list, key, val)
				return list:AddLine(val, key)
			end,

			function(key, val) return val end,

			function(key, val) return key end
		)
	end

	function PANEL:MoreOptionsRightClick(key)
		local menu = DermaMenu()

		menu:MakePopup()

		for _, part in pairs(pac.GetLocalParts()) do
			if not part:HasParent() and part:GetShowInEditor() then
				populate_part_menu(menu, part, function(part)
					if not self:IsValid() then return end
					if part.ClassName ~= "custom_animation" then return end
					self:SetValue(part:GetUniqueID())
					self.OnValueChanged(part:GetUniqueID())
				end)
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

		for key, name in pairs(pac.OwnerNames) do
			menu:AddOption(name, function() pace.current_part:SetOwnerName(name) self.OnValueChanged(name) end)
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

			local ent = pace.current_part:GetOwner()
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

do -- event ranger
	local PANEL = {}

	PANEL.ClassName = "properties_ranger"
	PANEL.Base = "pace_properties_number"

	function PANEL:OnValueSet()
		local function stop()
			hook.Remove("PostDrawOpaqueRenderables", "pace_draw_ranger")
		end

		local last_part = pace.current_part

		hook.Add("PostDrawOpaqueRenderables", "pace_draw_ranger", function()
			local part = pace.current_part
			if not part:IsValid() then stop() return end
			if part ~= last_part then stop() return end
			if part.ClassName ~= "event" then stop() return end
			if part:GetEvent() ~= "ranger" then stop() return end

			local distance = part:GetProperty("distance")
			local compare = part:GetProperty("compare")
			local trigger = part.event_triggered
			local parent = part:GetParent()
			if not parent:IsValid() or not parent.GetWorldPosition then stop() return end
			local startpos = parent:GetWorldPosition()
			local endpos
			local color

			if self.udata then
				if self.udata.ranger_property == "distance" then
					endpos = startpos + parent:GetWorldAngles():Forward() * distance
					color = Color(255,255,255)
				elseif self.udata.ranger_property == "compare" then
					endpos = startpos + parent:GetWorldAngles():Forward() * compare
					color = Color(10,255,10)
				end
				render.DrawLine( startpos, endpos, trigger and Color(255,0,0) or color)
			end
		end)
	end

	pace.RegisterPanel(PANEL)
end

do -- event is_touching
	local PANEL = {}

	PANEL.ClassName = "properties_is_touching"
	PANEL.Base = "pace_properties_number"

	function PANEL:OnValueSet()
		local function stop()
			hook.Remove("PostDrawOpaqueRenderables", "pace_draw_is_touching")
		end
		local last_part = pace.current_part

		hook.Add("PostDrawOpaqueRenderables", "pace_draw_is_touching", function()
			local part = pace.current_part
			if part ~= last_part then stop() return end
			if not part:IsValid() then stop() return end
			if part.ClassName ~= "event" then stop() return end
			if not (part:GetEvent() == "is_touching" or part:GetEvent() == "is_touching_scalable" or part:GetEvent() == "is_touching_filter" or part:GetEvent() == "is_touching_life") then stop() return end

			local extra_radius = part:GetProperty("extra_radius") or 0
			local nearest_model = part:GetProperty("nearest_model") or false
			local no_npc = part:GetProperty("no_npc") or false
			local no_players = part:GetProperty("no_players") or false
			local x_stretch = part:GetProperty("x_stretch") or 1
			local y_stretch = part:GetProperty("y_stretch") or 1
			local z_stretch = part:GetProperty("z_stretch") or 1

			local ent
			if part.RootOwner then
				ent = part:GetRootPart():GetOwner()
			else
				ent = part:GetOwner()
			end

			if nearest_model then ent = part:GetOwner() end

			if not IsValid(ent) then stop() return end
			local radius

			if radius == 0 and IsValid(ent.pac_projectile) then
				radius = ent.pac_projectile:GetRadius()
			end

			local mins = Vector(-x_stretch,-y_stretch,-z_stretch)
			local maxs = Vector(x_stretch,y_stretch,z_stretch)

			radius = math.max(ent:BoundingRadius() + extra_radius + 1, 1)
			mins = mins * radius
			maxs = maxs * radius

			local startpos = ent:WorldSpaceCenter()
			local b = false
			if part:GetEvent() == "is_touching" or part:GetEvent() == "is_touching_scalable" then
				local tr = util.TraceHull( {
					start = startpos,
					endpos = startpos,
					maxs = maxs,
					mins = mins,
					filter = {part:GetRootPart():GetOwner(),ent}
				} )
				b = tr.Hit
			elseif part:GetEvent() == "is_touching_life" then
				local found = false
				local ents_hits = ents.FindInBox(startpos + mins, startpos + maxs)
				for _,ent2 in pairs(ents_hits) do

					if IsValid(ent2) and (ent2 ~= ent and ent2 ~= part:GetRootPart():GetOwner()) and
					(ent2:IsNPC() or ent2:IsPlayer())
					then
						found = true
						if ent2:IsNPC() and no_npc then
							found = false
						elseif ent2:IsPlayer() and no_players then
							found = false
						end
						if found then b = true end
					end
				end
			elseif part:GetEvent() == "is_touching_filter" then
				local ents_hits = ents.FindInBox(startpos + mins, startpos + maxs)
				for _,ent2 in pairs(ents_hits) do
					if (ent2 ~= ent and ent2 ~= part:GetRootPart():GetOwner()) and
						(ent2:IsNPC() or ent2:IsPlayer()) and
						not ( (no_npc and ent2:IsNPC()) or (no_players and ent2:IsPlayer()) )
					then b = true end
				end
			end

			if self.udata then
				render.DrawWireframeBox( startpos, Angle( 0, 0, 0 ), mins, maxs, b and Color(255,0,0) or Color(255,255,255), true )
			end
		end)
	end

	pace.RegisterPanel(PANEL)
end

do -- event seen_by_player
	local PANEL = {}

	PANEL.ClassName = "properties_seen_by_player"
	PANEL.Base = "pace_properties_number"

	function PANEL:OnValueSet()
		local function stop()
			hook.Remove("PostDrawOpaqueRenderables", "pace_draw_is_touching2")
		end
		local last_part = pace.current_part

		hook.Add("PostDrawOpaqueRenderables", "pace_draw_is_touching2", function()
			local part = pace.current_part
			if part ~= last_part then stop() return end
			if not part:IsValid() then stop() return end
			if part.ClassName ~= "event" then stop() return end
			if not (part:GetEvent() == "seen_by_player") then stop() return end
			if not pace.IsActive() then stop() return end

			local extra_radius = part:GetProperty("extra_radius") or 0

			local ent
			if part.RootOwner then
				ent = part:GetRootPart():GetOwner()
			else
				ent = part:GetOwner()
			end

			if not IsValid(ent) then stop() return end

			local mins = Vector(-extra_radius,-extra_radius,-extra_radius)
			local maxs = Vector(extra_radius,extra_radius,extra_radius)

			local b = false
			local players_see = {}
			for _,v in ipairs(player.GetAll()) do
				if v == ent then continue end
				local eyetrace = v:GetEyeTrace()

				local this_player_sees = false
				if util.IntersectRayWithOBB(eyetrace.StartPos, eyetrace.HitPos - eyetrace.StartPos, LocalPlayer():GetPos() + LocalPlayer():OBBCenter(), Angle(0,0,0), Vector(-extra_radius,-extra_radius,-extra_radius), Vector(extra_radius,extra_radius,extra_radius)) then
					b = true
					this_player_sees = true
				end
				if eyetrace.Entity == ent then
					b = true
					this_player_sees = true
				end
				render.DrawLine(eyetrace.StartPos, eyetrace.HitPos, this_player_sees and Color(255, 0,0) or Color(255,255,255), true)
			end
			::CHECKOUT::
			if self.udata then
				render.DrawWireframeBox( ent:GetPos() + ent:OBBCenter(), Angle( 0, 0, 0 ), mins, maxs, b and Color(255,0,0) or Color(255,255,255), true )
			end
		end)
	end

	pace.RegisterPanel(PANEL)
end

do --projectile radius
	local PANEL = {}

	PANEL.ClassName = "properties_projectile_radii"
	PANEL.Base = "pace_properties_number"

	local testing_mesh
	local drawing = false
	local phys_mesh_vis = {}
	function PANEL:OnValueSet()
		time = os.clock() + 6
		local function stop()
			hook.Remove("PostDrawOpaqueRenderables", "pace_draw_projectile_radii")
			timer.Simple(0.2, function() SafeRemoveEntity(testing_mesh) end) drawing = false
		end
		local last_part = pace.current_part

		hook.Add("PostDrawOpaqueRenderables", "pace_draw_projectile_radii", function()
			drawing = true
			if time < os.clock() then
				stop()
			end
			if not pace.current_part:IsValid() then stop() return end
			if pace.current_part.ClassName ~= "projectile" then stop() return end
			if self.udata then
				if last_part.Sphere then
					render.DrawWireframeSphere( last_part:GetWorldPosition(), last_part.Radius, 10, 10, Color(255,255,255), true )
					render.DrawWireframeSphere( last_part:GetWorldPosition(), last_part.DamageRadius, 10, 10, Color(255,0,0), true )
				else
					local mins_ph = Vector(last_part.Radius,last_part.Radius,last_part.Radius)
					local mins_dm = Vector(last_part.DamageRadius,last_part.DamageRadius,last_part.DamageRadius)
					if last_part.OverridePhysMesh then
						if not IsValid(testing_mesh) then testing_mesh = ents.CreateClientProp("models/props_junk/PopCan01a.mdl") end
						testing_mesh:PhysicsInit(SOLID_VPHYSICS)
						if testing_mesh:GetModel() ~= last_part.FallbackSurfpropModel then
							testing_mesh:SetModel(last_part.FallbackSurfpropModel)
							testing_mesh:PhysicsInit(SOLID_VPHYSICS)
							phys_mesh_vis = {}
							for i = 0, testing_mesh:GetPhysicsObjectCount() - 1 do
								for i2,tri in ipairs(testing_mesh:GetPhysicsObjectNum( i ):GetMeshConvexes()) do
									for i3,vert in ipairs(tri) do
										table.insert(phys_mesh_vis, vert)
									end
								end
							end
						end
						local obj = Mesh()
						obj:BuildFromTriangles(phys_mesh_vis)
						cam.Start3D(pac.EyePos, pac.EyeAng)
							render.SetMaterial(Material("models/wireframe"))
								local mat = Matrix()
								mat:Translate(last_part:GetWorldPosition())
								mat:Rotate(last_part:GetWorldAngles())
								mat:Scale(Vector(last_part.Radius,last_part.Radius,last_part.Radius))
								cam.PushModelMatrix( mat )
								render.CullMode(MATERIAL_CULLMODE_CW)obj:Draw()
								render.CullMode(MATERIAL_CULLMODE_CCW)obj:Draw()
							cam.PopModelMatrix()
						cam.End3D()
					else
						render.DrawWireframeBox( last_part:GetWorldPosition(), last_part:GetWorldAngles(), -mins_ph, mins_ph, Color(255,255,255), true )
					end
					render.DrawWireframeBox( last_part:GetWorldPosition(), last_part:GetWorldAngles(), -mins_dm, mins_dm, Color(255,0,0), true )
				end

			end
		end)
	end

	pace.RegisterPanel(PANEL)
end