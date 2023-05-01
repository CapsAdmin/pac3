-- see https://github.com/Facepunch/garrysmod/blob/master/garrysmod/gamemodes/base/gamemode/animations.lua#L235
hook.Add("PostGamemodeLoaded", "pac_ear_grab_animation",function()
	if GAMEMODE.GrabEarAnimation then -- only add it if it exists
		GAMEMODE.GrabEarAnimation = function(_, ply)
			ply.ChatGestureWeight = ply.ChatGestureWeight || 0
			if ( ply.pac_disable_ear_grab ) then return end

			-- Don't show this when we're playing a taunt!
			if ( ply:IsPlayingTaunt() ) then return end

			if ( ply:IsTyping() ) then
				ply.ChatGestureWeight = math.Approach( ply.ChatGestureWeight, 1, FrameTime() * 5.0 )
			else
				ply.ChatGestureWeight = math.Approach( ply.ChatGestureWeight, 0, FrameTime() * 5.0 )
			end

			if ( ply.ChatGestureWeight > 0 ) then

				ply:AnimRestartGesture( GESTURE_SLOT_VCD, ACT_GMOD_IN_CHAT, true )
				ply:AnimSetGestureWeight( GESTURE_SLOT_VCD, ply.ChatGestureWeight )

			end
		end
	end
end)
