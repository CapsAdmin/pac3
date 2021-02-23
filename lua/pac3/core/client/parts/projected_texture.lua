local BUILDER, PART = pac.PartTemplate("base_drawable")

PART.ClassName = "projected_texture"
PART.Group = "effects"
PART.Icon = 'icon16/lightbulb.png'
PART.ProperColorRange = true

BUILDER:StartStorableVars()
	BUILDER:GetSet("Shadows", true)
	BUILDER:GetSet("Orthographic", false)

	BUILDER:GetSet("NearZ", 1)
	BUILDER:GetSet("FarZ", 2048)

	BUILDER:GetSet("FOV", 90)
	BUILDER:GetSet("HorizontalFOV", 90)
	BUILDER:GetSet("VerticalFOV", 90)

	BUILDER:GetSet("Texture", "effects/flashlight/hard", {editor_panel = "textures"})
	BUILDER:GetSet("TextureFrame", 0)

	BUILDER:SetPropertyGroup("appearance")
		BUILDER:GetSet("Brightness", 8)
		BUILDER:GetSet("Color", Vector(1, 1, 1), {editor_panel = "color2"})
BUILDER:EndStorableVars()

function PART:GetProjectedTexture()
	if not self.ptex then
		self.ptex = ProjectedTexture()
	end
	return self.ptex
end

function PART:GetNiceName()
	local hue = pac.ColorToNames(self:GetColor())
	return hue .. " projected texture"
end

local vars = {
	"Shadows",

	"NearZ",
	"FarZ",

	"FOV",
	"HorizontalFOV",
	"VerticalFOV",

	"Orthographic",

	"Texture",
	"TextureFrame",

	"Brightness",
	"Color",
}

function PART:OnShow()
	for _, v in ipairs(vars) do
		self["Set" .. v](self, self["Get" .. v](self))
	end
end

function PART:OnDraw()
	local pos, ang = self:GetDrawPosition()
	local ptex = self:GetProjectedTexture()
	ptex:SetPos(pos)
	ptex:SetAngles(ang)
	ptex:Update()
end


function PART:SetColor(val)
	self.Color = val
	self:GetProjectedTexture():SetColor(Color(val.x*255, val.y*255, val.z*255, 1))
end

function PART:SetBrightness(val)
	self.Brightness = val
	self:GetProjectedTexture():SetBrightness(val)
end

function PART:SetOrthographic(val)
	self.Orthographic = val
	self:GetProjectedTexture():SetOrthographic(val)
end

function PART:SetVerticalFOV(val)
	self.VerticalFOV = val
	self:GetProjectedTexture():SetVerticalFOV(val)
end

function PART:SetHorizontalFOV(val)
	self.HorizontalFOV = val
	self:GetProjectedTexture():SetHorizontalFOV(val)
end


function PART:SetFOV(val)
	self.FOV = val
	self:GetProjectedTexture():SetFOV(val)
end

function PART:SetNearZ(val)
	self.NearZ = val
	self:GetProjectedTexture():SetNearZ(val)
end

function PART:SetFarZ(val)
	self.FarZ = val
	self:GetProjectedTexture():SetFarZ(val)
end

function PART:SetShadows(val)
	self.Shadows = val
	self:GetProjectedTexture():SetEnableShadows(val)
end

function PART:SetTextureFrame(val)
	self.TextureFrame = val
	if self.vtf_frame_limit then
		self:GetProjectedTexture():SetTextureFrame(math.abs(val)%self.vtf_frame_limit)
	else
		self:GetProjectedTexture():SetTextureFrame(math.abs(val))
	end
end

function PART:SetTexture(val)
	if not val then
		return
	end

	self.Texture = val

	if not pac.resource.DownloadTexture(val, function(tex, frames)
		if frames then
			self.vtf_frame_limit = frames
		end
		self:GetProjectedTexture():SetTexture(tex)
	end, self:GetPlayerOwner()) then
		self:GetProjectedTexture():SetTexture(val)
	end
end

function PART:OnHide()
	local tex = self:GetProjectedTexture()
	tex:SetBrightness(0)
	tex:Update()
	-- give it one frame to update
	timer.Simple(0, function()
		if tex:IsValid() then
			tex:Remove()
		end
	end)
	self.ptex = nil
end

function PART:OnRemove()
	self:OnHide()
end

BUILDER:Register()