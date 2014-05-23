
concommand.Add("animeditor_in_editor", function(ply, _, args)
	ply:SetNWBool("in animeditor", tonumber(args[1]) == 1)
end)
