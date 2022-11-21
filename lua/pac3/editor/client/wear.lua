
local L = pace.LanguageString

function pace.IsPartSendable(part)

	if part:HasParent() then return false end
	if not part:GetShowInEditor() then return false end

	return true
end

function pace.WearOnServer(filter)
	local toWear = {}

	for key, part in pairs(pac.GetLocalParts()) do
		if pace.IsPartSendable(part) then
			table.insert(toWear, part)
		end
	end

	local transmissionID = math.random(1, 0x7FFFFFFF)

	for i, part in ipairs(toWear) do
		pace.SendPartToServer(part, {
			partID = i,
			totalParts = #toWear,
			transmissionID = transmissionID,
			temp_wear_filter = filter,
		})
	end
end

function pace.ClearParts()
	pace.ClearUndo()
	pac.RemoveAllParts(true, true)
	pace.RefreshTree()

	timer.Simple(0.1, function()
		if not pace.Editor:IsValid() then return end

		if table.Count(pac.GetLocalParts()) == 0 then
			pace.Call("CreatePart", "group", L"my outfit")
		end

		pace.TrySelectPart()
	end)
end



do -- to server
	local function net_write_table(tbl)

		local buffer = pac.StringStream()
		buffer:writeTable(tbl)

		local data = buffer:getString()
		local ok, err = pcall(net.WriteStream, data)

		if not ok then
			return ok, err
		end

		return #data
	end

	function pace.SendPartToServer(part, extra)
		local allowed, reason = pac.CallHook("CanWearParts", pac.LocalPlayer)

		if allowed == false then
			pac.Message(reason or "the server doesn't want you to wear parts for some reason")
			return false
		end

		if not pace.IsPartSendable(part) then return false end

		local data = {part = part:ToTable()}

		if extra then
			table.Merge(data, extra)
		end

		data.owner = part:GetPlayerOwner()
		data.wear_filter = pace.CreateWearFilter()

		net.Start("pac_submit")

		local bytes, err = net_write_table(data)

		if not bytes then
			pace.Notify(false, "unable to transfer data to server: " .. tostring(err or "too big"), pace.pac_show_uniqueid:GetBool() and string.format("%s (%s)", part:GetName(), part:GetPrintUniqueID()) or part:GetName())
			return false
		end

		net.SendToServer()
		pac.Message(('Transmitting outfit %q to server (%s)'):format(part.Name or part.ClassName or '<unknown>', string.NiceSize(bytes)))

		return true
	end

	function pace.RemovePartOnServer(name, server_only, filter)
		local data = {part = name, server_only = server_only, filter = filter}

		if name == "__ALL__" then
			pace.CallHook("RemoveOutfit", pac.LocalPlayer)
		end

		net.Start("pac_submit")
			local ret,err = net_write_table(data)
			if ret == nil then
				pace.Notify(false, "unable to transfer data to server: "..tostring(err or "too big"), name)
				return false
			end
		net.SendToServer()

		return true
	end
end

do -- from server
	function pace.WearPartFromServer(owner, part_data, data, doItNow)
		pac.dprint("received outfit %q from %s with %i number of children to set on %s", part_data.self.Name or "", tostring(owner), table.Count(part_data.children), part_data.self.OwnerName or "")

		if pace.CallHook("WearPartFromServer", owner, part_data, data) == false then return end

		local dupepart = pac.GetPartFromUniqueID(data.player_uid, part_data.self.UniqueID)

		if dupepart:IsValid() then
			pac.dprint("removing part %q to be replaced with the part previously received", dupepart.Name)
			dupepart:Remove()
		end

		local dupeEnt

		-- safe guard
		if data.is_dupe then
			local id = tonumber(part_data.self.OwnerName)
			dupeEnt = Entity(id or -1)
			if not dupeEnt:IsValid() then
				return
			end
		end

		local function load_outfit()
			if dupeEnt and not dupeEnt:IsValid() then return end

			dupepart = pac.GetPartFromUniqueID(data.player_uid, part_data.self.UniqueID)

			if dupepart:IsValid() then
				pac.dprint("removing part %q to be replaced with the part previously received ON callback call", dupepart.Name)
				dupepart:Remove()
			end

			owner.pac_render_time_exceeded = false

			-- specify "level" as 1 so we can delay CalcShowHide recursive call until we are ready
			local part = pac.CreatePart(part_data.self.ClassName, owner, part_data, false, 1)

			if data.is_dupe then
				part.dupe_remove = true
			end

			if owner == pac.LocalPlayer then
				pace.CallHook("OnWoreOutfit", part)
			end

			part:CallRecursive('OnWorn')
			part:CallRecursive('PostApplyFixes')

			if part.UpdateOwnerName then
				part:UpdateOwnerName(true)
				part:CallRecursive("CalcShowHide", true)
			end

			owner.pac_fix_show_from_render = SysTime() + 1
		end

		if doItNow then
			load_outfit()
		end

		return load_outfit
	end

	function pace.RemovePartFromServer(owner, part_name, data)
		pac.dprint("%s removed %q", tostring(owner), part_name)

		if part_name == "__ALL__" then
			pac.RemovePartsFromUniqueID(data.player_uid)

			pace.CallHook("RemoveOutfit", owner)
			pac.CleanupEntityIgnoreBound(owner)
		else
			local part = pac.GetPartFromUniqueID(data.player_uid, part_name)

			if part:IsValid() then
				part:Remove()
			end
		end
	end
