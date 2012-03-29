function pac.SubmitOutfit(ent, outfit)
	datastream.StreamToServer("pac_submit", {ent = ent, outfit = outfit})
end

function pac.SetSubmittedOutfit(ent, tbl)
	for key, outfit in ipairs(pac.GetOutfits()) do
		if outfit:GetName() == tbl.Name then
			outfit:Clear()
			outfit:SetTable(tbl)
			return
		end
	end

	pac.CreateOutfit(ent):SetTable(tbl)
end

function pac.RemoveSubmittedOutfit(ply, ent, name)
	pac.RemoveOutfitByName(name)
end

function pac.Notify(allowed, reason)
	 if allowed then
		chat.AddText(Color(255,255,0), "[PAC3] ", Color(0,255,0), "Your config has been applied.")
	else
		chat.AddText(Color(255,255,0), "[PAC3] ", Color(255,0,0), reason)
	end
end

usermessage.Hook("pac_submit_acknowledged", function(umr)
	local allowed = umr:ReadBool()
	local reason = umr:ReadString()

	pac.Notify(allowed, reason)
end)

datastream.Hook("pac_submit", function(_,_,_, data)
	if IsValid(data.ent) then
		if type(data.outfit) == "table" then
			pac.SetSubmittedOutfit(data.ent, data.outfit)
		elseif type(data.outfit) ==  "string" then
			pac.RemoveSubmittedOutfit(data.ply, data.ent, data.outfit)
		end
	end
end)