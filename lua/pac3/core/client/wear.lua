if not _BETA then
	require("datastream")
end

do -- to server
	function pac.SendPartToServer(part)
		if _BETA then
			net.Start("pac_submit")
				net.WriteString(glon.encode({part = part:ToTable()}))
			net.SendToServer()
		else
			datastream.StreamToServer("pac_submit", {part = part:ToTable()})
		end
	end

	function pac.RemovePartOnServer(name)
		if _BETA then
			net.Start("pac_submit")
				net.WriteString(glon.encode({part = name}))
			net.SendToServer()
		else
			datastream.StreamToServer("pac_submit", {part = name})
		end
	end
end

do -- from server
	function pac.WearPartFromServer(owner, part_data)
		pac.dprint("received outfit %q from %s with %i number of children to set on %s", part_data.self.Name, tostring(owner), table.Count(part_data.children), part_data.self.OwnerName)

		for key, part in pairs(pac.GetParts()) do
			if 
				not part:HasParent() and 
				part:GetPlayerOwner() == owner and 
				part:GetName() == pac.HandlePartName(owner, part_data.self.Name) and 
				part.ClassName == part_data.self.ClassName 
			then
				pac.dprint("removing part %q to be replaced with the part previously received", part.Name)
				part:Remove()
			end
		end 
		
		local part = pac.CreatePart(part_data.self.ClassName, owner)
		part:SetTable(part_data)
		part:CheckOwner()
	end

	function pac.RemovePartFromServer(owner, part_name)
		pac.dprint("%s is removed %q", tostring(owner), part_name)

		for key, part in pairs(pac.GetParts()) do
			if 
				not part:HasParent() and 
				part:GetPlayerOwner() == owner and 
				part:GetName() == pac.HandlePartName(owner, part_name)
			then
				part:Remove()
				return
			end
		end 
	end
end

local function handle_data(data)
	if data.owner:IsValid() then
		local T = type(data.part)
		if T == "table" then
			pac.WearPartFromServer(data.owner, data.part)
		elseif T ==  "string" then
			pac.RemovePartFromServer(data.owner, data.part)
		end
	end
end

if _BETA then
	net.Receive("pac_submit", function()
		handle_data(glon.decode(net.ReadString()))
	end)
else
	datastream.Hook("pac_submit", function(_,_,_, data)
		handle_data(data)
	end)
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