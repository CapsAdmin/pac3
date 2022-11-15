
util.AddNetworkString('pac_submit_acknowledged')
util.AddNetworkString('pac_update_playerfilter')

local function find_outfits(ply)
	for id, outfits in pairs(pace.Parts) do
		local owner = pac.ReverseHash(id, "Player")
		if owner:IsValid() then
			if owner == ply then
				return outfits
			end
		end
	end

	return {}
end

pace.PCallNetReceive(net.Receive, "pac_update_playerfilter", function(len, ply)
	local sizeof = net.ReadUInt(8)

	if sizeof > game.MaxPlayers() then
		pac.Message("Player ", ply, " tried to submit extraordinary wear filter size of ", sizeof, ", dropping.")
		return
	end

	local ids = {}

	for i = 1, sizeof do
		table.insert(ids, net.ReadString())
	end

	for _, outfit in pairs(find_outfits(ply)) do

		if outfit.wear_filter then
			for _, id in ipairs(ids) do
				if not table.HasValue(outfit.wear_filter, id) then
					local ply = pac.ReverseHash(id, "Player")
					if ply:IsValid() then
						if ply.pac_requested_outfits and not ply.pac_gonna_receive_outfits then
							pace.SubmitPart(outfit, ply)
						end
					end
				end
			end
		end

		outfit.wear_filter = ids
	end
end)

function pace.UpdateWearFilters()
	net.Start('pac_update_playerfilter')
	net.Broadcast()
end
