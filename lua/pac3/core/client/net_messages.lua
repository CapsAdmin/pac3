net.Receive("pac.net.TogglePartDrawing", function()
	local ent = net.ReadEntity()
	if ent:IsValid() then
		local b = (net.ReadBit() == 1)
		pac.TogglePartDrawing(ent, b)
	end
end )

function pac.SetInPAC3Editor(b)
	net.Start("pac.net.InPAC3Editor.ClientNotify")
	net.WriteBit(b)
	net.SendToServer()
end

net.Receive("pac.net.InPAC3Editor", function()
	local ent = net.ReadEntity()
	if ent:IsValid() then
		local b = (net.ReadBit() == 1)
		ent.InPAC3Editor = b
	end
end )

function pac.SetInAnimEditor(b)
	net.Start("pac.net.InAnimEditor.ClientNotify")
	net.WriteBit(b)
	net.SendToServer()
end

net.Receive("pac.net.InAnimEditor", function()
	local ent = net.ReadEntity()
	if ent:IsValid() then
		local b = (net.ReadBit() == 1)
		ent.InAnimEditor = b
	end
end )

function pac.SetCollisionGroup(ent,group)
	local index = ent:EntIndex()
	net.Start("pac.net.SetCollisionGroup.ClientNotify")
	net.WriteInt(index,13)
	net.WriteInt(group,7)
	net.SendToServer()
end

function pac.TouchFlexes(ent)
	local index = ent:EntIndex()
	if index == -1 then return end
	net.Start("pac.net.TouchFlexes.ClientNotify")
	net.WriteInt(index,13)
	net.SendToServer()
end
