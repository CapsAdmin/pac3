local DynamicLight = DynamicLight

local BUILDER, PART = pac.PartTemplate("base_drawable")

PART.FriendlyName = "light"
PART.ClassName = "light2"
PART.Group = "effects"
PART.Icon = "icon16/lightbulb.png"
PART.ProperColorRange = true

BUILDER:StartStorableVars()
	BUILDER:GetSet("InnerAngle", 0)
	BUILDER:GetSet("OuterAngle", 0)
	BUILDER:GetSet("NoModel", false)
	BUILDER:GetSet("NoWorld", false)

	BUILDER:SetPropertyGroup("appearance")
		BUILDER:GetSet("Brightness", 8)
		BUILDER:GetSet("Size", 100, {editor_sensitivity = 0.25})
		BUILDER:GetSet("Color", Vector(1, 1, 1), {editor_panel = "color2"})
		BUILDER:GetSet("Style", 0, {editor_clamp = {0, 12}, enums = {
			["Normal"] = "0",
			["Flicker A"] = "1",
			["Slow, strong pulse"] = "2",
			["Candle A"] = "3",
			["Fast strobe"] = "4",
			["Gentle pulse"] = "5",
			["Flicker B"] = "6",
			["Candle B"] = "7",
			["Candle C"] = "8",
			["Slow strobe"] = "9",
			["Fluorescent flicker"] = "10",
			["Slow pulse, noblack"] = "11",
			["Underwater light mutation"] = "12"
		}})
BUILDER:EndStorableVars()

function PART:GetLight()
	if not self.light then
		self.light = DynamicLight(tonumber(string.sub(self:GetPrintUniqueID(), 1, 7), 16))
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
	light.pos = Vector(9999, 9999, 9999)
	timer.Simple(0, function()
		light.dietime = 0
	end)
end

function PART:GetNiceName()
	local hue = pac.VectorColorToNames(self:GetColor())
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

function PART:OnDraw()
	local pos, ang = self:GetDrawPosition()
	self:GetLight().pos = pos
	self:GetLight().dir = ang:Forward()
end

function PART:SetStyle(val)
	self.Style = val
	self:GetLight().Style = self.Style
end

function PART:SetSize(val)
	self.Size = val
	self:GetLight().size = val
end

function PART:SetColor(val)
	self.Color = val
	self:GetLight().r = math.Clamp(val.r * 255, 0, 255)
	self:GetLight().g = math.Clamp(val.g * 255, 0, 255)
	self:GetLight().b = math.Clamp(val.b * 255, 0, 255)
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

BUILDER:Register()
