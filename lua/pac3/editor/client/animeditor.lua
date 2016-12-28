module("boneanimlib",package.seeall)

surface.CreateFont("DefaultFontVerySmall", {font = "tahoma", size = 10, weight = 0, antialias = false})
surface.CreateFont("DefaultFontSmall", {font = "tahoma", size = 11, weight = 0, antialias = false})
surface.CreateFont("DefaultFontSmallDropShadow", {font = "tahoma", size = 11, weight = 0, shadow = true, antialias = false})
surface.CreateFont("DefaultFont", {font = "tahoma", size = 13, weight = 500, antialias = false})
surface.CreateFont("DefaultFontBold", {font = "tahoma", size = 13, weight = 1000, antialias = false})
surface.CreateFont("DefaultFontLarge", {font = "tahoma", size = 16, weight = 0, antialias = false})

local animationData = {}

local function animprint()
	PrintTable(animationData)
end
concommand.Add("animprint",animprint)


local animName
local animType
local subAnimationsLoaded = {}
local playBarOffset = 0
local playingAnimation = false
local pressedPos = {}
local angToPlayer = Angle(0,0,0)
local selectedFrame
local draggingDir
local tblLineEndPoints = {}
local timeLine
local sliders
local animating = false
local editingAnimation = false
local rightDown = false
local leftDown = false
local mwheelDown = false
local TypeTable = {}
TypeTable[0] = "TYPE_GESTURE"
TypeTable[1] = "TYPE_POSTURE"
TypeTable[2] = "TYPE_STANCE"
TypeTable[3] = "TYPE_SEQUENCE"

local function DistFromPointToLine(x,y,x1,y1,x2,y2)

	local A = x - x1;
	local B = y - y1;
	local C = x2 - x1;
	local D = y2 - y1;

	local dot = A * C + B * D;
	local len_sq = C * C + D * D;
	local param = dot / len_sq;

	local xx,yy;

	if(param < 0) then

	    xx = x1;
	    yy = y1;
	elseif(param > 1) then

	    xx = x2;
	    yy = y2;

	else
	    xx = x1 + param * C;
	    yy = y1 + param * D;
	end
	return math.Dist(x,y,xx,yy)



end

local animEditorPanels = {}

local function AnimationStarted(bLoaded)
	if not bLoaded then
		animationData = {}
		animationData.FrameData = {}
		animationData.Type = animType

		for i,v in pairs(animEditorPanels) do
			if v.OnNewAnimation then
				v:OnNewAnimation()
			end
		end
	else

		for i,v in pairs(animEditorPanels) do
			if v.OnLoadAnimation then
				v:OnLoadAnimation()
			end
		end
	end
	editingAnimation = true
	timeLine.subAnims:Clear()
	table.Empty(subAnimationsLoaded)

end


local function NewAnimation()
	local frame = vgui.Create("DFrame")

	form = vgui.Create("DForm",frame)
	form:SetPos(5,25)
	form:SetWide(300)
	form:SetTall(300)
	form:SetName("Animation Properties")
	local entry = form:TextEntry("Animation Name")

	local info = form:Help([[Gestures are keyframed animations that use the current position and angles of the bones. They play once and then stop automatically.

	Postures are static animations that use the current position and angles of the bones. They stay that way until manually stopped. Use TimeToArrive if you want to have a posture lerp.

	Stances are keyframed animations that use the current position and angles of the bones. They play forever until manually stopped. Use RestartFrame to specify a frame to go to if the animation ends (instead of frame 1).

	Sequences are keyframed animations that use the origin and angles of the entity. They play forever until manually stopped. Use RestartFrame to specify a frame to go to if the animation ends (instead of frame 1).
	You can also use StartFrame to specify a starting frame for the first loop.]])
	local type = form:ComboBox("Animation Type")
	type:SetTall(100)

	type:AddChoice("TYPE_GESTURE", TYPE_GESTURE)
	type:AddChoice("TYPE_POSTURE", TYPE_POSTURE)
	type:AddChoice("TYPE_STANCE", TYPE_STANCE)
	type:AddChoice("TYPE_SEQUENCE", TYPE_SEQUENCE, true)
	local help = form:Help("Select your options")
	help:SetColor(Color(255,255,255))
	local begin = form:Button("Begin")
	begin.DoClick = function()
		animName = entry:GetValue()
		animType = _M[type:GetText()]

		if animName == "" then
			help:SetColor(Color(255,128,128))
			help:SetText("Write a name for this animation")
			surface.PlaySound("ui/buttonrollover.wav")
			return
		end
		if not animType then
			help:SetColor(Color(255,128,128))
			help:SetText("Select a valid animation type!")
			surface.PlaySound("ui/buttonrollover.wav")
			return
		end
		if (animType ~= nil) and (animName ~= nil) then --don't move on until these are set
		  if animType == TYPE_SEQUENCE then pace.SetTPose(true) end
		  if animType ~= TYPE_SEQUENCE then pace.SetTPose(false) end
		  frame:Remove()
		  AnimationStarted()
		end
	end
	frame:MakePopup()

	timer.Simple(0.01,function()frame:SetSize(form:GetWide()+10,450) frame:Center() end)
