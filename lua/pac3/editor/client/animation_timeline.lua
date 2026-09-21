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
		Scale = true,
	}

	BUILDER
		:StartStorableVars()
			:SetPropertyGroup("orientation")
			:PropertyOrder("Bone")
			:PropertyOrder("Position")
			:PropertyOrder("Angles")
			:GetSet("Scale", Vector(1,1,1), {editor_sensitivity = 0.25})
		:EndStorableVars()

	function PART:GetParentOwner()
		return self.Owner
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

timeline.interpolation = "linear"

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

	data.SX = data.SX or 0
	data.SY = data.SY or 0
	data.SZ = data.SZ or 0

	timeline.dummy_bone:SetPosition(Vector(data.MF, -data.MR, data.MU))
	timeline.dummy_bone:SetAngles(Angle(data.RR, data.RU, data.RF))
	timeline.dummy_bone:SetScale(Vector(1 + data.SX, 1 + data.SY, 1 + data.SZ))
end

do -- changed bones in selected keyframe
	local BONE_CHANNELS = { "MU", "MR", "MF", "RU", "RF", "RR", "SX", "SY", "SZ" }
	local CHANNEL_LABELS = { MU = "up", MR = "right", MF = "forward", RR = "pitch", RU = "yaw", RF = "roll", SX = "scale x", SY = "scale y", SZ = "scale z" }
	local ZERO_BONE = { MU = 0, MR = 0, MF = 0, RU = 0, RF = 0, RR = 0, SX = 0, SY = 0, SZ = 0 }

	-- A bone is "changed" in a keyframe if any of its channels differ from the
	-- previous keyframe (frame 0 = all zeros). This matches how the animation
	-- interpolates
	function timeline.GetFrameChangedBones(frameIndex)
		local data = timeline.data
		local changed = {}
		local keyed = {}
		local frameKeyed = {}

		if not data or not data.FrameData then return changed, keyed, frameKeyed end

		local curFrame = data.FrameData[frameIndex]
		if not curFrame then return changed, keyed, frameKeyed end

		local prevFrame = data.FrameData[frameIndex - 1]
		local curBones = curFrame.BoneInfo or {}

		for boneReal in pairs(curBones) do
			frameKeyed[boneReal] = true
		end

		for i, frame in ipairs(data.FrameData) do
			if frame and frame.BoneInfo then
				for boneReal in pairs(frame.BoneInfo) do
					keyed[boneReal] = true
				end
			end
		end

		-- map raw bone names to friendly names for display
		local realToFriendly = {}
		local boneData = pac.GetModelBones(timeline.entity)
		for friendly, v in pairs(boneData) do
			if v.real then realToFriendly[v.real] = friendly end
		end

		for boneReal, curInfo in pairs(curBones) do
			local prevInfo = prevFrame and prevFrame.BoneInfo and prevFrame.BoneInfo[boneReal] or ZERO_BONE

			local channels = {}
			for _, ch in ipairs(BONE_CHANNELS) do
				local diff = (curInfo[ch] or 0) - (prevInfo[ch] or 0)
				if diff ~= 0 then
					channels[ch] = diff
				end
			end

			if next(channels) then
				changed[boneReal] = {
					friendly = realToFriendly[boneReal] or boneReal,
					channels = channels,
				}
			end
		end

		return changed, keyed, frameKeyed
	end

	-- which channels belong to each property group
	local CHANNEL_GROUPS = {
		Position = {"MU", "MR", "MF"},
		Angles = {"RR", "RU", "RF"},
		Scale = {"SX", "SY", "SZ"},
	}

	function timeline.ResetBoneChannelsInFrame(boneReal, channels)
		if not timeline.selected_keyframe or not timeline.data or not timeline.data.FrameData then return end

		local index = timeline.selected_keyframe:GetAnimationIndex()
		local frame = timeline.data.FrameData[index]
		if not frame then return end

		local prevFrame = timeline.data.FrameData[index - 1]
		local prevInfo = prevFrame and prevFrame.BoneInfo and prevFrame.BoneInfo[boneReal]

		frame.BoneInfo = frame.BoneInfo or {}
		local info = frame.BoneInfo[boneReal]
		if not info then
			-- bone isn't keyed in this frame yet: treat current values as the
			-- previous frame's (hold), so the reset is a no-op that just keys it
			info = prevInfo and table.Copy(prevInfo) or table.Copy(ZERO_BONE)
			frame.BoneInfo[boneReal] = info
		end

		for _, ch in ipairs(channels) do
			if prevInfo then
				info[ch] = prevInfo[ch] or 0
			else
				info[ch] = 0
			end
		end

		if timeline.selected_bone == boneReal then
			timeline.UpdateFrameData()

			if pace.current_part == timeline.dummy_bone then
				pace.PopulateProperties(timeline.dummy_bone)
			end
		end

		timeline.Save()
		timeline.SyncPreview()
		timeline.UpdateChangedBonesPanel()
		pace.RecordUndoHistory()
	end

	function timeline.ResetBoneInFrame(boneReal)
		if not timeline.selected_keyframe or not timeline.data or not timeline.data.FrameData then return end

		local index = timeline.selected_keyframe:GetAnimationIndex()
		local frame = timeline.data.FrameData[index]
		if not frame then return end

		local prevFrame = timeline.data.FrameData[index - 1]
		local prevInfo = prevFrame and prevFrame.BoneInfo and prevFrame.BoneInfo[boneReal]

		frame.BoneInfo = frame.BoneInfo or {}
		frame.BoneInfo[boneReal] = prevInfo and table.Copy(prevInfo) or table.Copy(ZERO_BONE)

		if timeline.selected_bone == boneReal then
			timeline.UpdateFrameData()

			if pace.current_part == timeline.dummy_bone then
				pace.PopulateProperties(timeline.dummy_bone)
			end
		end

		timeline.Save()
		timeline.SyncPreview()
		timeline.UpdateChangedBonesPanel()
		pace.RecordUndoHistory()
	end

	-- Removes every trace of this bone from the whole animation (all frames).
	function timeline.RemoveBoneFromAnimation(boneReal)
		if not timeline.data or not timeline.data.FrameData then return end

		for _, frame in ipairs(timeline.data.FrameData) do
			if frame.BoneInfo then
				frame.BoneInfo[boneReal] = nil
			end
		end

		timeline.Save()
		timeline.SyncPreview()
		timeline.UpdateChangedBonesPanel()
		pace.RecordUndoHistory()
	end

	function timeline.AddBoneToFrame(friendly)
		local boneData = pac.GetModelBones(timeline.entity)
		local bone = friendly and boneData and boneData[friendly]
		if not bone or not bone.real then return end

		if not timeline.selected_keyframe or not timeline.data or not timeline.data.FrameData then return end

		local frame = timeline.data.FrameData[timeline.selected_keyframe:GetAnimationIndex()]
		if not frame then return end

		frame.BoneInfo = frame.BoneInfo or {}
		if not frame.BoneInfo[bone.real] then
			timeline.ResetBoneInFrame(bone.real)
			pace.RecordUndoHistory()
		end

		if timeline.dummy_bone and timeline.dummy_bone:IsValid() then
			timeline.dummy_bone:SetBone(friendly)
			timeline.EditBone()
		end
	end

	-- text content of a row, shared by the row painter and the width sizing
	local function get_row_texts(info, state)
		local name = info.friendly or "?"

		if state == "changed" and info.channels then
			local parts = {}
			for _, ch in ipairs(BONE_CHANNELS) do
				local v = info.channels[ch]
				if v then
					parts[#parts + 1] = CHANNEL_LABELS[ch] .. " " .. string.format("%+.2f", v)
				end
			end
			if #parts > 0 then
				return name, table.concat(parts, ", ")
			end
		elseif state == "held" then
			return name, L"unchanged"
		end

		return name
	end

	local function add_bone_row(parent, boneReal, info, state, alt)
		local row = parent:Add("DPanel")
		row:Dock(TOP)
		row:DockMargin(1, 1, 1, 0)
		row:SetTall(18)
		row:SetCursor("hand")

		local remove = vgui.Create("DImageButton", row)
		remove:SetImage("icon16/delete.png")
		remove:SetTooltip(L"remove bone from the whole animation")
		remove:SizeToContents()
		remove:Dock(LEFT)
		remove:DockMargin(2, 0, 2, 0)
		remove.DoClick = function()
			-- shift skips the confirmation and removes right away
			if input.IsKeyDown(KEY_LSHIFT) or input.IsKeyDown(KEY_RSHIFT) then
				timeline.RemoveBoneFromAnimation(boneReal)
				return true
			end

			Derma_Query(
				L"remove this bone from all keyframes of the animation? (hold shift while clicking the button to skip this prompt)",
				L"remove bone",
				L"remove", function() timeline.RemoveBoneFromAnimation(boneReal) end,
				L"cancel", function() end
			)
			return true
		end

		local changed_groups = {}
		if state == "changed" and info.channels then
			for group, channels in pairs(CHANNEL_GROUPS) do
				for _, ch in ipairs(channels) do
					if info.channels[ch] then
						changed_groups[group] = true
						break
					end
				end
			end
		end

		local changed_count = 0
		for _ in pairs(changed_groups) do
			changed_count = changed_count + 1
		end

		local reset
		if changed_count > 1 then
			reset = vgui.Create("DImageButton", row)
			reset:SetImage("icon16/arrow_undo.png")
			reset:SetTooltip(L"reset bone in this frame")
			reset:SizeToContents()
			reset:Dock(RIGHT)
			reset:DockMargin(0, 0, 2, 0)
			reset.DoClick = function()
				timeline.ResetBoneInFrame(boneReal)
				return true
			end
		end

		local CHANNEL_BUTTON_COLORS = {
			Position = Color(100, 200, 110),
			Angles = Color(90, 140, 230),
			Scale = Color(220, 90, 90),
		}
		local channel_buttons = {}

		for _, group in ipairs({"Scale", "Angles", "Position"}) do
			if changed_groups[group] then
				local btn = vgui.Create("DImageButton", row)
				btn:SetImage("icon16/arrow_refresh_small.png")
				btn:SetColor(CHANNEL_BUTTON_COLORS[group])
				btn:SetTooltip(L("reset " .. group:lower() .. " in this frame"))
				btn:SizeToContents()
				btn:Dock(RIGHT)
				btn:DockMargin(0, 0, 1, 0)
				btn.DoClick = function()
					timeline.ResetBoneChannelsInFrame(boneReal, CHANNEL_GROUPS[group])
					return true
				end
				table.insert(channel_buttons, 1, btn)
			end
		end

		local lm, _, rm = remove:GetDockMargin()
		local left_pad = remove:GetWide() + lm + rm + 4

		-- space for whichever buttons actually exist
		local buttons_w = 0
		if reset then
			buttons_w = reset:GetWide() + 2
		end
		for _, btn in ipairs(channel_buttons) do
			local bl, _, br = btn:GetDockMargin()
			buttons_w = buttons_w + btn:GetWide() + bl + br
		end

		surface.SetFont(pace.CurrentFont)
		local name_text, delta_text = get_row_texts(info, state)
		local content_w = left_pad + surface.GetTextSize(name_text) + 10
		if delta_text then
			content_w = content_w + surface.GetTextSize(delta_text)
		end
		row.ContentWidth = content_w + buttons_w + 14 -- gap between text and the right-docked buttons

		row.OnCursorEntered = function(s) s.Hovered = true end
		row.OnCursorExited = function(s) s.Hovered = false end

		row.Paint = function(s, w, h)
			local skin = s:GetSkin()
			local selected = timeline.selected_bone == boneReal

			-- same paint the keyframes use, so rows match the timeline look
			derma.SkinHook("Paint", "CategoryButton", s, w, h)

			if selected then
				local c = skin.Colours.Category.Line.Button_Selected
				surface.SetDrawColor(c.r, c.g, c.b, 250)
				surface.DrawRect(0, 0, w, h)
			elseif s.Hovered then
				surface.SetDrawColor(0, 0, 0, 10)
				surface.DrawRect(0, 0, w, h)
			end

			local text_color = selected and Color(40, 40, 40, 255) or skin.Colours.Label.Dark
			local dim_color = selected and Color(40, 40, 40, 255) or Color(120, 120, 120, 220)

			local name_text, delta_text = get_row_texts(info, state)
			draw.SimpleText(name_text, pace.CurrentFont, left_pad, h / 2, state == "changed" and text_color or dim_color, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

			if delta_text then
				surface.SetFont(pace.CurrentFont)
				local nw = surface.GetTextSize(name_text)
				local delta_color = state == "changed" and (selected and text_color or Color(40, 140, 70, 255)) or dim_color
				draw.SimpleText(delta_text, pace.CurrentFont, left_pad + nw + 10, h / 2, delta_color, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			end
		end

		row.OnMousePressed = function(_, mc)
			if mc == MOUSE_LEFT and timeline.dummy_bone and timeline.dummy_bone:IsValid() then
				timeline.dummy_bone:SetBone(info.friendly or boneReal)
				timeline.EditBone()
			end
		end

		return row
	end

	local function add_hint(parent, text)
		local hint = parent:Add("DPanel")
		hint:Dock(TOP)
		hint:SetTall(18)
		hint.Paint = function(_, w, h)
			draw.SimpleText(text, pace.CurrentFont, 4, h / 2, Color(100, 100, 100, 220), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		end
		return hint
	end

	function timeline.UpdateChangedBonesPanel()
		if timeline.bones_panel_queued then return end
		timeline.bones_panel_queued = true
		timer.Simple(0, function()
			timeline.bones_panel_queued = nil
			timeline.RebuildChangedBonesPanel()
		end)
	end

	function timeline.RebuildChangedBonesPanel()
		local bf = timeline.bones_frame
		if not bf or not bf:IsValid() then return end

		local list = bf.bones_list
		local canvas = list:GetCanvas()

		local children = canvas:GetChildren()
		for i = #children, 1, -1 do
			children[i]:Remove()
		end

		local frameIndex = timeline.selected_keyframe and timeline.selected_keyframe:GetAnimationIndex() or 0
		local changed, keyed, frameKeyed = timeline.GetFrameChangedBones(frameIndex)

		-- map raw bone names to friendly names for display
		local realToFriendly = {}
		local boneData = pac.GetModelBones(timeline.entity)
		for friendly, v in pairs(boneData) do
			if v.real then realToFriendly[v.real] = friendly end
		end
		local function fr(boneReal) return realToFriendly[boneReal] or boneReal end

		local rows = {}
		for boneReal in pairs(frameKeyed) do
			local ch = changed[boneReal]
			rows[#rows + 1] = {
				boneReal = boneReal,
				friendly = fr(boneReal),
				changed = ch ~= nil,
				channels = ch and ch.channels or nil,
			}
		end
		table.sort(rows, function(a, b)
			if a.changed ~= b.changed then return a.changed end
			return a.friendly < b.friendly
		end)

		for i, row in ipairs(rows) do
			add_bone_row(canvas, row.boneReal, row, row.changed and "changed" or "held", i % 2 == 0)
		end

		if #rows == 0 then
			add_hint(canvas, L"no bones keyed in this frame")
		end

		-- bones that only exist in other frames' BoneInfo
		local elsewhere = {}
		for boneReal in pairs(keyed) do
			if not frameKeyed[boneReal] then
				elsewhere[#elsewhere + 1] = { boneReal = boneReal, friendly = fr(boneReal) }
			end
		end
		table.sort(elsewhere, function(a, b) return a.friendly < b.friendly end)

		if #elsewhere > 0 then
			add_hint(canvas, L"keyed in other frames:")
			for _, row in ipairs(elsewhere) do
				add_bone_row(canvas, row.boneReal, row, "elsewhere", false)
			end
		end

		-- auto-size the window width to the widest row's measured content
		local maxw = 0
		for _, pnl in ipairs(canvas:GetChildren()) do
			if pnl.ContentWidth and pnl.ContentWidth > maxw then
				maxw = pnl.ContentWidth
			end
		end

		-- fit the window to the content
		bf:SetTall(math.min(#canvas:GetChildren() * 18 + 68, 340))
		if maxw > 0 then
			bf:SetWide(math.Clamp(maxw, 240, 600))
		end
		bf:SetTitle(L"keyframe bones")

		-- follow the selected keyframe
		if bf.last_frame_index ~= frameIndex then
			bf.last_frame_index = frameIndex
			local f = timeline.frame
			if f and f:IsValid() then
				local kf = timeline.selected_keyframe
				local x = f.x + f.keyframe_scroll.x
				if kf and kf:IsValid() then
					x = x + kf.x + kf:GetWide() / 2 - bf:GetWide() / 2
				end
				local y = f.y - bf:GetTall() - 4
				local min_x = 0
				if pace.Editor and pace.Editor:IsValid() then
					min_x = pace.Editor.x + pace.Editor:GetWide()
				end
				bf:SetPos(math.Clamp(x, min_x, ScrW() - bf:GetWide()), math.Clamp(y, 0, ScrH() - bf:GetTall()))
			end
		end

		list:InvalidateLayout()
	end

	function timeline.OpenBonesPanel()
		if timeline.bones_frame and timeline.bones_frame:IsValid() then
			timeline.bones_frame:Remove()
		end

		timeline.show_bones = true

		local bf = vgui.Create("DFrame")
		bf:SetSize(380, 240)
		bf:SetTitle(L"keyframe bones")
		bf:ShowCloseButton(true)
		bf:SetDraggable(true)
		bf:SetSizable(true)
		bf:SetMinWidth(240)
		bf:SetMinHeight(80)
		bf:DockPadding(4, 24, 4, 4)
		bf.last_frame_index = -1

		bf.Paint = function(s, w, h)
			derma.SkinHook("Paint", "ListBox", s, w, h)
			s:GetSkin().tex.CategoryList.Header(0, 0, w, 22)
		end
		if IsValid(bf.lblTitle) then
			bf.lblTitle:SetTextColor(Color(240, 240, 240, 255))
		end

		-- float above the pac editor, but don't steal keyboard focus
		bf:MakePopup()
		bf:SetKeyboardInputEnabled(false)

		local toolbar = vgui.Create("DPanel", bf)
		toolbar:Dock(TOP)
		toolbar:SetTall(18)

		local add_bone_btn = vgui.Create("DImageButton", toolbar)
		add_bone_btn:SetImage("icon16/add.png")
		add_bone_btn:SetTooltip(L"add a bone to this keyframe")
		add_bone_btn:SizeToContents()
		add_bone_btn:Dock(LEFT)
		add_bone_btn:DockMargin(2, 1, 2, 1)
		add_bone_btn.DoClick = function()
			timeline.OpenBoneSelector()
		end

		local add_bone_lbl = vgui.Create("DLabel", toolbar)
		add_bone_lbl:SetText(L"add bone")
		add_bone_lbl:SetFont(pace.CurrentFont)
		add_bone_lbl:SetTextColor(Color(120, 120, 120, 220))
		add_bone_lbl:SizeToContents()
		add_bone_lbl:Dock(LEFT)
		add_bone_lbl:DockMargin(0, 1, 0, 1)

		bf.bones_list = vgui.Create("DScrollPanel", bf)
		bf.bones_list:Dock(FILL)

		timeline.bones_frame = bf

		-- open above the timeline, near the selected keyframe
		local f = timeline.frame
		if f and f:IsValid() then
			local x = f.x + f.keyframe_scroll.x
			local kf = timeline.selected_keyframe
			if kf and kf:IsValid() then
				x = x + kf.x + kf:GetWide() / 2 - bf:GetWide() / 2
			end
			local y = f.y - bf:GetTall() - 4
			local min_x = 0
			if pace.Editor and pace.Editor:IsValid() then
				min_x = pace.Editor.x + pace.Editor:GetWide()
			end
			bf:SetPos(math.Clamp(x, min_x, ScrW() - bf:GetWide()), math.Clamp(y, 0, ScrH() - bf:GetTall()))
		end

		timeline.UpdateChangedBonesPanel()
	end

	function timeline.OpenBoneSelector()
		if not timeline.entity or not timeline.entity:IsValid() then return end
		if not timeline.selected_keyframe then return end

		local boneData = pac.GetModelBones(timeline.entity)
		if not boneData then return end

		local bones = {}
		for friendly, v in pairs(boneData) do
			if v.real and not v.is_special and not v.is_attachment then
				table.insert(bones, {friendly = friendly, real = v.real})
			end
		end
		table.sort(bones, function(a, b) return a.friendly < b.friendly end)

		pace.SafeRemoveSpecialPanel()

		local frame = vgui.Create("DFrame")
		frame:SetTitle(L"add bone")
		frame:SetSize(280, 300)
		frame:Center()
		frame:SetSizable(true)

		local list = vgui.Create("DListView", frame)
		list:Dock(FILL)
		list:SetMultiSelect(false)
		list:AddColumn(L"name")

		local search = vgui.Create("DTextEntry", frame)
		search:Dock(BOTTOM)
		search:RequestFocus()

		local first_line
		local building = false

		local function build(find)
			building = true
			list:Clear()
			first_line = nil
			if find then find = find:lower() end
			for _, bone in ipairs(bones) do
				if not find or find == "" or bone.friendly:lower():find(find, nil, true) then
					local line = list:AddLine(bone.friendly)
					line.bone = bone
					if not first_line then
						first_line = line
						list:SelectItem(line) -- preselect so enter picks it
					end
				end
			end
			building = false
		end

		search.OnTextChanged = function() build(search:GetValue()) end
		search.OnEnter = function()
			-- enter picks the first result 
			if first_line and first_line:IsValid() and first_line.bone then
				timeline.AddBoneToFrame(first_line.bone.friendly)
				frame:Remove()
			end
		end

		list.OnRowSelected = function(_, id, line)
			if building then return end
			if line.bone then
				timeline.AddBoneToFrame(line.bone.friendly)
			end
			frame:Remove()
		end

		frame:MakePopup()
		build()

		pace.ActiveSpecialPanel = frame

		return frame
	end

	local function draw_bone_marker(spos, size, r, g, b)
		surface.SetDrawColor(r, g, b, 70)
		surface.DrawRect(spos.x - size * 0.5, spos.y - size * 0.5, size, size)

		surface.SetDrawColor(r, g, b, 255)
		surface.DrawOutlinedRect(spos.x - size * 0.5, spos.y - size * 0.5, size, size)

		surface.SetDrawColor(0, 0, 0, 255)
		surface.DrawOutlinedRect(spos.x - size * 0.5 - 1, spos.y - size * 0.5 - 1, size + 2, size + 2)
	end

	local function changed_bones_hudpaint()
		if not timeline.editing then return end
		if not timeline.show_changed_bones then return end
		if not pace.Focused then return end -- input passthrough: hide editor overlays
		if not timeline.entity or not timeline.entity:IsValid() then return end

		local kf = timeline.selected_keyframe
		if not kf or not kf.IsValid or not kf:IsValid() then return end

		local frameIndex = kf.GetAnimationIndex and kf:GetAnimationIndex()
		if not frameIndex then return end

		local changed = timeline.GetFrameChangedBones(frameIndex)
		if not next(changed) then
			timeline.bone_markers = nil
			return
		end

		local ent = timeline.entity
		local markers = {}

		for boneReal, info in pairs(changed) do
			local bone_id = ent:LookupBone(boneReal)
			if bone_id and bone_id >= 0 then
				local pos = pac.GetBonePosAng(ent, boneReal)
				if pos then
					local spos = pos:ToScreen()
					if spos and spos.visible then
						markers[boneReal] = {
							x = spos.x,
							y = spos.y,
							friendly = info.friendly or boneReal,
						}

						if boneReal == timeline.selected_bone then
							draw_bone_marker(spos, 12 + math.sin(RealTime() * 4) * 3, 148, 67, 201)
						else
							draw_bone_marker(spos, 9, 255, 200, 60)
						end

						draw.SimpleTextOutlined(info.friendly or boneReal, pace.CurrentFont, spos.x, spos.y + 10, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0, 200))
					end
				end
			end
		end

		timeline.bone_markers = markers
	end

	timeline.changed_bones_hudpaint = changed_bones_hudpaint
end

do -- mirror keyframe pose
	-- this sucks, I think a better way would be getting the bind pose or whatever
	local function mirror_bone_info(info, has_mirror)
		local out = table.Copy(info)
		if has_mirror then
			out.RR = -(info.RR or 0)
			out.RF = -(info.RF or 0)
		else
			out.MR = -(info.MR or 0)
			out.RU = -(info.RU or 0)
			out.RF = -(info.RF or 0)
		end
		return out
	end

	local function mirror_bone_name(name, real_bones)
		local function swap_word(word)
			local lower = word:lower()
			local replacement
			if lower == "left" then replacement = "right"
			elseif lower == "right" then replacement = "left"
			elseif lower == "l" then replacement = "r"
			elseif lower == "r" then replacement = "l"
			else return end

			-- keep the word's casing style
			if word == word:upper() then
				replacement = replacement:upper()
			elseif word:sub(1, 1) == word:sub(1, 1):upper() then
				replacement = replacement:sub(1, 1):upper() .. replacement:sub(2)
			end

			return replacement
		end

		local candidates = {}

		candidates[#candidates + 1] = (name:gsub("%a+", swap_word))

		for _, pair in ipairs({{"left", "right"}, {"Left", "Right"}, {"LEFT", "RIGHT"}}) do
			candidates[#candidates + 1] = (name:gsub(pair[1], pair[2]))
			candidates[#candidates + 1] = (name:gsub(pair[2], pair[1]))
		end

		-- trailing letter ("upperarml" -> "upperarmr")
		local stem, last = name:sub(1, -2), name:sub(-1)
		if last:lower() == "l" then
			candidates[#candidates + 1] = stem .. (last == "l" and "r" or "R")
		elseif last:lower() == "r" then
			candidates[#candidates + 1] = stem .. (last == "r" and "l" or "L")
		end

		-- leading letter ("lthumb" -> "rthumb")
		local head = name:sub(1, 1)
		if head:lower() == "l" then
			candidates[#candidates + 1] = (head == "l" and "r" or "R") .. name:sub(2)
		elseif head:lower() == "r" then
			candidates[#candidates + 1] = (head == "r" and "l" or "L") .. name:sub(2)
		end

		for _, candidate in ipairs(candidates) do
			if candidate ~= name and candidate ~= "" and real_bones[candidate] then
				return candidate
			end
		end

		return nil -- no mirrored bone found
	end

	function timeline.MirrorKeyframe()
		if not timeline.selected_keyframe or not timeline.data or not timeline.data.FrameData then return end

		local frame = timeline.data.FrameData[timeline.selected_keyframe:GetAnimationIndex()]
		if not frame then return end

		local boneData = pac.GetModelBones(timeline.entity)
		if not boneData then return end

		local real_bones = {}
		for _, v in pairs(boneData) do
			if v.real and not v.is_attachment then
				real_bones[v.real] = true
			end
		end

		local mirrored = {}
		for boneReal, info in pairs(frame.BoneInfo or {}) do
			local target = mirror_bone_name(boneReal, real_bones) or boneReal
			mirrored[target] = mirror_bone_info(info, target ~= boneReal)
		end

		frame.BoneInfo = mirrored

		-- select the mirrored counterpart of the selected bone
		local sel = timeline.selected_bone
		if sel and timeline.dummy_bone and timeline.dummy_bone:IsValid() then
			local target = mirror_bone_name(sel, real_bones)
			if target and target ~= sel then
				for friendly, v in pairs(boneData) do
					if v.real == target and not v.is_special and not v.is_attachment then
						timeline.dummy_bone:SetBone(friendly)
						break
					end
				end
			end
		end

		timeline.EditBone()
		timeline.Save()
		timeline.SyncPreview()
		timeline.UpdateChangedBonesPanel()
		pace.RecordUndoHistory()
	end
end

function timeline.Reindex()
	timeline.frame:Clear()

	local keyframes = {}
	for i, v in ipairs(timeline.data.FrameData) do
		local keyframe = timeline.frame:AddKeyFrame(true)
		keyframe:SetFrameData(i, v)
		keyframes[i] = keyframe
	end

	timeline.UpdateChangedBonesPanel()
	timeline.frame:InvalidateLayout(true)

	return keyframes
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

local function frames_equal(a, b)
	for k, v in pairs(a) do
		local bv = b[k]
		if istable(v) then
			if not istable(bv) or not frames_equal(v, bv) then return false end
		elseif bv ~= v then
			return false
		end
	end
	for k in pairs(b) do
		if a[k] == nil then return false end
	end
	return true
end

function timeline.Load(data)
	timeline.data = data and table.Copy(data) or nil
	data = timeline.data

	local sel = timeline.selected_keyframe
	local prev_index, prev_data
	if sel and sel.IsValid and sel:IsValid() and sel.GetAnimationIndex and sel.GetData then
		prev_index = sel:GetAnimationIndex()
		prev_data = sel:GetData()
	end

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

		local keyframes = {}
		for i, v in ipairs(data.FrameData) do
			local keyframe = timeline.frame:AddKeyFrame(true)
			keyframe:SetFrameData(i, v)
			keyframes[i] = keyframe
		end

		local select_index = prev_index or 1
		if prev_data and data.FrameData then
			for i, frame in ipairs(data.FrameData) do
				if frames_equal(frame, prev_data) then
					select_index = i
					break
				end
			end
		end

		timeline.SelectKeyframe(keyframes[math.Clamp(select_index, 1, #keyframes)])
	else
		timeline.data = {FrameData = {}, Type = timeline.animation_type, Interpolation = timeline.interpolation}
		timeline.frame:Clear()

		timeline.SelectKeyframe(timeline.frame:AddKeyFrame())
	end

	timeline.UpdateFrameData()

	if timeline.frame and timeline.frame:IsValid() then
		timeline.frame:InvalidateLayout(true)
	end
end

local function refresh_entity_anim(id)
	local ent = timeline.entity
	if not ent or not ent:IsValid() or not timeline.data then return end

	local anim = animations.GetEntityAnimation(ent, id)
	if anim and anim.FrameData ~= timeline.data.FrameData then
		anim.FrameData = timeline.data.FrameData

		if timeline.editing and timeline.selected_keyframe and timeline.selected_keyframe:IsValid() then
			animations.SetEntityAnimationFrame(ent, id, timeline.selected_keyframe:GetAnimationIndex(), 1)
		end
	end
end

function timeline.SyncPreview()
	local ent = timeline.entity
	if not ent or not ent:IsValid() or not timeline.animation_part then return end

	local anim = animations.GetEntityAnimation(ent, timeline.animation_part:GetAnimID())
	if anim and timeline.data and anim.FrameData ~= timeline.data.FrameData then
		anim.FrameData = timeline.data.FrameData
	end
end

function timeline.Save()
	local part = timeline.animation_part

	if part and part:IsValid() and part:GetURL() == "" then
		part.Data = util.TableToJSON(timeline.data)
	end

	timer.Create("pace_timeline_save", 0.1, 1, function()
		if not (part and part:IsValid() and timeline.data) then return end

		local data = table.Copy(timeline.data)
		animations.RegisterAnimation(part:GetAnimID(), data)
		refresh_entity_anim(part:GetAnimID())

		if part:GetURL() ~= "" then
			file.Write("pac3/__animations/" .. part:GetName() .. ".txt", util.TableToJSON(data))
			part:SetData("")
		else
			timer.Create("pace_backup", 5, 1, function() pace.Backup() end)
		end
	end)
end

function timeline.SelectKeyframe(keyframe)
	timeline.selected_keyframe = keyframe
	timeline.UpdateFrameData()
	timeline.EditBone()
	timeline.Save()

	-- make sure a preview instance exists on the entity (gesture animations
	-- remove themselves once they finish playing)
	animations.SetEntityAnimation(timeline.entity, timeline.animation_part:GetAnimID())
	timeline.SyncPreview()
	animations.SetEntityAnimationFrame(timeline.entity, timeline.animation_part:GetAnimID(), keyframe.AnimationKeyIndex, 1)
	timeline.frame:Pause()

	timeline.UpdateChangedBonesPanel()
end

function timeline.IsEditingBone()
	return timeline.dummy_bone == pace.current_part
end

function timeline.Close()
	timeline.Save()

	if timeline.bones_frame and timeline.bones_frame:IsValid() then
		timeline.bones_frame:Remove()
	end
	timeline.bones_frame = nil

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
	pac.RemoveHook("HUDPaint", "pac3_timeline_bones")
	pac.RemoveHook("GUIMousePressed", "pac3_timeline_bones_click")
end

function timeline.Open(part)
	file.CreateDir("pac3")
	file.CreateDir("pac3/__animations")
	file.CreateDir("pac3/__animations/backups")

	timeline.editing = false
	timeline.first_pass = true
	if timeline.show_bones == nil then
		timeline.show_bones = false
	end

	timeline.editing = true
	timeline.animation_part = part
	timeline.entity = part:GetOwner()

	if timeline.show_changed_bones == nil then
		timeline.show_changed_bones = true
	end

	timeline.frame = vgui.Create("pac3_timeline")
	timeline.frame:SetSize(ScrW()-pace.Editor:GetWide(), 93)
	timeline.frame:SetPos(pace.Editor:GetWide(), ScrH()-timeline.frame:GetTall())
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
				timeline.UpdateChangedBonesPanel()
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

				data.BoneInfo[timeline.selected_bone].SX = data.BoneInfo[timeline.selected_bone].SX or 0
				data.BoneInfo[timeline.selected_bone].SY = data.BoneInfo[timeline.selected_bone].SY or 0
				data.BoneInfo[timeline.selected_bone].SZ = data.BoneInfo[timeline.selected_bone].SZ or 0

				if key == "Position" then
					data.BoneInfo[timeline.selected_bone].MF = val.x
					data.BoneInfo[timeline.selected_bone].MR = -val.y
					data.BoneInfo[timeline.selected_bone].MU = val.z
				elseif key == "Angles" then
					data.BoneInfo[timeline.selected_bone].RR = val.p
					data.BoneInfo[timeline.selected_bone].RU = val.y
					data.BoneInfo[timeline.selected_bone].RF = val.r
				elseif key == "Scale" then
					-- scale is stored as a delta from 1, so 0 means unchanged
					data.BoneInfo[timeline.selected_bone].SX = val.x - 1
					data.BoneInfo[timeline.selected_bone].SY = val.y - 1
					data.BoneInfo[timeline.selected_bone].SZ = val.z - 1
				end
			end

			timeline.Save()
			timeline.SyncPreview()
			timeline.UpdateChangedBonesPanel()

			if key == "Position" or key == "Angles" or key == "Scale" then
				timer.Create("pace_timeline_undo", 0.25, 1, function()
					pace.RecordUndoHistory()
				end)
			end
		elseif part == timeline.animation_part then
			if key == "Data" or key == "URL" then
				if timeline.editing and key == "Data" and isstring(val) and val ~= "" then
					local restored = util.JSONToTable(val)
					if restored and restored.FrameData then
						timeline.Load(restored)
					end
				elseif timeline.editing then
					timeline.Save()
				elseif timeline.frame and timeline.frame:IsValid() then
					timeline.Load(animations.GetRegisteredAnimations()[part:GetAnimID()])
				end
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

	pac.AddHook("HUDPaint", "pac3_timeline_bones", timeline.changed_bones_hudpaint)

	pac.AddHook("GUIMousePressed", "pac3_timeline_bones_click", function(mc)
		if mc ~= MOUSE_LEFT then return end
		if not timeline.show_changed_bones then return end
		if not pace.Focused then return end -- don't select bones while walking around

		local markers = timeline.bone_markers
		if not markers or not next(markers) then return end

		local mx, my = input.GetCursorPos()
		local best, best_dist
		for bone, m in pairs(markers) do
			if bone ~= timeline.selected_bone then
				local dx, dy = mx - m.x, my - m.y
				-- hit area: the marker square plus its label below
				if math.abs(dx) <= 14 and dy >= -12 and dy <= 26 then
					local dist = dx * dx + dy * dy
					if not best_dist or dist < best_dist then
						best, best_dist = m, dist
					end
				end
			end
		end

		if best and timeline.dummy_bone and timeline.dummy_bone:IsValid() then
			timeline.dummy_bone:SetBone(best.friendly)
			timeline.EditBone()
			return true -- don't start a camera drag from this click
		end
	end)

	timeline.Load(animations.GetRegisteredAnimations()[part:GetAnimID()])

	if timeline.show_bones then
		timeline.OpenBonesPanel()
	end

	-- base undo snapshot: the state the timeline was opened in, so the first
	-- edit can be undone
	pace.RecordUndoHistory()

	pac.RemoveHook("CalcMainActivity", "pac3_timeline")

	timeline.Stop()
end

local editing_part
pac.AddHook("pace_OnPartSelected", "pac3_timeline", function(part)
	if part.ClassName == "timeline_dummy_bone" then return end

	if pace.undoing then return end

	if part.ClassName == "custom_animation" then
		if timeline.editing then
			if part == editing_part then return end
			timeline.Close()
		end
		timeline.Open(part)
		editing_part = part
	elseif timeline.editing then
		if editing_part then
			local part2 = editing_part
			if part2.AnimationType ~= "gesture" and not part2:IsHidden() then
				timer.Simple(0, function()
					part2:OnHide()
					part2:OnShow()
				end)
			end
		end
		timeline.Close()
	end
end)

-- hide the timeline UI as well
pac.AddHook("pace_OnToggleFocus", "pac3_timeline", function(show_editor)
	if not timeline.editing then return end

	local killing = pace.Focused
	local hiding = killing and not show_editor

	if timeline.frame and timeline.frame:IsValid() then
		timeline.frame:SetVisible(not hiding)
	end

	local bf = timeline.bones_frame
	if bf and bf:IsValid() then
		bf:SetVisible(not hiding)

		bf:SetMouseInputEnabled(not killing)
		bf:SetKeyboardInputEnabled(not killing)
	end
end)

do
	local TIMELINE = {}

	function TIMELINE:Init()
		self:DockMargin(0, 0, 0, 0)
		self:DockPadding(0, 30, 0, 0)

		do -- time display info
			local time = self:Add("DPanel")

			local test = L"frame" .. ": 10.888"
			surface.SetFont(pace.CurrentFont)
			local w, h = surface.GetTextSize(test)
			time:SetWide(w)

			time:SetTall(h*2 + 2)
			time:SetPos(0, 1)
			time.Paint = function(s, w, h)
				self:GetSkin().tex.Tab_Control( 0, 0, w, h )
				self:GetSkin().tex.CategoryList.Header( 0, 0, w, h )

				if not timeline.animation_part then return end

				local w, h = draw.TextShadow({
					text = L"frame" .. ": " .. (animations.GetEntityAnimationFrame(timeline.entity, timeline.animation_part:GetAnimID()) or 0),
					font = pace.CurrentFont,
					pos = {5, 0},
					color = self:GetSkin().Colours.Category.Header
				}, 1, 100)

				draw.TextShadow({
					text = L"time" .. ": " .. math.Round(timeline.GetCycle() * animations.GetAnimationDuration(timeline.entity, timeline.animation_part:GetAnimID()), 3),
					font = pace.CurrentFont,
					pos = {5, h},
					color = self:GetSkin().Colours.Category.Header
				}, 1, 100)
			end
		end

		do
			local bottom = vgui.Create("DPanel", self)
			bottom:Dock(RIGHT)
			bottom:SetWide(92)
			do -- time controls
				local controls = bottom:Add("DPanel")
				controls:SetWide(100)
				controls:SetTall(bottom:GetTall())
				controls:Dock(BOTTOM)
				controls:SetTall(36)

				local size = 36
				local spacing = (size - 24)/2

				local play = controls:Add("DButton")
				play:SetSize(size, size)
				play:SetText("")
				play.DoClick = function() self:Toggle() end
				play:Dock(LEFT)

				local stop = controls:Add("DButton")
				stop:SetSize(size, size)
				stop:SetText("")
				stop.DoClick = function() self:Stop() end
				stop:Dock(LEFT)

				function play.PaintOver(_, w, h)
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

				function stop:PaintOver(w, h)
					surface.SetDrawColor(self:GetSkin().Colours.Button.Normal)
					surface.DrawRect(spacing, spacing, 24, 24)
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
				add.DoClick = function() timeline.SelectKeyframe(self:AddKeyFrame()) timeline.Save() pace.RecordUndoHistory() end
				add:Dock(LEFT)
				add:SetDisabled(true)
				self.add_keyframe_button = add

				local bone = saveload:Add("DImageButton")
				bone:SetImage("icon16/connect.png")
				bone:SetTooltip(L"edit the selected bone")
				bone:SizeToContents()
				bone:Dock(LEFT)
				bone.DoClick = function()
					timeline.EditBone()
				end

				local bone_toggle = saveload:Add("DImageButton")
				bone_toggle:SetImage("icon16/eye.png")
				bone_toggle:SetTooltip(L"show changed bones")
				bone_toggle:SizeToContents()
				bone_toggle:Dock(LEFT)
				bone_toggle.DoClick = function()
					timeline.show_changed_bones = not timeline.show_changed_bones
					bone_toggle:SetImage(timeline.show_changed_bones and "icon16/eye.png" or "icon16/cross.png")
					bone_toggle:SetTooltip(timeline.show_changed_bones and L"show changed bones" or L"show changed bones (disabled)")
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

					local x, y = bottom:LocalToScreen(0, 0)
					x = x + bottom:GetWide()
					menu:SetPos(x - menu:GetWide(), y - menu:GetTall())
				end
			end

		end

		do -- keyframes
			local pnl = vgui.Create("pac_scrollpanel_horizontal", self)
			pnl:Dock(FILL)

			pnl:GetCanvas().Paint = function(_, w, h)
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
				for k, v in ipairs(pnl:GetCanvas():GetChildren()) do
					v:SetWide(math.max(1/v:GetData().FrameRate * secondDistance, 4))
					v:SetTall(h)
					v:SetPos(x, 0)
					x = x + v:GetWide()
				end
			end

			self.keyframe_scroll = pnl
		end

		do -- timeline
			local pnl = vgui.Create("DPanel", self)

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
			pnl.Paint = function(s, w, h)
				local offset = -self.keyframe_scroll:GetCanvas():GetPos()

				self:GetSkin().tex.Tab_Control( 0, 0, w, h )
				self:GetSkin().tex.CategoryList.Header( 0, 0, w, h )

				local previousSecond = offset-(offset%secondDistance)
				for i = previousSecond, previousSecond+s:GetWide(), secondDistance/2 do
					if i-offset > 0 and i-offset < ScrW() then
						local sec = i/secondDistance
						local x = i-offset

						surface.SetDrawColor(0, 0, 0, 100)
						surface.DrawLine(x+1, 1+1, x+1, pnl:GetTall() - 3+1)

						surface.SetDrawColor(self:GetSkin().Colours.Category.Header)
						surface.DrawLine(x, 1, x, pnl:GetTall() - 3)

						surface.SetTextPos(x+2+1, 1+1)
						surface.SetFont(pace.CurrentFont)
						surface.SetTextColor(0, 0, 0, 100)
						surface.DrawText(sec)

						surface.SetTextPos(x+2, 1)
						surface.SetFont(pace.CurrentFont)
						surface.SetTextColor(self:GetSkin().Colours.Category.Header)
						surface.DrawText(sec)
					end
				end

				for i = previousSecond, previousSecond+s:GetWide(), secondDistance/8 do
					if i-offset > 0 and i-offset < ScrW() then
						local x = i-offset
						surface.SetDrawColor(0, 0, 0, 100)
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
						local x = v:GetPos() - offset
						if x > s:GetWide() - 10 then continue end
						surface.SetDrawColor(255, 255, 255, 200)
						surface.DrawLine(x, -mat:Height()/2 - 5, x, h)

						surface.SetDrawColor(255, 255, 255, 255)
						surface.SetMaterial(mat)
						surface.DrawTexturedRect(1+x, mat:Height() - 5, mat:Width(), mat:Height())

					end

					if esmat then
						local ps = v:GetSize()
						local x = v:GetPos() - offset + (ps * 0.5)
						if x > s:GetWide() - 10 then continue end
						surface.SetDrawColor(255, 255, 255, 255)
						surface.SetMaterial(esmat)
						surface.DrawTexturedRect(1+x - (esmat:Width() * 0.5), esmat:Height(), esmat:Width(), esmat:Height())
						if ps >= 65 then
							draw.SimpleText( v.estyle, pace.CurrentFont, x, esmat:Height() * 2, self:GetSkin().Colours.Label.Dark, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP )
						else
							v:SetTooltip(v.estyle)
						end
					end
				end

				if not timeline.animation_part then return end

				local x = timeline.GetCycle() * self.keyframe_scroll:GetCanvas():GetWide()
				x = x - offset

				surface.SetDrawColor(255, 0, 0, 200)
				surface.DrawLine(x, 0, x, h)

				surface.SetDrawColor(255, 0, 0, 255)
				surface.SetMaterial(scrub)
				surface.DrawTexturedRect(1 + x - scrub:Width()/2, -11, scrub:Width(), scrub:Height())
			end
		end
	end

	function TIMELINE:Paint(w, h)
		self:GetSkin().tex.Tab_Control(0, 35, w, h-35)
	end

	function TIMELINE:Think()
		DFrame.Think(self)

		-- a gesture animation plays once and is removed from the entity when done,
		-- so flip the play button back to "play" when it's no longer on the entity
		if self.playing and timeline.animation_part then
			local anim = animations.GetEntityAnimation(timeline.entity, timeline.animation_part:GetAnimID())
			if not anim then
				self.playing = false
			end
		end

		if pace.Editor:GetPos() + pace.Editor:GetWide() / 2 < ScrW() / 2 then
			self:SetSize(ScrW()-(pace.Editor.x+pace.Editor:GetWide()), 93)
			self:SetPos(pace.Editor.x+pace.Editor:GetWide(), ScrH()-self:GetTall())
		else
			self:SetSize(ScrW()-(ScrW()-pace.Editor.x), 93)
			self:SetPos(0, ScrH()-self:GetTall())
		end

		local focus = vgui.GetKeyboardFocus()
		local noplay = false
		if focus and (focus:GetClassName() == "TextEntry" or focus:GetClassName() == "DTextEntry") then noplay = true end

		if input.IsKeyDown(KEY_SPACE) and not input.IsMouseDown(MOUSE_LEFT) and not noplay and pace.Focused then
			if not self.toggled then
				self:Toggle()
				self.toggled = true
			end
		else
			self.toggled = false
		end
	end

	function TIMELINE:Play()
		-- register a copy so the zero-backfill in RegisterAnimation doesn't
		-- mutate the data we're editing
		local data = table.Copy(timeline.data)
		animations.RegisterAnimation(timeline.animation_part:GetAnimID(), data)
		refresh_entity_anim(timeline.animation_part:GetAnimID())

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
		for i, v in pairs(self.keyframe_scroll:GetCanvas():GetChildren()) do
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

		for i, v in ipairs(timeline.data.FrameData) do
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

		for i, v in ipairs(timeline.data.FrameData) do
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
	vgui.Register("pac3_timeline", TIMELINE, "DFrame")
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

	function KEYFRAME:SetFrameData(index, tbl)
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

	function KEYFRAME:Paint(w, h)
		self.AltLine = self.Alternate
		derma.SkinHook( "Paint", "CategoryButton", self, w, h )

		if timeline.selected_keyframe == self then
			local c = self:GetSkin().Colours.Category.Line.Button_Selected
			surface.SetDrawColor(c.r, c.g, c.b, 250)
		end

		surface.DrawRect(0, 0, w, h)

		surface.SetDrawColor(0, 0, 0, 75)
		surface.DrawOutlinedRect(0, 0, w, h)
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
				pace.RecordUndoHistory()
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

				for i, v in ipairs(panels) do
					v:SetParent(timeline.frame.keyframe_scroll)
					v.Alternate = #timeline.frame.keyframe_scroll:GetCanvas():GetChildren()%2 == 1

					frames[i] = timeline.data.FrameData[v:GetAnimationIndex()]
				end

				for i, v in ipairs(frames) do
					timeline.data.FrameData[i] = v
					panels[i].AnimationKeyIndex = i
				end

				self:MouseCapture(false)
				self:SetCursor("hand")
				self.move = nil
				self.move_x = nil
				timeline.frame.moving = false

				-- the reorder rewrote timeline.data.FrameData above
				timeline.Save()
				timeline.SyncPreview()
				pace.RecordUndoHistory()
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
			timeline.SelectKeyframe(self)
			local menu = DermaMenu()
			menu:AddOption(L"set length", function()
				Derma_StringRequest(L"question",
					L"how long should this frame be in seconds?",
					tostring(self:GetWide()/secondDistance),
					function(str) self:SetLength(tonumber(str)) timeline.Save() pace.RecordUndoHistory() end,
					function() end,
					L"set length",
					L"cancel" )
			end):SetImage("icon16/time.png")

			menu:AddOption(L"multiply length", function()
				Derma_StringRequest(L"question",
					L"multiply "..self:GetAnimationIndex().."'s length",
					"1.0",
					function(str) self:SetLength(1/tonumber(str)) timeline.Save() pace.RecordUndoHistory() end,
					function() end,
					L"multiply length",
					L"cancel" )
			end):SetImage("icon16/time_add.png")

			menu:AddOption(L"edit bones", function()
				timeline.SelectKeyframe(self)
				timeline.OpenBonesPanel()
			end):SetImage("icon16/application_view_list.png")

			if not self:GetRestart() then
				menu:AddOption(L"set restart", function()
					for _, v in pairs(timeline.frame.keyframe_scroll:GetCanvas():GetChildren()) do
						v:SetRestart(false)
					end
					self:SetRestart(true)
					timeline.data.RestartFrame = self:GetAnimationIndex()
					timeline.Save()
					pace.RecordUndoHistory()
				end):SetImage("icon16/control_repeat_blue.png")
			else
				menu:AddOption(L"unset restart", function()
					self:SetRestart(false)
					timeline.data.RestartFrame = nil
					timeline.Save()
					pace.RecordUndoHistory()
				end):SetImage("icon16/control_repeat.png")
			end

			if not self:GetStart() then
				menu:AddOption(L"set start", function()
					for _, v in pairs(timeline.frame.keyframe_scroll:GetCanvas():GetChildren()) do
						v:SetStart(false)
					end
					self:SetStart(true)
					timeline.data.StartFrame = self:GetAnimationIndex()
					timeline.Save()
					pace.RecordUndoHistory()
				end):SetImage("icon16/control_play_blue.png")
			else
				menu:AddOption(L"unset start", function()
					self:SetStart(false)
					timeline.data.StartFrame = nil
					timeline.Save()
					pace.RecordUndoHistory()
				end):SetImage("icon16/control_play.png")
			end

			menu:AddOption(L"reverse", function()
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
				timeline.Save()
				timeline.SyncPreview()
				pace.RecordUndoHistory()
			end):SetImage("icon16/control_rewind_blue.png")

			menu:AddOption(L"mirror", function()
				timeline.MirrorKeyframe()
			end):SetImage("icon16/arrow_switch.png")

			local function duplicateTo(index)
				local data = self:GetData();
				table.insert(timeline.data.FrameData, index, table.Copy(data))
				local keyframes = timeline.Reindex()

				timer.Simple(0, function()
					timeline.SelectKeyframe(keyframes[math.Clamp(index, 1, #keyframes)])
					pace.RecordUndoHistory()
				end)
			end

			local sub, opt = menu:AddSubMenu(L"duplicate", function() duplicateTo(self:GetAnimationIndex()) end)
			sub:AddOption(L"start", function() duplicateTo(1) end):SetImage("icon16/resultset_first.png")
			sub:AddOption(L"end", function() duplicateTo(#timeline.data.FrameData + 1) end):SetImage("icon16/resultset_last.png")
			opt:SetIcon("icon16/page_copy.png")

			menu:AddOption(L"remove", function()
				local frameNum = self:GetAnimationIndex()
				if frameNum == 1 and not timeline.data.FrameData[2] then return end
				table.remove(timeline.data.FrameData, frameNum)

				local remove_i

				for i, v in pairs(timeline.frame.keyframe_scroll:GetCanvas():GetChildren()) do
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

				local count = #timeline.frame.keyframe_scroll:GetCanvas():GetChildren()
				local offset = remove_i >= count and count - 1 or remove_i + 1
				timeline.SelectKeyframe(timeline.frame.keyframe_scroll:GetCanvas():GetChildren()[offset])
				timeline.Save()
				pace.RecordUndoHistory()
			end):SetImage("icon16/page_delete.png")

			menu:AddOption(L"set easing style", function()
				if timeline.data.Interpolation ~= "linear" then
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
		timeline.Save()
		pace.RecordUndoHistory()
	end

	function KEYFRAME:RemoveEaseStyle()
		self:GetData().EaseStyle = nil
		self.estyle = nil
		timeline.Save()
		pace.RecordUndoHistory()
	end

	vgui.Register("pac3_timeline_keyframe", KEYFRAME, "DPanel")
end
