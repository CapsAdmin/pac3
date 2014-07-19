net.Receive( "pac.net.TogglePartDrawing", function( length, client )
        ent = net.ReadEntity()
		b = (net.ReadBit() == 1)
		if ent:IsValid() then pac.TogglePartDrawing(ent, b) end
end )

function pac.SetInPAC3Editor(b)
	net.Start("pac.net.InPAC3Editor.ClientNotify")
	net.WriteBit(b)
	net.SendToServer()
end

net.Receive( "pac.net.InPAC3Editor", function( length, client )
    ent = net.ReadEntity()
	b = (net.ReadBit() == 1)
	if ent:IsValid() then 
		ent.InPAC3Editor = b
	end
end )

function pac.SetInAnimEditor(b)
	net.Start("pac.net.InAnimEditor.ClientNotify")
	net.WriteBit(b)
	net.SendToServer()
end

net.Receive( "pac.net.InAnimEditor", function( length, client )
    ent = net.ReadEntity()
	b = (net.ReadBit() == 1)
	if ent:IsValid() then 
		ent.InAnimEditor = b
	end
end )