local L = pace.LanguageString

module("boneanimlib",package.seeall)

local animationData = {}
local animType
local playBarOffset = 0
local playingAnimation = false
local animating = false

local secondDistance = 200 --100px per second on timeline
local firstPass = true

local TypeTable = {}
TypeTable[0] = "TYPE_GESTURE"
TypeTable[1] = "TYPE_POSTURE"
TypeTable[2] = "TYPE_STANCE"
TypeTable[3] = "TYPE_SEQUENCE"

do
	local PART = {}

	PART.ClassName = "timeline_dummy_bone"
	PART.show_in_editor = false

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

local function set_anim_type(str)
	if type(str) == "string" then
		for i,v in pairs(TypeTable) do
			if v == "TYPE_" .. str:upper() then
				animType = i
				break
			end
		end
	end

	if animType == TYPE_POSTURE then
		self.add_keyframe_button:SetDisabled(true)
	elseif animType == TYPE_SEQUENCE then
		pace.SetTPose(true)
	else
		pace.SetTPose(false)
	end

	animationData.Type = animType
end

local function update_bones()
	if not selected_keyframe or not selected_keyframe:IsValid() then return end -- WHAT
	local currentFrame = selected_keyframe:GetAnimationIndex()
	local postureAnim = {Type = TYPE_POSTURE, FrameData = {{BoneInfo = {}}}}

	postureAnim.FrameData[1] = table.Copy(animationData.FrameData[currentFrame])

	RegisterLuaAnimation("editingAnim",postureAnim)

	entity:StopAllLuaAnimations()
	entity:SetLuaAnimation("editingAnim")
end

local function update_frame_data()
	if not selected_keyframe or not selected_bone then return end

	local data = selected_keyframe:GetData().BoneInfo[selected_bone] or {}

	data.MF = data.MF or 0
	data.MR = data.MR or 0
	data.MU = data.MU or 0

	data.RR = data.RR or 0
	data.RU = data.RU or 0
	data.RF = data.RF or 0

	dummy_bone:SetPosition(Vector(data.MF, -data.MR, data.MU))
	dummy_bone:SetAngles(Angle(data.RR, data.RU, data.RF))
end

local function edit_bone()
	pace.Call("PartSelected", dummy_bone)
	selected_bone = pac.GetModelBones(entity)[dummy_bone:GetBone()].real
	update_frame_data()
end

local function load(data)
	animationData = data or util.JSONToTable(animation_part:GetData())

	if animationData then
		set_anim_type(animationData.Type)
		timeline:Clear()

		for i, v in pairs(animationData.FrameData) do
			local keyframe = timeline:AddKeyFrame(true)
			keyframe:SetFrameData(i, v)
		end

		selected_keyframe = timeline.keyframe_scroll.Panels[1]
	else
		animationData = {FrameData = {}, Type = animType}
		timeline:Clear()

		selected_keyframe = timeline:AddKeyFrame()
	end

	update_frame_data()
	update_bones()
end

local function save()
	animation_part:SetData(util.TableToJSON(animationData))
end

local function close_timeline()
	save()

	animating = false

	animation_part = nil
	timeline:Remove()

	entity:StopAllLuaAnimations()
	entity:ResetBoneMatrix()

	if dummy_bone and dummy_bone:IsValid() then
		dummy_bone:Remove()
	end

	hook.Remove("pace_OnVariableChanged", "pac3_timeline")
end

local function open_timeline(part)
	animating = true
	animation_part = part
	entity = part:GetOwner()

	timeline = vgui.Create("pac3_timeline")
	timeline:SetPos(pace.Editor:GetWide(),ScrH()-150)
	timeline:SetSize(ScrW()-pace.Editor:GetWide(),150)

	set_anim_type(part.AnimationType)

	if dummy_bone and dummy_bone:IsValid() then dummy_bone:Remove() end
	dummy_bone = pac.CreatePart("timeline_dummy_bone", entity)

	hook.Add("pace_OnVariableChanged", "pac3_timeline", function(part, key, val)

		if part == dummy_bone then
			if key == "Bone" then
				selected_bone = pac.GetModelBones(entity)[val].real
				update_frame_data()
			else
				selected_keyframe:GetData().BoneInfo = selected_keyframe:GetData().BoneInfo or {}
				selected_keyframe:GetData().BoneInfo[selected_bone] = selected_keyframe:GetData().BoneInfo[selected_bone] or {}

				if key == "Position" then
					selected_keyframe:GetData().BoneInfo[selected_bone].MF = val.x
					selected_keyframe:GetData().BoneInfo[selected_bone].MR = -val.y
					selected_keyframe:GetData().BoneInfo[selected_bone].MU = val.z
				elseif key == "Angles" then
					selected_keyframe:GetData().BoneInfo[selected_bone].RR = val.p
					selected_keyframe:GetData().BoneInfo[selected_bone].RU = val.y
					selected_keyframe:GetData().BoneInfo[selected_bone].RF = val.r
				end

				update_bones()
			end
		elseif part == animation_part then
			if key == "AnimationType" then
				set_anim_type(val)
			elseif key == "Data" then
				load()
			end
		end
	end)

	load()
