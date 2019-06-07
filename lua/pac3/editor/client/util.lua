pace.util = {}

local surface = surface
local math = math

local white = surface.GetTextureID("gui/center_gradient.vtf")

function pace.util.DrawLine(x1, y1, x2, y2, w, skip_tex)
	w = w or 1
	if not skip_tex then surface.SetTexture(white) end

	local dx,dy = x1-x2, y1 - y2
	local ang = math.atan2(dx, dy)
	local dst = math.sqrt((dx * dx) + (dy * dy))

	x1 = x1 - dx * 0.5
	y1 = y1 - dy * 0.5

	surface.DrawTexturedRectRotated(x1, y1, w, dst, math.deg(ang))
end

function pace.util.FastDistance(x1, y1, z1, x2, y2, z2)
	return math.sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2 + (z2 - z1) ^ 2)
end

function pace.util.FastDistance2D(x1, y1, x2, y2)
	return math.sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2)
end

local function isUpperCase(charIn)
	return
		charIn == 'A' or
		charIn == 'B' or
		charIn == 'C' or
		charIn == 'D' or
		charIn == 'E' or
		charIn == 'F' or
		charIn == 'G' or
		charIn == 'H' or
		charIn == 'I' or
		charIn == 'J' or
		charIn == 'K' or
		charIn == 'L' or
		charIn == 'M' or
		charIn == 'N' or
		charIn == 'O' or
		charIn == 'P' or
		charIn == 'Q' or
		charIn == 'R' or
		charIn == 'S' or
		charIn == 'T' or
		charIn == 'U' or
		charIn == 'V' or
		charIn == 'W' or
		charIn == 'X' or
		charIn == 'Y' or
		charIn == 'Z'
end

function pace.util.FriendlyName(strIn)
	local prevChar
	local outputTab = {}
	local iterableArray = string.Explode('', strIn)

	for i, charIn in ipairs(iterableArray) do
		if not prevChar and not isUpperCase(charIn) or prevChar == ' ' and not isUpperCase(charIn) then
			prevChar = string.upper(charIn)
			table.insert(outputTab, prevChar)
		elseif charIn == '_' then
			iterableArray[i] = ' '
			prevChar = ' '
			table.insert(outputTab, ' ')
		elseif isUpperCase(charIn) then
			if prevChar == '_' and (not iterableArray[i + 1] or isUpperCase(iterableArray[i + 1])) then
				if charIn == 'L' then
					prevChar = ' '
					table.insert(outputTab, 'Left ')
				elseif charIn == 'R' then
					prevChar = ' '
					table.insert(outputTab, 'Right ')
				-- elseif charIn == 'O' then
				--	prevChar = ' '
				-- 	table.insert(outputTab, 'Open ') -- i guess?
				else
					prevChar = charIn
					table.insert(outputTab, charIn)
				end
			elseif not isUpperCase(prevChar) then
				prevChar = charIn
				table.insert(outputTab, ' ')
				table.insert(outputTab, charIn)
			else
				prevChar = charIn
				table.insert(outputTab, charIn)
			end
		else
			local condUpper =
				charIn == 'm' and iterableArray[i + 1] == 'p' and iterableArray[i - 1] == ' ' or
				charIn == 'p' and iterableArray[i - 1] == 'm' and iterableArray[i - 2] == ' ' or
				charIn == 'w' and (iterableArray[i - 1] == 'C' or iterableArray[i - 1] == 'c') or
				charIn == 'c' and iterableArray[i + 1] == 'w' or
				charIn == 'i' and (iterableArray[i - 1] == 'C' or iterableArray[i - 1] == 'c') or
				charIn == 'c' and iterableArray[i + 1] == 'i' or
				(charIn == 'x' or charIn == 'y' or charIn == 'z') and not iterableArray[i + 1] and iterableArray[i - 1] == ' '

			if condUpper then
				prevChar = string.upper(charIn)
				table.insert(outputTab, prevChar)
			else
				prevChar = charIn
				table.insert(outputTab, charIn)
			end
		end
	end

	return table.concat(outputTab, '')
end
