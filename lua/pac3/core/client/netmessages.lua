net.Receive( "pac.net.TogglePartDrawing", function( length, client )
        ent = net.ReadEntity()
		b = (net.ReadBit() == 1)
		if ent:IsValid() then pac.TogglePartDrawing(ent, b) end
end )