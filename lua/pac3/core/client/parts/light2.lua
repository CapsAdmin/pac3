local PART = {}

PART.FriendlyName = "light"
PART.ClassName = "light2"
PART.Group = "experimental"
PART.Icon = 'icon16/lightbulb.png'

pac.StartStorableVars()
	pac.GetSet(PART, "InnerAngle", 0)
	pac.GetSet(PART, "OuterAngle", 0)
	pac.GetSet(PART, "NoModel", false)
	pac.GetSet(PART, "NoWorld", false)

	pac.SetPropertyGroup(PART, "appearance")
		pac.GetSet(PART, "Brightness", 8)
		pac.GetSet(PART, "Size", 100, {editor_sensitivity = 0.25})
		pac.GetSet(PART, "Color", Vector(1, 1, 1), {editor_panel = "color2"})
pac.EndStorableVars()

function PART:GetLight()
	if not self.light then
		self.light = DynamicLight(tonumber(self.UniqueID))
	end
	self.light.decay = 0
	self.light.dietime = math.huge

	return self.light
end

function PART:RemoveLight()
	if not self.light then return end
	local light = self.light
	self.light = nil
	-- this prevents fade out when removing the light
	light.pos = Vector(9999,9999,9999)
	timer.Simple(0, function()
		light.dietime = 0
	end)
end

function PART:GetNiceName()
	local hue = pac.ColorToNames(self:GetColor())
	return hue .. " light"
end

local vars = {
	"InnerAngle",
	"OuterAngle",
	"NoWorld",
	"NoModel",
	"Brightness",
	"Color",
	"Size",
}

function PART:OnShow()
	for _, v in ipairs(vars) do
		self["Set" .. v](self, self["Get" .. v](self))
	end
end

local DynamicLight = DynamicLight

function PART:OnDraw(owner, pos, ang)
	self:GetLight().pos = pos
	self:GetLight().dir = ang:Forward()
end

function PART:SetSize(val)
	self.Size = val
	self:GetLight().size = val
end

function PART:SetColor(val)
	self.Color = val
	self:GetLight().r = math.Clamp(val.r*255, 0, 255)
	self:GetLight().g = math.Clamp(val.g*255, 0, 255)
	self:GetLight().b = math.Clamp(val.b*255, 0, 255)
end

function PART:SetBrightness(val)
	self.Brightness = val
	self:GetLight().brightness = val
end

function PART:SetNoModel(val)
	self.NoModel = val
	self:GetLight().nomodel = val
end

function PART:SetNoWorld(val)
	self.NoWorld = val
	self:GetLight().noworld = val
end

function PART:SetInnerAngle(val)
	self.InnerAngle = val
	self:GetLight().innerangle = val
end

function PART:SetOuterAngle(val)
	self.OuterAngle = val
	self:GetLight().outerangle = val
end

function PART:OnHide()
	self:RemoveLight()
end

pac.RegisterPart(PART)