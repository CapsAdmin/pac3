--code moved from entity mutators
--extras to control other aspects of the model serverside. it's an adjacent functionality to editing your model
--without the need for active parts
--to let simple MDLs work better with pac-disabled and renderdistance cases


-- Inverse of Lerp()
local function InvLerp(t, from, to)
    if from==to then return from end
    return (t - from) / (to - from)
end

-- Returns flex bounds, or default [0, 1] as a failsafe
local function GetFlexBounds(entity, flex)
    local min, max = entity:GetFlexBounds(flex)
    return min or 0, max or 1
end
pac.GetFlexBounds = GetFlexBounds

-- Convert a flex weight value from [range_min, range_max] into [0, 1]
local function FromFlexRange(entity, flex, weight)
    return InvLerp( weight, GetFlexBounds(entity, flex) )
end
pac.FromFlexRange = FromFlexRange

-- Convert a flex weight value from [0, 1] into [range_min, range_max]
local function ToFlexRange(entity, flex, weight)
    return Lerp( weight, GetFlexBounds(entity, flex) )
end
pac.ToFlexRange = ToFlexRange

-- Set flex weight, using the flex controller defined range
local function SetFlexWeight(entity, flex, weight)
    entity:SetFlexWeight(
        flex,
        FromFlexRange( entity, flex, weight )
    )
end
pac.SetFlexWeight = SetFlexWeight

-- Get flex weight, using the flex controller defined range
local function GetFlexWeight(entity, flex)
    return ToFlexRange( entity, flex, entity:GetFlexWeight(flex) )
end
pac.GetFlexWeight = GetFlexWeight

-- Returns pose parameter bounds, or default [0, 1] as a failsafe
local function GetPoseParameterRange(entity, parameter)
    local min, max = entity:GetPoseParameterRange(parameter)
    return min or 0, max or 1
end
pac.GetPoseParameterRange = GetPoseParameterRange


-- Convert a pose parameter value from [range_min, range_max] into [0, 1]
local function FromPoseParameterRange(entity, parameter, value)
    return InvLerp( value, GetPoseParameterRange(entity, parameter) )
end
pac.FromPoseParameterRange = FromPoseParameterRange

-- Convert a pose parameter value from [0, 1] into [range_min, range_max]
local function ToPoseParameterRange(entity, parameter, value)
    return Lerp( value, GetPoseParameterRange(entity, parameter) )
end
pac.ToPoseParameterRange = ToPoseParameterRange

-- Set pose parameter, using the pose parameter's defined range
local function SetPoseParameter(entity, parameter, value)
    entity:SetPoseParameter(
        parameter,
        FromPoseParameterRange( entity, parameter, value )
    )
end
pac.SetPoseParameter = SetPoseParameter

-- Get pose parameter, using the pose parameter's defined range
local function GetPoseParameter(entity, parameter)
    return ToPoseParameterRange( entity, parameter, entity:GetPoseParameter(parameter) )
end
pac.GetPoseParameter = GetPoseParameter

