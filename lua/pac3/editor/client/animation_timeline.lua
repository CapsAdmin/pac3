local animations = pac.animations
local eases = animations.eases
local L = pace.LanguageString

pace.timeline = pace.timeline or {}
local timeline = pace.timeline

local secondDistance = 200 --100px per second on timeline

do
	local BUILDER, PART = pac.PartTemplate("base_movable")

	PART.ClassName = "timeline_dummy_bone"
	PART.show_in_editor = false
	PART.PropertyWhitelist = {
		Position = true,
		Angles = true,
		Bone = true,
	}

	function PART:GetParentOwner()
		return self:GetOwner()
	end

	function PART:GetBonePosition()
		local ent = self:GetOwner()

		local index = self:GetModelBoneIndex(self.Bone)
		if not index then return ent:GetPos(), ent:GetAngles() end

		pac.SetupBones(ent)
		local m = ent:GetBoneMatrix(index)

		local lm = Matrix()
		lm:SetTranslation(self.Position)
		lm:SetAngles(self.Angles)

		m = m * lm:GetInverse()

		if not m then return ent:GetPos(), ent:GetAngles() end

		return m:GetTranslation(), m:GetAngles()
	end

	BUILDER:Register()
end

function timeline.IsActive()
	return timeline.editing
end

local function check_tpose()
	if not timeline.entity:IsPlayer() then return end
	if timeline.data.Type == "sequence" then
		pac.AddHook("CalcMainActivity", "pac3_timeline", function(ply)
			if ply == timeline.entity then
				local act = ply:LookupSequence("ragdoll") or ply:LookupSequence("reference")
				return act, act
			end
		end)
	else
		pac.RemoveHook("CalcMainActivity", "pac3_timeline")
	end
end

timeline.interpolation = "cosine"

function timeline.SetInterpolation(str)
	timeline.interpolation = str
	timeline.data = timeline.data or {FrameData = {}}
	timeline.data.Interpolation = timeline.interpolation

	timeline.Save()
end

timeline.animation_type = "sequence"

function timeline.SetAnimationType(str)
	timeline.animation_type = str

	timeline.frame.add_keyframe_button:SetDisabled(timeline.animation_type == "posture")

	timeline.data = timeline.data or {FrameData = {}}
	timeline.data.Type = timeline.animation_type

	timeline.Save()
end

function timeline.SetCycle(f)
	animations.SetEntityAnimationCycle(timeline.entity, timeline.animation_part:GetAnimID(), f)
end

function timeline.GetCycle()
	return animations.GetEntityAnimationCycle(timeline.entity, timeline.animation_part:GetAnimID()) or 0
end

function timeline.Stop()
	timeline.frame:Stop()
end

function timeline.UpdateFrameData()
	if not timeline.selected_keyframe or not timeline.selected_bone then return end

	local data = timeline.selected_keyframe:GetData().BoneInfo[timeline.selected_bone] or {}

	data.MF = data.MF or 0
	data.MR = data.MR or 0
	data.MU = data.MU or 0

	data.RR = data.RR or 0
	data.RU = data.RU or 0
	data.RF = data.RF or 0

	timeline.dummy_bone:SetPosition(Vector(data.MF, -data.MR, data.MU))
	timeline.dummy_bone:SetAngles(Angle(data.RR, data.RU, data.RF))
end

function timeline.EditBone()
	pace.Call("PartSelected", timeline.dummy_bone)
	local boneData = pac.GetModelBones(timeline.entity)
	timeline.selected_bone = timeline.dummy_bone and
		timeline.dummy_bone:GetBone() and
		boneData[timeline.dummy_bone:GetBone()] and
		boneData[timeline.dummy_bone:GetBone()].real
		or false

	if not timeline.selected_bone then
		for k, v in pairs(boneData) do
			if not v.is_special and not v.is_attachment then
				timeline.selected_bone = v.real
				break
			end
		end

		if not timeline.selected_bone then
			timeline.selected_bone = '????'
		end
	end

	timeline.UpdateFrameData()
	pace.PopulateProperties(timeline.dummy_bone)

	check_tpose()
end

function timeline.Load(data)
	timeline.data = data

	if data and data.FrameData then
		animations.ConvertOldData(data)

		if not data.Type then
			data.Type = 0

			local frames = {}
			for k, v in pairs(data.FrameData) do
				table.insert(frames, v)
			end
			data.FrameData = frames
		end

		timeline.animation_part:SetInterpolation(data.Interpolation)
		timeline.animation_part:SetAnimationType(data.Type)
		timeline.frame:Clear()

		for i, v in ipairs(data.FrameData) do
			local keyframe = timeline.frame:AddKeyFrame(true)
			keyframe:SetFrameData(i, v)
		end

		timeline.SelectKeyframe(timeline.frame.keyframe_scroll:GetCanvas():GetChildren()[1])
	else
		timeline.data = {FrameData = {}, Type = timeline.animation_type, Interpolation = timeline.interpolation}
		timeline.frame:Clear()

		timeline.SelectKeyframe(timeline.frame:AddKeyFrame())
		timeline.Save()
	end

	timeline.UpdateFrameData()
