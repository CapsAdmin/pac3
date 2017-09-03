--[[

Bone Animations Library
Created by William "JetBoom" Moodhe (williammoodhe@gmail.com / www.noxiousnet.com)
Because I wanted custom, dynamic animations.
Give credit or reference if used in your creations.

]]
local _G = _G

module("boneanimlib",package.seeall)
TYPE_GESTURE = 0 -- Gestures are keyframed animations that use the current position and angles of the bones. They play once and then stop automatically.
TYPE_POSTURE = 1 -- Postures are static animations that use the current position and angles of the bones. They stay that way until manually stopped. Use TimeToArrive if you want to have a posture lerp.
TYPE_STANCE = 2 -- Stances are keyframed animations that use the current position and angles of the bones. They play forever until manually stopped. Use RestartFrame to specify a frame to go to if the animation ends (instead of frame 1).
TYPE_SEQUENCE = 3 -- Sequences are keyframed animations that use the reference pose. They play forever until manually stopped. Use RestartFrame to specify a frame to go to if the animation ends (instead of frame 1).
-- You can also use StartFrame to specify a starting frame for the first loop.

INTERP_LINEAR = 0 -- Straight linear interp.
INTERP_COSINE = 1 -- Best compatability / quality balance.
INTERP_CUBIC = 2 -- Overall best quality blending but may cause animation frames to go 'over the top'.
INTERP_DEFAULT = INTERP_COSINE

local Animations = {}

function GetLuaAnimations()
	return Animations
end

function RegisterLuaAnimation(sName, tInfo)
	if tInfo and tInfo.FrameData then
		local BonesUsed = {}
		for iFrame, tFrame in ipairs(tInfo.FrameData) do
			for iBoneID, tBoneTable in pairs(tFrame.BoneInfo) do
				BonesUsed[iBoneID] = (BonesUsed[iBoneID] or 0) + 1
				tBoneTable.MU = tBoneTable.MU or 0
				tBoneTable.MF = tBoneTable.MF or 0
				tBoneTable.MR = tBoneTable.MR or 0
				tBoneTable.RU = tBoneTable.RU or 0
				tBoneTable.RF = tBoneTable.RF or 0
				tBoneTable.RR = tBoneTable.RR or 0
			end
		end

		if #tInfo.FrameData > 1 then
			for iBoneUsed, iTimesUsed in pairs(BonesUsed) do
				for iFrame, tFrame in ipairs(tInfo.FrameData) do
					if not tFrame.BoneInfo[iBoneUsed] then
						tFrame.BoneInfo[iBoneUsed] = {MU = 0, MF = 0, MR = 0, RU = 0, RF = 0, RR = 0}
					end
				end
			end
		end
	end
	Animations[sName] = tInfo
end

-----------------------------
-- Deserialize / Serialize --
-----------------------------

function Deserialize(str)
	error"unsafe"
end


_G.GetLuaAnimations=GetLuaAnimations
_G.RegisterLuaAnimation=RegisterLuaAnimation

