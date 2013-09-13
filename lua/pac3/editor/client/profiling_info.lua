
local enable = CreateClientConVar("pac_show_profiling_info", 1, true, true)
local font = "pac_render_times"

surface.CreateFont(font, {font = "Arial", outline = true, size = 14, antialias = false})


hook.Add("HUDPaint", "pac_render_times", function()
	if not pace.IsActive() or not enable:GetBool() or pace.IsInBasicMode() then return end
			
	for key, ply in pairs(player.GetHumans()) do
		local data = pac.GetProfileTimes(ply)
		
		if data then
			
			local x, y
			
			if ply == LocalPlayer() then
				x = pace.Editor:GetPos() + pace.Editor:GetWide() + 5
				y = 5
			else
				local pos = ply:EyePos()
				
				if pos:Distance(pac.EyePos) < 100 then
					local pos = pos:ToScreen()
					
					if pos.visible then
						x = pos.x
						y = pos.y
					end
				end
			end
			
			if x then
				local mat = Matrix()
				
				mat:SetTranslation(Vector(x, y))
				
				cam.PushModelMatrix(mat)
				surface.SetFont(font)
				surface.SetTextColor(255, 255, 255, 255)
				local h = 0
				for event, info in pairs(data.events) do
					
					if info.average_ms < 0.01 then continue end
					
					surface.SetTextPos(0,h)
					surface.DrawText(string.format("%s parts:", event))
					h = h + 15
					surface.SetTextPos(0,h)
					surface.DrawText(string.format("\t\trender time (ms) : %s", math.Round(info.average_ms, 3)))
					h = h + 15
					
					if info.average_garbage > 0 then
						surface.SetTextPos(0,h)
						surface.DrawText(string.format("\t\taverage garbage : %s", string.NiceSize(math.ceil(info.average_garbage))))
						h = h + 15
					end
					
					h = h + 5
				end
				cam.PopModelMatrix()			
			end
		end
	end
end) 