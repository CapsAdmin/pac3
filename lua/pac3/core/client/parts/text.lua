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

local draw_distance = CreateClientConVar("pac_limit_text_2d_draw_distance", "1000", true, false, "How far to see other players' text parts using 2D modes. They will start fading out 200 units before this distance.")


net.Receive("pac_chat_typing_mirror_broadcast", function(len)
	local text = net.ReadString()
	local ply = net.ReadEntity()
	ply.pac_mirrored_chat_text = text
end)

local TTT_fonts = {
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

local sandbox_fonts = {
	"GModToolName",
	"GModToolSubtitle",
	"GModToolHelp",
	"GModToolScreen",
	"ContentHeader",
	"GModWorldtip",
	"ContentHeader",
}

--all "de facto" usables:
--base gmod fonts
--sandbox OR TTT gamemode fonts
--created fonts that passed all checks
local usable_fonts = {}

--all base usable:
--base gmod fonts
--sandbox OR TTT gamemode fonts
local included_fonts = {}


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
}
 
if engine.ActiveGamemode() == "sandbox" then
	for i,v in ipairs(sandbox_fonts) do
		table.insert(default_fonts,v)
	end
elseif engine.ActiveGamemode() == "ttt" then
	for i,v in ipairs(TTT_fonts) do
		table.insert(default_fonts,v)
	end
end

for i,v in ipairs(default_fonts) do
	usable_fonts[v] = true
	default_fonts[v] = v --I want string key lookup...
	included_fonts[v] = v
end

local gmod_basefonts = {
	--key is ttf filename, value is the nice title
	["akbar"] = "Akbar",
	["coolvetica"] = "Coolvetica",
	["csd"] = "csd",
	["Roboto-Black"] = "Roboto Black",
	["Roboto-BlackItalic"] = "Roboto Black Italic",
	["Roboto-Bold"] = "Roboto Bold",
	["Roboto-BoldCondensed"] = "Roboto Bold Condensed",
	["Roboto-BoldCondensedItalic"] = "Roboto Bold Condensed Italic",
	["Roboto-Condensed"] = "Roboto Condensed",
	["Roboto-CondensedItalic"] = "Roboto Condensed Italic",
	["Roboto-Italic"] = "Roboto Italic",
	["Roboto-Light"] = "Roboto Light",
	["Roboto-LightItalic"] = "Roboto Light Italic",
	["Roboto-Medium"] = "Roboto Medium",
	["Roboto-MediumItalic"] = "Roboto Medium Italic",
	["Roboto-Regular"] = "Roboto Regular",
	["Roboto-Thin"] = "Roboto Thin",
	["Roboto-Thin"] = "Roboto Thin Italic",
	["Tahoma"] = "Tahoma"
}

local buildable_basefonts = {}
--create some fonts
for k,v in pairs(gmod_basefonts) do
	buildable_basefonts[v] = v
	local newfont = v .. "_30"
	surface.CreateFont(newfont, {
		font = v,
		size = 30
	})
	table.insert(default_fonts, newfont)
	usable_fonts[newfont] = true
end


PART.ClassName = "text"
PART.Group = "effects"
PART.Icon = "icon16/text_align_center.png"

