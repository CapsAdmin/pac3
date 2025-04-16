local LocalToWorld = LocalToWorld
local render_StartBeam = render.StartBeam
local render_AddBeam = render.AddBeam
local render_EndBeam = render.EndBeam
local color_white = color_white
local math_sin = math.sin
local math_pi = math.pi
local Angle = Angle
local Lerp = Lerp
local Vector = Vector
local Color = Color

-- feel free to use this wherever!
do
	local ax,ay,az = 0,0,0
	local bx,by,bz = 0,0,0
	local adx,ady,adz = 0,0,0
	local bdx,bdy,bdz = 0,0,0

	local frac = 0
	local wave = 0
	local bendmult = 0

	local vector = Vector()
	local color = Color(255, 255, 255, 255)

	function pac.DrawBeam(veca, vecb, dira, dirb, bend, res, width, start_color, end_color, frequency, tex_stretch, tex_scroll, width_bend, width_bend_size, width_start_mul, width_end_mul, width_pow)

		if not veca or not vecb or not dira or not dirb then return end

		ax = veca.x; ay = veca.y; az = veca.z
		bx = vecb.x; by = vecb.y; bz = vecb.z

		adx = dira.x; ady = dira.y; adz = dira.z
		bdx = dirb.x; bdy = dirb.y; bdz = dirb.z

		bend = bend or 10
		res = math.max(res or 32, 2)
		width = width or 10
		start_color = start_color or color_white
		end_color = end_color or color_white
		frequency = frequency or 1
		tex_stretch = tex_stretch or 1
		width_bend = width_bend or 0
		width_bend_size = width_bend_size or 1
		tex_scroll = tex_scroll or 0
		width_start_mul = width_start_mul or 1
		width_end_mul = width_end_mul or 1
		width_pow = width_pow or 1

		render_StartBeam(res + 1)

			for i = 0, res do

				frac = i / res
				wave = frac * math_pi * frequency
				bendmult = math_sin(wave) * bend

				vector.x = Lerp(frac, ax, bx) + Lerp(frac, adx * bendmult, bdx * bendmult)
				vector.y = Lerp(frac, ay, by) + Lerp(frac, ady * bendmult, bdy * bendmult)
				vector.z = Lerp(frac, az, bz) + Lerp(frac, adz * bendmult, bdz * bendmult)

				color.r = start_color.r == end_color.r and start_color.r or Lerp(frac, start_color.r, end_color.r)
				color.g = start_color.g == end_color.g and start_color.g or Lerp(frac, start_color.g, end_color.g)
				color.b = start_color.b == end_color.b and start_color.b or Lerp(frac, start_color.b, end_color.b)
				color.a = start_color.a == end_color.a and start_color.a or Lerp(frac, start_color.a, end_color.a)

				render_AddBeam(
					vector,
					(width + ((math_sin(wave) ^ width_bend_size) * width_bend)) * Lerp(math.pow(frac,width_pow), width_start_mul, width_end_mul),
					(i / tex_stretch) + tex_scroll,
					color
				)

			end

		render_EndBeam()
	end
end

local BUILDER, PART = pac.PartTemplate("base_drawable")

PART.ClassName = "beam"
PART.Group = 'effects'
PART.Icon = 'icon16/vector.png'

BUILDER:StartStorableVars()
	BUILDER:SetPropertyGroup("generic")
		BUILDER:PropertyOrder("Name")
		BUILDER:PropertyOrder("Hide")
		BUILDER:PropertyOrder("ParentName")
		BUILDER:GetSet("Material", "cable/rope")
		BUILDER:GetSetPart("EndPoint")
		BUILDER:GetSet("MultipleEndPoints","")
		BUILDER:GetSet("AutoHitpos", false, {description = "Create the endpoint at the hit position in front of the part (red arrow)"})
		BUILDER:GetSet("AutoHitposFilter", "standard", {enums = {
			standard = "standard",
			world_only = "world_only",
			life = "life",
			none = "none"
		}, description = "the filter modes are as such: standard = exclude player, root owner and pac_projectile\nworld_only = only hit world\nlife = hit players, NPCs, Nextbots\nnone = hit anything"})
	BUILDER:SetPropertyGroup("beam size")
		BUILDER:GetSet("Width", 1)
		BUILDER:GetSet("WidthBend", 0)
		BUILDER:GetSet("WidthBendSize", 1)
		BUILDER:GetSet("StartWidthMultiplier", 1)
		BUILDER:GetSet("EndWidthMultiplier", 1)
		BUILDER:GetSet("WidthMorphPower", 1)
	BUILDER:SetPropertyGroup("beam detail")
		BUILDER:GetSet("Bend", 10)
		BUILDER:GetSet("Frequency", 1)
		BUILDER:GetSet("Resolution", 16)
		BUILDER:GetSet("TextureStretch", 1)
		BUILDER:GetSet("TextureScroll", 0)
		BUILDER:GetSet("ScrollRate", 0)
	BUILDER:SetPropertyGroup("orientation")
	BUILDER:SetPropertyGroup("appearance")
		BUILDER:GetSet("StartColor", Vector(255, 255, 255), {editor_panel = "color"})
		BUILDER:GetSet("EndColor", Vector(255, 255, 255), {editor_panel = "color"})
		BUILDER:GetSet("StartAlpha", 1)
		BUILDER:GetSet("EndAlpha", 1)
	BUILDER:SetPropertyGroup("other")
		BUILDER:PropertyOrder("DrawOrder")
	BUILDER:SetPropertyGroup("Showtime dynamics")
		BUILDER:GetSet("EnableDynamics", false, {description = "If you want to make a fading effect, you can do it here instead of adding proxies."})
		BUILDER:GetSet("SizeFadeSpeed", 1)
		BUILDER:GetSet("SizeFadePower", 1)
		BUILDER:GetSet("IncludeWidthBend", true, {description = "whether to include the width bend in the dynamics fading of the overall width multiplier"})
		BUILDER:GetSet("DynamicsStartSizeMultiplier", 1, {editor_friendly = "StartSizeMultiplier"})
		BUILDER:GetSet("DynamicsEndSizeMultiplier", 1, {editor_friendly = "EndSizeMultiplier"})

		BUILDER:GetSet("AlphaFadeSpeed", 1)
		BUILDER:GetSet("AlphaFadePower", 1)
		BUILDER:GetSet("DynamicsStartAlpha", 1, {editor_sensitivity = 0.25, editor_clamp = {0, 1}, editor_friendly = "StartAlpha"})
		BUILDER:GetSet("DynamicsEndAlpha", 1, {editor_sensitivity = 0.25, editor_clamp = {0, 1}, editor_friendly = "EndAlpha"})

