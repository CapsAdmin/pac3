
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

--wearing tracker counter
pace.still_loading_wearing_count = 0
--reusable function
function pace.ExtendWearTracker(duration)
	if not duration or not isnumber(duration) then duration = 1 end
	pace.still_loading_wearing = true
	pace.still_loading_wearing_count = pace.still_loading_wearing_count + 1 --this group is added to the tracked wear count
	timer.Simple(duration, function()
		pace.still_loading_wearing_count = pace.still_loading_wearing_count - 1 --assume max 8 seconds to wear
		if pace.still_loading_wearing_count == 0 then --if this is the last group to wear, we're done
			pace.still_loading_wearing = false
		end
	end)
end

do -- to server
	local function net_write_table(tbl)
		local buffer = pac.StringStream()
		buffer:writeTable(tbl)
		local data = buffer:getString()
		net.WriteStream(data)
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

		--hack so that camera part doesn't force-gain focus if it's not manually created, because wearing removes and re-creates parts.
		pace.hack_camera_part_donot_treat_wear_as_creating_part = true
		timer.Simple(2, function()
			pace.hack_camera_part_donot_treat_wear_as_creating_part = nil
		end)

		if extra then
			table.Merge(data, extra)
		end

		data.owner = part:GetPlayerOwner()
		data.wear_filter = pace.CreateWearFilter()

		net.Start("pac_submit")

		local ok, bytes = pcall(net_write_table, data)

		if not ok then
			net.Abort()
			pace.Notify(false, "unable to transfer data to server: " .. tostring(bytes or "too big"), pace.pac_show_uniqueid:GetBool() and string.format("%s (%s)", part:GetName(), part:GetPrintUniqueID()) or part:GetName())
			return false
		end

		net.SendToServer()
		pac.Message(("Transmitting outfit %q to server (%s)"):format(part.Name or part.ClassName or "<unknown>", string.NiceSize(bytes)))

		pace.ExtendWearTracker(8)

		return true
	end

	function pace.RemovePartOnServer(name, server_only, filter)
		local data = {part = name, server_only = server_only, filter = filter}

		if name == "__ALL__" then
			pace.CallHook("RemoveOutfit", pac.LocalPlayer)
		end

		net.Start("pac_submit")
			local ok, err = pcall(net_write_table, data)
			if not ok then
				net.Abort()
				pace.Notify(false, "unable to transfer data to server: " .. tostring(err or "too big"), name)
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
		if pace.ShouldIgnorePlayer(owner) and owner ~= LocalPlayer() then pace.RemovePartFromServer(owner, "__ALL__", data) return end
		
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
				pac.CallHook("OnWoreOutfit", part)
			end

			part:CallRecursive("OnWorn")
			part:CallRecursive("PostApplyFixes")

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
		ErrorNoHalt("PAC: Unhandled " .. T .. "!?\n")
	end
end