end

local function LoadAnimation()

	local frame = vgui.Create("DFrame")
	frame:SetSize(300,300)
	frame:SetTitle("Load Animation")
	local box = vgui.Create("DComboBox",frame)
	--box:SetMultiple(false) adurp
	box:StretchToParent(5,25,5,35)
	for i,v in pairs(GetLuaAnimations()) do
		if i ~= "editortest" and i ~= "editingAnim" and not string.find(i,"subPosture_") then --anim editor uses this internally
			if not string.find(i,"pac_anim_") then --animations made by custom_animation parts shouldn't be here
				box:AddChoice(i)
			end
		end
	end

	local button = vgui.Create("DButton",frame)
	button:SetWide(frame:GetWide()-10)
	button:SetPos(5,frame:GetTall()-25)
	button:SetText("Load Animation")
	button.DoClick = function()

		animName = box:GetText()
		animationData = GetLuaAnimations()[animName] or {}
		animType = animationData.Type
		if animType == TYPE_SEQUENCE then pace.SetTPose(true) end
		if animType ~= TYPE_SEQUENCE then pace.SetTPose(false) end
		frame:Remove()
		AnimationStarted(true)
		LocalPlayer():StopAllLuaAnimations()
	end

	frame:Center()
end

--return lua code for the loaded animation
local function OutputCode()
	if not animName then surface.PlaySound("buttons/button10.wav") return end
	local animData = table.Copy(animationData)

	--clean out unneeded entries
	for i,v in pairs(animData.FrameData) do
		for BoneName,BoneData in pairs(v.BoneInfo) do
			for MoveRot,Val in pairs(BoneData) do
				if Val == 0 then
					animData.FrameData[i].BoneInfo[BoneName][MoveRot] = nil
				end
			end
		end
	end




	local str = "RegisterLuaAnimation('"..animName.."', {\r\n"
	str = str .. "\tFrameData = {\r\n"
	local numFrames = table.Count(animData.FrameData)
	local numFrame = 1
	for frameIndex,frameData in pairs(animData.FrameData) do

		local commaFrame = ","
		if numFrame == numFrames then commaFrame = "" end



		str = str .. "\t\t{\r\n"
		str = str .. "\t\t\tBoneInfo = {\r\n"
		local numBones = table.Count(frameData.BoneInfo)
		local numBone = 1

		for boneName,boneData in pairs(frameData.BoneInfo) do
			local commaBone = ","
			if numBones == numBone then
				commaBone = ""
			end
			str = str .. "\t\t\t\t['"..boneName.."'] = {\r\n"
			local numChanges = table.Count(boneData)
			local numInner = 1

			for MoveRot,Value in pairs(boneData) do

				local commaInner = ","
				if numChanges == numInner then commaInner = "" end

				local innerStr = "\t\t\t\t\t"..MoveRot.." = "..Value..commaInner.."\r\n"
				str = str..innerStr
				numInner = numInner + 1



			end


			str = str .. "\t\t\t\t}"..commaBone.."\r\n"

			numBone = numBone + 1
		end



		numFrame = numFrame + 1

		str = str .. "\t\t\t},\r\n"
		if frameData.FrameRate then
			str = str .. "\t\t\tFrameRate = "..frameData.FrameRate.."\r\n"
		end


		str = str .. "\t\t}"..commaFrame.."\r\n"

	end
	str = str .. "\t},\r\n"

	if animData.RestartFrame then
		str = str .. "\tRestartFrame = "..animData.RestartFrame..",\r\n"
	end
	if animData.StartFrame then
		str = str .. "\tStartFrame = "..animData.StartFrame..",\r\n"
	end

	str = str .. "\tType = "..TypeTable[animData.Type].."\r\n})"



	return str
end


