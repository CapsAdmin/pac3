local L = pace.LanguageString

function pace.DrawHUDText(x, y, text)
	surface.SetDrawColor(255, 255, 255, 255)
	surface.DrawLine(
		Lerp(0.2, gui.MouseX(), x),
		Lerp(0.2, gui.MouseY(), y),

		Lerp(0.05, x, gui.MouseX()),
		Lerp(0.05, y, gui.MouseY())
	)
	
	surface.SetFont("DermaDefault")

	surface.SetTextColor(255, 255, 255, 255)
	local w, h = surface.GetTextSize(text)
	surface.SetTextPos(x - (w * 0.5), y - h)
	surface.DrawText(text)
end

local area = 20
local x,y = 0,0
local siz = 5

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
	local name = ent.GetName and ent:GetName()
	if not name or name == "" then
		name = ent:GetClass()
	end

	return ent:EntIndex() .. " - " .. name
end

local R = function(event, name) if hook.GetTable()[event] and hook.GetTable()[event][name] then hook.Remove(event, name) end end
function pace.StopSelect()
	R("GUIMousePressed", "pac_draw_select")
	R("HUDPaint", "pac_draw_select")
	R("HUDPaint", "pac_highlight")
	
	timer.Simple(0.1, function()
		pace.IsSelecting = false
	end)
end

function pace.SelectBone(ent, callback)
	local data
	local bones = pac.GetModelBones(ent)
	
	if not bones then return end

	local function GUIMousePressed(mcode)
		if mcode == MOUSE_LEFT and data then
			data.dist = nil
			callback(data)
			pace.StopSelect()
		end
	end

	local function HUDPaint()
		x,y = gui.MousePos()
		local tbl = {}

		for friendly, data in pairs(bones) do
			local pos = pac.GetBonePosAng(ent, friendly):ToScreen()
			if pace.DrawSelection(pos) then
				table.insert(tbl, {pos = pos, real = data.real, friendly = friendly, dist = Vector(pos.x, pos.y, 0):Distance(Vector(x, y, 0))})
			end
		end


		if tbl[1] then
			table.sort(tbl, function(a, b) return a.dist < b.dist end)
			data = tbl[1]
			pace.DrawHUDText(data.pos.x, data.pos.y, L(data.friendly))
		else
			data = nil
		end
	end
	
	pace.IsSelecting = true
	
	hook.Add("GUIMousePressed", "pac_draw_select", GUIMousePressed)
	hook.Add("HUDPaint", "pac_draw_select", HUDPaint)
end

function pace.SelectPart(parts, callback)
	local data

	local function GUIMousePressed(mcode)
		if mcode == MOUSE_LEFT and data then
			callback(data.part)
			pace.StopSelect()
		end
	end

	local function HUDPaint()
		x,y = gui.MousePos()
		local tbl = {}

		for key, part in pairs(parts) do
			if not part:IsHidden() then
				local pos = part.cached_pos:ToScreen()
				if pace.DrawSelection(pos) then
					table.insert(tbl, {part = part, pos = pos, dist = Vector(pos.x, pos.y, 0):Distance(Vector(x, y, 0))})
				end
			end
		end


		if tbl[1] then
			table.sort(tbl, function(a, b) return a.dist < b.dist end)
			data = tbl[1]
			pace.DrawHUDText(data.pos.x, data.pos.y, data.part:GetName())
			data.part:Highlight(true)
		else
			data = nil
		end
	end
	
	pace.IsSelecting = true

	hook.Add("GUIMousePressed", "pac_draw_select", GUIMousePressed)
	hook.Add("HUDPaint", "pac_draw_select", HUDPaint)
end

function pace.SelectEntity(callback)
	local data

	local function GUIMousePressed(mcode)
		if mcode == MOUSE_LEFT and data then
			callback(data.ent)
			pace.StopSelect()
		end
	end

	local function HUDPaint()
		x,y = gui.MousePos()
		local tbl = {}

		for _, ent in pairs(ents.GetAll()) do
			if ent:IsValid() then
				local pos = ent:EyePos():ToScreen()
				if pace.DrawSelection(pos) then
					table.insert(tbl, {pos = pos, ent = ent, dist = Vector(pos.x, pos.y, 0):Distance(Vector(x, y, 0))})
				end
			end
		end


		if tbl[1] then
			table.sort(tbl, function(a, b) return a.dist < b.dist end)
			data = tbl[1]
			pace.DrawHUDText(data.pos.x, data.pos.y, get_friendly_name(data.ent))
		else
			data = nil
		end
	end
	
	pace.IsSelecting = true

	hook.Add("GUIMousePressed", "pac_draw_select", GUIMousePressed)
	hook.Add("HUDPaint", "pac_draw_select", HUDPaint)
end