BUILDER:StartStorableVars()
	:SetPropertyGroup("generic")
		:PropertyOrder("Name")
		:PropertyOrder("Hide")
		:GetSet("Text", "", {editor_panel = "generic_multiline"})
		:GetSet("Font", "DermaDefault", {enums = default_fonts})
		:GetSet("Size", 1, {editor_sensitivity = 0.25})
		:GetSet("DrawMode", "DrawTextOutlined", {enums = {
			["draw.SimpleTextOutlined 3D2D"] = "DrawTextOutlined",
			["draw.SimpleTextOutlined 2D"] = "DrawTextOutlined2D",
			["surface.DrawText"] = "SurfaceText",
			["draw.DrawText"] = "DrawDrawText"
		}})

	:SetPropertyGroup("text layout")
		:GetSet("HorizontalTextAlign", TEXT_ALIGN_CENTER, {enums = {["Left"] = "0", ["Center"] = "1", ["Right"] = "2"}})
		:GetSet("VerticalTextAlign", TEXT_ALIGN_CENTER, {enums = {["Center"] = "1", ["Top"] = "3", ["Bottom"] = "4"}})
		:GetSet("ConcatenateTextAndOverrideValue",false,{editor_friendly = "CombinedText"})
		:GetSet("TextPosition","Prefix", {enums = {["Prefix"] = "Prefix", ["Postfix"] = "Postfix"}, description = "where the base text will be relative to the data-sourced text. this only applies when using Combined Text mode"})
		:GetSet("SentenceNewlines", false, {description = "With the punctuation marks . ! ? make a newline. Newlines only work with DrawDrawText mode.\nThis variable is useful for the chat modes since you can't put newlines in chat.\nBut if you're not using these, you might as well use the multiline text editor on the main text's [...] button"})
		:GetSet("Truncate", false, {description = "whether to cut the string off until a certain position. This can be used with proxies to gradually write the text.\nSkip Characters should normally be spaces and punctuation\nTruncate Words splits into words"})
		:GetSet("TruncateWords", false, {description = "whether to cut the string off until a certain position. This can be used with proxies to gradually write the text"})
		:GetSet("TruncateSkipCharacters", "", {description = "Characters to skip during truncation, or to split into words with the TruncateWords mode.\nNormally it could be a space, but if you want to split your text by lines (i.e. write one whole line at a time), write the escape character \"\\n\""})
		:GetSet("TruncatePosition", 0, {editor_onchange = function(self, val) return math.floor(val) end})
		:GetSet("VectorBrackets", "()")
		:GetSet("VectorSeparator", ",")
		:GetSet("UseBracketsOnNonVectors", false)
		:GetSet("ForceNewline", false, {description = "manually draw newlines"})
		:GetSet("LineSpacing", 1)

	:SetPropertyGroup("wrap")
		:GetSet("Wrap", false, {description = "force newline if text exceeds set width or there is a newline character"})
		:GetSet("WrapWidth", 500, {editor_round = true, editor_onchange = function(self, val) return math.floor(val) end, description = "text size is dependent on font. for the 3D2D text, size doesn't matter"})
		:GetSet("WrapByWords", false, {description = "split by spaces after splitting by newline characters"})

	:SetPropertyGroup("data source")
		:GetSet("TextOverride", "Text", {enums = {
			["Proxy value (DynamicTextValue)"] = "Proxy",
			["Proxy vector (DynamicVectorValue)"] = "ProxyVector",
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
			["Difficulty"] = "GameDifficulty",
			["Chat Being Typed"] = "ChatTyping",
			["Last Chat Sent"] = "ChatSent",
		}})
		:GetSet("DynamicTextValue", 0)
		:GetSet("DynamicVectorValue", Vector(0,0,0))
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
		:GetSet("CustomFont", "DermaDefault", {enums = buildable_basefonts})
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
	if string.find(self.Text, "\n") then
		if self.DrawMode == "DrawDrawText" then return "multiline text" else return string.Replace(self.Text, "\n", "") end
	end

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

function PART:SetTruncateSkipCharacters(str)
	self.TruncateSkipCharacters = str
	if str == "" then self.TruncateSkipCharacters_tbl = nil return end
	self.TruncateSkipCharacters_tbl = {}
	for i=1,#str,1 do
		local char = str[i]
		if char == [[\]] then
			if str[i+1] == "n" then self.TruncateSkipCharacters_tbl["\n"] = true
			elseif str[i+1] == "t" then self.TruncateSkipCharacters_tbl["\t"] = true
			elseif str[i+1] == [[\]] then self.TruncateSkipCharacters_tbl["\\"] = true
			end
		elseif str[i-1] ~= [[\]] then
			self.TruncateSkipCharacters_tbl[char] = true
		end
	end
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

