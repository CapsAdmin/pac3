module("boneanimlib",package.seeall)

surface.CreateFont("DefaultFontVerySmall", {font = "DejaVu Sans", size = 10, weight = 0, antialias = false})
surface.CreateFont("DefaultFontSmall", {font = "DejaVu Sans", size = 11, weight = 0, antialias = false})
surface.CreateFont("DefaultFontSmallDropShadow", {font = "DejaVu Sans", size = 11, weight = 0, shadow = true, antialias = false})
surface.CreateFont("DefaultFont", {font = "DejaVu Sans", size = 13, weight = 500, antialias = false})
surface.CreateFont("DefaultFontBold", {font = "DejaVu Sans", size = 13, weight = 1000, antialias = false})
surface.CreateFont("DefaultFontLarge", {font = "DejaVu Sans", size = 16, weight = 0, antialias = false})

local boneList = {}

boneList["ValveBiped.Bip01"] = {
	"ValveBiped.Bip01_Pelvis",
	"ValveBiped.Bip01_Spine",
	"ValveBiped.Bip01_Spine1",
	"ValveBiped.Bip01_Spine2",
	"ValveBiped.Bip01_Spine4",
	"ValveBiped.Bip01_Neck1",
	"ValveBiped.Bip01_Head1",
	"ValveBiped.Bip01_R_Clavicle",
	"ValveBiped.Bip01_R_UpperArm",
	"ValveBiped.Bip01_R_Forearm",
	"ValveBiped.Bip01_R_Hand",
	"ValveBiped.Bip01_L_Clavicle",
	"ValveBiped.Bip01_L_UpperArm",
	"ValveBiped.Bip01_L_Forearm",
	"ValveBiped.Bip01_L_Hand",
	"ValveBiped.Bip01_R_Thigh",
	"ValveBiped.Bip01_R_Calf",
	"ValveBiped.Bip01_R_Foot",
	"ValveBiped.Bip01_R_Toe0",
	"ValveBiped.Bip01_L_Thigh",
	"ValveBiped.Bip01_L_Calf",
	"ValveBiped.Bip01_L_Foot",
	"ValveBiped.Bip01_L_Toe0"
}
boneList["ValveBiped"] = {
	"ValveBiped.hips",
	"ValveBiped.leg_bone1_L",
	"ValveBiped.leg_bone2_L",
	"ValveBiped.leg_bone3_L",
	"ValveBiped.Bip01_L_Foot",
	"ValveBiped.Bip01_L_Toe0",
	"ValveBiped.leg_bone1_R",
	"ValveBiped.leg_bone2_R",
	"ValveBiped.leg_bone3_R",
	"ValveBiped.Bip01_R_Foot",
	"ValveBiped.Bip01_R_Toe0",
	"ValveBiped.spine1",
	"ValveBiped.spine2",
	"ValveBiped.spine3",
	"ValveBiped.spine4",
	"ValveBiped.neck1",
	"ValveBiped.neck2",
	"ValveBiped.head",
	"ValveBiped.clavical_L",
	"ValveBiped.arm1_L",
	"ValveBiped.arm2_L",
	"ValveBiped.hand1_L",
	"ValveBiped.clavical_R",
	"ValveBiped.arm1_R",
	"ValveBiped.arm2_R",
	"ValveBiped.hand1_R",
	"ValveBiped.bone",
	"ValveBiped.bone1",
	"ValveBiped.bone2"

}
local function ParseBones(ent)
	local thisbone = -1
	local bonetbl = {}
	if ent:GetBoneCount() == nil then return {} end
	while thisbone < ent:GetBoneCount() do
		thisbone = thisbone + 1
		realname = ent:GetBoneName(thisbone)
		if realname ~= "__INVALIDBONE__" then table.insert(bonetbl,realname) end
	end
	return bonetbl