end

function timeline.Save()
	local data = table.Copy(timeline.data)
	local part = timeline.animation_part
	timer.Create("pace_timeline_save", 0.1, 1, function()
		if part and part:IsValid() then
			animations.RegisterAnimation(part:GetAnimID(), data)
			if part:GetURL() ~= "" then
				file.Write("pac3/__animations/" .. part:GetName() .. ".txt", util.TableToJSON(data))
				part:SetData("")
			else
				part.Data = util.TableToJSON(data)
				timer.Create("pace_backup", 1, 1, function() pace.Backup() end)
			end
		end
	end)
end

function timeline.SelectKeyframe(keyframe)
	timeline.selected_keyframe = keyframe
	timeline.UpdateFrameData()
	timeline.EditBone()
	timeline.Save()

	animations.SetEntityAnimationFrame(timeline.entity, timeline.animation_part:GetAnimID(), keyframe.AnimationKeyIndex, 1)
	timeline.frame:Pause()
end

function timeline.IsEditingBone()
	return timeline.dummy_bone == pace.current_part
end

function timeline.Close()
	timeline.Save()

	-- old animeditor behavior
	if timeline.animation_part:GetURL() ~= "" then
		file.Write("pac3/__animations/backups/previous_session_"..os.date("%m%d%y%H%M%S")..".txt", util.TableToJSON(timeline.data))
	end

	timeline.editing = false

	if timeline.entity:IsValid() then
		timeline.Stop()
	end

	timeline.animation_part = nil
	timeline.frame:Remove()

	if timeline.dummy_bone and timeline.dummy_bone:IsValid() then
		timeline.dummy_bone:Remove()
	end

	pac.RemoveHook("pace_OnVariableChanged", "pac3_timeline")
	pac.RemoveHook("CalcMainActivity", "pac3_timeline")
end

function timeline.Open(part)
	file.CreateDir("pac3")
	file.CreateDir("pac3/__animations")
	file.CreateDir("pac3/__animations/backups")

	timeline.editing = false
	timeline.first_pass = true

	timeline.editing = true
	timeline.animation_part = part
	timeline.entity = part:GetOwner()

	timeline.frame = vgui.Create("pac3_timeline")
	timeline.frame:SetSize(ScrW()-pace.Editor:GetWide(),93)
	timeline.frame:SetPos(pace.Editor:GetWide(),ScrH()-timeline.frame:GetTall())
	timeline.frame:SetTitle("")
	timeline.frame:ShowCloseButton(false)

	timeline.SetAnimationType(part.AnimationType)

	if timeline.dummy_bone and timeline.dummy_bone:IsValid() then timeline.dummy_bone:Remove() end
	timeline.dummy_bone = pac.CreatePart("timeline_dummy_bone", timeline.entity)
	timeline.dummy_bone:SetOwner(timeline.entity)

	pac.AddHook("pace_OnVariableChanged", "pac3_timeline", function(part, key, val)
		if part == timeline.dummy_bone then
			if key == "Bone" then
				local boneData = pac.GetModelBones(timeline.entity)
				timeline.selected_bone = boneData[val] and boneData[val].real or false
				if not timeline.selected_bone then
					for k, v in pairs(boneData) do
						if not v.is_special and not v.is_attachment then
							timeline.selected_bone = v.real
							break
						end
					end

					if not timeline.selected_bone then
						timeline.selected_bone = '????'
					end
				end

				timer.Simple(0, function() timeline.EditBone() end) -- post variable changed?
			else
				local data = timeline.selected_keyframe:GetData()
				data.BoneInfo = data.BoneInfo or {}
				data.BoneInfo[timeline.selected_bone] = data.BoneInfo[timeline.selected_bone] or {}

				data.BoneInfo[timeline.selected_bone].MF = data.BoneInfo[timeline.selected_bone].MF or 0
				data.BoneInfo[timeline.selected_bone].MR = data.BoneInfo[timeline.selected_bone].MR or 0
				data.BoneInfo[timeline.selected_bone].MU = data.BoneInfo[timeline.selected_bone].MU or 0

				data.BoneInfo[timeline.selected_bone].RR = data.BoneInfo[timeline.selected_bone].RR or 0
				data.BoneInfo[timeline.selected_bone].RU = data.BoneInfo[timeline.selected_bone].RU or 0
				data.BoneInfo[timeline.selected_bone].RF = data.BoneInfo[timeline.selected_bone].RF or 0

				if key == "Position" then
					data.BoneInfo[timeline.selected_bone].MF = val.x
					data.BoneInfo[timeline.selected_bone].MR = -val.y
					data.BoneInfo[timeline.selected_bone].MU = val.z
				elseif key == "Angles" then
					data.BoneInfo[timeline.selected_bone].RR = val.p
					data.BoneInfo[timeline.selected_bone].RU = val.y
					data.BoneInfo[timeline.selected_bone].RF = val.r
				end
			end
			timeline.Save()
		elseif part == timeline.animation_part then
			if key == "Data" or key == "URL" then
				timeline.Load(animations.GetRegisteredAnimations()[part:GetAnimID()])
			elseif key == "AnimationType" then
				timeline.SetAnimationType(val)
			elseif key == "Interpolation" then
				timeline.SetInterpolation(val)
			elseif key == "Rate" then
				timeline.data.TimeScale = val
				timeline.Save()
			elseif key == "BonePower" then
				timeline.data.Power = val
				timeline.Save()
			end
		end
	end)

	timeline.Load(animations.GetRegisteredAnimations()[part:GetAnimID()])

	pac.RemoveHook("CalcMainActivity", "pac3_timeline")

	timeline.Stop()
