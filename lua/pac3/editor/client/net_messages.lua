function pace.SetInPAC3Editor(b)
	net.Start("pace.InPAC3Editor.ClientNotify")
	net.WriteBit(b)
	net.SendToServer()
end

net.Receive( "pace.InPAC3Editor", function( length, client )
    ent = net.ReadEntity()
	b = (net.ReadBit() == 1)
	if ent:IsValid() then
		ent.InPAC3Editor = b
	end
end )

function pace.SetInAnimEditor(b)
	net.Start("pace.InAnimEditor.ClientNotify")
	net.WriteBit(b)
	net.SendToServer()
end

net.Receive( "pace.InAnimEditor", function( length, client )
    ent = net.ReadEntity()
	b = (net.ReadBit() == 1)
	if ent:IsValid() then
		ent.InAnimEditor = b
	end
end )