end

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
local camDist = 200
local camHeight = 60 --offset from GetPos
local pressedPos = {}
local angToPlayer = Angle(0,0,0)
local selectedBoneSet = "ValveBiped.Bip01"
local selectedFrame
local draggingDir
local tblLineEndPoints = {}
local timeLine
local mainSettings
local sliders
local subAnims
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

local function PaintTopBar()
	local wide = ScrW()
	draw.RoundedBox(0,0,0,wide,26,Color(0,0,0,255))
	draw.RoundedBox(0,1,1,wide-2,24,Color(50,50,50,255))
	draw.SimpleText("Lua Animation Editor (API by JetBoom)","DefaultFont",25,13,Color(255,255,255,255),0,1)
	if type(animName ) == "string" then
		draw.SimpleText("Working On: ("..animName..")","DefaultFont",wide*0.5,13,Color(255,255,255,255),1,1)
	else
		draw.SimpleText("No Animation Loaded!","DefaultFont",wide*0.5,13,Color(255,255,255,255),1,1)
	end


	if selectedBone && selectedBone != "" then

			local boneID = LocalPlayer():LookupBone(selectedBone)

			if boneID then
				local matrix = LocalPlayer():GetBoneMatrix(boneID)
				local vec = matrix:GetTranslation()
				local ang = matrix:GetAngles()

				local upDir = ang:Up()*20
				local rightDir = ang:Right()*20
				local forwardDir = ang:Forward()*20

				local origin = vec:ToScreen()

				if !leftDown && draggingDir then
					draggingDir = nil
				end

				surface.SetDrawColor(255,0,0,255)
				local p1 = (vec+rightDir):ToScreen()

				local dist = DistFromPointToLine(gui.MouseX(),gui.MouseY(),origin.x,origin.y,p1.x,p1.y)
				if (dist < 10 && !draggingDir) ||  draggingDir == "RR" then
					surface.SetDrawColor(255,255,255,255)
					draggingDir = "RR"
					tblLineEndPoints[1] = {x=origin.x,origin.y}
					tblLineEndPoints[1] = {p1.x,p1.y}
				end



				surface.DrawLine(origin.x,origin.y,p1.x,p1.y)

				surface.SetDrawColor(0,255,0,255)
				local p2 = (vec+upDir):ToScreen()

				local dist = DistFromPointToLine(gui.MouseX(),gui.MouseY(),origin.x,origin.y,p2.x,p2.y)
				if (dist < 10 && !draggingDir) || draggingDir == "RU" then
					surface.SetDrawColor(255,255,255,255)
					draggingDir = "RU"
					tblLineEndPoints[1] = {x=origin.x,origin.y}
					tblLineEndPoints[1] = {p1.x,p1.y}
				end

				surface.DrawLine(origin.x,origin.y,p2.x,p2.y)

				surface.SetDrawColor(0,0,255,255)
				local p3 = (vec+forwardDir):ToScreen()

				local dist = DistFromPointToLine(gui.MouseX(),gui.MouseY(),origin.x,origin.y,p3.x,p3.y)
				if (dist < 10 && !draggingDir) || draggingDir == "RF" then
					surface.SetDrawColor(255,255,255,255)
					draggingDir = "RF"
					tblLineEndPoints[1] = {x=origin.x,origin.y}
					tblLineEndPoints[1] = {p1.x,p1.y}
				end
				surface.DrawLine(origin.x,origin.y,p3.x,p3.y)


			end


	end

end





local animEditorPanels = {}

