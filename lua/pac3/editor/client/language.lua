pace.KnownGUIStrings = pace.KnownGUIStrings or {}
pace.CurrentTranslation = {}

local cvar = CreateClientConVar("pac_language", "english", true)

function pace.LanguageString(val)
	local key = val:Trim():lower()

	pace.KnownGUIStrings[key] = val

	return pace.CurrentTranslation[key] or val
end

local L = pace.LanguageString

function pace.AddLanguagesToMenu(menu)
	local menu, pnl = menu:AddSubMenu(L"language")
	pnl:SetImage("icon16/world_edit.png")
	menu.GetDeleteSelf = function() return false end
	menu:AddOption("english", function()
		pace.SetLanguage("english")
	end)

	for key, val in pairs(file.Find("pac3/editor/client/translations/*", "LUA")) do
		val = val:gsub("%.lua", "")
		menu:AddOption(val, function()
			pace.SetLanguage(val)
		end)
	end

	menu:AddSpacer()

	menu:AddOption("edit", function() pace.ShowLanguageEditor() end)
end

function pace.ShowLanguageEditor()
	local lang = cvar:GetString()

	local frame = vgui.Create("DFrame")
	frame:SetSize(512, 512)
	frame:Center()
	frame:MakePopup()
	frame:SetTitle(L"translation editor")

	local list = vgui.Create("DListView", frame)
	list:Dock(FILL)

	list:AddColumn("english")
	list:AddColumn(lang)

	local strings = {}

	for k,v in pairs(pace.KnownGUIStrings) do
		strings[k] = v:Trim():lower()
	end
	table.Merge(strings, pace.CurrentTranslation)

	for english, other in pairs(strings) do

		local line = list:AddLine(english, other)
		line.OnRightClick = function()
			local menu = DermaMenu()
			menu:SetPos(gui.MousePos())
			menu:AddOption(L"edit", function()
				local window = Derma_StringRequest(
					L"translate",
					english,
					other,

					function(new)
						pace.CurrentTranslation[english] = new
						line:SetValue(2, new)
						pace.SaveCurrentTranslation()
					end
				)
				for _, pnl in pairs(window:GetChildren()) do
					if pnl.ClassName == "DPanel" then
						for key, pnl in pairs(pnl:GetChildren()) do
							if pnl.ClassName == "DTextEntry" then
								pnl:SetAllowNonAsciiCharacters(true)
							end
						end
					end
				end
			end):SetImage(pace.MiscIcons.edit)
			menu:AddOption(L"revert", function()
				local new = CompileFile("pac3/editor/client/translations/"..lang..".lua")()[english]
				pace.CurrentTranslation[english] = new
				line:SetValue(2, new or english)
				pace.SaveCurrentTranslation()
			end):SetImage(pace.MiscIcons.revert)

			menu:MakePopup()
		end
	end

	list:SizeToContents()
end

function pace.SaveCurrentTranslation()
	local str = {}

	table.insert(str, "return {")

	for key, val in pairs(pace.CurrentTranslation) do
		table.insert(str, string.format("[%q] = %q,", key, val))
	end

	table.insert(str, "}")

	file.CreateDir("pac3_editor", "DATA")
	file.Write("pac3_editor/" .. cvar:GetString() .. ".txt", table.concat(str, "\n"), "DATA")
end

function pace.GetOutputForTranslation()
	local str = ""

	for key, val in pairs(pace.KnownGUIStrings) do
		str = str .. ("%s = %s\n"):format(key:gsub("(.)","_%1_"), val)
	end

	return str
end

function pace.SetLanguage(lang)

	lang = lang or cvar:GetString()
	RunConsoleCommand("pac_language", lang)

	pace.CurrentTranslation = {}

	if lang ~= "english" then
		if file.Exists("pac3_editor/" .. lang .. ".txt", "DATA") then
			table.Merge(pace.CurrentTranslation, CompileString(file.Read("pac3_editor/" .. lang .. ".txt", "DATA"), "pac3_lang")())
		elseif file.Exists("pac3/editor/client/translations/"..lang..".lua", "LUA") then
			table.Merge(pace.CurrentTranslation, CompileFile("pac3/editor/client/translations/"..lang..".lua")())
		else
			pac.Message(Color(255,0,0), "language " .. lang .. " does not exist, falling back to english")
			RunConsoleCommand("pac_language", "english")
			lang = "english"
		end
	end

	if pace.Editor and pace.Editor:IsValid() then
		pace.CloseEditor()
		timer.Simple(0.1, function()
			pace.OpenEditor()
		end)
	end
end