end

function pace.HandleReceiveData(data, doitnow)
	local T = type(data.part)

	if T == "table" then
		return pace.WearPartFromServer(data.owner, data.part, data, doitnow)
	elseif T ==  "string" then
		return pace.RemovePartFromServer(data.owner, data.part, data)
	else
		ErrorNoHalt("PAC: Unhandled "..T..'!?\n')
	end
end

net.Receive("pac_submit", function()
	if not pac.IsEnabled() then return end

	net.ReadStream(ply, function(data)
		if not data then
			pac.Message("message from server timed out")
			return
		end

		local buffer = pac.StringStream(data)
		local data = buffer:readTable()

		if type(data.owner) ~= "Player" or not data.owner:IsValid() then
			pac.Message("received message from server but owner is not valid!? typeof " .. type(data.owner) .. ' || ', data.owner)
			return
		end

		if pac.IsPacOnUseOnly() and data.owner ~= pac.LocalPlayer then
			pace.HandleOnUseReceivedData(data)
		else
			pace.HandleReceiveData(data, true)
		end
	end)
end)

function pace.Notify(allowed, reason, name)
	name = name or "???"

	 if allowed == true then
		pac.Message(string.format('Your part %q has been applied', name))
	else
		chat.AddText(Color(255, 255, 0), "[PAC3] ", Color(255, 0, 0), string.format('The server rejected applying your part (%q) - %s', name, reason))
	end
end

net.Receive("pac_submit_acknowledged", function(umr)
	pace.Notify(net.ReadBool(), net.ReadString(), net.ReadString())
end)

do
	local function LoadUpDefault()
		if next(pac.GetLocalParts()) then
			pac.Message("not wearing autoload outfit, already wearing something")
		elseif pace.IsActive() then
			pac.Message("not wearing autoload outfit, editor is open")
		else
			pac.Message("Wearing autoload...")
			pace.LoadParts("autoload")
			pace.WearParts()
		end

		pac.RemoveHook("Think", "pac_request_outfits")
		pac.Message("Requesting outfits in 8 seconds...")

		timer.Simple(8, function()
			pac.Message("Requesting outfits...")
			RunConsoleCommand("pac_request_outfits")
		end)
	end

	local function Initialize()
		pac.RemoveHook("KeyRelease", "pac_request_outfits")

		if not pac.LocalPlayer:IsValid() then
			return
		end

		if not pac.IsEnabled() then
			pac.RemoveHook("Think", "pac_request_outfits")
			pace.NeverLoaded = true
			return
		end

		LoadUpDefault()
	end

	hook.Add("pac_Enable", "pac_LoadUpDefault", function()
		if not pace.NeverLoaded then return end
		pace.NeverLoaded = nil
		LoadUpDefault()
	end)

	local frames = 0

	pac.AddHook("Think", "pac_request_outfits", function()
		if RealFrameTime() > 0.2 then -- lag?
			return
		end

		frames = frames + 1

		if frames > 400 then
			if not xpcall(Initialize, ErrorNoHalt) then
				pac.RemoveHook("Think", "pac_request_outfits")
				pace.NeverLoaded = true
			end
		end
	end)

	pac.AddHook("KeyRelease", "pac_request_outfits", function()
		local me = pac.LocalPlayer

		if me:IsValid() and me:GetVelocity():Length() > 50 then
			frames = frames + 200

			if frames > 400 then
				Initialize()
			end
		end
	end)
end
