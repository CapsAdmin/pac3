local enable = CreateClientConVar("pac_show_profiling_info", 1, true, true)
local font = "pac_render_score"

surface.CreateFont(font, {font = "Arial", shadow = true, size = 14, antialias = false})

pace.RenderTimes = {}

timer.Create("pac_render_times", 0.1, 0, function()
	if not pac.IsEnabled() then return end
			
	for key, ply in pairs(player.GetHumans()) do
		local data = pac.GetProfilingData(ply)
		
		if data then
			local renderTime = 0
			local count = 0
			
			for k,v in pairs(data.events) do 
				renderTime = renderTime + v.average_ms 
				count = count + 1
			end
			
			-- calculate average
			renderTime = renderTime / count
			
			pace.RenderTimes[ply:EntIndex()] = renderTime
		end
	end
end)

hook.Add("HUDPaint", "pac_show_render_times", function()
	if not pace.IsActive() or not pace.IsFocused() or not enable:GetBool() or pace.IsInBasicMode() then return end
			
	for key, ply in pairs(player.GetHumans()) do
		if ply == LocalPlayer() then continue end
	
		local pos = ply:EyePos()
		
		if pos:Distance(pac.EyePos) < 100 then
			local pos = pos:ToScreen()
			
			if pos.visible then

				surface.SetFont(font)
				surface.SetTextColor(255, 255, 255, 255)
				
				local renderTime = pace.RenderTimes[ply:EntIndex()]
				
				surface.SetTextPos(pos.x, pos.y)
				surface.DrawText(string.format("average render time : %.3f ms", renderTime * 1000))				
			end
		end
	end
end)