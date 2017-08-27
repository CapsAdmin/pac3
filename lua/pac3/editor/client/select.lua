local L = pace.LanguageString

local RENDER_ATTACHMENTS = CreateConVar('pac_render_attachments', '0', {FCVAR_ARCHIVE}, 'Render attachments when selecting bones')

function pace.ToggleRenderAttachments()
	RunConsoleCommand('pac_render_attachments', RENDER_ATTACHMENTS:GetBool() and '0' or '1')
end

local font_name = "pac_select"
local font_scale = 0.05

surface.CreateFont(
	font_name,
	{
		font 		= "DejaVu Sans",
		size 		= 500 * font_scale,
		weight 		= 800,
		antialias 	= true,
		additive 	= true,
	}
)

local font_name_blur = font_name.."_blur"

surface.CreateFont(
	font_name_blur,
	{
		font 		= "DejaVu Sans",
		size 		= 500 * font_scale,
		weight 		= 800,
		antialias 	= true,
		additive 	= false,
		blursize 	= 3,
	}
)


local function draw_text(text, color, x, y)
	surface.SetFont(font_name_blur)
	surface.SetTextColor(color_black)

	for i=1, 10 do
		surface.SetTextPos(x,y)
		surface.DrawText(text)
	end

	surface.SetFont(font_name)
	surface.SetTextColor(color)
	surface.SetTextPos(x,y)
	surface.DrawText(text)
end

local holding
local area = 20
local x,y = 0,0
local siz = 5

local white = surface.GetTextureID("gui/center_gradient.vtf")

local function DrawLineEx(x1,y1, x2,y2, w, skip_tex)
	w = w or 1
	if not skip_tex then surface.SetTexture(white) end

	local dx,dy = x1-x2, y1-y2
	local ang = math.atan2(dx, dy)
	local dst = math.sqrt((dx * dx) + (dy * dy))

	x1 = x1 - dx * 0.5
	y1 = y1 - dy * 0.5

	surface.DrawTexturedRectRotated(x1, y1, w, dst, math.deg(ang))
end

function pace.DrawHUDText(x,y, text, lx,ly, mx,my, selected, line_color)
	mx = mx or gui.MouseX()
	my = my or gui.MouseY()

	local color = selected and Color(128, 255, 128) or color_white

	surface.SetDrawColor(line_color or color)

	DrawLineEx(
		Lerp(0.025, mx, x+lx),
		Lerp(0.025, my, y+ly),

		Lerp(0.05, x+lx, mx),
		Lerp(0.05, y+ly, my),
		selected and 4 or 1
	)

	surface.SetFont(font_name)

	local w, h = surface.GetTextSize(text)
	draw_text(text, color, (x+lx)-w/2,(y+ly)-h/2)
end


function pace.DrawSelection(pos)
	if pos.visible then
		surface.SetDrawColor(255, 255, 255, 255)
		surface.DrawOutlinedRect(pos.x-(siz*0.5), pos.y-(siz*0.5), siz, siz)
		surface.SetDrawColor(0, 0, 0, 255)
		surface.DrawOutlinedRect(pos.x-(siz*0.5)-1, pos.y-(siz*0.5)-1, siz+2, siz+2)

		return
			x > pos.x - area and x < pos.x + area and
			y > pos.y - area and y < pos.y + area
	end
end


local function get_friendly_name(ent)
	local name = ent.Nick and ent:Nick()
	if not name or name == "" then
		name = language.GetPhrase(ent:GetClass())
	end

	return ent:EntIndex() .. " - " .. name
end

local R = function(event, name) if hook.GetTable()[event] and hook.GetTable()[event][name] then hook.Remove(event, name) end end
function pace.StopSelect()
	R("GUIMouseReleased", "pac_draw_select")
	R("GUIMousePressed", "pac_draw_select")
	R("HUDPaint", "pac_draw_select")

	timer.Simple(0.1, function()
		pace.IsSelecting = false
	end)
end