BUILDER:EndStorableVars()

function PART:GetNiceName()
	local found = ("/" .. self:GetMaterial()):match(".*/(.+)")
	return found and pac.PrettifyName(found:gsub("%..+", "")) or "error"
end

function PART:Initialize()
	self:SetMaterial(self.Material)

	self.StartColorC = Color(255, 255, 255, 255)
	self.EndColorC = Color(255, 255, 255, 255)
end

function PART:GetOrFindCachedPart(uid_or_name)
	local part = nil
	self.erroring_cached_parts = {}
	self.found_cached_parts = self.found_cached_parts or {}
	if self.found_cached_parts[uid_or_name] then self.erroring_cached_parts[uid_or_name] = nil return self.found_cached_parts[uid_or_name] end
	if self.erroring_cached_parts[uid_or_name] then return end

	local owner = self:GetPlayerOwner()
	part = pac.GetPartFromUniqueID(pac.Hash(owner), uid_or_name) or pac.FindPartByPartialUniqueID(pac.Hash(owner), uid_or_name)
	if not part:IsValid() then
		part = pac.FindPartByName(pac.Hash(owner), uid_or_name, self)
	else
		self.found_cached_parts[uid_or_name] = part
		return part
	end
	if not part:IsValid() then
		self.erroring_cached_parts[uid_or_name] = true
	else
		self.found_cached_parts[uid_or_name] = part
		return part
	end
	return part
end

function PART:SetMultipleEndPoints(str)
	self.MultipleEndPoints = str
	if str == "" then self.MultiEndPoint = nil self.ExtraHermites = nil return end
	timer.Simple(0.2, function()
		if not string.find(str, ";") then
			local part = self:GetOrFindCachedPart(str)
			if IsValid(part) then
				self:SetEndPoint(part)
				self.MultipleEndPoints = ""
			else
				timer.Simple(3, function()
					local part = self:GetOrFindCachedPart(str)
					if part then
						self:SetEndPoint(part)
						self.MultipleEndPoints = ""
					end
				end)
			end
			self.MultiEndPoint = nil
		else
			self:SetEndPoint()
			self.MultiEndPoint = {}
			self.ExtraHermites = {}
			local uid_splits = string.Split(str, ";")
			for i,uid2 in ipairs(uid_splits) do
				local part = self:GetOrFindCachedPart(uid2)
				if not IsValid(part) then
					timer.Simple(3, function()
						local part = self:GetOrFindCachedPart(uid2)
						if part then table.insert(self.MultiEndPoint, part) table.insert(self.ExtraHermites, part) end
					end)
				else table.insert(self.MultiEndPoint, part) table.insert(self.ExtraHermites, part) end
			end
			self.ExtraHermites_Property = "MultipleEndPoints"
		end
	end)
end

function PART:SetStartColor(v)
	self.StartColorC = self.StartColorC or Color(255, 255, 255, 255)

	self.StartColorC.r = v.r
	self.StartColorC.g = v.g
	self.StartColorC.b = v.b

	self.StartColor = v
end

function PART:SetEndColor(v)
	self.EndColorC = self.EndColorC or Color(255, 255, 255, 255)

	self.EndColorC.r = v.r
	self.EndColorC.g = v.g
	self.EndColorC.b = v.b

	self.EndColor = v
end

function PART:SetStartAlpha(n)
	self.StartColorC = self.StartColorC or Color(255, 255, 255, 255)

	self.StartColorC.a = n * 255

	self.StartAlpha = n
end