local allowedtypes = {}
allowedtypes["string"] = true
allowedtypes["number"] = true
allowedtypes["table"] = true
allowedtypes["Vector"] = true
allowedtypes["Angle"] = true
allowedtypes["boolean"] = true
local function MakeTable(tab, done)
	local str = ""
	local done = done or {}

	local sequential = table.IsSequential(tab)

	for key, value in pairs(tab) do
		local keytype = type(key)
		local valuetype = type(value)

		if allowedtypes[keytype] and allowedtypes[valuetype] then
			if sequential then
				key = ""
			else
				if keytype == "number" or keytype == "boolean" then
					key ="["..tostring(key).."]="
				else
					key = "["..string.format("%q", tostring(key)).."]="
				end
			end

			if valuetype == "table" and not done[value] then
				done[value] = true
				if type(value._serialize) == "function" then
					str = str..key..value:_serialize()..","
				else
					str = str..key.."{"..MakeTable(value, done).."},"
				end
			else
				if valuetype == "string" then
					value = string.format("%q", value)
				elseif valuetype == "Vector" then
					value = "Vector("..value.x..","..value.y..","..value.z..")"
				elseif valuetype == "Angle" then
					value = "Angle("..value.pitch..","..value.yaw..","..value.roll..")"
				else
					value = tostring(value)
				end

				str = str .. key .. value .. ","
			end
		end
	end

	if string.sub(str, -1) == "," then
		return string.sub(str, 1, #str - 1)
	else
		return str
	end
end

function Serialize(tIn, bRaw)
	if bRaw then
		return "{"..MakeTable(tIn).."}"
	end

	return "SRL={"..MakeTable(tIn).."}"
end

---------------------------------
-- End Deserialize / Serialize --
---------------------------------

-- If your animation is only used on one model, use numbers instead of bone names (cache the lookup).
-- If it's being used on a wide array of models (including default player models) then you should use bone names.
-- You can use Callback as a function instead of MU, RR, etc. which will allow you to do some interesting things.
-- See cl_boneanimlib.lua for the full format.

-- STANCE: stancetest
-- A simple looping stance that stretches the model's spine up and down until stopped.

RegisterLuaAnimation("stancetest", {
	FrameData = {
		{
			BoneInfo = {
				["ValveBiped.Bip01_Spine"] = {
					MU = 64
				}
			},
			FrameRate = 0.25
		},
		{
			BoneInfo = {
				["ValveBiped.Bip01_Spine"] = {
					MU = -32
				}
			},
			FrameRate = 1.5
		},
		{
			BoneInfo = {
				["ValveBiped.Bip01_Spine"] = {
					MU = 32
				}
			},
			FrameRate = 4
		}
	},
	RestartFrame = 2,
	Type = TYPE_STANCE
})

--[[
STANCE: staffholdspell
To be used with the ACT_HL2MP_IDLE_MELEE2 animation.
Player holds the staff so that their left hand is over the top of it.
]]

RegisterLuaAnimation("staffholdspell", {
	FrameData = {
		{
			BoneInfo = {
				["ValveBiped.Bip01_R_Forearm"] = {
					RU = 40,
					RF = -40
				},
				["ValveBiped.Bip01_R_Upperarm"] = {
					RU = 40
				},
				["ValveBiped.Bip01_R_Hand"] = {
					RU = -40
				},
				["ValveBiped.Bip01_L_Forearm"] = {
					RU = 40
				},
				["ValveBiped.Bip01_L_Hand"] = {
					RU = -40
				}
			},
			FrameRate = 6
		},
		{
			BoneInfo = {
				["ValveBiped.Bip01_R_Forearm"] = {
					RU = 2,
				},
				["ValveBiped.Bip01_R_Upperarm"] = {
					RU = 1
				},
				["ValveBiped.Bip01_R_Hand"] = {
					RU = -10
				},
				["ValveBiped.Bip01_L_Forearm"] = {
					RU = 8
				},
				["ValveBiped.Bip01_L_Hand"] = {
					RU = -12
				}
			},
			FrameRate = 0.4
		},
		{
			BoneInfo = {
				["ValveBiped.Bip01_R_Forearm"] = {
					RU = -2,
				},
				["ValveBiped.Bip01_R_Upperarm"] = {
					RU = -1
				},
				["ValveBiped.Bip01_R_Hand"] = {
					RU = 10
				},
				["ValveBiped.Bip01_L_Forearm"] = {
					RU = -8
				},
				["ValveBiped.Bip01_L_Hand"] = {
					RU = 12
				}
			},
			FrameRate = 0.1
		}
	},
	RestartFrame = 2,
	Type = TYPE_STANCE,
	ShouldPlay = function(pl, sGestureName, tGestureTable, iCurFrame, tFrameData)
		local wepstatus = pl.WeaponStatus
		return wepstatus and wepstatus:IsValid() and wepstatus:GetSkin() == 1 and wepstatus.IsStaff
	end
})