local function AnimationStarted(bLoaded)
	subAnims:Refresh()
	if !bLoaded then
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
		if !animType then
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
		if i != "editortest" && i != "editingAnim" && !string.find(i,"subPosture_") then --anim editor uses this internally
			if !string.find(i,"pac_anim_") then --animations made by custom_animation parts shouldn't be here
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
	if !animName then surface.PlaySound("buttons/button10.wav") return end
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
		if anim.StartFrame && anim.StartFrame > 1 then
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
				if timeSoFar > timeInSeconds && (anim.StartFrame or 1) <= frameIndex then
					--thanks sassafrass
					delta = (timeInSeconds-prevTime)/(timeSoFar-prevTime)
				end

				for boneName,boneData in pairs(frameData.BoneInfo) do
					subPostureAnim.FrameData[1].BoneInfo[boneName] = subPostureAnim.FrameData[1].BoneInfo[boneName] or {}
					for moveType,moveVal in pairs(boneData) do
						if !subPostureAnim.FrameData[1].BoneInfo[boneName][moveType] then
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
		if !str then return end
		local success, t = pcall(util.JSONToTable, str)
		if !success then
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
		if !str then return end
		local success,t = pcall(Deserialize, str)
		if !success then
			ErrorNoHalt("WARNING: Animation '"..string.sub(v,1,-5).."' failed to load: "..tostring(t).."\n")
		else
			RegisterLuaAnimation(string.sub(v,1,-5),t)
		end
	end
	subAnims:Refresh()

end



local function SaveAnimation()
	if(!file.Exists("animations","DATA")) then file.CreateDir"animations" end

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
		if ValidPanel(v) && v:IsVisible() then

			local bChild = IsChildOfHiddenParent(v)
			if !bChild then

				local x,y = v:GetPos()
				local w = v:GetWide()
				local h = v:GetTall()
				local overX = mouseX > x && mouseX < x+w
				local overY = mouseY > y && mouseY < y+h
				if overX && overY then return true end
			end
		else
			table.remove(topLevelPanels,i)
		end
	end
	return false
end


local function FixMouse()
	if !animating then return end
	local notOverPanel = !IsMouseOverPanel()

	if !input.IsMouseDown(MOUSE_RIGHT) && rightDown then
		rightDown = false
	elseif input.IsMouseDown(MOUSE_RIGHT) && !rightDown && notOverPanel then
		rightDown = true
		pressedPos[1] = gui.MouseX()
		pressedPos[2] = gui.MouseY()

	elseif input.IsMouseDown(MOUSE_RIGHT) && rightDown then
		local mvmtX = gui.MouseX()-pressedPos[1]
		angToPlayer.yaw = angToPlayer.yaw + mvmtX

		local mvmtY = (gui.MouseY()-pressedPos[2])*0.1
		camHeight = math.max(10,camHeight - mvmtY)

		gui.SetMousePos(pressedPos[1],pressedPos[2])
	end
	if input.IsMouseDown(MOUSE_LEFT) && !leftDown && notOverPanel then

		if draggingDir then
			pressedPos[1] = gui.MouseX()
			pressedPos[2] = gui.MouseY()
			leftDown = true
		end

	elseif !input.IsMouseDown(MOUSE_LEFT) && leftDown then
		leftDown = false
	elseif input.IsMouseDown(MOUSE_LEFT) && leftDown then

		local mvmtX = gui.MouseX()-pressedPos[1]
		local mvmtY = gui.MouseY()-pressedPos[2]
		local dist = math.Distance(gui.MouseX(),gui.MouseY(),pressedPos[1],pressedPos[2])
		if mvmtX < 0 then
			dist = dist * -1
		end

		sliders:Dragged3D(dist,draggingDir)

		gui.SetMousePos(pressedPos[1],pressedPos[2])
	end
	if(input.IsMouseDown(MOUSE_WHEEL_DOWN)) then
		print":O"
	end
end


local function AnimationEditorView(pl,origin,angles,fov)


	local t = {}
	local vec = pl:GetForward()*camDist

	local camTarget = pl:GetPos()+Vector(0,0,camHeight)

	vec:Rotate(angToPlayer)
	t.origin=camTarget+vec
	t.angles=(camTarget-t.origin):Angle()
	return t

end