net.Receive("pac_submit", function()
	if not pac.IsEnabled() then return end

	local owner = net.ReadEntity()
	if owner:IsValid() and owner:IsPlayer() then
		pac.Message("Receiving outfit from ", owner)
	else
		return
	end

	net.ReadStream(ply, function(data)
		if not data then
			pac.Message("message from server timed out")
			return
		end

		local buffer = pac.StringStream(data)
		local ok, data = pcall(buffer.readTable, buffer)
		if not ok then
			pac.Message("received invalid message from server!?")
			return
		end

		if type(data.owner) ~= "Player" or not data.owner:IsValid() then
			pac.Message("received message from server but owner is not valid!? typeof " .. type(data.owner) .. " || ", data.owner)
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
		pac.Message(string.format("Your part %q has been applied", name))
	else
		chat.AddText(Color(255, 255, 0), "[PAC3] ", Color(255, 0, 0), string.format("The server rejected applying your part (%q) - %s", name, reason))
	end
end

net.Receive("pac_submit_acknowledged", function(umr)
	pace.Notify(net.ReadBool(), net.ReadString(), net.ReadString())
end)

do
	local function LoadUpDefault()
		if not GetConVar("pac_prompt_for_autoload"):GetBool() then
			--legacy behavior
			if next(pac.GetLocalParts()) then
				pac.Message("not wearing autoload outfit, already wearing something")
			elseif pace.IsActive() then
				pac.Message("not wearing autoload outfit, editor is open")
			else
				local autoload_file = "autoload"
				local autoload_result = hook.Run("PAC3Autoload", autoload_file)

				if autoload_result ~= false then
					if isstring(autoload_result) then
						autoload_file = autoload_result
					end
					pac.Message("Wearing " .. autoload_file .. "...")
					pace.LoadParts(autoload_file)
					pace.WearParts()
				end
			end

		else
			--prompt
			local backup_files, directories = file.Find( "pac3/__backup/*.txt", "DATA", "datedesc")
			local latest_outfit = cookie.GetString( "pac_last_loaded_outfit", "" )
			if not backup_files then
				local pnl = Derma_Query("Do you want to load your autoload outfit?\nclick outside the window to cancel", "PAC3 autoload (pac_prompt_for_autoload)",
					"load pac3/autoload.txt : " .. string.NiceSize(file.Size("pac3/autoload.txt", "DATA")), function()
						pac.Message("Wearing autoload...")
						pace.LoadParts("autoload")
						pace.WearParts()
					end,

					"load latest outfit : pac3/" .. latest_outfit .. " " .. string.NiceSize(file.Size("pac3/" .. latest_outfit, "DATA")), function()

						if latest_outfit and file.Exists("pac3/" .. latest_outfit, "DATA") then
							pac.Message("Wearing latest outfit...")
							pace.LoadParts(latest_outfit, true)
							pace.WearParts()
						end
					end,

					"don't show this again", function() GetConVar("pac_prompt_for_autoload"):SetBool(false) end
				)
				pnl.Think = function() if not pnl:HasFocus() or (input.IsMouseDown(MOUSE_LEFT) and not (pnl:IsHovered() or pnl:IsChildHovered())) then pnl:Remove() end end
			else
				if backup_files[1] then
					local latest_autosave = "pac3/__backup/" .. backup_files[1]
					local pnl = Derma_Query("Do you want to load an outfit?\nclick outside the window to cancel", "PAC3 autoload (pac_prompt_for_autoload)",
						"load pac3/autoload.txt : " .. string.NiceSize(file.Size("pac3/autoload.txt", "DATA")), function()
							pac.Message("Wearing autoload...")
							pace.LoadParts("autoload")
							pace.WearParts()
						end,

						"load latest backup : " .. latest_autosave .. " " .. string.NiceSize(file.Size(latest_autosave, "DATA")), function()
							pac.Message("Wearing latest backup outfit...")
							pace.LoadParts("__backup/" .. backup_files[1], true)
							pace.WearParts()
						end,

						"load latest outfit : pac3/" .. latest_outfit .. " " .. string.NiceSize(file.Size("pac3/" .. latest_outfit, "DATA")), function()
							if latest_outfit and file.Exists("pac3/" .. latest_outfit, "DATA") then
								pac.Message("Wearing latest outfit...")
								pace.LoadParts(latest_outfit, true)
								pace.WearParts()
							end
						end,

						"don't show this again", function() GetConVar("pac_prompt_for_autoload"):SetBool(false) end
					)
					pnl.Think = function() if not pnl:HasFocus() or (input.IsMouseDown(MOUSE_LEFT) and not (pnl:IsHovered() or pnl:IsChildHovered())) then pnl:Remove() end end
				else
					local pnl = Derma_Query("Do you want to load your autoload outfit?\nclick outside the window to cancel", "PAC3 autoload (pac_prompt_for_autoload)",
						"load pac3/autoload.txt : " .. string.NiceSize(file.Size("pac3/autoload.txt", "DATA")), function()
							pac.Message("Wearing autoload...")
							pace.LoadParts("autoload")
							pace.WearParts()
						end,

						"don't show this again", function() GetConVar("pac_prompt_for_autoload"):SetBool(false) end
					)
					pnl.Think = function() if not pnl:HasFocus() or (input.IsMouseDown(MOUSE_LEFT) and not (pnl:IsHovered() or pnl:IsChildHovered())) then pnl:Remove() end end
				end
			end
		end

		pac.RemoveHook("Think", "request_outfits")
		pac.Message("Requesting outfits in 8 seconds...")

		timer.Simple(8, function()
			pac.Message("Requesting outfits...")
			RunConsoleCommand("pac_request_outfits")
		end)
	end

	local function Initialize()
		pac.RemoveHook("KeyRelease", "request_outfits")

		if not pac.LocalPlayer:IsValid() then
			return
		end

		if not pac.IsEnabled() then
			pac.RemoveHook("Think", "request_outfits")
			pace.NeverLoaded = true
			return
		end

		LoadUpDefault()
	end

	pac.AddHook("pac_Enable", "LoadUpDefault", function()
		if not pace.NeverLoaded then return end
		pace.NeverLoaded = nil
		LoadUpDefault()
	end)

	local frames = 0

	pac.AddHook("Think", "request_outfits", function()
		if RealFrameTime() > 0.2 then -- lag?
			return
		end

		frames = frames + 1

		if frames > 400 and not xpcall(Initialize, ErrorNoHalt) then
			pac.RemoveHook("Think", "request_outfits")
			pace.NeverLoaded = true
		end
	end)

	pac.AddHook("KeyRelease", "request_outfits", function()
		local me = pac.LocalPlayer

		if me:IsValid() and me:GetVelocity():Length() > 50 then
			frames = frames + 200

			if frames > 400 then
				Initialize()
			end
		end
	end)
end
