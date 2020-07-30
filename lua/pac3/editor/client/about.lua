local DEMO = {}

DEMO.Title = "Sand"
DEMO.Author = "Capsadmin"

local lines =
{
	--surface.GetTextureID("sprites/laser"),
	--surface.GetTextureID("sprites/bluelaser"),
	surface.GetTextureID("effects/laser1"),
	surface.GetTextureID("trails/laser"),
}

local sprites =
{
	surface.GetTextureID("particle/fire"),
}

local white = surface.GetTextureID("vgui/white")

function DEMO:DrawLineEx(x1,y1, x2,y2, w, skip_tex)
	w = w or 1
	if not skip_tex then surface.SetTexture(white) end

	local dx,dy = x1-x2, y1-y2
	local ang = math.atan2(dx, dy)
	local dst = math.sqrt((dx * dx) + (dy * dy))

	x1 = x1 - dx * 0.5
	y1 = y1 - dy * 0.5

	surface.DrawTexturedRectRotated(x1, y1, w, dst, math.deg(ang))
end

do
	local fonts = {}

	local function create_fonts(font, size, weight, blursize)
		local main = "pretty_text_" .. size .. weight
		local blur = "pretty_text_blur_" .. size .. weight

		surface.CreateFont(
			main,
			{
				font = font,
				size = size,
				weight = weight,
				antialias 	= true,
				additive 	= true,
			}
		)

		surface.CreateFont(
			blur,
			{
				font = font,
				size = size,
				weight = weight,
				antialias 	= true,
				blursize = blursize,
			}
		)

		return
		{
			main = main,
			blur = blur,
		}
	end

	def_color1 = Color(255, 255, 255, 255)
	def_color2 = Color(0, 0, 0, 255)

	local surface_SetFont = surface.SetFont
	local surface_SetTextColor = surface.SetTextColor
	local surface_SetTextPos = surface.SetTextPos
	local surface_DrawText = surface.DrawText
	local surface_GetTextSize = surface.GetTextSize

	function DEMO:DrawPrettyText(text, x, y, font, size, weight, blursize, color1, color2, align_mult_x, align_mult_y)
		align_mult_x = align_mult_x or 0
		align_mult_y = align_mult_y or 0
		font = font or "Arial"
		size = size or 14
		weight = weight or 0
		blursize = blursize or 1
		color1 = color1 or def_color1
		color2 = color2 or def_color2

		fonts[font] = fonts[font] or {}
		fonts[font][size] = fonts[font][size] or {}
		fonts[font][size][weight] = fonts[font][size][weight] or {}
		fonts[font][size][weight][blursize] = fonts[font][size][weight][blursize] or create_fonts(font, size, weight, blursize)

		surface_SetFont(fonts[font][size][weight][blursize].blur)
		local w, h = surface_GetTextSize(text)
		surface_SetTextColor(color2)

		align_mult_x = (w * align_mult_x)
		align_mult_y = (h * align_mult_y)

		for i = 1, 5 do
			surface_SetTextPos(x - align_mult_x, y - align_mult_y) -- this resets for some reason after drawing
			surface_DrawText(text)
		end

		surface_SetFont(fonts[font][size][weight][blursize].main)
		surface_SetTextColor(color1)

		surface_SetTextPos(x - align_mult_x, y - align_mult_y)
		surface_DrawText(text)

		return w, h
	end
end


function DEMO:OnStart(w, h)

	input.SetCursorPos(w/2, h/2)

	surface.SetDrawColor(0,0,0,255)
	surface.DrawRect(0,0,w,h)

	self.first = true
	self.cam_pos = Vector(0, 0, 0)
	self.spos = Vector(w, h) / 2

	self.max_size = 16

	self.max_particles = 2000
	self.particles = {}
	self.base_color =  math.random(360)
end

