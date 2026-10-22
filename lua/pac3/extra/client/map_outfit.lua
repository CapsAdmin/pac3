local WAIT_INTERVAL = 0.1
local WAIT_ATTEMPTS = 300

local pending = 0

net.Receive("pac_map_outfit_effect", function()
	local index = net.ReadUInt(16)
	local effect = net.ReadString()

	pending = pending + 1
	local timer_name = "pac_map_outfit_effect_" .. pending

	timer.Create(timer_name, WAIT_INTERVAL, WAIT_ATTEMPTS, function()
		local ent = Entity(index)
		if not ent:IsValid() then return end
		if not pac.pcfprovider.LoadEffect(effect) then return end

		timer.Remove(timer_name)

		ParticleEffectAttach(effect, PATTACH_ABSORIGIN_FOLLOW, ent, 0)
	end)
end)