--calculates all the bone movements up to the current frame for DISPLAY PURPOSES.
local function ApplyEndResults()
	local currentFrame = selectedFrame:GetAnimationIndex()
	local postureAnim = {Type = TYPE_POSTURE,FrameData = {{BoneInfo = {}}}}

	--[[local timeInSeconds = 0
	for frameIndex,frameData in pairs(animationData.FrameData) do
		timeInSeconds = timeInSeconds + 1/(frameData.FrameRate or 1)

		for boneName, boneData in pairs(frameData.BoneInfo) do
			postureAnim.FrameData[1].BoneInfo[boneName] = postureAnim.FrameData[1].BoneInfo[boneName] or {}
			for moveType,moveVal in pairs(boneData) do
				postureAnim.FrameData[1].BoneInfo[boneName][moveType] = (postureAnim.FrameData[1].BoneInfo[boneName][moveType] or 0) + moveVal
			end
		end

		if frameIndex == currentFrame then break end
	end]]
	postureAnim.FrameData[1] = table.Copy(animationData.FrameData[currentFrame])


	--[[local subPostures = {}
	--load all the sub animations up to the exact point where the keyframe in the main animation ends...
	for i,v in pairs(subAnimationsLoaded) do

		local subPostureAnim = {Type = TYPE_POSTURE,FrameData = {{BoneInfo = {}}}}


		local anim = GetLuaAnimations()[i]
		local totalAnimTimeInSeconds = 0
		local timeToStart = 0
		local timeSoFar = 0

		--get the time from the actual start(0) to the animation start (StartFrame)
		if anim.StartFrame and anim.StartFrame > 1 then
			for i=1,anim.StartFrame-1 do

				timeToStart = timeToStart + 1/(anim.FrameData[i].FrameRate or 1)
			end
		end


		--pregather animation time
		for i=anim.StartFrame or 1,table.getn(anim.FrameData) do

			totalAnimTimeInSeconds = totalAnimTimeInSeconds + 1/(anim.FrameData[i].FrameRate or 1)
		end

		for frameIndex=1,table.getn(anim.FrameData) do


			local frameData = anim.FrameData[frameIndex]


			--this frame starts before the selected main keyframe ends
			if timeSoFar < timeInSeconds then


				local prevTime = timeSoFar
				timeSoFar = timeSoFar + 1/(frameData.FrameRate or 1)





				--we've reached a keyframe that extends beyond our main animation's current keyframe endpos
				local delta = 1
				if timeSoFar > timeInSeconds and (anim.StartFrame or 1) <= frameIndex then
					--thanks sassafrass
					delta = (timeInSeconds-prevTime)/(timeSoFar-prevTime)
				end

				for boneName,boneData in pairs(frameData.BoneInfo) do
					subPostureAnim.FrameData[1].BoneInfo[boneName] = subPostureAnim.FrameData[1].BoneInfo[boneName] or {}
					for moveType,moveVal in pairs(boneData) do
						if not subPostureAnim.FrameData[1].BoneInfo[boneName][moveType] then
							subPostureAnim.FrameData[1].BoneInfo[boneName][moveType] = moveVal*delta

						else
							subPostureAnim.FrameData[1].BoneInfo[boneName][moveType] = subPostureAnim.FrameData[1].BoneInfo[boneName][moveType] + moveVal*delta
						end
					end
				end
			end
		end
		RegisterLuaAnimation("subPosture_"..i,subPostureAnim)
		table.insert(subPostures,"subPosture_"..i)

	end]]

	RegisterLuaAnimation("editingAnim",postureAnim)


	LocalPlayer():StopAllLuaAnimations()
	LocalPlayer():SetLuaAnimation("editingAnim")
	--[[for i,v in pairs(subPostures) do
		LocalPlayer():SetLuaAnimation(v)
	end]]
end

local function LoadAnimationFromFile()

	local frame = vgui.Create("DFrame")
	frame:SetSize(300,300)
	frame:SetTitle("Load Animation From File")
	local box = vgui.Create("DComboBox",frame)
	--box:SetMultiple(false)
	box:StretchToParent(5,25,5,35)
	for i,v in pairs(file.Find("animations/*.txt", "DATA")) do
		box:AddChoice(string.sub(v,1,-5))
	end

	local button = vgui.Create("DButton",frame)
	button:SetWide(frame:GetWide()-10)
	button:SetPos(5,frame:GetTall()-25)
	button:SetText("Load Animation")
	button.DoClick = function()

		local name = box:GetText()

		local str = file.Read("animations/"..name..".txt", "DATA")
		if not str then return end
		local success, t = pcall(util.JSONToTable, str)
		if not success then
			ErrorNoHalt("WARNING: Animation '"..name.."' failed to load\n")
		else
			RegisterLuaAnimation(name,t)


		animName = name
		animationData = GetLuaAnimations()[animName] or {}
		animType = animationData.Type

		if animType == TYPE_SEQUENCE then pace.SetTPose(true) end
		if animType ~= TYPE_SEQUENCE then pace.SetTPose(false) end
		frame:Remove()
		AnimationStarted(true)
		LocalPlayer():StopAllLuaAnimations()
		end
	end
	frame:Center()
