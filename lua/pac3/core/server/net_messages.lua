util.AddNetworkString("pac.net.TogglePartDrawing")
function pac.TogglePartDrawing(ent, b, who) --serverside interface to clientside function of the same name
	net.Start("pac.net.TogglePartDrawing")
	net.WriteEntity(ent)
	net.WriteBit(b)
	if not who then
		net.Broadcast()
	else
		net.Send(who)
	end
end

util.AddNetworkString("pac.net.TouchFlexes.ClientNotify")
net.Receive( "pac.net.TouchFlexes.ClientNotify", function( length, client )
	local index = net.ReadInt(13)
	local ent = Entity(index)
	local target = ent:GetFlexWeight(1) or 0
	if ent and ent:IsValid() and ent.GetFlexNum and ent:GetFlexNum() > 0 then ent:SetFlexWeight(1,target) end
end )
