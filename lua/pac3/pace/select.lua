function pace.DrawHUDText(x, y, text)
	--[[surface.SetDrawColor(255, 255, 255, 255)
	surface.DrawLine(
		Lerp(0.2, gui.MouseX(), x),
		Lerp(0.2, gui.MouseY(), y),

		Lerp(0.05, x, gui.MouseX()),
		Lerp(0.05, y, gui.MouseY())
	)]]

	surface.SetFont("DefaultFixedOutline")
	surface.SetTextColor(255, 255, 255, 255)
	local w, h = surface.GetTextSize(text)
	surface.SetTextPos(x - (w * 0.5), y - h)
	surface.DrawText(text)
end

local area = 20

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
	R("PostDrawHUD", "pac_draw_select")
	R("HUDPaint", "pac_highlight")
end

function pace.SelectBone(ent, callback)
	local data
	local bones = pac.GetAllBones(ent)

	local function GUIMousePressed(mcode)
		if mcode == MOUSE_LEFT and data then
			data.dist = nil
			callback(data)
			pace.StopSelect()
		end
	end

	local function PostDrawHUD()
		local x,y = gui.MousePos()
		local tbl = {}

		for friendly, data in pairs(bones) do
			local pos = ent:GetBonePosition(ent:LookupBone(data.real)):ToScreen()

			surface.SetDrawColor(255, 255, 255, 255)
			surface.DrawRect(pos.x, pos.y, 2, 2)

			if
				x > pos.x - area and x < pos.x + 5 + area and
				y > pos.y - area and y < pos.y + 5 + area
			then
				table.insert(tbl, {pos = pos, real = data.real, friendly = friendly, dist = Vector(pos.x, pos.y, 0):Distance(Vector(x, y, 0))})
			end
		end


		if tbl[1] then
			table.sort(tbl, function(a, b) return a.dist < b.dist end)

			data = tbl[1]

			pace.DrawHUDText(data.pos.x, data.pos.y, data.friendly)
		else
			data = nil
		end
	end

	hook.Add("GUIMousePressed", "pac_draw_select", GUIMousePressed)
	hook.Add("PostDrawHUD", "pac_draw_select", PostDrawHUD)
end

function pace.SelectPart(parts, callback)
	local data

	local function GUIMousePressed(mcode)
		if mcode == MOUSE_LEFT and data then
			callback(data.part)
			pace.StopSelect()
		end
	end

	local function PostDrawHUD()
		local x,y = gui.MousePos()
		local tbl = {}

		for key, part in pairs(parts) do
			local pos = part:GetDrawPosition():ToScreen()

			surface.SetDrawColor(255, 255, 255, 255)
			surface.DrawRect(pos.x, pos.y, 2, 2)

			if
				x > pos.x - area and x < pos.x + 5 + area and
				y > pos.y - area and y < pos.y + 5 + area
			then
				table.insert(tbl, {part = part, pos = pos, dist = Vector(pos.x, pos.y, 0):Distance(Vector(x, y, 0))})
			end
		end


		if tbl[1] then
			table.sort(tbl, function(a, b) return a.dist < b.dist end)
			data = tbl[1]
			pace.DrawHUDText(data.pos.x, data.pos.y, data.part:GetName())
		else
			data = nil
		end
	end

	hook.Add("GUIMousePressed", "pac_draw_select", GUIMousePressed)
	hook.Add("PostDrawHUD", "pac_draw_select", PostDrawHUD)
end

function pace.SelectEntity(callback)
	local data

	local function GUIMousePressed(mcode)
		if mcode == MOUSE_LEFT and data then
			callback(data.ent)
			pace.StopSelect()
		end
	end

	local function PostDrawHUD()
		local x,y = gui.MousePos()
		local tbl = {}

		for _, ent in pairs(ents.GetAll()) do
			local pos = ent:EyePos():ToScreen()

			surface.SetDrawColor(255, 255, 255, 255)
			surface.DrawRect(pos.x, pos.y, 2, 2)

			if
				x > pos.x - area and x < pos.x + 5 + area and
				y > pos.y - area and y < pos.y + 5 + area
			then
				table.insert(tbl, {pos = pos, ent = ent, dist = Vector(pos.x, pos.y, 0):Distance(Vector(x, y, 0))})
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

	hook.Add("GUIMousePressed", "pac_draw_select", GUIMousePressed)
	hook.Add("PostDrawHUD", "pac_draw_select", PostDrawHUD)
end
