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
	ent:SetSkin(val.skn)
	ent:SetMaterial(val.mat) -- insecure
	ent:Spawn()
	ent:SetHealth(9999999)
	ent:SetColor(val.clr)
	ent:SetRenderMode( RENDERMODE_TRANSCOLOR )

	hook.Run("PlayerSpawnedProp", ply, model, ent)

	if ent.CPPISetOwner and not (ent:CPPIGetOwner() or NULL):IsValid() then
		ent:CPPISetOwner(ply)
	end

	local phys = ent:GetPhysicsObject()

	if phys:IsValid() then
		phys:EnableMotion(false)

		local maxabs = 150

		val.scale.X = math.Clamp(val.scale.X,-maxabs,maxabs)
		val.scale.Y = math.Clamp(val.scale.Y,-maxabs,maxabs)
		val.scale.Z = math.Clamp(val.scale.Z,-maxabs,maxabs)

		for i=0, ent:GetBoneCount()-1 do
			ent:ManipulateBoneScale( i, val.scale )
		end

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

pace.PCallNetReceive(net.Receive, "pac_to_contraption", function(len, ply)
	if not pac_to_contraption_allow:GetBool() then
		net.Start("pac_submit_acknowledged")
			net.WriteBool(false)
			net.WriteString("This server does not allow spawning PAC contraptions.")
		net.Send(ply)

		return
	end

	if len < 64 then return end

	local allowed = pac.RatelimitPlayer( ply, "pac_to_contraption", 5, 1, {"Player ", ply, " is spamming pac_to_contraption!"} )
	if not allowed then return end

	local data = net.ReadTable()

	local max = max_contraptions:GetInt()
	local count = table.Count(data)
	if count > max then
		net.Start("pac_submit_acknowledged")
			net.WriteBool(false)
			net.WriteString("You can only spawn " .. max .. " props at a time!")
		net.Send(ply)

		pac.Message(ply, " might have tried to crash the server by attempting to spawn ", count, " entities with the contraption system!")
		return
	end

	pac.Message("Spawning contraption by ", ply, " with ", count, " entities")

	for key, val in pairs(data) do
		spawn(val,ply)
	end
end)
