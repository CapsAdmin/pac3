local PART = {}

PART.ClassName = "projected_texture"
PART.Group = "experimental"
PART.Icon = 'icon16/lightbulb.png'

pac.StartStorableVars()
	pac.GetSet(PART, "Shadows", true)
	pac.GetSet(PART, "Orthographic", false)

	pac.GetSet(PART, "NearZ", 1)
	pac.GetSet(PART, "FarZ", 2048)

	pac.GetSet(PART, "FOV", 90)
	pac.GetSet(PART, "HorizontalFOV", 90)
	pac.GetSet(PART, "VerticalFOV", 90)

	pac.GetSet(PART, "Texture", "effects/flashlight/hard", {editor_panel = "textures"})
	pac.GetSet(PART, "TextureFrame", 0)

	pac.SetPropertyGroup(PART, "appearance")
		pac.GetSet(PART, "Brightness", 8)
		pac.GetSet(PART, "Color", Vector(1, 1, 1), {editor_panel = "color2"})
pac.EndStorableVars()

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

function PART:OnDraw(owner, pos, ang)
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
	self:GetProjectedTexture():Remove()
	self.ptex = nil
end

pac.RegisterPart(PART)