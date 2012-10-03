local PART = {}

PART.ClassName = "\231\166\129"

pac.StartStorableVars()
	pac.GetSet(PART, "Amount", 8)
	pac.GetSet(PART, "Size", 10)
pac.EndStorableVars()

local render_ReadPixel = render.ReadPixel
local surface_SetDrawColor = surface.SetDrawColor
local surface_DrawRect = surface.DrawRect
local render_CapturePixels = render.CapturePixels

local x2, y2
local r,g,b

function PART:SetAmount(num)
	self.Amount = math.Clamp(num, 4, 16)
end	

function PART:OnDraw(owner, pos, ang)
	local size = (self.Size / pos:Distance(pac.EyePos)) * 100
	local spos = pos:ToScreen()		
	
	cam.Start2D()
    
    render_CapturePixels()
	
    for x = 1, self.Amount do
		x = x * size
		for y = 1, self.Amount do
			y = y * size
			
			x2 = spos.x + x - (size * self.Amount / 2) 
			y2 = spos.y + y - (size * self.Amount / 2)
			
			r, g, b = render_ReadPixel(x2, y2)
			surface_SetDrawColor(r, g, b, 255)
			surface_DrawRect(x2-1, y2-1, size+1, size+1)
		end
    end
	
	cam.End2D()
end

pac.RegisterPart(PART)