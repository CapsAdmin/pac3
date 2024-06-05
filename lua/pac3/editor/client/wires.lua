
local function CubicHermite(p0, p1, m0, m1, t)
	local tS = t*t;
	local tC = tS*t;

	return (2*tC - 3*tS + 1)*p0 + (tC - 2*tS + t)*m0 + (-2*tC + 3*tS)*p1 + (tC - tS)*m1
end

local vsamples = {}
for i=1, 100 do vsamples[#vsamples+1] = {Vector(0,0,0), Color(0,0,0,0)} end

local math_sqrt = math.sqrt
local math_abs = math.abs
local math_max = math.max
local math_min = math.min
local math_cos = math.cos
local math_pi = math.pi

local black = Color(0,0,0,100)
local vector_add = Vector(0, 2.5, 0)

local mtVector =  FindMetaTable("Vector")
local mtColor = getmetatable(black)
local render_startBeam = render.StartBeam
local render_endBeam = render.EndBeam
local render_addBeam = render.AddBeam
local setVecUnpacked = mtVector.SetUnpacked
local setColUnpacked = mtColor.SetUnpacked
local colUnpack = mtColor.Unpack

local function DrawHermite(width, x0,y0,x1,y1,c0,c1,alpha,samples)

	--[[if x0 < 0 and x1 < 0 then return end
	if x0 > w and x1 > w then return end
	if y0 < 0 and y1 < 0 then return end
	if y0 > h and y1 > h then return end]]

	local r0,g0,b0,a0 = colUnpack(c0)
	local r1,g1,b1,a1 = colUnpack(c1)

	alpha = alpha or 1

	width = width or 5
	local samples = 20
	local positions = vsamples

	samples = samples or 20

	local dx = -(x1 - x0)
	local dy = (y1 - y0)

	local d = math_sqrt(math_max(dx*dx, 8000), dy*dy) * 1.5
	d = math_max(d, math_abs(dy))
	d = math_min(d, 1000)
	d = d * 1.25 / (-dy/300)

	setVecUnpacked(positions[1][1],x0,y0,0)
	positions[1][2] = c0

	for i=1, samples do

		local t = i/samples

		t = 1 - (.5 + math_cos(t * math_pi) * .5)

		local x = CubicHermite(x0, x1, dx >= 0 and d or -d, d, t)
		local y = CubicHermite(y0, y1, 0, 0, t)

		setVecUnpacked(positions[i+1][1],x,y,0)
		setColUnpacked(positions[i+1][2],Lerp(t, r0, r1), Lerp(t, g0, g1), Lerp(t, b0, b1), a0 * alpha)
	end

	render.PushFilterMag( TEXFILTER.LINEAR )
	render.PushFilterMin( TEXFILTER.LINEAR )

	render_startBeam(samples + 1)

	for i = 1, samples + 1 do
		render_addBeam(positions[i][1] + vector_add, width, 0.5, black)
	end

	render_endBeam()

	--render.SetMaterial(Material("cable/smoke.vmt"))
	render_startBeam(samples+1)

	for i=1, samples+1 do
		local curr = positions[i][1]
		render_addBeam(curr, width, ((i/samples)*10000 - 0.5)%1, positions[i][2])
	end

	render_endBeam()

	render.PopFilterMag()
	render.PopFilterMin()
end

local function draw_hermite(x,y, w,h, ...)
	local cam3d = {
		type = "3D",

		x = 0,
		y = 0,
		w = w,
		h = h,

		znear = -10000,
		zfar = 10000,

		origin = Vector(x,y,-1000),
		angles = Angle(-90,0,90),

		ortho = {
			left = 0,
			right = w,

			top = -h,
			bottom = 0
		}
	}

	cam.Start(cam3d)
	DrawHermite(...)
	cam.End(cam3d)
end
--[[
	function PANEL:DrawHermite(...)
		local x, y = self:ScreenToLocal(0,0)
		local w, h = self:GetSize()
		draw_hermite(x,y, w,h)
	end
]]

local last_part

hook.Add("PostRenderVGUI", "beams", function()
	if not pace.IsActive() then return end
	if not pace.IsFocused()  then return end
	local part = pace.current_part
	if not part:IsValid() then return end
	local node = part.pace_tree_node

	if part ~= last_part then
		part.cached_props = nil
	end
	part.cached_props = part.cached_props or part:GetProperties()
	local props = part.cached_props
	last_part = part

	for _, info in ipairs(props) do
		if info.udata.part_key then
			--if info.udata.part_key == "Parent" then continue end

			local from = part
			local to = part["Get" .. info.udata.part_key](part)

			if not to:IsValid() then continue end


			local from_pnl = from.pace_properties and from.pace_properties[info.key] or NULL
			local to_pnl = to.pace_tree_node or NULL

			if not from_pnl:IsValid() then continue  end
			if not to_pnl:IsValid() then continue  end

			local params = {}

			params["$basetexture"] = to.Icon or "gui/colors.png"
			params["$vertexcolor"] = 1
			params["$vertexalpha"] = 1
			params["$nocull"] = 1

			local path = to_pnl:GetModel()
			if path then
				path = "spawnicons/" .. path:sub(1, -5) .. "_32"
				params["$basetexture"] = path
			end


			local mat = CreateMaterial("pac_wire_icon_" .. params["$basetexture"], "UnlitGeneric", params)

			render.SetMaterial(mat)

			local fx,fy = from_pnl:LocalToScreen(from_pnl:GetWide(), from_pnl:GetTall() / 2)

			local tx,ty = to_pnl.Icon:LocalToScreen(0,to_pnl.Icon:GetTall() / 2)

			do
				local x,y = pace.tree:LocalToScreen(0,0)
				local w,h = pace.tree:LocalToScreen(pace.tree:GetSize())

				tx = math.Clamp(tx, x, w)
				ty = math.Clamp(ty, y, h)
			end

			from_pnl.wire_smooth_hover = from_pnl.wire_smooth_hover or 0

			if from_pnl:IsHovered() or (from.pace_tree_node and from.pace_tree_node:IsValid() and from.pace_tree_node.Label:IsHovered()) then
				from_pnl.wire_smooth_hover = from_pnl.wire_smooth_hover + (5 - from_pnl.wire_smooth_hover) * FrameTime() * 20
			else
				from_pnl.wire_smooth_hover = from_pnl.wire_smooth_hover + (0 - from_pnl.wire_smooth_hover) * FrameTime() * 20
			end

			from_pnl.wire_smooth_hover = math.Clamp(from_pnl.wire_smooth_hover, 0, 5)

			if from_pnl.wire_smooth_hover > 0.01 then
				draw_hermite(0,0,ScrW(),ScrH(), from_pnl.wire_smooth_hover, fx,fy, tx,ty, Color(255,255,255), Color(255,255,255, 255), 1)
			end
		end
	end

end)
