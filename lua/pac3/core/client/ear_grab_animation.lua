-- see https://github.com/Facepunch/garrysmod/blob/master/garrysmod/gamemodes/base/gamemode/animations.lua#L235
hook.Add("PostGamemodeLoaded", "pac_ear_grab_animation",function()
	if GAMEMODE.GrabEarAnimation then -- only add it if it exists
		local original_ear_grab_animation = GAMEMODE.GrabEarAnimation
		GAMEMODE.GrabEarAnimation = function(_, ply)
			if ( ply.pac_disable_ear_grab ) then return end
			return original_ear_grab_animation(_, ply)
		end
	end
end)