end
local function RegisterAll()


	for i,v in pairs(file.Find("animations/*.txt", "DATA")) do
		local str = file.Read("animations/"..string.sub(v,1,-5)..".txt", "DATA")
		if not str then return end
		local success,t = pcall(Deserialize, str)
		if not success then
			ErrorNoHalt("WARNING: Animation '"..string.sub(v,1,-5).."' failed to load: "..tostring(t).."\n")
		else
			RegisterLuaAnimation(string.sub(v,1,-5),t)
		end
	end
end



local function SaveAnimation()
	if(not file.Exists("animations","DATA")) then file.CreateDir"animations" end

			Derma_StringRequest( "Question",
					"Save as...",
					animName or "",
					function( strTextOut ) RegisterLuaAnimation(strTextOut,animationData) file.Write("animations/"..strTextOut..".txt", util.TableToJSON(animationData)) end,
					function( strTextOut ) end,
					"Save",
					"Cancel" )






end


local topLevelPanels = {}
local function IsMouseOverPanel()

	local mouseX = gui.MouseX()
	local mouseY = gui.MouseY()
	for i,v in pairs(topLevelPanels) do
		if ValidPanel(v) and v:IsVisible() then

			local bChild = IsChildOfHiddenParent(v)
			if not bChild then

				local x,y = v:GetPos()
				local w = v:GetWide()
				local h = v:GetTall()
				local overX = mouseX > x and mouseX < x+w
				local overY = mouseY > y and mouseY < y+h
				if overX and overY then return true end
			end
		else
			table.remove(topLevelPanels,i)
		end
	end
	return false
end


local function AnimationEditorOff()
--I want to eventually create a "save unsaved changes" dialog box when you close
	if(not file.Exists("animations/backups","DATA")) then file.CreateDir"animations/backups" end
	local tbl = util.TableToJSON(animationData)
	if tbl then
		file.Write("animations/backups/previous_session_"..os.date("%m%d%y%H%M%S")..".txt", tbl)
	end
	for i,v in pairs(animEditorPanels) do
		v:Remove()
	end
	pace.SetInAnimEditor(false)
	pace.SetTPose(false)
	LocalPlayer():StopAllLuaAnimations()
	LocalPlayer():ResetBoneMatrix()
	gui.EnableScreenClicker(false)
	animating = false
	animName = nil
	animationData = nil
	animType = nil
	editingAnimation = false
	pace.CloseEditor()
end

local function AnimationEditorOn()
	if hook.Call("PrePACEditorOpen", GAMEMODE, LocalPlayer()) == false then return end

	pace.OpenEditor()

	if animating then AnimationEditorOff() return end
	for i,v in pairs(animEditorPanels) do
		v:Remove()
	end

	--RunConsoleCommand("animeditor_in_editor", "1")
	pace.SetInAnimEditor(true)

	timeLine = vgui.Create("AnimEditor_TimeLine")
	timeLine.OnClose = function() AnimationEditorOff() end
	table.insert(animEditorPanels,timeLine)

	local frame=vgui.Create("DFrame")
	frame:SetTitle("sliders")
	frame:ShowCloseButton(true)
	frame.OnClose = function() AnimationEditorOff() end
	frame:SetPos(ScrW()-200,0)

	sliders = vgui.Create("AnimEditor_Sliders",frame)
	sliders:Dock(TOP)

	table.insert(animEditorPanels,frame)

	frame:SetSize(200,350)

	gui.EnableScreenClicker(true)

	animating = true
end
concommand.Add("animate",AnimationEditorOn)

local secondDistance = 200 --100px per second on timeline