local function GetReasonBadFont_At_CreationTime(str)
	local reason
	if #str < 20 then
		if not included_fonts[str] then reason = str .. " is not a font that exists" end
		if engine.ActiveGamemode() ~= "sandbox" then
			if table.HasValue(sandbox_fonts,str) then
				reason = str .. " is a sandbox-exclusive font not available in the gamemode " .. engine.ActiveGamemode()
			end
		end
		if engine.ActiveGamemode() ~= "ttt" then
			if table.HasValue(TTT_fonts,str) then
				reason = str .. " is a TTT-exclusive font not available in the gamemode " .. engine.ActiveGamemode()
			end
		end
	else --standard part UID length
		if #str > 31 then
			reason = "you cannot create fonts with the base font being longer than 31 letters"
		end
	end
	if string.find(str, "http") then
		reason = "urls are not supported"
	end
	return reason
end

local function GetReasonBadFont_At_UseTime(str)
	local reason
	if #str < 20 then
		if not included_fonts[str] then reason = str .. " is not a font that exists" end
		if engine.ActiveGamemode() ~= "sandbox" then
			if table.HasValue(sandbox_fonts,str) then
				reason = str .. " is a sandbox-exclusive font not available in the gamemode " .. engine.ActiveGamemode()
			end
		end
		if engine.ActiveGamemode() ~= "ttt" then
			if table.HasValue(TTT_fonts,str) then
				reason = str .. " is a TTT-exclusive font not available in the gamemode " .. engine.ActiveGamemode()
			end
		end
	else --standard part UID length
		reason = str .. " is possibly a pac custom font from another text part but it's not guaranteed to be created right now\nor maybe it doesn't exist"
	end
	if string.find(str, "http") then
		reason = "urls are not supported"
	end
	return reason
end


function PART:CheckFontBuildability(str)
	if string.find(str, "http") then
		return false, "urls are not supported"
	end
	if #str > 31 then return false, "base font is too long" end
	if buildable_basefonts[str] then return true, "base font recognized from gmod" end
	if included_fonts[str] then return true, "default font" end
	return false, "nonexistent base font"
end


--before using a font, we need to check if it exists
--font creation time should mark them
function PART:SetFont(str)
	self.request_line_recalculation = true
	self.Font = str
	self:SetError()
	self:CheckFont()
end


local lastfontcreationtime = 0
function PART:CheckFont()
	if self.CreateCustomFont then
		if not self:CheckFontBuildability(self.CustomFont) then
			self.UsedFont = "DermaDefault"
			self:SetError(GetReasonBadFont_At_UseTime(self.CustomFont) .. "\nreverting to " .. self.UsedFont)
		else
			self:TryCreateFont()
		end
	else
		if usable_fonts[self.Font] then
			self.UsedFont = self.Font
		else
			self.UsedFont = "DermaDefault"
			self:SetError(GetReasonBadFont_At_UseTime(self.Font) .. "\nreverting to " .. self.UsedFont)
		end
	end
end

function PART:SetCustomFont(str)
	self.CustomFont = str
	local buildable, reason = self:CheckFontBuildability(str)
	--suppress if not requesting custom font, and if name is too long
	if buildable then self:TryCreateFont() else return end
	if self:GetPlayerOwner() == pac.LocalPlayer then
		if not self.pace_properties then return end
		if pace.current_part == self then
			local pnl = self["pac_property_label_CustomFont"]
			if IsValid(pnl) then
				if not included_fonts[str] and not default_fonts[str] then
					--pnl:SetValue("")
					pnl:Clear()
					pnl:CreateAlternateLabel("bad font", true)
					pnl:SetTooltip(GetReasonBadFont_At_CreationTime(str))
				else
					pace.PopulateProperties(self)
				end
			end
		end
		
	end
end

