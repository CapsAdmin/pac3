local MUTATOR = {}

MUTATOR.ClassName = "model"
MUTATOR.UpdateRate = 0.25

function MUTATOR:WriteArguments(path)
	assert(isstring(path), "path must be a string")

	net.WriteString(path)
end

function MUTATOR:ReadArguments()
	return net.ReadString()
end

function MUTATOR:Update(val)
	if not self.actual_model or not IsValid(self.Entity) then return end

	if self.Entity:GetModel():lower() ~= self.actual_model:lower() then
		self.Entity:SetModel(self.actual_model)
	end
end

function MUTATOR:StoreState()
	return self.Entity:GetModel()
end

function MUTATOR:Mutate(path)
	if path:find("^http") then
		if SERVER and pac.debug then
			if self.Owner:IsPlayer() then
				pac.Message(self.Owner, " wants to use ", path, " as model on ", ent)
			end
		end

		local ent_str = tostring(self.Entity)

		pac.DownloadMDL(path, function(mdl_path)
			if not self.Entity:IsValid() then
				pac.Message("cannot set model ", mdl_path, " on ", ent_str ,': entity became invalid')
				return
			end

			if SERVER and pac.debug then
				pac.Message(mdl_path, " downloaded for ", ent, ': ', path)
			end

			self.Entity:SetModel(mdl_path)
			self.actual_model = mdl_path

		end, function(err)
			pac.Message(err)
		end, self.Owner)
	else
		if path:EndsWith(".mdl") then
			self.Entity:SetModel(path)

			if self.Owner:IsPlayer() and path:lower() ~= self.Entity:GetModel():lower() then
				self.Owner:ChatPrint('[PAC3] ERROR: ' .. path .. " is not a valid model on the server.")
			else
				self.actual_model = path
			end
		else
			local translated = player_manager.TranslatePlayerModel(path)
			self.Entity:SetModel(translated)
			self.actual_model = translated
		end
	end
end

pac.emut.Register(MUTATOR)

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

--extras to control other aspects of the model serverside. it's an adjacent functionality to editing your model
--to let simple MDLs work better with pac-disabled and renderdistance cases
if SERVER then
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
		elseif args[1] == "^" or args[1] == "__RESET__" then
			ply:SetNWBool("pac_overriding_bodygroups", false)
		end
		if args[1] and args[2] then
			local id = ply:FindBodygroupByName(args[1])
			if id == -1 then ply:PrintMessage(HUD_PRINTCONSOLE, "invalid bodygroup!") helptext() return end

			if args[2] == "+" then
				ply:SetBodygroup(id,(ply:GetBodygroup(id)+1) % (ply:GetBodygroupCount(id)))
			elseif args[2] == "-" then
				ply:SetBodygroup(id,(ply:GetBodygroup(id)-1) % (ply:GetBodygroupCount(id)))
			elseif isnumber(tonumber(args[2])) then
				ply:SetBodygroup(id, -1)
				ply:SetBodygroup(id, tonumber(args[2]))
			end

			ply:SetNWBool("pac_overriding_bodygroups", true)
		elseif args[1] then
			ply:SetBodyGroups(args[1])
			ply:SetNWBool("pac_overriding_bodygroups", true)
		end
	end, nil, "sends out a request to change your playermodel's bodygroups, but stops your entity parts from changing bodygroups")

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
		elseif args[1] == "^" or args[1] == "__RESET__" then
			for i=0,ply:GetFlexNum()-1 do
				SetFlexWeight(ply, i, 0)
			end
		end
		if args[1] and args[2] then
			local id = ply:GetFlexIDByName(args[1])
			if id == nil then return end

			if args[2] == "toggle" then
				if GetFlexWeight(ply, id) < 0.5 then
					SetFlexWeight(ply, id, 1)
				else
					SetFlexWeight(ply, id, 0)
				end
			elseif isnumber(tonumber(args[2])) then
				SetFlexWeight(ply, id, tonumber(args[2]))
			end
		end
	end, nil, "sends out a request to change your playermodel's flex weights")

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
				ply:PrintMessage(HUD_PRINTCONSOLE, "[" .. i .. "] " .. ply:GetPoseParameterName(i) .. " {"..min.."-"..max.."}")
			end
		end
		if not args[1] then
			helptext()
		elseif args[1] == "^" or args[1] == "__RESET__" then
			for i=0,ply:GetNumPoseParameters()-1 do
				broadcast_poseparam(ply, id, 0, true)
			end
		end
		if args[1] and args[2] then
			local id = ply:LookupPoseParameter(args[1])
			if id == -1 then return end
            local n = tonumber(args[2])
			if isnumber(n) then
				SetPoseParameter( ply, id, n )
				broadcast_poseparam(ply, id, n, false)
			elseif args[2] == "reset" then
				broadcast_poseparam(ply, id, 0, true)
			end
		end
	end, nil, "sends out a request to change your playermodel's pose parameters")

else
	net.Receive("pac_update_poseparameter", function()
		local id = net.ReadUInt(5)
		local value = net.ReadInt(16) / 100
		local reset = net.ReadBool()
		local ent = net.ReadEntity()
		local name = ent:GetPoseParameterName(id)
		local hookname = "manual_"..name
		ent.pac_pose_params = ent.pac_pose_params or {}
        
		if reset then 
            ent.pac_pose_params[hookname] = nil 
            
            SetPoseParameter(ent, id, 0)
            
            ent:InvalidateBoneCache()
        else
            ent.pac_pose_params[hookname] = ent.pac_pose_params[hookname] or {}
            ent.pac_pose_params[hookname].key  = name
            ent.pac_pose_params[hookname].val = value
            
            SetPoseParameter(ent, id, value)
            
            ent:InvalidateBoneCache()
        end
	end)
end