function PART:SetEndAlpha(n)
	self.EndColorC = self.EndColorC or Color(255, 255, 255, 255)

	self.EndColorC.a = n * 255

	self.EndAlpha = n
end

function PART:FixMaterial()
	local mat = self.Materialm

	if not mat then return end

	local shader = mat:GetShader()

	if shader == "VertexLitGeneric" or shader == "Cable" then
		local tex_path = mat:GetString("$basetexture")

		if tex_path then
			local params = {}

			params["$basetexture"] = tex_path
			params["$vertexcolor"] = 1
			params["$vertexalpha"] = 1

			self.Materialm = CreateMaterial(tostring(self) .. "_pac_trail", "UnlitGeneric", params)
		end
	end
end

function PART:SetMaterial(var)
	var = var or ""

	self.Material = var

	if not pac.Handleurltex(self, var) then
		if isstring(var) then
			self.Materialm = pac.Material(var, self)
			self:FixMaterial()
			self:CallRecursive("OnMaterialChanged")
		elseif type(var) == "IMaterial" then
			self.Materialm = var
			self:FixMaterial()
			self:CallRecursive("OnMaterialChanged")
		end
	end
end

function PART:OnShow()
	self.starttime = CurTime()
	self.scrolled_amount = 0
end

function PART:OnDraw()
	local part = self.EndPoint

	local lifetime = (CurTime() - self.starttime)
	self.scrolled_amount = self.scrolled_amount + FrameTime() * self.ScrollRate

	local fade_factor_w = math.Clamp(lifetime*self.SizeFadeSpeed,0,1)
	local fade_factor_a = math.Clamp(lifetime*self.AlphaFadeSpeed,0,1)
	
	local final_alpha_mult = self.EnableDynamics and
		self.DynamicsStartAlpha + (self.DynamicsEndAlpha - self.DynamicsStartAlpha) * math.pow(fade_factor_a,self.AlphaFadePower)
		or 1

	local StartColorA = self.StartColorC.a
	local EndColorA = self.EndColorC.a
	self.StartColorC.a = final_alpha_mult * StartColorA
	self.EndColorC.a = final_alpha_mult * EndColorA

	local final_size_mult = self.EnableDynamics and
		self.DynamicsStartSizeMultiplier + (self.DynamicsEndSizeMultiplier - self.DynamicsStartSizeMultiplier) * math.pow(fade_factor_w,self.SizeFadePower)
		or 1

	if self.Materialm and self.StartColorC and self.EndColorC and ((part:IsValid() and part.GetWorldPosition) or self.MultiEndPoint or self.AutoHitpos) then
		local pos, ang = self:GetDrawPosition()
		render.SetMaterial(self.Materialm)
		if self.MultiEndPoint then
			for _,part in ipairs(self.MultiEndPoint) do
				pac.DrawBeam(
					pos,
					part:GetWorldPosition(),

					ang:Forward(),
					part:GetWorldAngles():Forward(),

					self.Bend,
					math.Clamp(self.Resolution, 1, 256),
					self.Width * final_size_mult,
					self.StartColorC,
					self.EndColorC,
					self.Frequency,
					self.TextureStretch,
					self.TextureScroll - self.scrolled_amount,
					self.IncludeWidthBend and final_size_mult * self.WidthBend or self.WidthBend,
					self.WidthBendSize,
					self.StartWidthMultiplier,
					self.EndWidthMultiplier,
					self.WidthMorphPower
				)
			end
		else
			if self.AutoHitpos then
				local filter = {}
				local playerowner = self:GetPlayerOwner()
				local rootowner = self:GetRootPart():GetOwner()
				if self.AutoHitposFilter == "standard" then
					filter = function(ent)
						if ent == playerowner then return false end
						if ent == rootowner then return false end
						if ent:GetClass() == "pac_projectile" then return false end
						return true
					end
				elseif self.AutoHitposFilter == "world_only" then
					filter = function(ent)
						return ent:IsWorld()
					end
				elseif self.AutoHitposFilter == "life" then
					filter = function(ent) return (ent:IsNPC() or (ent:IsPlayer() and ent ~= playerowner) or ent:IsNextBot()) end
				else
					filter = nil
				end
				self.hitpos = util.QuickTrace(pos, ang:Forward()*32000, filter).HitPos
			end
			pac.DrawBeam(
				pos,
				self.AutoHitpos and self.hitpos or part:GetWorldPosition(),

				ang:Forward(),
				self.AutoHitpos and ang:Forward() or part:GetWorldAngles():Forward(),

				self.Bend,
				math.Clamp(self.Resolution, 1, 256),
				self.Width * final_size_mult,
				self.StartColorC,
				self.EndColorC,
				self.Frequency,
				self.TextureStretch,
				self.TextureScroll - self.scrolled_amount,
				self.IncludeWidthBend and final_size_mult * self.WidthBend or self.WidthBend,
				self.WidthBendSize,
				self.StartWidthMultiplier,
				self.EndWidthMultiplier,
				self.WidthMorphPower
			)
		end
	end

	self.StartColorC.a = StartColorA
	self.EndColorC.a = EndColorA
end

BUILDER:Register()