local function AnimationEditorOff()
--I want to eventually create a "save unsaved changes" dialog box when you close
	if(!file.Exists("animations/backups","DATA")) then file.CreateDir"animations/backups" end
	local tbl = util.TableToJSON(animationData)
	if tbl then
		file.Write("animations/backups/previous_session_"..os.date("%m%d%y%H%M%S")..".txt", tbl)
	end
	for i,v in pairs(animEditorPanels) do
		v:Remove()
	end
	pace.SetInAnimEditor(false)
	hook.Remove("HUDPaint","PaintTopBar")
	hook.Remove("CalcView","AnimationView")
	hook.Remove("Think","FixMouse")
	hook.Remove("ShouldDrawLocalPlayer","DrawMe")
	pace.SetTPose(false)
	LocalPlayer():StopAllLuaAnimations()
	LocalPlayer():ResetBoneMatrix()
	gui.EnableScreenClicker(false)
	animating = false
	animName = nil
	animationData = nil
	animType = nil
	editingAnimation = false
end

local function AnimationEditorOn()
	if hook.Call("PrePACEditorOpen", GAMEMODE, LocalPlayer()) == false then return end

	if animating then AnimationEditorOff() return end
	for i,v in pairs(animEditorPanels) do
		v:Remove()
	end

	--RunConsoleCommand("animeditor_in_editor", "1")
	pace.SetInAnimEditor(true)

	local close = vgui.Create("DButton")
	close:SetText("X")
	close.DoClick = function(slf) AnimationEditorOff() end
	close:SetSize(16,16)
	close:SetPos(ScrW() - 16-4,4)
	table.insert(animEditorPanels,close)

	timeLine = vgui.Create("AnimEditor_TimeLine")
	table.insert(animEditorPanels,timeLine)

	local frame=vgui.Create("DFrame")
	frame:SetTitle("Main Menu")
	frame:ShowCloseButton(false)
	table.insert(animEditorPanels,frame)
	mainSettings = vgui.Create("AnimEditor_MainSettings",frame)
	frame:SetSize(mainSettings:GetWide(), mainSettings:GetTall()+22)
	timer.Simple(0.01, function() frame:SetPos(ScrW()-200,ScrH()-mainSettings:GetTall()-timeLine:GetTall()*1.7) end)
	table.insert(animEditorPanels,mainSettings)





	local sliderFrame = vgui.Create("DFrame")
	sliderFrame:ShowCloseButton(false)
	sliderFrame:SetTitle("Sliders")
	sliderFrame:MakePopup()
	sliders = vgui.Create("AnimEditor_Sliders",sliderFrame)


	table.insert(animEditorPanels,sliderFrame)


	subAnims = vgui.Create("AnimEditor_SubAnimations")



	table.insert(animEditorPanels,subAnims)

	hook.Add("HUDPaint","PaintTopBar",PaintTopBar)
	hook.Add("CalcView","AnimationView",AnimationEditorView)
	hook.Add("Think","FixMouse",FixMouse)
	hook.Add("ShouldDrawLocalPlayer","DrawMe",function() return true end)
	gui.EnableScreenClicker(true)

	animating = true
end
concommand.Add("animate",AnimationEditorOn)

local secondDistance = 200 --100px per second on timeline



local MAIN = {}
function MAIN:Init()

	self:SetName("Main Settings")
	self:SetSize(200,315)
	self:SetPos(0,22)

	boneList["ParsedSkeleton"] = ParseBones(LocalPlayer())

	local newanim = self:Button("New Animation")
	newanim.DoClick = NewAnimation


	local loadanim = self:Button("Load Registered Animation")
	loadanim.DoClick = LoadAnimation

	local loadanim = self:Button("Load Animation From File")
	loadanim.DoClick = LoadAnimationFromFile

	local saveanim = self:Button("Save Animation To File")
	saveanim.DoClick = SaveAnimation

	--local register = self:Button("Register All Animations")
	--register.DoClick = RegisterAll

	local viewcode = self:Button("Copy Raw Lua To Clipboard")
	viewcode.DoClick = function() local str = OutputCode() if !str then return end SetClipboardText(str) end

	local maxcamdist_cvar = CreateConVar("pac_animeditor_maxcamdist",200)
	local maxcamdist = maxcamdist_cvar:GetInt()

	local distSlider = self:NumSlider("Cam Distance", nil, 40, maxcamdist, 0 )
	distSlider:SetValue(maxcamdist)
	distSlider.OnValueChanged = function(s,v) camDist = v end

	local boneSet = self:ComboBox("Bone Set")
	for i,v in pairs(boneList) do
		boneSet:AddChoice(i)
	end
	boneSet:SetText(selectedBoneSet)
	boneSet.OnSelect = function(s,i,v,d) selectedBoneSet = v self:RefreshBoneSet() end

	self.bones = self:ComboBox("Selected Bone")
	self.bones:SetTall(200)
	--self.bones:SetMultiple(false)
	self.bones.OnSelect = function(me, index, value, data)
		selectedBone = value
		sliders:SetFrameData()
	end

	self:RefreshBoneSet()


