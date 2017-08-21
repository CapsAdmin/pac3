util.AddNetworkString("pac_to_contraption")

local receieved = {}

local function spawn(val,ply)
	local model = val.mdl

	if not model or model == "" or model:find("\n") or model:find("..", 1, true) then
		return
	end

	pace.suppress_prop_spawn = true
	local ok = hook.Run("PlayerSpawnProp", ply, model)
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

	hook.Run("PlayerSpawnedProp", ply, model, ent)

	if ent.CPPISetOwner and not (ent:CPPIGetOwner() or NULL):IsValid() then
		ent:CPPISetOwner(ply)
	end

	local phys = ent:GetPhysicsObject()

	if phys:IsValid() then
		phys:EnableMotion(false)

		undo.Create("Prop")
			undo.SetPlayer(ply)
			undo.AddEntity(ent)
		undo.Finish("Prop ("..tostring(model)..")")

		ply:AddCleanup("props", ent)

		gamemode.Call("PlayerSpawnedProp", ply, model, ent)
	else
		ent:Remove()
	end

end

local pac_to_contraption_allow = CreateConVar("pac_to_contraption_allow", "1")

local max_contraptions = CreateConVar("pac_max_contraption_entities", 60)

net.Receive("pac_to_contraption", function(len, ply)
	if not pac_to_contraption_allow:GetBool() then
		umsg.Start("pac_submit_acknowledged", ply)
			umsg.Bool(false)
			umsg.String("This server does not allow spawning PAC contraptions.")
		umsg.End()

		return
	end

	local data = net.ReadTable()

	local max = max_contraptions:GetInt()
	local count = table.Count(data)
	if count > max then
		umsg.Start("pac_submit_acknowledged", ply)
			umsg.Bool(false)
			umsg.String("You can only spawn "..max.." props at a time!")
		umsg.End()

		print("[PAC3] ", ply, " might have tried to crash the server by attempting to spawn "..count.." entities with the contraption system!")
		return
	end

	print("[PAC3] Spawning contraption by ", ply, " with "..count.." entities")

	for key, val in pairs(data) do
		spawn(val,ply)
	end
end)
