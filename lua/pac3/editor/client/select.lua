local L = pace.LanguageString

pace.selectControl = {}
local selectControl = pace.selectControl

function selectControl.VecToScreen(vec)
	return vec:ToScreen()
end

function selectControl.GetMousePos()
	return input.GetCursorPos()
end

function selectControl.GUIMousePressed(mcode) end
function selectControl.GUIMouseReleased(mcode) end
function selectControl.HUDPaint() end

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
local x, y = 0, 0
local siz = 5
local sizeSelected = 12
local sizeHovered = 7
local currentSizeSelected = 5

local hR = 83
local hG = 167
local hB = 213

local sR = 148
local sG = 67
local sB = 201

local white = surface.GetTextureID("gui/center_gradient.vtf")

function pace.DrawHUDText(x, y, text, lx, ly, mx, my, selected, line_color)
	mx = mx or gui.MouseX()
	my = my or gui.MouseY()

	local color = selected and Color(128, 255, 128) or color_white

	surface.SetDrawColor(line_color or color)

	pace.util.DrawLine(
		Lerp(0.025, mx, x + lx),
		Lerp(0.025, my, y + ly),

		Lerp(0.05, x + lx, mx),
		Lerp(0.05, y + ly, my),
		selected and 4 or 1
	)

	surface.SetFont(font_name)

	local w, h = surface.GetTextSize(text)
	draw_text(text, color, (x + lx) - w / 2, (y + ly) - h / 2)
end

local function checkVisible(pos)
	return
		x > pos.x - area and x < pos.x + area and
		y > pos.y - area and y < pos.y + area
end

local function DrawSelection(pos, r, g, b, sizeToUse)
	if not pos.visible then return false end
	surface.SetDrawColor(r, g, b, 255)
	surface.DrawOutlinedRect(pos.x - (sizeToUse * 0.5), pos.y - (sizeToUse * 0.5), sizeToUse, sizeToUse)
	surface.SetDrawColor(0, 0, 0, 255)
	surface.DrawOutlinedRect(pos.x - (sizeToUse * 0.5) - 1, pos.y - (sizeToUse * 0.5) - 1, sizeToUse + 2, sizeToUse + 2)

	return checkVisible(pos)
end

function pace.DrawSelection(pos)
	return DrawSelection(pos, 255, 255, 255, siz)
end

function pace.DrawSelectionHovered(pos)
	return DrawSelection(pos, hR, hG, hB, sizeHovered)
end

function pace.DrawSelectionSelected(pos)
	return DrawSelection(pos, sR, sG, sB, sizeSelected + math.sin(RealTime() * 4) * 3)
end

local function get_friendly_name(ent)
	local name = ent.Nick and ent:Nick()
	if not name or name == "" then
		name = language.GetPhrase(ent:GetClass())
	end

	return ent:EntIndex() .. " - " .. name
end

function pace.StopSelect()
	pac.RemoveHook("GUIMouseReleased", "draw_select")
	pac.RemoveHook("GUIMousePressed", "draw_select")
	pac.RemoveHook("HUDPaint", "draw_select")
	function selectControl.GUIMousePressed(mcode) end
	function selectControl.GUIMouseReleased(mcode) end
	function selectControl.HUDPaint() end

	timer.Simple(0.1, function()
		pace.IsSelecting = false
	end)
end

local function select_something(tblin, check, getpos, getfriendly, callback, selectCallback, poll)
	local data
	local selected = {}
	holding = nil

	local function GUIMousePressed(mcode)
		if mcode == MOUSE_LEFT then
			if not selected then
				pace.StopSelect()
			end

			holding = Vector(selectControl.GetMousePos())
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
		if poll and not poll() then pace.StopSelect() return end

		surface.SetAlphaMultiplier(1)

		x, y = selectControl.GetMousePos()

		local tbl = {}

		for key, value in pairs(tblin) do
			if check(key, value) then
				goto CONTINUE
			end

			local pos = selectControl.VecToScreen(getpos(key, value))
			local friendly = getfriendly(key, value)

			if checkVisible(pos) then
				table.insert(tbl, {pos = pos, friendly = friendly, dist = pace.util.FastDistance2D(pos.x, pos.y, x, y), key = key, value = value})
			else
				local hit = false
				if selected then
					for i, val in ipairs(selected) do
						if val.key == key and val.value == value then
							hit = true
							break
						end
					end
				end

				if not hit then
					pace.DrawSelection(pos)
				end
			end
			::CONTINUE::
		end

		if tbl[1] then
			table.sort(tbl, function(a, b) return a.dist < b.dist end)

			if not selected or not holding then
				selected = {}

				local first = tbl[1]

				for i, v in ipairs(tbl) do
					if math.Round(v.dist / 200) == math.Round(first.dist / 200) then
						table.insert(selected, v)
					else
						break
					end
				end

				if #selected < 3 and first.dist < area / 4 then
					selected = {first}
				end
			end
		elseif not holding then
			selected = nil
		end

		if selected then
			if #selected == 1 then
				local v = selected[1]
				pace.DrawSelectionSelected(v.pos)
				pace.DrawHUDText(v.pos.x, v.pos.y, L(v.friendly), 0, -30, v.pos.x, v.pos.y)
				data = v
				if selectCallback then selectCallback(v.key, v.value) end
			else
				table.sort(selected, function(a,b) return L(a.friendly) > L(b.friendly) end)

				local found
				local rad = math.min(#selected * 30, 400)

				for k, v in ipairs(selected) do
					local sx = math.sin((k / #selected) * math.pi * 2) * rad
					local sy = math.cos((k / #selected) * math.pi * 2) * rad

					v.pos = selectControl.VecToScreen(getpos(v.key, v.value))

					if holding and pace.util.FastDistance2D(v.pos.x + sx, v.pos.y + sy, x, y) < area then
						pace.DrawSelectionSelected(v.pos)
						pace.DrawHUDText(v.pos.x, v.pos.y, L(v.friendly), sx, sy, v.pos.x, v.pos.y, true)
						found = v
						if selectCallback then selectCallback(v.key, v.value) end
					else
						pace.DrawSelectionHovered(v.pos)
						pace.DrawHUDText(v.pos.x, v.pos.y, L(v.friendly), sx, sy, v.pos.x, v.pos.y, false, Color(255, 255, 255, 128))
					end
				end

				data = found
			end
		end
	end

	pace.IsSelecting = true

	selectControl.HUDPaint = HUDPaint
	selectControl.GUIMousePressed = GUIMousePressed
	selectControl.GUIMouseReleased = GUIMouseReleased

	pac.AddHook("GUIMousePressed", "draw_select", selectControl.GUIMousePressed)
	pac.AddHook("GUIMouseReleased", "draw_select", selectControl.GUIMouseReleased)
	pac.AddHook("HUDPaint", "draw_select", selectControl.HUDPaint)
end

function pace.SelectBone(ent, callback, only_movable)
	if not ent or not ent:IsValid() then return end
	local tbl = table.Copy(pac.GetModelBones(ent))

	if only_movable then
		local models = ent:GetModel() and util.GetModelMeshes(ent:GetModel())

		if models then
			for k, v in pairs(tbl) do
				if not v.bone then
					tbl[k] = nil
				end
			end
		end

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

		callback,

		function (key, val)
			if val.is_special or val.is_attachment then return end
			ent.pac_bones_select_target = val.i
		end,

		function() return ent:IsValid() end
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
