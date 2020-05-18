local enable = CreateClientConVar("pac_show_profiling_info", 1, true, true)
local font = "pac_render_score"

surface.CreateFont(font, {font = "Arial", shadow = true, size = 14, antialias = false})

pace.RenderTimes = {} -- render times in seconds


function pace.GetProfilingData(ent)
	local profile_data = pac.profile_info[ent]

	if profile_data then
		local out = {events = {}}
		out.times_rendered = profile_data.times_ran


		for type, data in pairs(profile_data.types) do
			out.events[type] = {
				average_ms = data.total_render_time / out.times_rendered,
			}
		end

		return out
	end
end

timer.Create("pac_render_times", 0.1, 0, function()
	if not pac.IsEnabled() then return end

	for key, ply in pairs(player.GetHumans()) do
		local data = pace.GetProfilingData(ply)

		if data then
			local renderTime = 0

			-- events are "opaque" and "translucent"
			-- WE DO NOT CALCULATE AN AVERAGE
			for k,v in pairs(data.events) do
				renderTime = renderTime + v.average_ms * 0.001
			end

			pace.RenderTimes[ply:EntIndex()] = renderTime
		end
	end
end)

pac.AddHook("HUDPaint", "pac_show_render_times", function()
	if not pace.IsActive() or not pace.IsFocused() or not enable:GetBool() or pace.IsInBasicMode() then return end

	for key, ply in pairs(player.GetHumans()) do
		if ply == LocalPlayer() then goto CONTINUE end

		local pos = ply:EyePos()

		if pos:Distance(pac.EyePos) < 100 then
			local pos = pos:ToScreen()

			if pos.visible then

				surface.SetFont(font)
				surface.SetTextColor(255, 255, 255, 255)

				local renderTime = pace.RenderTimes[ply:EntIndex()]

				if renderTime then
					surface.SetTextPos(pos.x, pos.y)
					surface.DrawText(string.format("average render time : %.3f ms", renderTime * 1000))
				end
			end
		end
		::CONTINUE::
	end
end)