end

pac.AddHook("pace_OnPartSelected", "pac3_timeline", function(part)
	if part.ClassName == "timeline_dummy_bone" then return end
	if part.ClassName == "custom_animation" then
		if timeline.editing then
			timeline.Close()
		end
		timeline.Open(part)
	elseif timeline.editing then
		timeline.Close()
	end
end)

do
	local TIMELINE = {}

	function TIMELINE:Init()
		self:DockMargin(0,0,0,0)
		self:DockPadding(0,35,0,0)

		do -- time display info
			local time = self:Add("DPanel")

			local test = L"frame" .. ": 10.888"
			surface.SetFont(pace.CurrentFont)
			local w,h = surface.GetTextSize(test)
			time:SetWide(w)

			time:SetTall(h*2 + 2)
			time:SetPos(0,1)
			time.Paint = function(s, w,h)
				self:GetSkin().tex.Tab_Control( 0, 0, w, h )
				self:GetSkin().tex.CategoryList.Header( 0, 0, w, h )

				if not timeline.animation_part then return end

				local w,h = draw.TextShadow({
					text = L"frame" .. ": " .. (animations.GetEntityAnimationFrame(timeline.entity, timeline.animation_part:GetAnimID()) or 0),
					font = pace.CurrentFont,
					pos = {2, 0},
					color = self:GetSkin().Colours.Category.Header
				}, 1, 100)

				draw.TextShadow({
					text = L"time" .. ": " .. math.Round(timeline.GetCycle() * animations.GetAnimationDuration(timeline.entity, timeline.animation_part:GetAnimID()), 3),
					font = pace.CurrentFont,
					pos = {2, h},
					color = self:GetSkin().Colours.Category.Header
				}, 1, 100)
			end
		end

		do
			local bottom = vgui.Create("DPanel", self)
			bottom:Dock(RIGHT)
			bottom:SetWide(72)
			do -- time controls
				local controls = bottom:Add("DPanel")
				controls:SetWide(100)
				controls:SetTall(bottom:GetTall())
				controls:Dock(BOTTOM)
				controls:SetTall(36)

				local size = 36
				local spacing = (size - 24)/2

				local play = controls:Add("DButton")
				play:SetSize(size,size)
				play:SetText("")
				play.DoClick = function() self:Toggle() end
				play:Dock(LEFT)

				local stop = controls:Add("DButton")
				stop:SetSize(size,size)
				stop:SetText("")
				stop.DoClick = function() self:Stop() end
				stop:Dock(LEFT)

				function play.PaintOver(_,w,h)
					surface.SetDrawColor(self:GetSkin().Colours.Button.Normal)
					draw.NoTexture()
					if self:IsPlaying() then
						surface.DrawRect(spacing, spacing, 10, h - spacing * 2)
						surface.DrawRect(spacing + 13, spacing, 10, h - spacing * 2)
					else
						surface.DrawPoly({
							{ x = spacing, y = spacing },
							{ x = w - spacing, y = h / 2 },
							{ x = spacing, y = h - spacing },
						})
					end
				end

				function stop:PaintOver(w,h)
					surface.SetDrawColor(self:GetSkin().Colours.Button.Normal)
					surface.DrawRect(spacing,spacing,24,24)
				end
			end
			do -- save/load
				local saveload = bottom:Add("DPanel")
				saveload:SetWide(100)
				saveload:SetTall(bottom:GetTall())
				saveload:Dock(TOP)
				saveload:SetTall(16)

				local add = saveload:Add("DImageButton")
				add:SetImage("icon16/add.png")
				add:SetTooltip(L"add keyframe")
				add:SizeToContents()
				add.DoClick = function() timeline.SelectKeyframe(self:AddKeyFrame()) timeline.Save() end
				add:Dock(LEFT)
				add:SetDisabled(true)
				self.add_keyframe_button = add

				local bone = saveload:Add("DImageButton")
				bone:SetImage("icon16/connect.png")
				bone:SetTooltip(L"edit bones")
				bone:SizeToContents()
				bone:Dock(LEFT)
				bone.DoClick = function()
					timeline.EditBone()
				end

				local save = saveload:Add("DImageButton")
				save:SetImage("icon16/disk.png")
				save:SetTooltip(L"save")
				save:SizeToContents()
				save:Dock(RIGHT)
				save.DoClick = function()
					Derma_StringRequest(
						L"question",
						L"save as",
						timeline.animation_part:GetName(),
						function(name)
							animations.RegisterAnimation(name, table.Copy(timeline.data))
							file.Write("pac3/__animations/" .. name .. ".txt", util.TableToJSON(timeline.data)) end,
						function() end,
						L"save",
						L"cancel"
					)
				end

				local load = saveload:Add("DImageButton")
				load:SetImage("icon16/folder.png")
				load:SizeToContents()
				load:Dock(RIGHT)
				load:SetTooltip(L"load")
				load.DoClick = function()
					local menu = DermaMenu()
					menu:SetPos(load:LocalToScreen())

					for _, name in pairs(file.Find("animations/*.txt", "DATA")) do
						menu:AddOption(name:match("(.+)%.txt"), function()
							timeline.Load(util.JSONToTable(file.Read("animations/" .. name)))
						end)
					end

					for _, name in pairs(file.Find("pac3/__animations/*.txt", "DATA")) do
						menu:AddOption(name:match("(.+)%.txt"), function()
							timeline.Load(util.JSONToTable(file.Read("pac3/__animations/" .. name)))
						end)
					end

					menu:PerformLayout()

					local x, y = bottom:LocalToScreen(0,0)
					x = x + bottom:GetWide()
					menu:SetPos(x - menu:GetWide(), y - menu:GetTall())
				end
			end

		end

		do -- keyframes
			local pnl = vgui.Create("pac_scrollpanel_horizontal",self)
			pnl:Dock(FILL)

			pnl:GetCanvas().Paint = function(_,w,h)
				derma.SkinHook( "Paint", "ListBox", self, w, h )
			end

			pnl.PaintOver = function()
				if not timeline.animation_part then return end

				local offset = -self.keyframe_scroll:GetCanvas():GetPos()

				local x = timeline.GetCycle() * self.keyframe_scroll:GetCanvas():GetWide()

				--self.keyframe_scroll.VBar:SetScroll(x - self.keyframe_scroll:GetWide()/2)
			end

			local old = pnl.PerformLayout

			function pnl.PerformLayout()
				old(pnl)

				local h = self:GetTall() - 45
				pnl:GetCanvas():SetTall(h)

				if self.moving then return end

				local x = 0
				for k,v in ipairs(pnl:GetCanvas():GetChildren()) do
					v:SetWide(math.max(1/v:GetData().FrameRate * secondDistance, 4))
					v:SetTall(h)
					v:SetPos(x, 0)
					x = x + v:GetWide()
				end
			end

			self.keyframe_scroll = pnl
		end

		do -- timeline
			local pnl = vgui.Create("DPanel",self)

			surface.SetFont(pace.CurrentFont)
			local _, h = surface.GetTextSize("|")
			pnl:SetTall(h + 2)
			pnl:Dock(TOP)
			pnl:NoClipping(true)
			pnl:SetCursor("sizewe")
			pnl.Think = function(_)
				if (self.dragging or pnl:IsHovered()) and input.IsMouseDown(MOUSE_LEFT) then
					if not self:IsPlaying() then
						self:Play()
						self:Pause()
					end

					if timeline.data and timeline.data.FrameData then
						local X = -self.keyframe_scroll:GetCanvas():GetPos() + pnl:ScreenToLocal(gui.MouseX(), 0)
						X = X / self.keyframe_scroll:GetCanvas():GetWide()
						timeline.SetCycle(X)
					end

					self.dragging = true
				end
				if not input.IsMouseDown(MOUSE_LEFT) then
					self.dragging = false
				end
			end
			local scrub = Material("icon16/bullet_arrow_down.png")
			local start = Material("icon16/control_play_blue.png")
			local restart = Material("icon16/control_repeat_blue.png")
			local estyle = Material("icon16/arrow_branch.png")
			pnl.Paint = function(s,w,h)
				local offset = -self.keyframe_scroll:GetCanvas():GetPos()
				local esoffset = self.keyframe_scroll:GetCanvas():GetPos()

				self:GetSkin().tex.Tab_Control( 0, 0, w, h )
				self:GetSkin().tex.CategoryList.Header( 0, 0, w, h )

				local previousSecond = offset-(offset%secondDistance)
				for i=previousSecond,previousSecond+s:GetWide(),secondDistance/2 do
					if i-offset > 0 and i-offset < ScrW() then
						local sec = i/secondDistance
						local x = i-offset

						surface.SetDrawColor(0,0,0,100)
						surface.DrawLine(x+1, 1+1, x+1, pnl:GetTall() - 3+1)

						surface.SetDrawColor(self:GetSkin().Colours.Category.Header)
						surface.DrawLine(x, 1, x, pnl:GetTall() - 3)

						surface.SetTextPos(x+2+1, 1+1)
						surface.SetFont(pace.CurrentFont)
						surface.SetTextColor(0,0,0,100)
						surface.DrawText(sec)

						surface.SetTextPos(x+2, 1)
						surface.SetFont(pace.CurrentFont)
						surface.SetTextColor(self:GetSkin().Colours.Category.Header)
						surface.DrawText(sec)
					end
				end

				for i=previousSecond,previousSecond+s:GetWide(),secondDistance/8 do
					if i-offset > 0 and i-offset < ScrW() then
						local x = i-offset
						surface.SetDrawColor(0,0,0,100)
						surface.DrawLine(x+1, 1+1, x+1, pnl:GetTall()/2+1)

						surface.SetDrawColor(self:GetSkin().Colours.Category.Header)
						surface.DrawLine(x, 1, x, pnl:GetTall()/2)
					end
				end

				local h = self.keyframe_scroll:GetCanvas():GetTall() + pnl:GetTall()
				if self.keyframe_scroll:GetVBar():IsVisible() then
					h = h - self.keyframe_scroll:GetVBar():GetTall() + 5
				end

				for i, v in ipairs(self.keyframe_scroll:GetCanvas():GetChildren()) do
					local mat = v.restart and restart or v.start and start or false
					local esmat = v.estyle and estyle or false

					if mat then
						local x = v:GetPos()
						surface.SetDrawColor(255,255,255,200)
						surface.DrawLine(x, -mat:Height()/2 - 5, x, h)

						surface.SetDrawColor(255,255,255,255)
						surface.SetMaterial(mat)
						surface.DrawTexturedRect(1+x,mat:Height() - 5,mat:Width(), mat:Height())

					end

					if esmat then
						local ps = v:GetSize()
						local x = v:GetPos() + (ps * 0.5)
						surface.SetDrawColor(255,255,255,255)
						surface.SetMaterial(esmat)
						surface.DrawTexturedRect(1+x - (esmat:Width() * 0.5), esmat:Height(),esmat:Width(), esmat:Height())
						if ps >= 65 then
							draw.SimpleText( v.estyle, "Default", x, esmat:Height() * 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP )
						end
					end
				end

				if not timeline.animation_part then return end

				local x = timeline.GetCycle() * self.keyframe_scroll:GetCanvas():GetWide()
				x = x - offset

				surface.SetDrawColor(255,0,0,200)
				surface.DrawLine(x, 0, x, h)

				surface.SetDrawColor(255,0,0,255)
				surface.SetMaterial(scrub)
				surface.DrawTexturedRect(1 + x - scrub:Width()/2,-11,scrub:Width(), scrub:Height())
			end
		end
	end

	function TIMELINE:Paint(w,h)
		self:GetSkin().tex.Tab_Control(0, 35, w, h-35)
	end

	function TIMELINE:Think()
		DFrame.Think(self)

		if pace.Editor:GetPos() + pace.Editor:GetWide() / 2 < ScrW() / 2 then
			self:SetSize(ScrW()-(pace.Editor.x+pace.Editor:GetWide()),93)
			self:SetPos(pace.Editor.x+pace.Editor:GetWide(),ScrH()-self:GetTall())
		else
			self:SetSize(ScrW()-(ScrW()-pace.Editor.x),93)
			self:SetPos(0,ScrH()-self:GetTall())
		end

		if input.IsKeyDown(KEY_SPACE) then
			if not self.toggled then
				self:Toggle()
				self.toggled = true
			end
		else
			self.toggled = false
		end
	end

	function TIMELINE:Play()
		animations.RegisterAnimation(timeline.animation_part:GetAnimID(), timeline.data)
		animations.SetEntityAnimation(timeline.entity, timeline.animation_part:GetAnimID())

		animations.GetEntityAnimation(timeline.entity, timeline.animation_part:GetAnimID()).Paused = false

		self.playing = true
	end

	function TIMELINE:OnMouseWheeled(dt)
		if input.IsControlDown() then
			secondDistance = secondDistance + dt * 10
		end
	end

	function TIMELINE:Pause()
		local anim = animations.GetEntityAnimation(timeline.entity, timeline.animation_part:GetAnimID())
		if not anim then return end

		animations.GetEntityAnimation(timeline.entity, timeline.animation_part:GetAnimID()).Paused = true

		self.playing = false
	end

	function TIMELINE:IsPlaying()
		return self.playing
	end

	function TIMELINE:Toggle()
		if self:IsPlaying() then
			self:Pause()
		else
			self:Play()
		end
	end

	function TIMELINE:Stop()
		self:Pause()

		animations.StopAllEntityAnimations(timeline.entity)
		animations.ResetEntityBoneMatrix(timeline.entity)
	end

	function TIMELINE:Clear()
		for i,v in pairs(self.keyframe_scroll:GetCanvas():GetChildren()) do
			v:Remove()
		end
		self.add_keyframe_button:SetDisabled(false)
	end

	function TIMELINE:GetAnimationTime()
		local total = 0

		if timeline.data and timeline.data.FrameData then
			for i=1, #timeline.data.FrameData do
				local v = timeline.data.FrameData[i]
				total = total+(1/(v.FrameRate or 1))
			end
		end

		return total
	end

	function TIMELINE:ResolveRestart() --get restart pos in seconds
		timeline.first_pass = false
		local timeInSeconds = 0
		local restartFrame = timeline.data.RestartFrame
		if not restartFrame then return 0 end --no restart pos? start at the start

		for i,v in ipairs(timeline.data.FrameData) do
			if i == restartFrame then return timeInSeconds end
			timeInSeconds = timeInSeconds+(1/(v.FrameRate or 1))
		end

		return 0
	end

	function TIMELINE:ResolveStart() --get restart pos in seconds
		timeline.first_pass = true
		local timeInSeconds = 0
		local startFrame = timeline.data.StartFrame
		if not startFrame then return 0 end --no restart pos? start at the start

		for i,v in ipairs(timeline.data.FrameData) do
			if i == startFrame then return timeInSeconds end
			timeInSeconds = timeInSeconds+(1/(v.FrameRate or 1))
		end

		return 0
	end

	function TIMELINE:AddKeyFrame(raw)
		local keyframe = vgui.Create("pac3_timeline_keyframe")

		if not raw then
			keyframe.AnimationKeyIndex = table.insert(timeline.data.FrameData, {FrameRate = 1, BoneInfo = {}})
			keyframe.DataTable = timeline.data.FrameData[keyframe.AnimationKeyIndex]
		end

		keyframe:SetWide(secondDistance) --default to 1 second animations

		keyframe:SetParent(self.keyframe_scroll)
		self.keyframe_scroll:InvalidateLayout()

		keyframe.Alternate = #timeline.frame.keyframe_scroll:GetCanvas():GetChildren()%2 == 1

		return keyframe
	end
	vgui.Register("pac3_timeline",TIMELINE,"DFrame")
