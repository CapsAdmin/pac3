local SysTime = SysTime
local pairs = pairs
local Color = Color
local tostring = tostring
local cam_Start2D = cam.Start2D
local cam_IgnoreZ = cam.IgnoreZ
local Vector = Vector
local math_Clamp = math.Clamp
local EyePos = EyePos
local surface_SetFont = surface.SetFont
local surface_GetTextSize = surface.GetTextSize
local draw_DrawText = draw.DrawText
local string_format = string.format
local input_GetCursorPos = input.GetCursorPos
local vgui_CursorVisible = vgui.CursorVisible
local ScrW = ScrW
local ScrH = ScrH
local input_LookupBinding = input.LookupBinding
local LocalPlayer = LocalPlayer
local input_IsMouseDown = input.IsMouseDown
local cam_End2D = cam.End2D

local max_render_time_cvar = CreateClientConVar("pac_max_render_time", 0)

function pac.IsRenderTimeExceeded(ent)
	return ent.pac_render_time_exceeded
end

function pac.ResetRenderTime(ent)
	ent.pac_rendertime = ent.pac_rendertime or {}

	for key in pairs(ent.pac_rendertime) do
		ent.pac_rendertime[key] = 0
	end
end

function pac.RecordRenderTime(ent, type, start)
	ent.pac_rendertime = ent.pac_rendertime or {}
	ent.pac_rendertime[type] = (ent.pac_rendertime[type] or 0) + (SysTime() - start)

	local max_render_time = max_render_time_cvar:GetFloat()

	if max_render_time > 0 then
		local total_time = 0

		for k,v in pairs(ent.pac_rendertime) do
			total_time = total_time + v
		end

		total_time = total_time * 1000

		if total_time > max_render_time then
			pac.Message(Color(255, 50, 50), tostring(ent) .. ": max render time exceeded!")
			ent.pac_render_time_exceeded = total_time
			pac.HideEntityParts(ent)
		end
	end
end

function pac.DrawRenderTimeExceeded(ent)
	cam_Start2D()
	cam_IgnoreZ(true)
		local pos_3d = ent:NearestPoint(ent:EyePos() + ent:GetUp()) + Vector(0,0,5)
		local alpha = math_Clamp(pos_3d:Distance(EyePos()) * -1 + 500, 0, 500) / 500
		if alpha > 0 then
			local pos_2d = pos_3d:ToScreen()
			surface_SetFont("ChatFont")
			local _, h = surface_GetTextSize("|")

			draw_DrawText(
				string_format(
					"pac3 outfit took %.2f/%i ms to render",
					ent.pac_render_time_exceeded,
					max_render_time_cvar:GetFloat()
				),
				"ChatFont",
				pos_2d.x,
				pos_2d.y,
				Color(255,255,255,alpha * 255),
				1
			)
			local x, y = pos_2d.x, pos_2d.y + h

			local mx, my = input_GetCursorPos()
			if not vgui_CursorVisible() then
				mx = ScrW() / 2
				my = ScrH() / 2
			end
			local dist = 200
			local hovering = mx > x - dist and mx < x + dist and my > y - dist and my < y + dist

			local button = vgui_CursorVisible() and "click" or ("press " .. input_LookupBinding("+use"))
			draw_DrawText(button .. " here to try again", "ChatFont", x, y, Color(255,255,255,alpha * (hovering and 255 or 100) ), 1)

			if hovering and LocalPlayer():KeyDown(IN_USE) or (vgui_CursorVisible() and input_IsMouseDown(MOUSE_LEFT)) then
				ent.pac_render_time_exceeded = nil
			end
		end

	cam_IgnoreZ(false)
	cam_End2D()
end