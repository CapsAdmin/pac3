
module("boneanimlib",package.seeall)

include("pac3/libraries/sh_boneanimlib.lua")

local ANIMATIONFADEOUTTIME = 0.125

net.Receive("bal_reset", function(length)
	local ent = net.ReadEntity()
	local anim = net.ReadString()
	local time = net.ReadFloat()
	local power = net.ReadFloat()
	local timescale = net.ReadFloat()

	if ent:IsValid() then
		ent:ResetLuaAnimation(anim, time ~= -1 and time, power ~= -1 and power, timescale ~= -1 and timescale)
	end
end)

net.Receive("bal_set", function(length)
	local ent = net.ReadEntity()
	local anim = net.ReadString()
	local time = net.ReadFloat()
	local power = net.ReadFloat()
	local timescale = net.ReadFloat()

	if ent:IsValid() then
		ent:SetLuaAnimation(anim, time ~= -1 and time, power ~= -1 and power, timescale ~= -1 and timescale)
	end
end)

net.Receive("bal_stop", function(length)
	local ent = net.ReadEntity()
	local anim = net.ReadString()
	local tim = net.ReadFloat()

	if tim == 0 then tim = nil end
	if ent:IsValid() then
		ent:StopLuaAnimation(anim, tim)
	end
end)

net.Receive("bal_stopgroup", function(length)
	local ent = net.ReadEntity()
	local animgroup = net.ReadString()
	local tim = net.ReadFloat()

	if tim == 0 then tim = nil end
	if ent:IsValid() then
		ent:StopLuaAnimationGroup(animgroup, tim)
	end
end)

net.Receive("bal_stopall", function(length)
	local ent = net.ReadEntity()
	local tim = net.ReadFloat()

	if tim == 0 then tim = nil end
	if ent:IsValid() then
		ent:StopAllLuaAnimations(tim)
	end
end)

local TYPE_GESTURE = TYPE_GESTURE
local TYPE_POSTURE = TYPE_POSTURE
local TYPE_STANCE = TYPE_STANCE
local TYPE_SEQUENCE = TYPE_SEQUENCE

local Animations = GetLuaAnimations()

