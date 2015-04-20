net.Receive( "pac.net.TogglePartDrawing", function( length, client )
        ent = net.ReadEntity()
		b = (net.ReadBit() == 1)
		if ent:IsValid() then pac.TogglePartDrawing(ent, b) end
end )

function pac.TouchFlexes(ent)
	local index = ent:EntIndex()
	if index == -1 then return end
	net.Start("pac.net.TouchFlexes.ClientNotify")
	net.WriteInt(index,13)
	net.SendToServer()
end
