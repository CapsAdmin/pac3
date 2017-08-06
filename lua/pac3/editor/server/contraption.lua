util.AddNetworkString("pac_to_contraption")

local receieved = {}

local function spawn(val,player)
	local model = val.mdl

	if not model or model == "" or model:find("\n") or model:find("..", 1, true) then
		return
	end

	pace.suppress_prop_spawn = true
	local ok = hook.Run("PlayerSpawnProp", player, model)
	pace.suppress_prop_spawn = false

	if not ok then
		return
	end

	local ent = ents.Create("prop_physics")

	SafeRemoveEntity(receieved[val.id])
	receieved[val.id] = ent

	ent:SetModel(model)-- insecure
	ent:SetPos(val.pos)-- insecure
	ent:SetAngles(val.ang)-- insecure
	ent:SetColor(val.clr)
	ent:SetSkin(val.skn)
	ent:SetMaterial(val.mat) -- insecure
	ent:Spawn()
	ent:SetHealth(9999999)

	hook.Run("PlayerSpawnedProp", player, model, ent)

	if ent.CPPISetOwner and not (ent:CPPIGetOwner() or NULL):IsValid() then
		ent:CPPISetOwner(ply)
	end

	local phys = ent:GetPhysicsObject()

	if phys:IsValid() then
		phys:EnableMotion(false)

		undo.Create("Prop")
			undo.SetPlayer(player)
			undo.AddEntity(ent)
		undo.Finish( "Prop ("..tostring(model)..")" )

		player:AddCleanup( "props", ent )

		gamemode.Call( "PlayerSpawnedProp", player, model, ent )
	else
		ent:Remove()
	end

end

local pac_to_contraption_allow = CreateConVar("pac_to_contraption_allow", "1")

local max_contraptions = CreateConVar("pac_max_contraption_entities", 60)

net.Receive("pac_to_contraption", function(len, ply)
	if not pac_to_contraption_allow:GetBool() then
		ply:ChatPrint("This server does not allow spawning PAC contraptions")
		return
	end

	local data = net.ReadTable()

	local max = max_contraptions:GetInt()
	local count = table.Count(data)
	if count > max then
		ply:ChatPrint("You can max spawn " .. max .. " props at the time!")
		print("[PAC3] ",ply, "might have tried to crash the server by attempting to spawn " .. count .. " entities with the contraption system")
		return
	end

	print("[PAC3] Spawning contraption by ", ply, " with ", count, " entities")

	for key, val in pairs(data) do
		spawn(val,ply)
	end
end)