end

function MAIN:RefreshBoneSet()
	if not boneList[selectedBoneSet] then return end

	self.bones:Clear()

	for i, v in pairs(boneList[selectedBoneSet]) do
		--self.bones:AddItem(v).DoClick = function(s) selectedBone = s:GetValue() sliders:SetFrameData() end
		local id = self.bones:AddChoice(v)
	end
end

vgui.Register("AnimEditor_MainSettings", MAIN, "DForm")

local firstPass = true
local TIMELINE = {}
function TIMELINE:Init()

	self:SetTitle("Timeline")
	self:ShowCloseButton(false)
	self:SetSize(ScrW(),150)
	self:SetPos(0,ScrH()-150)
	self:SetDraggable(false)

	local timeLine = vgui.Create("DHorizontalScroller",self)
	timeLine:SetPos(5,45)
	timeLine:SetSize(self:GetWide()-self:GetTall()-30,20)
	self.timeLine = timeLine


	self.subAnims = vgui.Create("DPanelList",self)
	self.subAnims:SetSize(timeLine:GetWide(),self:GetTall()-75)
	self.subAnims:SetPos(5,50+timeLine:GetTall())
	self.subAnims:EnableVerticalScrollbar()
	local timeLineTop = vgui.Create("DPanel",self)
	timeLineTop:SetPos(5,25)
	timeLineTop:SetSize(self:GetWide()-self:GetTall(),20)
	timeLineTop.Paint = function(s)



		local XPos = timeLine.OffsetX

		draw.RoundedBox(0,0,0,self:GetWide(),16,Color(200,200,200,255))

		if animName then
			if playingAnimation then
				playBarOffset = playBarOffset + FrameTime()*secondDistance
			end


			local subtraction = 0
			if animationData then
				if firstPass && animationData.StartFrame then
					for i=1,animationData.StartFrame do
						local v = animationData.FrameData[i]
						if v then
							subtraction = subtraction+(1/(v.FrameRate or 1))
						end
					end
				elseif !firstPass && animationData.RestartFrame then
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
			if i-XPos > 0 && i-XPos < ScrW() then
				local sec = i/secondDistance
				draw.SimpleText(sec,"DefaultFontSmall",i-XPos,6,Color(0,0,0,255),1,1)
			end
		end

	end



	local addKeyButton = vgui.Create("DButton",self)
	addKeyButton:SetText("Add KeyFrame")
	addKeyButton.DoClick = function() self:AddKeyFrame() end
	addKeyButton:SetSize(self:GetTall()-20,self:GetTall()-60)
	addKeyButton:SetPos(self:GetWide()-self:GetTall()+10,30)
	self.addKeyButton = addKeyButton
	addKeyButton:SetDisabled(true)

	self.isPlaying = false
	local play = vgui.Create("DButton",self)
	play:SetPos(self:GetWide()-self:GetTall()+10,self:GetTall()-25)
	play:SetWide(self:GetTall()-60)
	play:SetText("Play")
	play.DoClick = function()
		self:Toggle()


	end
	self.play = play
	self.play:SetDisabled(true)

