local L = pace.LanguageString

pace.timeline = pace.timeline or {}
local timeline = pace.timeline

local secondDistance = 200 --100px per second on timeline

local animation_types = {
	[0] = "TYPE_GESTURE",
	[1] = "TYPE_POSTURE",
	[2] = "TYPE_STANCE",
	[3] = "TYPE_SEQUENCE",
}

do
	local PART = {}

	PART.ClassName = "timeline_dummy_bone"
	PART.show_in_editor = false
	PART.PropertyWhitelist = {
		"Position",
		"Angles",
		"Bone",
	}

	function PART:GetBonePosition()
		local owner = self:GetOwner()
		local pos, ang

		pos, ang = pac.GetBonePosAng(owner, self.Bone, true)
		if owner:IsValid() then owner:InvalidateBoneCache() end

		self.cached_pos = pos
		self.cached_ang = ang

		return pos, ang
	end

	pac.RegisterPart(PART)
end

function timeline.IsActive()
	return timeline.editing
end

local function check_tpose()
	if not timeline.entity:IsPlayer() then return end
	if timeline.data.Type == boneanimlib.TYPE_SEQUENCE then
		hook.Add("CalcMainActivity", "pac3_timeline", function(ply)
			if ply == timeline.entity then
				return
					ply:LookupSequence("reference"),
					ply:LookupSequence("reference")
			end
		end)
	else
		hook.Remove("CalcMainActivity", "pac3_timeline")
	end
end

function timeline.SetAnimationType(str)
	if type(str) == "string" then
		for i,v in pairs(animation_types) do
			if v == "TYPE_" .. str:upper() then
				timeline.animation_type = i
				break
			end
		end
	end

	timeline.frame.add_keyframe_button:SetDisabled(timeline.animation_type == boneanimlib.TYPE_POSTURE)

	timeline.data = timeline.data or {}
	timeline.data.Type = timeline.animation_type

	timeline.frame:Toggle()
	timeline.frame:Toggle()

	timeline.Save()
end

function timeline.UpdateBones()
	if not timeline.selected_keyframe or not timeline.selected_keyframe:IsValid() then return end -- WHAT
	local currentFrame = timeline.selected_keyframe:GetAnimationIndex()
	local postureAnim = {Type = boneanimlib.TYPE_POSTURE, FrameData = {{BoneInfo = {}}}}

	postureAnim.FrameData[1] = table.Copy(timeline.data.FrameData[currentFrame])

	boneanimlib.RegisterLuaAnimation("editingAnim",postureAnim)

	timeline.entity:StopAllLuaAnimations()
	timeline.entity:SetLuaAnimation("editingAnim")
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
		if not data.Type then
			data.Type = 0

			local frames = {}
			for k, v in pairs(data.FrameData) do
				table.insert(frames, v)
			end
			data.FrameData = frames
		end

		timeline.SetAnimationType(data.Type)
		timeline.frame:Clear()

		for i, v in ipairs(data.FrameData) do
			local keyframe = timeline.frame:AddKeyFrame(true)
			keyframe:SetFrameData(i, v)
		end

		timeline.SelectKeyframe(timeline.frame.keyframe_scroll.Panels[1])
	else
		timeline.data = {FrameData = {}, Type = timeline.animation_type}
		timeline.frame:Clear()

		timeline.SelectKeyframe(timeline.frame:AddKeyFrame())
		timeline.Save()
	end

	timeline.UpdateFrameData()
	timeline.UpdateBones()
end

