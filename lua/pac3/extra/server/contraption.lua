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

timer.Create("pac_contraption_spam", 3, 0, function()
	for i, ply in ipairs(player.GetAll()) do
		ply.pac_submit_spam3 = math.max((ply.pac_submit_spam3 or 0) - 3, 0)

		if ply.pac_submit_spam3_msg then
			ply.pac_submit_spam3_msg = ply.pac_submit_spam3 >= 20
		end
	end
end)

pace.PCallNetReceive(net.Receive, "pac_to_contraption", function(len, ply)
	if not pac_to_contraption_allow:GetBool() then
		net.Start("pac_submit_acknowledged")
			net.WriteBool(false)
			net.WriteString("This server does not allow spawning PAC contraptions.")
		net.Send(ply)

		return
	end

	if len < 64 then return end

	ply.pac_submit_spam3 = ply.pac_submit_spam3 + 1

	if ply.pac_submit_spam3 >= 8 then
		if not ply.pac_submit_spam3_msg then
			pac.Message("Player ", ply, " is spamming pac_to_contraption!")
			ply.pac_submit_spam3_msg = true
		end

		return
	end

	local data = net.ReadTable()

	local max = max_contraptions:GetInt()
	local count = table.Count(data)
	if count > max then
		net.Start("pac_submit_acknowledged")
			net.WriteBool(false)
			net.WriteString("You can only spawn ", max, " props at a time!")
		net.Send(ply)

		pac.Message(ply, " might have tried to crash the server by attempting to spawn ", count, " entities with the contraption system!")
		return
	end

	pac.Message("Spawning contraption by ", ply, " with ", count, " entities")

	for key, val in pairs(data) do
		spawn(val,ply)
	end
end)
