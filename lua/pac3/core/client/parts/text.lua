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

local default_fonts = {
	"BudgetLabel",
	"CenterPrintText",
	"ChatFont",
	"ClientTitleFont",
	"CloseCaption_Bold",
	"CloseCaption_BoldItalic",
	"CloseCaption_Italic",
	"CloseCaption_Normal",
	"CreditsLogo",
	"CreditsOutroLogos",
	"CreditsOutroText",
	"CreditsText",
	"Crosshairs",
	"DebugFixed",
	"DebugFixedSmall",
	"DebugOverlay",
	"Default",
	"DefaultFixed",
	"DefaultFixedDropShadow",
	"DefaultSmall",
	"DefaultUnderline",
	"DefaultVerySmall",
	"HDRDemoText",
	"HL2MPTypeDeath",
	"HudDefault",
	"HudHintTextLarge",
	"HudHintTextSmall",
	"HudNumbers",
	"HudNumbersGlow",
	"HudNumbersSmall",
	"HudSelectionNumbers",
	"HudSelectionText",
	"Marlett",
	"QuickInfo",
	"TargetID",
	"TargetIDSmall",
	"Trebuchet18",
	"Trebuchet24",
	"WeaponIcons",
	"WeaponIconsSelected",
	"WeaponIconsSmall",
	"DermaDefault",
	"DermaDefaultBold",
	"DermaLarge",
	"GModNotify",
	"ScoreboardDefault",
	"ScoreboardDefaultTitle",
	"GModToolName",
	"GModToolSubtitle",
	"GModToolHelp",
	"GModToolScreen",
	"ContentHeader",
	"GModWorldtip",
	"ContentHeader",
	"DefaultBold",
	"TabLarge",
	"Trebuchet22",
	"TraitorState",
	"TimeLeft",
	"HealthAmmo",
	"cool_small",
	"cool_large",
	"treb_small"
}


PART.ClassName = "text"
PART.Group = "effects"
PART.Icon = "icon16/text_align_center.png"

