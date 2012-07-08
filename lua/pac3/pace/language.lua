pace.KnownGUIStrings = pace.KnownGUIStrings or {}
pace.CurrentTranslation = {}

function pace.GetOutputForTranslation()
	local str = ""
	
	for key, val in pairs(pace.KnownGUIStrings) do
		str = str .. ("%s = %s\n"):format(key:gsub("(.)","_%1_"), val)
	end
	
	return str
end

local cvar = CreateConVar("pac_language", "english")

function pace.SetLanguage(lang)

	lang = lang or cvar:GetString()
	RunConsoleCommand("pac_language", lang)
	
	pace.CurrentTranslation = {}
	
	if lang ~= "english" then
		table.Merge(pace.CurrentTranslation, CompileFile("pac3/pace/translations/"..lang..".lua")())
	end
	
	if pace.Editor and pace.Editor:IsValid() then
		pace.CloseEditor()
		timer.Simple(0.1, function()
			pace.OpenEditor()
		end)
	end
end

function pace.LanguageString(val)
	local key = val:Trim():lower()
		
	pace.KnownGUIStrings[key] = val

	return pace.CurrentTranslation[key] or val
end