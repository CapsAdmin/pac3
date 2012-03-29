local KnownGUIStrings = {}

function pace.GetKnownGUIStrings()
	return KnownGUIStrings
end

function pace.AddLanguage(key, val)
	language.Add("pace_" .. key, val)
end

function pace.LanguageString(str, extra)
	local lang = str:gsub("%s", "_"):gsub("%p", ""):lower()

	if extra then
		lang = extra .. lang
	end

	lang = "pace_" .. lang

	language.Add(lang, str)

	lang = "#" .. lang

	KnownGUIStrings[lang] = str

	return lang
end