local function handle_data(data)
	if IsValid(data.ent) then
		if type(data.part) == "table" then
			pac.SetSubmittedPart(data.ply, data.ent, data.part)
		elseif type(data.part) ==  "string" then
			pac.RemoveSubmittedPart(data.ply, data.ent, data.part)
		end
	end
end

if net then
	function pac.SubmitPart(ent, part)
		net.Start("pac_submit")
			net.WriteString(glon.encode({ent = ent, part = part:ToTable()}))
		net.SendToServer()
	end

	net.Receive("pac_submit", function()
		local data = glon.decode(net.ReadString())
		handle_data(data)
	end)
else
	require("datastream")

	function pac.SubmitPart(ent, part)
		datastream.StreamToServer("pac_submit", {ent = ent, part = part:ToTable()})
	end

	datastream.Hook("pac_submit", function(_,_,_, data)
		handle_data(data)
	end)
end

function pac.SetSubmittedPart(ply, ent, tbl)
	print("received outfit from ", ply, " to set on ", ent)
	PrintTable(tbl)

	for key, part in pairs(pac.GetParts()) do
		if not part:HasParent() and part:GetPlayerOwner() == ply and part:GetName() == tbl.self.Name then
			part:Clear()
			part:SetOwner(ent)
			part:SetTable(tbl)
			return
		end
	end 

	local part = pac.CreatePart(tbl.self.ClassName)
	part:SetPlayerOwner(ply)
	part:SetOwner(ent)
	part:SetTable(tbl)
end

function pac.RemoveSubmittedPart(ply, ent, name)
	print(ply, " is removing ", name, " from ", ent)

	for key, part in pairs(pac.GetParts()) do
		if not part:HasParent() and part:GetPlayerOwner() == ply and part:GetName() == name then
			part:Remove()
			return
		end
	end 
end

function pac.SubmitRemove(ent, name)
	if net then
		net.Start("pac_submit")
			net.WriteString(glon.encode({ent = ent, part = name}))
		net.SendToServer()
	else
		datastream.StreamToServer("pac_submit", {ent = ent, part = name})
	end
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