function timeline.Save()
	local data = table.Copy(timeline.data)
	local part = timeline.animation_part
	timer.Create("pace_timeline_save", 0.1, 1, function()
		if part and part:IsValid() then
			boneanimlib.RegisterLuaAnimation(part:GetAnimID(), data)
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
	timeline.UpdateBones()
	timeline.EditBone()
	timeline.Save()
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

	timeline.animation_part = nil
	timeline.frame:Remove()

	if timeline.entity:IsValid() then
		timeline.entity:StopAllLuaAnimations()
		timeline.entity:ResetBoneMatrix()
	end

	if timeline.dummy_bone and timeline.dummy_bone:IsValid() then
		timeline.dummy_bone:Remove()
	end

	hook.Remove("pace_OnVariableChanged", "pac3_timeline")
	hook.Remove("CalcMainActivity", "pac3_timeline")
end

function timeline.Open(part)
	file.CreateDir("pac3")
	file.CreateDir("pac3/__animations")
	file.CreateDir("pac3/__animations/backups")

	timeline.play_bar_offset = 0
	timeline.playing_animation = false
	timeline.editing = false
	timeline.first_pass = true

	timeline.editing = true
	timeline.animation_part = part
	timeline.entity = part:GetOwner()

	timeline.frame = vgui.Create("pac3_timeline")
	timeline.frame:SetPos(pace.Editor:GetWide(),ScrH()-150)
	timeline.frame:SetSize(ScrW()-pace.Editor:GetWide(),150)
	timeline.frame:SetTitle(L"animation editor")
	timeline.frame:ShowCloseButton(false)

	timeline.SetAnimationType(part.AnimationType)

	if timeline.dummy_bone and timeline.dummy_bone:IsValid() then timeline.dummy_bone:Remove() end
	timeline.dummy_bone = pac.CreatePart("timeline_dummy_bone", timeline.entity)

	hook.Add("pace_OnVariableChanged", "pac3_timeline", function(part, key, val)
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
				timeline.selected_keyframe:GetData().BoneInfo = timeline.selected_keyframe:GetData().BoneInfo or {}
				timeline.selected_keyframe:GetData().BoneInfo[timeline.selected_bone] = timeline.selected_keyframe:GetData().BoneInfo[timeline.selected_bone] or {}

				if key == "Position" then
					timeline.selected_keyframe:GetData().BoneInfo[timeline.selected_bone].MF = val.x
					timeline.selected_keyframe:GetData().BoneInfo[timeline.selected_bone].MR = -val.y
					timeline.selected_keyframe:GetData().BoneInfo[timeline.selected_bone].MU = val.z
				elseif key == "Angles" then
					timeline.selected_keyframe:GetData().BoneInfo[timeline.selected_bone].RR = val.p
					timeline.selected_keyframe:GetData().BoneInfo[timeline.selected_bone].RU = val.y
					timeline.selected_keyframe:GetData().BoneInfo[timeline.selected_bone].RF = val.r
				end

				timeline.UpdateBones()
			end
			timeline.Save()
		elseif part == timeline.animation_part then
			if key == "Data" or key == "URL" then
				timeline.Load(boneanimlib.GetLuaAnimations()[part:GetAnimID()])
			elseif key == "AnimationType" then
				timeline.SetAnimationType(val)
			end
		end
	end)

	timeline.Load(boneanimlib.GetLuaAnimations()[part:GetAnimID()])

	hook.Remove("CalcMainActivity", "pac3_timeline")
	timeline.entity:StopAllLuaAnimations()
	timeline.entity:ResetBoneMatrix()
end

hook.Add("pace_OnPartSelected", "pac3_timeline", function(part)
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
		local button_area = vgui.Create("DPanel", self)
		button_area:SetPaintBackground(false)
		button_area:SetWide(128)
		button_area:Dock(RIGHT)

		local pnl = vgui.Create("DButton", button_area)
		pnl:SetText(L"edit bone")
		pnl:Dock(TOP)
		pnl.DoClick = function()
			timeline.EditBone()
		end

		local pnl = vgui.Create("DButton",button_area)
		pnl:SetText(L"add keyframe")
		pnl.DoClick = function() timeline.SelectKeyframe(self:AddKeyFrame()) timeline.Save() end
		pnl:Dock(TOP)
		pnl:SetDisabled(true)
		self.add_keyframe_button = pnl

		local pnl = vgui.Create("DButton",button_area)
		pnl:SetText(L"play")
		pnl:Dock(TOP)
		pnl:SetDisabled(true)
		pnl.DoClick = function() self:Toggle() end
		self.play_button = pnl

		local pnl = vgui.Create("DButton", button_area)
		pnl:SetText(L"save")
		pnl:Dock(TOP)
		pnl.DoClick = function()
			Derma_StringRequest(
				L"question",
				L"save as",
				timeline.animation_part:GetName(),
				function(name)
					boneanimlib.RegisterLuaAnimation(name, table.Copy(timeline.data))
					file.Write("pac3/__animations/" .. name .. ".txt", util.TableToJSON(timeline.data)) end,
				function() end,
				L"save",
				L"cancel"
			)
		end

		local pnl = vgui.Create("DButton", button_area)
		pnl:SetText(L"load")
		pnl:Dock(TOP)
		pnl.DoClick = function()
			local menu = DermaMenu()
			menu:SetPos(pnl:LocalToScreen())

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

			-- LOL
			timer.Simple(0, function()
				local x, y = menu:GetPos()
				menu:SetPos(x, y - menu:GetTall())
			end)
		end

		local pnl = vgui.Create("DPanel",self)
		pnl:SetTall(20)
		pnl:Dock(TOP)
		pnl.Paint = function(s,w,h)
			local XPos = self.keyframe_scroll.OffsetX

			derma.SkinHook( "Paint", "Panel", s, w, h )

			if timeline.playing_animation then
				timeline.play_bar_offset = timeline.play_bar_offset + FrameTime()*secondDistance
			end

			local subtraction = 0
			if timeline.data then
				if timeline.first_pass and timeline.data.StartFrame then
					for i=1,timeline.data.StartFrame do
						local v = timeline.data.FrameData[i]
						if v then
							subtraction = subtraction+(1/(v.FrameRate or 1))
						end
					end
				elseif not timeline.first_pass and timeline.data.RestartFrame then
					for i=1,timeline.data.RestartFrame do
						local v = timeline.data.FrameData[i]
						if v then
							subtraction = subtraction+(1/(v.FrameRate or 1))
						end
					end
				end
			end

			if (timeline.play_bar_offset-subtraction)/secondDistance > self:GetAnimationTime() then
				local restartPos = self:ResolveRestart()
				timeline.play_bar_offset = restartPos*secondDistance
			end
			draw.RoundedBox(0,timeline.play_bar_offset-1,0,2,16,Color(255,0,0,240))

			local previousSecond = XPos-(XPos%secondDistance)
			for i=previousSecond,previousSecond+s:GetWide(),secondDistance/4 do
				if i-XPos > 0 and i-XPos < ScrW() then
					local sec = i/secondDistance
					draw.SimpleText(sec,pace.CurrentFont,i-XPos,6,Color(0,0,0,255),1,1)
				end
			end

		end

		local pnl = vgui.Create("DHorizontalScroller",self)
		pnl:Dock(TOP)
		self.keyframe_scroll = pnl
	end

	function TIMELINE:Toggle(bForce)
		if bForce ~= nil then
			self.isPlaying = bForce
		else
			self.isPlaying = not self.isPlaying
		end

		if self.isPlaying then
			boneanimlib.RegisterLuaAnimation("editortest", timeline.data)
			timeline.entity:StopAllLuaAnimations()
			timeline.entity:SetLuaAnimation("editortest")

			timeline.playing_animation = true
			timeline.play_bar_offset = self:ResolveStart()*secondDistance

			self.play_button:SetText(L"stop")
		else
			timeline.entity:StopAllLuaAnimations()

			if not timeline.IsEditingBone() then
				timeline.entity:ResetBoneMatrix()
				hook.Remove("CalcMainActivity", "pac3_timeline")
			end

			timeline.playing_animation = false

			timeline.play_bar_offset = self:ResolveStart()*secondDistance
			self.play_button:SetText(L"play")
		end
	end

	function TIMELINE:Clear()
		for i,v in pairs(self.keyframe_scroll.Panels) do
			v:Remove()
			self.keyframe_scroll.Panels[i] = nil
		end
		self.add_keyframe_button:SetDisabled(false)
		self.play_button:SetDisabled(false)
	end

	function TIMELINE:GetAnimationTime()
		local tempTime = 0
		local startIndex = 1

		if timeline.data and timeline.data.FrameData then
			for i=startIndex, #timeline.data.FrameData do
				local v = timeline.data.FrameData[i]
				tempTime = tempTime+(1/(v.FrameRate or 1))
			end
		end

		return tempTime
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

	end

	function TIMELINE:AddKeyFrame(raw)
		local keyframe = vgui.Create("pac3_timeline_keyframe")

		if not raw then
			keyframe.AnimationKeyIndex = table.insert(timeline.data.FrameData, {FrameRate = 1, BoneInfo = {}})
			keyframe.DataTable = timeline.data.FrameData[keyframe.AnimationKeyIndex]
		end

		keyframe:SetWide(secondDistance) --default to 1 second animations

		self.keyframe_scroll:AddPanel(keyframe)
		self.keyframe_scroll:InvalidateLayout()

		keyframe.Alternate = #timeline.frame.keyframe_scroll.Panels%2 == 1

		return keyframe

	end
	vgui.Register("pac3_timeline",TIMELINE,"DFrame")
end

do
	local KEYFRAME = {}

	function KEYFRAME:GetData()
		return self.DataTable
	end
	function KEYFRAME:SetFrameData(index,tbl)
		self.DataTable = tbl
		self.AnimationKeyIndex = index
		self:SetWide(1/self:GetData().FrameRate*secondDistance)
		self:GetParent():GetParent():InvalidateLayout() --rebuild the timeline
		if timeline.data.RestartFrame == index then
			self.RestartPos = true
		end
		if timeline.data.StartFrame == index then
			self.StartPos = true
		end
	end

	function KEYFRAME:GetAnimationIndex()
		return self.AnimationKeyIndex
	end

	function KEYFRAME:Paint(w,h)
		local c = self:GetSkin().Colours.Tree.Normal

		derma.SkinHook( "Paint", "ListBox", self, w, h )

		draw.RoundedBox(0,0,0,w,h, Color(c.r, c.g, c.b, self.Alternate and 75 or 25))

		if timeline.selected_keyframe == self then
			derma.SkinHook( "Paint", "Selection", self, w, h )
		end

		draw.SimpleText(self:GetAnimationIndex(),pace.CurrentFont,5,5,self:GetSkin().Colours.Tree.Normal,0,3)

		if self.RestartPos then
			draw.SimpleText("Restart",pace.CurrentFont,self:GetWide()-30,5,Color(0,0,0,255),2,3)
		end
		if self.StartPos then
			draw.SimpleText("Start",pace.CurrentFont,self:GetWide()-25,5,Color(0,0,0,255),0,3)
		end
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
				self:SetCursor("none")
				timeline.Save()
			elseif self.move then
				local panels = {}
				local frames = {}

				for k, v in pairs(timeline.frame.keyframe_scroll.Panels) do
					table.insert(panels, v)
					v:SetParent()
					timeline.frame.keyframe_scroll.Panels[k] = nil
				end

				table.sort(panels, function(a, b)
					return (a:GetPos() + a:GetWide() / 2) < (b:GetPos() + b:GetWide() / 2)
				end)

				for i,v in ipairs(panels) do
					timeline.frame.keyframe_scroll:AddPanel(v)
					v.Alternate = #timeline.frame.keyframe_scroll.Panels%2 == 1

					frames[i] = timeline.data.FrameData[v:GetAnimationIndex()]
				end

				for i,v in ipairs(frames) do
					timeline.data.FrameData[i] = v
					panels[i].AnimationKeyIndex = i
				end

				self:MouseCapture(false)
				self:SetCursor("none")
				self.move = nil
				self.move_x = nil
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
			end)

			menu:AddOption(L"multiply length",function()
				Derma_StringRequest(L"question",
						L"multiply "..self:GetAnimationIndex().."'s length",
						"1.0",
						function(str) self:SetLength(1/tonumber(str)) end,
						function() end,
						L"multiply length",
						L"cancel" )
				end)

			menu:AddOption(L"set restart",function()
				for _,v in pairs(timeline.frame.keyframe_scroll.Panels) do
					if v.RestartPos then v.RestartPos = nil end
				end
				self.RestartPos = true
				timeline.data.RestartFrame = self:GetAnimationIndex()
			end)

			menu:AddOption(L"set start",function()
				for _,v in pairs(timeline.frame.keyframe_scroll.Panels) do
					if v.StartPos then
						v.StartPos = nil
					end
				end
				self.StartPos = true
				timeline.data.StartFrame = self:GetAnimationIndex()
			end)

			if self:GetAnimationIndex() > 1 then
				menu:AddOption(L"reverse last frame",function()
					local tbl = timeline.data.FrameData[self:GetAnimationIndex() - 1].BoneInfo
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
				end)
			end

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
			end)

			menu:AddOption(L"remove",function()
				local frameNum = self:GetAnimationIndex()
				if frameNum == 1 and not timeline.data.FrameData[2] then return end
				table.remove(timeline.data.FrameData, frameNum)

				local remove_i

				for i,v in pairs(timeline.frame.keyframe_scroll.Panels) do
					if v == self then
						remove_i = i
					elseif v:GetAnimationIndex() > frameNum then
						v.AnimationKeyIndex = v.AnimationKeyIndex - 1
						v.Alternate = not v.Alternate
					end
				end

				table.remove(timeline.frame.keyframe_scroll.Panels, remove_i)

				timeline.frame.keyframe_scroll:InvalidateLayout()

				self:Remove()

				timeline.SelectKeyframe(timeline.frame.keyframe_scroll.Panels[#timeline.frame.keyframe_scroll.Panels])
			end)

			menu:Open()

		end
	end

	function KEYFRAME:SetLength(int)
		if not int then return end
		self:SetWide(secondDistance*int)
		self:GetParent():GetParent():InvalidateLayout() --rebuild the timeline
		self:GetData().FrameRate = 1/int --set animation frame rate
	end

	vgui.Register("pac3_timeline_keyframe",KEYFRAME,"DPanel")
end