local firstPass = true
local TIMELINE = {}
function TIMELINE:Init()

	self:SetTitle("Timeline")
	self:ShowCloseButton(true)
	self:SetPos(pace.Editor:GetWide(),ScrH()-150)
	self:SetSize(ScrW()-pace.Editor:GetWide(),150)
	---self:SetDraggable(false)

	local area = vgui.Create("DPanel", self)
	area:SetPaintBackground(false)
	area:SetWide(128)
	area:Dock(RIGHT)

	local btn = vgui.Create("DButton", area)
	btn:SetText("File")
	btn:Dock(TOP)
	btn.DoClick = function()
		local menu = DermaMenu()
		menu:SetPos(btn:LocalToScreen())
		menu:AddOption("New Animation", NewAnimation)
		menu:AddOption("Load Registered Animation", LoadAnimation)
		menu:AddOption("Load Animation From File", LoadAnimationFromFile)
		menu:AddOption("Save Animation To File", SaveAnimation)
		menu:AddOption("Copy Raw Lua To Clipboard", function() local str = OutputCode() if not str then return end SetClipboardText(str) end)
	end

	self.bones = vgui.Create("DButton", area)
	self.bones:SetText("Select Bone")
	self.bones:Dock(TOP)
	self.bones.DoClick = function()
		pace.SelectBone(LocalPlayer(), function(data)
			selectedBone = data.value.real
			sliders:SetFrameData()
		end)
	end

	local addKeyButton = vgui.Create("DButton",area)
	addKeyButton:SetText("Add KeyFrame")
	addKeyButton.DoClick = function() self:AddKeyFrame() end
	addKeyButton:Dock(TOP)
	self.addKeyButton = addKeyButton
	addKeyButton:SetDisabled(true)

	self.isPlaying = false
	local play = vgui.Create("DButton",area)
	play:SetText("Play")
	play:Dock(TOP)
	play.DoClick = function() self:Toggle() end
	self.play = play
	self.play:SetDisabled(true)

	local timeLineTop = vgui.Create("DPanel",self)
	timeLineTop:SetTall(20)
	timeLineTop:Dock(TOP)
	timeLineTop.Paint = function(s,w,h)
		local XPos = self.timeLine.OffsetX

		derma.SkinHook( "Paint", "Panel", s, w, h )

		if animName then
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
		end

		local previousSecond = XPos-(XPos%secondDistance)
		for i=previousSecond,previousSecond+s:GetWide(),secondDistance/4 do
			if i-XPos > 0 and i-XPos < ScrW() then
				local sec = i/secondDistance
				draw.SimpleText(sec,"DefaultFontSmall",i-XPos,6,Color(0,0,0,255),1,1)
			end
		end

	end

	local timeLine = vgui.Create("DHorizontalScroller",self)
	timeLine:Dock(TOP)
	self.timeLine = timeLine

	self.subAnims = vgui.Create("DPanelList",self)
	self.subAnims:Dock(TOP)
	self.subAnims:EnableVerticalScrollbar()

end
function TIMELINE:Toggle(bForce)
		if bForce ~= nil then
			self.isPlaying = bForce
		else
			self.isPlaying = not self.isPlaying
		end
		if self.isPlaying then


			RegisterLuaAnimation("editortest",animationData)
			LocalPlayer():StopAllLuaAnimations()
			LocalPlayer():SetLuaAnimation("editortest")
			for i,v in pairs(subAnimationsLoaded) do
				LocalPlayer():SetLuaAnimation(i)
			end

			playingAnimation = true
			playBarOffset = self:ResolveStart()*secondDistance

			self.play:SetText("Stop")

			for i,v in pairs(subAnimationsLoaded) do
				v.subPlayBarOffset = v.storedTimeTillStart
			end
		else


			LocalPlayer():StopAllLuaAnimations()
			playingAnimation = false


			playBarOffset = self:ResolveStart()*secondDistance
			self.play:SetText("Play")
			for i,v in pairs(subAnimationsLoaded) do
				v.subPlayBarOffset = v.storedTimeTillStart
			end
		end

end

function TIMELINE:OnNewAnimation()
	for i,v in pairs(self.timeLine.Panels) do
		v:Remove()
		self.timeLine.Panels[i] = nil
	end
	self.addKeyButton:SetDisabled(false)
	self.play:SetDisabled(false)
	self:AddKeyFrame() --helper add first frame
end
local addFrame = true
function TIMELINE:OnLoadAnimation()
	for i,v in pairs(self.timeLine.Panels) do
		v:Remove()
		self.timeLine.Panels[i] = nil
	end
	self.addKeyButton:SetDisabled(false)
	self.play:SetDisabled(false)


	addFrame = false
	for i,v in pairs(animationData.FrameData) do

		local keyframe = self:AddKeyFrame() --helper add first frame
		keyframe:SetFrameData(i,v)

	end
	addFrame = true

