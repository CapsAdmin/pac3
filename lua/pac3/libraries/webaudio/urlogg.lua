-- made by Morten and CapsAdmin

pac.webaudio = pac.webaudio or {}
local webaudio = pac.webaudio

webaudio.Debug        = 0

webaudio.SampleRate   = nil

webaudio.SpeedOfSound = 340.29 -- metres per second

function webaudio.DebugPrint(str, ...)
	if webaudio.Debug == 0 then return end

    if webaudio.Debug >= 1 then
        if epoe then
			-- Why is this even present here?
            epoe.MsgC(Color(0, 255, 0), "[WebAudio] ")
            epoe.MsgC(Color(255, 255, 255), str)
            epoe.Print("")
		end

        pac.Message(Color(0, 255, 0), "[WebAudio] ", Color(255, 255, 255), str, ...)
    end

    if webaudio.Debug >= 2 then
		if easylua then
			easylua.PrintOnServer("[WebAudio] " .. str .. ' ' .. table.concat({...}, ', '))
		end
    end
end

function webaudio.GetSampleRate ()
	return webaudio.SampleRate
end

local volume             = GetConVar("volume")
local snd_mute_losefocus = GetConVar("snd_mute_losefocus")

pac.AddHook("Think", "webaudio", function()
	if not webaudio.Browser.IsInitialized () then
		if not webaudio.Browser.IsInitializing () then
			webaudio.Browser.Initialize ()
		end
		return
	end

	-- Update volume
	if not system.HasFocus() and snd_mute_losefocus:GetBool() then
		-- Garry's Mod not in foreground and we're not supposed to be making any sound
		webaudio.Browser.SetVolume(0)
	else
		webaudio.Browser.SetVolume(volume:GetFloat())
	end

	webaudio.Streams.Think()
	webaudio.Browser.Think()
end)
