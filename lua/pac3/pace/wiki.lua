pace.wiki_cache = {}

function pace.GetPropertyDescription(part, field, callback)
	local function go(s)
		callback(s:match("<td>%s-"..field:gsub("%u", " %1"):lower().."%s-</td>.-</td><td> (.-)\n</td>") or "")
	end
	
	if pace.wiki_cache[part] then
		 go(pace.wiki_cache[part])
	end
	http.Fetch("http://pac.educatewiki.com/wiki/Part_"..part, function(s)	
		pace.wiki_cache[part] = pace.wiki_cache[part] or s
		go(s)
	end)
end


function pace.ShowHelp(part)
	if part then
		pace.ShowWiki("http://pac.educatewiki.com/w/index.php?title=Part_" .. part .. "&action=view")
	end
end