end
local flip = false
function TIMELINE:LoadSubAnimation(name)

	local anim = GetLuaAnimations()[name]
	if not anim then return end

	if subAnimationsLoaded[name] then
		self.subAnims:RemoveItem(subAnimationsLoaded[name])
		subAnimationsLoaded[name] = nil
	else
		flip = not flip
		local timeLine = vgui.Create("DHorizontalScroller")
		timeLine:SetPos(5,45)
		timeLine:SetSize(self:GetWide()-self:GetTall()-30,20)



		local dataCache = {} --holds key frame size for sub anims
		timeLine.subPlayBarOffset = 0

		local tempFlip = flip
		local start = anim.StartFrame or 1
		local restart = anim.RestartFrame or 1
		local restartPos = 0
		local totalAnimationTime = 0
		local firstPass = true

		for i,v in ipairs(anim.FrameData) do

			local frameLen = 1/(v.FrameRate or 1)
			if anim.StartFrame and anim.StartFrame > i then
				timeLine.subPlayBarOffset = timeLine.subPlayBarOffset + frameLen*secondDistance
			end
			if anim.RestartFrame and anim.RestartFrame > i then
				restartPos = restartPos + frameLen
			end
			totalAnimationTime = totalAnimationTime + frameLen
			table.insert(dataCache,secondDistance/v.FrameRate)
		end
		timeLine.storedTimeTillStart = timeLine.subPlayBarOffset


		timeLine.Paint = function(s)
			local XPos = self.timeLine.OffsetX


			local total = 0
			local drawnName = false


			for i,v in ipairs(dataCache) do

					local col
					if i%2 == 0 then
						if tempFlip then
							col = Color(200,200,200,255)
						else
							col = Color(150,150,150,255)
						end
					else
						if tempFlip then
							col = Color(150,150,150,255)
						else
							col = Color(200,200,200,255)
						end
					end
					local leftStart = total-XPos
					draw.RoundedBox(0,leftStart,0,v,self:GetTall(),col)

					draw.SimpleText(name,"DefaultFontSmall",leftStart+20,5,Color(0,0,0,255),0,3)
					draw.SimpleText(i,"DefaultFontSmall",total-XPos+5,5,Color(0,0,0,255),0,3)
					local rightBound = leftStart+v
					if restart ~= 1 and restart == i then
						draw.SimpleText("Restart","DefaultFontSmall",rightBound-30,5,Color(0,0,0,255),2,3)
					end
					if start ~= 1 and start == i then
						draw.SimpleText("Start","DefaultFontSmall",rightBound-25,5,Color(0,0,0,255),0,3)
					end
					total = total + v

			end




				if playingAnimation then
					timeLine.subPlayBarOffset = timeLine.subPlayBarOffset + FrameTime()*secondDistance
				end


				local subtraction = 0
				if firstPass and animationData.StartFrame then
					subtraction = timeLine.storedTimeTillStart
					firstPass = false
				elseif not firstPass and animationData.RestartFrame then
					for i=1,animationData.RestartFrame do
						subtraction = restartPos
					end
				end


				if (timeLine.subPlayBarOffset-subtraction)/secondDistance > totalAnimationTime then
					timeLine.subPlayBarOffset = restartPos*secondDistance
				end
				draw.RoundedBox(0,timeLine.subPlayBarOffset-1,0,2,16,Color(0,255,0,240))

		end
		self.subAnims:AddItem(timeLine)




		subAnimationsLoaded[name] = timeLine
	end


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

local flippedBool = false
function TIMELINE:AddKeyFrame()
	flippedBool = not flippedBool
	local keyframe = vgui.Create("AnimEditor_KeyFrame")
	keyframe:SetWide(secondDistance) --default to 1 second animations

	keyframe.Alternate = flippedBool


	--[[if keyframe:GetAnimationIndex() and keyframe:GetAnimationIndex() > 1 then
		keyframe:CopyPreviousKey()
	end]]

	self.timeLine:AddPanel(keyframe)
	self.timeLine:InvalidateLayout()



	if animType == TYPE_POSTURE then self.addKeyButton:SetDisabled(true) end --postures have only one keyframe

	return keyframe

end
vgui.Register("AnimEditor_TimeLine",TIMELINE,"DFrame")

local KEYFRAME = {}

function KEYFRAME:Init()
	self:SetWide(secondDistance)
	if addFrame then
		self.AnimationKeyIndex = table.insert(animationData.FrameData,{FrameRate = 1,BoneInfo = {}})
		self.DataTable = animationData.FrameData[self.AnimationKeyIndex]
	end
	selectedFrame = self
end
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
function KEYFRAME:CopyPreviousKey()
	local iKeyIndex = self:GetAnimationIndex()-1
	local tFrameData = table.Copy(animationData.FrameData[iKeyIndex])
	if not tFrameData then return end



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
	if selectedFrame == self then
		surface.SetDrawColor(255,0,0,255)
		surface.DrawOutlinedRect(1,1,self:GetWide()-2,self:GetTall()-2)
	end
	draw.SimpleText(self:GetAnimationIndex(),"DefaultFontSmall",5,5,Color(0,0,0,255),0,3)
	if self.RestartPos then
		draw.SimpleText("Restart","DefaultFontSmall",self:GetWide()-30,5,Color(0,0,0,255),2,3)
	end
	if self.StartPos then
		draw.SimpleText("Start","DefaultFontSmall",self:GetWide()-25,5,Color(0,0,0,255),0,3)
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
		end
	end

	local x,y = self:CursorPos()
	if x >= self:GetWide() - 4 then
		self:SetCursor("sizewe")
	end
