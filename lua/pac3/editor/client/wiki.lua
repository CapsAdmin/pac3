pace.WikiURL = "https://github.com/capsadmin/pac3/wiki/"
pace.wiki_cache = {}

function pace.GetPropertyDescription(part, field, callback)
	--[==[
	local function go(s)
		callback(s:match("<td>%s-"..field:gsub("%u", " %1"):lower().."%s-</td>.-</td><td> (.-)\n</td>") or "")
	end

	if pace.wiki_cache[part] then
		 go(pace.wiki_cache[part])
	end
	pac.HTTPGet(pace.WikiURL .. "/index.php/Part_"..part, function(s)
		pace.wiki_cache[part] = pace.wiki_cache[part] or s
		go(s)
	end, function(err) Derma_Message("HTTP Request Failed for " .. pace.WikiURL .. "/index.php/Part_"..part, err, "OK") end)
	]==]
end


function pace.ShowHelp(part)
	pace.ShowWiki(pace.WikiURL)
	--[[if part then
		pace.ShowWiki(pace.WikiURL .. "/index.php?title=Part_" .. part .. "&action=view")
	end]]
end