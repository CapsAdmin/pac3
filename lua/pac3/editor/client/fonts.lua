local L = pace.LanguageString

pace.Fonts = {}

for i = 1, 5 do
	surface.CreateFont("pac_font_"..i,
	{
		font = "Arial",
		size = 11 + i,
		weight = 50,
		antialias = true,
	})

	table.insert(pace.Fonts, "pac_font_"..i)
end

for i = 1, 5 do
	surface.CreateFont("pac_font_bold"..i,
	{
		font = "Arial",
		size = 11 + i,
		weight = 800,
		antialias = true,
	})
	table.insert(pace.Fonts, "pac_font_bold"..i)
end

table.insert(pace.Fonts, "DermaDefault")
table.insert(pace.Fonts, "DermaDefaultBold")

local font_cvar = CreateClientConVar("pac_editor_font", pace.Fonts[1])

function pace.SetFont(fnt)
	pace.CurrentFont = fnt or font_cvar:GetString()

	if not table.HasValue(pace.Fonts, pace.CurrentFont) then
		pace.CurrentFont = "DermaDefault"
	end

	RunConsoleCommand("pac_editor_font", pace.CurrentFont)

	if pace.Editor and pace.Editor:IsValid() then
		pace.CloseEditor()
		timer.Simple(0.1, function()
			pace.OpenEditor()
		end)
	end
end

function pace.AddFontsToMenu(menu)
	local menu,pnl = menu:AddSubMenu(L"font")
	pnl:SetImage("icon16/text_bold.png")
	menu.GetDeleteSelf = function() return false end

	for key, val in pairs(pace.Fonts) do
		local pnl = menu:AddOption(L"The quick brown fox jumps over the lazy dog. (" ..val ..")", function()
			pace.SetFont(val)
		end)

		pnl:SetFont(val)
	end
end

pace.SetFont()