end

function KEYFRAME:OnMousePressed(mc)
	if mc == MOUSE_LEFT then
		local x,y = self:CursorPos()

		if x >= self:GetWide() - 4 then
			self.size_x = gui.MouseX()
			self.size_w = self:GetWide()
			self:MouseCapture(true)

			return
		end
		timeLine:Toggle(false)
		selectedFrame = self
		sliders:SetFrameData()
		ApplyEndResults()
	elseif mc == MOUSE_RIGHT then
		local menu = DermaMenu()
		menu:AddOption("Change Frame Length",function()
			Derma_StringRequest( "Question",
					"How long should this frame be (seconds)?",
					tostring(self:GetWide()/secondDistance),
					function( strTextOut ) self:SetLength(tonumber(strTextOut)) end,
					function( strTextOut ) end,
					"Set Length",
					"Cancel" )
			end)
		menu:AddOption("Change Frame Rate",function()
			Derma_StringRequest( "Question",
					"Set frame "..self:GetAnimationIndex().."'s framerate",
					"1.0",
					function( strTextOut ) self:SetLength(1/tonumber(strTextOut)) end,
					function( strTextOut ) end,
					"Set Frame Rate",
					"Cancel" )
			end)
		if animationData.Type ~= TYPE_GESTURE then
			menu:AddOption("Set Restart Pos",function()

				for i,v in pairs(timeLine.timeLine.Panels) do
					if v.RestartPos then v.RestartPos = nil end
				end
				self.RestartPos = true
				animationData.RestartFrame = self:GetAnimationIndex()
			end)
		end
		if animationData.Type == TYPE_SEQUENCE then
			menu:AddOption("Set Start Pos",function()

				for i,v in pairs(timeLine.timeLine.Panels) do
					if v.StartPos then v.StartPos = nil end
				end
				self.StartPos = true
				animationData.StartFrame = self:GetAnimationIndex()
			end)
		end



		if self:GetAnimationIndex() > 1 then
			menu:AddOption("Reverse Previous Frame",function()
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
				sliders:SetFrameData()
			end)
		end

		menu:AddOption("Duplicate Frame To End", function()
			local keyframe = timeLine:AddKeyFrame()

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
			sliders:SetFrameData()

			--[[local tbl = animationData.FrameData
			local keyframe = timeLine:AddKeyFrame()
			keyframe.DataTable = table.Copy(self:GetData() or {})
			selectedFrame = keyframe
			sliders:SetFrameData()]]
		end)


		menu:AddOption("Remove Frame",function()
			local frameNum = self:GetAnimationIndex()
			if frameNum == 1 and not animationData.FrameData[2] then return end --can't delete the frame when it's the only one
			table.remove(animationData.FrameData,frameNum)
			for i,v in pairs(timeLine.timeLine.Panels) do
				if v == self then
					timeLine.timeLine.Panels[i] = nil
				elseif v:GetAnimationIndex() > frameNum then
					v.AnimationKeyIndex = v.AnimationKeyIndex - 1
					v.Alternate = not v.Alternate
				end
			end

			timeLine.timeLine:InvalidateLayout()
			self:Remove()

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
vgui.Register("AnimEditor_KeyFrame",KEYFRAME,"DPanel")


local SLIDERS = {}
function SLIDERS:Init()
	self:SetName("Modify Bone")
	self.Sliders = {}

	self.Sliders.MU = self:NumSlider("Translate UP", nil, -100, 100, 0 )
	self.Sliders.MU.OnValueChanged = function(s,v) self:OnSliderChanged("MU",v) end
	self.Sliders.MU.Label:SetTextColor(Color(0,0,255,255))

	local oldEnter = self.Sliders.MU.Wang.OnEnter
	self.Sliders.MU.Wang.OnEnter = function(s) self:OnSliderChanged("MU",self.Sliders.MU.Wang:GetValue()) self.Sliders.MU.Slider:InvalidateLayout() oldEnter(s) end

	self.Sliders.MR = self:NumSlider("Translate RIGHT", nil, -100, 100, 0 )
	self.Sliders.MR.OnValueChanged = function(s,v) self:OnSliderChanged("MR",v) end
	self.Sliders.MR.Label:SetTextColor(Color(255,0,0,255))
	self.Sliders.MR.Wang.OnEnter = function(s) self:OnSliderChanged("MR",self.Sliders.MR.Wang:GetValue()) self.Sliders.MR.Slider:InvalidateLayout() oldEnter(s) end

	self.Sliders.MF = self:NumSlider("Translate FORWARD", nil, -100, 100, 0 )
	self.Sliders.MF.OnValueChanged = function(s,v) self:OnSliderChanged("MF",v) end
	self.Sliders.MF.Label:SetTextColor(Color(0,255,0,255))
	self.Sliders.MF.Wang.OnEnter = function(s) self:OnSliderChanged("MF",self.Sliders.MF.Wang:GetValue()) self.Sliders.MF.Slider:InvalidateLayout() oldEnter(s) end

	self.Sliders.RU = self:NumSlider("Rotate UP", nil, -360, 360, 0 )
	self.Sliders.RU.OnValueChanged = function(s,v) self:OnSliderChanged("RU",v) end
	self.Sliders.RU.Label:SetTextColor(Color(0,255,0,255))
	self.Sliders.RU.Wang.OnEnter = function(s) self:OnSliderChanged("RU",self.Sliders.RU.Wang:GetValue()) self.Sliders.RU.Slider:InvalidateLayout() oldEnter(s) end

	self.Sliders.RR = self:NumSlider("Rotate RIGHT", nil, -360, 360, 0 )
	self.Sliders.RR.OnValueChanged = function(s,v) self:OnSliderChanged("RR",v) end
	self.Sliders.RR.Label:SetTextColor(Color(255,0,0,255))
	self.Sliders.RR.Wang.OnEnter = function(s) self:OnSliderChanged("RR",self.Sliders.RR.Wang:GetValue()) self.Sliders.RR.Slider:InvalidateLayout() oldEnter(s) end

	self.Sliders.RF = self:NumSlider("Rotate FORWARD", nil, -360, 360, 0 )
	self.Sliders.RF.OnValueChanged = function(s,v) self:OnSliderChanged("RF",v) end
	self.Sliders.RF.Label:SetTextColor(Color(0,0,255,255))
	self.Sliders.RF.Wang.OnEnter = function(s) self:OnSliderChanged("RF",self.Sliders.RF.Wang:GetValue()) self.Sliders.RF.Slider:InvalidateLayout() oldEnter(s) end

end
local needsUpdate = true
function SLIDERS:SetFrameData()
	--print(selectedFrame,selectedBone,selectedFrame:GetData().BoneInfo[selectedBone])
	needsUpdate = false
	if not ValidPanel(selectedFrame) or not selectedBone or not selectedFrame:GetData().BoneInfo[selectedBone] then

		for i,v in pairs(self.Sliders) do
			v:SetValue(0)
		end
		needsUpdate = true
	return end

	for i,v in pairs(self.Sliders) do
		v:SetValue(selectedFrame:GetData().BoneInfo[selectedBone][i] or 0)
	end
	needsUpdate = true
end
function SLIDERS:Dragged3D(changeAmt,moveType)
	local ChangeAmt = math.Clamp(self.Sliders[moveType]:GetValue()+changeAmt,-360,360)
	if ChangeAmt == self.Sliders[moveType]:GetValue() then return end
	self.Sliders[moveType]:SetValue(ChangeAmt)
end
function SLIDERS:OnSliderChanged(moveType,value)
	if not ValidPanel(selectedFrame) or not selectedBone then return end --no keyframe/bone selected
	if (tonumber(value) == 0 and selectedFrame:GetData().BoneInfo[selectedBone] == nil) or not needsUpdate then return end

	--[[if selectedFrame:GetAnimationIndex() > 1 then
		local prevBoneData = animationData.FrameData[self:GetAnimationIndex()-1][selectedBone]
		if prevBoneData then]]


	selectedFrame:GetData().BoneInfo = selectedFrame:GetData().BoneInfo or {}
	selectedFrame:GetData().BoneInfo[selectedBone] = selectedFrame:GetData().BoneInfo[selectedBone] or {}
	selectedFrame:GetData().BoneInfo[selectedBone][moveType] = tonumber(value)
	ApplyEndResults()


end
vgui.Register("AnimEditor_Sliders",SLIDERS,"DForm")

hook.Add("HUDPaint", "animeditor_InAnimEditor", function()
	for key, ply in pairs(player.GetAll()) do
		if ply ~= LocalPlayer() and ply.InAnimEditor then
			local id = ply:LookupBone("ValveBiped.Bip01_Head1")
			local pos_3d = id and ply:GetBonePosition(id) or ply:EyePos()
			local pos_2d = (pos_3d + Vector(0,0,10)):ToScreen()
			draw.DrawText("In Animation Editor", "ChatFont", pos_2d.x, pos_2d.y, Color(255,255,255,math.Clamp((pos_3d + Vector(0,0,10)):Distance(EyePos()) * -1 + 500, 0, 500)/500*255),1)
		end
	end
end)