if SERVER then
	pac.player_submodel_mutations = {}

	util.AddNetworkString("pac_update_flexweight")
	local function broadcast_flexweight(ply, id, value)
		if ply:GetInfoNum("pac_override_flexweight_mirrored_on_ragdoll", 0) ~= 1 then return end
		if pac.player_submodel_mutations and pac.player_submodel_mutations[ply] then
			if not pac.player_submodel_mutations[ply]["flex"] then return end
			if not pac.player_submodel_mutations[ply]["flex"][id] then return end
			net.Start("pac_update_flexweight", true)
			net.WriteUInt(id, 6)
			net.WriteInt(value * 100, 16)
			net.WriteEntity(ply)
			net.Broadcast()
		end
	end

	local function update_register(ply, mutation, key, value)
		pac.player_submodel_mutations[ply] = pac.player_submodel_mutations[ply] or {
			bodygroup = {},
			flex = {},
			poseparameter = {},
		}
		if pac.player_submodel_mutations[ply][mutation] then
			pac.player_submodel_mutations[ply][mutation][key] = value
		end
	end
	local function reapply_modifications(ent, owner, duplicate_to_ragdoll)

		if not pac.player_submodel_mutations then return end
		if not pac.player_submodel_mutations[owner] then return end


		--bodygroups are already networked to the ragdoll
		if pac.player_submodel_mutations[owner]["bodygroup"] then
			for k,v in pairs(pac.player_submodel_mutations[owner]["bodygroup"]) do
				ent:SetBodygroup(k, v)
			end
		end

		--poseparameters I'm not sure
		if pac.player_submodel_mutations[owner]["poseparameter"] then
			for k,v in pairs(pac.player_submodel_mutations[owner]["poseparameter"]) do
				ent:SetPoseParameter(k, v)
			end
		end

		--flexes need to be reapplied
		if pac.player_submodel_mutations[owner]["flex"] then
			if duplicate_to_ragdoll then
				local limit = 10
				local msg = 0
				local min_value = 0.1
				for k,v in pairs(pac.player_submodel_mutations[owner]["flex"]) do
					if math.abs(v) < min_value then continue end
					if msg > limit then break end
					pac.SetFlexWeight(ent, k, v)
					broadcast_flexweight(owner, k, v)
					msg = msg + 1
				end
				return
			else
				for k,v in pairs(pac.player_submodel_mutations[owner]["flex"]) do
					pac.SetFlexWeight(owner, k, v)
				end
			end
		end
	end

	concommand.Add("pac_override_bodygroup", function(ply, name, args, args_str)
		if not ply:IsValid() then return end
		if not GetConVar("pac_modifier_model"):GetBool() then return end
		local function helptext()
			for i,tbl in ipairs(ply:GetBodyGroups()) do
				ply:PrintMessage(HUD_PRINTCONSOLE, "[" .. tbl.id .. "] " .. tbl.name)
				if table.Count(tbl.submodels) > 1 then
					for i2=0, table.Count(tbl.submodels) - 1 do
						local selected = ""
						if i2 == ply:GetBodygroup(tbl.id) then selected = " [active]" end
						ply:PrintMessage(HUD_PRINTCONSOLE, "  [" .. i2 .. "] " .. tbl.submodels[i2] .. selected)
					end
				end
				ply:PrintMessage(HUD_PRINTCONSOLE, "\n")
			end
		end
		if not args[1] then
			helptext()
		elseif args[1] == "^" or args[1] == "reset" then
			for i, str in ipairs(string.Split(ply:GetInfo("cl_playerbodygroups")," ")) do
				ply:SetBodygroup(i-1, tonumber(str))
			end
		end
		if args[1] and args[2] then
			local id = ply:FindBodygroupByName(args[1])
			if id == -1 then ply:PrintMessage(HUD_PRINTCONSOLE, "invalid bodygroup!") helptext() return end

			if args[2] == "+" then
				local val = (ply:GetBodygroup(id)+1) % (ply:GetBodygroupCount(id))
				ply:SetBodygroup(id,val)
				update_register(ply, "bodygroup", id, val)
			elseif args[2] == "-" then
				local val = (ply:GetBodygroup(id)-1) % (ply:GetBodygroupCount(id))
				ply:SetBodygroup(id,val)
				update_register(ply, "bodygroup", id, val)
			elseif args[2] == "toggle" then
				if ply:GetBodygroup(id) >= 1 then
					ply:SetBodygroup(id, 0)
					update_register(ply, "bodygroup", id, 0)
				else
					ply:SetBodygroup(id, 1)
					update_register(ply, "bodygroup", id, 1)
				end
			elseif isnumber(tonumber(args[2])) then
				ply:SetBodygroup(id, -1)
				ply:SetBodygroup(id, tonumber(args[2]))
				update_register(ply, "bodygroup", id, tonumber(args[2]))
			end
		elseif args[1] then
			ply:SetBodyGroups(args[1])
		end
	end, nil, "sends out a request to change your playermodel's bodygroups, but you'll need to stop your entity parts from changing bodygroups\n\ne.g.\npac_override_bodygroup  1pac_override_bodygroup 'Head Dress' 1")

	concommand.Add("pac_override_flexweight", function(ply, name, args, args_str)
		if not ply:IsValid() then return end
		if not GetConVar("pac_modifier_model"):GetBool() then return end
		local function helptext()
			for i=0,ply:GetFlexNum()-1 do
				ply:PrintMessage(HUD_PRINTCONSOLE, "[" .. i .. "] " .. ply:GetFlexName(i))
			end
		end
		if not args[1] then
			helptext()
		elseif args[1] == "^" or args[1] == "reset" then
			for i=0,ply:GetFlexNum()-1 do
				pac.SetFlexWeight(ply, i, 0)
				update_register(ply, "flex", i, nil)
			end
		end
		if args[1] and args[2] then
			local id = ply:GetFlexIDByName(args[1]) or tonumber(args[1])
			if id == nil then return end

			if args[2] == "toggle" then
				local val = ply:GetFlexWeight(id) < 0.5 and 1 or 0
				pac.SetFlexWeight(ply, id, -1)
				pac.SetFlexWeight(ply, id, val)
				update_register(ply, "flex", id, val)
				broadcast_flexweight(ply, id, val)
			elseif isnumber(tonumber(args[2])) then
				pac.SetFlexWeight(ply, id, tonumber(args[2]))
				update_register(ply, "flex", id, tonumber(args[2]))
				broadcast_flexweight(ply, id, tonumber(args[2]))
			end
		end
	end, nil, "sends out a request to change your playermodel's flex weights\n\ne.g.\npac_override_flexweight blink-happy 1\npac_override_flexweight ^\npac_override_flexweight blink toggle\n\nthe toggle mode switches between 0 and 1, depending on whether the serverside value is above 0.5")

	util.AddNetworkString("pac_update_poseparameter")
	local function broadcast_poseparam(ply, id, value, reset)
		net.Start("pac_update_poseparameter", true)
		net.WriteUInt(id, 5)
		net.WriteInt(value * 100, 16)
		net.WriteBool(reset)
		net.WriteEntity(ply)
		net.Broadcast()
	end

	concommand.Add("pac_override_poseparameter", function(ply, name, args, args_str)
		if not ply:IsValid() then return end
		if not GetConVar("pac_modifier_model"):GetBool() then return end
		local function helptext()
			for i=0,ply:GetNumPoseParameters()-1 do
				local min, max = ply:GetPoseParameterRange(i)
				ply:PrintMessage(HUD_PRINTCONSOLE, "[" .. i .. "] " .. ply:GetPoseParameterName(i) .. " {"..min..", "..max.."}")
			end
		end
		if not args[1] then
			helptext()
		elseif args[1] == "^" or args[1] == "reset" then
			for id=0,ply:GetNumPoseParameters()-1 do
				broadcast_poseparam(ply, id, 0, true)
				update_register(ply, "poseparameter", id, nil)
			end
			return
		end
		if args[1] and args[2] then
			local id = ply:LookupPoseParameter(args[1])
			if id == -1 then return end

			if isnumber(tonumber(args[2])) then
				ply:SetPoseParameter(id, tonumber(args[2]))
				broadcast_poseparam(ply, id, tonumber(args[2]), false)
				update_register(ply, "poseparameter", id, tonumber(args[2]))
			elseif args[2] == "^" or args[2] == "reset" then
				broadcast_poseparam(ply, id, 0, true)
				update_register(ply, "poseparameter", id, tonumber(args[2]))
			end
		end
	end, nil, "sends out a request to change your playermodel's pose parameters.\n\ne.g.\npac_override_poseparameter head_yaw 70\npac_override_poseparameter head_yaw reset\npac_override_poseparameter ^\nusing ^ or reset at the FIRST argument will reset all your poseparameters\nusing reset at the SECOND argument will reset ONE poseparameter")

	gameevent.Listen( "entity_killed" )
	hook.Add( "entity_killed", "pac_transfer_submodel_mutations", function( data )
		if not GetConVar("pac_modifier_model"):GetBool() then return end
		// Called when a Player or Entity is killed
		local ent = Entity(data.entindex_killed)
		if not IsValid(ent) then return end
		if ent:IsPlayer() then
			timer.Simple(0.1, function()
				reapply_modifications(ent:GetRagdollEntity(), ent, true)
			end)
		end
	end)