local function AdvanceFrame(tGestureTable, tFrameData)

	if tGestureTable.TimeScale == 0 then
		local max = #tGestureTable.FrameData
		local offset = tGestureTable.Offset
		local start = tGestureTable.RestartFrame or 1

		offset = Lerp(offset%1, start, max + 1)

		tGestureTable.Frame = math.floor(offset)
		tGestureTable.FrameDelta = offset%1

		return true
	end

	tGestureTable.FrameDelta = tGestureTable.FrameDelta + FrameTime() * tFrameData.FrameRate * tGestureTable.TimeScale

	if tGestureTable.FrameDelta > 1 then
		tGestureTable.Frame = tGestureTable.Frame + 1
		tGestureTable.FrameDelta = math.min(1, tGestureTable.FrameDelta - 1)
		if tGestureTable.Frame > #tGestureTable.FrameData then
			tGestureTable.Frame = math.min(tGestureTable.RestartFrame or 1, #tGestureTable.FrameData)

			return true
		end
	end

	return false
end

local function CosineInterpolation(y1, y2, mu)
	local mu2 = (1 - math.cos(mu * math.pi)) / 2
	return y1 * (1 - mu2) + y2 * mu2
end

local function CubicInterpolation(y0, y1, y2, y3, mu)
	local mu2 = mu * mu
	local a0 = y3 - y2 - y0 + y1
	return a0 * mu * mu2 + (y0 - y1 - a0) * mu2 + (y2 - y0) * mu + y1
end

local EMPTYBONEINFO = {MU = 0, MR = 0, MF = 0, RU = 0, RR = 0, RF = 0}
local function GetFrameBoneInfo(pl, tGestureTable, iFrame, iBoneID)
	local tPrev = tGestureTable.FrameData[iFrame]
	if tPrev then
		return tPrev.BoneInfo[iBoneID] or tPrev.BoneInfo[pl:GetBoneName(iBoneID)] or EMPTYBONEINFO
	end

	return EMPTYBONEINFO
end

local function DoCurrentFrame(tGestureTable, tFrameData, iCurFrame, pl, fAmount, fFrameDelta, fPower, bNoInterp, tBuffer)
	for iBoneID, tBoneInfo in pairs(tFrameData.BoneInfo) do
		if type(iBoneID) ~= "number" then
			iBoneID = pl:LookupBone(iBoneID)
		end
		if not iBoneID then continue end

		if not tBuffer[iBoneID] then tBuffer[iBoneID] = Matrix() end
		local mBoneMatrix = tBuffer[iBoneID]

		local vCurBonePos, aCurBoneAng = mBoneMatrix:GetTranslation(), mBoneMatrix:GetAngles()
		if not tBoneInfo.Callback or not tBoneInfo.Callback(pl, mBoneMatrix, iBoneID, vCurBonePos, aCurBoneAng, fFrameDelta, fPower) then
			local vUp = aCurBoneAng:Up()
			local vRight = aCurBoneAng:Right()
			local vForward = aCurBoneAng:Forward()
			local iInterp = tGestureTable.Interpolation
			if iInterp == INTERP_LINEAR or bNoInterp then
				mBoneMatrix:Translate((tBoneInfo.MU * vUp + tBoneInfo.MR * vRight + tBoneInfo.MF * vForward) * fAmount)
				mBoneMatrix:Rotate(Angle(tBoneInfo.RR, tBoneInfo.RU, tBoneInfo.RF) * fAmount)
			elseif iInterp == INTERP_CUBIC and tGestureTable.FrameData[iCurFrame - 2] and tGestureTable.FrameData[iCurFrame + 1] then
					local bi0 = GetFrameBoneInfo(pl, tGestureTable, iCurFrame - 2, iBoneID)
					local bi1 = GetFrameBoneInfo(pl, tGestureTable, iCurFrame - 1, iBoneID)
					local bi3 = GetFrameBoneInfo(pl, tGestureTable, iCurFrame + 1, iBoneID)
					mBoneMatrix:Translate(CosineInterpolation(bi1.MU * vUp + bi1.MR * vRight + bi1.MF * vForward, tBoneInfo.MU * vUp + tBoneInfo.MR * vRight + tBoneInfo.MF * vForward, fFrameDelta) * fPower)
					mBoneMatrix:Rotate(CubicInterpolation(Angle(bi0.RR, bi0.RU, bi0.RF),
															Angle(bi1.RR, bi1.RU, bi1.RF),
															Angle(tBoneInfo.RR, tBoneInfo.RU, tBoneInfo.RF),
															Angle(bi3.RR, bi3.RU, bi3.RF),
															fFrameDelta) * fPower)
			else -- Default is Cosine
				local bi1 = GetFrameBoneInfo(pl, tGestureTable, iCurFrame - 1, iBoneID)
				mBoneMatrix:Translate(CosineInterpolation(bi1.MU * vUp + bi1.MR * vRight + bi1.MF * vForward, tBoneInfo.MU * vUp + tBoneInfo.MR * vRight + tBoneInfo.MF * vForward, fFrameDelta) * fPower)
				mBoneMatrix:Rotate(CosineInterpolation(Angle(bi1.RR, bi1.RU, bi1.RF), Angle(tBoneInfo.RR, tBoneInfo.RU, tBoneInfo.RF), fFrameDelta) * fPower)
			end
		end
	end
end

local function BuildBonePositions(pl)
	pl:ResetBoneMatrix()

	local tBuffer = {}

	local tLuaAnimations = pl.LuaAnimations
	for sGestureName, tGestureTable in pairs(tLuaAnimations) do
		local iCurFrame = tGestureTable.Frame
		local tFrameData = tGestureTable.FrameData[iCurFrame]
		local fFrameDelta = tGestureTable.FrameDelta
		local fDieTime = tGestureTable.DieTime
		local fPower = tGestureTable.Power
		if fDieTime and fDieTime - ANIMATIONFADEOUTTIME <= CurTime() then
			fPower = fPower * (fDieTime - CurTime()) / ANIMATIONFADEOUTTIME
		end
		local fAmount = fPower * fFrameDelta

		DoCurrentFrame(tGestureTable, tFrameData, iCurFrame, pl, fAmount, fFrameDelta, fPower, tGestureTable.Type == TYPE_POSTURE, tBuffer)
		if tGestureTable.DisplayCallback then
			tGestureTable.DisplayCallback(pl, sGestureName, tGestureTable, iCurFrame, tFrameData, fFrameDelta, fPower)
		end
	end

	for iBoneID, mMatrix in pairs(tBuffer) do
		pac.ManipulateBonePosition(pl, iBoneID, mMatrix:GetTranslation())
		pac.ManipulateBoneAngles(pl, iBoneID, mMatrix:GetAngles())
	end
end

local function ProcessAnimations(pl)
	local tLuaAnimations = pl.LuaAnimations
	for sGestureName, tGestureTable in pairs(tLuaAnimations) do
		local iCurFrame = tGestureTable.Frame
		local tFrameData = tGestureTable.FrameData[iCurFrame]
		local fFrameDelta = tGestureTable.FrameDelta
		local fDieTime = tGestureTable.DieTime
		local fPower = tGestureTable.Power
		if fDieTime and fDieTime - ANIMATIONFADEOUTTIME <= CurTime() then
			fPower = fPower * (fDieTime - CurTime()) / ANIMATIONFADEOUTTIME
		end
		local fAmount = fPower * fFrameDelta

		if fDieTime and fDieTime <= CurTime() then
			pl:StopLuaAnimation(sGestureName)
		elseif not tGestureTable.PreCallback or not tGestureTable.PreCallback(pl, sGestureName, tGestureTable, iCurFrame, tFrameData, fFrameDelta) then
			if tGestureTable.ShouldPlay and not tGestureTable.ShouldPlay(pl, sGestureName, tGestureTable, iCurFrame, tFrameData, fFrameDelta, fPower) then
				pl:StopLuaAnimation(sGestureName, 0.2)
			end

			if tGestureTable.Type == TYPE_GESTURE then
				if AdvanceFrame(tGestureTable, tFrameData) then
					pl:StopLuaAnimation(sGestureName)
				end
			elseif tGestureTable.Type == TYPE_POSTURE then
				if fFrameDelta < 1 and tGestureTable.TimeToArrive then
					fFrameDelta = math.min(1, fFrameDelta + FrameTime() * (1 / tGestureTable.TimeToArrive))
					tGestureTable.FrameDelta = fFrameDelta
				end
			else
				AdvanceFrame(tGestureTable, tFrameData)
			end
		end
	end

	if pl.LuaAnimations then
		BuildBonePositions(pl)
	end
end

hook.Add("Think", "BoneAnimThink", function()
	for _, pl in pairs(player.GetAll()) do
		if pl.LuaAnimations and pl:IsValid() then
			ProcessAnimations(pl)
		end
	end
end)

hook.Add("CalcMainActivity", "LuaAnimationSequence", function(pl)
	if pl.InSequence then
		pl:ResetInSequence()
		return 0, 0
	end
end)

local meta = FindMetaTable("Entity")
if not meta then return end

function meta:ResetBoneMatrix()
	for i=0, self:GetBoneCount() - 1 do
		pac.ManipulateBoneAngles(self, i, angle_zero)
		pac.ManipulateBonePosition(self, i, vector_origin)
	end
end

function meta:ResetLuaAnimation(sAnimation, fDieTime, fPower, fTimeScale)
	local animtable = Animations[sAnimation]
	if animtable then
		self.LuaAnimations = self.LuaAnimations or {}

		local framedelta = 0
		if animtable.Type == TYPE_POSTURE and not animtable.TimeToArrive then
			framedelta = 1
		end

		self.LuaAnimations[sAnimation] = {
			Frame = animtable.StartFrame or 1,
			Offset = 0,
			FrameDelta = framedelta,
			FrameData = animtable.FrameData,
			TimeScale = fTimeScale or animtable.TimeScale or 1,
			Type = animtable.Type,
			RestartFrame = animtable.RestartFrame,
			TimeToArrive = animtable.TimeToArrive,
			Callback = animtable.Callback,
			ShouldPlay = animtable.ShouldPlay,
			PreCallback = animtable.PreCallback,
			Power = fPower or animtable.Power or 1,
			DieTime = fDieTime or animtable.DieTime,
			Group = animtable.Group,
			UseReferencePose = animtable.UseReferencePose
		}

		self:ResetLuaAnimationProperties()
	end
end

function meta:SetLuaAnimation(sAnimation, fDieTime, fPower, fTimeScale)
	if self.LuaAnimations and self.LuaAnimations[sAnimation] then return end

	self:ResetLuaAnimation(sAnimation, fDieTime, fPower, fTimeScale)
end

function meta:SetLuaAnimationPower(sAnimation, fPower)
	if self.LuaAnimations and self.LuaAnimations[sAnimation] then
		self.LuaAnimations[sAnimation].Power = fPower
	end
end

function meta:SetLuaAnimationTimeScale(sAnimation, fTimeScale)
	if self.LuaAnimations and self.LuaAnimations[sAnimation] then
		self.LuaAnimations[sAnimation].TimeScale = fTimeScale
	end
end

function meta:SetLuaAnimationDieTime(sAnimation, fTime)
	if self.LuaAnimations and self.LuaAnimations[sAnimation] then
		if self.LuaAnimations[sAnimation].DieTime then
			self.LuaAnimations[sAnimation].DieTime = math.min(self.LuaAnimations[sAnimation].DieTime, fTime)
		else
			self.LuaAnimations[sAnimation].DieTime = fTime
		end
	end
end

function meta:ResetInSequence()
	local anims = self.LuaAnimations
	if anims then
		for sAnimation, tAnimTab in pairs(anims) do
			if tAnimTab.Type == TYPE_SEQUENCE and (not tAnimTab.DieTime or CurTime() < tAnimTab.DieTime - ANIMATIONFADEOUTTIME) or tAnimTab.UseReferencePose then
				self.InSequence = true
				return
			end
		end

		self.InSequence = nil
	end
end

function meta:ResetLuaAnimationProperties()
	local anims = self.LuaAnimations
	if anims and table.Count(anims) > 0 then
		self:SetIK(false)
		self:ResetInSequence()
	else
		--self:SetIK(true)
		self.LuaAnimations = nil
		self.InSequence = nil
	end
end

-- Time is optional, sets the die time to CurTime() + fTime
function meta:StopLuaAnimation(sAnimation, fTime)
	local anims = self.LuaAnimations
	if anims and anims[sAnimation] then
		if fTime then
			if anims[sAnimation].DieTime then
				anims[sAnimation].DieTime = math.min(anims[sAnimation].DieTime, CurTime() + fTime)
			else
				anims[sAnimation].DieTime = CurTime() + fTime
			end
		else
			anims[sAnimation] = nil
		end

		self:ResetLuaAnimationProperties()
	end
end

function meta:StopLuaAnimationGroup(sGroup, fTime)
	if self.LuaAnimations then
		for animname, animtable in pairs(self.LuaAnimations) do
			if animtable.Group == sGroup then
				self:StopLuaAnimation(animname, fTime)
			end
		end
	end
end

function meta:StopAllLuaAnimations(fTime)
	if self.LuaAnimations then
		for name in pairs(self.LuaAnimations) do
			self:StopLuaAnimation(name, fTime)
		end
	end
end
