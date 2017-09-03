if CLIENT then return end

include("pac3/core/shared/boneanimlib.lua")

util.AddNetworkString("bal_reset")
util.AddNetworkString("bal_set")
util.AddNetworkString("bal_stop")
util.AddNetworkString("bal_stopgroup")
util.AddNetworkString("bal_stopall")

-- These are unreliable. All Lua animations should be set on both the client and server (predicted).
local meta = FindMetaTable("Entity")
if not meta then return end

function meta:ResetLuaAnimation(sAnimation, fTime, fPower, fTimeScale)
	--[[umsg.Start("resetluaanim")
		umsg.Entity(self)
		umsg.String(sAnimation)
		umsg.Float(fTime or -1)
		umsg.Float(fPower or -1)
		umsg.Float(fTimeScale or -1)
	umsg.End()]]
	net.Start("bal_reset")
		net.WriteEntity(self)
		net.WriteString(sAnimation)
		net.WriteFloat(fTime or -1)
		net.WriteFloat(fPower or -1)
		net.WriteFloat(fTimeScale or -1)
	net.Broadcast()
end

function meta:SetLuaAnimation(sAnimation, fTime, fPower, fTimeScale)
	--[[umsg.Start("setluaanim")
		umsg.Entity(self)
		umsg.String(sAnimation)
		umsg.Float(fTime or -1)
		umsg.Float(fPower or -1)
		umsg.Float(fTimeScale or -1)
	umsg.End()]]
	net.Start("bal_set")
		net.WriteEntity(self)
		net.WriteString(sAnimation)
		net.WriteFloat(fTime or -1)
		net.WriteFloat(fPower or -1)
		net.WriteFloat(fTimeScale or -1)
	net.Broadcast()
end

function meta:StopLuaAnimation(sAnimation, fTime)
	--[[umsg.Start("stopluaanim")
		umsg.Entity(self)
		umsg.String(sAnimation)
		umsg.Float(fTime or 0)
	umsg.End()]]
	net.Start("bal_stop")
		net.WriteEntity(self)
		net.WriteString(sAnimation)
		net.WriteFloat(fTime or 0)
	net.Broadcast()
end

function meta:StopLuaAnimationGroup(sAnimation, fTime)
	--[[umsg.Start("stopluaanimgp")
		umsg.Entity(self)
		umsg.String(sAnimation)
		umsg.Float(fTime or 0)
	umsg.End()]]
	net.Start("bal_stopgroup")
		net.WriteEntity(self)
		net.WriteString(sAnimation)
		net.WriteFloat(fTime or 0)
	net.Broadcast()
end

function meta:StopAllLuaAnimations(fTime)
	--[[umsg.Start("stopallluaanim")
		umsg.Entity(self)
		umsg.Float(fTime or 0)
	umsg.End()]]
	net.Start("bal_stopall")
		net.WriteEntity(self)
		net.WriteFloat(fTime or 0)
	net.Broadcast()
end