end

do
	local KEYFRAME = {}

	function KEYFRAME:Init()
		self:SetCursor("hand")
	end

	function KEYFRAME:OnCursorMoved(x, y)
		if x > self:GetWide() - 4 then
			self:SetCursor("sizewe")
		else
			self:SetCursor("hand")
		end
	end

	function KEYFRAME:SetStart(b)
		self.start = b
	end

	function KEYFRAME:GetStart()
		return self.start
	end

	function KEYFRAME:SetRestart(b)
		self.restart = b
	end

	function KEYFRAME:GetRestart()
		return self.restart
	end

	function KEYFRAME:GetData()
		return self.DataTable
	end
	function KEYFRAME:SetFrameData(index,tbl)
		self.DataTable = tbl
		self.AnimationKeyIndex = index
		self:GetParent():GetParent():InvalidateLayout() --rebuild the timeline
		if tbl.EaseStyle then
			self.estyle = tbl.EaseStyle
		end
		if timeline.data.RestartFrame == index then
			self:SetRestart(true)
		end
		if timeline.data.StartFrame == index then
			self:SetStart(true)
		end
	end

	function KEYFRAME:GetAnimationIndex()
		return self.AnimationKeyIndex
	end

	function KEYFRAME:Paint(w,h)
		self.AltLine = self.Alternate
		derma.SkinHook( "Paint", "CategoryButton", self, w, h )

		if timeline.selected_keyframe == self then
			local c = self:GetSkin().Colours.Category.Line.Button_Selected
			surface.SetDrawColor(c.r,c.g,c.b,250)
		end

		surface.DrawRect(0,0,w,h)

		surface.SetDrawColor(0,0,0,75)
		surface.DrawOutlinedRect(0,0,w,h)
	end

	function KEYFRAME:Think()
		if self.size_x then
			local delta = self.size_x - gui.MouseX()

			self:SetLength((self.size_w - delta) / secondDistance)
		elseif self.move then
			local x, y = self:GetPos()
			local delta = gui.MouseX() - self.move
			self:SetPos(self.move_x + delta, y)
		end
	end

	function KEYFRAME:OnMouseReleased(mc)
		if mc == MOUSE_LEFT then
			if self.size_x then
				self.size_x = nil
				self.size_w = nil
				self:MouseCapture(false)
				self:SetCursor("sizewe")
				timeline.Save()
			elseif self.move then
				local panels = {}
				local frames = {}

				for k, v in pairs(timeline.frame.keyframe_scroll:GetCanvas():GetChildren()) do
					table.insert(panels, v)
					v:SetParent()
				end

				table.sort(panels, function(a, b)
					return (a:GetPos() + a:GetWide() / 2) < (b:GetPos() + b:GetWide() / 2)
				end)

				for i,v in ipairs(panels) do
					v:SetParent(timeline.frame.keyframe_scroll)
					v.Alternate = #timeline.frame.keyframe_scroll:GetCanvas():GetChildren()%2 == 1

					frames[i] = timeline.data.FrameData[v:GetAnimationIndex()]
				end

				for i,v in ipairs(frames) do
					timeline.data.FrameData[i] = v
					panels[i].AnimationKeyIndex = i
				end

				self:MouseCapture(false)
				self:SetCursor("hand")
				self.move = nil
				self.move_x = nil
				timeline.frame.moving = false
			end
		end
	end

	function KEYFRAME:OnMousePressed(mc)
		if mc == MOUSE_LEFT then
			local x = self:CursorPos()

			if x >= self:GetWide() - 4 then
				self.size_x = gui.MouseX()
				self.size_w = self:GetWide()
				self:MouseCapture(true)
				self:SetCursor("sizewe")
			else
				self.move = gui.MouseX()
				self.move_x = self:GetPos()
				self:MoveToFront()
				self:MouseCapture(true)
				self:SetCursor("sizeall")

				timeline.frame.moving = true
			end

			timeline.frame:Toggle(false)
			timeline.SelectKeyframe(self)
		elseif mc == MOUSE_RIGHT then
			local menu = DermaMenu()
			menu:AddOption(L"set length",function()
				Derma_StringRequest(L"question",
					L"how long should this frame be in seconds?",
					tostring(self:GetWide()/secondDistance),
					function(str) self:SetLength(tonumber(str)) end,
					function() end,
					L"set length",
					L"cancel" )
			end):SetImage("icon16/time.png")

			menu:AddOption(L"multiply length",function()
				Derma_StringRequest(L"question",
					L"multiply "..self:GetAnimationIndex().."'s length",
					"1.0",
					function(str) self:SetLength(1/tonumber(str)) end,
					function() end,
					L"multiply length",
					L"cancel" )
			end):SetImage("icon16/time_add.png")

			if not self:GetRestart() then
				menu:AddOption(L"set restart",function()
					for _,v in pairs(timeline.frame.keyframe_scroll:GetCanvas():GetChildren()) do
						v:SetRestart(false)
					end
					self:SetRestart(true)
					timeline.data.RestartFrame = self:GetAnimationIndex()
				end):SetImage("icon16/control_repeat_blue.png")
			else
				menu:AddOption(L"unset restart",function()
					self:SetRestart(false)
					timeline.data.StartFrame = nil
				end):SetImage("icon16/control_repeat.png")
			end

			if not self:GetStart() then
				menu:AddOption(L"set start",function()
					for _,v in pairs(timeline.frame.keyframe_scroll:GetCanvas():GetChildren()) do
						v:SetStart(false)
					end
					self:SetStart(true)
					timeline.data.StartFrame = self:GetAnimationIndex()
				end):SetImage("icon16/control_play_blue.png")
			else
				menu:AddOption(L"unset start",function()
					self:SetStart(false)
					timeline.data.StartFrame = nil
				end):SetImage("icon16/control_play.png")
			end

			menu:AddOption(L"reverse",function()
				local frame = timeline.data.FrameData[self:GetAnimationIndex() - 1]
				if not frame then
					frame = timeline.data.FrameData[#timeline.data.FrameData]
				end
				local tbl = frame.BoneInfo
				for i, v in pairs(tbl) do
					self:GetData().BoneInfo[i] = table.Copy(self:GetData().BoneInfo[i] or {})
					self:GetData().BoneInfo[i].MU = v.MU * -1
					self:GetData().BoneInfo[i].MR = v.MR * -1
					self:GetData().BoneInfo[i].MF = v.MF * -1
					self:GetData().BoneInfo[i].RU = v.RU * -1
					self:GetData().BoneInfo[i].RR = v.RR * -1
					self:GetData().BoneInfo[i].RF = v.RF * -1
				end
				timeline.UpdateFrameData()
			end):SetImage("icon16/control_rewind_blue.png")

			menu:AddOption(L"duplicate to end", function()
				local keyframe = timeline.frame:AddKeyFrame()

				local tbl = self:GetData().BoneInfo
				for i, v in pairs(tbl) do
					local data = keyframe:GetData()
					data.BoneInfo[i] = table.Copy(self:GetData().BoneInfo[i] or {})
					data.BoneInfo[i].MU = v.MU
					data.BoneInfo[i].MR = v.MR
					data.BoneInfo[i].MF = v.MF
					data.BoneInfo[i].RU = v.RU
					data.BoneInfo[i].RR = v.RR
					data.BoneInfo[i].RF = v.RF
				end
				keyframe:SetLength(1/(self:GetData().FrameRate))
				timeline.SelectKeyframe(keyframe)
			end):SetImage("icon16/application_double.png")

			menu:AddOption(L"remove",function()
				local frameNum = self:GetAnimationIndex()
				if frameNum == 1 and not timeline.data.FrameData[2] then return end
				table.remove(timeline.data.FrameData, frameNum)

				local remove_i

				for i,v in pairs(timeline.frame.keyframe_scroll:GetCanvas():GetChildren()) do
					if v == self then
						remove_i = i
					elseif v:GetAnimationIndex() > frameNum then
						v.AnimationKeyIndex = v.AnimationKeyIndex - 1
						v.Alternate = not v.Alternate
					end
				end

				table.remove(timeline.frame.keyframe_scroll:GetCanvas():GetChildren(), remove_i)

				timeline.frame.keyframe_scroll:InvalidateLayout()

				self:Remove()
				-- * even if it was removed from the table it still exists for some reason
				local count = #timeline.frame.keyframe_scroll:GetCanvas():GetChildren()
				local offset = frameNum == count and count - 1 or count
				timeline.SelectKeyframe(timeline.frame.keyframe_scroll:GetCanvas():GetChildren()[offset])
			end):SetImage("icon16/application_delete.png")

			menu:AddOption(L"set easing style", function()
				if timeline.data.Interpolation != "linear" then
					local frame = vgui.Create("DFrame")
					frame:SetSize(300, 100)
					frame:Center()
					frame:SetTitle("Easing styles work only with the linear interpolation type!")
					frame:ShowCloseButton(false)

					local button = vgui.Create("DButton", frame)
					button:SetText("Okay")
					button:Dock(FILL)
					button.DoClick = function()
						frame:Close()
					end
					frame:MakePopup()
					return
				end

				local frameNum = self:GetAnimationIndex()

				local frame = vgui.Create( "DFrame" )
				frame:SetSize( 200, 100 )
				frame:Center()
				frame:SetTitle("Select easing type")
				frame:MakePopup()

				local combo = vgui.Create( "DComboBox", frame )

				combo:SetPos( 5, 30 )
				combo:Dock(FILL)
				combo:SetValue("None")

				for easeName, _ in pairs(eases) do
					combo:AddChoice(easeName)
				end

				combo.OnSelect = function(sf, index, val)
					self:SetEaseStyle(val)
					frame:Close()
				end
			end):SetImage("icon16/arrow_turn_right.png")

			if self:GetEaseStyle() then
				menu:AddOption(L"unset easing style", function()
					self:RemoveEaseStyle()
				end):SetImage("icon16/arrow_up.png")
			end

			menu:Open()

		end
	end

	function KEYFRAME:SetLength(int)
		if not int then return end
		self:GetParent():GetParent():InvalidateLayout() --rebuild the timeline
		self:GetData().FrameRate = 1/math.max(int, 0.001) --set animation frame rate
	end

	function KEYFRAME:GetEaseStyle()
		return self.estyle
	end

	function KEYFRAME:SetEaseStyle(style)
		if not style then return end
		self:GetData().EaseStyle = style
		self.estyle = style
	end

	function KEYFRAME:RemoveEaseStyle()
		self:GetData().EaseStyle = nil
		self.estyle = nil
	end

	vgui.Register("pac3_timeline_keyframe",KEYFRAME,"DPanel")
end