end

hook.Add("pace_OnPartSelected", "pac3_timeline", function(part)
	if part.ClassName == "timeline_dummy_bone" then return end
	if part.ClassName == "custom_animation" then
		if animating then
			close_timeline()
		end
		open_timeline(part)
	elseif animating then
		close_timeline()
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
			edit_bone()
		end

		local pnl = vgui.Create("DButton",button_area)
		pnl:SetText(L"add keyframe")
		pnl.DoClick = function() selected_keyframe = self:AddKeyFrame() end
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
				animName or "",
				function(name)
					RegisterLuaAnimation(name, animationData)
					if not file.Exists("animations", "DATA") then
						file.CreateDir("animations")
					end
					file.Write("animations/" .. name .. ".txt", util.TableToJSON(animationData)) end,
				function(name) end,
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
					load(util.JSONToTable(file.Read("animations/" .. name)))
				end)
			end
		end

		local pnl = vgui.Create("DPanel",self)
		pnl:SetTall(20)
		pnl:Dock(TOP)
		pnl.Paint = function(s,w,h)
			local XPos = self.keyframe_scroll.OffsetX

			derma.SkinHook( "Paint", "Panel", s, w, h )

			if playingAnimation then
				playBarOffset = playBarOffset + FrameTime()*secondDistance
			end

			local subtraction = 0
			if animationData then
				if firstPass and animationData.StartFrame then
					for i=1,animationData.StartFrame do
						local v = animationData.FrameData[i]
						if v then
							subtraction = subtraction+(1/(v.FrameRate or 1))
						end
					end
				elseif not firstPass and animationData.RestartFrame then
					for i=1,animationData.RestartFrame do
						local v = animationData.FrameData[i]
						if v then
							subtraction = subtraction+(1/(v.FrameRate or 1))
						end
					end
				end
			end

			if (playBarOffset-subtraction)/secondDistance > self:GetAnimationTime() then
				local restartPos = self:ResolveRestart()
				playBarOffset = restartPos*secondDistance
			end
			draw.RoundedBox(0,playBarOffset-1,0,2,16,Color(255,0,0,240))

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
			RegisterLuaAnimation("editortest",animationData)
			entity:StopAllLuaAnimations()
			entity:SetLuaAnimation("editortest")

			playingAnimation = true
			playBarOffset = self:ResolveStart()*secondDistance

			self.play_button:SetText("Stop")
		else


			entity:StopAllLuaAnimations()
			playingAnimation = false


			playBarOffset = self:ResolveStart()*secondDistance
			self.play_button:SetText("Play")
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
		local globalAnims = GetLuaAnimations()
		local startIndex = 1

		if animationData and animationData.FrameData then
			for i=startIndex, #animationData.FrameData do
				local v = animationData.FrameData[i]
				tempTime = tempTime+(1/(v.FrameRate or 1))
			end
		end



		return tempTime

	end

	function TIMELINE:ResolveRestart() --get restart pos in seconds
		firstPass = false
		local timeInSeconds = 0
		local restartFrame = animationData.RestartFrame
		if not restartFrame then return 0 end --no restart pos? start at the start

		for i,v in pairs(animationData.FrameData) do
			if i == restartFrame then return timeInSeconds end
			timeInSeconds = timeInSeconds+(1/(v.FrameRate or 1))
		end

	end

	function TIMELINE:ResolveStart() --get restart pos in seconds
		firstPass = true
		local timeInSeconds = 0
		local startFrame = animationData.StartFrame
		if not startFrame then return 0 end --no restart pos? start at the start

		for i,v in pairs(animationData.FrameData) do
			if i == startFrame then return timeInSeconds end
			timeInSeconds = timeInSeconds+(1/(v.FrameRate or 1))
		end

	end

	function TIMELINE:AddKeyFrame(raw)
		local keyframe = vgui.Create("pac3_timeline_keyframe")

		if not raw then
			keyframe.AnimationKeyIndex = table.insert(animationData.FrameData, {FrameRate = 1, BoneInfo = {}})
			keyframe.DataTable = animationData.FrameData[keyframe.AnimationKeyIndex]
		end

		keyframe:SetWide(secondDistance) --default to 1 second animations

		self.keyframe_scroll:AddPanel(keyframe)
		self.keyframe_scroll:InvalidateLayout()

		keyframe.Alternate = #timeline.keyframe_scroll.Panels%2 == 1

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
		if animationData.RestartFrame == index then
			self.RestartPos = true
		end
		if animationData.StartFrame == index then
			self.StartPos = true
		end
	end

	function KEYFRAME:GetAnimationIndex()
		return self.AnimationKeyIndex
	end

	function KEYFRAME:Paint()
		local col = Color(150,150,150,255)
		if self.Alternate then
			col = Color(200,200,200,255)
		end
		draw.RoundedBox(0,0,0,self:GetWide(),self:GetTall(),col)
		if selected_keyframe == self then
			surface.SetDrawColor(255,0,0,255)
			surface.DrawOutlinedRect(1,1,self:GetWide()-2,self:GetTall()-2)
		end
		draw.SimpleText(self:GetAnimationIndex(),pace.CurrentFont,5,5,Color(0,0,0,255),0,3)
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

			self:SetLength((self.size_w - delta)/secondDistance)
		end
	end

	function KEYFRAME:OnMouseReleased(mc)
		if mc == MOUSE_LEFT then
			if self.size_x then
				self.size_x = nil
				self.size_w = nil
				self:MouseCapture(false)
				self:SetCursor("none")
			end
		end
	end

	function KEYFRAME:OnMousePressed(mc)
		if mc == MOUSE_LEFT then
			local x,y = self:CursorPos()

			if x >= self:GetWide() - 4 then
				self.size_x = gui.MouseX()
				self.size_w = self:GetWide()
				self:MouseCapture(true)
				self:SetCursor("sizewe")
			end

			timeline:Toggle(false)
			selected_keyframe = self
			update_frame_data()
			edit_bone()
			update_bones()
		elseif mc == MOUSE_RIGHT then
			local menu = DermaMenu()
			menu:AddOption(L"set length",function()
				Derma_StringRequest(L"question",
						L"how long should this frame be in seconds?",
						tostring(self:GetWide()/secondDistance),
						function( strTextOut ) self:SetLength(tonumber(strTextOut)) end,
						function( strTextOut ) end,
						L"set length",
						L"cancel" )
				end)
			menu:AddOption(L"multiply length",function()
				Derma_StringRequest(L"question",
						L"multiply "..self:GetAnimationIndex().."'s length",
						"1.0",
						function( strTextOut ) self:SetLength(1/tonumber(strTextOut)) end,
						function( strTextOut ) end,
						L"multiply length",
						L"cancel" )
				end)
			if animationData.Type ~= TYPE_GESTURE then
				menu:AddOption(L"set restart",function()
					for i,v in pairs(timeline.keyframe_scroll.Panels) do
						if v.RestartPos then v.RestartPos = nil end
					end
					self.RestartPos = true
					animationData.RestartFrame = self:GetAnimationIndex()
				end)
			end
			if animationData.Type == TYPE_SEQUENCE then
				menu:AddOption(L"set start",function()

					for i,v in pairs(timeline.keyframe_scroll.Panels) do
						if v.StartPos then v.StartPos = nil end
					end
					self.StartPos = true
					animationData.StartFrame = self:GetAnimationIndex()
				end)
			end

			if self:GetAnimationIndex() > 1 then
				menu:AddOption(L"reverse last frame",function()
					local tbl = animationData.FrameData[self:GetAnimationIndex() - 1].BoneInfo
					for i, v in pairs(tbl) do
						self:GetData().BoneInfo[i] = table.Copy(self:GetData().BoneInfo[i] or {})
						self:GetData().BoneInfo[i].MU = v.MU * -1
						self:GetData().BoneInfo[i].MR = v.MR * -1
						self:GetData().BoneInfo[i].MF = v.MF * -1
						self:GetData().BoneInfo[i].RU = v.RU * -1
						self:GetData().BoneInfo[i].RR = v.RR * -1
						self:GetData().BoneInfo[i].RF = v.RF * -1
					end
					update_frame_data()
				end)
			end

			menu:AddOption(L"duplicate to end", function()
				local keyframe = timeline:AddKeyFrame()

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
				selected_keyframe = keyframe
				update_frame_data()
			end)

			menu:AddOption(L"remove",function()
				local frameNum = self:GetAnimationIndex()
				if frameNum == 1 and not animationData.FrameData[2] then return end
				table.remove(animationData.FrameData, frameNum)
				local remove_i
				for i,v in pairs(timeline.keyframe_scroll.Panels) do
					if v == self then
						remove_i = i
					elseif v:GetAnimationIndex() > frameNum then
						v.AnimationKeyIndex = v.AnimationKeyIndex - 1
						v.Alternate = not v.Alternate
					end
				end

				table.remove(timeline.keyframe_scroll.Panels, remove_i)

				timeline.keyframe_scroll:InvalidateLayout()

				self:Remove()

				selected_keyframe = timeline.keyframe_scroll.Panels[#timeline.keyframe_scroll.Panels]
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