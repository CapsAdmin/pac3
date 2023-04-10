local cam_Start3D = cam.Start3D
local cam_Start3D2D = cam.Start3D2D
local EyePos = EyePos
local EyeAngles = EyeAngles
local draw_SimpleTextOutlined = draw.SimpleTextOutlined
local DisableClipping = DisableClipping
local render_CullMode = render.CullMode
local cam_End3D2D = cam.End3D2D
local cam_End3D = cam.End3D
--local Text_Align = TEXT_ALIGN_CENTER
local surface_SetFont = surface.SetFont
local Color = Color

local BUILDER, PART = pac.PartTemplate("base_drawable")

PART.ClassName = "text"
PART.Group = 'effects'
PART.Icon = 'icon16/text_align_center.png'

BUILDER:StartStorableVars()
	:SetPropertyGroup("generic")
		:PropertyOrder("Name")
		:PropertyOrder("Hide")
		:GetSet("Text", "")
		:GetSet("Font", "default")
		:GetSet("Size", 1, {editor_sensitivity = 0.25})


	:SetPropertyGroup("text layout")
		:GetSet("HorizontalTextAlign", TEXT_ALIGN_CENTER, {enums = {["Left"] = "0", ["Center"] = "1", ["Right"] = "2"}})
		:GetSet("VerticalTextAlign", TEXT_ALIGN_CENTER, {enums = {["Center"] = "1", ["Top"] = "3", ["Bottom"] = "4"}})
		:GetSet("ConcatenateTextAndOverrideValue",false,{editor_friendly = "CombinedText"})

	:SetPropertyGroup("data source")
		:GetSet("TextOverride", "Text", {enums = {
			["Text"] = "Text",
			["Health"] = "Health",
			["Maximum Health"] = "MaxHealth",
			["Armor"] = "Armor",
			["Maximum Armor"] = "MaxArmor",
			["Timerx"] = "Timerx",
			["CurTime"] = "CurTime",
			["RealTime"] = "RealTime",
			["Clip current Ammo"] = "Ammo",
			["Clip Size"] = "ClipSize",
			["Ammo Reserve"] = "AmmoReserve",
			["Proxy value (Using DynamicTextValue)"] = "Proxy"}})
		:GetSet("DynamicTextValue", 0)

	:SetPropertyGroup("appearance")
	BUILDER:GetSet("Outline", 0)
	BUILDER:GetSet("Color", Vector(255, 255, 255), {editor_panel = "color"})
	BUILDER:GetSet("Alpha", 1, {editor_sensitivity = 0.25, editor_clamp = {0, 1}})
	BUILDER:GetSet("OutlineColor", Vector(255, 255, 255), {editor_panel = "color"})
	BUILDER:GetSet("OutlineAlpha", 1, {editor_onchange = function(self, num)
		self.sens = 0.25
		num = tonumber(num)
		return math.Clamp(num, 0, 1)
	end})
	BUILDER:GetSet("Translucent", true)
BUILDER:EndStorableVars()

function PART:GetNiceName()
	if self.TextOverride ~= "Text" then return self.TextOverride end

	return 'Text: "' .. self:GetText() .. '"'
end

function PART:SetColor(v)
	self.ColorC = self.ColorC or Color(255, 255, 255, 255)

	self.ColorC.r = v.r
	self.ColorC.g = v.g
	self.ColorC.b = v.b

	self.Color = v
end

function PART:SetAlpha(n)
	self.ColorC = self.ColorC or Color(255, 255, 255, 255)
	self.ColorC.a = n * 255

	self.Alpha = n
end

function PART:SetOutlineColor(v)
	self.OutlineColorC = self.OutlineColorC or Color(255, 255, 255, 255)

	self.OutlineColorC.r = v.r
	self.OutlineColorC.g = v.g
	self.OutlineColorC.b = v.b

	self.OutlineColor = v
end

function PART:SetOutlineAlpha(n)
	self.OutlineColorC = self.OutlineColorC or Color(255, 255, 255, 255)
	self.OutlineColorC.a = n * 255

	self.OutlineAlpha = n
end

function PART:SetFont(str)
	if not pcall(surface_SetFont, str) then
		pac.Message(Color(255,150,0),str.." Font not found! Reverting to DermaDefault!")
		str = "DermaDefault"
	end

	self.Font = str
end

function PART:OnDraw()
	local pos, ang = self:GetDrawPosition()
	local DisplayText = self.Text or ""
	if self.TextOverride == "Text" then goto DRAW end

	if self.TextOverride == "Health"then DisplayText = self:GetPlayerOwner():Health()
	elseif self.TextOverride == "MaxHealth"	then
		DisplayText = self:GetPlayerOwner():GetMaxHealth()
	elseif self.TextOverride == "Ammo" then
		DisplayText = self:GetPlayerOwner():GetActiveWeapon():Clip1()
	elseif self.TextOverride == "ClipSize" then
		DisplayText = self:GetPlayerOwner():GetActiveWeapon():GetMaxClip1()
	elseif self.TextOverride == "AmmoReserve" then
		DisplayText = self:GetPlayerOwner():GetAmmoCount(self:GetPlayerOwner():GetActiveWeapon():GetPrimaryAmmoType())
	elseif self.TextOverride == "Armor" then
		DisplayText = self:GetPlayerOwner():Armor()
	elseif self.TextOverride == "MaxArmor" then
		DisplayText = self:GetPlayerOwner():GetMaxArmor()
	elseif self.TextOverride == "Timerx" then
		DisplayText = ""..math.Round(CurTime() - self.time,2)
	elseif self.TextOverride == "CurTime" then
		DisplayText = ""..math.Round(CurTime(),2)
	elseif self.TextOverride == "RealTime" then
		DisplayText = ""..math.Round(RealTime(),2)
	elseif self.TextOverride == "Proxy" then
		--print(type(self.DynamicTextValue))
		DisplayText = ""..math.Round(self.DynamicTextValue,2)
	end

	if self.ConcatenateTextAndOverrideValue then DisplayText = ""..self.Text..DisplayText end

	::DRAW::
	if DisplayText ~= "" then
		cam_Start3D(EyePos(), EyeAngles())
			cam_Start3D2D(pos, ang, self.Size)
			local oldState = DisableClipping(true)

			draw_SimpleTextOutlined(DisplayText, self.Font, 0,0, self.ColorC, self.HorizontalTextAlign,self.VerticalTextAlign, self.Outline, self.OutlineColorC)
			render_CullMode(1) -- MATERIAL_CULLMODE_CW

			draw_SimpleTextOutlined(DisplayText, self.Font, 0,0, self.ColorC, self.HorizontalTextAlign,self.VerticalTextAlign, self.Outline, self.OutlineColorC)
			render_CullMode(0) -- MATERIAL_CULLMODE_CCW

			DisableClipping(oldState)
			cam_End3D2D()
		cam_End3D()
	end
end

function PART:OnShow()
	self.time = CurTime()
end

function PART:SetText(str)
	self.Text = str
end

BUILDER:Register()