BUILDER:StartStorableVars()
	:SetPropertyGroup("generic")
		:PropertyOrder("Name")
		:PropertyOrder("Hide")
		:GetSet("Text", "")
		:GetSet("Font", "default", {enums = default_fonts})
		:GetSet("Size", 1, {editor_sensitivity = 0.25})
		:GetSet("DrawMode", "DrawTextOutlined", {enums = {
			["draw.SimpleTextOutlined 3D2D"] = "DrawTextOutlined",
			["draw.SimpleTextOutlined 2D"] = "DrawTextOutlined2D",
			["surface.DrawText"] = "SurfaceText"
		}})

	:SetPropertyGroup("text layout")
		:GetSet("HorizontalTextAlign", TEXT_ALIGN_CENTER, {enums = {["Left"] = "0", ["Center"] = "1", ["Right"] = "2"}})
		:GetSet("VerticalTextAlign", TEXT_ALIGN_CENTER, {enums = {["Center"] = "1", ["Top"] = "3", ["Bottom"] = "4"}})
		:GetSet("ConcatenateTextAndOverrideValue",false,{editor_friendly = "CombinedText"})
		:GetSet("TextPosition","Prefix", {enums = {["Prefix"] = "Prefix", ["Postfix"] = "Postfix"}},{editor_friendly = "ConcatenateMode"})

	:SetPropertyGroup("data source")
		:GetSet("TextOverride", "Text", {enums = {
			["Proxy value (DynamicTextValue)"] = "Proxy",
			["Text"] = "Text",
			["Health"] = "Health",
			["Maximum Health"] = "MaxHealth",
			["Armor"] = "Armor",
			["Maximum Armor"] = "MaxArmor",
			["Timerx"] = "Timerx",
			["CurTime"] = "CurTime",
			["RealTime"] = "RealTime",
			["Velocity"] = "Velocity",
			["Velocity Vector"] = "VelocityVector",
			["Position Vector"] = "PositionVector",
			["Owner Position Vector"] = "OwnerPositionVector",
			["Clip current Ammo"] = "Ammo",
			["Clip Size"] = "ClipSize",
			["Ammo Reserve"] = "AmmoReserve",
			["Sequence Name"] = "SequenceName",
			["Weapon Name"] = "Weapon",
			["Vehicle Class"] = "VehicleClass",
			["Model Name"] = "ModelName",
			["Model Path"] = "ModelPath",
			["Player Name"] = "PlayerName",
			["Player SteamID"] = "SteamID",
			["Map"] = "Map",
			["Ground Surface"] = "GroundSurface",
			["Ground Entity Class"] = "GroundEntityClass",
			["Players"] = "Players",
			["Max Players"] = "MaxPlayers",
			["Difficulty"] = "GameDifficulty"
		}})
		:GetSet("DynamicTextValue", 0)
		:GetSet("RoundingPosition", 2, {editor_onchange = function(self, num)
			return math.Round(num,0)
		end})

	:SetPropertyGroup("orientation")
		:PropertyOrder("AimPartName")
		:PropertyOrder("Bone")
		:PropertyOrder("Position")
	:SetPropertyGroup("appearance")
	BUILDER:GetSet("ForceAdditive",false, {description = "additive rendering for the surface.DrawText mode"})
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
	:SetPropertyGroup("CustomFont")
		:GetSet("CreateCustomFont",false, {description = "Tries to create a custom font.\nHeavily throttled as creating fonts is an expensive process.\nSupport is limited because of the fonts' supported features and the limits of Lua strings.\nFont names include those stored in your operating system. for example: Comic Sans MS, Ink Free"})
		:GetSet("CustomFont", "DermaDefault")
		:GetSet("FontSize", 13)
		:GetSet("FontWeight",500)
		:GetSet("FontBlurSize",0)
		:GetSet("FontScanLines",0)
		:GetSet("FontAntialias",true)
		:GetSet("FontUnderline",false)
		:GetSet("FontItalic",false)
		:GetSet("FontStrikeout",false)
		:GetSet("FontSymbol",false)
		:GetSet("FontRotary",false)
		:GetSet("Shadow",false)
		:GetSet("FontAdditive",false)
		:GetSet("FontOutline",false)
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
	self.UsedFont = str
	if not self.CreateCustomFont then
		if not pcall(surface_SetFont, str) then
			if #self.Font > 20 then

				self.lastwarn = self.lastwarn or CurTime()
				if self.lastwarn > CurTime() + 1 then
					pac.Message(Color(255,150,0),str.." Font not found! Could be custom font, trying again in 4 seconds!")
					self.lastwarn = CurTime()
				end
				timer.Simple(4, function()
					if not pcall(surface_SetFont, str) then
						pac.Message(Color(255,150,0),str.." Font still not found! Reverting to DermaDefault!")
						str = "DermaDefault"
						self.UsedFont = str
					end
				end)
			else
				timer.Simple(5, function()
					if not pcall(surface_SetFont, str) then
						pac.Message(Color(255,150,0),str.." Font still not found! Reverting to DermaDefault!")
						str = "DermaDefault"
						self.UsedFont = str
					end
				end)
			end
		end
	end
	self.Font = self.UsedFont
