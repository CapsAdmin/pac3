local PART = {}

PART.ClassName = "woohoo"
-- PART.ClassName = "pixelate"
PART.Group = 'modifiers'
PART.Icon = 'icon16/webcam_delete.png'

pac.StartStorableVars()
	pac.GetSet(PART, "Resolution", 8)
	pac.GetSet(PART, "Size", 1, {editor_sensitivity = 0.25})
	pac.GetSet(PART, "FixedSize", true)
pac.EndStorableVars()

local render_ReadPixel = render.ReadPixel
local surface_SetDrawColor = surface.SetDrawColor
local surface_DrawRect = surface.DrawRect
local render_CapturePixels = render.CapturePixels

local x2, y2
local r,g,b

function PART:SetSize(size)
	self.Size = math.Clamp(size, 1, 32)
end

function PART:SetResolution(num)
	self.Resolution = math.Clamp(num, 8, 128)
end

function PART:OnDraw(owner, pos, ang)
	local spos = pos:ToScreen()
	local size = self.Size

	if self.FixedSize then
		size = size / pos:Distance(pac.EyePos) * 100
	end

	cam.Start2D()

    render_CapturePixels()

    for x = -64 * size, 64 * size, self.Resolution * size do
		for y = -64 * size, 64 * size, self.Resolution * size do
			x2 = spos.x + x
			y2 = spos.y + y

			r, g, b = render_ReadPixel(x2, y2)
			surface_SetDrawColor(r, g, b, 255)
			surface_DrawRect(x2, y2, (self.Resolution * size) + 1, (self.Resolution * size) + 1)
		end
    end

	cam.End2D()
end

pac.RegisterPart(PART)