function DEMO:CreateParticle(x, y, vx, vy, life, on_death)
	life = life or math.Rand(0.25, 2)


	local siz = math.Rand(0.5,self.max_size)
	table.insert(
		self.particles,
		{
			pos = {x = x, y = y},
			vel = {x = vx, y = vy},
			siz = siz,
			clr = HSVToColor(math.Rand(0, 60) + self.base_color, 1, 1),
			drag = 0.99 - (siz/150) ^ 3,
			tex_id1 = table.Random(lines),
			tex_id2 = table.Random(sprites),
			on_death = on_death,
			life = self.time + life,
			random = math.Rand(-1,1),
		}
	)
end

function DEMO:PreUpdate(w, h, t, d)
	if input.IsKeyDown(KEY_W) then
		self.cam_pos.y = self.cam_pos.y + d
	elseif input.IsKeyDown(KEY_S) then
		self.cam_pos.y = self.cam_pos.y - d
	end

	if input.IsKeyDown(KEY_A)then
		self.cam_pos.x = self.cam_pos.x - d
	elseif input.IsKeyDown(KEY_D) then
		self.cam_pos.x = self.cam_pos.x + d
	end

	local mat = Matrix()

	mat:Translate(Vector(w/2,h/2,0))

	mat:Translate(Vector(self.cam_pos.x * 100, 0, 0))
	mat:Scale(Vector(1, 1, 1) * math.min(t ^ 4, 1))
	mat:Rotate(Angle(0, 0, 0))

	mat:Translate(-Vector(w/2,h/2,0))

	return mat
end

local ext_vel_x = 0
local ext_vel_y = 0
local ext_vel_z = 0

local blur = Material("pp/blurscreen")

local function blur_screen(w, h, x, y)
	surface.SetMaterial(blur)
	surface.SetDrawColor(255, 50, 50, 2)

	for i = 0, 10 do
		blur:SetFloat("$blur", i / 10)
		blur:Recompute()
		render.UpdateScreenEffectTexture()
		surface.DrawTexturedRect(x * math.random(-16, 16), y * math.random(-16, 16), w, h)
	end
end

surface.CreateFont("pace_about_1", {font = "Roboto Bold", size = 512, weight = 800, additive = false, antialias = true})

local credits = {}
local A = function(str, size, ...) table.insert(credits, {str, size or type(str) == "string" and 1 or nil, ...}) end

local cast = {
	"morshmellow",
	"immortalyes",
	"kilroy",
	"white queen",
	"dizrahk",
	"kerahk",
	"Nomad'Zorah vas Source",
	"Verbal Silence",
	"Madness",
	"Techbot",
	"Elmo",
	"Arctic",
	"krionikal",
	"Gm Matsilagi",
	"Daft Lad",
	"GigiSpahz",
	"Black Tea",
	"RocketMania",
	"ssogal",
	"Expresso",
	"Ryokon!",
	"Zeriga",
	"Aeo",
	"techbot",
	"midori",
	"sauer",
	"LilTrenya",
	"maarc",
	"dekota",
	"liltrenya",
	"nanori",
	"svetlana",
	"scud",
}

local koreans = {
	"black tea",
	"ssogal",
	"girong",
	"scud",
	"명박오니●",
	"rocketmania",
	"maybe",
	"lac",
	"chupa",
	"momo",
	"천령씨",
}

local japanese = {
	"kilroy",
	"bubu",
	"ゆっけりあーの",
	"yomofox",
	"zaguya",
	"acchan",
	"cabin mild",
	"enngawa",
	"freeman",
	"piichan",
	"fia",
}

for _, text in RandomPairs(japanese) do
	A(text, 1, 0)
end

A("00:06 - *DEAD* Bubu: おおおっきいいいいおおおおおおお", 2)

for _, text in RandomPairs(koreans) do
	A(text, 1, 0)
end

A("ㅋㅋㅋㅋㅋㅋㅋㅋㅋ", 2)

for _, text in RandomPairs(cast) do
	A(text, 1, 0)
end

A("makeup department", 2)

A(4)

A("black tea", 1)
A("momo", 1.5)
A("yomofox", 1)
A("translations", 2)