end
function TIMELINE:Toggle(bForce)
		if bForce != nil then
			self.isPlaying = bForce
		else
			self.isPlaying = !self.isPlaying
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
	if !anim then return end

	if subAnimationsLoaded[name] then
		self.subAnims:RemoveItem(subAnimationsLoaded[name])
		subAnimationsLoaded[name] = nil
	else
		flip = !flip
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
			if anim.StartFrame && anim.StartFrame > i then
				timeLine.subPlayBarOffset = timeLine.subPlayBarOffset + frameLen*secondDistance
			end
			if anim.RestartFrame && anim.RestartFrame > i then
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
					if restart != 1 && restart == i then
						draw.SimpleText("Restart","DefaultFontSmall",rightBound-30,5,Color(0,0,0,255),2,3)
					end
					if start != 1 && start == i then
						draw.SimpleText("Start","DefaultFontSmall",rightBound-25,5,Color(0,0,0,255),0,3)
					end
					total = total + v

			end




				if playingAnimation then
					timeLine.subPlayBarOffset = timeLine.subPlayBarOffset + FrameTime()*secondDistance
				end


				local subtraction = 0
				if firstPass && animationData.StartFrame then
					subtraction = timeLine.storedTimeTillStart
					firstPass = false
				elseif !firstPass && animationData.RestartFrame then
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
	if !restartFrame then return 0 end --no restart pos? start at the start

	for i,v in pairs(animationData.FrameData) do
		if i == restartFrame then return timeInSeconds end
		timeInSeconds = timeInSeconds+(1/(v.FrameRate or 1))
	end

end

function TIMELINE:ResolveStart() --get restart pos in seconds
	firstPass = true
	local timeInSeconds = 0
	local startFrame = animationData.StartFrame
	if !startFrame then return 0 end --no restart pos? start at the start

	for i,v in pairs(animationData.FrameData) do
		if i == startFrame then return timeInSeconds end
		timeInSeconds = timeInSeconds+(1/(v.FrameRate or 1))
	end

end

