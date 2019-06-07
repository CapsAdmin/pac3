local PART = {}

PART.ClassName = "woohoo"
PART.Group = "effects"
PART.Icon = "icon16/webcam_delete.png"

pac.StartStorableVars()
	pac.GetSet(PART, "Resolution", 8)
	pac.GetSet(PART, "Size", 1, {editor_sensitivity = 0.25})
	pac.GetSet(PART, "FixedSize", true)
	pac.GetSet(PART, "BlurFiltering", false)
	pac.GetSet(PART, "Translucent", true)
pac.EndStorableVars()

local render_ReadPixel = render.ReadPixel
local surface_SetDrawColor = surface.SetDrawColor
local surface_DrawRect = surface.DrawRect
local render_CapturePixels = render.CapturePixels

local x2, y2
local r,g,b

function PART:SetSize(size)
	self.Size = math.Clamp(size, 1, 32)
end

local function create_rt(self)
	self.rt = GetRenderTargetEx(
		"pac3_woohoo_rt_" .. math.Round(self.Resolution) .. "_" .. tostring(self.BlurFiltering),
		self.Resolution,
		self.Resolution,
		RT_SIZE_NO_CHANGE,
		MATERIAL_RT_DEPTH_NONE,
		self.BlurFiltering and 2 or 1, -- TEXTUREFLAGS_POINTSAMPLE,
		CREATERENDERTARGETFLAGS_AUTOMIPMAP,
		IMAGE_FORMAT_RGB565
	)

	collectgarbage()
end

function PART:SetBlurFiltering(b)
	self.BlurFiltering = b
	create_rt(self)
end

function PART:SetResolution(num)
	local old = self.Resolution
	self.Resolution = math.Clamp(num, 4, 1024)

	if not old or math.Round(old) ~= math.Round(self.Resolution) then
		create_rt(self)
	end
end

function PART:OnDraw(owner, pos, ang)
	if not self.rt then create_rt(self) end

	render.CopyTexture(render.GetScreenEffectTexture(), self.rt)

	cam.Start2D()

	local spos = pos:ToScreen()
	local size = self.Size

	if self.FixedSize then
		size = size / pos:Distance(pac.EyePos) * 100
	end

	size = size * 64

	local x, y, w, h = spos.x-size, spos.y-size, spos.x + size, spos.y + size

	render.SetScissorRect(x,y,w,h, true)
	render.DrawTextureToScreenRect(self.rt, 0, 0, ScrW(), ScrH())
	render.SetScissorRect(0, 0, 0, 0, false)

	cam.End2D()
end

pac.RegisterPart(PART)