else
	CreateClientConVar("pac_override_flexweight_mirrored_on_ragdoll", "0", true, true, "Whether to request that flex weight edits from the pac_override_flexweight command should be networked to re-apply to your corpse ragdoll")
	net.Receive("pac_update_poseparameter", function()
		local id = net.ReadUInt(5)
		local value = net.ReadInt(16) / 100
		local reset = net.ReadBool()
		local ent = net.ReadEntity()
		local name = ent:GetPoseParameterName(id)
		local hook_id = "manual_"..name
		ent.pac_pose_params = ent.pac_pose_params or {}
		if reset then ent.pac_pose_params[hook_id] = nil return end
		ent.pac_pose_params[hook_id] = ent.pac_pose_params[hook_id] or {}
		ent.pac_pose_params[hook_id].key  = name
		ent.pac_pose_params[hook_id].val = value
		ent:SetPoseParameter(id, value)
	end)
	net.Receive("pac_update_flexweight", function()
		local id = net.ReadUInt(6)
		local value = net.ReadInt(16) / 100
		local ent = net.ReadEntity()
									  
		ent:SetFlexWeight(id, value)
		if not ent:Alive() then
			local rag = ent:GetRagdollEntity()
			if IsValid(rag) then
				rag:SetFlexWeight(id, value)
			end
		end
	end)
end
