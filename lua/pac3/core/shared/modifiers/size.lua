local def = 
{
	run = 500,
	walk = 250,
	step = 18,
	jump = 200,
	
	view = Vector(0,0,64),
	viewducked = Vector(0,0,28),	
	mass = 85,
	
	min = Vector(-16, -16, 0),
	max = Vector(16, 16, 72),
	maxduck = Vector(16, 16, 36),
}

function pac.SetPlayerSize(ply, f)	
	--local TICKRATE = SERVER and 1/FrameTime() or 0
	
	local safe = math.max(f, 0.1)
		
	if ply.SetViewOffset then ply:SetViewOffset(def.view * safe) end
	if ply.SetViewOffsetDucked then ply:SetViewOffsetDucked(def.viewducked * safe) end
	
	if SERVER then		
		if ply.SetStepSize then ply:SetStepSize(def.step * f) end

		ply:SetModelScale(f, 0)
	end
	
	if ply.ResetHull and f == 1 then
		ply:ResetHull()
	else
		
		if ply.SetHull then 
			ply:SetHull(def.min * safe, def.max * safe)
		end
		
		if ply.SetHullDuck then 
			ply:SetHullDuck(def.min * safe, def.maxduck * safe)
		end
	end
	--[[
	
	ply:SetRunSpeed(math.max(def.run * f, TICKRATE/2))
	ply:SetWalkSpeed(math.max(def.walk * f, TICKRATE/4))

	hook.Add("UpdateAnimation", "pac_scale", function(ply, vel, max)
		if ply.pac_player_size and ply.pac_player_size ~= 1 then
			if 
				ply:GetModelScale() ~= ply.pac_player_size or
				ply:GetViewOffset() ~= def.view * ply.pac_player_size or
				ply:GetRunSpeed() ~= math.max(def.run *  ply.pac_player_size, TICKRATE/2) or
				ply:GetWalkSpeed() ~= math.max(def.walk *  ply.pac_player_size, TICKRATE/4)
			then
				pac.SetPlayerSize(ply, ply.pac_player_size)
			end
		
			ply:SetPlaybackRate(1 / ply.pac_player_size)
			return true
		end
	end)
	]]
	
	if SERVER then
		hook.Add("Think", "pac_check_scale", function()
			for key, ply in pairs(player.GetAll()) do 
				local siz = ply.pac_player_size or 1
								
				if siz ~= 1 and (ply:GetModelScale() ~= siz or ply:GetViewOffset() ~= def.view * siz) then
					pac.SetPlayerSize(ply, siz)
				end
			end
		end)
	end
	
	if CLIENT then
		hook.Add("UpdateAnimation", "pac_check_scale", function(ply)
			local ply = pac.LocalPlayer
			local siz = ply.pac_player_size or 1
		
			if siz ~= 1 and (ply:GetModelScale() ~= siz or ply:GetViewOffset() ~= def.view * siz) then
				pac.SetPlayerSize(ply, ply.pac_player_size)
			end	
			
			if siz ~= 1 then
				ply:SetPlaybackRate(1/siz)
				return true
			end
		end)
	end
	
	ply.pac_player_size = f
end

pac.AddServerModifier("size", function(data, owner)
	if data and tonumber(data.self.OwnerName) then
		 local ent = Entity(tonumber(data.self.OwnerName))
		 if ent:IsValid() then
			owner = ent
		 end
	end
 
	if not data then
		pac.SetPlayerSize(owner, 1)
	else
		local offset = 1

		if owner.GetInfoNum then
			offset = owner:GetInfoNum("pac_modifier_size", 0)
		end
		
		if offset > 1 then
			offset = offset - 1
			pac.SetPlayerSize(owner, offset)
		elseif offset == 1 then
			local size
			
			for key, part in pairs(data.children) do
				if 
					part.self.ClassName == "entity" and
					part.self.Size and 
					part.self.Size ~= 1
				then
					size = part.self.Size
				end
			end	
			
			if size then
				pac.SetPlayerSize(owner, size)
			end
		end
	end
end)