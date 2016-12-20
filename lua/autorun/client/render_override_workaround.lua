local skip = false 
hook.Add("PrePlayerDraw", "renderoverride_workaround", function(p) 
	if not skip and p.RenderOverride then 
		skip = true 
		p:RenderOverride() 
		skip = false 
		return true 
	end
end)