
local pac_onuse_only = CreateClientConVar('pac_onuse_only', '0', true, false, 'Enable "on +use only" mode. Within this mode, outfits are not being actually "loaded" until you hover over player and press your use button')
local L = pace.LanguageString
local MAX_DIST = 270

hook.Add("PlayerBindPress", "pac_onuse_only", function(ply, bind, isPressed)
	if bind ~= "use" and bind ~= "+use" then return end
	if bind ~= "+use" and isPressed then return end
	if not pac_onuse_only:GetBool() then return end
	local eyes, aim = ply:EyePos(), ply:GetAimVector()

	local tr = util.TraceLine({
		start = eyes,
		endpos = eyes + aim * MAX_DIST,
		filter = ply
	})

	-- if not tr.Hit or not tr.Entity:IsValid() or not tr.Entity:IsPlayer() then return end
	if not tr.Hit or not tr.Entity:IsValid() then return end

	local ply2 = tr.Entity
	if not ply2.pac_onuse_only or not ply2.pac_onuse_only_check then return end
	ply2.pac_onuse_only_check = false
	pac.ToggleIgnoreEntity(ply2, false, "pac_onuse_only")
end)

do
	local lastDisplayLabel = 0

	surface.CreateFont("pac_onuse_only_hint", {
		font = "Roboto",
		size = ScreenScale(16),
		weight = 600,
	})

	hook.Add("HUDPaint", "pac_onuse_only", function(ply, bind, isPressed)
		if not pac_onuse_only:GetBool() then return end
		local ply = pac.LocalPlayer
		local eyes, aim = ply:EyePos(), ply:GetAimVector()

		local tr = util.TraceLine({
			start = eyes,
			endpos = eyes + aim * MAX_DIST,
			filter = ply
		})

		if tr.Hit and tr.Entity:IsValid() and tr.Entity.pac_onuse_only and tr.Entity.pac_onuse_only_check then
			lastDisplayLabel = RealTime() + 1
		end

		if lastDisplayLabel < RealTime() then return end

		local alpha = (lastDisplayLabel - RealTime()) / 3
		draw.DrawText(L"Press +use to reveal PAC3 outfit", "pac_onuse_only_hint", ScrW() / 2, ScrH() * 0.3, Color(255, 255, 255, alpha * 255), TEXT_ALIGN_CENTER)
	end)
end

local pac_onuse_only = CreateClientConVar('pac_onuse_only', '0', true, false, 'Enable "on +use only" mode. Within this mode, outfits are not being actually "loaded" until you hover over player and press your use button')

function pace.OnUseOnlyUpdates(cvar, ...)
	hook.Call('pace_OnUseOnlyUpdates', nil, ...)
end

cvars.AddChangeCallback("pac_onuse_only", pace.OnUseOnlyUpdates, "PAC3")

concommand.Add("pac_onuse_reset", function()
	for i, ent in ipairs(ents.GetAll()) do
		if ent.pac_onuse_only then
			ent.pac_onuse_only_check = true

			if pac_onuse_only:GetBool() then
				pac.ToggleIgnoreEntity(ent, ent.pac_onuse_only_check, 'pac_onuse_only')
			else
				pac.ToggleIgnoreEntity(ent, false, 'pac_onuse_only')
			end
		end
	end
end)

local transmissions = {}

timer.Create('pac3_transmissions_ttl', 1, 0, function()
	local time = RealTime()

	for transmissionID, data in pairs(transmissions) do
		if data.activity + 10 < time then
			transmissions[transmissionID] = nil
			pac.Message('Marking transmission session with id ', transmissionID, ' as dead. Received ', #data.list, ' out from ', data.total, ' parts.')
		end
	end
end)

function pace.HandleOnUseReceivedData(data)
	local validTransmission = isnumber(data.partID) and
		isnumber(data.totalParts) and isnumber(data.transmissionID)

	if not data.owner.pac_onuse_only then
		data.owner.pac_onuse_only = true
		-- if TRUE - hide outfit
		data.owner.pac_onuse_only_check = true

		if pac_onuse_only:GetBool() then
			pac.ToggleIgnoreEntity(data.owner, data.owner.pac_onuse_only_check, 'pac_onuse_only')
		else
			pac.ToggleIgnoreEntity(data.owner, false, 'pac_onuse_only')
		end
	end

	-- behaviour of this (if one of entities on this hook becomes invalid)
	-- is undefined if DLib is not installed, but anyway
	hook.Add('pace_OnUseOnlyUpdates', data.owner, function()
		if pac_onuse_only:GetBool() then
			pac.ToggleIgnoreEntity(data.owner, data.owner.pac_onuse_only_check, 'pac_onuse_only')
		else
			pac.ToggleIgnoreEntity(data.owner, false, 'pac_onuse_only')
		end
	end)

	if not validTransmission then
		local func = pace.HandleReceiveData(data)

		local part_uid

		if istable(data.part) and istable(data.part.self) then
			part_uid = data.part.self.UniqueID
		end

		if isfunction(func) then
			pac.EntityIgnoreBound(data.owner, func, part_uid)
		end

		return
	end

	local trData = transmissions[data.transmissionID]

	if not trData then
		trData = {
			id = data.transmissionID,
			total = data.totalParts,
			list = {},
			activity = RealTime()
		}

		transmissions[data.transmissionID] = trData
	end

	local transmissionID = data.transmissionID
	data.transmissionID = nil
	data.totalParts = nil
	data.partID = nil
	table.insert(trData.list, data)
	trData.activity = RealTime()

	if #trData.list == trData.total then
		local funcs = {}

		for i, part in ipairs(trData.list) do
			local func = pace.HandleReceiveData(part)

			if isfunction(func) then
				table.insert(funcs, func)
			end
		end

		for i, func in ipairs(funcs) do
			pac.EntityIgnoreBound(data.owner, func)
		end

		transmissions[data.transmissionID or transmissionID] = nil
	end
end