end
local lastfontcreationtime = 0
function PART:OnDraw()
	local pos, ang = self:GetDrawPosition()
	self:CheckFont()
	if not pcall(surface_SetFont, self.UsedFont) then return end

	local DisplayText = self.Text or ""
	if self.TextOverride == "Text" then goto DRAW end
	DisplayText = ""
	if self.TextOverride == "Health" then DisplayText = self:GetRootPart():GetOwner():Health()
	elseif self.TextOverride == "MaxHealth"	then
		DisplayText = self:GetRootPart():GetOwner():GetMaxHealth()
	elseif self.TextOverride == "Ammo" then
		DisplayText = IsValid(self:GetPlayerOwner():GetActiveWeapon()) and self:GetPlayerOwner():GetActiveWeapon():Clip1() or ""
	elseif self.TextOverride == "ClipSize" then
		DisplayText = IsValid(self:GetPlayerOwner():GetActiveWeapon()) and self:GetPlayerOwner():GetActiveWeapon():GetMaxClip1() or ""
	elseif self.TextOverride == "AmmoReserve" then
		DisplayText = IsValid(self:GetPlayerOwner():GetActiveWeapon()) and self:GetPlayerOwner():GetAmmoCount(self:GetPlayerOwner():GetActiveWeapon():GetPrimaryAmmoType()) or ""
	elseif self.TextOverride == "Armor" then
		DisplayText = self:GetPlayerOwner():Armor()
	elseif self.TextOverride == "MaxArmor" then
		DisplayText = self:GetPlayerOwner():GetMaxArmor()
	elseif self.TextOverride == "Timerx" then
		DisplayText = ""..math.Round(CurTime() - self.time,self.RoundingPosition)
	elseif self.TextOverride == "CurTime" then
		DisplayText = ""..math.Round(CurTime(),self.RoundingPosition)
	elseif self.TextOverride == "RealTime" then
		DisplayText = ""..math.Round(RealTime(),self.RoundingPosition)
	elseif self.TextOverride == "Velocity" then
		local ent = self:GetRootPart():GetOwner()
		DisplayText = math.Round(ent:GetVelocity():Length(),2)
	elseif self.TextOverride == "VelocityVector" then
		local ent = self:GetOwner() or self:GetRootPart():GetOwner()
		local vec = ent:GetVelocity()
		DisplayText = "("..math.Round(vec.x,self.RoundingPosition)..","..math.Round(vec.y,self.RoundingPosition)..","..math.Round(vec.z,self.RoundingPosition)..")"
	elseif self.TextOverride == "PositionVector" then
		local vec = self:GetDrawPosition()
		DisplayText = "("..math.Round(vec.x,self.RoundingPosition)..","..math.Round(vec.y,self.RoundingPosition)..","..math.Round(vec.z,self.RoundingPosition)..")"
	elseif self.TextOverride == "OwnerPositionVector" then
		local ent = self:GetRootPart():GetOwner()
		local vec = ent:GetPos()
		DisplayText = "("..math.Round(vec.x,self.RoundingPosition)..","..math.Round(vec.y,self.RoundingPosition)..","..math.Round(vec.z,self.RoundingPosition)..")"
	elseif self.TextOverride == "SequenceName" then
		DisplayText = self:GetRootPart():GetOwner():GetSequenceName(self:GetPlayerOwner():GetSequence())
	elseif self.TextOverride == "PlayerName" then
		DisplayText = self:GetPlayerOwner():GetName()
	elseif self.TextOverride == "SteamID" then
		DisplayText = self:GetPlayerOwner():SteamID()
	elseif self.TextOverride == "ModelName" then
		local path = self:GetRootPart():GetOwner():GetModel() or "null"
		path = string.Split(path, "/")[#string.Split(path, "/")]
		path = string.gsub(path,".mdl","")
		DisplayText = path
	elseif self.TextOverride == "ModelPath" then
		DisplayText = self:GetPlayerOwner():GetModel()
	elseif self.TextOverride == "Map" then
		DisplayText = game.GetMap()
	elseif self.TextOverride == "GroundSurface" then
		local trace = util.TraceLine( {
			start = self:GetRootPart():GetOwner():GetPos() + Vector( 0, 0, 30),
			endpos = self:GetRootPart():GetOwner():GetPos() + Vector( 0, 0, -60 ),
			filter = function(ent)
				if ent == self:GetRootPart():GetOwner() or ent == self:GetPlayerOwner() then return false else return true end
			end
		})
		if trace.Hit then
			if trace.MatType == MAT_ANTLION then DisplayText = "Antlion"
			elseif trace.MatType == MAT_BLOODYFLESH then DisplayText = "Bloody Flesh"
			elseif trace.MatType == MAT_CONCRETE then DisplayText = "Concrete"
			elseif trace.MatType == MAT_DIRT then DisplayText = "Dirt"
			elseif trace.MatType == MAT_EGGSHELL then DisplayText = "Egg Shell"
			elseif trace.MatType == MAT_FLESH then DisplayText = "Flesh"
			elseif trace.MatType == MAT_GRATE then DisplayText = "Grate"
			elseif trace.MatType == MAT_ALIENFLESH then DisplayText = "Alien Flesh"
			elseif trace.MatType == MAT_CLIP then DisplayText = "Clip"
			elseif trace.MatType == MAT_SNOW then DisplayText = "Snow"
			elseif trace.MatType == MAT_PLASTIC then DisplayText = "Plastic"
			elseif trace.MatType == MAT_METAL then DisplayText = "Metal"
			elseif trace.MatType == MAT_SAND then DisplayText = "Sand"
			elseif trace.MatType == MAT_FOLIAGE then DisplayText = "Foliage"
			elseif trace.MatType == MAT_COMPUTER then DisplayText = "Computer"
			elseif trace.MatType == MAT_SLOSH then DisplayText = "Slime"
			elseif trace.MatType == MAT_TILE then DisplayText = "Tile"
			elseif trace.MatType == MAT_GRASS then DisplayText = "Grass"
			elseif trace.MatType == MAT_VENT then DisplayText = "Grass"
			elseif trace.MatType == MAT_WOOD then DisplayText = "Wood"
			elseif trace.MatType == MAT_DEFAULT then DisplayText = "Default"
			elseif trace.MatType == MAT_GLASS then DisplayText = "Glass"
			elseif trace.MatType == MAT_WARPSHIELD then DisplayText = "Warp Shield"
			else DisplayText = "Other Surface" end
		else DisplayText = "Air" end
	elseif self.TextOverride == "GroundEntityClass" then
		local trace = util.TraceLine( {
			start = self:GetRootPart():GetOwner():GetPos() + Vector( 0, 0, 30),
			endpos = self:GetRootPart():GetOwner():GetPos() + Vector( 0, 0, -60 ),
			filter = function(ent)
				if ent == self:GetRootPart():GetOwner() or ent == self:GetPlayerOwner() then return false else return true end
			end
		})
		if trace.Hit then
			DisplayText = trace.Entity:GetClass()
		end
	elseif self.TextOverride == "GameDifficulty" then
		local diff = game.GetSkillLevel()
		if diff == 1 then DisplayText = "Easy"
		elseif diff == 2 then DisplayText = "Normal"
		elseif diff == 3 then DisplayText = "Hard" end
	elseif self.TextOverride == "Players" then
		DisplayText = #player.GetAll()
	elseif self.TextOverride == "MaxPlayers" then
		DisplayText = game.MaxPlayers()
	elseif self.TextOverride == "Weapon" then
		if IsValid(self:GetPlayerOwner():GetActiveWeapon()) then
			DisplayText = self:GetPlayerOwner():GetActiveWeapon():GetClass()
		else DisplayText = "unarmed" end
	elseif self.TextOverride == "VehicleClass" then
		if IsValid(self:GetPlayerOwner():GetVehicle()) then
			DisplayText = self:GetPlayerOwner():GetVehicle():GetClass()
		else DisplayText = "not driving" end
	elseif self.TextOverride == "Proxy" then
		DisplayText = ""..math.Round(self.DynamicTextValue,self.RoundingPosition)
	end

	if self.ConcatenateTextAndOverrideValue then
		if self.TextPosition == "Prefix" then
			DisplayText = ""..self.Text..DisplayText
		elseif self.TextPosition == "Postfix" then
			DisplayText = ""..DisplayText..self.Text
		end
	end

	::DRAW::

	if DisplayText ~= "" then
		if self.DrawMode == "DrawTextOutlined" then
			cam_Start3D(EyePos(), EyeAngles())
				cam_Start3D2D(pos, ang, self.Size)
				local oldState = DisableClipping(true)

				draw_SimpleTextOutlined(DisplayText, self.UsedFont, 0,0, self.ColorC, self.HorizontalTextAlign,self.VerticalTextAlign, self.Outline, self.OutlineColorC)
				render_CullMode(1) -- MATERIAL_CULLMODE_CW

				draw_SimpleTextOutlined(DisplayText, self.UsedFont, 0,0, self.ColorC, self.HorizontalTextAlign,self.VerticalTextAlign, self.Outline, self.OutlineColorC)
				render_CullMode(0) -- MATERIAL_CULLMODE_CCW

				DisableClipping(oldState)
				cam_End3D2D()
			cam_End3D()
			cam_Start3D(EyePos(), EyeAngles())
				cam_Start3D2D(pos, ang, self.Size)
				local oldState = DisableClipping(true)

				draw.SimpleText(DisplayText, self.UsedFont, 0,0, self.ColorC, self.HorizontalTextAlign,self.VerticalTextAlign, self.Outline, self.OutlineColorC)
				render_CullMode(1) -- MATERIAL_CULLMODE_CW

				draw.SimpleText(DisplayText, self.UsedFont, 0,0, self.ColorC, self.HorizontalTextAlign,self.VerticalTextAlign, self.Outline, self.OutlineColorC)
				render_CullMode(0) -- MATERIAL_CULLMODE_CCW

				DisableClipping(oldState)
				cam_End3D2D()
			cam_End3D()
		elseif self.DrawMode == "SurfaceText" or self.DrawMode == "DrawTextOutlined2D" then
			hook.Add("HUDPaint", "pac.DrawText"..self.UniqueID, function()
				if not pcall(surface_SetFont, self.UsedFont) then return end
				self:SetFont(self.UsedFont)

				surface.SetTextColor(self.Color.r, self.Color.g, self.Color.b, 255*self.Alpha)

				surface.SetFont(self.UsedFont)
				local pos2d = self:GetDrawPosition():ToScreen()
				local w, h = surface.GetTextSize(DisplayText)

				if self.HorizontalTextAlign == 0 then --left
					pos2d.x = pos2d.x
				elseif self.HorizontalTextAlign == 1 then --center
					pos2d.x = pos2d.x - w/2
				elseif self.HorizontalTextAlign == 2 then --right
					pos2d.x = pos2d.x - w
				end

				if self.VerticalTextAlign == 1 then --center
					pos2d.y = pos2d.y - h/2
				elseif self.VerticalTextAlign == 3 then --top
					pos2d.y = pos2d.y
				elseif self.VerticalTextAlign == 4 then --bottom
					pos2d.y = pos2d.y - h
				end

				surface.SetTextPos(pos2d.x, pos2d.y)
				local dist = (EyePos() - self:GetWorldPosition()):Length()
				local fadestartdist = 200
				local fadeenddist = 1000
				if fadestartdist == 0 then fadestartdist = 0.1 end
				if fadeenddist == 0 then fadeenddist = 0.1 end

				if fadestartdist > fadeenddist then
					local temp = fadestartdist
					fadestartdist = fadeenddist
					fadeenddist = temp
				end

				if dist < fadeenddist then
					if dist < fadestartdist then
						if self.DrawMode == "DrawTextOutlined2D" then
							draw.SimpleTextOutlined(DisplayText, self.UsedFont, pos2d.x, pos2d.y, Color(self.Color.r,self.Color.g,self.Color.b,255*self.Alpha), TEXT_ALIGN_TOP, TEXT_ALIGN_LEFT, self.Outline, Color(self.OutlineColor.r,self.OutlineColor.g,self.OutlineColor.b, 255*self.OutlineAlpha))
						elseif self.DrawMode == "SurfaceText" then
							surface.DrawText(DisplayText, self.ForceAdditive)
						end

					else
						local fade = math.pow(math.Clamp(1 - (dist-fadestartdist)/fadeenddist,0,1),3)

						if self.DrawMode == "DrawTextOutlined2D" then
							draw.SimpleTextOutlined(DisplayText, self.UsedFont, pos2d.x, pos2d.y, Color(self.Color.r,self.Color.g,self.Color.b,255*self.Alpha*fade), TEXT_ALIGN_TOP, TEXT_ALIGN_LEFT, self.Outline, Color(self.OutlineColor.r,self.OutlineColor.g,self.OutlineColor.b, 255*self.OutlineAlpha*fade))
						elseif self.DrawMode == "SurfaceText" then
							surface.SetTextColor(self.Color.r * fade, self.Color.g * fade, self.Color.b * fade)
							surface.DrawText(DisplayText, true)
						end

					end
				end
			end)
		end
		if self.DrawMode == "DrawTextOutlined" then
			hook.Remove("HUDPaint", "pac.DrawText"..self.UniqueID)
		end
	else hook.Remove("HUDPaint", "pac.DrawText"..self.UniqueID) end
end

function PART:Initialize()
	self:TryCreateFont()
end

function PART:CheckFont()
	if self.CreateCustomFont then
		lastfontcreationtime = lastfontcreationtime or 0
		if lastfontcreationtime + 3 <= CurTime() then
			self:TryCreateFont()
		end
	else
		self:SetFont(self.Font)
	end

end

function PART:TryCreateFont()
	if "Font_"..self.CustomFont.."_"..math.Round(self.FontSize,3).."_"..self.UniqueID == self.lastcustomfont then
		self.UsedFont = "Font_"..self.CustomFont.."_"..math.Round(self.FontSize,3).."_"..self.UniqueID
		return
	end
	if self.CreateCustomFont then
		local newfont = "Font_"..self.CustomFont.."_"..math.Round(self.FontSize,3).."_"..self.UniqueID
		surface.CreateFont( newfont, {
			font = self.CustomFont, --  Use the font-name which is shown to you by your operating system Font Viewer, not the file name
			extended = self.Extended,
			size = self.FontSize,
			weight = self.Weight,
			blursize = self.BlurSize,
			scanlines = self.ScanLines,
			antialias = self.Antialias,
			underline = self.Underline,
			italic = self.Italic,
			strikeout = self.Strikeout,
			symbol = self.Symbol,
			rotary = self.Rotary,
			shadow = self.Shadow,
			additive = self.Additive,
			outline = self.Outline,
		} )
		self:SetFont(newfont)
		self.lastcustomfont = newfont
		lastfontcreationtime = CurTime()
	end
end

function PART:OnShow()
	self.time = CurTime()
end

function PART:OnHide()
	hook.Remove("HUDPaint", "pac.DrawText"..self.UniqueID)
end
function PART:OnRemove()
	hook.Remove("HUDPaint", "pac.DrawText"..self.UniqueID)
end
function PART:SetText(str)
	self.Text = str
end

BUILDER:Register()