local function select_something(tblin, check, getpos, getfriendly, callback)
	local data
	local selected = {}
	holding = nil

	local function GUIMousePressed(mcode)
		if mcode == MOUSE_LEFT then
			if not selected then
				pace.StopSelect()
			end

			holding = Vector(gui.MousePos())
		end
	end

	local function GUIMouseReleased(mcode)
		if mcode == MOUSE_LEFT then
			if data then
				data.dist = nil
				callback(data)
				pace.StopSelect()
			end
		end
	end

	local function HUDPaint()

		surface.SetAlphaMultiplier(1)

		x,y = gui.MousePos()

		local tbl = {}

		for key, value in pairs(tblin) do
			if check(key, value) then
				continue
			end

			local pos = getpos(key, value):ToScreen()
			local friendly = getfriendly(key, value)

			if pace.DrawSelection(pos) then
				table.insert(tbl, {pos = pos, friendly = friendly, dist = Vector(pos.x, pos.y, 0):Distance(Vector(x, y, 0)), key = key, value = value})
			end
		end


		if tbl[1] then
			table.sort(tbl, function(a, b) return a.dist < b.dist end)

			if not selected or not holding then
				selected = {}

				local first = tbl[1]

				for i,v in pairs(tbl) do
					if math.Round(v.dist/200) == math.Round(first.dist/200) then
						table.insert(selected, v)
					else
						break
					end
				end

				if #selected < 3 and first.dist < area/4 then
					selected = {first}
				end
			end
		elseif not holding then
			selected = nil
		end

		if selected then
			if #selected == 1 then
				local v = selected[1]
				pace.DrawHUDText(v.pos.x, v.pos.y, L(v.friendly), 0, -30, v.pos.x, v.pos.y)
				data = v
			else
				table.sort(selected, function(a,b) return L(a.friendly) > L(b.friendly) end)

				local found
				local rad = math.min(#selected * 30, 400)

				for k,v in pairs(selected) do
					local sx = math.sin((k/#selected) * math.pi * 2) * rad
					local sy = math.cos((k/#selected) * math.pi * 2) * rad

					v.pos = getpos(v.key, v.value):ToScreen()

					if holding and Vector(v.pos.x+sx,v.pos.y+sy,0):Distance(Vector(x,y,0)) < area then
						pace.DrawHUDText(v.pos.x, v.pos.y, L(v.friendly), sx, sy, v.pos.x, v.pos.y, true)
						found = v
					else
						pace.DrawHUDText(v.pos.x, v.pos.y, L(v.friendly), sx, sy, v.pos.x, v.pos.y, false, Color(255, 255, 255, 128))
					end
				end

				data = found
			end
		end
	end

	pace.IsSelecting = true

	hook.Add("GUIMousePressed", "pac_draw_select", GUIMousePressed)
	hook.Add("GUIMouseReleased", "pac_draw_select", GUIMouseReleased)
	hook.Add("HUDPaint", "pac_draw_select", HUDPaint)
end

function pace.SelectBone(ent, callback, only_movable)
	local tbl = table.Copy(pac.GetModelBones(ent))

	if only_movable then
		for k, v in pairs(tbl) do
			if v.is_special or not RENDER_ATTACHMENTS:GetBool() and v.is_attachment then
				tbl[k] = nil
			end
		end
	end

	select_something(
		tbl,

		function() end,

		function(k, v)
			return pac.GetBonePosAng(ent, k)
		end,

		function(k, v)
			return k
		end,

		callback
	)
end

function pace.SelectPart(parts, callback)
	select_something(
		parts,

		function(_, part)
			return part:IsHidden()
		end,

		function(_, part)
			return part:GetDrawPosition()
		end,

		function(_, part)
			return part:GetName()
		end,

		function(data) return callback(data.value) end
	)
end

function pace.SelectEntity(callback)
	select_something(
		ents.GetAll(),

		function(_, ent)
			return
				not ent:IsValid() or
				ent:EntIndex() == -1
		end,

		function(_, ent)
			return ent:EyePos()
		end,

		function(_, ent)
			return get_friendly_name(ent)
		end,

		function(data) return callback(data.value) end
	)
end