local flippedBool = false
function TIMELINE:AddKeyFrame()
	flippedBool = !flippedBool
	local keyframe = vgui.Create("AnimEditor_KeyFrame")
	keyframe:SetWide(secondDistance) --default to 1 second animations

	keyframe.Alternate = flippedBool


	--[[if keyframe:GetAnimationIndex() && keyframe:GetAnimationIndex() > 1 then
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
	if !tFrameData then return end



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
function KEYFRAME:OnMousePressed(mc)
	if mc == MOUSE_LEFT then
		timeLine:Toggle(false)
		selectedFrame = self
		sliders:SetFrameData()
		ApplyEndResults()
	elseif mc == MOUSE_RIGHT then
		local menu = DermaMenu()
		menu:AddOption("Change Frame Length",function()
			Derma_StringRequest( "Question",
					"How long should this frame be (seconds)?",
					"1.0",
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
		if animationData.Type != TYPE_GESTURE then
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
			if frameNum == 1 and !animationData.FrameData[2] then return end --can't delete the frame when it's the only one
			table.remove(animationData.FrameData,frameNum)
			for i,v in pairs(timeLine.timeLine.Panels) do
				if v == self then
					timeLine.timeLine.Panels[i] = nil
				elseif v:GetAnimationIndex() > frameNum then
					v.AnimationKeyIndex = v.AnimationKeyIndex - 1
					v.Alternate = !v.Alternate
				end
			end

			timeLine.timeLine:InvalidateLayout()
			self:Remove()

		end)

		menu:Open()

	end
end
function KEYFRAME:SetLength(int)
	if !int then return end
	self:SetWide(secondDistance*int)
	self:GetParent():GetParent():InvalidateLayout() --rebuild the timeline
	self:GetData().FrameRate = 1/int --set animation frame rate
end
vgui.Register("AnimEditor_KeyFrame",KEYFRAME,"DPanel")


local SLIDERS = {}
function SLIDERS:Init()
	self:SetName("Modify Bone")
	self:SetMinimumSize(200,650)
	self:SetWide(200)
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
	--self:GetParent():MakePopup()
	--self:GetParent():KillFocus()
	--self:GetParent():SetKeyboardInputEnabled(false)
	--self:GetParent():SetMouseInputEnabled(false)

	timer.Simple(0.01,function()
		local x,y = self:GetSize()
		self:GetParent():SetSize(x+10,y+200)
		self:SetPos(5,25)
		self:GetParent():SetPos(0,ScrH()-timeLine:GetTall()-self:GetParent():GetTall())
		x,y = self:GetParent():GetPos()
		subAnims:SetPos(0,y-subAnims:GetTall())


	end)
end
local needsUpdate = true
function SLIDERS:SetFrameData()
	--print(selectedFrame,selectedBone,selectedFrame:GetData().BoneInfo[selectedBone])
	needsUpdate = false
	if !ValidPanel(selectedFrame) || !selectedBone || !selectedFrame:GetData().BoneInfo[selectedBone] then

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
	if !ValidPanel(selectedFrame) || !table.HasValue(boneList[selectedBoneSet],selectedBone) then return end --no keyframe/bone selected
	if (tonumber(value) == 0 && selectedFrame:GetData().BoneInfo[selectedBone] == nil) || !needsUpdate then return end

	--[[if selectedFrame:GetAnimationIndex() > 1 then
		local prevBoneData = animationData.FrameData[self:GetAnimationIndex()-1][selectedBone]
		if prevBoneData then]]


	selectedFrame:GetData().BoneInfo = selectedFrame:GetData().BoneInfo or {}
	selectedFrame:GetData().BoneInfo[selectedBone] = selectedFrame:GetData().BoneInfo[selectedBone] or {}
	selectedFrame:GetData().BoneInfo[selectedBone][moveType] = tonumber(value)
	ApplyEndResults()


end
vgui.Register("AnimEditor_Sliders",SLIDERS,"DForm")

local SUBANIMS = {}
function SUBANIMS:Init()
	self:SetSize(210,120)
	self:ShowCloseButton(false)
	self.AnimList = vgui.Create("DComboBox",self)
	self.AnimList:StretchToParent(5,25,5,30)
	self:SetTitle("Sub Animations")
	self.SelectedAnim = ""
	self.AnimList.OnSelect = function(me, id, value, data)
		self.SelectedAnim = value
		if subAnimationsLoaded[value] then
			self.AddButton:SetText("Remove Animation")
		else
			self.AddButton:SetText("Add Animation")
		end
	end

	self.AddButton = vgui.Create("DButton",self)
	self.AddButton:SetPos(5,self:GetTall()-25)
	self.AddButton:SetSize(self:GetWide()-10,20)
	self.AddButton.DoClick = function() timeLine:LoadSubAnimation(self.SelectedAnim,self.AnimList)
				if subAnimationsLoaded[i] then
					self.AddButton:SetText("Remove Animation")
				else
					self.AddButton:SetText("Add Animation")
				end
	end
	self.AddButton:SetText("Click an Animation...")

	self:Refresh()

end
function SUBANIMS:Refresh()
	self.AnimList:Clear()
	for i,v in pairs(GetLuaAnimations()) do

		--no need to show these
		if i != "editortest" && i != animName && i != "editingAnim" && !string.find(i,"subPosture_") then
			if !string.find(i,"pac_anim_") then --animations made by custom_animation parts shouldn't be here
				local item = self.AnimList:AddChoice(i)
				--[[local item = self.AnimList:AddItem(i)
				item.DoClick = function()
					self.SelectedAnim = i
					if subAnimationsLoaded[i] then
						self.AddButton:SetText("Remove Animation")
					else
						self.AddButton:SetText("Add Animation")
					end

				end]]
			end
		end
	end

end
vgui.Register("AnimEditor_SubAnimations",SUBANIMS,"DFrame")

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