A("your imagination")
A("garry")
A("puush")
A("gdrive")
A("dropbox")
A("metastruct")
A("Production Management", 2)

A("workshop")
A("garrysmod.org")
A("nexusmods")
A("valve")
A("Art Direction", 2)

A("Mark James")
A("Editor Icons", 2)

A("Morten")
A("HTML Department", 2)
A(4)
A("capsadmin", 1)
A("written and managed by", 1)
A("pac3", 4)

local start_height = 0
local text_size = 32
local text_spacing = 4

for k,v in pairs(credits) do
	if v[2] then
		v[1] = v[1]:upper()
		start_height = start_height + text_size + text_spacing
	end
end

start_height = start_height * 1.75

function DEMO:DrawCredits(w, h, d, t, pos)
	local last_height = 0

	for i, data in pairs(credits) do
		if not data[2] then
			last_height = last_height + data[1] * text_size + text_spacing
		else
			local w, h = self:DrawPrettyText(
				data[1],
				self.spos.x,
				-t * 30 + self.spos.y - last_height + start_height,

				"Roboto-Black",
				text_size * data[2],

				0,
				10,

				Color(255, 255, 255, 200),
				Color(255, 100, 255, 50),

				data[3] or 0.5,
				1
			)

			last_height = last_height + h * data[2] + text_spacing
		end
	end

	self.spos = self.spos + ((pos - self.spos) * d)
end

function DEMO:DrawParticles(w, h, d, t, pos)
	d = d * 50

	local mult = 0.00001

	if input.IsMouseDown(MOUSE_RIGHT) then
		mult = 0.0001
	end

	for i, part in pairs(self.particles) do
		-- random velocity for some variation
		part.vel.x = part.vel.x + ((pos.x - part.pos.x) * mult * part.siz) + math.Rand(-0.1,0.1)
		part.vel.y = part.vel.y + ((pos.y - part.pos.y) * mult * part.siz) + math.Rand(-0.1,0.1)

		-- velocity
		part.pos.x = part.pos.x + (part.vel.x * d)
		part.pos.y = part.pos.y + (part.vel.y * d)

		-- friction
		part.vel.x = part.vel.x * part.drag
		part.vel.y = part.vel.y * part.drag

		-- collision with other particles (buggy)
		if part.pos.x - part.siz < 0 then
			part.pos.x = 0 + part.siz * 1
			part.vel.x = part.vel.x * -part.drag
		end

		if part.pos.x + part.siz > w then
			part.pos.x = w - part.siz
			part.vel.x = part.vel.x * -part.drag
		end

		if part.pos.y - part.siz < 0 then
			part.pos.y = 0 + part.siz * 1
			part.vel.y = part.vel.y * -part.drag
		end

		if part.pos.y + part.siz > h then
			part.pos.y = h + part.siz * -1
			part.vel.y = part.vel.y * -part.drag
		end

		local l = (part.vel.x * part.vel.y) + 5
		l = l * 0.75

		local life_scale = math.min(part.life - t, 1) ^ 2
		local s = math.min(part.siz * l + 40, 100)

		surface.SetTexture(part.tex_id2)

		surface.SetDrawColor(part.clr.r, part.clr.g, part.clr.b, 255)
		self:DrawLineEx(
			part.pos.x,
			part.pos.y,
			part.pos.x - part.vel.x*l,
			part.pos.y - part.vel.y*l,

			part.siz * life_scale, true
		)

		s = s * life_scale

		surface.SetDrawColor(part.clr.r*0.1*l, part.clr.g*0.1*l, part.clr.b*0.1*l, 255)
		surface.DrawTexturedRect(
			(part.pos.x - s * 0.5),
			(part.pos.y - s * 0.5),
			s,
			s
		)

		if part.life < t and (not part.on_death or part:on_death() ~= false) then
			self.particles[i] = nil
		end
	end
end