function PART:GetBrackets()
	local bracket1 = ""
	local bracket2 = ""
	local bracks = tostring(self.VectorBrackets)
	if #bracks % 2 == 1 then
		bracket1 = string.sub(bracks,1, (#bracks + 1) / 2) or ""
		bracket2 = string.sub(bracks, (#bracks + 1) / 2, #bracks) or ""
	else
		bracket1 = string.sub(bracks,1, #bracks / 2) or ""
		bracket2 = string.sub(bracks, #bracks / 2 + 1, #bracks) or ""
	end
	return bracket1, bracket2
end

function PART:GetNiceVector(vec)
	local bracket1, bracket2 = self:GetBrackets()
	return bracket1..math.Round(vec.x,self.RoundingPosition)..self.VectorSeparator..math.Round(vec.y,self.RoundingPosition)..self.VectorSeparator..math.Round(vec.z,self.RoundingPosition)..bracket2
end


function PART:OnDraw()
	local pos, ang = self:GetDrawPosition()

	self:CheckFont()
	if not self.UsedFont then self.UsedFont = self.Font end
	if not usable_fonts[self.UsedFont] then return end

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
		DisplayText = self:GetNiceVector(ent:GetVelocity())
	elseif self.TextOverride == "PositionVector" then
		local vec = self:GetDrawPosition()
		DisplayText = self:GetNiceVector(vec)
	elseif self.TextOverride == "OwnerPositionVector" then
		local ent = self:GetRootPart():GetOwner()
		DisplayText = self:GetNiceVector(ent:GetPos())
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
	elseif self.TextOverride == "ProxyVector" then
		DisplayText = self:GetNiceVector(self.DynamicVectorValue)
	elseif self.TextOverride == "ChatTyping" then
		if self:GetPlayerOwner() == pac.LocalPlayer and not pac.broadcast_chat_typing then
			pac.AddHook("ChatTextChanged", "broadcast_chat_typing", function(text)
				net.Start("pac_chat_typing_mirror")
				net.WriteString(text)
				net.SendToServer()
			end)
			pac.AddHook("FinishChat", "end_chat_typing", function(text)
				net.Start("pac_chat_typing_mirror")
				net.WriteString("")
				net.SendToServer()
			end)
			pac.broadcast_chat_typing = true
		end
		DisplayText = self:GetPlayerOwner().pac_mirrored_chat_text or ""
	elseif self.TextOverride == "ChatSent" then
		if self:GetPlayerOwner().pac_say_event then
			DisplayText = self:GetPlayerOwner().pac_say_event.str
		else
			DisplayText = ""
		end
	end

	if not string.find(self.TextOverride, "Vector") then
		if self.UseBracketsOnNonVectors then
			local bracket1, bracket2 = self:GetBrackets()
			DisplayText = bracket1 .. DisplayText .. bracket2
		end
	end

	if self.ConcatenateTextAndOverrideValue then
		if self.TextPosition == "Prefix" then
			DisplayText = ""..self.Text..DisplayText
		elseif self.TextPosition == "Postfix" then
			DisplayText = ""..DisplayText..self.Text
		end
	end

	::DRAW::
	if self.Truncate then
		
		if self.TruncateSkipCharacters_tbl then
			local temp_string = ""
			local char_pos = 1
			local temp_chunk = ""
			for i=1,#DisplayText,1 do
				local char = DisplayText[i]
				local escaped_char = false
				if char == "\n" or char == "\t" then escaped_char = true end
				if not self.TruncateWords then --char by char, add to the string only if it's a non-skip character
					if char_pos > self.TruncatePosition then break end
					if self.TruncateSkipCharacters_tbl[char] or escaped_char then
						temp_chunk = temp_chunk .. char
					else
						temp_string = temp_string .. temp_chunk .. char
						temp_chunk = ""
						char_pos = char_pos + 1
					end
				else --word by word, add to the string once i reaches the end or reaches a boundary
					if char_pos > self.TruncatePosition then break end
					if not self.TruncateSkipCharacters_tbl[char] and (self.TruncateSkipCharacters_tbl[DisplayText[i+1]] or i == #DisplayText) then
						temp_string = string.sub(DisplayText,0,i)
						char_pos = char_pos + 1
					end
				end
			end
			DisplayText = temp_string
		else
			DisplayText = string.sub(DisplayText, 0, self.TruncatePosition)
		end
	end

	if self.SentenceNewlines then
		DisplayText = string.Replace(DisplayText,". ",".\n")
		DisplayText = string.Replace(DisplayText,"! ","!\n")
		DisplayText = string.Replace(DisplayText,"? ","?\n")
	end

	if self.Wrap or self.ForceNewline then
		if (self.lines == nil) or (self.previous_str ~= DisplayText) or self.request_line_recalculation then
			self.lines = self:WrapString(DisplayText, self.WrapWidth)
		end
	end

	if DisplayText ~= "" then
		local w, h = surface.GetTextSize(DisplayText)
		if not w or not h then return end

		if self.DrawMode == "DrawTextOutlined" then
			local y = 0
			local function drawtext(str)
				cam_Start3D(EyePos(), EyeAngles())
					if self.IgnoreZ then cam.IgnoreZ(true) end
					cam_Start3D2D(pos, ang, self.Size)
					local oldState = DisableClipping(true)
					
					draw_SimpleTextOutlined(str, self.UsedFont, 0,y, self.ColorC, self.HorizontalTextAlign,self.VerticalTextAlign, self.Outline, self.OutlineColorC)
					render_CullMode(1) -- MATERIAL_CULLMODE_CW

					draw_SimpleTextOutlined(str, self.UsedFont, 0,y, self.ColorC, self.HorizontalTextAlign,self.VerticalTextAlign, self.Outline, self.OutlineColorC)
					render_CullMode(0) -- MATERIAL_CULLMODE_CCW

					DisableClipping(oldState)
					cam_End3D2D()
					cam.IgnoreZ(false)
				cam_End3D()
				cam_Start3D(EyePos(), EyeAngles())
					if self.IgnoreZ then cam.IgnoreZ(true) end
					cam_Start3D2D(pos, ang, self.Size)
					local oldState = DisableClipping(true)

					draw.SimpleText(str, self.UsedFont, 0,y, self.ColorC, self.HorizontalTextAlign,self.VerticalTextAlign, self.Outline, self.OutlineColorC)
					render_CullMode(1) -- MATERIAL_CULLMODE_CW

					draw.SimpleText(str, self.UsedFont, 0,y, self.ColorC, self.HorizontalTextAlign,self.VerticalTextAlign, self.Outline, self.OutlineColorC)
					render_CullMode(0) -- MATERIAL_CULLMODE_CCW

					DisableClipping(oldState)
					cam_End3D2D()
					cam.IgnoreZ(false)
				cam_End3D()
				if self.IgnoreZ then cam.IgnoreZ(false) end
			end

			if not self.Wrap and not self.ForceNewline then
				drawtext(DisplayText)
			else
				if (self.lines == nil) or (self.previous_str ~= DisplayText) then
					self.lines = self:WrapString(DisplayText, self.WrapWidth)
				end
				for i, str in ipairs(self.lines) do
					drawtext(str)
					local w, h = surface.GetTextSize(str)
					if h then y = y + self.LineSpacing*h end
				end
			end
			
		elseif self.DrawMode == "SurfaceText" or self.DrawMode == "DrawTextOutlined2D" or self.DrawMode == "DrawDrawText" then
			pac.AddHook("HUDPaint", "pac.DrawText"..self.UniqueID, function()
				surface.SetFont(self.UsedFont)

				surface.SetTextColor(self.Color.r, self.Color.g, self.Color.b, 255*self.Alpha)


				local pos2d = self:GetDrawPosition():ToScreen()
				local pos2d_original = table.Copy(pos2d)

				local function drawtext(str)
					local w, h = surface.GetTextSize(str)
					if not h or not w then return end

					local X = pos2d.x
					local Y = pos2d.y

					if self.HorizontalTextAlign == 0 then --left
						X = pos2d.x
					elseif self.HorizontalTextAlign == 1 then --center
						X = pos2d.x - w/2
					elseif self.HorizontalTextAlign == 2 then --right
						X = pos2d.x - w
					end

					if self.VerticalTextAlign == 1 then --center
						Y = pos2d.y - h/2
					elseif self.VerticalTextAlign == 3 then --top
						Y = pos2d.y
					elseif self.VerticalTextAlign == 4 then --bottom
						Y = pos2d.y - h
					end

					surface.SetTextPos(X, Y)
					local dist = (pac.EyePos - self:GetWorldPosition()):Length()

					--clamp down the part's requested values with the viewer client's cvar
					local fadestartdist = math.max(draw_distance:GetInt() - 200,0)
					local fadeenddist = math.max(draw_distance:GetInt(),0)

					if dist < fadeenddist then
						if dist < fadestartdist then
							if self.DrawMode == "DrawTextOutlined2D" then
								draw.SimpleTextOutlined(str, self.UsedFont, X, Y, Color(self.Color.r,self.Color.g,self.Color.b,255*self.Alpha), TEXT_ALIGN_TOP, TEXT_ALIGN_LEFT, self.Outline, Color(self.OutlineColor.r,self.OutlineColor.g,self.OutlineColor.b, 255*self.OutlineAlpha))
							elseif self.DrawMode == "SurfaceText" then
								surface.DrawText(str, self.ForceAdditive)
							elseif self.DrawMode == "DrawDrawText" then
								draw.DrawText(str, self.UsedFont, pos2d_original.x, Y, Color(self.Color.r,self.Color.g,self.Color.b,255*self.Alpha), self.HorizontalTextAlign)
							end
						else
							local fade = math.pow(math.Clamp(1 - (dist-fadestartdist)/math.max(fadeenddist - fadestartdist,0.1),0,1),3)
							if self.DrawMode == "DrawTextOutlined2D" then
								draw.SimpleTextOutlined(str, self.UsedFont, X, Y, Color(self.Color.r,self.Color.g,self.Color.b,255*self.Alpha*fade), TEXT_ALIGN_TOP, TEXT_ALIGN_LEFT, self.Outline, Color(self.OutlineColor.r,self.OutlineColor.g,self.OutlineColor.b, 255*self.OutlineAlpha*fade))
							elseif self.DrawMode == "SurfaceText" then
								surface.SetTextColor(self.Color.r * fade, self.Color.g * fade, self.Color.b * fade)
								surface.DrawText(str, true)
							elseif self.DrawMode == "DrawDrawText" then
								draw.DrawText(str, self.UsedFont, X, Y, Color(self.Color.r,self.Color.g,self.Color.b,255*self.Alpha*fade), TEXT_ALIGN_LEFT)
							end

						end
					end
				end

				if not self.Wrap and not self.ForceNewline then
					drawtext(DisplayText)
				else
					if (self.lines == nil) or (self.previous_str ~= DisplayText) then
						self.lines = self:WrapString(DisplayText, self.WrapWidth)
					end
					for i, str in ipairs(self.lines) do
						drawtext(str)
						local w, h = surface.GetTextSize(str)
						if h then pos2d.y = pos2d.y + self.LineSpacing*h end
					end
				end
			end)
		end
		if self.DrawMode == "DrawTextOutlined" then
			pac.RemoveHook("HUDPaint", "pac.DrawText"..self.UniqueID)
		end
	else pac.RemoveHook("HUDPaint", "pac.DrawText"..self.UniqueID) end
	self.previous_str = DisplayText
end

function PART:Initialize()
	self.lines = nil
	self.previous_str = ""
	if self.Font == "default" then self.Font = "DermaDefault" end
	self:TryCreateFont()
	self.anotherwarning = false
end


function PART:TryCreateFont(force_refresh)
	local newfont = "Font_"..self.CustomFont.."_"..math.Round(self.FontSize,3).."_"..self.UniqueID
	if self.CreateCustomFont then
		if usable_fonts[newfont] then self.UsedFont = newfont self.Font = newfont return end
		local buildable, reason = self:CheckFontBuildability(self.CustomFont)
		--if reason == "default font" then self.CustomFont = "default" end
		if not buildable then
			return
		end
		if lastfontcreationtime + 2 > CurTime() then return end
		surface.CreateFont( newfont, {
			font = self.CustomFont, --  Use the font-name which is shown to you by your operating system Font Viewer, not the file name
			extended = self.Extended,
			size = self.FontSize,
			weight = self.FontWeight,
			blursize = self.FontBlurSize,
			scanlines = self.FontScanLines,
			antialias = self.FontAntialias,
			underline = self.FontUnderline,
			italic = self.FontItalic,
			strikeout = self.FontStrikeout,
			symbol = self.FontSymbol,
			rotary = self.FontRotary,
			shadow = self.Shadow,
			additive = self.FontAdditive,
			outline = self.Outline,
		} )
		lastfontcreationtime = CurTime()
		--base fonts are ok to derive from
		usable_fonts[newfont] = true
		self.UsedFont = newfont
		self.Font = newfont
	end
end

function PART:OnShow()
	self.time = CurTime()
end

function PART:OnHide()
	pac.RemoveHook("HUDPaint", "pac.DrawText"..self.UniqueID)
end

function PART:OnRemove()
	pac.RemoveHook("HUDPaint", "pac.DrawText"..self.UniqueID)
	local remains_chat_text_part = false
	for i,v in ipairs(pac.GetLocalParts()) do
		if v.ClassName == "text" then
			if v.TextOverride == "ChatTyping" then
				remains_chat_text_part = true
			end
		end
	end
	if not remains_chat_text_part then
		pac.RemoveHook("ChatTextChanged", "broadcast_chat_typing")
		pac.broadcast_chat_typing = false
	end
end
function PART:SetText(str)
	self.request_line_recalculation = true
	self.Text = str
end

function PART:SetWrapWidth(num)
	self.WrapWidth = math.Round(num,0)
	self.request_line_recalculation = true
end
function PART:SetWrapByWords(b)
	self.WrapByWords = b
	self.request_line_recalculation = true
end
function PART:SetForceNewline(b)
	self.ForceNewline = b
	self.request_line_recalculation = true
end

local font = ""
local wrap_calculation_time = 0
local frame_reset = 0
function PART:WrapString(str, max_w, font_override)
	local stime = SysTime()
	if self.UsedFont == "" then self.previous_str = nil return {} end
	if not self.ForceNewline and #str > 5000 then self.previous_str = nil return {} end
	if stime < wrap_calculation_time then return self.lines or {} end --rate limit
	if font_override then
		surface.SetFont(font_override)
	else
		surface.SetFont(self.UsedFont)
	end
	
	local lines = string.Split(str, "\n")
	local lines_pushed = {}

	--newline first pass
	for i,v in ipairs(lines) do
		local words = {}
		if self.Wrap and self.WrapByWords then
			words = string.Split(v, " ")
		else
			words = {v}
		end

		if self.Wrap then
			if self.WrapByWords then
				local guard = 0
				local remain_tbl = words
				local offset = 0

				while (#remain_tbl > 0 and guard < 200) do
					local remain_tbl_temp = {}
					for i2=#words,1,-1 do --longest to shortest possible sentence
						local sentence = {}
						--i2 is the decreasing limit
						for i3=offset,#words,1 do
							--i3 is the increasing counter
							if i3 < i2 then
								table.insert(sentence,words[i3])
							else
								table.insert(remain_tbl_temp,words[i3])
							end
						end
						local concatenated = table.concat(sentence, " ")
						local w,_ = surface.GetTextSize(concatenated)
						if w > max_w then
							continue
						else
							offset = i2
							table.insert(lines_pushed, concatenated)
							remain_tbl = remain_tbl_temp
							break
						end
					end
					if #remain_tbl_temp == 1 then lines_pushed[#lines_pushed] = lines_pushed[#lines_pushed] .. " " .. remain_tbl_temp[1] break end
					
					guard = guard + 1
				end
			else
				for i2, word in ipairs(words) do
					local word = word
					local remain = word
					local w,_ = surface.GetTextSize(word)

					if w > max_w then --overflow
						local guard = 0
						while (#remain > 0 and guard < 15) do
							for c=#word,1,-1 do
								local split_word = string.sub(word,1,c)
								local w2,_ = surface.GetTextSize(split_word)
								if w2 > max_w then
									continue
								else
									table.insert(lines_pushed, split_word)
									remain = string.sub(word,c+1,#word)
									word = remain
									break
								end
							end
							guard = guard + 1
						end
					else
						table.insert(lines_pushed, remain)
					end
				end
			end
		else
			table.insert(lines_pushed, v)
		end
	end
	local delta = SysTime() - stime
	
	if game.SinglePlayer() then wrap_calculation_time = SysTime() else wrap_calculation_time = SysTime() + 0.5 end
	self.request_line_recalculation = false
	return lines_pushed
end

BUILDER:Register()
