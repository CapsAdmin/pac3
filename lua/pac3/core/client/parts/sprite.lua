local PART = {}

PART.ClassName = "sprite"

pac.StartStorableVars()
	pac.GetSet(PART, "SizeX", 1)
	pac.GetSet(PART, "SizeY", 1)
	pac.GetSet(PART, "Size", 1)
	pac.GetSet(PART, "Color", color_white)
	pac.GetSet(PART, "SpritePath", "sprites/grip")
pac.EndStorableVars()


function PART:Initialize()
	self:SetSpritePath(self.SpritePath)
end

function PART:SetSpritePath(var)
	self:SetMaterial(var)
	self:SetTooltip(var)
end

function PART:SetMaterial(var)
	if type(var) == "string" then
		self.Sprite = Material(var)
	elseif type(var) == "IMaterial" then
		self.Sprite = var
	end

	self.SpritePath = var
end

function PART:PostPlayerDraw(owner, pos, ang)
	if self.Sprite then
		render.SetMaterial(self.Sprite)
		render.DrawSprite(pos, self.SizeX * self.Size, self.SizeX * self.Size, self.Color)
	end
end

function PART:OnRestore(data)
	self:SetMaterial(data.SpritePath)
end

pac.RegisterPart(PART)