function DEMO:DrawPostProcess(w, h, d, t, pos)
	local params = {}

		params["$pp_colour_addr"] = 0
		params["$pp_colour_addg"] = 0
		params["$pp_colour_addb"] = 0
		params["$pp_colour_brightness"] = -0.1
		params["$pp_colour_contrast"] =  0.8
		params["$pp_colour_colour"] = math.sin(t) * 1 - 0.5
		params["$pp_colour_mulr"] = math.sin(t) / 3
		params["$pp_colour_mulg"] = math.cos(t) / 2
		params["$pp_colour_mulb"] = math.asin(t) / 2
	DrawColorModify(params)

	local vel = ((self.last_pos or pos) - pos):Length() / 200

	if vel > 1 then
		self.cursor = "arrow"
	else
		self.cursor = "none"
	end

	vel = vel + 0.1

	DrawSunbeams(0.5, vel, 0.05, self.spos.x / w, self.spos.y / h)
	blur_screen(w, h, self.spos.x / w, self.spos.y / h)
end

local function ang_to_dir(ang, scale)
	ang = math.deg(ang)
	scale = scale or 1
	return math.sin(ang) * scale, math.cos(ang) * scale
end

function DEMO:SpawnFireworks(x, y)
	local vx, vy = ang_to_dir(math.Rand(-45, 45), math.Rand(10, 20))
	self:CreateParticle(x, y, vx, vy, nil, function(part)
		for i = -90, 90 do
			self:CreateParticle(part.pos.x, part.pos.y, ang_to_dir(i * 2, math.Rand(1, 5) * math.Rand(1, 2)))
		end

		self.base_color = self.base_color + math.Rand(30, 60)
	end)
end

function DEMO:OnDraw(w, h, d, t, pos)

	-- background
	surface.SetDrawColor(0, 0, 0, 20)
	surface.DrawRect(w*-1, h*-1, w*4, h*4)

	if input.IsMouseDown(MOUSE_LEFT) then
		self:SpawnFireworks(input.GetCursorPos())
	end

	if math.random() > 0.99 then
		self:SpawnFireworks(math.Rand(0, w), h - 20)
	end

	self:DrawCredits(w, h, d, t, pos)
	self:DrawParticles(w, h, d, t, pos)
	self:DrawPostProcess(w, h, d, t, pos)

	self.last_pos = pos
end

function DEMO:OnUpate(w, h, d, t, pos, first)
	self.time = t

	if first then
		local ok, err = pcall(self.OnStart, self, w, h)
		if not ok then return ok, err end
	end

	local ok, mat = pcall(self.PreUpdate, self, w, h, t, d)

	if not ok then return ok, mat end

	cam.Start2D()
		if mat then cam.PushModelMatrix(mat) end
			local ok, err = pcall(self.OnDraw, self, w, h, d, t, pos)
		if mat then cam.PopModelMatrix() end
	cam.End2D()

	return ok, err
end

function pace.ShowAbout()

	local pnl = vgui.Create("Panel")
	pnl:SetPos(0, 0)
	pnl:SetSize(ScrW(), ScrH())
	pnl:MakePopup()

	local html = vgui.Create("DHTML", pnl)
	html:OpenURL("https://www.youtube.com/watch?v=Kvg7oTfGhYg")

	local first = true
	local start_time = RealTime()

	pac.AddHook("PreRender", "pace_about", function()

		local w, h = ScrW(), ScrH()
		local t = RealTime() - start_time
		local d = FrameTime()

		local ok, err = DEMO:OnUpate(w, h, d, t, Vector(input.GetCursorPos()), first)

		if pnl.last_cursor ~= DEMO.cursor then
			pnl:SetCursor(DEMO.cursor or "arrow")
			pnl.last_cursor = DEMO.cursor
		end

		first = false

		quit = input.IsKeyDown(KEY_SPACE) or input.IsKeyDown(KEY_ESCAPE) or not ok

		if quit then
			if not ok then print(err) end
			pnl:Remove()
			pac.RemoveHook("PreRender", "pace_about")
			return
		end

		return true
	end)
end
