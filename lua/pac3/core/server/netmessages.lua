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

util.AddNetworkString("pac.net.InPAC3Editor")
util.AddNetworkString("pac.net.InPAC3Editor.ClientNotify")
net.Receive( "pac.net.InPAC3Editor.ClientNotify", function( length, client )
	b = (net.ReadBit() == 1)
	net.Start("pac.net.InPAC3Editor")
	net.WriteEntity(client)
	net.WriteBit(b)
	net.Broadcast()
end )

util.AddNetworkString("pac.net.InAnimEditor")
util.AddNetworkString("pac.net.InAnimEditor.ClientNotify")
net.Receive( "pac.net.InAnimEditor.ClientNotify", function( length, client )
	b = (net.ReadBit() == 1)
	net.Start("pac.net.InAnimEditor")
	net.WriteEntity(client)
	net.WriteBit(b)
	net.Broadcast()
end )

util.AddNetworkString("pac.net.SetCollisionGroup.ClientNotify")
net.Receive( "pac.net.SetCollisionGroup.ClientNotify", function(ent,group)
	local index = net.ReadInt(13)
	local group = net.ReadInt(7)
	Entity(index):SetCollisionGroup(group)
end )

function pac.setHasVfs(b, ply, target)
	ply.has_vfs = b
	net.Start("pac.net.setHasVfs")
	net.WriteEntity(ply)
	net.WriteBit(b)
	if not target then
		net.Broadcast()
	else 
		net.Send(target)
	end
end

util.AddNetworkString("pac.net.setHasVfs")
util.AddNetworkString("pac.net.setHasVfs.ClientNotify")
net.Receive( "pac.net.setHasVfs.ClientNotify", function( length, client )
	local b = (net.ReadBit() == 1)
	pac.setHasVfs(b,client)
end )

--util.AddNetworkString("pac.net.requestVfsStatus")
util.AddNetworkString("pac.net.requestVfsStatus.ClientNotify")
net.Receive( "pac.net.requestVfsStatus.ClientNotify", function(length, client)
	for k,v in pairs(player.GetAll()) do
		if v.has_vfs then
			pac.setHasVfs(true, v, client)
		end
	end
end)

util.AddNetworkString("pac.net.PlayerInitialSpawn")
hook.Add("PlayerInitialSpawn","pac.net.PlayerInitialSpawn",function(ply)
	net.Start("pac.net.PlayerInitialSpawn")
	net.Send(ply)
end)