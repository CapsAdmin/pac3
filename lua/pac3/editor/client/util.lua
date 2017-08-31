
pace.util = {}
local Util = pace.util
local surface = surface
local math = math

local white = surface.GetTextureID("gui/center_gradient.vtf")

function Util.DrawLine(x1, y1, x2, y2, w, skip_tex)
	w = w or 1
	if not skip_tex then surface.SetTexture(white) end

	local dx,dy = x1-x2, y1 - y2
	local ang = math.atan2(dx, dy)
	local dst = math.sqrt((dx * dx) + (dy * dy))

	x1 = x1 - dx * 0.5
	y1 = y1 - dy * 0.5

	surface.DrawTexturedRectRotated(x1, y1, w, dst, math.deg(ang))
end

function Util.FastDistance(x1, y1, z1, x2, y2, z2)
	return math.sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2 + (z2 - z1) ^ 2)
end

function Util.FastDistance2D(x1, y1, x2, y2)
	return math.sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2)
end
